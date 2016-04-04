#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
fi

# > Query
source "${AWQL_QUERY_DIR}/create.sh"
source "${AWQL_QUERY_DIR}/desc.sh"
source "${AWQL_QUERY_DIR}/select.sh"
source "${AWQL_QUERY_DIR}/show.sh"

##
# Help
function awqlHelpQuery ()
{
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
}

##
#
# @param string $2 Awql query
# @param string $3 API version
# @return arrayToString Request
# @returnStatus 2 If query is empty
# @returnStatus 2 If query is not a valid AWQL method
# @returnStatus 2 If query method is help
# @returnStatus 1 If apiVersion are invalids
# @returnStatus 1 If query methods is quit or exit
function __queryToRequest ()
{
    local queryStr="$(trim "$1")"
    if [[ -z "$queryStr" ]]; then
        return 2
    fi
    local apiVersion="$2"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "${AWQL_INTERNAL_ERROR_API_VERSION}"
        return 1
    fi
    local queryMethod="$(echo "$queryStr" | awk '{ print tolower($1) }')"

    case "$queryMethod" in
        "")
            echo "${AWQL_QUERY_ERROR_MISSING}"
            return 2
            ;;
        ${AWQL_QUERY_CREATE})
            awqlCreateQuery "$queryStr" "$apiVersion"
            ;;
        ${AWQL_QUERY_DESC})
            awqlDescQuery "$queryStr" "$apiVersion"
            ;;
        ${AWQL_QUERY_EXIT}|${AWQL_QUERY_QUIT})
            echo "${AWQL_PROMPT_EXIT}"
            return 1
            ;;
        ${AWQL_QUERY_HELP})
            awqlHelpQuery
            ;;
        ${AWQL_QUERY_SELECT})
            awqlSelectQuery "$queryStr" "$apiVersion"
            ;;
        ${AWQL_QUERY_SHOW})
            awqlShowQuery "$queryStr" "$apiVersion"
            ;;
        *)
            echo "${AWQL_QUERY_ERROR_METHOD}"
            return 2
            ;;
    esac
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
# > SOURCE          : SELECT * FROM CAMPAIGN_PERFORMANCE_REPORT LIMIT 5;
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
#
# @param string $1 Adwords ID
# @param string $2 Awql query
# @param string $3 API version
# @param int $4 Caching
# @param int $5 Verbose mode
# @param int $6 Raw mode
# @param string $7 Access token
# @param string $8 Developer token
# @return arrayToString Request
# @returnStatus 2 If query is empty
# @returnStatus 2 If query is not a valid AWQL method
# @returnStatus 2 If query is not a report table
# @returnStatus 1 If AdwordsId or apiVersion are invalids
function awqlRequest ()
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
    declare -i raw="$6"
    local accessToken="$7"
    local developerToken="$8"

    # Manage vertical mode, also named G modifier
    declare -i verticalMode=0
    queryStr=$(__queryWithoutDisplayMode "$queryStr")
    if [[ $? -eq 0 ]]; then
        verticalMode=1
    fi

    # Management by query method
    local queryComponents
    queryComponents="$(__queryToRequest "$queryStr" "$apiVersion")"
    if [[ $? -ne 0 ]]; then
        declare -i errCode=$?
        echo "$queryComponents"
        return ${errCode}
    fi
    declare -A request="$queryComponents"

    request["${AWQL_REQUEST_ID}"]="$adwordsId"
    request["${AWQL_REQUEST_VERSION}"]="$apiVersion"
    request["${AWQL_REQUEST_CACHED}"]=${cache}
    request["${AWQL_REQUEST_VERBOSE}"]=${verbose}
    request["${AWQL_REQUEST_RAW}"]=${raw}
    request["${AWQL_REQUEST_VERTICAL}"]=${verticalMode}
    request["${AWQL_REQUEST_ACCESS_TOKEN}"]="$accessToken"
    request["${AWQL_REQUEST_DEVELOPER_TOKEN}"]="$developerToken"

    # Calculate a unique identifier for the query
    request["${AWQL_REQUEST_CHECKSUM}"]="$(checksum "${request["${AWQL_REQUEST_ID}"]} ${request["${AWQL_REQUEST_QUERY}"]}")"
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_QUERY_CHECKSUM}"
        return 1
    fi

    arrayToString "$(declare -p request)"
}