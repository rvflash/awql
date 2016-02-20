#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../csv.sh

declare -r TEST_CSV_TMP_FILE="unit/_tmp.pcsv"
declare -r TEST_CSV_ONE_LINE_FILE="unit/one.csv"
declare -r TEST_CSV_MULTI_LINES_FILE="unit/lines.csv"
declare -r TEST_CSV_PRINTED_HEADER=" Campaign  | Clicks  | Impressions  | Cost       | Tracking template  "
declare -r TEST_CSV_BREAK_LINE_FOR_HEADER="+-----------+---------+--------------+------------+--------------------+"


##
# Basic function to test A with B and validate the behavior of a method
# @codeCoverageIgnore
# @param string $1 Method's name
# @param string $2 Expected string
# @param string $3 Received string to compare with expected string
# @exit 1 If one the three parameters are empty
function bashUnit ()
{
    local METHOD="$1"
    local EXPECTED="$2"
    local RECEIVED="$3"

    if [[ -z "$METHOD" || -z "$EXPECTED" || -z "$RECEIVED" ]]; then
        echo "Missing values for BashUnit testing tool"
        exit 1
    fi

    if [[ "${RECEIVED}" == "${EXPECTED}" ]]; then
        echo "Function ${METHOD}: OK"
    else
        echo "Function ${METHOD}: KO (Expected ${EXPECTED}, received ${RECEIVED})"
    fi
}


readonly TEST_CSV_BREAK_LINE="-01-01"

function test_csvBreakLine ()
{
    local TEST

    # Check nothing
    TEST=$(csvBreakLine)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with header
    TEST=$(csvBreakLine "${TEST_CSV_PRINTED_HEADER}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_CSV_BREAK_LINE_FOR_HEADER}" ]] && echo -n 1
}


readonly TEST_CSV_HORIZONTAL_MODE="-11-11-01-21-01-01-01"

function test_csvHorizontalMode ()
{
    local TEST

    # Check nothing
    TEST=$(csvHorizontalMode)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with unknown file path
    TEST=$(csvHorizontalMode "void.csv")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with valid file path but no destination file
    TEST=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}")
    echo -n "-$?"
    [[ -n "$TEST" && $(wc -l <<< "$TEST") -eq 5 ]] && echo -n 1

    # Check with valid file path but no destination file and quiet mode
    TEST=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}" "" 1)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with valid file path and destination file
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    TEST=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$TEST" && $(wc -l <<< "$TEST") -eq 5 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with valid file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    TEST=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}" 1)
    echo -n "-$?"
    [[ -z "$TEST" && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with absolute file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    TEST=$(csvHorizontalMode "${TEST_CSV_MULTI_LINES_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$TEST" && $(wc -l <<< "$TEST") -eq 27 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
}


readonly TEST_CSV_VERTICAL_MODE="-11-11-01-21-01-01-01"

function test_csvVerticalMode ()
{
    local TEST

    # Check nothing
    TEST=$(csvVerticalMode)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with unknown file path
    TEST=$(csvVerticalMode "void.csv")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with valid file path but no destination file
    TEST=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}")
    echo -n "-$?"
    [[ -n "$TEST" && $(wc -l <<< "$TEST") -eq 6 ]] && echo -n 1

    # Check with valid file path but no destination file and quiet mode
    TEST=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}" "" 1)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with valid file path and destination file
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    TEST=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$TEST" && $(wc -l <<< "$TEST") -eq 6 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with valid file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    TEST=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}" 1)
    echo -n "-$?"
    [[ -z "$TEST" && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with absolute file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    TEST=$(csvVerticalMode "${TEST_CSV_MULTI_LINES_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$TEST" && $(wc -l <<< "$TEST") -eq 92 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
}


# Launch all functional tests
bashUnit "csvBreakLine" "${TEST_CSV_BREAK_LINE}" "$(test_csvBreakLine)"
bashUnit "csvHorizontalMode" "${TEST_CSV_HORIZONTAL_MODE}" "$(test_csvHorizontalMode)"
bashUnit "csvVerticalMode" "${TEST_CSV_VERTICAL_MODE}" "$(test_csvVerticalMode)"