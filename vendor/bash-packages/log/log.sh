#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package log
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Constant
declare -r BP_LOG_LEVEL_INFO="info"
declare -r BP_LOG_LEVEL_WARN="warn"
declare -r BP_LOG_LEVEL_ERROR="error"
declare -r BP_LOG_LEVEL_FATAL="fatal"
declare -r BP_LOG_UTC_DATE_FORMAT="%Y-%m-%dT%H:%M:%S%z"

# Properties
declare BP_LOG_PREFIX
declare -i BP_LOG_WITH_DATE_TIME=0
declare -i BP_LOG_WITH_LEVEL=0
declare -i BP_LOG_MUTE=0


##
# Add or remove date and time of each log
# @returnStatus 1 If log methods are enabled, 0 otherwise
function logIsMuted ()
{
    if [[ ${BP_LOG_MUTE} -eq 0 ]]; then
        return 1
    else
        return 0
    fi
}

##
# Disable or re-enable log
# @param int $1 Enable
function logMute ()
{
    BP_LOG_MUTE="$1"
}

##
# Get prefix used on each log
# @return string $1 Str
function logPrefix ()
{
    echo "${BP_LOG_PREFIX}"
}

##
# Set prefix to use on each log
# @param string $1 Str
function logUsePrefix ()
{
    BP_LOG_PREFIX="$1"
    if [[ -n "${BP_LOG_PREFIX}" ]]; then
        BP_LOG_PREFIX+=" "
    fi
}

##
# Add or remove date and time of each log
# @param int $1 Enable
function logUseDateTime ()
{
    BP_LOG_WITH_DATE_TIME="$1"
}

##
# Add or remove level of each log
# @param int $1 Enable
function logUseLevel ()
{
    BP_LOG_WITH_LEVEL="$1"
}

##
# Check if date and time is displayed for each log
# @returnStatus 1 If date and time not used as prefix, 0 otherwise
function logWithDateTime ()
{
    if [[ ${BP_LOG_WITH_DATE_TIME} -eq 0 ]]; then
        return 1
    else
        return 0
    fi
}

##
# Check if level prefixes a log
# @returnStatus 1 If level not used as prefix, 0 otherwise
function logWithLevel ()
{
    if [[ ${BP_LOG_WITH_LEVEL} -eq 0 ]]; then
        return 1
    else
        return 0
    fi
}