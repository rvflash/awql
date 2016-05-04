#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
    source "${AWQL_INC_DIR}/complete.sh"
    source "${AWQL_BASH_PACKAGES_DIR}/math.sh"
fi

# DEBUG
source "${AWQL_BASH_PACKAGES_DIR}/log/file.sh"


##
# Erase all the screen on go on top on the screen
# @return string
function __clearScreen ()
{
    tput clear
    echo -n "${AWQL_PROMPT}"
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
        # Save cursor position
        tput sc
    fi
    # Reset current line on print the new
    tput el
    echo -n "$text"
    if [[ ${moveCursor} -eq 0 ]]; then
        # Restore cursor position
        tput rc
    fi
}

##
# Erase text after this position and add in place the given text
# @param int $1 Position
# @param string $2 Text
# @param int $3 Line width
# @param int $4 Window width
function __printLineModification ()
{
    declare -i position="$1"
    local text="$2"
    declare -i width="$3"
    declare -i windowWidth="$4"

    # Need to reset more than the current line ?
    declare -i lineCurrentIndex="$(floor $(divide ${position} ${windowWidth} 4))"
    declare -i lineIndex="$(floor $(divide ${width} ${windowWidth} 4))"
    if [[ ${lineCurrentIndex} -lt ${lineIndex} ]]; then
        # Erase the screen from the line below to the bottom of the screen
        tput sc
        tput cud1
        tput ed
        tput cuu1
        tput rc
    fi
    __printLine "$text"
}

##
# Replace current line by another
# @param int $1 Previous position
# @param int $2 Line
# @param int $3 Position
# @param int $4 Window width
# @return string
function __replaceLine ()
{
    declare -i charPrevIndex="$1"
    local text="$2"
    declare -i charIndex="$3"
    declare -i windowWidth="$4"

    __moveToStart ${charPrevIndex} ${windowWidth}
    # Erase the screen from the current line to the bottom of the screen
    tput ed
    __printLine "$text" 1
}

##
# Change content of the current line
# @param int $1 Position
# @param string $2 Text
# @param int $3 Increment
# @param int $4 Line width
# @param int $5 Window width
function __reformLine ()
{
    declare -i position="$1"
    local text="$2"
    declare -i increment="$3"
    declare -i width="$4"
    declare -i windowWidth="$5"

    # Manage end of line
    __printLineModification ${position} "$text" ${width} ${windowWidth}
    # Move cursor right
    if [[ ${increment} -gt 0 ]]; then
        tput cuf ${increment}
    fi
}

##
# Restore line and cursor position
# @param int $1 Position
# @param string $2 Text
# @param int $3 Line width
# @param int $4 Window width
function __restoreLine ()
{
    declare -i position="$1"
    local text="$2"
    declare -i width="$3"
    declare -i windowWidth="$4"

    __printLine "$text" 1
    __moveLineAndCursor ${width} ${position} ${windowWidth}
}

##
# Erase character to the left of the current position
# @param int $1 Position
# @param string $2 Text
# @param int $3 Line width
# @param int $4 Window width
function __reviseLine ()
{
    declare -i position="$1"
    local text="$2"
    declare -i width="$3"
    declare -i windowWidth="$4"

    # Move cursor left
    tput cub 1
    # Erase it
    tput ech 1
    # Manage end of line
    __printLineModification ${position} "$text" ${width} ${windowWidth}
}

