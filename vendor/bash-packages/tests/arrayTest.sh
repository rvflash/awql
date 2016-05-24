#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../array.sh

# Default entries
declare -r TEST_ARRAY_VALUE="third"
declare -r TEST_ARRAY_FROM_STRING="first second third fourth"
declare -r TEST_ARRAY_FROM_STRING_PLUS="first second third fourth fifth sixth seventh"
declare -r TEST_ARRAY_FROM_STRING_MINUS="first second"
declare -r TEST_ARRAY_FROM_STRING_SURROUND="(first second third fourth)"
declare -r TEST_ARRAY_NUMERIC_INDEX="([0]=\"first\" [1]=\"second\" [2]=\"third\" [3]=\"fourth\")"
declare -r TEST_ARRAY_ASSOCIATIVE_INDEX="([\"one\"]=\"first\" [\"two\"]=\"second\" [\"three\"]=\"third\" [\"four\"]=\"fourth\")"
declare -r TEST_ARRAY_ASSOCIATIVE_INDEX_DIFF="([four]=\"fourth\" [three]=\"third\" )"
declare -r TEST_ARRAY_ASSOCIATIVE_INDEX_OVER="([four]=\"fifth\")"
declare -r TEST_ARRAY_DECLARE_ASSOCIATIVE_INDEX="declare -A rv='${TEST_ARRAY_ASSOCIATIVE_INDEX}'"
declare -r TEST_ARRAY_DECLARE_NUMERIC_INDEX="declare -a RV='${TEST_ARRAY_NUMERIC_INDEX}'"
declare -r TEST_ARRAY_NUMERIC_INDEX_DIFF="([2]=\"third\" [3]=\"fourth\")"
declare -r TEST_ARRAY_MIXED_INDEX="([one]=\"1 one\" [two]=\"2 two\" [1]=\"1\")"
declare -r TEST_ARRAY_MERGE_NUMERIC_INDEX="([0]=\"first\" [1]=\"second\" [2]=\"third\" [3]=\"fourth\" [4]=\"first\" [5]=\"second\" [6]=\"third\" [7]=\"fourth\")"
declare -r TEST_ARRAY_MERGE_ASSOC_INDEX_WITH_MINUS="([four]=\"fourth\" [one]=\"first\" [two]=\"second\" [0]=\"first\" [1]=\"second\" [three]=\"third\" )"
declare -r TEST_ARRAY_MERGE_ASSOCIATIVE_INDEX="([four]=\"fifth\" [three]=\"third\" )"
declare -r TEST_ARRAY_COMBINE="([fourth]=\"fourth\" [third]=\"third\" [second]=\"second\" [first]=\"first\" )"
declare -r TEST_ARRAY_EMPTY_FILL_KEYS="([fourth]=\"\" [third]=\"\" [second]=\"\" [first]=\"\" )"
declare -r TEST_ARRAY_WITH_FILL_KEYS="([fourth]=\"third\" [third]=\"third\" [second]=\"third\" [first]=\"third\" )"
declare -r TEST_ARRAY_DUPLICATED_FROM_STRING="first second third second fourth first fourth"
declare -r TEST_ARRAY_DUPLICATED_NUMERIC_INDEX="([0]=\"first\" [1]=\"second\" [2]=\"second\" [3]=\"second\" [4]=\"fourth\" [5]=\"first\")"
declare -r TEST_ARRAY_DUPLICATED_ASSOCIATIVE_INDEX="([\"one\"]=\"first\" [\"two\"]=\"second\" [\"three\"]=\"second\" [\"four\"]=\"fourth\")"
declare -r TEST_ARRAY_UNIQUE_NUMERIC_INDEX="([0]=\"first\" [1]=\"second\" [4]=\"fourth\" )"
declare -r TEST_ARRAY_UNIQUE_ASSOCIATIVE_INDEX="([four]=\"fourth\" [one]=\"first\" [two]=\"second\" )"


readonly TEST_ARRAY_ARRAY_COMBINE="-01-11-01-11-01"

