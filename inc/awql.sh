#!/usr/bin/env bash

declare AWQL_EXTRA AWQL_FIELDS AWQL_BLACKLISTED_FIELDS AWQL_UNCOMPATIBLE_FIELDS AWQL_KEYS AWQL_TABLES AWQL_TABLES_TYPE

##
# Get all field names with for each, their description
# @example ([AccountDescriptiveName]="The descriptive name...")
# @use AWQL_EXTRA
function awqlExtra ()
{
    if [[ -z "$AWQL_EXTRA" ]]; then
        AWQL_EXTRA=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_EXTRA_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_EXTRA_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_EXTRA"
}

##
# Get all fields names with for each, the type of data
# @example ([AccountDescriptiveName]="String")
# @use AWQL_FIELDS
function awqlFields ()
{
    if [[ -z "$AWQL_FIELDS" ]]; then
        AWQL_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_FIELDS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_FIELDS"
}

##
# Get all table names with for each, the list of their blacklisted fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
# @use AWQL_BLACKLISTED_FIELDS
function awqlBlacklistedFields ()
{
    if [[ -z "$AWQL_BLACKLISTED_FIELDS" ]]; then
        AWQL_BLACKLISTED_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_BLACKLISTED_FIELDS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_BLACKLISTED_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_BLACKLISTED_FIELDS"
}

##
# Get all fields names with for each, the list of their incompatible fields
# @example ([AccountDescriptiveName]="Hour")
# @use AWQL_UNCOMPATIBLE_FIELDS
function awqlUncompatibleFields ()
{
    local TABLE="$1"

    if [[ -z "$AWQL_UNCOMPATIBLE_FIELDS" ]]; then
        AWQL_UNCOMPATIBLE_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_COMPATIBILITY_DIR_NAME}/${TABLE}.yaml")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_UNCOMPATIBLE_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_UNCOMPATIBLE_FIELDS"
}

##
# Get all table names with for each, their structuring keys
# @example ([PRODUCT_PARTITION_REPORT]="ClickType Date...")
# @use AWQL_KEYS
function awqlKeys ()
{
    if [[ -z "$AWQL_KEYS" ]]; then
        AWQL_KEYS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_KEYS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_KEYS"
            return 1
        fi
    fi
    echo -n "$AWQL_KEYS"
}

##
# Get all table names with for each, the list of their fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
# @use AWQL_TABLES
function awqlTables ()
{
    if [[ -z "$AWQL_TABLES" ]]; then
        AWQL_TABLES=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_TABLES_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_TABLES"
            return 1
        fi
    fi
    echo -n "$AWQL_TABLES"
}

##
# Get all table names with for each, their type
# @example ([PRODUCT_PARTITION_REPORT]="SHOPPING")
# @use AWQL_TABLES_TYPE
function awqlTablesType ()
{
    if [[ -z "$AWQL_TABLES_TYPE" ]]; then
        AWQL_TABLES_TYPE=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_TABLES_TYPE_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_TABLES_TYPE"
            return 1
        fi
    fi
    echo -n "$AWQL_TABLES_TYPE"
}

##
# Get data from cache if available
# @param string $1 FilePath
# @param string $2 Caching enabled
function getFromCache ()
{
    local FILE="$1"
    local CACHING="$2"

    if [[ "$CACHING" -eq 0 ]]; then
        echo "CacheError.DISABLED"
        return 1
    elif [[ ! -f "$FILE" ]]; then
        echo "CacheError.UNKNOWN_KEY"
        return 1
    fi

    echo -n "([FILE]=\"${FILE}\" [CACHED]=1)"
}

