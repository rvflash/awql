#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Allow access to table structure
# @param string $1 Request
# @param string $2 Output filepath
# @return arrayToString Response
# @returnStatus 2 If query uses a un-existing table
# @returnStatus 2 If query is empty
# @returnStatus 1 If configuration files are not loaded
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If response file does not exist
function awqlDesc ()
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
    declare -A -r tables="$(awqlTables "${request["${AWQL_REQUEST_VERSION}"]}")"
    if [[ "${#tables[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
        return 1
    fi

    # AWQL table or view
    local table
    if [[ "${request["${AWQL_REQUEST_VIEW}"]}" -eq 0 ]]; then
        table="${request["${AWQL_REQUEST_TABLE}"]}"
        declare -A -r tableFields="$(arrayCombine "${tables["$table"]}" "${tables["$table"]}")"
        if [[ "${#tableFields[@]}" -eq 0 ]]; then
            echo "${AWQL_QUERY_ERROR_UNKNOWN_TABLE}"
            return 2
        fi
    else
        declare -A -r views="$(awqlViews)"
        if [[ "${#views[@]}" -eq 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_INVALID_VIEWS}"
            return 1
        fi
        declare -A -r view="${views["${request["${AWQL_REQUEST_TABLE}"]}"]}"
        if [[ "${#view[@]}" -eq 0 ]]; then
            echo "${AWQL_QUERY_ERROR_UNKNOWN_TABLE}"
            return 2
        fi
        declare -A -r tableFields="$(arrayCombine "${view["${AWQL_VIEW_NAMES}"]}" "${view["${AWQL_VIEW_FIELDS}"]}")"
        if [[ "${#tableFields[@]}" -eq 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_INVALID_FIELDS}"
            return 1
        fi
        table="${view["${AWQL_VIEW_TABLE}"]}"
    fi

    # Load field properties
    declare -A -r fields="$(awqlFields "${request["${AWQL_REQUEST_VERSION}"]}")"
    if [[ "${#fields[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_FIELDS}"
        return 1
    fi
    # Load key fields
    declare -A -r keys="$(awqlKeys "${request["${AWQL_REQUEST_VERSION}"]}")"
    if [[ "${#keys[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_KEYS}"
        return 1
    fi
    # Load uncompatible fields
    if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
        declare -A -r clash="$(awqlUncompatibleFields "$table" "${request["${AWQL_REQUEST_VERSION}"]}")"
        if [[ "${#clash[@]}" -eq 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_CLASH_FIELDS}"
            return 1
        fi
    fi
    # Columns to fetch
    if [[ -z "${request["${AWQL_REQUEST_FIELD}"]}" ]]; then
        declare -a -r columns="(${!tableFields[@]})"
    else
        declare -a -r columns="(${request["${AWQL_REQUEST_FIELD}"]})"
    fi

    # Header
    local header="${AWQL_TABLE_FIELD_NAME},${AWQL_TABLE_FIELD_TYPE},${AWQL_TABLE_FIELD_KEY}"
    if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
        header+=",${AWQL_TABLE_FIELD_UNCOMPATIBLES}"
    fi
    echo "$header" > "$file"
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_WRITE_FILE}"
        return 1
    fi

    # Give properties for each columns
    local body field awqlName fieldIsKey
    for field in "${columns[@]}"; do
        awqlName="${tableFields["$field"]}"
        if [[ -z "${fields["$awqlName"]}" ]]; then
            echo "${AWQL_INTERNAL_ERROR_INVALID_FIELDS}"
            return 1
        fi
        if inArray "$awqlName" "${keys["$table"]}"; then
            fieldIsKey="${AWQL_FIELD_IS_KEY}"
        else
            fieldIsKey=""
        fi
        body="${field},${fields["$awqlName"]},${fieldIsKey}"
        if [[ "${request["${AWQL_REQUEST_FULL}"]}" -eq 1 ]]; then
            body+=",${clash["$awqlName"]}"
        fi
        echo "$body" >> "$file"
        if [[ $? -ne 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_WRITE_FILE}"
            return 1
        fi
    done

    echo "(["${AWQL_RESPONSE_FILE}"]=\"${file}\" ["${AWQL_RESPONSE_CACHED}"]=1)"
}