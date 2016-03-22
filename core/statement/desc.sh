#!/usr/bin/env bash

# @includeBy /inc/awql.sh

##
# Allow access to table structure
# @param string $1 Awql query
# @param string $2 Output filepath
# @param string $3 Api version
# @return arrayToString Response
# @returnStatus 2 If query uses a un-existing table
# @returnStatus 2 If query is empty
# @returnStatus 1 If configuration files are not loaded
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If response file does not exist
function awqlDesc ()
{
    declare -i fullQuery=0
    local queryStr="${1//\'/}"
    if [[ "$queryStr" == ${AWQL_QUERY_DESC}[[:space:]]*${AWQL_QUERY_FULL}* ]]; then
        fullQuery=1
    fi
    queryStr="$(echo "$queryStr" | sed -e "s/${AWQL_QUERY_DESC}[[:space:]]*${AWQL_QUERY_FULL}//g" -e "s/^${AWQL_QUERY_DESC}//g")"
    local file="$2"
    local apiVersion="$3"

    declare -a query="($(trim "$queryStr"))"
    local table="${query[0]}"
    local column="${query[1]}"
    if [[ -z "$query" ]]; then
        echo "QueryError.EMPTY_QUERY"
        return 2
    elif [[ -z "$table" ]]; then
        echo "QueryError.NO_TABLE"
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
    fi
    # Load table fields
    local awqlTableFields="${awqlTables[$table]}"
    if [[ -z "$awqlTableFields" ]]; then
        echo "QueryError.UNKNOWN_TABLE"
        return 2
    fi
    # Load fields
    declare -A awqlFields="$(awqlFields "$apiVersion")"
    if [[ -z "$awqlFields" ]]; then
        echo "InternalError.INVALID_AWQL_FIELDS"
        return 1
    fi
    # Load key fields
    declare -A awqlKeys="$(awqlKeys "$apiVersion")"
    if [[ -z "$awqlKeys" ]]; then
        echo "InternalError.INVALID_AWQL_KEYS"
        return 1
    fi
    # Load uncompatible fields
    if [[ ${fullQuery} -eq 1 ]]; then
        declare -A awqlUncompatibleFields="$(awqlUncompatibleFields "$table" "$apiVersion")"
        if [[ -z "$awqlUncompatibleFields" ]]; then
            echo "InternalError.INVALID_AWQL_UNCOMPATIBLE_FIELDS"
            return 1
        fi
    fi

    # Header
    local header="${AWQL_TABLE_FIELD_NAME},${AWQL_TABLE_FIELD_TYPE},${AWQL_TABLE_FIELD_KEY}"
    if [[ ${fullQuery} -eq 1 ]]; then
        header+=",${AWQL_TABLE_FIELD_UNCOMPATIBLES}"
    fi
    echo "$header" > "$file"
    if [[ $? -ne 0 ]]; then
        echo "InternalError.WRITE_FILE_PERMISSION"
        return 1
    fi

    # Give properties for each fields of this table
    local body field fieldIsKey
    for field in "${awqlTableFields[@]}"; do
        if [[ -n "${awqlFields[$field]}" ]] && ([[ -z "$column" || "$column" == "$field" ]]); then
            if inArray "$field" "${awqlKeys[$table]}"; then
                fieldIsKey="${AWQL_FIELD_IS_KEY}"
            else
                fieldIsKey=""
            fi
            body="${field},${awqlFields[$field]},${fieldIsKey}"
            if [[ ${fullQuery} -eq 1 ]]; then
                body+=",${awqlUncompatibleFields[$field]}"
            fi
            echo "$body" >> "$file"
            if [[ $? -ne 0 ]]; then
                echo "InternalError.WRITE_FILE_PERMISSION"
                return 1
            fi
        fi
    done

    echo -n "([FILE]=\"${file}\" [CACHED]=1)"
}