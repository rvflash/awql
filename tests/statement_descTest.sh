#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/select.sh

# Default entries


readonly TEST_SHOW_AWQL_SELECT="-21"

function test_awqlSelect ()
{
    local test

    #1 Check nothing
    test=$(awqlSelect)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlSelect" "${TEST_SHOW_AWQL_SELECT}" "$(test_awqlSelect)"
