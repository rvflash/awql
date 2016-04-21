#!/usr/bin/env bash

# @includeBy /core/query.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Parse a AWQL DESC query to split it by its component
#
# Order: DESC [FULL] table_name [column_name]
#
# @response
# > STATEMENT       : DESC FULL
# > FULL            : 1
# > TABLE           : CAMPAIGN_PERFORMANCE_REPORT
# > FIELD           : CampaignId
# > VIEW            : 0
# > VERTICAL_MODE   : 1
# > QUERY           : DESC FULL CAMPAIGN_PERFORMANCE_REPORT CampaignId
# > API_VERSION     : v201601
#
# @param string $1 Query
# @param string $2 apiVersion
# @return arrayToString Query component
# @returnStatus 1 If query is malformed
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If query is empty
function awqlDescQuery ()
{
    local queryStr="$(trim "$1")"
    if [[ -z "$queryStr" ]]; then
        echo "${AWQL_INTERNAL_ERROR_QUERY}"
        return 1
    fi
    local apiVersion="$2"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "${AWQL_INTERNAL_ERROR_API_VERSION}"
        return 1
    fi

    # Query components
    declare -i pos=0
    declare -i fullQuery=0
    declare -A components

    # Parse query word by word
    local name="${AWQL_REQUEST_STATEMENT}"
    declare -a parts
    read -a parts <<<"$queryStr"
    local part
    for part in "${parts[@]}"; do
        if [[ "${AWQL_REQUEST_STATEMENT}" == "$name" ]]; then
            if [[ "$part" == ${AWQL_QUERY_DESC} && -z "${components["$name"]}" ]]; then
                components["$name"]="DESC"
                continue
            elif [[ "$part" == ${AWQL_QUERY_FULL} && -n "${components["$name"]}" ]]; then
                components["$name"]+=" FULL"
                fullQuery=1
                continue
            elif [[ -n "${components["$name"]}" ]]; then
                name="${AWQL_REQUEST_TABLE}"
            else
                echo "${AWQL_QUERY_ERROR_METHOD}"
                return 2
            fi
        fi
        if [[ "${AWQL_REQUEST_TABLE}" == "$name" ]]; then
            components["$name"]="$part"
            name="${AWQL_REQUEST_FIELD}"
        elif [[ "${AWQL_REQUEST_FIELD}" == "$name" ]]; then
            if [[ -z "${components["$name"]}" ]]; then
                components["$name"]="$part"
            else
                echo "${AWQL_QUERY_ERROR_METHOD}"
                return 2
            fi
        fi
    done

    # No table name
    if [[ -z "${components["${AWQL_REQUEST_TABLE}"]}" ]]; then
        echo "${AWQL_QUERY_ERROR_SYNTAX}"
        return 2
    fi

    # Check if it is a valid report table or view name
    declare -i isView=0
    declare -A -r tables="$(awqlTables "$apiVersion")"
    if [[ "${#tables[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
        return 1
    fi
    local tableNames="${!tables[@]}"
    if ! inArray "${components["${AWQL_REQUEST_TABLE}"]}" "$tableNames"; then
        declare -A -r views="$(awqlViews)"
        if [[ -z "${views["${components["${AWQL_REQUEST_TABLE}"]}"]}" ]]; then
            echo "${AWQL_QUERY_ERROR_UNKNOWN_TABLE}"
            return 2
        else
            isView=1
        fi
    fi

    # Check if it is a valid report table or view field name
    if [[ -n "${components["${AWQL_REQUEST_FIELD}"]}" ]]; then
        if [[ ${isView} -eq 1 ]]; then
            declare -A -r view="${views["${components["${AWQL_REQUEST_TABLE}"]}"]}"
            if ! inArray "${components["${AWQL_REQUEST_FIELD}"]}" "${view["${AWQL_VIEW_NAMES}"]}"; then
                echo "${AWQL_QUERY_ERROR_UNKNOWN_FIELD}"
                return 2
            fi
        elif ! inArray "${components["${AWQL_REQUEST_FIELD}"]}" "${tables["${components["${AWQL_REQUEST_TABLE}"]}"]}"; then
            echo "${AWQL_QUERY_ERROR_UNKNOWN_FIELD}"
            return 2
        fi
    fi

    components["${AWQL_REQUEST_QUERY}"]="${components["${AWQL_REQUEST_STATEMENT}"]}"
    if [[ -n "${components["${AWQL_REQUEST_TABLE}"]}" ]]; then
        components["${AWQL_REQUEST_QUERY}"]+=" ${components["${AWQL_REQUEST_TABLE}"]}"
    fi
    if [[ -n "${components["${AWQL_REQUEST_FIELD}"]}" ]]; then
        components["${AWQL_REQUEST_QUERY}"]+=" ${components["${AWQL_REQUEST_FIELD}"]}"
    fi
    components["${AWQL_REQUEST_QUERY_SOURCE}"]="$queryStr"
    components["${AWQL_REQUEST_FULL}"]=${fullQuery}
    components["${AWQL_REQUEST_VIEW}"]=${isView}
    components["${AWQL_REQUEST_VERSION}"]="$apiVersion"
    components["${AWQL_REQUEST_TYPE}"]="desc"

    arrayToString "$(declare -p components)"
}