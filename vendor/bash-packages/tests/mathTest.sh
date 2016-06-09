#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../math.sh

# Default entries
declare -i -r TEST_NUMBER_TYPE_INT=127
readonly TEST_NUMBER_STR_INT="12"
readonly TEST_NUMBER_STR_BIG_INT="13"
readonly TEST_NUMBER_STR_INT_NEGATIVE="-5"
readonly TEST_NUMBER_STR_BIG_INT_NEGATIVE="-6"
readonly TEST_NUMBER_STR_FLOAT_NEGATIVE="-5.016"
readonly TEST_NUMBER_STR_FLOAT_NEGATIVE_ROUND="-5.02"
readonly TEST_NUMBER_STR_FLOAT_LEADING_ZERO="5.012"
readonly TEST_NUMBER_STR_FLOAT_LEADING_ZERO_2D="5.01"
readonly TEST_NUMBER_STR_FLOAT_POSITIVE="5.166"
readonly TEST_NUMBER_STR_FLOAT_POSITIVE_ROUND="5.2"
readonly TEST_NUMBER_STR_FLOAT_POSITIVE_ROUND_2="5.17"
readonly TEST_NUMBER_STR_INT_LEADING_ZERO="012"
readonly TEST_NUMBER_STR_FLOAT="12.45"
readonly TEST_NUMBER_STR_BIG_FLOAT="12.55"
readonly TEST_NUMBER_STR_MIN_FLOAT="1.255"
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


readonly TEST_IS_FLOAT="-11-11-11-01-11-11"

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

    # Check with number leading with zero
    test=$(isFloat ${TEST_NUMBER_STR_INT_LEADING_ZERO})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_IS_INT="-11-01-01-11-11-01"

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

    # Check with number leading with zero
    test=$(isInt ${TEST_NUMBER_STR_INT_LEADING_ZERO})
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_IS_NUMERIC="-11-01-01-01-11-01"

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

    # Check with number leading with zero
    test=$(isNumeric ${TEST_NUMBER_STR_INT_LEADING_ZERO})
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

    # Other checks was validated by opposite function isFloatGreaterThan
}

readonly TEST_CEIL="-11-11-01-01-01-01"

function test_ceil ()
{
    local test

    # Check nothing
    test=$(ceil)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check invalid type
    test=$(ceil "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check int value
    test=$(ceil "${TEST_NUMBER_STR_BIG_INT}")
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT} ]] && echo -n 1

    # Check float value
    test=$(ceil "${TEST_NUMBER_STR_BIG_FLOAT}")
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT} ]] && echo -n 1

    # Check negative float value
    test=$(ceil "${TEST_NUMBER_STR_FLOAT_NEGATIVE}")
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_INT_NEGATIVE} ]] && echo -n 1

    # Check with number leading with zero
    test=$(ceil ${TEST_NUMBER_STR_INT_LEADING_ZERO})
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_INT} ]] && echo -n 1
}

readonly TEST_FLOOR="-11-11-01-01-01-01"

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

    # Check negative float value
    test=$(floor "${TEST_NUMBER_STR_FLOAT_NEGATIVE}")
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT_NEGATIVE} ]] && echo -n 1

    # Check with number leading with zero
    test=$(floor ${TEST_NUMBER_STR_INT_LEADING_ZERO})
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


readonly TEST_ADD="-31-31-31-41-01-01-01"

function test_add ()
{
    local test

    # Check nothing
    test=$(add)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid first number
    test=$(add "${TEST_NUMBER_STR_UNKNOWN}" "${TEST_NUMBER_STR_INT}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid second number
    test=$(add "${TEST_NUMBER_STR_INT}" "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid scale
    test=$(add "${TEST_NUMBER_STR_INT}" 1 "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with both valid numbers and no decimal
    test=$(add "${TEST_NUMBER_STR_INT}" 1 0)
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT} ]] && echo -n 1

    # Check with both valid float numbers
    test=$(add "${TEST_NUMBER_STR_FLOAT}" "0.1")
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_BIG_FLOAT} ]] && echo -n 1

    # Check with both valid float numbers and 3 digits as decimal
    test=$(add "${TEST_NUMBER_STR_FLOAT_LEADING_ZERO_2D}" "0.002" 3)
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_FLOAT_LEADING_ZERO} ]] && echo -n 1
}


readonly TEST_DIVIDE="-31-31-31-41-01-01-01"

