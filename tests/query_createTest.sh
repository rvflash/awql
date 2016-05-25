#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/query/create.sh

# Default entries
declare -r TEST_QUERY_API_ID="123-456-7890"
declare -r TEST_QUERY_API_VERSION="v201603"
declare -r TEST_QUERY_BAD_API_VERSION="v0883"
declare -r TEST_QUERY_INVALID_METHOD="UPDATE RV_REPORT SET R='v'"
# > Create
declare -r TEST_QUERY_BASIC_CREATE="CREATE VIEW RV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_BASIC_CREATE_REQUEST='([VIEW]="RV_REPORT" [QUERY]="CREATE VIEW RV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="0" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [AWQL_QUERY]="CREATE VIEW RV_REPORT (CampaignId CampaignName CampaignStatus Impressions Clicks) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC " [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [AGGREGATES]=\"()\" [GROUP]=\"\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_QUERY_REPLACE_CREATE="CREATE OR REPLACE VIEW RV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_REPLACE_CREATE_REQUEST='([VIEW]="RV_REPORT" [QUERY]="CREATE OR REPLACE VIEW RV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE OR REPLACE VIEW" [METHOD]="create" [REPLACE]="1" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [AWQL_QUERY]="CREATE OR REPLACE VIEW RV_REPORT (CampaignId CampaignName CampaignStatus Impressions Clicks) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC " [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [AGGREGATES]=\"()\" [GROUP]=\"\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_QUERY_FULL_CREATE="CREATE OR REPLACE VIEW RV_REPORT (Id, Name, Status, Impressions, Clicks) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_FULL_CREATE_REQUEST='([VIEW]="RV_REPORT" [QUERY]="CREATE OR REPLACE VIEW RV_REPORT (Id, Name, Status, Impressions, Clicks) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE OR REPLACE VIEW" [METHOD]="create" [REPLACE]="1" [FIELD_NAMES]="Id Name Status Impressions Clicks" [AWQL_QUERY]="CREATE OR REPLACE VIEW RV_REPORT (Id Name Status Impressions Clicks) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC " [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [AGGREGATES]=\"()\" [GROUP]=\"\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_QUERY_CREATE_COLUMN_NOT_MATCH="CREATE VIEW RV_REPORT (Id,Name,Status) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_CREATE_NO_VIEW_NAME="CREATE VIEW (Id,Name,Status) AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_CREATE_NO_SELECT="CREATE VIEW RV_REPORT AS"
declare -r TEST_QUERY_CREATE_NO_AS="CREATE VIEW RV_REPORT (Id,Name,Status) SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_CREATE_BAD_QUERY="CREATE VIEW RV_REPORT (Id,Name,Status) AS SELECT * FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_CREATE_INCOMPLETE_QUERY="CREATE"
declare -r TEST_QUERY_REDUNDANT_VIEW_CREATE="CREATE VIEW CAMPAIGN_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_TABLE_EXISTS_CREATE="CREATE VIEW CAMPAIGN_PERFORMANCE_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"
declare -r TEST_QUERY_RESERVED_KEYWORD_CREATE="CREATE VIEW WHERE AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC"


readonly TEST_AWQL_CREATE="-11-11-11-01-21-01-01-21-21-21-21-21-21-21-21-21"

function test_awqlCreateQuery ()
{
    local test

    #1 Check nothing
    test=$(awqlCreateQuery)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_QUERY}" ]] && echo -n 1

    #2 Check with valid query but without api version
    test=$(awqlCreateQuery "${TEST_QUERY_BASIC_CREATE}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #3 Check with valid query and invalid api version
    test=$(awqlCreateQuery "${TEST_QUERY_BASIC_CREATE}" "${TEST_QUERY_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_API_VERSION}" ]] && echo -n 1

    #4 Check with valid query and api version
    test=$(awqlCreateQuery "${TEST_QUERY_BASIC_CREATE}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_BASIC_CREATE_REQUEST}" ]] && echo -n 1

    #5 Check with update query
    test=$(awqlCreateQuery "${TEST_QUERY_INVALID_METHOD}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_METHOD}" ]] && echo -n 1

    #6 Check with create or replace query
    test=$(awqlCreateQuery "${TEST_QUERY_REPLACE_CREATE}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_REPLACE_CREATE_REQUEST}" ]] && echo -n 1

    #7 Check with create or replace query with specified column names
    test=$(awqlCreateQuery "${TEST_QUERY_FULL_CREATE}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_QUERY_FULL_CREATE_REQUEST}" ]] && echo -n 1

    #8 Check with create or replace query with specified column names
    test=$(awqlCreateQuery "${TEST_QUERY_CREATE_COLUMN_NOT_MATCH}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_COLUMNS_NOT_MATCH}" ]] && echo -n 1

    #9 Check with create with no view name
    test=$(awqlCreateQuery "${TEST_QUERY_CREATE_NO_VIEW_NAME}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_VIEW}" ]] && echo -n 1

    #10 Check with create with no select as source
    test=$(awqlCreateQuery "${TEST_QUERY_CREATE_NO_SELECT}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_MISSING_SOURCE}" ]] && echo -n 1

    #11 Check with missing "AS" keyword to identify source query
    test=$(awqlCreateQuery "${TEST_QUERY_CREATE_NO_AS}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_SYNTAX}" ]] && echo -n 1

    #12 Check with bad source query
    test=$(awqlCreateQuery "${TEST_QUERY_CREATE_BAD_QUERY}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_INVALID_SOURCE}" ]] && echo -n 1

    #13 Check with incomplete query
    test=$(awqlCreateQuery "${TEST_QUERY_CREATE_INCOMPLETE_QUERY}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_VIEW}" ]] && echo -n 1

    #14 Check with existing view name
    test=$(awqlCreateQuery "${TEST_QUERY_REDUNDANT_VIEW_CREATE}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_VIEW_ALREADY_EXISTS}" ]] && echo -n 1

    #15 Check with existing table name
    test=$(awqlCreateQuery "${TEST_QUERY_TABLE_EXISTS_CREATE}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_TABLE}" ]] && echo -n 1

    #16 Check with reserved keyword for view name
    test=$(awqlCreateQuery "${TEST_QUERY_RESERVED_KEYWORD_CREATE}" "${TEST_QUERY_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_VIEW}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlCreateQuery" "${TEST_AWQL_CREATE}" "$(test_awqlCreateQuery)"