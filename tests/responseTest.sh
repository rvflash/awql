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
declare -r TEST_PRINT_EMPTY="$(echo -e "Empty set (0.00 sec) \n")"
declare -r TEST_PRINT_ONE_LINE_WITH_HEADER="$(echo -e "1 row in set (0.00 sec) \n")"
declare -r TEST_PRINT_ALL_LINE="$(echo -e "$((${TEST_PRINT_FILE_SIZE}-1)) rows in set (${TEST_PRINT_DURATION} sec) \n")"
declare -r TEST_PRINT_ALL_LINE_CACHED_FILE="$(echo -e "$((${TEST_PRINT_FILE_SIZE}-1)) rows in set (${TEST_PRINT_DURATION} sec) @source ${TEST_PRINT_CSV_FILE} @cached\n")"
declare -r TEST_PRINT_ALL_LINE_FILE="$(echo -e "$((${TEST_PRINT_FILE_SIZE}-1)) rows in set (${TEST_PRINT_DURATION} sec) @source ${TEST_PRINT_CSV_FILE}\n")"


readonly TEST_PRINT_BUILD_DATA_FILE="-00-11-11-11-21-01-01-01-01-01-01"

function test_buildDataFile ()
{
    local test

    # Prepare workspace
    if [[ -n "${TEST_PRINT_TEST_DIR}" && -d "${TEST_PRINT_TEST_DIR}" ]]; then
        cp "${TEST_PRINT_HEADER_FILE}" "${TEST_PRINT_HEADER_AWQL_FILE}"
        echo -n "-$?"
        cp "${TEST_PRINT_CSV_FILE}" "${TEST_PRINT_AWQL_FILE}"
        echo -n "$?"
    fi

    #1 Check nothing
    test=$(__buildDataFile)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with unknown AWQL file
    test=$(__buildDataFile "${TEST_PRINT_UNKNOWN_CSV_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid file (not with .awql as extension, just .csv)
    test=$(__buildDataFile "${TEST_PRINT_CSV_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with valid AWQL file but with only header inside
    test=$(__buildDataFile "${TEST_PRINT_HEADER_AWQL_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with valid AWQL file
    test=$(__buildDataFile "${TEST_PRINT_AWQL_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_AWQL_FILE}" ]] && echo -n 1

    #6 Check with valid AWQL file and limited response to first result
    test=$(__buildDataFile "${TEST_PRINT_AWQL_FILE}" 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_AWQL_FILE_ONE_LIMITED}" ]] && echo -n 1

    #7 Check with valid AWQL file and limited response to line 2 at 5
    test=$(__buildDataFile "${TEST_PRINT_AWQL_FILE}" "${TEST_PRINT_RANGE_LIMIT}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3}" && "$(wc -l < "${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3}")" -eq 4 ]] && echo -n 1

    #8 Check with valid AWQL file and limited response to 3 lines
    test=$(__buildDataFile "${TEST_PRINT_AWQL_FILE}" 3)
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_AWQL_FILE_LIMIT_OFFSET3}" && "$(wc -l < "${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3}")" -eq 4 ]] && echo -n 1

    #9 Check with valid AWQL file and limited response to line 2 at 5 and order by ascendant campaign names (second column)
    test=$(__buildDataFile "${TEST_PRINT_AWQL_FILE}" "${TEST_PRINT_RANGE_LIMIT}" "${TEST_PRINT_ALPHA_ORDER}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3_ORDER_TEXT2_ASC}" && "$(wc -l <"${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3_ORDER_TEXT2_ASC}")" -eq 4 ]] && echo -n 1

    #10 Check with valid AWQL file and limited response to line 2 at 5 and order by descendant cost (third column)
    test=$(__buildDataFile "${TEST_PRINT_AWQL_FILE}" "${TEST_PRINT_RANGE_LIMIT}" "${TEST_PRINT_NUMERIC_DESC_ORDER}")
    echo -n "-$?"
    [[ "$test" == "${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3_ORDER_NUMERIC3_DESC}" && "$(wc -l < "${TEST_PRINT_AWQL_FILE_LIMIT_START2_OFFSET3_ORDER_NUMERIC3_DESC}")" -eq 4 ]] && echo -n 1

    # Clean workspace
    if [[ -n "${TEST_PRINT_TEST_DIR}" && -d "${TEST_PRINT_TEST_DIR}" && -n "${AWQL_FILE_EXT}" ]]; then
        rm -f "${TEST_PRINT_TEST_DIR}/"*${AWQL_FILE_EXT}
    fi
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


readonly TEST_PRINT_FILE="-11-11-01-01"

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
bashUnit "__buildDataFile" "${TEST_PRINT_BUILD_DATA_FILE}" "$(test_buildDataFile)"
bashUnit "__printContext" "${TEST_PRINT_CONTEXT}" "$(test_printContext)"
bashUnit "__printFile" "${TEST_PRINT_FILE}" "$(test_printFile)"
bashUnit "awqlResponse" "${TEST_AWQL_RESPONSE}" "$(test_awqlResponse)"