#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Views has stored in user home in a folder named .awql/views
# Each view has its own configuration file with structure details (name, query source, etc.)
#
# @example /home/hgouchet/.awql/views/CAMPAIGN_REPORT.yaml
# > ORIGIN  : SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC LIMIT 5;
# > NAMES   : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
# > FIELDS  : CampaignId CampaignName CampaignStatus Impressions Clicks Conversions Cost AverageCpc
# > TABLE   : CAMPAIGN_PERFORMANCE_REPORT
# > WHERE   : Impressions > O
# > DURING  :
# > ORDER   : Clicks DESC
# > LIMIT   : 5
##

##
# Allow access to table listing and information
# @param string $1 Request
# @param arrayToString Response
# @returnStatus 2 If query uses a un-existing table
# @returnStatus 2 If query is empty
# @returnStatus 1 If configuration files are not loaded
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If response file does not exist
function awqlCreate ()
{
    if [[ -z "$1" || "$1" != "("*")" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi
    declare -A -r request="$1"
    if [[ -z "${request["${AWQL_REQUEST_DEFINITION}"]}" || "${request["${AWQL_REQUEST_DEFINITION}"]}" != "("*")" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    elif [[ -z "${request["${AWQL_REQUEST_VIEW}"]}" || -z "${request["${AWQL_REQUEST_FIELD_NAMES}"]}" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi
    declare -A -r table="${request["${AWQL_REQUEST_DEFINITION}"]}"
    if [[ -z "${table["${AWQL_REQUEST_QUERY}"]}" || -z "${table["${AWQL_REQUEST_FIELD_NAMES}"]}" || -z "${table["${AWQL_REQUEST_TABLE}"]}" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi

    local file="${AWQL_USER_VIEWS_DIR}/${request["${AWQL_REQUEST_VIEW}"]}.yaml"
    if [[ -f "$file" && "${request["${AWQL_REQUEST_REPLACE}"]}" -eq 0 ]]; then
        echo "${AWQL_QUERY_ERROR_VIEW_ALREADY_EXISTS}"
        return 2
    fi
    declare -i pad=10

    # Query source
    printRightPadding "${AWQL_VIEW_ORIGIN}" $((${pad}-${#AWQL_VIEW_ORIGIN})) > "$file"
    echo -ne ": ${table["${AWQL_REQUEST_QUERY}"]}\n" >> "$file"
    # Column names
    printRightPadding "${AWQL_VIEW_NAMES}" $((${pad}-${#AWQL_VIEW_NAMES})) >> "$file"
    echo -ne ": ${request["${AWQL_REQUEST_FIELD_NAMES}"]}\n" >> "$file"
    # Columns
    printRightPadding "${AWQL_VIEW_FIELDS}" $((${pad}-${#AWQL_VIEW_FIELDS})) >> "$file"
    echo -ne ": ${table["${AWQL_REQUEST_FIELD_NAMES}"]}\n" >> "$file"
    # Table name
    printRightPadding "${AWQL_VIEW_TABLE}" $((${pad}-${#AWQL_VIEW_TABLE})) >> "$file"
    echo -ne ": ${table["${AWQL_REQUEST_TABLE}"]}\n" >> "$file"
    # Where
    printRightPadding "${AWQL_VIEW_WHERE}" $((${pad}-${#AWQL_VIEW_WHERE})) >> "$file"
    echo -ne ": ${table["${AWQL_REQUEST_WHERE}"]}\n" >> "$file"
    # During
    printRightPadding "${AWQL_VIEW_DURING}" $((${pad}-${#AWQL_VIEW_DURING})) >> "$file"
    echo -ne ": ${table["${AWQL_REQUEST_DURING}"]}\n" >> "$file"
    # Order
    printRightPadding "${AWQL_VIEW_ORDER}" $((${pad}-${#AWQL_VIEW_ORDER})) >> "$file"
    echo -ne ": ${table["${AWQL_REQUEST_ORDER}"]}\n" >> "$file"
    # Limit
    printRightPadding "${AWQL_VIEW_LIMIT}" $((${pad}-${#AWQL_VIEW_LIMIT})) >> "$file"
    echo -ne ": ${table["${AWQL_REQUEST_LIMIT}"]}\n" >> "$file"

    echo "()"
}