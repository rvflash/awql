#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package time
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

declare -r BP_OS="$(uname -s)"
declare -r BP_UTC_DATE_FORMAT="%Y-%m-%dT%H:%M:%S%z"

##
# Get current timestamp
# @example 1450485413
# @return int
# @returnStatus 1 If date method fails
function timestamp ()
{
    declare -i ts

    ts=$(date +"%s" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo -n ${ts}
}

##
# Get as arrayToString the time duration in seconds to run command given as parameter
# @example (["real"]="0m0.011s" ["user"]="0m0.001s" ["sys"]="0m0.005s" )
# @param string $1 Command
# @return arrayToString
# @returnStatus 1 If the first parameter named command is empty
# @returnStatus 1 If the time method does not return expected time values
function timeTodo ()
{
    local command="$1"
    if [[ -z "$command" ]]; then
        return 1
    fi
    declare -a timer="($({ time "$command"; } 2>&1 >/dev/null))"

    if [[ "${timer[0]}" == "real" && "${timer[2]}" == "user" && "${timer[4]}" == "sys" ]]; then
        echo -n "([\"real\"]=\"${timer[1]}\" [\"user\"]=\"${timer[3]}\" [\"sys\"]=\"${timer[5]}\")"
        return 0
    fi

    return 1
}

##
# Get in seconds the user time duration to run command given as parameter
# @param string $1 Command
# @return float
# @returnStatus 1 If the first parameter named command is empty
# @returnStatus 1 If the time method does not return the user timer
function userTimeTodo ()
{
    local command="$1"
    if [[ -z "$command" ]]; then
        return 1
    fi

    local userTime
    userTime="$(timeTodo "$command")"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    declare -a timer="$userTime"
    if [[ -n "${timer["user"]}" ]]; then
        echo -n "${timer["user"]}" |  awk -F '[^0-9.]*' '$0=$2'
        return 0
    fi

    return 1
}

##
# Launch command in first parameter and check time duration.
# If time exceeds the maximum float value given in second parameter return 1, 0 otherwise
# @param string $1 Command
# @param float $1 Maximum time in second
# @returnStatus 1 If the first parameter named command is empty
# @returnStatus 1 If the timer of the command's duration does not return float value as expected
# @returnStatus 1 If the second parameter named maxTime is empty or an invalid number
function isUserTimeTodoExceeded ()
{
    local maxTime
    if [[ -z "$1" || -z "$2" ]]; then
        return 1
    elif [[ "$2" =~ ^[-+]?[0-9]+\.[0-9]+$ ]]; then
        maxTime="$2"
    elif [[ "$2" =~ ^[-+]?[0-9]+$ ]]; then
        # Int to float
        maxTime="${2}.0"
    else
        return 1
    fi

    local userTime
    userTime="$(userTimeTodo "$1")"
    if [[ $? -ne 0 ]]; then
        return 1
    elif [[ "$userTime" != *"."* ]]; then
        # Int to float
        userTime="${userTime}.0"
    fi

    declare -i decUserTime=$(( 10#${userTime##*.} ))
    declare -i decMaxTime=$(( 10#${maxTime##*.} ))
    if (( ${userTime%%.*} > ${maxTime%%.*} || ( ${userTime%%.*} == ${maxTime%%.*} && $decUserTime > $decMaxTime ) )) ; then
        return 0
    fi

    return 1
}

##
# Convert a Timestamp to UTC datetime
# @example 2015-12-19T01:28:58+01:00
# @param int $1 Timestamp
# @return string
# @returnStatus 1 If parameter named timestamp is invalid
# @returnStatus 1 If UTC datetime is invalid
function utcDateTimeFromTimestamp ()
{
    # Data check
    local ts="$1"
    if [[ -z "$ts" || ! "$ts" =~ ^[-+]?[0-9]+$ ]]; then
        return 1
    fi

    # MacOs portability
    local options="-d @"
    if [[ "${BP_OS}" == 'Darwin' ]]; then
       options="-r"
    fi

    local utcDatetime
    utcDatetime=$(date ${options}${ts} "+${BP_UTC_DATE_FORMAT}" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo -n "$utcDatetime"
}

##
# Convert a UTC datetime to Timestamp
# @example 1450485413 => 2015-12-19T01:28:58+01:00
# @param string $1 utcDatetime
# @return int
# @returnStatus 1 If parameter named utcDatetime is invalid
# @returnStatus 1 If timestamp is invalid
function timestampFromUtcDateTime ()
{
    local utcDatetime="$1"
    declare -i ts=O

    # Data check
    if [[ -z "$utcDatetime" || ! "$utcDatetime" == *"T"* ]]; then
        return 1
    fi

    # MacOs portability
    if [[ "${BP_OS}" == 'Darwin' ]]; then
        ts=$(date -j -f "${BP_UTC_DATE_FORMAT}" "$utcDatetime" "+%s" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    else
        ts=$(date -d "$utcDatetime" "+%s" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    echo -n ${ts}
}