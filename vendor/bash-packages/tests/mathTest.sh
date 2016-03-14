#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../math.sh

# Default entries
declare -i -r TEST_NUMBER_TYPE_INT=127
readonly TEST_NUMBER_STR_INT="12"
readonly TEST_NUMBER_STR_BIG_INT="13"
readonly TEST_NUMBER_STR_FLOAT_LEADING_ZERO="5.012"
readonly TEST_NUMBER_STR_INT_LEADING_ZERO="012"
readonly TEST_NUMBER_STR_FLOAT="12.45"
readonly TEST_NUMBER_STR_BIG_FLOAT="12.55"
readonly TEST_NUMBER_STR_BIGGER_FLOAT="13.12"
readonly TEST_NUMBER_STR_UNKNOWN="12s"


readonly TEST_DECIMAL="-11-11-11-01-01"

function test_decimal ()
{
    local test

    # Check nothing
    test=$(decimal)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check int value
    test=$(decimal "${TEST_NUMBER_STR_INT}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

     # Check string value
    test=$(decimal "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check float value
    test=$(decimal "${TEST_NUMBER_STR_BIGGER_FLOAT}")
    echo -n "-$?"
    [[ "$test" -eq "${TEST_NUMBER_STR_INT}" ]] && echo -n 1

    # Check float value with decimal starting with zero
    test=$(decimal "${TEST_NUMBER_STR_FLOAT_LEADING_ZERO}")
    echo -n "-$?"
    [[ "$test" -eq "${TEST_NUMBER_STR_INT}" ]] && echo -n 1
}


readonly TEST_INT="-11-11-01-01-01"

function test_int ()
{
    local test

    # Check nothing
    test=$(int)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check bad value
    test=$(int "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check float value
    test=$(int "${TEST_NUMBER_STR_BIG_FLOAT}")
    echo -n "-$?"
    [[ "$test" -eq "${TEST_NUMBER_STR_INT}" ]] && echo -n 1

    # Check integer value with leading zero
    test=$(int "${TEST_NUMBER_STR_INT_LEADING_ZERO}")
    echo -n "-$?"
    [[ "$test" -eq "${TEST_NUMBER_STR_INT}" ]] && echo -n 1

    # Check integer value
    test=$(int "${TEST_NUMBER_STR_BIG_INT}")
    echo -n "-$?"
    [[ "$test" -eq "${TEST_NUMBER_STR_BIG_INT}" ]] && echo -n 1
}


readonly TEST_IS_FLOAT="-11-11-11-01-11"

function test_isFloat ()
{
    local test

    # Check nothing
    test=$(isFloat)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check int type value
    test=$(isFloat ${TEST_NUMBER_TYPE_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check int value in string
    test=$(isFloat ${TEST_NUMBER_STR_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #  Check if it is a float value
    test=$(isFloat ${TEST_NUMBER_STR_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check invalid number value
    test=$(isFloat ${TEST_NUMBER_STR_UNKNOWN})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_IS_INT="-11-01-01-11-11"

function test_isInt ()
{
    local test

    # Check nothing
    test=$(isInt)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check int type value
    test=$(isInt ${TEST_NUMBER_TYPE_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check int value in string
    test=$(isInt ${TEST_NUMBER_STR_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #  Check if it is a float value
    test=$(isInt ${TEST_NUMBER_STR_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check invalid number value
    test=$(isInt ${TEST_NUMBER_STR_UNKNOWN})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_IS_NUMERIC="-11-01-01-01-11"

function test_isNumeric ()
{
    local test

    # Check nothing
    test=$(isNumeric)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check int type value
    test=$(isNumeric ${TEST_NUMBER_TYPE_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check int value in string
    test=$(isNumeric ${TEST_NUMBER_STR_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #  Check if it is a float value
    test=$(isNumeric ${TEST_NUMBER_STR_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check invalid number value
    test=$(isNumeric ${TEST_NUMBER_STR_UNKNOWN})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_FLOAT_GREATER_THAN="-11-11-11-01-01-11-11-11-01"

function test_isFloatGreaterThan ()
{
    local test

    # Check nothing
    test=$(isFloatGreaterThan)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare equal int values
    test=$(isFloatGreaterThan ${TEST_NUMBER_TYPE_INT} ${TEST_NUMBER_TYPE_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare equal float values
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_FLOAT} ${TEST_NUMBER_STR_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare int value with float value
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_BIG_INT} ${TEST_NUMBER_STR_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare float value with int value
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_FLOAT} ${TEST_NUMBER_STR_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare string value with int value
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_UNKNOWN} ${TEST_NUMBER_TYPE_INT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare float value with string value
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_FLOAT} ${TEST_NUMBER_STR_UNKNOWN})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare float value with an another float value with same decimal
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_FLOAT} ${TEST_NUMBER_STR_BIG_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare float value with a smaller float
    test=$(isFloatGreaterThan ${TEST_NUMBER_STR_BIGGER_FLOAT} ${TEST_NUMBER_STR_BIG_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_FLOAT_LOWER_THAN="-11-01-11"

function test_isFloatLowerThan ()
{
    local test

    # Check nothing
    test=$(isFloatLowerThan)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare float value with an another float value with same decimal
    test=$(isFloatLowerThan ${TEST_NUMBER_STR_FLOAT} ${TEST_NUMBER_STR_BIG_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Compare float value with a smaller float
    test=$(isFloatLowerThan ${TEST_NUMBER_STR_BIGGER_FLOAT} ${TEST_NUMBER_STR_BIG_FLOAT})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Other checks was validated by opposite function isFloatgreaterThan
}


readonly TEST_FLOAT_FLOOR="-11-11-01-01"

function test_floor ()
{
    local test

    # Check nothing
    test=$(floor)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check invalid type
    test=$(floor "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check int value
    test=$(floor "${TEST_NUMBER_STR_BIG_INT}")
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT} ]] && echo -n 1

    # Check float value
    test=$(floor "${TEST_NUMBER_STR_BIG_FLOAT}")
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_INT} ]] && echo -n 1
}


readonly TEST_NUMERIC_TYPE="-01-01-01-01-01"

function test_numericType ()
{
    local test

    # Check nothing
    test=$(numericType)
    echo -n "-$?"
    [[ "$test" == "$BP_UNKNOWN_TYPE" ]] && echo -n 1

    # Check int type value
    test=$(numericType ${TEST_NUMBER_TYPE_INT})
    echo -n "-$?"
    [[ "$test" == "$BP_INT_TYPE" ]] && echo -n 1

    # Check int value in string
    test=$(numericType ${TEST_NUMBER_STR_INT})
    echo -n "-$?"
    [[ "$test" == "$BP_INT_TYPE" ]] && echo -n 1

    # Check float value in string
    test=$(numericType ${TEST_NUMBER_STR_FLOAT})
    echo -n "-$?"
    [[ "$test" == "$BP_FLOAT_TYPE" ]] && echo -n 1

    # Check invalid number value
    test=$(numericType ${TEST_NUMBER_STR_UNKNOWN})
    echo -n "-$?"
    [[ "$test" == "$BP_UNKNOWN_TYPE" ]] && echo -n 1
}


readonly TEST_FLOAT_RAND="-01-01"

function test_rand ()
{
    local test NEXT_TEST

    # Check
    test=$(rand)
    echo -n "-$?"
    [[ "$test" -gt 0 ]] && echo -n 1

    # Another check
    NEXT_TEST=$(rand)
    echo -n "-$?"
    [[ "$NEXT_TEST" -gt 0 && "$test" != "$NEXT_TEST" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "decimal" "${TEST_DECIMAL}" "$(test_decimal)"
bashUnit "int" "${TEST_INT}" "$(test_int)"
bashUnit "isFloat" "${TEST_IS_FLOAT}" "$(test_isFloat)"
bashUnit "isInt" "${TEST_IS_INT}" "$(test_isInt)"
bashUnit "isNumeric" "${TEST_IS_NUMERIC}" "$(test_isNumeric)"
bashUnit "isFloatGreaterThan" "${TEST_FLOAT_GREATER_THAN}" "$(test_isFloatGreaterThan)"
bashUnit "isFloatLowerThan" "${TEST_FLOAT_LOWER_THAN}" "$(test_isFloatLowerThan)"
bashUnit "floor" "${TEST_FLOAT_FLOOR}" "$(test_floor)"
bashUnit "numericType" "${TEST_NUMERIC_TYPE}" "$(test_numericType)"
bashUnit "rand" "${TEST_FLOAT_RAND}" "$(test_rand)"