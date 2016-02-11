#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../array.sh

# Default entries
declare -r TEST_ARRAY_FROM_STRING="first second third fourth"
declare -r TEST_ARRAY_FROM_STRING_PLUS="first second third fourth fifth sixth seventh"
declare -r TEST_ARRAY_FROM_STRING_MINUS="first second"
declare -r TEST_ARRAY_FROM_STRING_SURROUND="(first second third fourth)"
declare -r TEST_ARRAY_NUMERIC_INDEX="([0]=\"first\" [1]=\"second\" [2]=\"third\" [3]=\"fourth\")"
declare -r TEST_ARRAY_ASSOCIATIVE_INDEX="([\"one\"]=\"first\" [\"two\"]=\"second\" [\"three\"]=\"third\" [\"four\"]=\"fourth\")"
declare -r TEST_ARRAY_ASSOCIATIVE_INDEX_DIFF="([four]=\"fourth\" [three]=\"third\" )"
declare -r TEST_ARRAY_DECLARE_ASSOCIATIVE_INDEX="declare -A rv='${TEST_ARRAY_ASSOCIATIVE_INDEX}'"
declare -r TEST_ARRAY_DECLARE_NUMERIC_INDEX="declare -a RV='${TEST_ARRAY_NUMERIC_INDEX}'"
declare -r TEST_ARRAY_NUMERIC_INDEX_DIFF="([2]=\"third\" [3]=\"fourth\")"

readonly TEST_ARRAY_ARRAY_DIFF="-01-01-01-01-01"

function test_arrayDiff ()
{
    local TEST

    # Check nothing
    TEST=$(arrayDiff)
    echo -n "-$?"
    [[ "$TEST" == "()" ]] && echo -n 1

    # Check with only first parameter
    TEST=$(arrayDiff "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ARRAY_NUMERIC_INDEX}" ]] && echo -n 1

    # Check with arrays with no difference
    TEST=$(arrayDiff "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$TEST" == "()" ]] && echo -n 1

    # Check with associative array with differences
    TEST=$(arrayDiff "${TEST_ARRAY_ASSOCIATIVE_INDEX}" "${TEST_ARRAY_FROM_STRING_MINUS}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ARRAY_ASSOCIATIVE_INDEX_DIFF}" ]] && echo -n 1

    # Check with numeric indexed arrays with differences
    TEST=$(arrayDiff "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_FROM_STRING_MINUS}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ARRAY_NUMERIC_INDEX_DIFF}" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_SEARCH="-11-11-11-01-01-01"

function test_arraySearch ()
{
    local TEST

    # Check nothing
    TEST=$(arraySearch)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with empty needle
    TEST=$(arraySearch "" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check with empty haystack
    TEST=$(arraySearch "third" "")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check in basic array
    TEST=$(arraySearch "third" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$TEST" -eq 2 ]] && echo -n 1

    # Check in numeric indexed array
    TEST=$(arraySearch "third" "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$TEST" -eq 2 ]] && echo -n 1

    # Check in associative array
    TEST=$(arraySearch "third" "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$TEST" == "three" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_TO_STRING="-01-01-01-01"

function test_arrayToString ()
{
    local TEST

    # Check nothing
    TEST=$(arrayToString)
    echo -n "-$?"
    [[ "$TEST" == "()" ]] && echo -n 1

    # Simple string
    TEST=$(arrayToString "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ARRAY_FROM_STRING_SURROUND}" ]] && echo -n 1

    # Associative declared associative array
    TEST=$(arrayToString "${TEST_ARRAY_DECLARE_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ARRAY_ASSOCIATIVE_INDEX}" ]] && echo -n 1

    # Associative declared indexed array
    TEST=$(arrayToString "${TEST_ARRAY_DECLARE_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ARRAY_NUMERIC_INDEX}" ]] && echo -n 1
}


readonly TEST_ARRAY_COUNT="-01-01-01-01-01-01-01"

function test_count ()
{
    local TEST

    # Check nothing
    TEST=$(count)
    echo -n "-$?"
    [[ "$TEST" -eq 0 ]] && echo -n 1

    # Check empty array
    TEST=$(count "()")
    echo -n "-$?"
    [[ "$TEST" -eq 0 ]] && echo -n 1

    # Check empty array with only space inside
    TEST=$(count "( )")
    echo -n "-$?"
    [[ "$TEST" -eq 0 ]] && echo -n 1

    # Check associative array with values
    TEST=$(count "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$TEST" -eq 4 ]] && echo -n 1

    # Check array with values between parentheses
    TEST=$(count "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$TEST" -eq 4 ]] && echo -n 1

    # Check basic array with values
    TEST=$(count "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$TEST" -eq 4 ]] && echo -n 1

    # Check indexed array with values
    TEST=$(count "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$TEST" -eq 4 ]] && echo -n 1
}


readonly TEST_ARRAY_IN_ARRAY="-11-11-01-01-01"

function test_inArray ()
{
    local TEST

    # Check nothing
    TEST=$(inArray)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Search in basic array a unexisting value
    TEST=$(inArray "fifth" "${TEST_ARRAY_FROM_STRING}" )
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Search in basic array an existing value
    TEST=$(inArray "second" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Search in indexed array an existing value
    TEST=$(inArray "second" "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Search in associative array an existing value
    TEST=$(inArray "second" "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "arrayDiff" "${TEST_ARRAY_ARRAY_DIFF}" "$(test_arrayDiff)"
bashUnit "arraySearch" "${TEST_ARRAY_ARRAY_SEARCH}" "$(test_arraySearch)"
bashUnit "arrayToString" "${TEST_ARRAY_ARRAY_TO_STRING}" "$(test_arrayToString)"
bashUnit "count" "${TEST_ARRAY_COUNT}" "$(test_count)"
bashUnit "inArray" "${TEST_ARRAY_IN_ARRAY}" "$(test_inArray)"