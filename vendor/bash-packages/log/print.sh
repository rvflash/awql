#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
# All functions dedicated to print log
#
# @package log
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Load configuration files if is not already loaded
if [[ -z "${BP_LOG_LEVEL_INFO}" || -z "${BP_ASCII_COLOR_OFF}" ]]; then
    declare -r BP_LOG_PRINT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -z "${BP_LOG_LEVEL_INFO}" ]]; then
        source "${BP_LOG_PRINT_DIR}/log.sh"
    fi
    if [[ -z "${BP_ASCII_COLOR_OFF}" ]]; then
        source "${BP_LOG_PRINT_DIR}/../encoding/ascii.sh"
    fi
fi

##
# Print pre-formatted Str in the standard output
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 Level
# @param string $2 Format
# @param string ${@:3} Args
# @return string
# @returnStatus 1 If the datas to print are invalids
function __printLog ()
{
    if [[ ${BP_LOG_MUTE} -ne 0 ]]; then
        return 0
    fi

    local level="$1"
    if [[ ${BP_LOG_WITH_LEVEL} -eq 0 ]]; then
        level=""
    elif [[ -n "$level" ]]; then
        level+=" "
    fi

    local format="$2"
    if [[ -z "$format" ]]; then
        return 0
    else
        local utcDate
        if [[ ${BP_LOG_WITH_DATE_TIME} -ne 0 ]];then
            utcDate="$(date "+${BP_LOG_UTC_DATE_FORMAT}") "
        fi
        printf "%s%s%s${format}\n" "$utcDate" "$level" "${BP_LOG_PREFIX}" "${@:3}" 2>/dev/null
    fi
}

##
# Print pre-formatted Str in the standard output
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 Format
# @param string ${@:2} Args
# @return string
# @returnStatus 1 If the datas to print are invalids
function pInfoF ()
{
    __printLog "${BP_LOG_LEVEL_INFO}" "${@}"
}

##
# Print Str in the standard output
# @param string $1 Str
# @return string
function pInfo ()
{
    pInfoF "%s" "$1"
}

##
# Print in yellow pre-formatted Str in the standard output
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 Format
# @param string ${@:2} Args
# @return string
# @returnStatus 1 If the datas to print are invalids
function pWarnF ()
{
    local format="$1"
    if [[ -n "$format" ]]; then
        if [[ -n "${@:2}" || "$format" != *"%"[bqdiouxXfeEgGcsnaA]* ]]; then
            # Format is not a formatstring or there are arguments
            format="${BP_ASCII_COLOR_YELLOW}${format}${BP_ASCII_COLOR_OFF}"
        fi
    fi

    __printLog "${BP_LOG_LEVEL_WARN}" "$format" "${@:2}"
}

##
# Print in yellow Str in the standard output
# @param string $1 Str
# @return string
function pWarn ()
{
    pWarnF "%s" "$1"
}

##
# Print in red pre-formatted Str in the standard output
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 Format
# @param string ${@:2} Args
# @return string
# @returnStatus 1 If the datas to print are invalids
function pErrorF ()
{
    local format="$1"
    if [[ -n "$format" ]]; then
        if [[ -n "${@:2}" || "$format" != *"%"[bqdiouxXfeEgGcsnaA]* ]]; then
            # Format is not a formatstring or there are arguments
            format="${BP_ASCII_COLOR_IRED}${format}${BP_ASCII_COLOR_OFF}"
        fi
    fi

    __printLog "${BP_LOG_LEVEL_ERROR}" "$format" "${@:2}"
}

##
# Print in red Str in the standard output
# @param string $1 Str
# @return string
function pError ()
{
    pErrorF "%s" "$1"
}

##
# Print in dark red pre-formatted Str in the standard output and exit with error code
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 Format
# @param string ${@:2} Args
# @return string
# @exitStatus 1 As expected with fatal method: print log and exit
function pFatalF ()
{
    local format="$1"
    if [[ -n "$format" ]]; then
        if [[ -n "${@:2}" || "$format" != *"%"[bqdiouxXfeEgGcsnaA]* ]]; then
            # Format is not a formatstring or there are arguments
            format="${BP_ASCII_COLOR_RED}${format}${BP_ASCII_COLOR_OFF}"
        fi
    fi

    __printLog "${BP_LOG_LEVEL_FATAL}" "$format" "${@:2}"
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
    exit 1
}

##
# Print in dark red Str in the standard output and and exit with error code
# @param string $1 Str
# @return string
# @exitStatus 1 As expected with fatal method: print log and exit
function pFatal ()
{
    pFatalF "%s" "$1"
}