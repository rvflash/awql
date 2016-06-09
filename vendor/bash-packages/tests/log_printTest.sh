#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../log/print.sh

declare -r TEST_LOG_PREFIX="bp"
declare -r TEST_LOG_NUM="12"
declare -r TEST_LOG_MSG="Bash package with informational message"
declare -r TEST_LOG_WARN_MSG=$(echo -e "${BP_ASCII_COLOR_YELLOW}${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")
declare -r TEST_LOG_ERROR_MSG=$(echo -e "${BP_ASCII_COLOR_IRED}${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")
declare -r TEST_LOG_FATAL_MSG=$(echo -e "${BP_ASCII_COLOR_RED}${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")


readonly TEST_LOG_P_INFO="-01-01-01-01-01-01-01-01-01"

function test_pInfo ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pInfo)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_INFO} ${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_INFO} "${TEST_LOG_PREFIX}" ${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_INFO} ${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_INFO} ${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(pInfo "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_INFO_F="-01-01-01-01-01-11"

function test_pInfoF ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pInfoF)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with only a message
    test=$(pInfoF "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern and message
    test=$(pInfoF "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pInfoF "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pInfoF "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$test" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(pInfoF "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_NUM}-0" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_WARN="-01-01-01-01-01-01-01-01-01"

function test_pWarn ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pWarn)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_WARN} ${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_WARN} "${TEST_LOG_PREFIX}" ${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_WARN} ${TEST_LOG_PREFIX} ${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_WARN} ${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(pWarn "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_PREFIX} ${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_WARN_F="-01-01-01-01-01-11"

function test_pWarnF ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pWarnF)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with only a message
    test=$(pWarnF "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern and message
    test=$(pWarnF "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_WARN_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pWarnF "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_YELLOW}${TEST_LOG_NUM}-${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pWarnF "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_YELLOW}${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(pWarnF "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_YELLOW}${TEST_LOG_NUM}-0${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_ERROR="-01-01-01-01-01-01-01-01-01"

function test_pError ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pError)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_ERROR} ${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_ERROR} "${TEST_LOG_PREFIX}" ${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_ERROR} ${TEST_LOG_PREFIX} ${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_ERROR} ${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(pError "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_PREFIX} ${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_ERROR_F="-01-01-01-01-01-11"

function test_pErrorF ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pErrorF)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with only a message
    test=$(pErrorF "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern and message
    test=$(pErrorF "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_ERROR_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pErrorF "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_IRED}${TEST_LOG_NUM}-${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pErrorF "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_IRED}${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(pErrorF "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_IRED}${TEST_LOG_NUM}-0${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_FATAL="-11-11-11-11-11-11-11-11-11"

function test_pFatal ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pFatal)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_FATAL} ${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_FATAL} "${TEST_LOG_PREFIX}" ${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_FATAL} ${TEST_LOG_PREFIX} ${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${BP_LOG_LEVEL_FATAL} ${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(pFatal "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_PREFIX} ${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1
}


readonly TEST_LOG_P_FATAL_F="-11-11-11-11-11-21"

function test_pFatalF ()
{
    local test

    # Reset
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(pFatalF)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with only a message
    test=$(pFatalF "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern and message
    test=$(pFatalF "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "${TEST_LOG_FATAL_MSG}" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pFatalF "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_RED}${TEST_LOG_NUM}-${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(pFatalF "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_RED}${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(pFatalF "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ "$(echo -e "${BP_ASCII_COLOR_RED}${TEST_LOG_NUM}-0${BP_ASCII_COLOR_OFF}")" == "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "pInfo" "${TEST_LOG_P_INFO}" "$(test_pInfo)"
bashUnit "pInfoF" "${TEST_LOG_P_INFO_F}" "$(test_pInfoF)"
bashUnit "pWarn" "${TEST_LOG_P_WARN}" "$(test_pWarn)"
bashUnit "pWarnF" "${TEST_LOG_P_WARN_F}" "$(test_pWarnF)"
bashUnit "pError" "${TEST_LOG_P_ERROR}" "$(test_pError)"
bashUnit "pErrorF" "${TEST_LOG_P_ERROR_F}" "$(test_pErrorF)"
bashUnit "pFatal" "${TEST_LOG_P_FATAL}" "$(test_pFatal)"
bashUnit "pFatalF" "${TEST_LOG_P_FATAL_F}" "$(test_pFatalF)"