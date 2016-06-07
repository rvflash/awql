#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package term
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Load dependencies files if are not already loaded
if [[ -z "${BP_ASCII_COLOR_OFF}" ]]; then
    declare -r BP_TERM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${BP_TERM_DIR}/encoding/ascii.sh"
fi
declare -r BP_TERM_ERROR="An error occured"

##
# @example Are you sure ? [Y/N]
# @codeCoverageIgnore
# @param string $1 Message
# @param string $2 Extended message to add after confirm request [optional]
# @returnStatus 0 I answer is YES
# @returnStatus 1 I answer is NO
function confirm ()
{
    local msg="$1"
    local extendedMsg="$2"

    local str
    while read -e -p "${msg} ${extendedMsg}? " str; do
        if [[ "$str" == [Yy] || "$str" == [Yy][Ee][Ss] ]]; then
            return 0
        elif [[ "$str" == [Nn] || "$str" == [Nn][Oo] ]]; then
            return 1
        fi
    done
}

##
# Ask anything to user and get his response
# @codeCoverageIgnore
# @param string $1 Message
# @param int $2 If 1 or undefined, a response is required, 0 otherwise [optional]
# @param string $3 Mandatory text [optional]
# return string
function dialog ()
{
    local msg="$1"
    declare -i mandatory="$2"
    if [[ ${mandatory} -ne 0 ]]; then
        mandatory=1
    fi
    local mandatoryMsg="$3"

    declare -i count=0
    local mandatoryField
    local str
    while [[ "$mandatory" -ne -1 ]]; do
        if [[ ${mandatory} -eq 1 && ${count} -gt 0 && -n "$mandatoryMsg" ]]; then
            mandatoryField=" $mandatoryMsg"
        fi
        read -e -p "${msg}${mandatoryField}: " str
        if [[ -n "$str" || "$mandatory" -eq 0 ]]; then
            echo "$str"
            mandatory=-1
        fi
        ((count++))
    done
}

##
# Print a progress bar
#
# @example
#    Upload  [++++++++++++++++----] 70%
#
# @param string $1 Name
# @param int $2 Step, default '0'
# @param int $3 Max, default '100'
# @param string $4 Error, default 'An error occured'. Printed if the max value is lower or equals to 0
# @param int $5 With, default '20'
# @param string $6 CharEmpty, default '-'
# @param string $7 CharFilled, default '+'
# @return string
# @returnStatus 1 If first parameter named jobName is empty
# @returnStatus 1 If third parameter named Max is negative (an error occured)
function progressBar ()
{
    local name="$1"
    if [[ -z "$name" ]]; then
        return 1
    fi
    declare -i step
    if [[ "$2" =~ ^[-+]?[0-9]+$ ]]; then
        step="$2"
    else
        step=0
    fi
    declare -i max
    if [[ "$3" =~ ^[-+]?[0-9]+$ ]]; then
        max="$3"
    else
        max=100
    fi
    local error="$4"
    if [[ -z "$error" ]]; then
        error="${BP_TERM_ERROR}"
    fi
    if [[ ${max} -le 0 ]]; then
        echo -e " ${BP_ASCII_COLOR_RED}${error}${BP_ASCII_COLOR_OFF}"
        return 1
    fi
    declare -i width="$5"
    if [[ ${width} -eq 0 ]]; then
        width=20
    fi
    local charEmpty="$6"
    if [[ -z "$charEmpty" ]]; then
        charEmpty="-"
    fi
    local charFilled="$7"
    if [[ -z "$charFilled" ]]; then
        charFilled="+"
    fi

    declare -i percent=0
    declare -i progress=0
    if [[ ${step} -gt 0 ]]; then
        percent=$((100*${step}/${max}))
        progress=$((${width}*${step}/${max}))
        if [[ ${progress} -gt ${width} ]]; then
            progress=${width}
        fi
    fi
    declare -i empty=$((${progress}-${width}))

    # Output to screen
    local strFilled=$(printf "%${progress}s" | tr " " "$charFilled")
    local strEmpty=$(printf "%${empty}s" | tr " " "$charEmpty")
    printf "\r%s [%s%s] %d%%" "$name" "$strFilled" "$strEmpty" "$percent"

    # Job done
    if [[ ${step} -ge ${max} ]]; then
        echo
    fi
}

##
# Get width or height or both of a terminal window
#
# @example return width
# @example return width height
#
# @param string $1 Type width or height [optional]
# @return int or arrayToString
function windowSize ()
{
    local type="$1"
    local size
    size=$(stty size 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    case "$type" in
        "width" ) echo -n "${size##* }" ;;
        "height") echo -n "${size%% *}" ;;
        *       ) echo -n "(${size})" ;;
    esac
}