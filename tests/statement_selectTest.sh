#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/select.sh


readonly TEST_STATEMENT_ACCESS_TOKEN="-01"

function test_accessToken ()
{
    local test

    #1 Check nothing
    test=$(__accessToken)
    echo -n "-$?"
    [[ "$test" == "("*")" ]] && echo -n 1

    # @todo Complete unit tests
}


readonly TEST_STATEMENT_OAUTH="-01"

function test_oauth ()
{
    local test

    #1 Check nothing
    test=$(__oauth)
    echo -n "-$?"
    [[ "$test" == "("*")" ]] && echo -n 1

    # @todo Complete unit tests
}


readonly TEST_STATEMENT_AWQL_SELECT="-11"

function test_awqlSelect ()
{
    local test

    #1 Check nothing
    test=$(awqlSelect)
    echo -n "-$?"
    [[ "$test" == "${AWQL_INTERNAL_ERROR_CONFIG}" ]] && echo -n 1

    # @todo Complete unit tests
}


# Launch all functional tests
bashUnit "__accessToken" "${TEST_STATEMENT_ACCESS_TOKEN}" "$(test_accessToken)"
bashUnit "__oauth" "${TEST_STATEMENT_OAUTH}" "$(test_oauth)"
bashUnit "awqlSelect" "${TEST_STATEMENT_AWQL_SELECT}" "$(test_awqlSelect)"