function test_divide ()
{
    local test

   local test

    # Check nothing
    test=$(divide)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid first number
    test=$(divide "${TEST_NUMBER_STR_UNKNOWN}" "${TEST_NUMBER_STR_INT}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid second number
    test=$(divide "${TEST_NUMBER_STR_INT}" "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid scale
    test=$(divide "${TEST_NUMBER_STR_INT}" 1 "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check by zero
    test=$(divide "${TEST_NUMBER_STR_INT}" 0 0)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with both valid float numbers
    test=$(divide "${TEST_NUMBER_STR_BIG_FLOAT}" "10" 3)
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_MIN_FLOAT} ]] && echo -n 1

    # Check with both valid float numbers and 3 digits as decimal
    test=$(divide "${TEST_NUMBER_STR_FLOAT_LEADING_ZERO}" 1 2)
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_FLOAT_LEADING_ZERO_2D} ]] && echo -n 1
}


readonly TEST_MATH="-21-21-01-01-01-01-01"

function test_math ()
{
    local test

    # Check nothing
    test=$(math)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check unknown operation
    test=$(math "exp" "${TEST_NUMBER_STR_INT}" 1 0)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check add operation
    test=$(math "+" "${TEST_NUMBER_STR_INT}" 1 0)
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT} ]] && echo -n 1

    # Check subtract operation
    test=$(math "-" "${TEST_NUMBER_STR_BIG_INT}" 1 0)
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_INT} ]] && echo -n 1

    # Check multiply operation
    test=$(math "*" "${TEST_NUMBER_STR_INT}" 1 2)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_INT}.00" ]] && echo -n 1

    # Check divide operation
    test=$(math "/" "${TEST_NUMBER_STR_INT}" 1 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_INT}.0" ]] && echo -n 1

    # Check modulo operation
    test=$(math "%" "${TEST_NUMBER_STR_INT}" 2 0)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # All others are done with dedicated methods (add, divide, etc.)
}


readonly TEST_MODULO="-31-31-31-41-01-01"

function test_modulo ()
{
    local test

    # Check nothing
    test=$(modulo)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid first number
    test=$(modulo "${TEST_NUMBER_STR_UNKNOWN}" "${TEST_NUMBER_STR_INT}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid second number
    test=$(modulo "${TEST_NUMBER_STR_INT}" "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid scale
    test=$(modulo "${TEST_NUMBER_STR_INT}" 1 "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with both valid numbers
    test=$(modulo "${TEST_NUMBER_STR_INT}" 2)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with both valid numbers
    test=$(modulo "${TEST_NUMBER_STR_BIG_INT}" 2)
    echo -n "-$?"
    [[ "$test" -eq 1 ]] && echo -n 1
}


readonly TEST_MULTIPLY="-31-31-31-41-01-01-01-01"

function test_multiply ()
{
    local test

    # Check nothing
    test=$(multiply)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid first number
    test=$(multiply "${TEST_NUMBER_STR_UNKNOWN}" "${TEST_NUMBER_STR_INT}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid second number
    test=$(multiply "${TEST_NUMBER_STR_INT}" "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid scale
    test=$(multiply "${TEST_NUMBER_STR_INT}" 1 "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with both valid numbers
    test=$(multiply "${TEST_NUMBER_STR_BIG_INT}" 1 0)
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_BIG_INT} ]] && echo -n 1

    # Check with both valid numbers
    test=$(multiply "63.5" 2 0)
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_TYPE_INT} ]] && echo -n 1

    # Check with both valid float numbers
    test=$(multiply "${TEST_NUMBER_STR_BIG_FLOAT}" "0.1" 3)
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_MIN_FLOAT} ]] && echo -n 1

    # Check with both valid float numbers and 3 digits as decimal
    test=$(multiply "${TEST_NUMBER_STR_MIN_FLOAT}" "10" 2)
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_BIG_FLOAT} ]] && echo -n 1
}


readonly TEST_RAND="-01-01"

function test_rand ()
{
    local test anotherTest

    # Check nothing
    test=$(rand)
    echo -n "-$?"
    [[ "$test" -gt 0 ]] && echo -n 1

    # Another check
    anotherTest=$(rand)
    echo -n "-$?"
    [[ "$anotherTest" -gt 0 && "$test" != "$anotherTest" ]] && echo -n 1
}


