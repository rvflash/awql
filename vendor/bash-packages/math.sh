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
declare -r -i BP_AWK="$(if [[ -z "$(type -p awk)" ]]; then echo 0; else echo 1; fi)"
declare -r BP_INT_TYPE="integer"
declare -r BP_FLOAT_TYPE="float"
declare -r BP_UNKNOWN_TYPE="unknown"


##
# Calculates a mathematical operation
# @param string $1 Operation
# @param int $2 Scale / Precision
# @return numeric
# @returnStatus 1 If operation can not be done
function __calculate ()
{
    local operation="$1"
    if [[ -z "$operation" ]]; then
        echo 0
        return 1
    elif [[ ${BP_BC} -eq 0 && ${BP_AWK} -eq 0 ]]; then
        echo 0
        return 1
    fi
    declare -i scale="$2"

    local rs
    if [[ ${BP_BC} -eq 1 ]]; then
        rs=$(echo "scale=${scale}; ${operation}" | bc -l 2>/dev/null)
        rs=$(LC_NUMERIC="en_US.UTF-8" printf "%.${scale}f" "$rs")
    else
        rs="BEGIN { LC_NUMERIC='en_US.UTF-8' printf scale, ${operation} }"
        rs=$(awk -v scale="%.${scale}f" "$rs" 2>/dev/null)
    fi

    echo "$rs"
}

