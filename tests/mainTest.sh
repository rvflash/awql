#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/main.sh

# Default entries
declare -r TEST_QUERY_API_ID="123-456-7890"
declare -r TEST_QUERY_BAD_API_ID="123"
declare -r TEST_QUERY_API_VERSION="v201605"
declare -r TEST_QUERY_BAD_API_VERSION="v0883"
declare -ri TEST_MAIN_QUERY_LINE=18
declare -r TEST_MAIN_QUERY_ENDING="13 rows in set (0.00 sec) "
declare -r TEST_MAIN_QUERY_VERBOSE_ENDING="${TEST_MAIN_QUERY_ENDING}@source ${AWQL_WRK_DIR}/3928115536.awql"
declare -r TEST_MAIN_QUERY_CACHED_VERBOSE_ENDING="${TEST_MAIN_QUERY_ENDING}@source ${AWQL_WRK_DIR}/3928115536.awql @cached"
declare -r TEST_MAIN_QUERY="DESC CAMPAIGN_REPORT"
declare -r TEST_MAIN_BAD_QUERY="UPDATE CAMPAIGN_REPORT SET CampaignId = 12;"
declare -r TEST_MAIN_TEST_DIR="${PWD}/unit"
declare -r TEST_MAIN_UNKNOWN_CSV_FILE="/awql/file.csv"
declare -r TEST_MAIN_CSV_FILE="${TEST_MAIN_TEST_DIR}/test01.csv"
declare -r TEST_MAIN_RESPONSE_FILE="${AWQL_WRK_DIR}/123456789${AWQL_FILE_EXT}"
declare -r TEST_MAIN_CSV_RESPONSE="([FILE]=\"${TEST_MAIN_CSV_FILE}\" [CACHING]=1)"
declare -r TEST_MAIN_MISSING_CHECKSUM_REQUEST='([FULL]="0" [VIEW]="0" [QUERY]="DESC CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="DESC" [METHOD]="desc" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [API_VERSION]="v201605" )'
declare -r TEST_MAIN_ERROR_REQUEST='([ADWORDS_ID]="123-456-7890" [CACHING]="1" [CHECKSUM]="123456789" [VIEW]="RV_REPORT" [QUERY]="DROP TABLE RV_REPORT" [STATEMENT]="DROP TABLE" [METHOD]="drop" [API_VERSION]="v201605" )'
declare -r TEST_MAIN_BASIC_CREATE_REQUEST='([CHECKSUM]="123456789" [VIEW]="RV_REPORT" [QUERY]="CREATE VIEW RV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="0" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"Clicks DESC\" [SORT_ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_MAIN_BASIC_DESC_REQUEST='([CHECKSUM]="123456789" [FULL]="0" [VIEW]="0" [QUERY]="DESC CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="DESC" [METHOD]="desc" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [API_VERSION]="v201605" )'
declare -r TEST_MAIN_BASIC_REQUEST='([CHECKSUM]="/123456789" [VIEW]="0" [QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="SELECT" [METHOD]="select" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId" [AWQL_QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [FIELDS]="CampaignId" )'
declare -r TEST_MAIN_CACHED_SELECT_REQUEST='([ADWORDS_ID]="123-456-7890" [CACHING]="1" [CHECKSUM]="123456789" [VIEW]="0" [QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="SELECT" [METHOD]="select" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId" [AWQL_QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [FIELDS]="CampaignId" )'
declare -r TEST_MAIN_BASIC_SHOW_REQUEST='([CHECKSUM]="123456789" [FULL]="0" [QUERY]="SHOW TABLES" [STATEMENT]="SHOW TABLES" [METHOD]="show" [API_VERSION]="v201605" )'


readonly TEST_MAIN_GET_DATA_FROM_CACHE="-21-11-11-01-21"

function test_getDataFromCache ()
{
    local test

    #1 Check nothing
    test=$(__getDataFromCache)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check without file but activated cache
    test=$(__getDataFromCache "" 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with unknown file but activated cache
    test=$(__getDataFromCache "${TEST_MAIN_UNKNOWN_CSV_FILE}" 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with valid file and activated cache
    test=$(__getDataFromCache "${TEST_MAIN_CSV_FILE}" 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_MAIN_CSV_RESPONSE}" ]] && echo -n 1

    #5 Check with valid file but disabled cache
    test=$(__getDataFromCache "${TEST_MAIN_CSV_FILE}" 0)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_MAIN_GET_DATA="-11-11-21-11-01-11-01-01"

function test_getData ()
{
    local test testFile="${AWQL_USER_VIEWS_DIR}/RV_REPORT.yaml"

    #1 Check nothing
    test=$(__getData)
    echo -n "-$?"
    [[ "${AWQL_INTERNAL_ERROR_CONFIG}" == "$test" ]] && echo -n 1

    #2 Check with bad request
    test=$(__getData "rv")
    echo -n "-$?"
    [[ "${AWQL_INTERNAL_ERROR_CONFIG}" == "$test" ]] && echo -n 1

    #3 Check with unsupported method as request
    test=$(__getData "${TEST_MAIN_ERROR_REQUEST}")
    echo -n "-$?"
    [[ "${AWQL_QUERY_ERROR_METHOD}" == "$test" ]] && echo -n 1

    #4 Check with missing query checksum in request
    test=$(__getData "${TEST_MAIN_MISSING_CHECKSUM_REQUEST}")
    echo -n "-$?"
    [[ "${AWQL_INTERNAL_ERROR_QUERY_CHECKSUM}" == "$test" ]] && echo -n 1

    #5 Check with create method as request
    test=$(__getData "${TEST_MAIN_BASIC_CREATE_REQUEST}")
    echo -n "-$?"
    [[ "()" == "$test" ]] && echo -n 1

    #6 Check with select method as request
    test=$(__getData "${TEST_MAIN_BASIC_REQUEST}")
    echo -n "-$?"
    [[ "${AWQL_INTERNAL_ERROR_ID}" == "$test" ]] && echo -n 1

    #7 Check with show method as request
    test=$(__getData "${TEST_MAIN_BASIC_SHOW_REQUEST}")
    echo -n "-$?"
    [[ "$test" == "([FILE]="*" [CACHING]=0)" ]] && echo -n 1

    #0 Force workspace
    touch "${TEST_MAIN_RESPONSE_FILE}"

    #8 Check with select query in cache
    test=$(__getData "${TEST_MAIN_CACHED_SELECT_REQUEST}")
    echo -n "-$?"
    [[ "$test" == "([FILE]="*" [CACHING]=1)" ]] && echo -n 1

    #0 Clear workspace
    rm -f "$testFile"
    rm -f "${TEST_MAIN_RESPONSE_FILE}"
    awqlClearCacheViews
}


readonly TEST_MAIN_AWQL="-11-11-11-01-11-11-11-11-01-01-01"

function test_awql ()
{
    local test

    #1 Check nothing, expected error
    test=$(awql)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_ID}" ]] && echo -n 1

    #2 Check with only query, expected error
    test=$(awql "${TEST_MAIN_QUERY}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_ID}" ]] && echo -n 1

    #3 Check only with query and valid API version, expected error
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_ID}" ]] && echo -n 1

    #4 Check only with query, valid API version and Adwords Id, expected valid response
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_API_ID}")
    echo -n "-$?"
    [[ $(wc -l <<< "$test") -eq ${TEST_MAIN_QUERY_LINE} && "$test" == *"${TEST_MAIN_QUERY_ENDING}" ]] && echo -n 1

    #5 Check with empty query, valid API version and Adwords ID, expected empty response with error status
    test=$(awql "" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_API_ID}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with bad query, valid API version and Adwords ID, expected query error
    test=$(awql "${TEST_MAIN_BAD_QUERY}" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_API_ID}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_METHOD}" ]] && echo -n 1

    #7 Check with with query, invalid API version and Adwords ID, expected internal error
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_BAD_API_VERSION}" "${TEST_QUERY_API_ID}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #8 Check with with query, API version and invalid Adwords ID, expected internal error
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_BAD_API_ID}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_ID}" ]] && echo -n 1

    #9 Check with with query, API version and invalid Adwords ID with verbose mode, expected valid response
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_API_ID}" "" "" 0 1)
    echo -n "-$?"
    [[ $(wc -l <<< "$test") -eq ${TEST_MAIN_QUERY_LINE} && "$test" == *"${TEST_MAIN_QUERY_VERBOSE_ENDING}" ]] && echo -n 1

    #10 Check with with query, API version and invalid Adwords ID with cache and verbose mode, expected valid response
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_API_ID}" "" "" 1 1)
    echo -n "-$?"
    [[ $(wc -l <<< "$test") -eq ${TEST_MAIN_QUERY_LINE} && "$test" == *"${TEST_MAIN_QUERY_CACHED_VERBOSE_ENDING}" ]] && echo -n 1

    #11 Check with with query, API version and invalid Adwords ID with only cache enabled, expected valid response
    test=$(awql "${TEST_MAIN_QUERY}" "${TEST_QUERY_API_VERSION}" "${TEST_QUERY_API_ID}" "" "" 1 0)
    echo -n "-$?"
    [[ $(wc -l <<< "$test") -eq ${TEST_MAIN_QUERY_LINE} && "$test" == *"${TEST_MAIN_QUERY_ENDING}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "__getDataFromCache" "${TEST_MAIN_GET_DATA_FROM_CACHE}" "$(test_getDataFromCache)"
bashUnit "__getData" "${TEST_MAIN_GET_DATA}" "$(test_getData)"
bashUnit "awql" "${TEST_MAIN_AWQL}" "$(test_awql)"