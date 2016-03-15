#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
fi


##
# Get query sort order
# @param string $1 Requested sort order
# @return int 1 for DESC, 0 for ASC
function __queryOrder ()
{
    if [[ "$1" == ${AWQL_QUERY_DESC} ]]; then
        echo "${AWQL_SORT_ORDER_DESC}"
    else
        echo "${AWQL_SORT_ORDER_ASC}"
    fi
}

##
# Return sort order (n for numeric, d for others)
# @param $1 Column data type
# @return string
function __queryOrderType ()
{
    if inArray "$1" "${AWQL_SORT_NUMERICS}"; then
        echo "n"
    else
        echo "d"
    fi
}

##
# Queries can be displayed vertically by terminating the query with \G instead of a semicolon
#
# @param string $1 Query
# @return string $1 Query without semicolon or \[Gg]
# @returnStatus 0 If query must be displayed in vertical mode, 1 otherwise
function __queryWithoutDisplayMode ()
{
    local queryStr="$1"
    if [[ -z "$queryStr" ]]; then
        return 1
    fi

    declare -i queryLength=${#queryStr}
    if [[ "${queryStr:${queryLength}-1}" == [gG] ]]; then
        if [[ "${queryStr:${queryLength}-2:1}" == "\\" ]]; then
            echo "${queryStr::-2}"
        else
            # Prompt mode
            echo "${queryStr::-1}"
        fi
        return 0
    elif [[ "${queryStr:${queryLength}-1}" == ";" ]]; then
        echo "${queryStr::-1}"
    else
        echo "$queryStr"
    fi

    return 1
}

##
# Parse a AWQL query to split it by its component
#
# Order: SELECT...FROM...WHERE...DURING...ORDER BY...LIMIT...
#
# @response
# > STATEMENT       : SELECT
# > FIELD_NAMES     : Id Name Status Impressions Clicks Conversions Cost AverageCpc
# > FIELDS          : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
# > TABLE           : CAMPAIGN_REPORT
# > WHERE           : Impressions > O
# > DURING          :
# > ORDER           : Clicks DESC
# > LIMIT           : 5
# > VERTICAL_MODE   : 0
# > QUERY           : SELECT Id, Name, Status, Impressions, Clicks FROM CAMPAIGN_REPORT WHERE Impressions > O ORDER BY Clicks DESC;
# > AWQL_QUERY      : SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O;
#
# @param string $1 Query
# @param string $2 Api version
# @return arrayToString Query component
# @returnStatus 1 If query is malformed
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If query is empty
function querySelectComponents ()
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
    declare -A components
    declare -a fieldNames

    # Manage vertical mode, also named G modifier
    declare -i verticalMode=0
    queryStr=$(__queryWithoutDisplayMode "$queryStr")
    if [[ $? -eq 0 ]]; then
        verticalMode=1
    fi
    declare -i queryLength=${#queryStr}

    # During literal dates
    local duringLiteral="${AWQL_COMPLETE_DURING[@]}"

    # Parse query char by char
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
                    if [[ "$part" == ${AWQL_QUERY_SELECT} ]]; then
                        components["$name"]="$part"
                        part=""
                        name=${AWQL_REQUEST_FIELDS}
                    else
                        echo "${AWQL_QUERY_ERROR_METHOD}"
                        return 2
                    fi
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_FIELDS})
                if [[ "$part" == *[[:space:]]*${AWQL_QUERY_FROM} ]]; then
                    # Get rest of fields without from method
                    fieldNames+=("${part%% *}")
                    part=""
                    name=${AWQL_REQUEST_TABLE}
                elif [[ "$char" == "," ]]; then
                    if [[ -n "$part" ]]; then
                        fieldNames+=("$part")
                        part=""
                    fi
                elif [[ -n "$part" || "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_TABLE})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ -z "${components["$name"]}" ]]; then
                        components["$name"]="$part"
                    elif [[ "$part" == ${AWQL_QUERY_WHERE} ]]; then
                        name=${AWQL_REQUEST_WHERE}
                    elif [[ "$part" == ${AWQL_QUERY_DURING} ]]; then
                        name=${AWQL_REQUEST_DURING}
                    elif [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_WHERE})
                 if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_DURING} ]]; then
                        name=${AWQL_REQUEST_DURING}
                    elif [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif [[ -n "${components["$name"]}" ]]; then
                        components["$name"]+=" $part"
                    else
                        components["$name"]="$part"
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_DURING})
                if ([[ "$char" == " " || "$char" == "," ]]) && [[ -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif inArray "$part" "$duringLiteral"; then
                        components["$name"]="$part"
                    elif [[ "$part" =~ ^[[:digit:]]{8}$ ]]; then
                        if [[ -n "${components["$name"]}" ]]; then
                            components["$name"]+=" $part"
                        else
                            components["$name"]="$part"
                        fi
                    else
                        echo "${AWQL_QUERY_ERROR_DURING}"
                        return 2
                    fi
                    part=""
                elif [[ "$char" != " " && "$char" != "," ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_ORDER})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif [[ ! ${components["$name"]+rv} ]]; then
                        if [[ "$part" != ${AWQL_QUERY_BY} ]]; then
                            echo "QueryError.ORDER_BY"
                            return 2
                        else
                            components["$name"]=""
                        fi
                    else
                        if [[ -n "${components["$name"]}" ]]; then
                            components["$name"]+=" "
                        fi
                        components["$name"]+="$part"
                    fi
                    part=""
                elif [[ "$char" == "," ]]; then
                    # Multiple order by is not supported for the moment
                    echo "${AWQL_QUERY_ERROR_MULTIPLE_ORDER}"
                    return 2
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_LIMIT})
                if ([[ "$char" == " " || "$char" == "," ]]) && [[ -n "$part" ]]; then
                    if [[ "$part" =~ ^[0-9]+$ ]]; then
                        if [[ -n "${components["$name"]}" ]]; then
                            components["$name"]+=" $part"
                        else
                            components["$name"]="$part"
                        fi
                    else
                        echo "${AWQL_QUERY_ERROR_LIMIT}"
                        return 2
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            *)
                echo "${AWQL_INTERNAL_ERROR_QUERY_COMPONENT}"
                return 1
                ;;
        esac
    done

    # Empty query
    declare -i fieldSize="${#fieldNames[@]}"
    if [[ -z "${components["${AWQL_REQUEST_TABLE}"]}" || ${fieldSize} -eq 0 ]]; then
        echo "${AWQL_QUERY_ERROR_SELECT}"
        return 2
    fi

    # Check if it is a valid report table or view
    declare -i isView=0
    declare -A -r tables="$(awqlTables "$apiVersion")"
    if [[ "${#tables[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
        return 1
    fi
    local tableNames="${!tables[@]}"
    if ! inArray "${components["${AWQL_REQUEST_TABLE}"]}" "$tableNames"; then
        # Here also check for view
        echo "${AWQL_QUERY_ERROR_TABLE}"
        return 2
    fi

    # Awql fields
    declare -a fields
    for field in "${fieldNames[@]}"; do
        if [[ ${isView} -eq 0 && "$field" == *"*"* ]]; then
            # Exclude all pattern
            echo "${AWQL_QUERY_ERROR}"
            return 2
        fi
        # Manage alias name (AS)

        # Manage methods like SUM  or COUNT
        if [[ "$field" == *[\(\)]* ]]; then
            # Get only column name: SUM(Cost)
            field="${field%%\(*}"
            field="${field##*\)}"
        fi
        fields+=("$field")
    done
    components["${AWQL_REQUEST_FIELDS}"]="${fields[@]}"
    components["${AWQL_REQUEST_FIELD_NAME}"]="${fieldNames[@]}"

    # During check
    local during="${components["${AWQL_REQUEST_DURING}"]}"
    if ([[ "${#during[@]}" -eq 1 && "${during[0]}" =~ ^[[:digit:]]{8}$ ]]) || [[ "${#during[@]}" -gt 2 ]]; then
        echo "${AWQL_QUERY_ERROR_DURING}"
        return 2
    fi

    # Sort order by
    if [[ -n "${components["${AWQL_REQUEST_ORDER}"]}" ]]; then
        declare -a order="(${components["${AWQL_REQUEST_ORDER}"]})"
        declare -i orderColumn
        if [[ "${order[0]}" =~ ^[0-9]+$ ]]; then
            # Order by 1
            orderColumn="${order[0]}"
            if [[ ${orderColumn} -eq 0 || ${orderColumn} -gt ${fieldSize} ]]; then
                echo "${AWQL_QUERY_ERROR_ORDER}"
                return 2
            fi
            orderColumn+=-1
        else
            # Order by columnName
            orderColumn=$(arraySearch "${order[0]}" "${components["${AWQL_REQUEST_FIELD_NAME}"]}")
            if [[ $? -ne 0 ]]; then
                echo "${AWQL_QUERY_ERROR_ORDER}"
                return 2
            fi
        fi
        declare -A -r fieldsType="$(awqlFields "$apiVersion")"
        local type="${fieldsType[${fields[${orderColumn}]}]}"
        if [[ -z "$type" ]]; then
            echo "${AWQL_QUERY_ERROR_COLUMN_TYPE}"
            return 1
        fi
        orderColumn+=1

        # @fields CampaignId, CampaignName
        # @orderBy CampaignName ASC
        # @example d 2 0
        components["${AWQL_REQUEST_SORT_ORDER}"]="$(__queryOrderType "$type") $orderColumn $(__queryOrder "${order[1]}")"
    fi

    # Vertical mode
    components["${AWQL_REQUEST_VERTICAL}"]=${verticalMode}

    # Original query
    components["${AWQL_REQUEST_QUERY_SOURCE}"]="$queryStr"

    # Build AWQL query
    # SELECT...FROM...WHERE...DURING...
    declare -a awqlQuery
    awqlQuery+=("${components["${AWQL_REQUEST_STATEMENT}"]}")
    awqlQuery+=("${components["${AWQL_REQUEST_FIELD_NAME}"]// /,}")
    awqlQuery+=("FROM ${components["${AWQL_REQUEST_TABLE}"]}")
    if [[ -n "${components["${AWQL_REQUEST_WHERE}"]}" ]]; then
        awqlQuery+=("${AWQL_REQUEST_WHERE} ${components["${AWQL_REQUEST_WHERE}"]}")
    fi
    if [[ -n "${components["${AWQL_REQUEST_DURING}"]}" ]]; then
        awqlQuery+=("${AWQL_REQUEST_DURING} ${components["${AWQL_REQUEST_DURING}"]// /,}")
    fi
    components["${AWQL_REQUEST_QUERY}"]="${awqlQuery[@]}"

    arrayToString "$(declare -p components)"
}

##
# Check query to verify structure & limits
#
# @response
# > ADWORDS_ID      : 123-456-7890
# > API_VERSION     : v201601
# > VERTICAL_MODE   : 0
# > VERBOSE         : 0
# > CACHING         : 0
# > ORDER_BY        : n 4 1
# > CHECKSUM        : 1234567890
# > METHOD          : select
# > STATEMENT       : SELECT
# > SOURCE          : SELECT * FROM CAMPAIGN_REPORT LIMIT 5;
# > QUERY           : SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O;
# > ORIGIN          : SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC;
# > NAMES           : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
# > FIELDS          : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
# > COLUMNS         : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
# > TABLE           : CAMPAIGN_PERFORMANCE_REPORT
# > WHERE           : Impressions > O
# > DURING          :
# > ORDER           : Clicks DESC
# > LIMIT           : 5

# @param string $1 Adwords ID
# @param string $2 Awql query
# @param string $3 API version
# @param int $4 Caching
# @param int $5 Verbose
# @return arrayToString Request
# @returnStatus 2 If query is empty
# @returnStatus 2 If query is not a valid AWQL method
# @returnStatus 2 If query is not a report table
# @returnStatus 1 If AdwordsId or apiVersion are invalids
function query ()
{
    local adwordsId="$1"
    if [[ ! "$adwordsId" =~ ${AWQL_API_ID_REGEX} ]]; then
        echo "${AWQL_INTERNAL_ERROR_ID}"
        return 1
    fi
    local queryStr="$(trim "$2")"
    if [[ -z "$queryStr" ]]; then
        return 2
    fi
    local apiVersion="$3"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "${AWQL_INTERNAL_ERROR_API_VERSION}"
        return 1
    fi
    declare -i cache="$4"
    declare -i verbose="$5"

    # Management by query method
    local queryComponents
    local queryMethod="$(__queryWithoutDisplayMode "$(echo "$queryStr" | awk '{ print tolower($1) }')")"
    case "$queryMethod" in
        "")
            echo "${AWQL_QUERY_ERROR_MISSING}"
            return 2
            ;;
        ${AWQL_QUERY_SELECT})
            queryComponents=$(querySelectComponents "$queryStr" "$apiVersion")
            declare -i errCode=$?
            if [[ ${errCode} -ne 0 ]]; then
                echo "$queryComponents"
                return ${errCode}
            fi
            ;;
        ${AWQL_QUERY_EXIT}|${AWQL_QUERY_QUIT})
            echo "${AWQL_PROMPT_EXIT}"
            return 1
            ;;
        ${AWQL_QUERY_HELP})
            echo "The AWQL command line tool is developed by Hervé GOUCHET."
            echo "For developer information, visit:"
            echo "    https://github.com/rvflash/awql/"
            echo "For information about AWQL language, visit:"
            echo "    https://developers.google.com/adwords/api/docs/guides/awql"
            echo
            echo "List of all AWQL commands:"
            echo "Note that all text commands must be first on line and end with ';'"
            printLeftPadding "${AWQL_TEXT_COMMAND_CLEAR}" 10
            echo "(\\${AWQL_COMMAND_CLEAR}) Clear the current input statement."
            printLeftPadding "${AWQL_TEXT_COMMAND_EXIT}" 10
            echo "(\\${AWQL_COMMAND_EXIT}) Exit awql. Same as quit."
            printLeftPadding "${AWQL_TEXT_COMMAND_HELP}" 10
            echo "(\\${AWQL_COMMAND_HELP}) Display this help."
            printLeftPadding "${AWQL_TEXT_COMMAND_QUIT}" 10
            echo "(\\${AWQL_COMMAND_EXIT}) Quit awql command line tool."
            return 2
            ;;
        *)
            echo "${AWQL_QUERY_ERROR_METHOD}"
            return 2
            ;;
    esac

    # Query properties
    declare -A request="$queryComponents"
    request["${AWQL_REQUEST_TYPE}"]="$queryMethod"
    request["${AWQL_REQUEST_ID}"]="$adwordsId"
    request["${AWQL_REQUEST_VERSION}"]="$apiVersion"
    request["${AWQL_REQUEST_CACHED}"]=${cache}
    request["${AWQL_REQUEST_VERBOSE}"]=${verbose}

    # Calculate a unique identifier for the query
    request["${AWQL_REQUEST_CHECKSUM}"]="$(checksum "${request["${AWQL_REQUEST_ID}"]} ${request["${AWQL_REQUEST_QUERY}"]}")"
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_QUERY_CHECKSUM}"
        return 1
    fi

    arrayToString "$(declare -p request)"
}