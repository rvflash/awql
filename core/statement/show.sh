#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Allow access to table listing and information
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
    declare -i fullQuery=0
    local queryStr="${1//\'/}"
    if [[ "$queryStr" == ${AWQL_QUERY_SHOW}[[:space:]]*${AWQL_QUERY_FULL}* ]]; then
        fullQuery=1
    fi
    queryStr="$(echo "$queryStr" | sed -e "s/${AWQL_QUERY_SHOW}[[:space:]]*${AWQL_QUERY_FULL}//g" -e "s/^${AWQL_QUERY_SHOW}//g")"
    local file="$2"
    local apiVersion="$3"

    declare -a query="($(trim "$queryStr"))"
    if [[ -z "$query" ]]; then
        echo "QueryError.EMPTY_QUERY"
        return 2
    elif [[ -z "$file" ]]; then
        echo "InternalError.INVALID_RESPONSE_FILE_PATH"
        return 1
    elif [[ -z "$apiVersion" ]]; then
        echo "QueryError.INVALID_API_VERSION"
        return 1
    fi

    # Load tables
    declare -A -r awqlTables="$(awqlTables "$apiVersion")"
    if [[ -z "$awqlTables" ]]; then
        echo "InternalError.INVALID_AWQL_TABLES"
        return 1
    elif [[ "${query[0]}" != ${AWQL_QUERY_TABLES} ]]; then
        echo "QueryError.INVALID_SHOW_TABLES"
        return 2
    elif [[ -n "${query[1]}" && "${query[1]}" != ${AWQL_QUERY_LIKE} && "${query[1]}" != ${AWQL_QUERY_WITH} ]]; then
        echo "QueryError.INVALID_SHOW_TABLES_METHOD"
        return 2
    fi

    # Manage SHOW TABLES without anything or with LIKE / WITH behaviors
    queryStr="${query[1]}"
    if [[ -n "${query[2]}" ]]; then
        queryStr="${query[2]}"
    fi

    # Full mode: display type of tables
    if [[ ${fullQuery} -eq 1 ]]; then
        declare -A -r awqlTablesType="$(awqlTablesType "$apiVersion")"
        if [[ -z "$awqlTablesType" ]]; then
            echo "InternalError.INVALID_AWQL_TABLES_TYPE"
            return 1
        fi
    fi

    local showTables table
    if [[ -z "${query[1]}" || "${query[1]}" == ${AWQL_QUERY_LIKE} ]]; then
        # List tables that match the search terms
        for table in "${!awqlTables[@]}"; do
            # Also manage Like with %
            if [[ -z "${queryStr#%}" || "${queryStr#%}" = "$table" ]] ||
               ([[ "$queryStr" == "%"*"%" && "$table" == *"${queryStr:1:-1}"* ]]) ||
               ([[ "$queryStr" == "%"* && "$table" == *"${queryStr:1}" ]]) ||
               ([[ "$queryStr" == *"%" && "$table" == "${queryStr::-1}"* ]]); then

                if [ -n "$showTables" ]; then
                    showTables+="\n"
                fi
                showTables+="$table"

                if [[ ${fullQuery} -eq 1 ]]; then
                    showTables+=",${awqlTablesType[$table]}"
                fi
            fi
        done

        if [[ -n "$queryStr" ]]; then
            queryStr=" (${queryStr})"
        fi
    else
        # List tables that expose this column name
        if [[ -z "$queryStr" ]]; then
            echo "QueryError.MISSING_COLUMN_NAME"
            return 2
        fi

        for table in "${!awqlTables[@]}"; do
            if inArray "$queryStr" "${awqlTables[$table]}"; then
                if [[ -n "$showTables" ]]; then
                    showTables+="\n"
                fi
                showTables+="$table"

                if [[ ${fullQuery} -eq 1 ]]; then
                    showTables+=",${awqlTablesType[$table]}"
                fi
            fi
        done

        queryStr="${AWQL_TABLES_WITH}${queryStr}"
    fi

    if [[ -n "$showTables" ]]; then
        local header="${AWQL_TABLES_IN}${apiVersion}${queryStr}"
        if [[ ${fullQuery} -eq 1 ]]; then
            header+=",${AWQL_TABLE_TYPE}"
        fi
        echo -e "$header" > "$file"
        echo -e "$showTables" | sort -t, -k+1 -d >> "$file"
    fi

    echo -n "([FILE]=\"${file}\" [CACHED]=1)"
}