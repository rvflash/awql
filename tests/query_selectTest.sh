#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/query/select.sh

# Default entries
declare -r TEST_QUERY_API_VERSION="v201601"
declare -r TEST_QUERY_BAD_API_VERSION="v0883"
declare -r TEST_QUERY_INVALID_METHOD="UPDATE RV_REPORT SET R='v'"
# > Select
declare -r TEST_QUERY_INCOMPLETE_SELECT="SELECT CampaignId"
declare -r TEST_QUERY_NO_TABLE_SELECT="SELECT CampaignId FROM"
declare -r TEST_QUERY_UNKNOWN_TABLE_SELECT="SELECT CampaignId FROM RV_REPORT"
declare -r TEST_QUERY_BASIC_SELECT_WITH_NO_ENDING="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_QUERY_BASIC_SELECT="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_QUERY_BASIC_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="SELECT" [METHOD]="select" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId" [AWQL_QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [FIELDS]="CampaignId" )'
declare -r TEST_QUERY_WHERE_SELECT="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0"
declare -r TEST_QUERY_WHERE_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [STATEMENT]="SELECT" [WHERE]="Impressions > 0" [METHOD]="select" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName" [AWQL_QUERY]="SELECT CampaignId,CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [FIELDS]="CampaignId CampaignName" )'
declare -r TEST_QUERY_DURING_SELECT="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING 20160412,20160413"
declare -r TEST_QUERY_DURING_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING 20160412,20160413" [STATEMENT]="SELECT" [WHERE]="Impressions > 0" [METHOD]="select" [DURING]="20160412 20160413" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName" [AWQL_QUERY]="SELECT CampaignId,CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING 20160412,20160413" [FIELDS]="CampaignId CampaignName" )'
declare -r TEST_QUERY_LITERAL_DURING_SELECT="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY"
declare -r TEST_QUERY_LITERAL_DURING_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY" [STATEMENT]="SELECT" [WHERE]="Impressions > 0" [METHOD]="select" [DURING]="YESTERDAY" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName" [AWQL_QUERY]="SELECT CampaignId,CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY" [FIELDS]="CampaignId CampaignName" )'
declare -r TEST_QUERY_COMPLEX_SELECT="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY Cost DESC"
declare -r TEST_QUERY_COMPLEX_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY Cost DESC" [STATEMENT]="SELECT" [WHERE]="Impressions > 0" [METHOD]="select" [ORDER]="Cost DESC" [SORT_ORDER]="n 3 1" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName Cost" [AWQL_QUERY]="SELECT CampaignId,CampaignName,Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [FIELDS]="CampaignId CampaignName Cost" )'
declare -r TEST_QUERY_COMPLETE_SELECT="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY ORDER BY 2 ASC LIMIT 5"
declare -r TEST_QUERY_COMPLETE_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY ORDER BY 2 ASC LIMIT 5" [STATEMENT]="SELECT" [WHERE]="Impressions > 0" [METHOD]="select" [DURING]="YESTERDAY" [ORDER]="2 ASC" [SORT_ORDER]="d 2 0" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName Cost" [LIMIT]="5" [AWQL_QUERY]="SELECT CampaignId,CampaignName,Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY" [FIELDS]="CampaignId CampaignName Cost" )'
declare -r TEST_QUERY_ORDERS_SELECT="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY Cost DESC, CampaignName ASC"


readonly TEST_QUERY_ORDER="-01-01-01-01-01-01"

function test_queryOrder ()
{
    local test

    # Check nothing
    test=$(__queryOrder)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with ASC
    test=$(__queryOrder "ASC")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with asc
    test=$(__queryOrder "asc")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with anything
    test=$(__queryOrder "rv")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with DESC
    test=$(__queryOrder "DESC")
    echo -n "-$?"
    [[ "$test" -eq 1 ]] && echo -n 1

    # Check with desc
    test=$(__queryOrder "desc")
    echo -n "-$?"
    [[ "$test" -eq 1 ]] && echo -n 1
}


readonly TEST_QUERY_ORDER_TYPE="-01-01-01-01-01-01-01-01"

function test_queryOrderType ()
{
    local test

    # Check nothing
    test=$(__queryOrderType)
    echo -n "-$?"
    [[ "$test" == "d" ]] && echo -n 1

    # Check with string
    test=$(__queryOrderType "string")
    echo -n "-$?"
    [[ "$test" == "d" ]] && echo -n 1

    # Check with Double
    test=$(__queryOrderType "Double")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    # Check with Long
    test=$(__queryOrderType "Long")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    # Check with Money
    test=$(__queryOrderType "Money")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    # Check with Integer
    test=$(__queryOrderType "Integer")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    # Check with Byte
    test=$(__queryOrderType "Byte")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    # Check with int
    test=$(__queryOrderType "int")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1
}


readonly TEST_QUERY_SELECT_COMPONENTS="-11-11-11-01-21-21-21-21-01-01-01-01-01-21"

function test_awqlSelectQuery ()
{
    local test

    #1 Check nothing
    test=$(awqlSelectQuery)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_QUERY}" ]] && echo -n 1

    #2 Check with valid query but without api version
    test=$(awqlSelectQuery "${TEST_QUERY_BASIC_SELECT}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #3 Check with valid query and invalid api version
    test=$(awqlSelectQuery "${TEST_QUERY_BASIC_SELECT}" "${TEST_QUERY_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #4 Check with valid query and api version
    test=$(awqlSelectQuery "${TEST_QUERY_BASIC_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_BASIC_REQUEST}" ]] && echo -n 1

    #5 Check with update query
    test=$(awqlSelectQuery "${TEST_QUERY_INVALID_METHOD}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_METHOD}" ]] && echo -n 1

    #6 Check with incomplete select query
    test=$(awqlSelectQuery "${TEST_QUERY_INCOMPLETE_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1

    #7 Check with no table in select query
    test=$(awqlSelectQuery "${TEST_QUERY_NO_TABLE_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1

    #8 Check with unknown table in select query
    test=$(awqlSelectQuery "${TEST_QUERY_UNKNOWN_TABLE_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_TABLE}" ]] && echo -n 1

    #9 Check with with valid query with where clause
    test=$(awqlSelectQuery "${TEST_QUERY_WHERE_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_WHERE_REQUEST}" ]] && echo -n 1

    #10 Check with with valid query with during clause using dates
    test=$(awqlSelectQuery "${TEST_QUERY_DURING_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_DURING_REQUEST}" ]] && echo -n 1

    #11 Check with with valid query with where clause
    test=$(awqlSelectQuery "${TEST_QUERY_LITERAL_DURING_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_LITERAL_DURING_REQUEST}" ]] && echo -n 1

    #12 Check with with valid query with where and order clauses
    test=$(awqlSelectQuery "${TEST_QUERY_COMPLEX_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_COMPLEX_REQUEST}" ]] && echo -n 1

    #13 Check with with valid query with where, order and limit clauses
    test=$(awqlSelectQuery "${TEST_QUERY_COMPLETE_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_COMPLETE_REQUEST}" ]] && echo -n 1

    #14 Check with with valid query but multiple orders. Not supported yet
    test=$(awqlSelectQuery "${TEST_QUERY_ORDERS_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_MULTIPLE_ORDER}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "__queryOrder" "${TEST_QUERY_ORDER}" "$(test_queryOrder)"
bashUnit "__queryOrderType" "${TEST_QUERY_ORDER_TYPE}" "$(test_queryOrderType)"
bashUnit "awqlSelectQuery" "${TEST_QUERY_SELECT_COMPONENTS}" "$(test_awqlSelectQuery)"