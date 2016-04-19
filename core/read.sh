#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
fi


##
# Read lines from the standard input and split it into fields.
# Manage history in file, completion with tab, navigation with arrow keys and backspace
#
# # pager ?
# http://superuser.com/questions/848516/long-commands-typed-in-bash-overwrite-the-same-line
# echo "set horizontal-scroll-mode off" >> ~/.inputrc
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
    while IFS="" read -rsn1 char; do
        # \x1b is the start of an escape sequence == \033
        if [[ "$char" == $'\x1b' ]]; then
            # Get the rest of the escape sequence (3 characters total)
            while IFS= read -rsn2 rest; do
                char+="$rest"
                break
            done
        fi

        if [[ "$char" == $'\f' ]]; then
            # Clear the terminal (ctrl + l)
            echo -ne "\r\033c${prompt}"
        elif [[ "$char" == $'\x1b[F' || "$char" == $'\x1b[H' || "$char" == $'\001' || "$char" == $'\005' ]]; then
            # Go to start (home) or end of the line (Fn or ctrl + left and right arrow keys)
            if [[ "$char" == $'\x1b[F' || "$char" == $'\005' ]]; then
                # Forward to end
                charIndex=${readLength}
            else
                # Backward to start
                charIndex=0
            fi
            # Move the cursor
            echo -ne "\r\033[$((${charIndex}+${#prompt}))C"
        elif [[ "$char" == $'\x1b[A' || "$char" == $'\x1b[B' ]]; then
            if [[ -n "$file" ]]; then
                # Navigate in history with up and down arrow keys
                if [[ "$char" == $'\x1b[A' && ${historyIndex} -gt 0 ]];then
                    # Up
                    historyIndex+=-1
                elif [[ "$char" == $'\x1b[B' && ${historyIndex} -lt ${historySize} ]]; then
                    # Down
                    historyIndex+=1
                fi
                if [[ ${historyIndex} -ne ${historySize} && ${readIndex} -eq 0 ]]; then
                    # Remove current line and replace it by this from historic
                    read[${readIndex}]=${history[${historyIndex}]}
                    readLength=${#read[${readIndex}]}
                    charIndex=${readLength}
                    # Reset prompt and display historic reply
                    echo -ne "\r\033[K${prompt}"
                    echo -n "${read[${readIndex}]}"
                fi
            fi
        elif [[ "$char" == $'\x1b[C' || "$char" == $'\x1b[D' ]]; then
            # Moving char by char with left or right arrow keys
            if [[ "$char" == $'\x1b[C' && ${charIndex} -lt ${readLength} ]]; then
                # Right
                charIndex+=1
            elif [[ "$char" == $'\x1b[D' && ${charIndex} -gt 0 ]]; then
                # Left
                charIndex+=-1
            fi
            # Only move the cursor
            echo -ne "\r\033[$((${charIndex}+${#prompt}))C"
        elif [[ "$char" == $'\177' || "$char" == $'\010' ]]; then
            # Backspace / Delete
            if [[ ${charIndex} -gt 0 ]]; then
                if [[ ${charIndex} -eq ${readLength} ]]; then
                    read[${readIndex}]="${read[${readIndex}]%?}"
                else
                    read[${readIndex}]="${read[${readIndex}]::$((${charIndex}-1))}${read[${readIndex}]:${charIndex}}"
                fi
                readLength+=-1
                charIndex+=-1
                # Remove the char as requested
                echo -ne "\r\033[K${prompt}"
                echo -n "${read[${readIndex}]}"
                # Reposition the cursor
                echo -ne "\r\033[$((${charIndex}+${#prompt}))C"
            fi
        elif [[ "$char" == $'\x09' ]]; then
            # Tabulation
            if [[ ${autoRehash} -eq 1 ]]; then
                reply="${read[@]}"
                reply="${reply:0:${charIndex}}"

                compReply=$(awqlComplete "$reply" "$apiVersion")
                if [[ $? -eq 0 ]]; then
                    IFS=' ' read -a compReply <<< "$compReply"
                    declare -i compReplyLength=${#compReply[@]}
                    if [[ ${compReplyLength} -eq 1 ]]; then
                        # A completed word was found
                        read[${readIndex}]+="${compReply[0]}"
                        readLength+=${#compReply[0]}
                        charIndex+=${#compReply[0]}
                    else
                        # Various completed words were found
                        # Go to new line to display propositions
                        echo
                        local displayAllCompletions="$(printf "${AWQL_COMPLETION_CONFIRM}" "${compReplyLength}")"
                        if confirm "$displayAllCompletions" "${AWQL_CONFIRM}"; then
                            # Display in columns
                            declare -i columnSize=50
                            declare -i columnNb="$((${windowWidth}/${columnSize}))"
                            declare -i compReplyIndex
                            for ((compReplyIndex=0; I < ${compReplyLength}; I++)); do
                                if [[ $(( ${compReplyIndex}%${columnNb} )) == 0 ]]; then
                                    echo
                                fi
                                printLeftPadding "${compReply[${compReplyIndex}]}" ${columnSize}
                            done
                        fi
                    fi
                    # Reset prompt and display line with new char
                    echo -ne "\r\033[K${prompt}"
                    echo -n "${read[$readIndex]}"
                    # Move the cursor
                    echo -ne "\r\033[$((${charIndex}+${#prompt}))C"
                fi
            fi
        elif [[ -z "$char" ]]; then
            # Enter
            reply="${read[@]}"
            reply="$(trim "$reply")"
            if [[ -z "$reply" ]]; then
                # Empty lines
                echo
                break
            elif [[ "$reply" == *";" || "$reply" == *"\\"[gG] ]]; then
                # Query ending
                if [[ -n "$file" ]]; then
                    # Add line in history
                    if [[ "${historyIndex}" -lt "$historySize" ]]; then
                        # Remove the old position in historic in order to put this line as the last command played
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
                    ${AWQL_COMMAND_CLEAR}) reply="" ;;
                    ${AWQL_COMMAND_HELP})  reply="${AWQL_TEXT_COMMAND_HELP}" ;;
                    ${AWQL_COMMAND_EXIT})  reply="${AWQL_TEXT_COMMAND_EXIT}" ;;
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
            # Manage terminal ending
            if [[ $((${charIndex} + ${#prompt} + 1)) -gt "${windowWidth}" ]]; then
                prompt="$promptNewLine"
                readIndex+=1
                readLength=0
                charIndex=0
                echo
                echo -n "$prompt"
            fi
            # Write only printable chars
            if [[ ${charIndex} -eq ${readLength} ]]; then
                read[${readIndex}]+="$char"
                # Add this char ...
                echo -n "$char"
            else
                read[${readIndex}]="${read[$readIndex]::$charIndex}${char}${read[$readIndex]:$charIndex}"
                # Reset prompt and display line with new char
                echo -ne "\r\033[K${prompt}"
                echo -n "${read[$readIndex]}"
                # Reposition the cursor
                echo -ne "\r\033[$((${charIndex}+${#prompt}+1))C"
            fi
            readLength+=1
            charIndex+=1
        fi
    done

    eval "${readerVarName}=\"${reply}\""
}