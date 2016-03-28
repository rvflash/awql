#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/main.sh

# Default entries


readonly TEST_MAIN_GET_DATA_FROM_CACHE="-21"

function test_getDataFromCache ()
{
    local test

    #1 Check nothing
    test=$(__getDataFromCache)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_MAIN_GET_DATA="-21"

function test_getData ()
{
    local test

    #1 Check nothing
    test=$(__getData)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_MAIN_AWQL="-21"

function test_awql ()
{
    local test

    #1 Check nothing
    test=$(awql)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "__getDataFromCache" "${TEST_MAIN_GET_DATA_FROM_CACHE}" "$(test_getDataFromCache)"
bashUnit "__getData" "${TEST_MAIN_GET_DATA}" "$(test_getData)"
bashUnit "awql" "${TEST_MAIN_AWQL}" "$(test_awql)"