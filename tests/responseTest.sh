#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/response.sh

# Default entries
declare -r -i TEST_PRINT_FILE_SIZE=1908
declare -r TEST_PRINT_DURATION="0.93"
declare -r TEST_PRINT_TEST_DIR="${PWD}/unit"
declare -r TEST_PRINT_UNKNOWN_CSV_FILE="/awql/file.csv"
declare -r TEST_PRINT_HEADER_FILE="${TEST_PRINT_TEST_DIR}/test00.csv"
declare -r TEST_PRINT_HEADER_AWQL_FILE="${TEST_PRINT_TEST_DIR}/test00.awql"
declare -r TEST_PRINT_CSV_FILE="${TEST_PRINT_TEST_DIR}/test01.csv"
declare -r TEST_PRINT_AWQL_FILE="${TEST_PRINT_TEST_DIR}/test01.awql"
declare -r TEST_PRINT_AWQL_FILE_ONE_LIMITED="${TEST_PRINT_TEST_DIR}/test01_1.awql"
declare -r TEST_PRINT_AWQL_FILE_LIMIT_OFFSET3="${TEST_PRINT_TEST_DIR}/test01_3.awql"
declare -r TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3="${TEST_PRINT_TEST_DIR}/test01_2-3.awql"
declare -r TEST_PRINT_RANGE_LIMIT="2 3"
declare -r TEST_PRINT_ALPHA_ORDER="d 2 0"
declare -r TEST_PRINT_NUMERIC_DESC_ORDER="n 3 1"
declare -r TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3_ORDER_TEXT2_ASC="${TEST_PRINT_TEST_DIR}/test01_2-3_k2-0.awql"
declare -r TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3_ORDER_NUMERIC3_DESC="${TEST_PRINT_TEST_DIR}/test01_2-3_k3-1.awql"
declare -r TEST_PRINT_PRINT_CSV_FILE="${TEST_PRINT_TEST_DIR}/test01.pcsv"
declare -r TEST_PRINT_VPRINT_CSV_FILE="${TEST_PRINT_TEST_DIR}/test01-g.pcsv"
declare -r TEST_PRINT_HPRINT_CSV_FILE="${TEST_PRINT_TEST_DIR}/test01-h.pcsv"
declare -r TEST_PRINT_HVPRINT_CSV_FILE="${TEST_PRINT_TEST_DIR}/test01-hg.pcsv"
declare -r TEST_PRINT_HEADERS="Day,Id,Name,Clicks,Impressions,Cost,Mobile Url,Status,Url"
declare -r TEST_PRINT_EMPTY="$(echo -e "Empty set (0.00 sec) \n")"
declare -r TEST_PRINT_ONE_LINE_WITH_HEADER="$(echo -e "1 row in set (0.00 sec) \n")"
declare -r TEST_PRINT_ALL_LINE="$(echo -e "$((${TEST_PRINT_FILE_SIZE}-1)) rows in set (${TEST_PRINT_DURATION} sec) \n")"
declare -r TEST_PRINT_ALL_LINE_CACHED_FILE="$(echo -e "$((${TEST_PRINT_FILE_SIZE}-1)) rows in set (${TEST_PRINT_DURATION} sec) @source ${TEST_PRINT_CSV_FILE} @cached\n")"
declare -r TEST_PRINT_ALL_LINE_FILE="$(echo -e "$((${TEST_PRINT_FILE_SIZE}-1)) rows in set (${TEST_PRINT_DURATION} sec) @source ${TEST_PRINT_CSV_FILE}\n")"


readonly TEST_AGGREGATE_ROWS="-11"

