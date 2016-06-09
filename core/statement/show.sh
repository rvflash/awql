#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Allow access to table listing and information
# @param string $1 Request
# @param string $2 Output filepath
# @param arrayToString Response
# @returnStatus 2 If query uses a unexisting table
# @returnStatus 2 If query is empty
# @returnStatus 1 If configuration files are not loaded
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If response file does not exist
function awqlShow ()
{
    if [[ -z "$1" || "$1" != "("*")" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi
    declare -A request="$1"
    local file="$2"
    if [[ -z "$file" || "$file" != *"${AWQL_FILE_EXT}" ]]; then
        echo "${AWQL_INTERNAL_ERROR_DATA_FILE}"
        return 1
    fi

    # Load tables
    declare -A tables="$(awqlTables "${request["${AWQL_REQUEST_VERSION}"]}")"
    if [[ "${#tables[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
        return 1
    fi

    # Load type of tables
    if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
        declare -A tablesType="$(awqlTablesType "${request["${AWQL_REQUEST_VERSION}"]}")"
        if [[ "${#tablesType[@]}" -eq 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_INVALID_TYPES}"
            return 1
        fi
    fi

    # Add views
    declare -A -r views="$(awqlViews)"
    local viewName
    for viewName in "${!views[@]}"; do
        declare -A view="${views["$viewName"]}"
        if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
            tablesType["$viewName"]="${AWQL_REQUEST_VIEW}"
        fi
        tables["$viewName"]="${view["${AWQL_VIEW_NAMES}"]}"
    done

    local query res table
    if [[ -n "${request["${AWQL_REQUEST_WITH}"]}" ]]; then
        # With ...
        query="${AWQL_TABLES_WITH}${request["${AWQL_REQUEST_WITH}"]}"

        for table in "${!tables[@]}"; do
            if inArray "${request["${AWQL_REQUEST_WITH}"]}" "${tables["$table"]}"; then
                if [[ -n "$res" ]]; then
                    res+="\n"
                fi
                res+="$table"

                if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
                    res+=",${tablesType["$table"]}"
                fi
            fi
        done
    else
        # Like ...
        local str="${request["${AWQL_REQUEST_LIKE}"]}"
        if [[ -n "$str" ]]; then
            query=" (${str})"
        fi

        for table in "${!tables[@]}"; do
            # Also manage Like with %
            if [[ -z "${str#%}" || "${str#%}" = "$table" ]] ||
               ([[ "$str" == "%"*"%" && "$table" == *"${str:1:-1}"* ]]) ||
               ([[ "$str" == "%"* && "$table" == *"${str:1}" ]]) ||
               ([[ "$str" == *"%" && "$table" == "${str::-1}"* ]])
            then
                if [ -n "$res" ]; then
                    res+="\n"
                fi
                res+="$table"

                if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
                    res+=",${tablesType["$table"]}"
                fi
            fi
        done
    fi

    if [[ -n "$res" ]]; then
        local header="${AWQL_TABLES_IN}${request["${AWQL_REQUEST_VERSION}"]}${query}"
        if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
            header+=",${AWQL_TABLE_TYPE}"
        fi
        echo "$header" > "$file"
        if [[ $? -ne 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_WRITE_FILE}"
            return 1
        fi
        echo -e "$res" | sort -t, -k+1 -d >> "$file"
    fi

    echo "(["${AWQL_RESPONSE_FILE}"]=\"${file}\" ["${AWQL_RESPONSE_CACHED}"]=0)"
}