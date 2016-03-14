#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package math
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Use BC by default to manipulate string. If BC is not available, used pure bash
declare -r -i BP_BC="$(if [[ -z "$(type -p bc)" ]]; then echo 0; else echo 1; fi)"
declare -r BP_INT_TYPE="integer"
declare -r BP_FLOAT_TYPE="float"
declare -r BP_UNKNOWN_TYPE="unknown"


##
# Only return the decimal part of a float in integer
# @param string $1 Value
# @return int
# @returnStatus 1 If first parameter named var is not a float
function decimal ()
{
    local value="$1"
    if ! isFloat "$value"; then
        echo -n 0
        return 1
    fi
    value=${value##*.}

    # Removing leading zeros by converting it in base 10
    if [[ ${value:0:1} == 0 && ${value} != 0 ]]; then
        echo -n $(( 10#$value ))
    else
        echo -n ${value}
    fi
}

##
# Get the integer value of a variable
# @param string $1 Value
# @return int
# @returnStatus 1 If first parameter named var is not a numeric
function int ()
{
    local value="$1"

    if ! isNumeric "$value"; then
        echo -n 0
        return 1
    fi

    # Keep only the value left point
    value=$(floor "$value")
    if [[ $? -ne 0 ]]; then
        echo -n ${value}
        return 1
    fi

    # Removing leading zeros by converting it in base 10
    if [[ ${value:0:1} == 0 && ${value} != 0 ]]; then
        echo -n $(( 10#${value} ))
    else
        echo -n ${value}
    fi
}

##
# Finds whether the type of a variable is float
# @param string $1
# @returnStatus 1 If first parameter named var is not a float
function isFloat ()
{
    if [[ -z "$1" ]]; then
        return 1
    elif [[ "$1" =~ ^[-+]?[0-9]+\.[0-9]+$ ]]; then
        return
    else
        return 1
    fi
}

##
# Find whether the type of a variable is integer
# @param string $1
# @returnStatus 1 If first parameter named var is not an integer
function isInt ()
{
    if [[ -z "$1" ]]; then
        return 1
    elif [[ "$1" =~ ^[-+]?[0-9]+$ ]]; then
        return
    else
        return 1
    fi
}

##
# Finds whether a variable is a number or a numeric string
# @param string Var
# @returnStatus 1 If first parameter named var is not numeric
function isNumeric ()
{
    if isFloat "$1" || isInt "$1"; then
         return
    else
        return 1
    fi
}

##
# First float value is greater than the second ?
# @param float $1
# @param float|int $2
# @returnStatus 1 If $1 is greater than $2, 0 otherwise
function isFloatGreaterThan ()
{
    local val1="$1"
    local res1=$(numericType "$val1")
    if [[ "$res1" == "${BP_UNKNOWN_TYPE}" ]]; then
        return 1
    fi

    local val2="$2"
    local res2=$(numericType "$val2")
    if [[ "$res2" == "${BP_UNKNOWN_TYPE}" ]]; then
        return 1
    fi

    if [[ ${BP_BC} -eq 1 ]]; then
        if [[ 1 -eq $(echo "$val1 > $val2" | bc) ]]; then
            return
        fi
    else
        if [[ "$res1" == "${BP_INT_TYPE}" ]]; then
            val1="${val1}.0"
        fi
        if [[ "$res2" == "${BP_INT_TYPE}" ]]; then
            val2="${val2}.0"
        fi
        if (( $(floor "$val1") > $(floor "$val2") || ( $(floor "$val1") == $(floor "$val2") && $(decimal "$val1") > $(decimal "$val2") ) )) ; then
            return
        fi
    fi

    return 1
}

##
# First float value is lower than the second ?
# @param float Var1
# @param float|int Var2
# @returnStatus 1 If $1 is lower than $2, 0 otherwise
function isFloatLowerThan ()
{
    if isFloatGreaterThan "$2" "$1"; then
        return
    else
        return 1
    fi
}

##
# Round fractions down
# @param float Value
# @return int Var
# @returnStatus 1 If first parameter named var is not numeric
function floor ()
{
    if isFloat "$1"; then
        # Keep only the value left point
        echo -n "${1%%.*}"
    elif isInt "$1"; then
        echo -n $1
    else
        echo -n 0
        return 1
    fi
}

##
# Get the type of a numeric variable
#
# Possible values for the returned string are:
# - "float" via constant named BP_UNKNOWN_TYPE
# - "int" via constant named BP_UNKNOWN_TYPE
# - "unknown" via constant named BP_UNKNOWN_TYPE
#
# @param mixed $1
# @return string
function numericType ()
{
    if isFloat "$1"; then
        echo -n "${BP_FLOAT_TYPE}"
    elif isInt "$1"; then
        echo -n "${BP_INT_TYPE}"
    else
        echo -n "${BP_UNKNOWN_TYPE}"
    fi
}

##
# Generate a random integer
# @return int
function rand ()
{
    echo -n ${RANDOM}
}