function test_aggregateRows ()
{
    local test

    #1 Check nothing
    test=$(__aggregateRows)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_LIMIT_ROWS="-11"

function test_limitRows ()
{
    local test

    #1 Check nothing
    test=$(__limitRows)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_SORTING_ROWS="-11"

function test_sortingRows ()
{
    local test

    #1 Check nothing
    test=$(__sortingRows)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_PRINT_CONTEXT="-01-01-01-01-01-01-01-01-01-01-01"

function test_printContext ()
{
    local test

    #1 Check nothing
    test=$(__printContext)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_EMPTY}" ]] && echo -n 1

    #2 Check with unknown AWQL file
    test=$(__printContext "${TEST_PRINT_UNKNOWN_CSV_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_EMPTY}" ]] && echo -n 1

    #3 Check with unknown AWQL file and file size with only header
    test=$(__printContext "${TEST_PRINT_UNKNOWN_CSV_FILE}" 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_EMPTY}" ]] && echo -n 1

    #4 Check with unknown AWQL file and file size with only one line with header
    test=$(__printContext "${TEST_PRINT_UNKNOWN_CSV_FILE}" 2)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ONE_LINE_WITH_HEADER}" ]] && echo -n 1

    #5 Check with valid AWQL file, file size and time duration
    test=$(__printContext "${TEST_PRINT_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE}" ]] && echo -n 1

    #6 Check with unknown AWQL file, file size, time duration and cache
    test=$(__printContext "${TEST_PRINT_UNKNOWN_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}" 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE}" ]] && echo -n 1

    #7 Check with unknown AWQL file, file size, time duration, cache and verbose mode
    test=$(__printContext "${TEST_PRINT_UNKNOWN_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}" 1 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE}" ]] && echo -n 1

    #8 Check with valid AWQL file, file size and time duration
    test=$(__printContext "${TEST_PRINT_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE}" ]] && echo -n 1

    #9 Check with valid AWQL file, file size, time duration and cache
    test=$(__printContext "${TEST_PRINT_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}" 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE}" ]] && echo -n 1

    #10 Check with valid AWQL file, file size, time duration, cache and verbose mode
    test=$(__printContext "${TEST_PRINT_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}" 1 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE_CACHED_FILE}" ]] && echo -n 1

    #11 Check with valid AWQL file, file size, time duration, verbose mode but without cache
    test=$(__printContext "${TEST_PRINT_CSV_FILE}" ${TEST_PRINT_FILE_SIZE} "${TEST_PRINT_DURATION}" 0 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_ALL_LINE_FILE}" ]] && echo -n 1
}


readonly TEST_PRINT_FILE="-11-11-01-01-01-01"

function test_printFile ()
{
    local test

    #1 Check nothing
    test=$(__printFile)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with invalid file path
    test=$(__printFile "${TEST_PRINT_UNKNOWN_CSV_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid CSV file and default values for other parameters
    test=$(__printFile "${TEST_PRINT_CSV_FILE}")
    echo -n "-$?"
    [[ -n "$test" && -z "$(diff -b "${TEST_PRINT_PRINT_CSV_FILE}" <(echo "$test"))" ]] && echo -n 1

    #4 Check with valid CSV file and enable vertical display
    test=$(__printFile "${TEST_PRINT_CSV_FILE}" 1)
    echo -n "-$?"
    [[ -n "$test" && -z "$(diff -b "${TEST_PRINT_VPRINT_CSV_FILE}" <(echo "$test"))" ]] && echo -n 1

    #5 Check with valid CSV file and overloading for header line
    test=$(__printFile "${TEST_PRINT_CSV_FILE}" 0 "${TEST_PRINT_HEADERS}")
    echo -n "-$?"
    [[ -n "$test" && -z "$(diff -b "${TEST_PRINT_HPRINT_CSV_FILE}" <(echo "$test"))" ]] && echo -n 1

    #6 Check with valid CSV file and overloading for header line
    test=$(__printFile "${TEST_PRINT_CSV_FILE}" 1 "${TEST_PRINT_HEADERS}")
    echo -n "-$?"
    [[ -n "$test" && -z "$(diff -b "${TEST_PRINT_HVPRINT_CSV_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_AWQL_RESPONSE="-11"

function test_awqlResponse ()
{
    local test

    # Check nothing
    test=$(awqlResponse)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "__aggregateRows" "${TEST_AGGREGATE_ROWS}" "$(test_aggregateRows)"
bashUnit "__limitRows" "${TEST_LIMIT_ROWS}" "$(test_limitRows)"
bashUnit "__sortingRows" "${TEST_SORTING_ROWS}" "$(test_sortingRows)"
bashUnit "__printContext" "${TEST_PRINT_CONTEXT}" "$(test_printContext)"
bashUnit "__printFile" "${TEST_PRINT_FILE}" "$(test_printFile)"
bashUnit "awqlResponse" "${TEST_AWQL_RESPONSE}" "$(test_awqlResponse)"