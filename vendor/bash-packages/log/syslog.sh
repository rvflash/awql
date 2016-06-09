#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
# All functions dedicated to write log into file
#
# @package log
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Load configuration file if is not already loaded
if [[ -z "${BP_LOG_LEVEL_INFO}" ]]; then
    declare -r BP_LOG_FILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${BP_LOG_FILE_DIR}/log.sh"
fi

##
# Check if file can be created, if not exists, or if it is writable
# @param string $1 FilePath
# @returnStatus 1 If file can not be create, 0 otherwise
function __isWritableLogFile ()
{
    local filePath="$1"
    if [[ -z "$filePath" || -d "$filePath" ]]; then
        return 1
    elif [[ ! -f "$filePath" ]]; then
        # Try to create log file
        touch "$filePath" 2>/dev/null
    fi

    # Writable file ?
    if [[ -w "$filePath" ]]; then
        return 0
    else
        return 1
    fi
}

##
# Print pre-formatted Str into log file
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 Level
# @param string $2 FilePath
# @param string $3 Format
# @param string ${@:4} Args [optional]
# @returnStatus 1 If filepath is not writable
# @returnStatus 1 If the datas to print are invalids
# @returnStatus 2 If formatstring is empty or mal-formated
function __writeLog ()
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

    local filePath="$2"
    if ! __isWritableLogFile "$filePath"; then
        return 1
    fi

    local format="$3"
    if [[ -z "$format" ]]; then
        return 2
    fi

    local utcDate
    if [[ ${BP_LOG_WITH_DATE_TIME} -ne 0 ]];then
        utcDate="$(date "+${BP_LOG_UTC_DATE_FORMAT}") "
    fi

    printf "%s%s%s${format}\n" "$utcDate" "$level" "${BP_LOG_PREFIX}" "${@:4}" >> "$filePath" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        return 2
    fi
}

##
# Print pre-formatted Str into log file
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 FilePath
# @param string $2 Format
# @param string ${@:3} Args [optional]
# @returnStatus 1 If filepath is not writable
# @returnStatus 2 If formatstring is empty or mal-formated
function wInfoF ()
{
    __writeLog "${BP_LOG_LEVEL_INFO}" "${@}"
}

##
# Print Str into log file
# @param string $1 FilePath
# @param string $2 Str
# @returnStatus 1 If filepath is not writable
# @returnStatus 2 If formatstring is empty or mal-formated
function wInfo ()
{
    wInfoF "$1" "%s" "$2"
}

##
# Print, with warning level message, a pre-formatted Str into log file
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 FilePath
# @param string $2 Format
# @param string ${@:3} Args [optional]
# @returnStatus 1 If filepath is not writable
# @returnStatus 2 If formatstring is empty or mal-formated
function wWarnF ()
{
    __writeLog "${BP_LOG_LEVEL_WARN}" "${@}"
}

##
# Print with warning level message, a Str into log file
# @param string $1 FilePath
# @param string $2 Str
# @returnStatus 1 If filepath is not writable
# @returnStatus 2 If formatstring is empty or mal-formated
function wWarn ()
{
    wWarnF "$1" "%s" "$2"
}

##
# Print, with error level message, a pre-formatted Str into log file
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 FilePath
# @param string $2 Format
# @param string ${@:3} Args [optional]
# @returnStatus 1 If filepath is not writable
# @returnStatus 2 If formatstring is empty or mal-formated
function wErrorF ()
{
    __writeLog "${BP_LOG_LEVEL_ERROR}" "${@}"
}

##
# Print, with error level message, a Str into log file
# @param string $1 FilePath
# @param string $2 Str
# @returnStatus 1 If filepath is not writable
# @returnStatus 2 If formatstring is empty or mal-formated
function wError ()
{
    wErrorF "$1" "%s" "$2"
}

##
# Print, with fatal level message, a pre-formatted Str into log file and exit with error code
# The text format is given in Format, while all arguments the formatstring may point to are given after that
# @param string $1 FilePath
# @param string $2 Format
# @param string ${@:3} Args [optional]
# @return string
# @exitStatus 1 As expected with fatal method: log and exit
# @exitStatus 2 If file logging has failed
function wFatalF ()
{
    __writeLog "${BP_LOG_LEVEL_FATAL}" "${@}"
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
    exit 1
}

##
# Print, with fatal level message, a Str into log file and and exit with error code
# @param string $1 FilePath
# @param string $2 Str
# @exitStatus 1 As expected with fatal method: log and exit
# @exitStatus 2 If file logging has failed
function wFatal ()
{
    wFatalF "$1" "%s" "$2"
}