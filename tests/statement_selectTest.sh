#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/show.sh

# Default entries


readonly TEST_SHOW_AWQL_SHOW="-21"

function test_awqlShow ()
{
    local test

    #1 Check nothing
    test=$(awqlShow)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlShow" "${TEST_SHOW_AWQL_SHOW}" "$(test_awqlShow)"