function test_arrayCombine ()
{
    local test

    # Check nothing
    test=$(arrayCombine)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    # Check with only first parameter
    test=$(arrayCombine "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with arrays with same values
    test=$(arrayCombine "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_COMBINE}" ]] && echo -n 1

    # Check with associative array with number of elements for each array isn't equal
    test=$(arrayCombine "${TEST_ARRAY_ASSOCIATIVE_INDEX}" "${TEST_ARRAY_FROM_STRING_MINUS}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with indexed array for keys and associative array for values. Bug: the order is not respected
    test=$(arrayCombine "${TEST_ARRAY_FROM_STRING_SURROUND}" "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ -n "$test" && "$test" != "()" && "$test" != "${TEST_ARRAY_COMBINE}" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_DIFF="-01-01-01-01-01"

function test_arrayDiff ()
{
    local test

    # Check nothing
    test=$(arrayDiff)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    # Check with only first parameter
    test=$(arrayDiff "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_NUMERIC_INDEX}" ]] && echo -n 1

    # Check with arrays with no difference
    test=$(arrayDiff "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    # Check with associative array with differences
    test=$(arrayDiff "${TEST_ARRAY_ASSOCIATIVE_INDEX}" "${TEST_ARRAY_FROM_STRING_MINUS}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_ASSOCIATIVE_INDEX_DIFF}" ]] && echo -n 1

    # Check with numeric indexed arrays with differences
    test=$(arrayDiff "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_FROM_STRING_MINUS}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_NUMERIC_INDEX_DIFF}" ]] && echo -n 1
}


readonly TEST_ARRAY_FILL_KEYS="-01-01-01-01-01"

function test_arrayFillKeys ()
{
    local test

    # Check nothing
    test=$(arrayFillKeys)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    # Check with no value as second parameter
    test=$(arrayFillKeys "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_EMPTY_FILL_KEYS}" ]] && echo -n 1

    # Check with empty value as second parameter
    test=$(arrayFillKeys "${TEST_ARRAY_FROM_STRING_SURROUND}" "")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_EMPTY_FILL_KEYS}" ]] && echo -n 1

    # Check with indexed array
    test=$(arrayFillKeys "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_VALUE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_WITH_FILL_KEYS}" ]] && echo -n 1

    # Check with associative array
    test=$(arrayFillKeys "${TEST_ARRAY_ASSOCIATIVE_INDEX}" "${TEST_ARRAY_VALUE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_WITH_FILL_KEYS}" ]] && echo -n 1
}


readonly TEST_ARRAY_KEY_EXISTS="-11-11-11-01-01"

function test_arrayKeyExists ()
{
    local test

    # Check nothing
    test=$(arrayKeyExists)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search with no array as second parameter
    test=$(arrayKeyExists "fifth")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in basic array a unexisting value
    test=$(arrayKeyExists "fifth" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in indexed array an existing value
    test=$(arrayKeyExists "2" "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in associative array an existing value
    test=$(arrayKeyExists "two" "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_MERGE="-01-01-01-01-01"

function test_arrayMerge ()
{
    local test

    # Check nothing
    test=$(arrayMerge)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    # Check with only first parameter
    test=$(arrayMerge "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_NUMERIC_INDEX}" ]] && echo -n 1

    # Check with indexed arrays with same values
    test=$(arrayMerge "${TEST_ARRAY_NUMERIC_INDEX}" "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_MERGE_NUMERIC_INDEX}" ]] && echo -n 1

    # Check with associative array with differences
    test=$(arrayMerge "${TEST_ARRAY_ASSOCIATIVE_INDEX}" "${TEST_ARRAY_FROM_STRING_MINUS}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_MERGE_ASSOC_INDEX_WITH_MINUS}" ]] && echo -n 1

    # Check with numeric indexed arrays with differences
    test=$(arrayMerge "${TEST_ARRAY_ASSOCIATIVE_INDEX_DIFF}" "${TEST_ARRAY_ASSOCIATIVE_INDEX_OVER}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_MERGE_ASSOCIATIVE_INDEX}" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_SEARCH="-11-11-11-01-01-01"

function test_arraySearch ()
{
    local test

    # Check nothing
    test=$(arraySearch)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with empty needle
    test=$(arraySearch "" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with empty haystack
    test=$(arraySearch "${TEST_ARRAY_VALUE}" "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check in basic array
    test=$(arraySearch "${TEST_ARRAY_VALUE}" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$test" -eq 2 ]] && echo -n 1

    # Check in numeric indexed array
    test=$(arraySearch "${TEST_ARRAY_VALUE}" "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$test" -eq 2 ]] && echo -n 1

    # Check in associative array
    test=$(arraySearch "${TEST_ARRAY_VALUE}" "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$test" == "three" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_TO_STRING="-01-01-01-01"

function test_arrayToString ()
{
    local test

    # Check nothing
    test=$(arrayToString)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    # Simple string
    test=$(arrayToString "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_FROM_STRING_SURROUND}" ]] && echo -n 1

    # Associative declared associative array
    test=$(arrayToString "${TEST_ARRAY_DECLARE_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_ASSOCIATIVE_INDEX}" ]] && echo -n 1

    # Associative declared indexed array
    test=$(arrayToString "${TEST_ARRAY_DECLARE_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_NUMERIC_INDEX}" ]] && echo -n 1
}


readonly TEST_ARRAY_ARRAY_UNIQUE="-01-01-01-01-01"

function test_arrayUnique ()
{
    local test

    #1 Check nothing
    test=$(arrayUnique)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Simple string without duplicate, expected same array
    test=$(arrayUnique "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_FROM_STRING_SURROUND}" ]] && echo -n 1

    #3 Simple string with duplicates, expected same array
    test=$(arrayUnique "${TEST_ARRAY_DUPLICATED_FROM_STRING}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_FROM_STRING_SURROUND}" ]] && echo -n 1

    #4 Associative declared associative array
    test=$(arrayUnique "${TEST_ARRAY_DUPLICATED_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_UNIQUE_ASSOCIATIVE_INDEX}" ]] && echo -n 1

    #5 Associative declared indexed array
    test=$(arrayUnique "${TEST_ARRAY_DUPLICATED_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$test" == "${TEST_ARRAY_UNIQUE_NUMERIC_INDEX}" ]] && echo -n 1
}


