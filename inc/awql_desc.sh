#!/usr/bin/env bash

##
# Allow access to table structure
# @param string $1 Awql query
# @param string $2 Output filepath
function awqlDesc ()
{
    declare -a QUERY="($(echo "$1" | sed -e "s/${AWQL_QUERY_DESC} //g"))"
    local TABLE="${QUERY[0]}"
    local COLUMN="${QUERY[1]}"
    local FILE="$2"

    local AWQL_TABLES=$(awqlTables)
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_TABLES"
        return 1
    fi
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    local AWQL_FIELDS=$(awqlFields)
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_FIELDS"
        return 1
    fi
    declare -A -r AWQL_FIELDS="$AWQL_FIELDS"

    local AWQL_KEYS=$(awqlKeys)
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_KEYS"
        return 1
    fi
    declare -A -r AWQL_KEYS="$AWQL_KEYS"

    # Header
    echo "${AWQL_TABLE_FIELD_NAME},${AWQL_TABLE_FIELD_TYPE},${AWQL_TABLE_FIELD_KEY}" > "$FILE"

    # Give properties for each fields of this table
    local FIELD_IS_KEY=""
    local FIELDS="${AWQL_TABLES[$TABLE]}"
    for FIELD in ${FIELDS[@]}; do
        if [ -n "${AWQL_FIELDS[$FIELD]}" ] && ([ -z "$COLUMN" ] || [ "$COLUMN" = "$FIELD" ]); then
            inArray "$FIELD" "${AWQL_KEYS[$TABLE]}"
            if [ $? -eq 0 ]; then
                FIELD_IS_KEY="${AWQL_FIELD_IS_KEY}"
            else
                FIELD_IS_KEY=""
            fi
            echo "${FIELD},${AWQL_FIELDS[$FIELD]},${FIELD_IS_KEY}" >> "$FILE"
        fi
    done

    echo -n "([FILE]=\"${FILE}\" [CACHED]=0)"
}