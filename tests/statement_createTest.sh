#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/statement/desc.sh

# Default entries


readonly TEST_SHOW_AWQL_DESC="-21"

function test_awqlDesc ()
{
    local test

    #1 Check nothing
    test=$(awqlDesc)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlDesc" "${TEST_SHOW_AWQL_DESC}" "$(test_awqlDesc)"
