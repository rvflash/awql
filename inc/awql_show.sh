#!/usr/bin/env bash

##
# Allow access to table listing and informations
# @param string $1 Awql query
# @param string $2 Output filepath
function awqlShow ()
{
    # Removes mandatory or optionnal SQL terms
    local QUERY="$(echo "${1//\'/}" | sed -e "s/${AWQL_QUERY_SHOW}[[:space:]]*${AWQL_QUERY_SHOW_FULL}//g" -e "s/^${AWQL_QUERY_SHOW}//g")"
    declare -a QUERY="($(trim "$QUERY"))" 2>>/dev/null
    local FILE="$2"

    local AWQL_TABLES
    AWQL_TABLES="$(awqlTables)"
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_TABLES"
        return 1
    elif [[ "${QUERY[0]}" != ${AWQL_QUERY_TABLES} ]]; then
        echo "QueryError.INVALID_SHOW_TABLES"
        return 2
    elif ([[ "${QUERY[1]}" != ${AWQL_QUERY_LIKE} && "${QUERY[1]}" != ${AWQL_QUERY_WITH} && -n "${QUERY[1]}" ]]); then
        echo "QueryError.INVALID_SHOW_TABLES_METHOD"
        return 2
    fi
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    # Manage SHOW TABLES without anything or with LIKE / WITH behaviors
    local QUERY_STRING="${QUERY[1]}"
    if [[ -n "${QUERY[2]}" ]]; then
        QUERY_STRING="${QUERY[2]}"
    fi

    local SHOW_TABLES=""
    if [[ -z "${QUERY[1]}" || "${QUERY[1]}" == ${AWQL_QUERY_LIKE} ]]; then
        # List tables that match the search terms
        for TABLE in "${!AWQL_TABLES[@]}"; do
            # Also manage Like with %
            if [[ -z "${QUERY_STRING#%}" ]] || [[ "${QUERY_STRING#%}" = "$TABLE" ]] ||
               ([[ "$QUERY_STRING" == "%"*"%" ]] && [[ "$TABLE" == *"${QUERY_STRING:1:-1}"* ]]) ||
               ([[ "$QUERY_STRING" == "%"* ]] && [[ "$TABLE" == *"${QUERY_STRING:1}" ]]) ||
               ([[ "$QUERY_STRING" == *"%" ]] && [[ "$TABLE" == "${QUERY_STRING::-1}"* ]]); then

                if [ -n "$SHOW_TABLES" ]; then
                    SHOW_TABLES+="\n"
                fi
                SHOW_TABLES+="$TABLE"
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
            fi
        done

        QUERY_STRING="${AWQL_TABLES_WITH}${QUERY_STRING}"
    fi

    if [[ -n "$SHOW_TABLES" ]]; then
        echo -e "${AWQL_TABLES_IN}${AWQL_API_VERSION}${QUERY_STRING}" > "$FILE"
        echo -e "${SHOW_TABLES}" | sort -t, -k+1 -d >> "$FILE"
    fi

    echo -n "([FILE]=\"${FILE}\" [CACHED]=0)"
}