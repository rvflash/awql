#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../csv.sh

# Constants
declare -r CSV_COLOR_RED_BG='\033[101m'
declare -r CSV_COLOR_GREEN_BG='\033[42m'
declare -r CSV_COLOR_RED='\033[0;31m'
declare -r CSV_COLOR_GREEN='\033[0;32m'
declare -r CSV_COLOR_YELLOW='\033[0;33m'
declare -r CSV_COLOR_GRAY='\033[0;90m'
declare -r CSV_COLOR_OFF='\033[0m'

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
# @exit 1 If one of the three parameters are empty
function bashUnit ()
{
    local method="$1"
    local expected="$2"
    local received="$3"

    if [[ -z "$method" || -z "$expected" || -z "$received" ]]; then
        echo -i "${CSV_COLOR_RED}Missing values for BashUnit testing tool${CSV_COLOR_OFF}"
        exit 1
    fi

    echo -ne "${CSV_COLOR_GRAY}Function${CSV_COLOR_OFF} ${method}: "

    if [[ "$received" == "$expected" ]]; then
        echo -ne "${CSV_COLOR_GREEN}OK${CSV_COLOR_OFF}\n"
    else
        echo -ne "${CSV_COLOR_YELLOW}KO${CSV_COLOR_OFF}\n"
        echo -ne "    > ${CSV_COLOR_GREEN}Expected:${CSV_COLOR_OFF} ${CSV_COLOR_GREEN_BG}${expected}${CSV_COLOR_OFF}\n"
        echo -ne "    > ${CSV_COLOR_RED}Received:${CSV_COLOR_OFF} ${CSV_COLOR_RED_BG}${received}${CSV_COLOR_OFF}\n"
    fi
}


readonly TEST_CSV_BREAK_LINE="-01-01"

function test_csvBreakLine ()
{
    local test

    # Check nothing
    test=$(csvBreakLine)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with header
    test=$(csvBreakLine "${TEST_CSV_PRINTED_HEADER}")
    echo -n "-$?"
    [[ "$test" == "${TEST_CSV_BREAK_LINE_FOR_HEADER}" ]] && echo -n 1
}


readonly TEST_CSV_HORIZONTAL_MODE="-11-11-01-21-01-01-01"

function test_csvHorizontalMode ()
{
    local test

    # Check nothing
    test=$(csvHorizontalMode)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with unknown file path
    test=$(csvHorizontalMode "void.csv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with valid file path but no destination file
    test=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}")
    echo -n "-$?"
    [[ -n "$test" && $(wc -l <<< "$test") -eq 5 ]] && echo -n 1

    # Check with valid file path but no destination file and quiet mode
    test=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}" "" 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with valid file path and destination file
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    test=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$test" && $(wc -l <<< "$test") -eq 5 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with valid file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    test=$(csvHorizontalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}" 1)
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with absolute file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    test=$(csvHorizontalMode "${TEST_CSV_MULTI_LINES_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$test" && $(wc -l <<< "$test") -eq 27 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
}


readonly TEST_CSV_VERTICAL_MODE="-11-11-01-21-01-01-01"

function test_csvVerticalMode ()
{
    local test

    # Check nothing
    test=$(csvVerticalMode)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with unknown file path
    test=$(csvVerticalMode "void.csv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with valid file path but no destination file
    test=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}")
    echo -n "-$?"
    [[ -n "$test" && $(wc -l <<< "$test") -eq 6 ]] && echo -n 1

    # Check with valid file path but no destination file and quiet mode
    test=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}" "" 1)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with valid file path and destination file
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    test=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$test" && $(wc -l <<< "$test") -eq 6 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with valid file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    test=$(csvVerticalMode "${TEST_CSV_ONE_LINE_FILE}" "${TEST_CSV_TMP_FILE}" 1)
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Check with absolute file path, valid destination file and silent mode
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
    test=$(csvVerticalMode "${TEST_CSV_MULTI_LINES_FILE}" "${TEST_CSV_TMP_FILE}")
    echo -n "-$?"
    [[ -n "$test" && $(wc -l <<< "$test") -eq 92 && -f "${TEST_CSV_TMP_FILE}" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_CSV_TMP_FILE}" ]]; then
        rm -f "${TEST_CSV_TMP_FILE}"
    fi
}


# Launch all functional tests
bashUnit "csvBreakLine" "${TEST_CSV_BREAK_LINE}" "$(test_csvBreakLine)"
bashUnit "csvHorizontalMode" "${TEST_CSV_HORIZONTAL_MODE}" "$(test_csvHorizontalMode)"
bashUnit "csvVerticalMode" "${TEST_CSV_VERTICAL_MODE}" "$(test_csvVerticalMode)"