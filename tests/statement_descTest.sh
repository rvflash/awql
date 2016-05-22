#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/desc.sh

# Default entries
declare -r TEST_STATEMENT_TEST_DIR="${PWD}/unit"
declare -r TEST_STATEMENT_DESC_FILE="${TEST_STATEMENT_TEST_DIR}/desc.csv"
declare -r TEST_STATEMENT_DESC_FIELD_FILE="${TEST_STATEMENT_TEST_DIR}/desc-field.csv"
declare -r TEST_STATEMENT_DESC_FULL_FILE="${TEST_STATEMENT_TEST_DIR}/desc-full.csv"
declare -r TEST_STATEMENT_DESC_FULL_FIELD_FILE="${TEST_STATEMENT_TEST_DIR}/desc-full-field.csv"
declare -r TEST_STATEMENT_DESC_VIEW_FILE="${TEST_STATEMENT_TEST_DIR}/desc-view.csv"
declare -r TEST_STATEMENT_DESC_VIEW_FIELD_FILE="${TEST_STATEMENT_TEST_DIR}/desc-view-field.csv"
declare -r TEST_STATEMENT_DESC_ERROR_FILE="${TEST_STATEMENT_TEST_DIR}/123456789.txt"
declare -r TEST_STATEMENT_DESC_TEST_FILE="${TEST_STATEMENT_TEST_DIR}/123456789${AWQL_FILE_EXT}"
declare -r TEST_STATEMENT_DESC_RESPONSE="([FILE]=\"${TEST_STATEMENT_DESC_TEST_FILE}\" [CACHING]=0)"
declare -r TEST_STATEMENT_DESC_REQUEST='([FULL]="0" [VIEW]="0" [QUERY]="DESC CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="DESC" [METHOD]="desc" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [API_VERSION]="v201601" )'
declare -r TEST_STATEMENT_DESC_FULL_REQUEST='([FULL]="1" [VIEW]="0" [QUERY]="desc full CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="desc full" [METHOD]="desc" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [API_VERSION]="v201601" )'
declare -r TEST_STATEMENT_DESC_FULL_FIELD_REQUEST='([FULL]="1" [VIEW]="0" [QUERY]="desc full CAMPAIGN_PERFORMANCE_REPORT CampaignId" [STATEMENT]="desc full" [METHOD]="desc" [FIELD]="CampaignId" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [API_VERSION]="v201601" )'
declare -r TEST_STATEMENT_DESC_FIELD_REQUEST='([FULL]="0" [VIEW]="0" [QUERY]="DESC CAMPAIGN_PERFORMANCE_REPORT CampaignId" [STATEMENT]="DESC" [METHOD]="desc" [FIELD]="CampaignId" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [API_VERSION]="v201601" )'
declare -r TEST_STATEMENT_DESC_VIEW_REQUEST='([FULL]="0" [VIEW]="1" [QUERY]="DESC CAMPAIGN_REPORT" [STATEMENT]="DESC" [METHOD]="desc" [TABLE]="CAMPAIGN_REPORT" [API_VERSION]="v201601" )'
declare -r TEST_STATEMENT_DESC_VIEW_FIELD_REQUEST='([FULL]="0" [VIEW]="1" [QUERY]="DESC CAMPAIGN_REPORT Id" [STATEMENT]="DESC" [METHOD]="desc" [FIELD]="Id" [TABLE]="CAMPAIGN_REPORT" [API_VERSION]="v201601" )'


readonly TEST_AWQL_DESC="-11-11-11-01-01-01-01-01-01-0"

function test_awqlDesc ()
{
    local test

    #0 Clean workspace
    rm -f "${TEST_STATEMENT_DESC_TEST_FILE}"

    #1 Check nothing
    test=$(awqlDesc)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #2 Check with no query and invalid file destination
    test=$(awqlDesc "" "${TEST_STATEMENT_DESC_ERROR_FILE}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #3 Check with valid query and invalid file destination
    test=$(awqlDesc "${TEST_STATEMENT_DESC_REQUEST}" "${TEST_STATEMENT_DESC_ERROR_FILE}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_DATA_FILE}" ]] && echo -n 1

    #4 Check with valid query and file destination
    test=$(awqlDesc "${TEST_STATEMENT_DESC_REQUEST}" "${TEST_STATEMENT_DESC_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_DESC_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_DESC_TEST_FILE}" "${TEST_STATEMENT_DESC_FILE}")" ]] && echo -n 1

    #5 Check with full desc query
    test=$(awqlDesc "${TEST_STATEMENT_DESC_FULL_REQUEST}" "${TEST_STATEMENT_DESC_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_DESC_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_DESC_TEST_FILE}" "${TEST_STATEMENT_DESC_FULL_FILE}")" ]] && echo -n 1

    #6 Check with full desc query
    test=$(awqlDesc "${TEST_STATEMENT_DESC_FULL_FIELD_REQUEST}" "${TEST_STATEMENT_DESC_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_DESC_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_DESC_TEST_FILE}" "${TEST_STATEMENT_DESC_FULL_FIELD_FILE}")" ]] && echo -n 1

    #7 Check with full desc query
    test=$(awqlDesc "${TEST_STATEMENT_DESC_FIELD_REQUEST}" "${TEST_STATEMENT_DESC_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_DESC_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_DESC_TEST_FILE}" "${TEST_STATEMENT_DESC_FIELD_FILE}")" ]] && echo -n 1

    #8 Check with full desc query
    test=$(awqlDesc "${TEST_STATEMENT_DESC_VIEW_REQUEST}" "${TEST_STATEMENT_DESC_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_DESC_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_DESC_TEST_FILE}" "${TEST_STATEMENT_DESC_VIEW_FILE}")" ]] && echo -n 1

    #9 Check with full desc query
    test=$(awqlDesc "${TEST_STATEMENT_DESC_VIEW_FIELD_REQUEST}" "${TEST_STATEMENT_DESC_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_DESC_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_DESC_TEST_FILE}" "${TEST_STATEMENT_DESC_VIEW_FIELD_FILE}")" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_STATEMENT_DESC_TEST_FILE}" ]]; then
        rm "${TEST_STATEMENT_DESC_TEST_FILE}"
        echo -n "-$?"
    fi
}


# Launch all functional tests
bashUnit "awqlDesc" "${TEST_AWQL_DESC}" "$(test_awqlDesc)"
