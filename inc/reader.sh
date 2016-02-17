#!/usr/bin/env bash

# @includeBy /awql.sh

##
# Read lines from the standard input and split it into fields.
# Manage history in file, completion with tab, navigation with arrow keys and backspace
#
# # pager ?
# http://superuser.com/questions/848516/long-commands-typed-in-bash-overwrite-the-same-line
# echo "set horizontal-scroll-mode off" >> ~/.inputrc
#
# In order to identify witch code for each key, use command: sed -n l
# @param string $1 OutpitVarName
# @param int $2 Auto-rehash
# @param string $3 Api version
# @return void
function reader ()
{
    # Variable name use to export the response of prompt
    local READER_VAR_NAME="$1"
    local REPLY
    # Completion
    declare -i AUTO_REHASH="$2"
    local COMPREPLY
    local API_VERSION="$3"

    # Terminal size
    declare -i WINDOW_WIDTH
    WINDOW_WIDTH=$(windowSize "width")
    exitOnError "$?" "InternalError.USE_ONLY_IN_TERMINAL";

    # History file
    local HISTORY_FILE="${AWQL_HISTORY_FILE}"
    if [[ -n "$HISTORY_FILE" ]]; then
        declare -a HISTORY=()
        if [[ -f "$HISTORY_FILE" ]]; then
            mapfile -t HISTORY < "$HISTORY_FILE"
        fi
        declare -i HISTORY_SIZE=${#HISTORY[@]}
        declare -i HISTORY_INDEX=${HISTORY_SIZE}
    fi

    # Introduction messages
    local PROMPT="${AWQL_PROMPT}"
    local PROMPT_NEW_LINE="${AWQL_PROMPT_NEW_LINE}"

    # Launch prompt by sending introducion message
    echo -n "$PROMPT"

    # Read one character at a time
    declare -a READ
    declare -i READ_LENGTH=0
    declare -i READ_INDEX=0
    declare -i CHAR_INDEX=0
    while IFS="" read -rsn1 CHAR; do
        # \x1b is the start of an escape sequence == \033
        if [[ "$CHAR" == $'\x1b' ]]; then
            # Get the rest of the escape sequence (3 characters total)
            while IFS= read -rsn2 REST; do
                CHAR+="$REST"
                break
            done
        fi

        if [[ "$CHAR" == $'\f' ]]; then
            # Clear the terminal (ctrl + l)
            echo -ne "\r\033c${PROMPT}"
        elif [[ "$CHAR" == $'\x1b[F' || "$CHAR" == $'\x1b[H' || "$CHAR" == $'\001' || "$CHAR" == $'\005' ]]; then
            # Go to start (home) or end of the line (Fn or ctrl + left and right arrow keys)
            if [[ "$CHAR" == $'\x1b[F' || "$CHAR" == $'\005' ]]; then
                # Forward to end
                CHAR_INDEX="$READ_LENGTH"
            else
                # Backward to start
                CHAR_INDEX=0
            fi
            # Move the cursor
            echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
        elif [[ "$CHAR" == $'\x1b[A' || "$CHAR" == $'\x1b[B' ]]; then
            if [[ -n "$HISTORY_FILE" ]]; then
                # Navigate in history with up and down arrow keys
                if [[ "$CHAR" == $'\x1b[A' && "$HISTORY_INDEX" -gt 0 ]];then
                    # Up
                    HISTORY_INDEX+=-1
                elif [[ "$CHAR" == $'\x1b[B' && "$HISTORY_INDEX" -lt "$HISTORY_SIZE" ]]; then
                    # Down
                    HISTORY_INDEX+=1
                fi
                if [[ "$HISTORY_INDEX" -ne "$HISTORY_SIZE" && "$READ_INDEX" -eq 0 ]]; then
                    # Remove current line and replace it by this from historic
                    READ["$READ_INDEX"]="${HISTORY[$HISTORY_INDEX]}"
                    READ_LENGTH="${#READ[$READ_INDEX]}"
                    CHAR_INDEX="$READ_LENGTH"
                    # Reset prompt and display historic reply
                    echo -ne "\r\033[K${PROMPT}"
                    echo -n "${READ[$READ_INDEX]}"
                fi
            fi
        elif [[ "$CHAR" == $'\x1b[C' || "$CHAR" == $'\x1b[D' ]]; then
            # Moving char by char with left or right arrow keys
            if [[ "$CHAR" == $'\x1b[C' && "$CHAR_INDEX" -lt "$READ_LENGTH" ]]; then
                # Right
                CHAR_INDEX+=1
            elif [[ "$CHAR" == $'\x1b[D' && "$CHAR_INDEX" -gt 0 ]]; then
                # Left
                CHAR_INDEX+=-1
            fi
            # Only move the cursor
            echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
        elif [[ "$CHAR" == $'\177' || "$CHAR" == $'\010' ]]; then
            # Backspace / Delete
            if [[ "$CHAR_INDEX" -gt 0 ]]; then
                if [[ "$CHAR_INDEX" -eq "$READ_LENGTH" ]]; then
                    READ["$READ_INDEX"]="${READ[$READ_INDEX]%?}"
                else
                    READ["$READ_INDEX"]="${READ[$READ_INDEX]::$(($CHAR_INDEX-1))}${READ[$READ_INDEX]:$CHAR_INDEX}"
                fi
                READ_LENGTH+=-1
                CHAR_INDEX+=-1
                # Remove the char as requested
                echo -ne "\r\033[K${PROMPT}"
                echo -n "${READ[$READ_INDEX]}"
                # Reposition the cursor
                echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
            fi
        elif [[ "$CHAR" == $'\x09' ]]; then
            # Tabulation
            if [[ "$AUTO_REHASH" -eq 1 ]]; then
                REPLY="${READ[@]}"
                REPLY="${REPLY:0:$CHAR_INDEX}"

                COMPREPLY=$(completion "${REPLY}" "${API_VERSION}")
                if [[ $? -eq 0 ]]; then
                    IFS=' ' read -a COMPREPLY <<< "${COMPREPLY}"
                    declare -i COMPREPLY_LENGTH="${#COMPREPLY[@]}"
                    if [[ "${COMPREPLY_LENGTH}" -eq 1 ]]; then
                        # A completed word was found
                        READ[$READ_INDEX]+="${COMPREPLY[0]}"
                        READ_LENGTH+=${#COMPREPLY[0]}
                        CHAR_INDEX+=${#COMPREPLY[0]}
                    else
                        # Various completed words were found
                        # Go to new line to display propositions
                        echo
                        local DISPLAY_ALL_COMPLETIONS="$(printf "${AWQL_COMPLETION_CONFIRM}" "${COMPREPLY_LENGTH}")"
                        if confirm "$DISPLAY_ALL_COMPLETIONS" "$AWQL_CONFIRM"; then
                            # Display in columns
                            declare -i COLUMN_SIZE=50
                            declare -i COLUMN_NB="$((${WINDOW_WIDTH}/${COLUMN_SIZE}))"
                            declare -i I
                            for ((I=0; I < ${COMPREPLY_LENGTH}; I++)); do
                                if [[ $(( $I%$COLUMN_NB )) == 0 ]]; then
                                    echo
                                fi
                                printLeftPad "${COMPREPLY[$I]}" "$COLUMN_SIZE"
                            done
                        fi
                    fi
                    # Reset prompt and display line with new char
                    echo -ne "\r\033[K${PROMPT}"
                    echo -n "${READ[$READ_INDEX]}"
                    # Move the cursor
                    echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
                fi
            fi
        elif [[ -z "$CHAR" ]]; then
            # Enter
            REPLY="${READ[@]}"
            REPLY="$(trim "$REPLY")"
            if [[ -z "$REPLY" ]]; then
                # Empty lines
                echo
                break
            elif [[ "$REPLY" == *";" || "$REPLY" == *"\\"[gG] ]]; then
                # Query ending
                if [[ -n "$HISTORY_FILE" ]]; then
                    # Add line in history
                    if [[ "$HISTORY_INDEX" -lt "$HISTORY_SIZE" ]]; then
                        # Remove the old position in historic in order to put this line as the last command played
                        sed -i -e $((${HISTORY_INDEX} + 1))d "$HISTORY_FILE"
                    fi
                    echo "$REPLY" >> "$HISTORY_FILE"
                fi
                # Go to new line to display response
                echo
                break
            elif [[  "$REPLY" == *"\\"[${AWQL_COMMAND_CLEAR}${AWQL_COMMAND_HELP}${AWQL_COMMAND_EXIT}] ]]; then
                # Awql commands shortcut
                case "${REPLY: -1}" in
                    ${AWQL_COMMAND_CLEAR}) REPLY="" ;;
                    ${AWQL_COMMAND_HELP})  REPLY="${AWQL_TEXT_COMMAND_HELP}" ;;
                    ${AWQL_COMMAND_EXIT})  REPLY="${AWQL_TEXT_COMMAND_EXIT}" ;;
                esac
                # Go to new line to display response
                echo
                break
            else
                # Newline!
                PROMPT="$PROMPT_NEW_LINE"
                READ_INDEX+=1
                READ_LENGTH=0
                CHAR_INDEX=0
                echo
                echo -n "$PROMPT"
            fi
        elif [[ "$CHAR" == [[:print:]] ]]; then
            # Manage terminal ending
            if [[ "$((${CHAR_INDEX}+${#PROMPT}+1))" -gt "${WINDOW_WIDTH}" ]]; then
                PROMPT="$PROMPT_NEW_LINE"
                READ_INDEX+=1
                READ_LENGTH=0
                CHAR_INDEX=0
                echo
                echo -n "$PROMPT"
            fi
            # Write only printable chars
            if [[ "$CHAR_INDEX" -eq "$READ_LENGTH" ]]; then
                READ["$READ_INDEX"]+="$CHAR"
                # Add this char ...
                echo -n "$CHAR"
            else
                READ["$READ_INDEX"]="${READ[$READ_INDEX]::$CHAR_INDEX}${CHAR}${READ[$READ_INDEX]:$CHAR_INDEX}"
                # Reset prompt and display line with new char
                echo -ne "\r\033[K${PROMPT}"
                echo -n "${READ[$READ_INDEX]}"
                # Reposition the cursor
                echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}+1))C"
            fi
            READ_LENGTH+=1
            CHAR_INDEX+=1
        fi
    done

    eval "${READER_VAR_NAME}=\"${REPLY}\""
}