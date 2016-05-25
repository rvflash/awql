#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/query/select.sh

# Default entries
declare -r TEST_QUERY_API_VERSION="v201603"
declare -r TEST_QUERY_BAD_API_VERSION="v0883"
declare -r TEST_QUERY_INVALID_METHOD="UPDATE RV_REPORT SET R='v'"
# > Select
declare -r TEST_QUERY_COLUMN="CampaignName"
declare -r TEST_QUERY_COLUMN_NAME="Name"
declare -r TEST_QUERY_COLUMN_NAME_FAIL="Name NONSENSE"
declare -r TEST_QUERY_COLUMNS="1,CampaignName"
declare -r TEST_QUERY_INVALID_GROUPS="1 CampaignName"
declare -r TEST_QUERY_FIELDS="CampaignId CampaignName Cost"
declare -r TEST_QUERY_FIELD_NAMES="Id Name Costs"
declare -r TEST_QUERY_AGGREGATES="([SUM]=\"3\" )"
declare -r TEST_QUERY_AGGREGATES_FAIL="([SUM]=\"2\" )"
declare -r TEST_QUERY_RESPONSE_SORT_ASC_ORDER="d 2 0"
declare -r TEST_QUERY_RESPONSE_SORT_DESC_ORDER="d 2 1"
declare -r TEST_QUERY_RESPONSE_NUMERIC_SORT_DESC_ORDER="n 3 1"
declare -r TEST_QUERY_SORT_COLUMNS="${TEST_QUERY_COLUMN_NAME},3 DESC"
declare -r TEST_QUERY_SORT_COLUMNS_FAIL="${TEST_QUERY_COLUMN_NAME},${TEST_QUERY_COLUMN_NAME_FAIL}"
declare -r TEST_QUERY_INCOMPLETE_SELECT="SELECT CampaignId"
declare -r TEST_QUERY_NO_TABLE_SELECT="SELECT CampaignId FROM"
declare -r TEST_QUERY_UNKNOWN_TABLE_SELECT="SELECT CampaignId FROM RV_REPORT"
declare -r TEST_QUERY_BASIC_SELECT_WITH_NO_ENDING="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_QUERY_BASIC_SELECT="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_QUERY_BASIC_REQUEST='([HEADERS]="" [VIEW]="0" [QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [METHOD]="select" [ORDER]="" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId" [AWQL_QUERY]="SELECT CampaignId FROM CAMPAIGN_PERFORMANCE_REPORT" [FIELDS]="CampaignId" )'
declare -r TEST_QUERY_WHERE_SELECT="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0"
declare -r TEST_QUERY_WHERE_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [WHERE]="Impressions > 0" [METHOD]="select" [ORDER]="" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName" [AWQL_QUERY]="SELECT CampaignId,CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [FIELDS]="CampaignId CampaignName" )'
declare -r TEST_QUERY_DURING_SELECT="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING 20160412,20160413"
declare -r TEST_QUERY_DURING_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING 20160412,20160413" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [WHERE]="Impressions > 0" [METHOD]="select" [DURING]="20160412 20160413" [ORDER]="" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName" [AWQL_QUERY]="SELECT CampaignId,CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING 20160412,20160413" [FIELDS]="CampaignId CampaignName" )'
declare -r TEST_QUERY_LITERAL_DURING_SELECT="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY"
declare -r TEST_QUERY_LITERAL_DURING_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [WHERE]="Impressions > 0" [METHOD]="select" [DURING]="YESTERDAY" [ORDER]="" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName" [AWQL_QUERY]="SELECT CampaignId,CampaignName FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY" [FIELDS]="CampaignId CampaignName" )'
declare -r TEST_QUERY_COMPLEX_SELECT="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY Cost DESC"
declare -r TEST_QUERY_COMPLEX_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY Cost DESC" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [WHERE]="Impressions > 0" [METHOD]="select" [ORDER]="n 3 1" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName Cost" [AWQL_QUERY]="SELECT CampaignId,CampaignName,Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [FIELDS]="CampaignId CampaignName Cost" )'
declare -r TEST_QUERY_COMPLETE_SELECT="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY ORDER BY 2 ASC LIMIT 5"
declare -r TEST_QUERY_COMPLETE_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY ORDER BY 2 ASC LIMIT 5" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [WHERE]="Impressions > 0" [METHOD]="select" [DURING]="YESTERDAY" [ORDER]="d 2 0" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName Cost" [LIMIT]="5" [AWQL_QUERY]="SELECT CampaignId,CampaignName,Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 DURING YESTERDAY" [FIELDS]="CampaignId CampaignName Cost" )'
declare -r TEST_QUERY_ORDERS_SELECT="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY 3 DESC, CampaignName"
declare -r TEST_QUERY_ORDERS_REQUEST='([VIEW]="0" [QUERY]="SELECT CampaignId, CampaignName, Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0 ORDER BY 3 DESC, CampaignName" [STATEMENT]="SELECT" [AGGREGATES]="()" [GROUP]="" [WHERE]="Impressions > 0" [METHOD]="select" [ORDER]="n 3 1,d 2 0" [TABLE]="CAMPAIGN_PERFORMANCE_REPORT" [FIELD_NAMES]="CampaignId CampaignName Cost" [AWQL_QUERY]="SELECT CampaignId,CampaignName,Cost FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > 0" [FIELDS]="CampaignId CampaignName Cost" )'