##
# Fetch internal cache or send request to Adwords to get results
# @param string $1 Adwords ID
# @param arrayToString $2 User request
# @param array $3 Google authentification tokens
# @param array $4 Google request properties
# @param array $5 Verbose mode
# @param array $6 Enable caching
function get ()
{
    # In
    local ADWORDS_ID="$1"
    declare -A REQUEST="$2"
    local AUTH="$3"
    local SERVER="$4"
    local VERBOSE="$5"
    local CACHING="$6"

    # Out
    local FILE="${AWQL_WRK_DIR}/${REQUEST[CHECKSUM]}${AWQL_FILE_EXT}"

    # Overload caching mode for local database AWQL methods
    if [[ "${REQUEST[METHOD]}" != ${AWQL_QUERY_SELECT} ]]; then
        CACHING=1
    fi

    local RESPONSE=""
    RESPONSE=$(getFromCache "$FILE" "$CACHING")
    local ERR_TYPE=$?
    if [[ "$ERR_TYPE" -ne 0 ]]; then
        case "${REQUEST[METHOD]}" in
            ${AWQL_QUERY_SELECT})
                source "${AWQL_INC_DIR}/awql_select.sh"
                RESPONSE=$(awqlSelect "$ADWORDS_ID" "$AUTH" "$SERVER" "${REQUEST[QUERY]}" "$FILE" "$VERBOSE")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_DESC})
                source "${AWQL_INC_DIR}/awql_desc.sh"
                RESPONSE=$(awqlDesc "${REQUEST[QUERY]}" "$FILE")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_SHOW})
                source "${AWQL_INC_DIR}/awql_show.sh"
                RESPONSE=$(awqlShow "${REQUEST[QUERY]}" "$FILE")
                ERR_TYPE=$?
                ;;
            *)
                RESPONSE="QueryError.UNKNOWN_AWQL_METHOD"
                ERR_TYPE=2
                ;;
        esac

        # An error occured, remove cache file and return with error code
        if [[ "$ERR_TYPE" -ne 0 ]]; then
            # @see command protected by /dev/null exit
            if [[ -z "$RESPONSE" ]]; then
                RESPONSE="QueryError.AWQL_SYNTAX_ERROR"
                ERR_TYPE=2
            fi
            rm -f "$FILE"
        fi
    fi

    echo "$RESPONSE"

    return "$ERR_TYPE"
}

##
# Build a call to Google Adwords and retrieve report for the AWQL query
# @param string $1 Query
# @param string $2 Adwords ID
# @param string $3 Google Access Token
# @param string $4 Google Developer Token
# @param arrayToString $5 Google request configuration
# @param string $6 Save file path
# @param int $7 Cachine mode
# @param int $8 Verbose mode
function awql ()
{
    local QUERY="$1"
    local ADWORDS_ID="$2"
    local ACCESS_TOKEN="$3"
    local DEVELOPER_TOKEN="$4"
    local REQUEST="$5"
    local SAVE_FILE="$6"
    local VERBOSE="$7"
    local CACHING="$8"

    # Prepare and validate query, manage all extended behaviors to AWQL basics
    QUERY=$(query "$ADWORDS_ID" "$QUERY")
    if exitOnError "$?" "$QUERY" "$VERBOSE"; then
        return 1
    fi

    # Retrieve Google tokens (only if HTTP call is needed)
    local AUTH
    if [[ "$QUERY" == *"\"select\""* ]]; then
        AUTH=$(auth "$ACCESS_TOKEN" "$DEVELOPER_TOKEN")
        if exitOnError "$?" "$AUTH" "$VERBOSE"; then
            return 1
        fi
    fi

    # Send request to Adwords or local cache to get report
    local RESPONSE
    RESPONSE=$(get "$ADWORDS_ID" "$QUERY" "$AUTH" "$REQUEST" "$VERBOSE" "$CACHING")
    if exitOnError "$?" "$RESPONSE" "$VERBOSE"; then
        return 1
    fi

    # Print response
    print "$QUERY" "$RESPONSE" "$SAVE_FILE" "$VERBOSE"
}

