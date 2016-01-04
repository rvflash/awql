#!/usr/bin/env bash

##
# Allow access to table listing and informations
# @param string $1 Awql query
# @param string $2 Output filepath
function awqlShow ()
{
    # Removes mandatory or optionnal SQL terms
    declare -a QUERY="($(echo "$1" | sed -e "s/${AWQL_QUERY_SHOW} ${AWQL_QUERY_SHOW_FULL} //g" -e "s/${AWQL_QUERY_SHOW} //g"))"
    local FILE="$2"

    local AWQL_TABLES="$(awqlTables)"
    if [[ $? -ne 0 ]]; then
        echo "$AWQL_TABLES"
        return 1
    elif [[ "$QUERY[0]" != ${AWQL_QUERY_TABLES} ]]; then
        echo "QueryError.INVALID_SHOW_TABLES"
        return 1
    elif ([[ "$QUERY[1]" != ${AWQL_QUERY_LIKE} ]] && [[ "$QUERY[1]" != ${AWQL_QUERY_WITH} ]]); then
        echo "QueryError.INVALID_SHOW_TABLES_METHOD"
        return 1
    fi
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    local SHOW_TABLES=""
    local QUERY_STRING="$QUERY[2]"
    if [[ "$QUERY[1]" != ${AWQL_QUERY_LIKE} ]]; then
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
            return 1
        fi
        for TABLE in "${!AWQL_TABLES[@]}"; do
            if inArray "$COLUMN" "${AWQL_TABLES[$TABLE]}"; then
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