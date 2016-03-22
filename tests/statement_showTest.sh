#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/main.sh

# Default entries
declare -r TEST_MAIN_TEST_DIR="${PWD}/unit"
declare -r TEST_MAIN_UNKNOWN_FILE="/awql/file.csv"
declare -r TEST_MAIN_DATA_FILE="${TEST_MAIN_TEST_DIR}/test00.csv"
declare -r TEST_MAIN_DATA_CACHED="([FILE]=\"${TEST_MAIN_TEST_DIR}/test00.csv\" [CACHING]=1)"


readonly TEST_MAIN_GET_DATA="-21"

function test_getData ()
{
    local test

    #1 Check nothing
    test=$(__getData)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_MAIN_GET_DATA_FROM_CACHE="-21-21-21-21-21-11-11-01"

function test_getDataFromCache ()
{
    local test

    #1 Check nothing
    test=$(__getDataFromCache)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with empty file
    test=$(__getDataFromCache "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with empty file and no cache
    test=$(__getDataFromCache "" 0)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with unknown file and no cache
    test=$(__getDataFromCache "${TEST_MAIN_UNKNOWN_FILE}" 0)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with valid file and no cache
    test=$(__getDataFromCache "${TEST_MAIN_DATA_FILE}" 0)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with empty file but cache enabled
    test=$(__getDataFromCache "" 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #7 Check with unknown file and cache enabled
    test=$(__getDataFromCache "${TEST_MAIN_UNKNOWN_FILE}" 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #8 Check with valid file and cache enabled
    test=$(__getDataFromCache "${TEST_MAIN_DATA_FILE}" 1)
    echo -n "-$?"
    [[ -n "$test" && "$test" == "${TEST_MAIN_DATA_CACHED}" ]] && echo -n 1
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
bashUnit "__getData" "${TEST_MAIN_GET_DATA_FROM_CACHE}" "$(test_getData)"
bashUnit "__getDataFromCache" "${TEST_MAIN_GET_DATA_FROM_CACHE}" "$(test_getDataFromCache)"
bashUnit "awql" "${TEST_MAIN_AWQL}" "$(test_awql)"
