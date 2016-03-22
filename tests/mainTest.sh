#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../inc/reader.sh


readonly TEST_READER="-11"

function test_reader ()
{
    local test

    #1 Check nothing
    test=$(reader)
    echo -n "-$?$test"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "reader" "${TEST_READER}" "$(test_reader)"