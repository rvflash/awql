#!/usr/bin/env bash

# @includeBy /inc/awql.sh

##
# Add informations about context of the query (time duration & number of lines)
# @example 2 rows in set (0.93 sec)
# @param string $1 AWQL filepath
# @param int $2 Number of elements in file
# @param float $3 Time duration in milliseconds to get the data
# @param string $4 Verbose mode
# @param bool $5 If 1, data source is cached
function printContext ()
{
    local FILE_PATH="$1"
    local FILE_SIZE="$2"
    local TIME_DURATION="$3"
    local VERBOSE="$4"
    local CACHED="$5"

    # Size
    local CONTEXT
    if [[ "$FILE_SIZE" -lt 2 ]]; then
        CONTEXT="Empty set"
    elif [[ "$FILE_SIZE" -eq 2 ]]; then
        CONTEXT="1 row in set"
    else
        CONTEXT="$(($FILE_SIZE-1)) rows in set"
    fi

    # Time duration
    if [[ -z "$TIME_DURATION" ]]; then
        TIME_DURATION="0.00"
    fi
    CONTEXT="$CONTEXT ($TIME_DURATION sec)"

    if [[ "$VERBOSE" -eq 1 ]]; then
        if [[ -n "$FILE_PATH" && -f "$FILE_PATH" ]]; then
            # Source
            CONTEXT="$CONTEXT @source $FILE_PATH"
            # From cache ?
            if [[ "$CACHED" -eq 1 ]]; then
                CONTEXT="$CONTEXT @cached"
            fi
        fi
    fi

    echo -en "$CONTEXT\n"
    echo
}

##
# Show response & info about it
# @param arrayToString $1 Request
# @param arrayToString $2 Response
# @param string $3 If given, path to save AWQL response
# @param string $4 Verbose mode
function print ()
{
    declare -A REQUEST="$1"
    declare -A RESPONSE="$2"
    local SAVE_FILE="$3"
    local VERBOSE="$4"

    local FILE_SIZE=0
    local FILE_PATH="${RESPONSE[FILE]}"
    if [[ -n "$FILE_PATH" && -f "$FILE_PATH" ]]; then
        declare -a LIMIT_QUERY=(${REQUEST[LIMIT]})
        declare -a ORDER_QUERY=(${REQUEST[ORDER]})
        local LIMIT_QUERY_SIZE=${#LIMIT_QUERY[@]}

        FILE_SIZE=$(wc -l < "$FILE_PATH")
        if [[ "$FILE_SIZE" -gt 1 ]]; then

            # Manage LIMIT queries
            if [[ "$LIMIT_QUERY_SIZE" -eq 1 || "$LIMIT_QUERY_SIZE" -eq 2 ]]; then
                # Limit size of datas to display (@see limit Adwords on daily report)
                local LIMITS="${LIMIT_QUERY[@]}"
                local WRK_PARTIAL_FILE="${FILE_PATH/.awql/_${LIMITS/ /-}.awql}"

                # Keep only first line for column names and lines in bounces
                if [[ ! -f "$WRK_PARTIAL_FILE" ]]; then
                    if [[ "$LIMIT_QUERY_SIZE" -eq 2 ]]; then
                        LIMITS="$((${LIMIT_QUERY[0]}+1)),$((${LIMIT_QUERY[0]}+${LIMIT_QUERY[1]}))"
                        sed -n -e 1p -e "${LIMITS}p" "$FILE_PATH" > "$WRK_PARTIAL_FILE"
                    else
                        LIMITS="1,$((${LIMIT_QUERY[0]}+1))"
                        sed -n -e "${LIMITS}p" "$FILE_PATH" > "$WRK_PARTIAL_FILE"
                    fi
                fi
                FILE_PATH="$WRK_PARTIAL_FILE"

                # Change file size
                if [[ "$LIMIT_QUERY_SIZE" -eq 2 ]]; then
                    FILE_SIZE="${LIMIT_QUERY[1]}"
                else
                    FILE_SIZE="${LIMIT_QUERY[0]}"
                fi
                FILE_SIZE="$((${FILE_SIZE}+1))"
            fi

            # Manage SORT ORDER queries
            if [[ "${#ORDER_QUERY[@]}" -ne 0 ]]; then
                local WRK_ORDERED_FILE="${FILE_PATH/.awql/_k${ORDER_QUERY[1]}-${ORDER_QUERY[2]}.awql}"
                if [[ ! -f "$WRK_ORDERED_FILE" ]]; then
                    local SORT_OPTIONS="-t, -k+${ORDER_QUERY[1]} -${ORDER_QUERY[0]}"
                    if [[ "${ORDER_QUERY[2]}" -eq "$AWQL_SORT_ORDER_DESC" ]]; then
                        SORT_OPTIONS+=" -r"
                    fi
                    head -1 "$FILE_PATH" > "$WRK_ORDERED_FILE"
                    sed 1d "$FILE_PATH" | sort ${SORT_OPTIONS} >> "$WRK_ORDERED_FILE"
                fi
                FILE_PATH="$WRK_ORDERED_FILE"
            fi

            # Format CVS to print it in shell terminal
            local CVS_OPTIONS
            if [[ "${REQUEST[VERTICAL_MODE]}" -eq 1 ]]; then
                CVS_OPTIONS="-g"
            fi
            echo -e "$(${AWQL_CSV_TOOL_FILE} ${CVS_OPTIONS} -f "$FILE_PATH")"

            # Save response in an dedicated file
            if [[ -n "$SAVE_FILE" ]]; then
                cat "$FILE_PATH" >> "$SAVE_FILE"
                if exitOnError $? "FileError.UNABLE_TO_SAVE_IN_FILE" "$VERBOSE"; then
                    return 1
                fi
            fi
        fi
    fi

    # Add context (file size, time duration, etc.)
    printContext "$FILE_PATH" "$FILE_SIZE" "${RESPONSE[TIME_DURATION]}" "$VERBOSE" "${RESPONSE[CACHED]}"
}