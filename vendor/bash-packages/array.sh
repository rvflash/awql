#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package array
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

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
    local arr="$1"
    if [[ "$arr" == "declare -${BP_ARRAY_INDEXED_TYPE}"* ]]; then
        # declare -A NAME='([0]="v1" [1]="v2")'
        echo ${BP_ARRAY_DECLARED_INDEXED_TYPE}
    elif [[ "$arr" == "declare -${BP_ARRAY_ASSOCIATIVE_TYPE}"* ]]; then
        # declare -A NAME='(["k0"]="v1" ["k1"]="v2")'
        echo ${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}
    elif [[ "$arr" == "("*")" ]]; then
        if [[ "$arr" =~ ^\(([[:space:]]*)?\[[0-9]+\]=.*$ ]]; then
            # ([0]="v1" [1]="v2")
            echo ${BP_ARRAY_INDEXED_TYPE}
        elif [[ "$arr" =~ ^\(([[:space:]]*)?\[.*$ ]]; then
            # (["k0"]="v1" ["k1"]="v2")
            echo ${BP_ARRAY_ASSOCIATIVE_TYPE}
        else
            # (v1 v2)
            echo ${BP_ARRAY_INDEXED_TYPE}
        fi
    else
        # v1 v2
        echo ${BP_ARRAY_DEFAULT_INDEXED_TYPE}
    fi
}

##
# Computes the difference of arrays
#
# @example inputs "v1 v2 v3" "v1"
# @example return "v2 v3"
#
# @example inputs "(["k0"]="v1" ["k1"]="v2" ["k2"]="v3")" "v1"
# @example return "(["k0"]="v1")"
#
# @param arrayToString $1 Arr1
# @param arrayToString $2 Arr2
# @return arrayToString
function arrayDiff ()
{
    local haystack1="$1"
    local type1="$(__arrayType "$haystack1")"
    if [[ "$type1" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr1="$(arrayToString "$haystack1")"
    elif [[ "$type1" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr1="$(arrayToString "$haystack1")"
    elif [[ "$type1" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr1="$haystack1"
    elif [[ "$type1" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr1="$haystack1"
    else
        declare -a arr1="(${haystack1})"
    fi
    if [[ "${#arr1[@]}" -eq 0 ]]; then
        echo "()"
        return 0
    fi

    local haystack2="$2"
    local type2="$(__arrayType "$haystack2")"
    if [[ "$type2" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr2="$(arrayToString "$haystack2")"
    elif [[ "$type2" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr2="$(arrayToString "$haystack2")"
    elif [[ "$type2" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr2="$haystack2"
    elif [[ "$type2" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr2="$haystack2"
    else
        declare -a arr2="(${haystack2})"
    fi
    if [[ "${#arr2[@]}" -eq 0 ]]; then
        arrayToString "$(declare -p arr1)"
        return 0
    fi

    if [[ "${type1: -1}" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A diff=()
    else
        declare -a diff=()
    fi

    declare -i skip
    local key1 val2
    for key1 in "${!arr1[@]}"; do
        skip=0
        for val2 in "${arr2[@]}"; do
            [[ "${arr1[$key1]}" == "$val2" ]] && { skip=1; break; }
        done
        [[ ${skip} -eq 1 ]] || diff["$key1"]="${arr1[$key1]}"
    done

    arrayToString "$(declare -p diff)"
}

##
# Checks if the given key or index exists in the array
# @param string $1 Needle
# @param arrayToString $2 Haystack
# @returnStatus 1 If first parameter named needle is empty
# @returnStatus 1 If needle is not a key of the haystack
function arrayKeyExists ()
{
    local needle="$1"
    if [[ -z "$needle" ]]; then
        return 1
    fi

    local haystack="$2"
    local type="$(__arrayType "$haystack")"
    if [[ "$type" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr="$(arrayToString "$haystack")"
    elif [[ "$type" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$(arrayToString "$haystack")"
    elif [[ "$type" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr="$haystack"
    elif [[ "$type" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$haystack"
    else
        declare -a arr="(${haystack})"
    fi

    local key
    for key in "${!arr[@]}"; do
        if [[ "$key" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

##
# Merge two arrays
# If the input arrays have the same string keys, then the later value for that key will overwrite the previous one.
# If, however, the arrays contain numeric keys, the later value will not overwrite the original value, but will be appended.
# Values in the input array with numeric keys will be renumbered with incrementing keys starting from zero in the result array.
#
# @example inputs "v1 v2 v3" "v1"
# @example return "v1 v2 v3 v1"
#
# @example inputs "(["k0"]="v1" ["k1"]="v2" ["k2"]="v3")" "v1"
# @example return "(["k0"]="v1" ["k1"]="v2" ["k2"]="v3" [0]=""v1")"
#
# @example inputs "(["k0"]="v1" ["k1"]="v2" ["k2"]="v3")" "["k0"]="R1"
# @example return "(["k0"]="R1" ["k1"]="v2" ["k2"]="v3")"
#
# @param arrayToString $1 Arr1
# @param arrayToString $2 Arr2
# @return arrayToString
function arrayMerge ()
{
    local haystack1="$1"
    local type1="$(__arrayType "$haystack1")"
    if [[ "$type1" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr1="$(arrayToString "$haystack1")"
    elif [[ "$type1" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr1="$(arrayToString "$haystack1")"
    elif [[ "$type1" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr1="$haystack1"
    elif [[ "$type1" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr1="$haystack1"
    else
        declare -a arr1="(${haystack1})"
    fi

    local haystack2="$2"
    local type2="$(__arrayType "$haystack2")"
    if [[ "$type2" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr2="$(arrayToString "$haystack2")"
    elif [[ "$type2" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr2="$(arrayToString "$haystack2")"
    elif [[ "$type2" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr2="$haystack2"
    elif [[ "$type2" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr2="$haystack2"
    else
        declare -a arr2="(${haystack2})"
    fi
    if [[ "${#arr1[@]}" -eq 0 && "${#arr2[@]}" -eq 0 ]]; then
        echo "()"
        return 0
    elif [[ "${#arr2[@]}" -eq 0 ]]; then
        arrayToString "$(declare -p arr1)"
        return 0
    fi

    declare -i assoc=0
    if [[ "${type1: -1}" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" || "${type2: -1}" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr=()
        assoc=1
    else
        declare -a arr=()
    fi

    local key
    declare -i max=0
    for key in "${!arr1[@]}"; do
        if [[ ${assoc} -eq 1 ]]; then
            if [[ "$key" =~ ^[0-9]+$ ]]; then
                arr["$max"]="${arr1["$key"]}"
                max+=1
            else
                arr["$key"]="${arr1["$key"]}"
            fi
        else
            arr+=("${arr1["$key"]}")
        fi
    done
    for key in "${!arr2[@]}"; do
        if [[ ${assoc} -eq 1 ]]; then
            if [[ "$key" =~ ^[0-9]+$ ]]; then
                arr["$max"]="${arr2["$key"]}"
                max+=1
            else
                arr["$key"]="${arr2["$key"]}"
            fi
        else
            arr+=("${arr2["$key"]}")
        fi
    done

    arrayToString "$(declare -p arr)"
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
    local needle="$1"
    if [[ -z "$needle" ]]; then
        return 1
    fi

    local haystack="$2"
    local type="$(__arrayType "${haystack}")"
    if [[ "$type" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr="$(arrayToString "${haystack}")"
    elif [[ "$type" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$(arrayToString "${haystack}")"
    elif [[ "$type" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr="${haystack}"
    elif [[ "$type" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="${haystack}"
    else
        declare -a arr="(${haystack})"
    fi

    local key
    for key in "${!arr[@]}"; do
        if [[ "${arr[$key]}" == $needle ]]; then
            echo "$key"
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
    local str="$1"
    if [[ -z "$str" ]]; then
        echo "()"
        return 0
    fi

    # Remove declare -OPTIONS NAME='(
    str="${str#*\(}"
    # Remove )'
    str="${str%\)*}"
    # Remove escaping of single quote (') by declare function
    str="${str//\\\'\'/}"

    echo "(${str})"
}

##
# Count all elements in an array
# @param string $1 Haystack
# return int
function count ()
{
    declare -i count=0
    local haystack="$1"
    if [[ -z "$haystack" || "$haystack" =~ ^\(([[:space:]]*)?\)*$ ]]; then
        echo ${count}
        return 0
    fi

    local type="$(__arrayType "$haystack")"
    if [[ "$type" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr="$(arrayToString "$haystack")"
    elif [[ "$type" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$(arrayToString "$haystack")"
    elif [[ "$type" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr="$haystack"
    elif [[ "$type" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$haystack"
    else
        declare -a arr="(${haystack})"
    fi
    count="${#arr[@]}"

    echo ${count}
}

##
# Check if a value is available in array
# @param string $1 Needle
# @param arrayToString $2 Haystack
# @returnStatus 1 If first parameter named needle is empty
# @returnStatus 1 If needle does not exist in haystack
function inArray ()
{
    local needle="$1"
    if [[ -z "$needle" ]]; then
        return 1
    fi

    local haystack="$2"
    local type="$(__arrayType "$haystack")"
    if [[ "$type" == "${BP_ARRAY_DECLARED_INDEXED_TYPE}" ]]; then
        declare -a arr="$(arrayToString "$haystack")"
    elif [[ "$type" == "${BP_ARRAY_DECLARED_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$(arrayToString "$haystack")"
    elif [[ "$type" == "${BP_ARRAY_INDEXED_TYPE}" ]]; then
        declare -a arr="$haystack"
    elif [[ "$type" == "${BP_ARRAY_ASSOCIATIVE_TYPE}" ]]; then
        declare -A arr="$haystack"
    else
        declare -a arr="(${haystack})"
    fi

    local value
    for value in "${arr[@]}"; do
        if [[ "$value" == ${needle} ]]; then
            return 0
        fi
    done

    return 1
}