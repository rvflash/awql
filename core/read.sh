#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
    source "${AWQL_INC_DIR}/complete.sh"
    source "${AWQL_BASH_PACKAGES_DIR}/math.sh"
fi

declare -r AWQL_READ_TERM="$(stty -g)"

##
# Erase all the screen on go on top on the screen
# @return string
function __clearScreen ()
{
    (tput clear; echo -n "${AWQL_PROMPT}")
}

##
# Move to required line
# @param int $1 Previous position
# @param int $2 Position
# @param int $3 Window width
# @return string
function __moveLineAndCursor ()
{
    declare -i prevPosition="$1"
    declare -i position="$2"
    declare -i windowWidth="$3"
    declare -i promptWidth="${#AWQL_PROMPT}"

    # Add prompt size
    prevPosition+=${promptWidth}
    position+=${promptWidth}

    # Move to the line
    declare -i linePrevIndex="$(floor $(divide ${prevPosition} ${windowWidth} 4))"
    declare -i lineIndex="$(floor $(divide ${position} ${windowWidth} 4))"
    if [[ ${lineIndex} -lt ${linePrevIndex} ]]; then
        # Go to the line on top
        tput cuu $((${linePrevIndex}-${lineIndex}))
    elif [[ ${lineIndex} -gt ${linePrevIndex} ]]; then
        # Go to the line below
        tput cud $((${lineIndex}-${linePrevIndex}))
    fi

    # Move cursor on line
    declare -i linePrevPosition="$(modulo ${prevPosition} ${windowWidth})"
    declare -i linePosition="$(modulo ${position} ${windowWidth})"
    if [[ ${linePosition} -gt ${linePrevPosition} ]]; then
        # Move cursor right
        tput cuf $((${linePosition}-${linePrevPosition}))
    elif [[ ${linePosition} -lt ${linePrevPosition} ]]; then
        # Move cursor left
        tput cub $((${linePrevPosition}-${linePosition}))
    fi
}

##
# Move to the first line
# @param int $1 Position
# @param int $2 Window width
# @return string
function __moveToStart ()
{
    declare -i position="$1"
    declare -i windowWidth="$2"
    declare -i promptWidth="${#AWQL_PROMPT}"

    # Add prompt size
    position+=${promptWidth}

    declare -i linePosition="$(modulo ${position} ${windowWidth})"
    if [[ ${linePosition} -gt 0 ]]; then
        # Move cursor left to the beginning of line
        tput cub ${linePosition}
    fi
    declare -i lineIndex="$(floor $(divide ${position} ${windowWidth} 4))"
    if [[ ${lineIndex} -gt 0 ]]; then
        # Go to the line on top
        tput cuu ${lineIndex}
    fi
}

##
# Reset prompt and display line
# @param string $1 Text
# @param bool $2 Move cursor
# @return string
function __printLine ()
{
    local text="$1"
    declare -i moveCursor="$2"

    if [[ ${moveCursor} -eq 0 ]]; then
        # Also save cursor position
        (echo -e "sc\ned" | tput -S; echo -n "$text"; tput rc)
    else
        (tput ed; echo -n "$text")
    fi
}

##
# Replace current line by another
# @param int $1 Previous position
# @param int $2 Line
# @param int $3 Window width
# @return string
function __replaceLine ()
{
    declare -i position="$1"
    local text="$2"
    declare -i windowWidth="$3"

    # Erase the screen from the beginning of the line to the bottom of the screen
    (tput civis; __moveToStart ${position} ${windowWidth}; __printLine "$text" 1; tput cnorm)
}

##
# Change content of the current line
# @param int $1 Previous position
# @param int $2 Position
# @param string $3 Text
# @param int $4 Window width
function __reformLine ()
{
    declare -i prevPosition="$1"
    declare -i position="$2"
    local text="$3"
    declare -i windowWidth="$4"

    (tput civis; __printLine "$text" 1; __moveLineAndCursor ${prevPosition} ${position} ${windowWidth}; tput cnorm)
}

##
# Erase character to the left of the current position and move rest of the content backwards
# @param int $1 Position
# @param string $2 Text
# @param int $3 Window width
function __reviseLine ()
{
    declare -i position="$1"
    local text="$2"
    declare -i windowWidth="$3"
    declare -i promptWidth="${#AWQL_PROMPT}"

    if [[ 0 -eq $(modulo $((${position}+${promptWidth})) ${windowWidth}) ]]; then
        # Move cursor on right of the line up & erase char & move rest of line backwards
        (echo -e "cuu1\nhpa ${windowWidth}\ndch1" | tput -S; __printLine "$text")
    else
        # Move cursor left & erase this char & move rest of line backwards
        (echo -e "cub1\ndch1" | tput -S; __printLine "$text")
    fi
}

##
# Reset terminal to current state when we exit
# @param int $1 Disable exit
# @return void
function __restoreTerm()
{
    stty "${AWQL_READ_TERM}";

    declare -i withoutExit="$1"
    if [[ ${withoutExit} -eq 0 ]]; then
        exit 0
    fi
}