readonly TEST_ARRAY_COUNT="-01-01-01-01-01-01-01"

function test_count ()
{
    local test

    # Check nothing
    test=$(count)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check empty array
    test=$(count "()")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check empty array with only space inside
    test=$(count "( )")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check associative array with values
    test=$(count "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ "$test" -eq 4 ]] && echo -n 1

    # Check array with values between parentheses
    test=$(count "${TEST_ARRAY_FROM_STRING_SURROUND}")
    echo -n "-$?"
    [[ "$test" -eq 4 ]] && echo -n 1

    # Check basic array with values
    test=$(count "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ "$test" -eq 4 ]] && echo -n 1

    # Check indexed array with values
    test=$(count "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ "$test" -eq 4 ]] && echo -n 1
}


readonly TEST_ARRAY_IN_ARRAY="-11-11-11-01-01-01"

function test_inArray ()
{
    local test

    # Check nothing
    test=$(inArray)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search with no array as second parameter
    test=$(inArray "fifth")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in basic array a unexisting value
    test=$(inArray "fifth" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in basic array an existing value
    test=$(inArray "second" "${TEST_ARRAY_FROM_STRING}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in indexed array an existing value
    test=$(inArray "second" "${TEST_ARRAY_NUMERIC_INDEX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Search in associative array an existing value
    test=$(inArray "second" "${TEST_ARRAY_ASSOCIATIVE_INDEX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "arrayCombine" "${TEST_ARRAY_ARRAY_COMBINE}" "$(test_arrayCombine)"
bashUnit "arrayDiff" "${TEST_ARRAY_ARRAY_DIFF}" "$(test_arrayDiff)"
bashUnit "arrayFillKeys" "${TEST_ARRAY_FILL_KEYS}" "$(test_arrayFillKeys)"
bashUnit "arrayKeyExists" "${TEST_ARRAY_KEY_EXISTS}" "$(test_arrayKeyExists)"
bashUnit "arrayMerge" "${TEST_ARRAY_ARRAY_MERGE}" "$(test_arrayMerge)"
bashUnit "arraySearch" "${TEST_ARRAY_ARRAY_SEARCH}" "$(test_arraySearch)"
bashUnit "arrayToString" "${TEST_ARRAY_ARRAY_TO_STRING}" "$(test_arrayToString)"
bashUnit "arrayUnique" "${TEST_ARRAY_ARRAY_UNIQUE}" "$(test_arrayUnique)"
bashUnit "count" "${TEST_ARRAY_COUNT}" "$(test_count)"
bashUnit "inArray" "${TEST_ARRAY_IN_ARRAY}" "$(test_inArray)"