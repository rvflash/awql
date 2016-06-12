#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/show.sh

# Default entries
declare -r TEST_STATEMENT_TEST_DIR="${PWD}/unit"
declare -r TEST_STATEMENT_SHOW_FILE="${TEST_STATEMENT_TEST_DIR}/show.csv"
declare -r TEST_STATEMENT_SHOW_FULL_FILE="${TEST_STATEMENT_TEST_DIR}/show-full.csv"
declare -r TEST_STATEMENT_SHOW_FULL_LIKE_FILE="${TEST_STATEMENT_TEST_DIR}/show-full-like.csv"
declare -r TEST_STATEMENT_SHOW_LIKE_FILE="${TEST_STATEMENT_TEST_DIR}/show-like.csv"
declare -r TEST_STATEMENT_SHOW_EMPTY_LIKE_FILE="${TEST_STATEMENT_TEST_DIR}/show-empty-like.csv"
declare -r TEST_STATEMENT_SHOW_FULL_WITH_FILE="${TEST_STATEMENT_TEST_DIR}/show-full-with.csv"
declare -r TEST_STATEMENT_SHOW_WITH_FILE="${TEST_STATEMENT_TEST_DIR}/show-with.csv"
declare -r TEST_STATEMENT_SHOW_ERROR_FILE="${TEST_STATEMENT_TEST_DIR}/123456789.txt"
declare -r TEST_STATEMENT_SHOW_TEST_FILE="${TEST_STATEMENT_TEST_DIR}/123456789${AWQL_FILE_EXT}"
declare -r TEST_STATEMENT_SHOW_RESPONSE="([FILE]=\"${TEST_STATEMENT_SHOW_TEST_FILE}\" [CACHING]=0)"
declare -r TEST_STATEMENT_SHOW_BASIC='([FULL]="0" [QUERY]="SHOW TABLES" [STATEMENT]="SHOW TABLES" [METHOD]="show" [API_VERSION]="v201605" )'
declare -r TEST_STATEMENT_SHOW_FULL='([FULL]="1" [QUERY]="show full tables" [STATEMENT]="show full tables" [METHOD]="show" [API_VERSION]="v201605" )'
declare -r TEST_STATEMENT_SHOW_FULL_LIKE='([FULL]="1" [QUERY]="SHOW FULL TABLES LIKE \"CAMPAIGN%\"" [STATEMENT]="SHOW FULL TABLES" [LIKE]="CAMPAIGN%" [METHOD]="show" [API_VERSION]="v201605" )'
declare -r TEST_STATEMENT_SHOW_LIKE="([FULL]=\"0\" [QUERY]=\"show tables like 'CAMPAIGN%'\" [STATEMENT]=\"show tables\" [LIKE]=\"CAMPAIGN%\" [METHOD]=\"show\" [API_VERSION]=\"v201605\" )"
declare -r TEST_STATEMENT_SHOW_EMPTY_LIKE='([FULL]="0" [QUERY]="SHOW TABLES LIKE \"\"" [STATEMENT]="SHOW TABLES" [LIKE]="" [METHOD]="show" [API_VERSION]="v201605" )'
declare -r TEST_STATEMENT_SHOW_FULL_WITH="([FULL]=\"1\" [QUERY]=\"show full tables with 'ViewThroughConversions'\" [STATEMENT]=\"show full tables\" [METHOD]=\"show\" [WITH]=\"ViewThroughConversions\" [API_VERSION]=\"v201605\" )"
declare -r TEST_STATEMENT_SHOW_WITH="([FULL]=\"0\" [QUERY]=\"SHOW TABLES WITH 'ViewThroughConversions'\" [STATEMENT]=\"SHOW TABLES\" [METHOD]=\"show\" [WITH]=\"ViewThroughConversions\" [API_VERSION]=\"v201605\" )"


readonly TEST_AWQL_SHOW="-11-11-11-01-01-01-01-01-01-01-0"

function test_awqlShow ()
{
    local test

    #0 Clean workspace
    rm -f "${TEST_STATEMENT_SHOW_TEST_FILE}"

    #1 Check nothing
    test=$(awqlShow)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #2 Check with no query and invalid file destination
    test=$(awqlShow "" "${TEST_STATEMENT_SHOW_ERROR_FILE}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    #3 Check with valid query and invalid file destination
    test=$(awqlShow "${TEST_STATEMENT_SHOW_BASIC}" "${TEST_STATEMENT_SHOW_ERROR_FILE}")
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_DATA_FILE}" ]] && echo -n 1

    #4 Check with valid query and file destination
    test=$(awqlShow "${TEST_STATEMENT_SHOW_BASIC}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_FILE}")" ]] && echo -n 1

    #5 Check with show full query
    test=$(awqlShow "${TEST_STATEMENT_SHOW_FULL}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_FULL_FILE}")" ]] && echo -n 1

    #6 Check with show full query like
    test=$(awqlShow "${TEST_STATEMENT_SHOW_FULL_LIKE}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_FULL_LIKE_FILE}")" ]] && echo -n 1

    #7 Check with show query like
    test=$(awqlShow "${TEST_STATEMENT_SHOW_LIKE}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_LIKE_FILE}")" ]] && echo -n 1

    #8 Check with show with empty like
    test=$(awqlShow "${TEST_STATEMENT_SHOW_EMPTY_LIKE}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_EMPTY_LIKE_FILE}")" ]] && echo -n 1

    #9 Check with show full query with
    test=$(awqlShow "${TEST_STATEMENT_SHOW_FULL_WITH}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_FULL_WITH_FILE}")" ]] && echo -n 1

    #10 Check with show query with
    test=$(awqlShow "${TEST_STATEMENT_SHOW_WITH}" "${TEST_STATEMENT_SHOW_TEST_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_STATEMENT_SHOW_RESPONSE}" && -z "$(diff "${TEST_STATEMENT_SHOW_TEST_FILE}" "${TEST_STATEMENT_SHOW_WITH_FILE}")" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_STATEMENT_SHOW_TEST_FILE}" ]]; then
        rm "${TEST_STATEMENT_SHOW_TEST_FILE}"
        echo -n "-$?"
    fi
}


# Launch all functional tests
bashUnit "awqlShow" "${TEST_AWQL_SHOW}" "$(test_awqlShow)"
