#!/usr/bin/env bash

# @includeBy /core/query.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi

if [[ -z "$(type -t querySelectComponents)" ]]; then
    source "${AWQL_QUERY_DIR}/select.sh"
fi

##
# Parse a AWQL CREATE VIEW query to split it by its component
#
# Order: CREATE [OR REPLACE] VIEW view_name [(column_list)] AS select_statement;
#
# @response
# > STATEMENT         : CREATE VIEW
# > REPLACE           : 0
# > VIEW              : CAMPAIGN_REPORT
# > FIELD_NAMES       :
# > QUERY             : CREATE VIEW CAMPAIGN_REPORT AS SELECT Id, Name, Status, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC
# > DEFINITION        :
#   > STATEMENT       : SELECT
#   > FIELD_NAMES     : Id Name Status Impressions Clicks Conversions Cost AverageCpc
#   > FIELDS          : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
#   > TABLE           : CAMPAIGN_PERFORMANCE_REPORT
#   > WHERE           : Impressions > O
#   > DURING          :
#   > ORDER           : Clicks DESC
#   > LIMIT           : 5
#   > VIEW            : 0
#   > QUERY           : SELECT Id, Name, Status, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC;
#   > AWQL_QUERY      : SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O;
#
# @param string $1 Query
# @return arrayToString Query component
# @returnStatus 1 If query is malformed
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If query is empty
function awqlCreateQuery ()
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
    declare -i queryLength=${#queryStr}
    declare -i replace=0
    declare -A components

    # Parse create query char by char
    local name="${AWQL_REQUEST_STATEMENT}"
    local char part
    declare -i pos
    for (( pos = 0; pos <= ${queryLength}; ++pos )); do
        # Manage end of query
        if [[ ${pos} -lt ${queryLength} ]]; then
            char="${queryStr:$pos:1}"
            if [[ "$char" == [[:space:]] ]]; then
                char=" "
            fi
        else
            char=" "
        fi
        # Split by components
        case "$name" in
            ${AWQL_REQUEST_STATEMENT})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_CREATE} && -z "${components["$name"]}" ]]; then
                        components["$name"]="$part"
                        part=""
                    elif [[ -n "${components["$name"]}" ]]; then
                        if [[ "$part" == ${AWQL_QUERY_OR} && "${components["$name"]}" != *" "${AWQL_QUERY_OR} ]]; then
                            components["$name"]+=" $part"
                        elif [[ "$part" == ${AWQL_QUERY_REPLACE} && ${replace} -eq 0 ]]; then
                            components["$name"]+=" $part"
                            replace=1
                        elif [[ "$part" == ${AWQL_QUERY_VIEW} ]]; then
                            components["$name"]+=" $part"
                            name="${AWQL_REQUEST_VIEW}"
                        else
                            echo "${AWQL_QUERY_ERROR_METHOD}"
                            return 1
                        fi
                        part=""
                    else
                        echo "${AWQL_QUERY_ERROR_METHOD}"
                        return 2
                    fi
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_VIEW})
                if ([[ "$char" == " " || "$char" == "(" ]]) && [[ -n "$part" ]]; then
                    if [[ -z "${components["$name"]}" ]]; then
                        components["$name"]="$part"
                        if [[ "$char" == "(" ]]; then
                            name="${AWQL_REQUEST_FIELD_NAMES}"
                        fi
                    elif [[ "$char" == " " && "$part" == ${AWQL_QUERY_AS} ]]; then
                        name="${AWQL_REQUEST_QUERY_SOURCE}"
                    else
                        echo "${AWQL_QUERY_ERROR_SYNTAX}"
                        return 2
                    fi
                    part=""
                elif [[ "$char" == "(" ]]; then
                    name="${AWQL_REQUEST_FIELD_NAMES}"
                elif [[ "$char" != " " && "$char" != "(" ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_FIELD_NAMES})
                if [[ -z "${components["$name"]}" ]]; then
                    if [[ "$char" != ")" ]]; then
                        part+="$char"
                    else
                        components["$name"]="$part"
                        part=""
                    fi
                elif [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" != ${AWQL_QUERY_AS} ]]; then
                        echo "${AWQL_QUERY_ERROR_SYNTAX}"
                        return 2
                    fi
                    name="${AWQL_REQUEST_QUERY_SOURCE}"
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_QUERY_SOURCE})
                components["$name"]+="$char"
                ;;
            *)
                echo "${AWQL_INTERNAL_ERROR_QUERY_COMPONENT}"
                return 1
                ;;
        esac
    done

    # Empty query or using of reserved keyword
    if [[ -z "${components["${AWQL_REQUEST_VIEW}"]}" ]]; then
        echo "${AWQL_QUERY_ERROR_VIEW}"
        return 2
    elif [[ -z "${components["${AWQL_REQUEST_QUERY_SOURCE}"]}" ]]; then
        echo "${AWQL_QUERY_ERROR_SOURCE}"
        return 2
    elif awqlReservedWord "${components["${AWQL_REQUEST_VIEW}"]}"; then
        echo "${AWQL_QUERY_ERROR_VIEW}"
        return 2
    fi
    # Already a AWQL table ?
    declare -A -r tables="$(awqlTables "$apiVersion")"
    if [[ "${#tables[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
        return 1
    elif [[ ${tables["${components["${AWQL_REQUEST_VIEW}"]}"]+rv} ]]; then
        echo "${AWQL_QUERY_ERROR_TABLE}"
        return 2
    fi
    # Already a AWQL view ?
    if [[ ${replace} -eq 0 ]]; then
        declare -A -r views="$(awqlViews)"
        if [[ "${#views[@]}" -eq 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
            return 1
        elif [[ ${views["${components["${AWQL_REQUEST_VIEW}"]}"]+rv} ]]; then
            echo "${AWQL_QUERY_ERROR_VIEW_ALREADY_EXISTS}"
            return 2
        fi
    fi
    # Source
    components["${AWQL_REQUEST_DEFINITION}"]="$(awqlSelectQuery "${components["${AWQL_REQUEST_QUERY_SOURCE}"]}" "$apiVersion")"
    if [[ $? -ne 0 ]]; then
         echo "${AWQL_QUERY_ERROR_SOURCE}"
        return 2
    fi
    # Check view definition
    declare -A query="${components["${AWQL_REQUEST_DEFINITION}"]}"
    if [[ "${components["${AWQL_REQUEST_VIEW}"]}" -ne 0 ]]; then
        echo "${AWQL_QUERY_ERROR_SOURCE_IS_VIEW}"
        return 2
    fi
    # Columns names
    declare -a queryFieldNames
    IFS=" " read -a queryFieldNames <<<"${query["${AWQL_REQUEST_FIELD_NAMES}"]}"
    if [[ -n "${components["${AWQL_REQUEST_FIELD_NAMES}"]}" ]]; then
        declare -a fieldNames
        IFS=" " read -a fieldNames <<<"${components["${AWQL_REQUEST_FIELD_NAMES}"]//,/ }"
        if [[ ${#fieldNames[@]} -ne ${#queryFieldNames[@]} ]]; then
            echo "${AWQL_QUERY_ERROR_COLUMNS_NOT_MATCH}"
            return 2
        fi
        components["${AWQL_REQUEST_FIELD_NAMES}"]="${fieldNames[@]}"
    else
        components["${AWQL_REQUEST_FIELD_NAMES}"]="${queryFieldNames[@]}"
    fi
    components["${AWQL_REQUEST_QUERY_SOURCE}"]="$queryStr"
    components["${AWQL_REQUEST_REPLACE}"]=${replace}
    components["${AWQL_REQUEST_TYPE}"]="create"

    arrayToString "$(declare -p components)"
}