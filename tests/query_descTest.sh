#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/query/desc.sh

# Default entries
declare -r TEST_QUERY_API_VERSION="v201601"
declare -r TEST_QUERY_BAD_API_VERSION="v0883"
declare -r TEST_QUERY_INVALID_METHOD="UPDATE RV_REPORT SET R='v'"
# > Desc
declare -r TEST_QUERY_BASIC_DESC="DESC CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_QUERY_BASIC_DESC_REQUEST='([FULL]="0" [QUERY]="DESC CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="DESC" [METHOD]="desc" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" )'
declare -r TEST_QUERY_FULL_DESC="desc full CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_QUERY_FULL_DESC_REQUEST='([FULL]="1" [QUERY]="desc full CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="desc full" [METHOD]="desc" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" )'
declare -r TEST_QUERY_FULL_DESC_COLUMN="desc full CAMPAIGN_PERFORMANCE_REPORT CampaignId"
declare -r TEST_QUERY_FULL_DESC_COLUMN_REQUEST='([FULL]="1" [QUERY]="desc full CAMPAIGN_PERFORMANCE_REPORT CampaignId" [STATEMENT]="desc full" [METHOD]="desc" [FIELD]="CampaignId" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" )'
declare -r TEST_QUERY_DESC_COLUMN="DESC CAMPAIGN_PERFORMANCE_REPORT CampaignId"
declare -r TEST_QUERY_DESC_COLUMN_REQUEST='([FULL]="0" [QUERY]="DESC CAMPAIGN_PERFORMANCE_REPORT CampaignId" [STATEMENT]="DESC" [METHOD]="desc" [FIELD]="CampaignId" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" )'
declare -r TEST_QUERY_UNKNOWN_TABLE_DESC="DESC RV_REPORT"
declare -r TEST_QUERY_UNKNOWN_FIELD_DESC="DESC CAMPAIGN_PERFORMANCE_REPORT Rv"
declare -r TEST_QUERY_EMPTY_DESC="DESC "
declare -r TEST_QUERY_INCOMPLETE_DESC="DESC"
declare -r TEST_QUERY_STUPID_DESC="desc CAMPAIGN_PERFORMANCE_REPORT CampaignId CampaignName"


readonly TEST_QUERY_DESC_COMPONENTS="-11-11-11-01-21-21-21-21-21-01-01-01-21"

function test_awqlDescQuery ()
{
    local test

    #1 Check nothing
    test=$(awqlDescQuery)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_QUERY}" ]] && echo -n 1

    #2 Check with valid query but without api version
    test=$(awqlDescQuery "${TEST_QUERY_BASIC_DESC}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #3 Check with valid query and invalid api version
    test=$(awqlDescQuery "${TEST_QUERY_BASIC_DESC}" "${TEST_QUERY_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #4 Check with valid query and api version
    test=$(awqlDescQuery "${TEST_QUERY_BASIC_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_BASIC_DESC_REQUEST}" ]] && echo -n 1

    #5 Check with update query
    test=$(awqlDescQuery "${TEST_QUERY_INVALID_METHOD}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_METHOD}" ]] && echo -n 1

    #6 Check with incomplete query (without table name)
    test=$(awqlDescQuery "${TEST_QUERY_INCOMPLETE_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_MISSING_TABLE}" ]] && echo -n 1

    #7 Check with empty desc
    test=$(awqlDescQuery "${TEST_QUERY_EMPTY_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_MISSING_TABLE}" ]] && echo -n 1

    #8 Check with unknown table in select query
    test=$(awqlDescQuery "${TEST_QUERY_UNKNOWN_TABLE_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_UNKNOWN_TABLE}" ]] && echo -n 1

    #9 Check with known table but unknown field
    test=$(awqlDescQuery "${TEST_QUERY_UNKNOWN_FIELD_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_UNKNOWN_FIELD}" ]] && echo -n 1

    #10 Check with full query on known table
    test=$(awqlDescQuery "${TEST_QUERY_FULL_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_FULL_DESC_REQUEST}" ]] && echo -n 1

    #11 Check with full query on known table's field
    test=$(awqlDescQuery "${TEST_QUERY_FULL_DESC_COLUMN}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_FULL_DESC_COLUMN_REQUEST}" ]] && echo -n 1

    #12 Check with query on known table's field with vertical mode
    test=$(awqlDescQuery "${TEST_QUERY_DESC_COLUMN}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_DESC_COLUMN_REQUEST}" ]] && echo -n 1

    #13 Check with query on known table's field with vertical mode
    test=$(awqlDescQuery "${TEST_QUERY_STUPID_DESC}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_METHOD}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlDescQuery" "${TEST_QUERY_DESC_COMPONENTS}" "$(test_awqlDescQuery)"