##
# Finds whether the type of a variable is float
# @param string $1 Value
# @returnStatus 1 If first parameter named var is not a float
function isFloat ()
{
    if [[ -z "$1" ]]; then
        return 1
    elif [[ "$1" =~ ^[-+]?[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

##
# Find whether the type of a variable is integer
# @param string $1 Value
# @returnStatus 1 If first parameter named var is not an integer
function isInt ()
{
    if [[ -z "$1" ]]; then
        return 1
    elif [[ "$1" =~ ^[-+]?[0-9]+$ ]]; then
        return 0
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
         return 0
    else
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
        echo "${BP_FLOAT_TYPE}"
    elif isInt "$1"; then
        echo "${BP_INT_TYPE}"
    else
        echo "${BP_UNKNOWN_TYPE}"
    fi
}

##
# Only return the decimal part of a float in integer
# @param string $1 Value
# @return int
# @returnStatus 1 If first parameter named var is not a float
function decimal ()
{
    local value="$1"

    if ! isFloat "$value"; then
        echo 0
        return 1
    fi
    value=${value##*.}

    # Removing leading zeros by converting it in base 10
    echo $(( 10#$value ))
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
        echo 0
        return 1
    fi

    # Keep only the value left point
    if isFloat "$value"; then
        value=$(floor "$value")
        if [[ $? -ne 0 ]]; then
            echo ${value}
            return 1
        fi
    fi

    # Removing leading zeros by converting it in base 10
    echo $(( 10#$value ))
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
            return 0
        fi
    else
        if [[ "$res1" == "${BP_INT_TYPE}" ]]; then
            val1="${val1}.0"
        fi
        if [[ "$res2" == "${BP_INT_TYPE}" ]]; then
            val2="${val2}.0"
        fi
        if (( $(floor "$val1") > $(floor "$val2") || ( $(floor "$val1") == $(floor "$val2") && $(decimal "$val1") > $(decimal "$val2") ) )) ; then
            return 0
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
        return 0
    else
        return 1
    fi
}

##
# Round fractions up
# @param float Value
# @return int Var
# @returnStatus 1 If first parameter named var is not numeric
function ceil ()
{
    local val1="$1"
    declare -i value=0

    if isFloat "$val1"; then
        # Keep only the value left point
        value=$(( 10#${val1%%.*} ))
        if [[ $(decimal "$val1") -gt 0 && "$val1" != "-"* ]] ; then
            value+=1
        fi
    elif isInt "$val1"; then
        value=$(( 10#$val1 ))
    else
        echo ${value}
        return 1
    fi

    echo ${value}
}

##
# Round fractions down
# @param float Value
# @return int Var
# @returnStatus 1 If first parameter named var is not numeric
function floor ()
{
    local val1="$1"
    declare -i value=0

    if isFloat "$val1"; then
        # Keep only the value left point
        value=$(( 10#${val1%%.*} ))
        if [[ ${value} -lt 0 || "$val1" == "-"* ]] && [[ $(decimal "$val1") -gt 0 ]]; then
            value+=-1
        fi
    elif isInt "$val1"; then
        value=$(( 10#$val1 ))
    else
        echo ${value}
        return 1
    fi

    echo ${value}
}

##
# Mathematical operations with float precision
# @param string $1 Operator
# @param mixed $2 Value1
# @param mixed $3 Value2
# @param int $4 Scale
# @return numeric
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If arithmetic's operation is unknown
# @returnStatus 3 If value1 or value2 are not numeric
# @returnStatus 4 If scale parameter is not an integer
function math ()
{
    local op="$1"
    if [[ "+" != "$op" && "-" != "$op" && "*" != "$op" && "/" != "$op" && "%" != "$op" ]]; then
        echo 0
        return 2
    fi
    local val1="$2"
    if ! isNumeric "$val1"; then
        echo 0
        return 3
    fi
    local val2="$3"
    if ! isNumeric "$val2"; then
        echo 0
        return 3
    fi
    declare -i scale=0
    if isInt "$4"; then
        scale="$4"
    elif [[ -z "$4" ]]; then
        if [[ "%" != "$op" ]]; then
            scale=2;
        fi
    else
        return 4
    fi

    __calculate "( ${val1} ${op} ${val2} )" ${scale}
}

##
# Addition with float precision
# @param mixed $1 Value1
# @param mixed $2 Value2
# @param int $3 Scale, number of digits after decimal point
# @return numeric
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If arithmetic's operation is unknown
# @returnStatus 3 If value1 or value2 are not numeric
# @returnStatus 4 If scale parameter is not an integer
function add ()
{
    math "+" "$1" "$2" "$3"
}

##
# Division with float precision
# @param mixed $1 Value1
# @param mixed $2 Value2
# @param int $3 Scale, number of digits after decimal point
# @return numeric
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If arithmetic's operation is unknown
# @returnStatus 3 If value1 or value2 are not numeric
# @returnStatus 4 If scale parameter is not an integer
function divide ()
{
    math "/" "$1" "$2" "$3"
}

##
# Multiplication with float precision
# @param mixed $1 Value1
# @param mixed $2 Value2
# @param int $3 Scale, number of digits after decimal point
# @return numeric
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If arithmetic's operation is unknown
# @returnStatus 3 If value1 or value2 are not numeric
# @returnStatus 4 If scale parameter is not an integer
function multiply ()
{
    math "*" "$1" "$2" "$3"
}

##
# Modulo with float precision
# @param mixed $1 Value1
# @param mixed $2 Value2
# @param int $3 Scale, number of digits after decimal point
# @return numeric
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If arithmetic's operation is unknown
# @returnStatus 3 If value1 or value2 are not numeric
# @returnStatus 4 If scale parameter is not an integer
function modulo ()
{
    math "%" "$1" "$2" "$3"
}

##
# Subtraction with float precision
# @param mixed $1 Value1
# @param mixed $2 Value2
# @param int $3 Scale, number of digits after decimal point
# @return numeric
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If arithmetic's operation is unknown
# @returnStatus 3 If value1 or value2 are not numeric
# @returnStatus 4 If scale parameter is not an integer
function subtract ()
{
    math "-" "$1" "$2" "$3"
}

##
# Generate a random integer
# @return int
function rand ()
{
    echo ${RANDOM}
}

##
# Rounds a float
# @param float $1 Value
# @param int $2 Scale / Precision
# @return float
# @returnStatus 1 If bc or awk are not available in current environment
# @returnStatus 2 If value is not numeric
# @returnStatus 3 If scale parameter is not an integer
function round()
{
    local value="$1"
    if ! isNumeric "$value"; then
        echo 0
        return 2
    fi
    declare -i scale=0
    if isInt "$2"; then
        scale="$2"
    elif [[ -n "$2" ]]; then
        return 3
    fi

    local sign="+"
    if [[ "$value" == "-"* ]]; then
        sign="-"
    fi

    __calculate "(((10^${scale}) * ${value}) ${sign} 0.5) / (10^${scale})" ${scale}
}