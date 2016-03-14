#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package string
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

##
# Calculate and return a checksum for one string
# @param string $1 Str
# @return string
# @returnStatus 1 If first parameter named string is empty
# @returnStatus 1 If checkum is empty or cksum methods returns in error
function checksum ()
{
    local str="$1"
    if [[ -z "$str" ]]; then
        return 1
    fi

    declare -i checksum
    checksum="$(cksum <<<"$(trim "$str")" | awk '{print $1}')"
    if [[ $? -ne 0 || -z "$checksum" ]]; then
        return 1
    fi

    echo -n "$checksum"
}

##
# Determine whether a variable is empty
# The following things are considered to be empty:
#
#     "" (an empty string)
#     0 (0 as an integer or string)
#     0.0 (0 as a float)
#     FALSE
#     array() (an empty array)
# @param string $1 Str
# @returnStatus 1 If empty, 0 otherwise
function isEmpty ()
{
    local str="$1"
    if [[ -z "$str" || "$str" == 0 || "$str" == "0.0" || "$str" == false || "$str" =~ ^\(([[:space:]]*)?\)*$ ]]; then
        return 0
    fi

    return 1
}

##
# Print a string and apply on it a left padding
# @param string $1 Str
# @param int $2 Pad length
# @param string $3 Padding char [optional]
# @return string
function printLeftPadding ()
{
    local str="$1"
    declare -i pad="$2"
    local chr="$3"

    if [[ -z "$chr" ]]; then
        pad+=${#str}
        printf "%${pad}s" "$str"
    else
        if [[ ${pad} -gt 1 ]]; then
            local PADDING=$(printf '%0.1s' "$chr"{1..500})
            printf '%*.*s' 0 $((${pad} - 1)) "${PADDING}"
        fi
        echo -n " $str"
    fi
}

##
# Print a string and apply on it a right padding
# @param string $1 Str
# @param int $2 Pad length
# @param string $3 Padding char [optional]
# @return string
function printRightPadding ()
{
    local str="$1"
    declare -i pad="$2"
    local chr="$3"

    if [[ -z "$chr" ]]; then
        pad+=${#str}
        printf "%-${pad}s" "$str"
    else
        echo -n "$str "
        if [[ ${pad} -gt 1 ]]; then
            local PADDING=$(printf '%0.1s' "$chr"{1..500})
            printf '%*.*s' 0 $((${pad} - 1)) "${PADDING}"
        fi
    fi
}

##
# This function returns a string with whitespace (or other characters) stripped from the beginning and end of str
# @param string $1 Str
# @param string $2 Character to mask [optional]
# @return string
function trim ()
{
    local str="$1"
    if [[ -z "$str" ]]; then
        return 0
    fi

    local mask="$2"
    if [[ -n "$mask" ]]; then
        # Escape special chars
        mask=$( echo "$mask" | sed -e 's/[]\/$*.^|[]/\\&/g' )
        # Remove characters to mask
        str=$( echo "$str" | sed -e "s/^[[:space:]]*[${mask}]*//" -e "s/[${mask}]*[[:space:]]*$//" )
    fi

    echo -n "$str" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//"
}