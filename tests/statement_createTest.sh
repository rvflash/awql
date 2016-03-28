#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/create.sh

# Default entries
declare -r TEST_STATEMENT_TEST_DIR="${PWD}/unit"
declare -r TEST_STATEMENT_CREATE_FILE="${TEST_STATEMENT_TEST_DIR}/view.yaml"
declare -r TEST_STATEMENT_CREATE_BASIC='([VIEW]="PRV_REPORT" [QUERY]="CREATE VIEW PRV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="0" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"Clicks DESC\" [SORT_ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_STATEMENT_REPLACE_BASIC='([VIEW]="PRV_REPORT" [QUERY]="CREATE VIEW PRV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="1" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"Clicks DESC\" [SORT_ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_STATEMENT_CREATE_NO_NAME='([VIEW]="" [QUERY]="CREATE VIEW PRV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="0" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"Clicks DESC\" [SORT_ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_STATEMENT_CREATE_NO_FIELDS='([VIEW]="PRV_REPORT" [QUERY]="CREATE VIEW PRV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="0" [FIELD_NAMES]="" [DEFINITION]="([VIEW]=\"0\" [QUERY]=\"SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC\" [STATEMENT]=\"SELECT\" [WHERE]=\"Impressions > O\" [METHOD]=\"select\" [ORDER]=\"Clicks DESC\" [SORT_ORDER]=\"n 5 1\" [TABLE]=\"CAMPAIGN_PERFORMANCE_REPORT\" [FIELD_NAMES]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" [AWQL_QUERY]=\"SELECT CampaignId,CampaignName,CampaignStatus,Impressions,Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O\" [FIELDS]=\"CampaignId CampaignName CampaignStatus Impressions Clicks\" )" )'
declare -r TEST_STATEMENT_CREATE_NO_QUERY='([VIEW]="PRV_REPORT" [QUERY]="CREATE VIEW PRV_REPORT AS SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O ORDER BY Clicks DESC" [STATEMENT]="CREATE VIEW" [METHOD]="create" [REPLACE]="0" [FIELD_NAMES]="CampaignId CampaignName CampaignStatus Impressions Clicks" [DEFINITION]="" )'


readonly TEST_AWQL_CREATE="-11-01-21-01-11-11-11-11-0"

function test_awqlCreate ()
{
    local test testFile

    # Clean workspace
    testFile="${AWQL_USER_VIEWS_DIR}/PRV_REPORT.yaml"
    rm -f "$testFile"

    #1 Check nothing
    test=$(awqlCreate)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #2 Check with basic create request
    test=$(awqlCreate "${TEST_STATEMENT_CREATE_BASIC}")
    echo -n "-$?"
    [[ "$test" == "()" && -f "$testFile" && -z "$(diff -b "${TEST_STATEMENT_CREATE_FILE}" "$testFile")" ]] && echo -n 1

    #3 Check with same create request without replace option
    test=$(awqlCreate "${TEST_STATEMENT_CREATE_BASIC}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_QUERY_ERROR_VIEW_ALREADY_EXISTS}" ]] && echo -n 1

    #4 Check with create request with replace option
    test=$(awqlCreate "${TEST_STATEMENT_REPLACE_BASIC}")
    echo -n "-$?"
    [[ "$test" == "()" && -f "$testFile" && -z "$(diff -b "${TEST_STATEMENT_CREATE_FILE}" "$testFile")" ]] && echo -n 1

    #5 Check with create view without name
    test=$(awqlCreate "${TEST_STATEMENT_CREATE_NO_NAME}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #6 Check with create view without name
    test=$(awqlCreate "${TEST_STATEMENT_CREATE_NO_QUERY}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #7 Check with create view without name
    test=$(awqlCreate "${TEST_STATEMENT_CREATE_NO_FIELDS}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #8 Check with create view without name
    test=$(awqlCreate "${TEST_STATEMENT_CREATE_NO_QUERY}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    # Clean workspace
    if [[ -f "$testFile" ]]; then
        rm "$testFile"
        echo -n "-$?"
    fi
}


# Launch all functional tests
bashUnit "awqlCreate" "${TEST_AWQL_CREATE}" "$(test_awqlCreate)"