##
# Read lines from the standard input and split it into fields.
# Manage history in file, completion with tab, navigation with arrow keys and backspace
# @see http://www.termsys.demon.co.uk/vtansi.htm
# @see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# @see https://www.gnu.org/software/termutils/manual/termutils-2.0/html_chapter/tput_1.html
#
# In order to find out a key combination
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
    windowWidth=$(windowSize "width")
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
        historySize=${#history[@]}
        historyIndex=${historySize}
    fi

    # Introduction messages
    declare -i promptSize="${#AWQL_PROMPT}"
    local prompt="${AWQL_PROMPT}"
    local promptNewLine="${AWQL_PROMPT_NEW_LINE}"

    # Launch prompt by sending introduction message
    echo -n "$prompt"

    # Read one character at a time
    local char rest
    declare -a read
    declare -i readLength=0
    declare -i readIndex=0
    declare -i charIndex=0
    declare -i charPrevIndex=0
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
        if [[ "$char" == $'\f' ]]; then
            # Clear the terminal (ctrl + l)
            __clearScreen
        elif [[ "$char" == $'\x1b[F' || "$char" == $'\x1b[H' || "$char" == $'\001' || "$char" == $'\005' ]]; then
            # Go to start (home) or end of the line (Fn or ctrl + left and right arrow keys)
            if [[ "$char" == $'\x1b[F' || "$char" == $'\005' ]]; then
                # Forward to end
                __moveLineAndCursor ${charIndex} ${readLength} ${windowWidth}
                charIndex=${readLength}
            else
                # Backward to start
                __moveLineAndCursor ${charIndex} 0 ${windowWidth}
                charIndex=0
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
            if [[ ${historyIndex} -lt ${historySize} ]]; then
                read["${readIndex}"]="${history["${historyIndex}"]}"
                readLength="${#read["${readIndex}"]}"
                charIndex="${readLength}"
                __replaceLine ${charPrevIndex} "${prompt}${read["${readIndex}"]}" ${charIndex} ${windowWidth}
            fi
        elif [[ "$char" == $'\x1b[C' || "$char" == $'\x1b[D' ]]; then
            # Moving char by char with left or right arrow keys
            if [[ "$char" == $'\x1b[C' && ${charIndex} -lt ${readLength} ]]; then
                # Right
                tput cuf1
                charIndex+=1
            elif [[ "$char" == $'\x1b[D' && ${charIndex} -gt 0 ]]; then
                # Left
                tput cub1
                charIndex+=-1
            else
                continue
            fi
        elif [[ "$char" == $'\177' || "$char" == $'\010' ]]; then
            # Backspace / Delete
            if [[ ${charIndex} -eq 0 ]]; then
                continue
            elif [[ ${charIndex} -eq ${readLength} ]]; then
                # Remove the last char
                rest=""
                read["${readIndex}"]="${read["${readIndex}"]%?}"
            else
                # Remove the char at the given index
                rest="${read["${readIndex}"]:${charIndex}}"
                read["${readIndex}"]="${read["${readIndex}"]::$((${charIndex}-1))}${rest}"
            fi
            __reviseLine  ${charIndex} "$rest" ${readLength} ${windowWidth}
            readLength+=-1
            charIndex+=-1
        elif [[ "$char" == $'\x09' ]]; then
            # Tabulation
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
                rest="${compReply[0]}${read["${readIndex}"]:$charIndex}"
                read["${readIndex}"]="${read["${readIndex}"]::$charIndex}${rest}"
                __reformLine ${charIndex} "$rest" ${compReplySize} ${readLength} ${windowWidth}
                readLength+=${compReplySize}
                charIndex+=${compReplySize}
            else
                # Various completions were found, go to new line to display it
                echo
                local displayAllCompletions="$(printf "${AWQL_COMPLETION_CONFIRM}" "${compReplyLength}")"
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
                __restoreLine ${charIndex} "${prompt}${read["${readIndex}"]}" ${readLength} ${windowWidth}
            fi
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
                        # Remove the old position in historic in order to put this line as the last played command
                        sed -e $((${historyIndex} + 1))d "$file" > "${file}-e" && mv "${file}-e" "$file"
                    fi
                    echo "$reply" >> "$file"
                fi
                # Go to new line to display response
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
            if [[ ${charIndex} -eq ${readLength} ]]; then
                read["${readIndex}"]+="$char"
                echo -n "$char"
            else
                rest="${char}${read["${readIndex}"]:$charIndex}"
                read["${readIndex}"]="${read["${readIndex}"]::$charIndex}${rest}"
                __reformLine ${charIndex} "$rest" 1 ${readLength} ${windowWidth}
            fi
            readLength+=1
            charIndex+=1
        fi
    done

    eval "${readerVarName}=\"${reply}\""
}