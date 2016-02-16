#!/usr/bin/env bash

# @includeBy /inc/awql.sh

##
# Allow access to table structure
# @param string $1 Awql query
# @param string $2 Output filepath
# @param string $3 Api version
# @return arrayToString Response
# @returnStatus 2 If query uses a unexisting table
# @returnStatus 2 If query is empty
# @returnStatus 1 If configuration files are not loaded
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If response file does not exist
function awqlDesc ()
{
    # Removes mandatory or optionnal SQL terms
    declare -i FULL=0
    if [[ "$1" == ${AWQL_QUERY_DESC}[[:space:]]*${AWQL_QUERY_FULL}* ]]; then
        FULL=1
    fi
    local QUERY="$(echo "${1//\'/}" | sed -e "s/${AWQL_QUERY_DESC}[[:space:]]*${AWQL_QUERY_FULL}//g" -e "s/^${AWQL_QUERY_DESC}//g")"
    declare -a QUERY="($(trim "$QUERY"))" 2>>/dev/null
    local TABLE="${QUERY[0]}"
    local COLUMN="${QUERY[1]}"
    local FILE="$2"
    local API_VERSION="$3"

    if [[ -z "${QUERY}" ]]; then
        echo "QueryError.EMPTY_QUERY"
        return 2
    elif [[ -z "$TABLE" ]]; then
        echo "QueryError.NO_TABLE"
        return 2
    elif [[ -z "${FILE}" ]]; then
        echo "InternalError.INVALID_RESPONSE_FILE_PATH"
        return 1
    elif [[ -z "${API_VERSION}" ]]; then
        echo "QueryError.INVALID_API_VERSION"
        return 1
    fi

    # Load tables
    local AWQL_TABLES
    AWQL_TABLES="$(awqlTables "${API_VERSION}")"
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_TABLES"
        return 1
    fi
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    local FIELDS="${AWQL_TABLES[$TABLE]}"
    if [[ -z "$FIELDS" ]]; then
        echo "QueryError.UNKNOWN_TABLE"
        return 2
    fi

    # Load fields
    local AWQL_FIELDS
    AWQL_FIELDS="$(awqlFields "${API_VERSION}")"
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_FIELDS"
        return 1
    fi
    declare -A -r AWQL_FIELDS="$AWQL_FIELDS"

    # Load key fields
    local AWQL_KEYS
    AWQL_KEYS="$(awqlKeys "${API_VERSION}")"
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_KEYS"
        return 1
    fi
    declare -A -r AWQL_KEYS="$AWQL_KEYS"

    # Load uncompatible fields
    if [[ "$FULL" -eq 1 ]]; then
        local AWQL_UNCOMPATIBLE_FIELDS
        AWQL_UNCOMPATIBLE_FIELDS="$(awqlUncompatibleFields "${TABLE}" "${API_VERSION}")"
        if [[ $? -ne 0 ]]; then
            echo "$AWQL_UNCOMPATIBLE_FIELDS"
            return 1
        fi
        declare -A -r AWQL_UNCOMPATIBLE_FIELDS="$AWQL_UNCOMPATIBLE_FIELDS"
    fi

    # Header
    local HEADER="${AWQL_TABLE_FIELD_NAME},${AWQL_TABLE_FIELD_TYPE},${AWQL_TABLE_FIELD_KEY}"
    if [[ "$FULL" -eq 1 ]]; then
        HEADER+=",${AWQL_TABLE_FIELD_UNCOMPATIBLES}"
    fi
    echo "$HEADER" > "$FILE"

    # Give properties for each fields of this table
    local BODY
    local FIELD_IS_KEY=""
    for FIELD in ${FIELDS[@]}; do
        if [ -n "${AWQL_FIELDS[$FIELD]}" ] && ([ -z "$COLUMN" ] || [ "$COLUMN" = "$FIELD" ]); then
            if inArray "$FIELD" "${AWQL_KEYS[$TABLE]}"; then
                FIELD_IS_KEY="${AWQL_FIELD_IS_KEY}"
            else
                FIELD_IS_KEY=""
            fi
            BODY="${FIELD},${AWQL_FIELDS[$FIELD]},${FIELD_IS_KEY}"
            if [[ "$FULL" -eq 1 ]]; then
                BODY+=",${AWQL_UNCOMPATIBLE_FIELDS[$FIELD]}"
            fi
            echo "$BODY" >> "$FILE"
        fi
    done

    echo -n "([FILE]=\"${FILE}\" [CACHED]=1)"
}