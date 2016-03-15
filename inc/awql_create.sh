#!/usr/bin/env bash

# @includeBy /inc/awql.sh

##
# Allow access to table listing and informations
# @param string $1 Awql query
# @param string $2 Output filepath
# @param string $3 Api version
# @param arrayToString Response
# @returnStatus 2 If query uses a unexisting table
# @returnStatus 2 If query is empty
# @returnStatus 1 If configuration files are not loaded
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If response file does not exist
function awqlShow ()
{
    # Removes mandatory or optionnal SQL terms
    declare -i FULL=0
    if [[ "$1" == ${AWQL_QUERY_SHOW}[[:space:]]*${AWQL_QUERY_FULL}* ]]; then
        FULL=1
    fi
    local QUERY="$(echo "${1//\'/}" | sed -e "s/${AWQL_QUERY_SHOW}[[:space:]]*${AWQL_QUERY_FULL}//g" -e "s/^${AWQL_QUERY_SHOW}//g")"
    declare -a QUERY="($(trim "$QUERY"))" 2>>/dev/null
    local FILE="$2"
    local API_VERSION="$3"

    if [[ "${#QUERY[@]}" -eq 0 ]]; then
        echo "QueryError.EMPTY_QUERY"
        return 2
    elif [[ -z "${FILE}" ]]; then
        echo "InternalError.INVALID_RESPONSE_FILE_PATH"
        return 1
    elif [[ -z "${API_VERSION}" ]]; then
        echo "QueryError.INVALID_API_VERSION"
        return 1
    fi

    # Laod tables
    local AWQL_TABLES
    AWQL_TABLES="$(awqlTables "${API_VERSION}")"
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_TABLES"
        return 1
    elif [[ "${QUERY[0]}" != ${AWQL_QUERY_TABLES} ]]; then
        echo "QueryError.INVALID_SHOW_TABLES"
        return 2
    elif ([[ "${QUERY[1]}" != ${AWQL_QUERY_LIKE} && "${QUERY[1]}" != ${AWQL_QUERY_WITH} && -n "${QUERY[1]}" ]]); then
        echo "QueryError.INVALID_SHOW_TABLES_METHOD"
        return 2
    elif [[ -z "${FILE}" ]]; then
        echo "InternalError.INVALID_RESPONSE_FILE_PATH"
        return 1
    elif [[ -z "${API_VERSION}" ]]; then
        echo "QueryError.INVALID_API_VERSION"
        return 1
    fi
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    # Manage SHOW TABLES without anything or with LIKE / WITH behaviors
    local QUERY_STRING="${QUERY[1]}"
    if [[ -n "${QUERY[2]}" ]]; then
        QUERY_STRING="${QUERY[2]}"
    fi

    # Full mode: display type of tables
    if [[ "$FULL" -eq 1 ]]; then
        local AWQL_TABLES_TYPE
        AWQL_TABLES_TYPE="$(awqlTablesType "${API_VERSION}")"
        if [[ $? -ne 0 ]]; then
            echo "$AWQL_TABLES_TYPE"
            return 1
        fi
        declare -A -r AWQL_TABLES_TYPE="$AWQL_TABLES_TYPE"
    fi

    local SHOW_TABLES=""
    if [[ -z "${QUERY[1]}" || "${QUERY[1]}" == ${AWQL_QUERY_LIKE} ]]; then
        # List tables that match the search terms
        for TABLE in "${!AWQL_TABLES[@]}"; do
            # Also manage Like with %
            if [[ -z "${QUERY_STRING#%}" || "${QUERY_STRING#%}" = "$TABLE" ]] ||
               ([[ "$QUERY_STRING" == "%"*"%" && "$TABLE" == *"${QUERY_STRING:1:-1}"* ]]) ||
               ([[ "$QUERY_STRING" == "%"* && "$TABLE" == *"${QUERY_STRING:1}" ]]) ||
               ([[ "$QUERY_STRING" == *"%" && "$TABLE" == "${QUERY_STRING::-1}"* ]]); then

                if [ -n "$SHOW_TABLES" ]; then
                    SHOW_TABLES+="\n"
                fi
                SHOW_TABLES+="$TABLE"

                if [[ "$FULL" -eq 1 ]]; then
                    SHOW_TABLES+=",${AWQL_TABLES_TYPE[$TABLE]}"
                fi
            fi
        done

        if [[ -n "$QUERY_STRING" ]]; then
            QUERY_STRING=" (${QUERY_STRING})"
        fi
    else
        # List tables that expose this column name
        if [[ -z "$QUERY_STRING" ]]; then
            echo "QueryError.MISSING_COLUMN_NAME"
            return 2
        fi

        for TABLE in "${!AWQL_TABLES[@]}"; do
            if inArray "$QUERY_STRING" "${AWQL_TABLES[$TABLE]}"; then
                if [[ -n "$SHOW_TABLES" ]]; then
                    SHOW_TABLES+="\n"
                fi
                SHOW_TABLES+="$TABLE"

                if [[ "$FULL" -eq 1 ]]; then
                    SHOW_TABLES+=",${AWQL_TABLES_TYPE[$TABLE]}"
                fi
            fi
        done

        QUERY_STRING="${AWQL_TABLES_WITH}${QUERY_STRING}"
    fi

    if [[ -n "$SHOW_TABLES" ]]; then
        local HEADER="${AWQL_TABLES_IN}${API_VERSION}${QUERY_STRING}"
        if [[ "$FULL" -eq 1 ]]; then
            HEADER+=",${AWQL_TABLE_TYPE}"
        fi
        echo -e "$HEADER" > "$FILE"
        echo -e "$SHOW_TABLES" | sort -t, -k+1 -d >> "$FILE"
    fi

    echo -n "([FILE]=\"${FILE}\" [CACHED]=1)"
}