readonly TEST_QUERY_COLUMN_BY="-01-01-11-11-01-01-21-21"

function test_queryGroupBy ()
{
    local test

    #1 Check with nothing
    test=$(__queryGroupBy)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with empty first parameter
    test=$(__queryGroupBy "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with empty second parameter
    test=$(__queryGroupBy "${TEST_QUERY_COLUMN}" "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with empty third parameter
    test=$(__queryGroupBy "${TEST_QUERY_COLUMN}" "${TEST_QUERY_FIELDS}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with valid parameters, no aggregate, expected group by on second column
    test=$(__queryGroupBy "${TEST_QUERY_COLUMN}" "${TEST_QUERY_FIELDS}" "()")
    echo -n "-$?"
    [[ 2 -eq "$test" ]] && echo -n 1

    #6 Check with valid parameters, aggregate on third column, expected group by on first and second columns
    test=$(__queryGroupBy "${TEST_QUERY_COLUMNS}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_AGGREGATES}")
    echo -n "-$?"
    [[ "1 2" == "$test" ]] && echo -n 1

    #6 Check with invalid first parameter, aggregate on third column, expected group by on first and second columns
    test=$(__queryGroupBy "${TEST_QUERY_INVALID_GROUPS}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_AGGREGATES}")
    echo -n "-$?"
    [[ "${AWQL_QUERY_ERROR_GROUP} on '${TEST_QUERY_INVALID_GROUPS}'" == "$test" ]] && echo -n 1

    #7 Check with valid parameters, aggregate on second column, expected fail on group by
    test=$(__queryGroupBy "${TEST_QUERY_COLUMNS}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_AGGREGATES_FAIL}")
    echo -n "-$?"
    [[ "${AWQL_QUERY_ERROR_GROUP} on aggregated field named '${TEST_QUERY_COLUMN}'" == "$test" ]] && echo -n 1
}


readonly TEST_QUERY_ORDER="-01-01-01-11-01-01"

function test_queryOrder ()
{
    local test

    #1 Check nothing
    test=$(__queryOrder)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    #2 Check with ASC
    test=$(__queryOrder "ASC")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    #3 Check with asc
    test=$(__queryOrder "asc")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    #4 Check with anything
    test=$(__queryOrder "rv")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    #5 Check with DESC
    test=$(__queryOrder "DESC")
    echo -n "-$?"
    [[ "$test" -eq 1 ]] && echo -n 1

    #6 Check with desc
    test=$(__queryOrder "desc")
    echo -n "-$?"
    [[ "$test" -eq 1 ]] && echo -n 1
}


readonly TEST_QUERY_ORDER_TYPE="-01-01-01-01-01-01-01-01"

function test_queryOrderType ()
{
    local test

    #1 Check nothing
    test=$(__queryOrderType)
    echo -n "-$?"
    [[ "$test" == "d" ]] && echo -n 1

    #2 Check with string
    test=$(__queryOrderType "string")
    echo -n "-$?"
    [[ "$test" == "d" ]] && echo -n 1

    #3 Check with Double
    test=$(__queryOrderType "Double")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    #4 Check with Long
    test=$(__queryOrderType "Long")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    #5 Check with Money
    test=$(__queryOrderType "Money")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    #6 Check with Integer
    test=$(__queryOrderType "Integer")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    #7 Check with Byte
    test=$(__queryOrderType "Byte")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1

    #8 Check with int
    test=$(__queryOrderType "int")
    echo -n "-$?"
    [[ "$test" == "n" ]] && echo -n 1
}


readonly TEST_QUERY_SORT_ORDER="-01-11-11-11-11-01-01-01-21-01-21"

function test_querySortOrder ()
{
    local test

    #1 Check with nothing
    test=$(__querySortOrder)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with only first parameter
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid first both parameters
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME}" "${TEST_QUERY_FIELD_NAMES}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with missing last parameter named version
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME}" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with invalid last parameter named version
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME}" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_BAD_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with all valid parameters, expected ascendant sort on second column
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME}" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "${TEST_QUERY_RESPONSE_SORT_ASC_ORDER}" == "$test" ]] && echo -n 1

    #7 Check with all valid parameters, expected explicit ascendant sort on second column
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME} ASC" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "${TEST_QUERY_RESPONSE_SORT_ASC_ORDER}" == "$test" ]] && echo -n 1

    #8 Check with all valid parameters, expected explicit descendant sort on second column
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME} DESC" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "${TEST_QUERY_RESPONSE_SORT_DESC_ORDER}" == "$test" ]] && echo -n 1

    #9 Check with all valid parameters, expected explicit descendant sort on second column
    test=$(__querySortOrder "${TEST_QUERY_COLUMN_NAME_FAIL}" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "${AWQL_QUERY_ERROR_ORDER} with '${TEST_QUERY_COLUMN_NAME_FAIL}'" == "$test" ]] && echo -n 1

    #10 Check with all valid parameters, expected explicit ascendant sort on second column, descendant on third
    test=$(__querySortOrder "${TEST_QUERY_SORT_COLUMNS}" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "${TEST_QUERY_RESPONSE_SORT_ASC_ORDER},${TEST_QUERY_RESPONSE_NUMERIC_SORT_DESC_ORDER}" == "$test" ]] && echo -n 1

    #11 Check with with invalid order parameters, expected error on second order by
    test=$(__querySortOrder "${TEST_QUERY_SORT_COLUMNS_FAIL}" "${TEST_QUERY_FIELD_NAMES}" "${TEST_QUERY_FIELDS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "${AWQL_QUERY_ERROR_ORDER} with '${TEST_QUERY_COLUMN_NAME_FAIL}'" == "$test" ]] && echo -n 1
}


readonly TEST_QUERY_SELECT_COMPONENTS="-11-11-11-01-21-21-21-21-01-01-01-01-01-01"

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
    [[ "$test" == "${TEST_QUERY_ORDERS_REQUEST}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "__queryGroupBy" "${TEST_QUERY_COLUMN_BY}" "$(test_queryGroupBy)"
bashUnit "__queryOrder" "${TEST_QUERY_ORDER}" "$(test_queryOrder)"
bashUnit "__queryOrderType" "${TEST_QUERY_ORDER_TYPE}" "$(test_queryOrderType)"
bashUnit "__querySortOrder" "${TEST_QUERY_SORT_ORDER}" "$(test_querySortOrder)"
bashUnit "awqlSelectQuery" "${TEST_QUERY_SELECT_COMPONENTS}" "$(test_awqlSelectQuery)"