readonly TEST_ROUND="-21-01-01-01-01-01-01"

function test_round ()
{
    local test

    # Check nothing
    test=$(round)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check without scale
    test=$(round "${TEST_NUMBER_STR_FLOAT_NEGATIVE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_INT_NEGATIVE}" ]] && echo -n 1

    # Check with negative float and precision to 2
    test=$(round "${TEST_NUMBER_STR_FLOAT_NEGATIVE}" 2)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_FLOAT_NEGATIVE_ROUND}" ]] && echo -n 1

    # Check with positive float and precision to 1
    test=$(round "${TEST_NUMBER_STR_FLOAT_POSITIVE}" 1)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_FLOAT_POSITIVE_ROUND}" ]] && echo -n 1

    # Check with positive float and precision to 2
    test=$(round "${TEST_NUMBER_STR_FLOAT_POSITIVE}" 2)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_FLOAT_POSITIVE_ROUND_2}" ]] && echo -n 1

    # Check with base 10 int
    test=$(round "${TEST_NUMBER_STR_INT}" 2)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_INT}.00" ]] && echo -n 1

    # Check with int
    test=$(round "${TEST_NUMBER_STR_INT_LEADING_ZERO}" 2)
    echo -n "-$?"
    [[ "$test" == "${TEST_NUMBER_STR_INT}.00" ]] && echo -n 1
}


readonly TEST_SUBTRACT="-31-31-31-41-01-01-01"

function test_subtract ()
{
    # Check nothing
    test=$(subtract)
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid first number
    test=$(subtract "${TEST_NUMBER_STR_UNKNOWN}" "${TEST_NUMBER_STR_INT}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid second number
    test=$(subtract "${TEST_NUMBER_STR_INT}" "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with invalid scale
    test=$(subtract "${TEST_NUMBER_STR_INT}" 1 "${TEST_NUMBER_STR_UNKNOWN}")
    echo -n "-$?"
    [[ "$test" -eq 0 ]] && echo -n 1

    # Check with both valid numbers
    test=$(subtract "${TEST_NUMBER_STR_BIG_INT}" 1 0)
    echo -n "-$?"
    [[ "$test" -eq ${TEST_NUMBER_STR_INT} ]] && echo -n 1

    # Check with both valid float numbers
    test=$(subtract "${TEST_NUMBER_STR_BIG_FLOAT}" "0.1")
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_FLOAT} ]] && echo -n 1

    # Check with both valid float numbers and 3 digits as decimal
    test=$(subtract "${TEST_NUMBER_STR_BIGGER_FLOAT}" "0.57" 2)
    echo -n "-$?"
    [[ "$test" == ${TEST_NUMBER_STR_BIG_FLOAT} ]] && echo -n 1
}


# Launch all functional tests
bashUnit "add" "${TEST_ADD}" "$(test_add)"
bashUnit "ceil" "${TEST_CEIL}" "$(test_ceil)"
bashUnit "decimal" "${TEST_DECIMAL}" "$(test_decimal)"
bashUnit "divide" "${TEST_DIVIDE}" "$(test_divide)"
bashUnit "floor" "${TEST_FLOOR}" "$(test_floor)"
bashUnit "int" "${TEST_INT}" "$(test_int)"
bashUnit "isFloat" "${TEST_IS_FLOAT}" "$(test_isFloat)"
bashUnit "isInt" "${TEST_IS_INT}" "$(test_isInt)"
bashUnit "isNumeric" "${TEST_IS_NUMERIC}" "$(test_isNumeric)"
bashUnit "isFloatGreaterThan" "${TEST_FLOAT_GREATER_THAN}" "$(test_isFloatGreaterThan)"
bashUnit "isFloatLowerThan" "${TEST_FLOAT_LOWER_THAN}" "$(test_isFloatLowerThan)"
bashUnit "math" "${TEST_MATH}" "$(test_math)"
bashUnit "modulo" "${TEST_MODULO}" "$(test_modulo)"
bashUnit "multiply" "${TEST_MULTIPLY}" "$(test_multiply)"
bashUnit "numericType" "${TEST_NUMERIC_TYPE}" "$(test_numericType)"
bashUnit "rand" "${TEST_RAND}" "$(test_rand)"
bashUnit "round" "${TEST_ROUND}" "$(test_round)"
bashUnit "subtract" "${TEST_SUBTRACT}" "$(test_subtract)"