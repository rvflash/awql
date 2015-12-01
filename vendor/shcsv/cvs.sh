#!/usr/bin/env bash

##
# Print a CVS file in Shell with readable columns and lines like Mysql command line

declare -r SPACE_CHAR="§"

##
# @param string $1 CVS filepath
# @print Print CVS files in order to view it in shell
function csvToPrintableArray ()
{
    local CSV_FILE="$1"
    if [ -z "$CSV_FILE" ] || [ ! -f "$CSV_FILE" ]; then
        return 1
    fi

    # Formats its input into multiple columns, ignore empty lines
    local CSV=$(cat "$CSV_FILE" | sed -e "s/,$/,${SPACE_CHAR}/g" | sed -e "s/,,/, ,/g" | column -s, -t)
    local CSV_HEAD=$(echo "$CSV" | head -1)
    local CSV_NB_LINE=$(echo "$CSV" | wc -l)

    # Parse header in order to build schema
    declare -a COLUMN_SIZE
    local COLUMN_NB=1
    local NEW_COLUMN=0

    # Base on first line, build structure of array
    while read -r -n1 LETTER; do
        if [ "${#COLUMN_SIZE[@]}" -eq 0 ]; then
            COLUMN_SIZE[$COLUMN_NB]=1
        elif [ "$LETTER" != "" ] && [ "$NEW_COLUMN" -gt 1 ]; then
            (( COLUMN_NB++ ))
            COLUMN_SIZE[$COLUMN_NB]=1
            NEW_COLUMN=0
        else
            if [ "$LETTER" = "" ]; then
                (( NEW_COLUMN++ ))
            fi
            let "COLUMN_SIZE[$COLUMN_NB]++"
        fi
    done <<< "$CSV_HEAD"

    # Base on last column, get the max length for it
    while read -r LINE; do
        local LAST_COLUMN=${LINE##*,}
        if [ "${#LAST_COLUMN}" -gt "${COLUMN_SIZE[$COLUMN_NB]}" ]; then
            COLUMN_SIZE[$COLUMN_NB]="${#LAST_COLUMN}"
        fi
    done < "$CSV_FILE"

    # With the structure of array, print CVS
    local PCVS=""
    local CURRENT_LINE=1
    while read LINE; do
        # Head
        if [ "$CURRENT_LINE" -eq 1 ]; then
            PCVS+=$(printCsvBreakLine "$(echo ${COLUMN_SIZE[@]})")
        fi
        # Body
        PCVS+=$(printCsvLine "$(echo ${COLUMN_SIZE[@]})" "$LINE")
        # Footer (of table and head)
        if [ "$CURRENT_LINE" -eq 1 ] || [ "$CURRENT_LINE" -eq "$CSV_NB_LINE" ]; then
            PCVS+=$(printCsvBreakLine "$(echo ${COLUMN_SIZE[@]})")
        fi
        (( CURRENT_LINE++ ))
    done <<< "$CSV"

    echo -e "$PCVS"
}

##
# @example | Hervé | 32 | ACTIVE |
# @param string $1 Array of size of each column
# @param string $2 CVS line
# @print Echo CVS line with | as separator for each column
function printCsvLine ()
{
    declare -a CVS_COLUMN_SIZE="($1)"
    local CVS_COLUMN_NB="${#CVS_COLUMN_SIZE[@]}"
    local CVS_SOURCE_LINE="$2"
    local CVS_LINE_SIZE=${#CVS_SOURCE_LINE}
    local CVS_LINE=""

    if [ "$CVS_COLUMN_NB" -gt 0 ] && [ "$CVS_SOURCE_LINE" != "" ]; then
        local CURRENT_COL=0
        local CURRENT_POS=1
        local CURRENT_LINE_POS=1
        while read -r -n1 LETTER; do
            # Add | separator between each column
            if [ "$CURRENT_POS" -eq 1 ]; then
                if [ "$CURRENT_COL" -eq 0 ]; then
                    CVS_LINE+="| "
                else
                    CVS_LINE+=" | "
                fi
            fi
            # Add current letter on the output
            if [ "$LETTER" = "" ] || ([ "$CURRENT_POS" -eq 1 ] && [ "$LETTER" = "$SPACE_CHAR" ]);then
                CVS_LINE+=" "
            else
                CVS_LINE+="$LETTER"
            fi
            # Dedicated behavior by column
            if
                [ "$CURRENT_LINE_POS" -eq "$CVS_LINE_SIZE" ] &&
                [ "$CURRENT_POS" -lt "${CVS_COLUMN_SIZE[$CURRENT_COL]}" ]; then
                # Dealing with size of the last column (no space right)
                CVS_LINE+=$(printf '%0.s ' $(seq ${CURRENT_POS} $((${CVS_COLUMN_SIZE[$CURRENT_COL]} -1))))
            elif
                [ "$CURRENT_POS" -eq "${CVS_COLUMN_SIZE[$CURRENT_COL]}" ] &&
                [ "$(($CURRENT_COL+1))" -lt "$CVS_COLUMN_NB" ]; then
                # New column
                CURRENT_POS=0
                (( CURRENT_COL++ ))
            fi
            (( CURRENT_POS++ ))
            (( CURRENT_LINE_POS++ ))
        done <<< "$CVS_SOURCE_LINE"
        CVS_LINE+="|"
    else
        CVS_LINE="$CVS_SOURCE_LINE"
    fi
    echo "$CVS_LINE\n"
}

##
# @example +-------+----+-------+
# @param string $1 Array with size as values for each column
# @print Print a break line for table
function printCsvBreakLine ()
{
    declare -a CVS_COLUMN_SIZE="$1"
    local CVS_LINE=""

    if [ "${#CVS_COLUMN_SIZE[@]}" -gt 0 ]; then
        for SIZE in ${CVS_COLUMN_SIZE}; do
            CVS_LINE+="+"
            CVS_LINE+=$(printf '%0.s-' $(seq 1 $((${SIZE} + 2))))
        done
        CVS_LINE+="+"
    fi
    echo "$CVS_LINE\n"
}