##
# Read lines from the standard input and split it into fields.
# Manage history in file, completion with tab, navigation with arrow keys and backspace
# @see http://www.termsys.demon.co.uk/vtansi.htm
# @see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# @see https://www.gnu.org/software/termutils/manual/termutils-2.0/html_chapter/tput_1.html
#
# In order to find out a key combination in ANSI:
# @use sed -n l
#
# In order to identify witch code for each key, use command: sed -n l
# @param string $1 Output variable name
# @param int $2 Auto-rehash
# @param string $3 Api version
# @return void
function awqlRead ()
{
    # Variable name use to export the response of prompt
    local readerVarName="$1"
    local reply

    # Completion
    declare -i autoRehash="$2"
    local apiVersion="$3"
    declare -a compReply

    # Terminal size
    declare -i windowWidth
    windowWidth="$(windowSize "width")"
    if [[ $? -ne 0 ]]; then
        echo "InternalError.USE_ONLY_IN_TERMINAL"
        return 1
    fi

    # History file
    declare -i historyIndex historySize
    declare -a history=()
    local file="${AWQL_HISTORY_FILE}"
    if [[ -n "$file" ]]; then
        if [[ -f "$file" ]]; then
            mapfile -t history < "$file"
        fi
        historySize="${#history[@]}"
        historyIndex=${historySize}
    fi

    # Introduction messages
    declare -i promptSize="${#AWQL_PROMPT}"
    local prompt="${AWQL_PROMPT}"
    local promptNewLine="${AWQL_PROMPT_NEW_LINE}"

    # Launch prompt by sending introduction message
    echo -n "$prompt"

    # Ash or Dash do not trap signals with EXIT
    trap __restoreTerm EXIT INT TERM

    # Disable echo and special characters, set input timeout to 0.2 seconds
    stty -echo -icanon time 2

    # Read one character at a time
    local char rest
    declare -a read=()
    declare -i readLength=0 readPrevLength=0 readIndex=0 charIndex=0 charPrevIndex=0
    while IFS="" read -rsn1 char; do
        # \x1b is the start of an escape sequence == \033
        if [[ "$char" == $'\x1b' ]]; then
            # Get the rest of the escape sequence (3 characters total)
            while IFS= read -rsn2 rest; do
                char+="$rest"
                break
            done
        fi

        charPrevIndex=${charIndex}
        readPrevLength=${readLength}
        if [[ "$char" == $'\f' ]]; then
            # Clear the terminal (ctrl + l)
            __clearScreen
        elif [[ "$char" == $'\x1b[F' || "$char" == $'\x1b[H' || "$char" == $'\001' || "$char" == $'\005' ]]; then
            # Go to start (home) or end of the line (Fn or ctrl + left and right arrow keys)
            if [[ "$char" == $'\x1b[F' || "$char" == $'\005' ]]; then
                # Forward to end
                charIndex=${readLength}
                __moveLineAndCursor ${charPrevIndex} ${readLength} ${windowWidth}
            else
                # Backward to start
                charIndex=0
                __moveLineAndCursor ${charPrevIndex} 0 ${windowWidth}
            fi
        elif [[ "$char" == $'\x1b[A' || "$char" == $'\x1b[B' ]]; then
            # Navigate in history with up and down arrow keys
            if [[ -z "$file" || ${readIndex} -gt 0 ]]; then
                continue;
            elif [[ "$char" == $'\x1b[A' && ${historyIndex} -gt 0 ]];then
                # Up
                historyIndex+=-1
            elif [[ "$char" == $'\x1b[B' && ${historyIndex} -lt ${historySize} ]]; then
                # Down
                historyIndex+=1
            else
                continue
            fi
            # Remove current line and replace it by this one from historic
            read["${readIndex}"]="${history["${historyIndex}"]}"
            readLength="${#read["${readIndex}"]}"
            charIndex="${readLength}"
            __replaceLine ${charPrevIndex} "${prompt}${read["${readIndex}"]}" ${windowWidth}
        elif [[ "$char" == $'\x1b[C' || "$char" == $'\x1b[D' ]]; then
            # Moving char by char with left or right arrow keys
            if [[ "$char" == $'\x1b[C' && ${charIndex} -lt ${readLength} ]]; then
                # Right (cuf1)
                charIndex+=1
            elif [[ "$char" == $'\x1b[D' && ${charIndex} -gt 0 ]]; then
                # Left (cub1)
                charIndex+=-1
            else
                continue
            fi
            __moveLineAndCursor ${charPrevIndex} ${charIndex} ${windowWidth}
        elif [[ "$char" == $'\177' || "$char" == $'\010' ]]; then
            # Backspace / Delete
            if [[ ${charIndex} -eq 0 ]]; then
                continue
            elif [[ ${charIndex} -eq ${readLength} ]]; then
                # Remove only the last char
                rest=""
                read["${readIndex}"]="${read["${readIndex}"]%?}"
            else
                # Remove the char at the given index
                rest="${read["${readIndex}"]:${charIndex}}"
                read["${readIndex}"]="${read["${readIndex}"]::$((${charIndex}-1))}${rest}"
            fi
            readLength+=-1
            charIndex+=-1
            __reviseLine ${charPrevIndex} "$rest" ${windowWidth}
        elif [[ "$char" == $'\x09' ]]; then
            # Completion enabled ?
            if [[ ${autoRehash} -eq 0 ]]; then
                continue
            fi
            # Retrieve completion
            reply="${read[@]}"
            reply="${reply:0:${charIndex}}"
            compReply=$(awqlComplete "$reply" "$apiVersion")
            if [[ $? -ne 0 ]]; then
                continue
            fi
            # Display completion reply if necessary
            IFS=" " read -a compReply <<< "$compReply"
            declare -i compReplyLength="${#compReply[@]}"
            if [[ ${compReplyLength} -eq 1 ]]; then
                # A completion was found
                declare -i compReplySize="${#compReply[0]}"
                charIndex+=${compReplySize}
                readLength+=${compReplySize}
                rest="${compReply[0]}${read["${readIndex}"]:$charPrevIndex}"
                read["${readIndex}"]="${read["${readIndex}"]::$charPrevIndex}${rest}"
            else
                # Various completions were found, go to new line to display it
                echo
                local displayAllCompletions="$(printf "${AWQL_COMPLETION_CONFIRM}" "${compReplyLength}")"
                # Temporary re-enable echoing for read method
                stty echo
                if confirm "$displayAllCompletions" "${AWQL_CONFIRM}"; then
                    # Display in columns
                    local column=""
                    declare -i columnSize=55
                    declare -i columnNb="$(( ${windowWidth}/${columnSize} ))"
                    declare -i columnPos goToLine
                    for columnPos in "${!compReply[@]}"; do
                        goToLine=1
                        column="${compReply["${columnPos}"]}"
                        printRightPadding "$column" $((${columnSize}-${#column}))
                        if [[ $(( ${columnPos}%${columnNb} )) -eq $(( ${columnNb}-1 )) ]]; then
                            goToLine=0
                            echo
                        fi
                    done
                    # Go to line after displaying propositions (prevent reset by prompt)
                    if [[ ${goToLine} -eq 1 ]]; then
                        echo
                    fi
                fi
                stty -echo
                # Reset and restore query with previous position of cursor
                rest="${prompt}${read["${readIndex}"]}"
            fi
            __reformLine ${readLength} ${charIndex} "$rest" ${windowWidth}
        elif [[ -z "$char" ]]; then
            # Enter
            reply="${read[@]}"
            reply="$(trim "$reply")"
            if [[ -z "$reply" ]]; then
                # Empty line
                echo
                break
            elif [[ "$reply" == *";" || "$reply" == *"\\"[gG] ]]; then
                # Query ending
                if [[ -n "$file" ]]; then
                    # Add current line in file history
                    if [[ "${historyIndex}" -lt ${historySize} ]]; then
                        # Remove the old position in historic in order to put this line as the last command
                        sed -e $((${historyIndex} + 1))d "$file" > "${file}-e" && mv "${file}-e" "$file"
                    fi
                    echo "$reply" >> "$file"
                fi
                # Go to new line to display response
                echo
                break
            elif [[ \
                "$reply" == ${AWQL_QUERY_CLEAR} || "$reply" == ${AWQL_QUERY_HELP} || \
                "$reply" == ${AWQL_QUERY_EXIT} || "$reply" == ${AWQL_QUERY_QUIT} \
            ]]; then
                # Go to new line to display command's response
                echo
                break
            elif [[ "$reply" == *"\\"[${AWQL_COMMAND_CLEAR}${AWQL_COMMAND_HELP}${AWQL_COMMAND_EXIT}] ]]; then
                # Awql commands shortcut
                case "${reply: -1}" in
                    ${AWQL_COMMAND_CLEAR})
                        reply=""
                        ;;
                    ${AWQL_COMMAND_HELP})
                        reply="${AWQL_TEXT_COMMAND_HELP}"
                        ;;
                    ${AWQL_COMMAND_EXIT})
                        reply="${AWQL_TEXT_COMMAND_EXIT}"
                        ;;
                esac
                # Go to new line to display response
                echo
                break
            else
                # Newline!
                prompt="$promptNewLine"
                readIndex+=1
                readLength=0
                charIndex=0
                echo
                echo -n "$prompt"
            fi
        elif [[ "$char" == [[:print:]] ]]; then
            # Write only printable chars
            charIndex+=1
            readLength+=1
            if [[ ${charPrevIndex} -eq ${readPrevLength} ]]; then
                read["${readIndex}"]+="$char"
                echo -n "$char"
            else
                rest="${char}${read["${readIndex}"]:$charPrevIndex}"
                read["${readIndex}"]="${read["${readIndex}"]::$charPrevIndex}${rest}"
                __reformLine ${readLength} ${charIndex} "$rest" ${windowWidth}
            fi
        fi
    done

    # Manages all exit cases
    __restoreTerm 1
    # Protects and exports the query
    eval "${readerVarName}=\"${reply//\"/\\\"}\""
}