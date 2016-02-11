#!/usr/bin/env bash

declare -r BP_ARRAY_DECLARED_INDEXED_TYPE="+a"
declare -r BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE="+A"
declare -r BP_ARRAY_DEFAULT_INDEXED_TYPE="-a"
declare -r BP_ARRAY_INDEXED_TYPE="a"
declare -r BP_ARRAY_ASSOCIATIVE_TYPE="A"


##
# Return type of array
# @param string $1 Array
# @return string
function __arrayType ()
{
    local ARRAY="$1"
    if [[ "$ARRAY" == "declare -${BP_ARRAY_INDEXED_TYPE}"* ]]; then
        # declare -A NAME='([0]="v1" [1]="v2")'
        echo -n ${BP_ARRAY_DECLARED_INDEXED_TYPE}
    elif [[ "$ARRAY" == "declare -${BP_ARRAY_ASSOCIATIVE_TYPE}"* ]]; then
        # declare -A NAME='(["k0"]="v1" ["k1"]="v2")'
        echo -n ${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}
    elif [[ "$ARRAY" == "("*")" ]]; then
        if [[ "$ARRAY" =~ ^\(([[:space:]]*)?\[[0-9]+\]=.*$ ]]; then
            # ([0]="v1" [1]="v2")
            echo -n ${BP_ARRAY_INDEXED_TYPE}
        elif [[ "$ARRAY" =~ ^\(([[:space:]]*)?\[.*$ ]]; then
            # (["k0"]="v1" ["k1"]="v2")
            echo -n ${BP_ARRAY_ASSOCIATIVE_TYPE}
        else
            # (v1 v2)
            echo -n ${BP_ARRAY_INDEXED_TYPE}
        fi
    else
        # v1 v2
        echo -n ${BP_ARRAY_DEFAULT_INDEXED_TYPE}
    fi
}

##
# Computes the difference of arrays
#
# @example inputs "v1 v2 v3" "v1"
# @example return "v2 v3"
#
# @example inputs '(["k0"]="v1" ["k1"]="v2" ["k2"]="v3")" "v1"
# @example return "(["k0"]="v1")"
#
# @param arrayToString $1
# @param arrayToString $2
# @return arrayToString
function arrayDiff ()
{
    local HAYSTACK_1="$1"
    local TYPE_1="$(__arrayType "${HAYSTACK_1}")"
    if [[ "${TYPE_1}" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a ARRAY_1="$(arrayToString "${HAYSTACK_1}")"
    elif [[ "${TYPE_1}" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY_1="$(arrayToString "${HAYSTACK_1}")"
    elif [[ "${TYPE_1}" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a ARRAY_1="${HAYSTACK_1}"
    elif [[ "${TYPE_1}" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY_1="${HAYSTACK_1}"
    else
        declare -a ARRAY_1="(${HAYSTACK_1})"
    fi
    if [[ "${#ARRAY_1[@]}" -eq 0 ]]; then
        echo -n "()"
        return 0
    fi

    local HAYSTACK_2="$2"
    local TYPE_2="$(__arrayType "${HAYSTACK_2}")"
    if [[ "${TYPE_2}" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a ARRAY_2="$(arrayToString "${HAYSTACK_2}")"
    elif [[ "${TYPE_2}" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY_2="$(arrayToString "${HAYSTACK_2}")"
    elif [[ "${TYPE_2}" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a ARRAY_2="${HAYSTACK_2}"
    elif [[ "${TYPE_2}" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY_2="${HAYSTACK_2}"
    else
        declare -a ARRAY_2="(${HAYSTACK_2})"
    fi
    if [[ "${#ARRAY_2[@]}" -eq 0 ]]; then
        arrayToString "$(declare -p ARRAY_1)"
        return 0
    fi

    if [[ "${TYPE_1: -1}" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A DIFFERENCE=()
    else
        declare -a DIFFERENCE=()
    fi

    declare -i SKIP
    local KEY_1 VALUE_2
    for KEY_1 in "${!ARRAY_1[@]}"; do
        SKIP=0
        for VALUE_2 in "${ARRAY_2[@]}"; do
            [[ "${ARRAY_1[$KEY_1]}" == "$VALUE_2" ]] && { SKIP=1; break; }
        done
        [[ ${SKIP} -eq 1 ]] || DIFFERENCE["$KEY_1"]="${ARRAY_1[$KEY_1]}"
    done

    arrayToString "$(declare -p DIFFERENCE)"
}

##
# Searches the array for a given value and returns the corresponding key if successful
#
# @example inputs "v2" "v1 v2 v3"
# @example return "1"
#
# @example inputs "v2" '(["k0"]="v1" ["k1"]="v2" ["k2"]="v3")"
# @example return "k1"
#
# @param string $1 Needle
# @param arrayToString $2 Haystack
# @return mixed
# @returnStatus 1 If first parameter named needle is empty
# @returnStatus 1 If needle does not exist in haystack
function arraySearch ()
{
    local NEEDLE="$1"
    if [[ -z "$NEEDLE" ]]; then
        return 1
    fi

    local HAYSTACK="$2"
    local TYPE="$(__arrayType "${HAYSTACK}")"
    if [[ "$TYPE" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a ARRAY="$(arrayToString "${HAYSTACK}")"
    elif [[ "$TYPE" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY="$(arrayToString "${HAYSTACK}")"
    elif [[ "$TYPE" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a ARRAY="${HAYSTACK}"
    elif [[ "$TYPE" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY="${HAYSTACK}"
    else
        declare -a ARRAY="(${HAYSTACK})"
    fi
    declare -i LENGTH="${#ARRAY[@]}"

    local KEY
    for KEY in "${!ARRAY[@]}"; do
        if [[ "${ARRAY[$KEY]}" == ${NEEDLE} ]]; then
            echo -n "$KEY"
            return 0
        fi
    done

    return 1
}

##
# Get printed array string with declare method and convert it in arrayToString
#
# @example input declare -A rv='([k]="v")'
# @example code
#   declare -A rv
#   rv[k]="v"
#   arrayToString "$(declare -p rv)"
# @example return ([k]=v)
#
# @param string $1 Array declaration
# @return string
function arrayToString ()
{
    local ARRAY_TO_STRING="$1"
    if [[ -z "$ARRAY_TO_STRING" ]]; then
        echo -n "()"
        return 0
    fi

    # Remove declare -OPTIONS NAME='(
    ARRAY_TO_STRING="${ARRAY_TO_STRING#*(}"
    # Remove )'
    ARRAY_TO_STRING="${ARRAY_TO_STRING%)*}"
    # Remove escaping of single quote (') by declare function
    ARRAY_TO_STRING="${ARRAY_TO_STRING//\\\'\'/}"

    echo -n "(${ARRAY_TO_STRING})"
}

##
# Count all elements in an array
# @param string $1 Haystack
# return int
function count ()
{
    declare -i COUNT=0
    local HAYSTACK="$1"
    if [[ -z "${HAYSTACK}" || "${HAYSTACK}" =~ ^\(([[:space:]]*)?\)*$ ]]; then
        echo -n ${COUNT}
        return 0
    fi

    local TYPE="$(__arrayType "${HAYSTACK}")"
    if [[ "$TYPE" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a ARRAY="$(arrayToString "${HAYSTACK}")"
    elif [[ "$TYPE" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY="$(arrayToString "${HAYSTACK}")"
    elif [[ "$TYPE" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a ARRAY="${HAYSTACK}"
    elif [[ "$TYPE" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY="${HAYSTACK}"
    else
        declare -a ARRAY="(${HAYSTACK})"
    fi
    COUNT=${#ARRAY[@]}

    echo -n ${COUNT}
}

##
# Check if a value is available in array
# @param string $1 Needle
# @param arrayToString $2 Haystack
# @returnStatus 1 If first parameter named needle is empty
# @returnStatus 1 If needle does not exist in haystack
function inArray ()
{
    local NEEDLE="$1"
    if [[ -z "$NEEDLE" ]]; then
        return 1
    fi

    local HAYSTACK="$2"
    local TYPE="$(__arrayType "${HAYSTACK}")"
    if [[ "$TYPE" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a ARRAY="$(arrayToString "${HAYSTACK}")"
    elif [[ "$TYPE" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY="$(arrayToString "${HAYSTACK}")"
    elif [[ "$TYPE" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a ARRAY="${HAYSTACK}"
    elif [[ "$TYPE" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A ARRAY="${HAYSTACK}"
    else
        declare -a ARRAY="(${HAYSTACK})"
    fi

    for VALUE in ${ARRAY[@]}; do
        if [[ "${VALUE}" == ${NEEDLE} ]]; then
            return 0
        fi
    done

    return 1
}