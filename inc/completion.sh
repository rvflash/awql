#!/usr/bin/env bash

# @includedBy /awql.sh

declare -i -r COMPLETION_DISABLED=0
declare -i -r COMPLETION_MODE_TABLES=1
declare -i -r COMPLETION_MODE_FIELDS=2
declare -i -r COMPLETION_MODE_DURING=3

##
# Return lits of options to propose as completion
# @param int $1 Mode
# @param string $2 Filter value
# @return string
function completeOptions ()
{
    local MODE="$1"
    if [[ "$MODE" -eq ${COMPLETION_DISABLED} ]]; then
        return
    fi
    local FILTER="$2"

    local AWQL_TABLES
    if [[ "$MODE" -eq ${COMPLETION_MODE_TABLES} ]]; then
        # Load tables
        AWQL_TABLES=$(awqlTables)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        declare -A -r AWQL_TABLES="$AWQL_TABLES"
    fi

    local AWQL_FIELDS
    if [[ "$MODE" -eq ${COMPLETION_MODE_FIELDS} ]]; then
        # Load fields
        local AWQL_FIELDS
        AWQL_FIELDS=$(awqlFields)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        declare -A -r AWQL_FIELDS="$AWQL_FIELDS"
    fi

    if [[ "$MODE" -eq ${COMPLETION_MODE_TABLES} ]]; then
        if [[ -z "$FILTER" ]]; then
            # List all available table names
            echo -n "${!AWQL_TABLES[@]}"
        else
            # List all table's fields
            echo -n "${AWQL_TABLES[$FILTER]}"
        fi
    else
        # List all available fields
        echo -n "${!AWQL_FIELDS[@]}"
    fi
}

function completeWord ()
{
    declare -i POSITION="${#1}"
    local COMPLETION="$2"
    if [[ -z "$POSITION" || -z "$COMPLETION" ]]; then
        echo "$COMPLETION"
        return
    fi

    declare -a COMPREPLY
    IFS=' ' read -a COMPREPLY <<< "$COMPLETION"
    declare -i COMPSIZE="${#COMPREPLY[@]}"
    if [[ "$COMPSIZE" -eq 1 ]]; then
        COMPLETION="${COMPREPLY[0]:$POSITION}"
    else
        declare -i I Y LENGTH
        declare -i SUGGESTPOS=$(($POSITION+1))
        declare -i SUGGESTSIZE=${#COMPREPLY[0]}

        COMPLETION=""
        for (( Y=$SUGGESTPOS; Y < $SUGGESTSIZE; Y++ )); do
            LENGTH=$(($Y-$POSITION))
            for (( I=1; I < $COMPSIZE; I++ )); do
                if [[ "${COMPREPLY[$I]:$POSITION:$LENGTH}" != "${COMPREPLY[0]:$POSITION:$LENGTH}" ]]; then
                    break 2
                fi
            done
            COMPLETION="${COMPREPLY[0]:$POSITION:$LENGTH}"
        done

        if [[ -z "$COMPLETION" ]]; then
            COMPLETION="${COMPREPLY[@]}"
        fi
    fi

    echo -n "$COMPLETION"
}

##
# Complete curent query with table or column names and with AWQL keywords.
# @param string $1
function completion ()
{
    local COMP="$1"
    if [[ -z "$COMP" ]]; then
        # Empty string
        return 1
    fi
    IFS=' ' read -a WORDS <<< "$COMP"
    declare -i LENGTH="${#WORDS[@]}"
    if [[ "$LENGTH" -eq 0 ]]; then
        # Only spaces string
        return 1
    fi

    # Terms to complete
    local CUR
    if [[ "${COMP: -1}" == " " ]]; then
        # Last char is a space, add it as word
        WORDS[$LENGTH]=""
        LENGTH+=1
    fi
    CUR="${WORDS[$(($LENGTH-1))]}"

    # All available words to use as completion
    declare -i MODE
    local FILTER OPTIONS
    if [[ "$COMP" == *";" || "$COMP" == *"\\"[gG] ]]; then
        return 1
    elif [[ "$COMP" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_LIMIT}[[:space:]]* ]]; then
        # SELECT ... LIMIT ...
        return 1
    elif [[ "$COMP" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_ORDER_BY}[[:space:]]* ]]; then
        # SELECT ... ORDER BY ...
        # Get only columns used in query
        OPTIONS=$(echo "$COMP" | sed -e "s/${AWQL_QUERY_SELECT}\(.*\)${AWQL_QUERY_FROM}.*/\1/" -e "s/,/ /g" -e "s/[^a-zA-Z0-9 ]//g")
    elif [[ "$COMP" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_DURING}[[:space:]]* ]]; then
        # SELECT ... DURING ...
        MODE=${COMPLETION_MODE_DURING}
    elif [[ "$COMP" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_WHERE}[[:space:]]* ]]; then
        # SELECT ... WHERE ...
        declare -i FROM_INDEX
        FROM_INDEX=$(arraySearch "${AWQL_QUERY_FROM}" "$COMP")
        if [[ $? -eq 0 ]]; then
            FILTER="${WORDS[$((FROM_INDEX+1))]}"
        fi
        MODE=${COMPLETION_MODE_TABLES}
    elif [[ "$COMP" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_FROM}[[:space:]]* ]]; then
        # SELECT ... FROM ...
        MODE=${COMPLETION_MODE_TABLES}
    elif [[ "$COMP" == ${AWQL_QUERY_SELECT}[[:space:]]** ]]; then
        # SELECT ...
        MODE=${COMPLETION_MODE_FIELDS}
    elif [[ "$COMP" == ${AWQL_QUERY_DESC}[[:space:]]*${AWQL_QUERY_FULL}[[:space:]]* ]]; then
        # DESC FULL ...
        if [[ "$LENGTH" -eq 3 ]]; then
            MODE=${COMPLETION_MODE_TABLES}
        elif [[ "$LENGTH" -eq 4 ]]; then
            FILTER="${WORDS[2]}"
            MODE=${COMPLETION_MODE_TABLES}
        fi
    elif [[ "$COMP" == ${AWQL_QUERY_DESC}[[:space:]]* ]]; then
        # DESC ...
        if [[ "$LENGTH" -eq 2 ]]; then
            MODE=${COMPLETION_MODE_TABLES}
        elif [[ "$LENGTH" -eq 3 ]]; then
            FILTER="${WORDS[1]}"
            MODE=${COMPLETION_MODE_TABLES}
        fi
    fi

    if [[ -z "$OPTIONS" ]]; then
        OPTIONS=$(completeOptions "$MODE" "$FILTER")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    declare -a COMPREPLY
    if [[ -n "$OPTIONS" ]]; then
        COMPREPLY=( $(compgen -W "$OPTIONS" -- "$CUR") )
    fi
    local REPLY="${COMPREPLY[@]}"
    if [[ "${#COMPREPLY[@]}" -eq 0 || ("${#COMPREPLY[@]}" -eq 1 && "${REPLY}" == "$CUR") ]]; then
        return 1
    fi

    completeWord "${CUR}" "${REPLY}"
}