##
# Read user prompt to retrieve AWQL query.
# Enable up and down arrow keys to navigate in history of queries.
# @param string $1 Adwords ID
# @param string $2 Google Access Token
# @param string $3 Google Developer Token
# @param arrayToString $4 Google request configuration
# @param string $5 Save file path
# @param int $6 Cachine mode
# @param int $7 Verbose mode
# @param int $8 Auto rehash for completion
function awqlRead ()
{
    local ADWORDS_ID="$1"
    local ACCESS_TOKEN="$2"
    local DEVELOPER_TOKEN="$3"
    local REQUEST="$4"
    local SAVE_FILE="$5"
    local VERBOSE="$6"
    local CACHING="$7"

    # Auto completion
    local AUTO_REHASH="$8"
    local COMPREPLY

    # Get AWQL history file in an array
    local HISTORY=()
    if [[ -f "$AWQL_HISTORY_FILE" ]]; then
        mapfile -t HISTORY < "$AWQL_HISTORY_FILE"
    fi
    declare -i HISTORY_SIZE="${#HISTORY[@]}"
    declare -i HISTORY_INDEX="$HISTORY_SIZE"

    # Launch prompt by sending introducion message
    local PROMPT="$AWQL_PROMPT"
    echo -n "$PROMPT"

    # Read one character at a time
    local QUERY_STRING
    declare -a QUERY
    declare -i QUERY_LENGTH
    declare -i QUERY_INDEX
    declare -i CHAR_INDEX
    local CHAR=""
    while IFS="" read -rsn1 CHAR; do
        # \x1b is the start of an escape sequence == \033
        if [[ "$CHAR" == $'\x1b' ]]; then
            # Get the rest of the escape sequence (3 characters total)
            while IFS= read -rsn2 REST; do
                CHAR+="$REST"
                break
            done
        fi

        # @todo Manage moving word by word (alt + left and right arrow keys) // Forward-word and Backward-word

        if [[ "$CHAR" == $'\x1b[F' || "$CHAR" == $'\x1b[H' ]]; then
            # Go to start (home) or end of the line (Fn or ctrl + left and right arrow keys)
            if [[ "$CHAR" == $'\x1b[F' ]]; then
                # Forward to end
                CHAR_INDEX="$QUERY_LENGTH"
            else
                # Backward to start
                CHAR_INDEX=0
            fi
            # Move the cursor
            echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
        elif [[ "$CHAR" == $'\x1b[A' || "$CHAR" == $'\x1b[B' ]]; then
            # Navigate in history with up and down arrow keys
            if [[ "$CHAR" == $'\x1b[A' && "$HISTORY_INDEX" -gt 0 ]];then
                # Up
                HISTORY_INDEX+=-1
            elif [[ "$CHAR" == $'\x1b[B' && "$HISTORY_INDEX" -lt "$HISTORY_SIZE" ]]; then
                # Down
                HISTORY_INDEX+=1
            fi
            if [[ "$HISTORY_INDEX" -ne "$HISTORY_SIZE" && "$QUERY_INDEX" -eq 0 ]]; then
                # Remove current line and replace it by this from historic
                QUERY[$QUERY_INDEX]="${HISTORY[$HISTORY_INDEX]}"
                QUERY_LENGTH="${#QUERY[$QUERY_INDEX]}"
                CHAR_INDEX="$QUERY_LENGTH"
                echo -ne "\r\033[K${PROMPT}"
                echo -n "${QUERY[$QUERY_INDEX]}"
            fi
        elif [[ "$CHAR" == $'\x1b[C' || "$CHAR" == $'\x1b[D' ]]; then
            # Moving by char in current query with left and right arrow keys
            if [[ "$CHAR" == $'\x1b[C' && "$CHAR_INDEX" -lt "$QUERY_LENGTH" ]]; then
                # Right
                CHAR_INDEX+=1
            elif [[ "$CHAR" == $'\x1b[D' && "$CHAR_INDEX" -gt 0 ]]; then
                # Left
                CHAR_INDEX+=-1
            fi
            # Move the cursor
            echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
        elif [[ "$CHAR" == $'\177' ]]; then
            # Backspace (@see $'\010' to delete char ?)
            if [[ "$CHAR_INDEX" -gt 0 ]]; then
                if [[ "$CHAR_INDEX" -eq "$QUERY_LENGTH" ]]; then
                    QUERY[$QUERY_INDEX]="${QUERY[$QUERY_INDEX]%?}"
                else
                    QUERY[$QUERY_INDEX]="${QUERY[$QUERY_INDEX]::$(($CHAR_INDEX-1))}${QUERY[$QUERY_INDEX]:$CHAR_INDEX}"
                fi
                QUERY_LENGTH+=-1
                CHAR_INDEX+=-1

                # Remove the char as requested
                echo -ne "\r\033[K${PROMPT}"
                echo -n "${QUERY[$QUERY_INDEX]}"
                # Move the cursor
                echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
            fi
        elif [[ "$CHAR" == $'\x09' ]]; then
            # Tabulation
            if [[ "$AUTO_REHASH" -eq 1 ]]; then
                QUERY_STRING="${QUERY[@]}"
                QUERY_STRING="${QUERY_STRING:0:$CHAR_INDEX}"

                COMPREPLY=$(completion "${QUERY_STRING}")
                if [[ $? -eq 0 ]]; then
                    IFS=' ' read -a COMPREPLY <<< "${COMPREPLY}"
                    declare -i COMPREPLY_LENGTH="${#COMPREPLY[@]}"
                    if [[ "${COMPREPLY_LENGTH}" -eq 1 ]]; then
                        # A completed word was found
                        QUERY[$QUERY_INDEX]+="${COMPREPLY[0]}"
                        QUERY_LENGTH+=${#COMPREPLY[0]}
                        CHAR_INDEX+=${#COMPREPLY[0]}
                    else
                        # Various completed words were found
                        # Go to new line to display propositions
                        echo
                        local DISPLAY_ALL_COMPLETIONS="$(printf "${AWQL_COMPLETION_CONFIRM}" "${COMPREPLY_LENGTH}")"
                        if confirm "$DISPLAY_ALL_COMPLETIONS" "$AWQL_CONFIRM"; then
                            # Display in 3 columns
                            declare -i WINDOW_WIDTH=$(windowSize "width")
                            declare -i COLUMN_SIZE=50
                            declare -i COLUMN_NB="$(($WINDOW_WIDTH/$COLUMN_SIZE))"

                            declare -i I
                            for ((I=0; I < ${COMPREPLY_LENGTH}; I++)); do
                                if [[ $(( $I%$COLUMN_NB )) == 0 ]]; then
                                    echo
                                fi
                                printLeftPad "${COMPREPLY[$I]}" "$COLUMN_SIZE"
                            done
                        fi
                    fi
                    # Reset prompt and display query with new char
                    echo -ne "\r\033[K${PROMPT}"
                    echo -n "${QUERY[$QUERY_INDEX]}"
                    # Move the cursor
                    echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
                fi
            fi
        elif [[ -z "$CHAR" ]]; then
            # Enter
            QUERY_STRING="${QUERY[@]}"
            QUERY_STRING="$(trim "$QUERY_STRING")"
            if [[ -z "$QUERY_STRING" ]]; then
                # Empty lines
                echo
                break
            elif [[ "$QUERY_STRING" == *";" || "$QUERY_STRING" == *"\\"[gG] ]]; then
                # Query ending
                if [[ "$HISTORY_INDEX" -lt "$HISTORY_SIZE" ]]; then
                    # Remove the old position in historic in order to put this query as the last query played
                    sed -i -e $((${HISTORY_INDEX} + 1))d "$AWQL_HISTORY_FILE"
                fi
                # Add query in history
                echo "$QUERY_STRING" >> "$AWQL_HISTORY_FILE"
                # Go to new line to display response
                echo
                break
            elif [[  "$QUERY_STRING" == *"\\"[${AWQL_COMMAND_CLEAR}${AWQL_COMMAND_HELP}${AWQL_COMMAND_EXIT}] ]]; then
                # Awql commands shortcut
                case "${QUERY_STRING: -1}" in
                    ${AWQL_COMMAND_CLEAR}) QUERY_STRING="" ;;
                    ${AWQL_COMMAND_HELP}) QUERY_STRING="${AWQL_TEXT_COMMAND_HELP}" ;;
                    ${AWQL_COMMAND_EXIT}) QUERY_STRING="${AWQL_TEXT_COMMAND_EXIT}" ;;
                esac
                # Go to new line to display response
                echo
                break
            else
                # Newline
                PROMPT="$AWQL_PROMPT_NEW_LINE"
                QUERY_INDEX+=1
                QUERY_LENGTH=0
                CHAR_INDEX=0
                echo
                echo -n "$PROMPT"
            fi
        else
            # Writting
            if [[ "$CHAR_INDEX" -eq "$QUERY_LENGTH" ]]; then
                QUERY[$QUERY_INDEX]+="$CHAR"
            else
                QUERY[$QUERY_INDEX]="${QUERY[$QUERY_INDEX]::$CHAR_INDEX}${CHAR}${QUERY[$QUERY_INDEX]:$CHAR_INDEX}"
            fi
            QUERY_LENGTH+=1
            CHAR_INDEX+=1

            # Reset prompt and display query with new char
            echo -ne "\r\033[K${PROMPT}"
            echo -n "${QUERY[$QUERY_INDEX]}"
            # Move the cursor
            echo -ne "\r\033[$((${CHAR_INDEX}+${#PROMPT}))C"
        fi
    done

    # Process query
    awql "$QUERY_STRING" "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$REQUEST" "$SAVE_FILE" "$VERBOSE" "$CACHING"
}