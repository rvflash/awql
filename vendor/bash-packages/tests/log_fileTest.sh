#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../log/file.sh

declare -r TEST_LOG_FILE="/tmp/bp_file.log"
declare -r TEST_LOG_PREFIX="bp"
declare -r TEST_LOG_NUM="12"
declare -r TEST_LOG_MSG="Bash package with informational message"


readonly TEST_LOG_W_INFO="-11-01-01-01-01-01-01-01-01-01"

function test_wInfo ()
{
    local test
    declare -i testFileSize

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wInfo)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only filepath
    test=$(wInfo "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_INFO} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_INFO} "${TEST_LOG_PREFIX}" ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    testFileSize=$(wc -l < "${TEST_LOG_FILE}")
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && ${testFileSize} -eq $(wc -l < "${TEST_LOG_FILE}") ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_INFO} ${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_INFO} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(wInfo "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_INFO_F="-11-21-01-01-01-01-21"

function test_wInfoF ()
{
    local test

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wInfoF)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only a filepath
    test=$(wInfoF "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wInfoF "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern and message
    test=$(wInfoF "${TEST_LOG_FILE}" "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wInfoF "${TEST_LOG_FILE}" "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wInfoF "${TEST_LOG_FILE}" "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(wInfoF "${TEST_LOG_FILE}" "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-0" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_WARN="-11-01-01-01-01-01-01-01-01-01"

function test_wWarn ()
{
    local test
    declare -i testFileSize

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wWarn)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only filepath
    test=$(wWarn "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_WARN} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_WARN} "${TEST_LOG_PREFIX}" ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    testFileSize=$(wc -l < "${TEST_LOG_FILE}")
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && ${testFileSize} -eq $(wc -l < "${TEST_LOG_FILE}") ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_WARN} ${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_WARN} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(wWarn "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_WARN_F="-11-21-01-01-01-01-21"

function test_wWarnF ()
{
    local test

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wWarnF)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only a filepath
    test=$(wWarnF "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wWarnF "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern and message
    test=$(wWarnF "${TEST_LOG_FILE}" "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wWarnF "${TEST_LOG_FILE}" "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wWarnF "${TEST_LOG_FILE}" "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(wWarnF "${TEST_LOG_FILE}" "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-0" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_ERROR="-11-01-01-01-01-01-01-01-01-01"

function test_wError ()
{
    local test
    declare -i testFileSize

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wError)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only filepath
    test=$(wError "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_ERROR} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_ERROR} "${TEST_LOG_PREFIX}" ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    testFileSize=$(wc -l < "${TEST_LOG_FILE}")
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && ${testFileSize} -eq $(wc -l < "${TEST_LOG_FILE}") ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_ERROR} ${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_ERROR} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(wError "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_ERROR_F="-11-21-01-01-01-01-21"

function test_wErrorF ()
{
    local test

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wErrorF)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only a filepath
    test=$(wErrorF "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wErrorF "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern and message
    test=$(wErrorF "${TEST_LOG_FILE}" "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wErrorF "${TEST_LOG_FILE}" "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wErrorF "${TEST_LOG_FILE}" "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(wErrorF "${TEST_LOG_FILE}" "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-0" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_FATAL="-21-11-11-11-11-11-11-11-11-11"

function test_wFatal ()
{
    local test
    declare -i testFileSize

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wFatal)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only filepath
    test=$(wFatal "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date as prefix
    logUseDateTime 1
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level as prefix
    logUseLevel 1
    logUseDateTime 1
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_FATAL} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and date + level + custom prefix
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "$(date "+${BP_LOG_UTC_DATE_FORMAT}") ${BP_LOG_LEVEL_FATAL} "${TEST_LOG_PREFIX}" ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with mute mode enabled
    logMute 1
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 1
    testFileSize=$(wc -l < "${TEST_LOG_FILE}")
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && ${testFileSize} -eq $(wc -l < "${TEST_LOG_FILE}") ]] && echo -n 1

    # Check with message and level + custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 1
    logUseDateTime 0
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_FATAL} ${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and level as prefix
    logMute 0
    logUsePrefix ""
    logUseLevel 1
    logUseDateTime 0
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${BP_LOG_LEVEL_FATAL} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with message and custom prefix
    logMute 0
    logUsePrefix "${TEST_LOG_PREFIX}"
    logUseLevel 0
    logUseDateTime 0
    test=$(wFatal "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_PREFIX} ${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


readonly TEST_LOG_W_FATAL_F="-21-21-11-11-11-11-21"

function test_wFatalF ()
{
    local test

    # Reset
    rm -f "${TEST_LOG_FILE}"
    logMute 0
    logUsePrefix ""
    logUseLevel 0
    logUseDateTime 0

    # Check nothing
    test=$(wFatalF)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_LOG_FILE}" ]] && echo -n 1

    # Check with only a filepath
    test=$(wFatalF "${TEST_LOG_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && -z "$(cat "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with filepath and message
    test=$(wFatalF "${TEST_LOG_FILE}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern and message
    test=$(wFatalF "${TEST_LOG_FILE}" "%s" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_LOG_FILE}" && "${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wFatalF "${TEST_LOG_FILE}" "%d-%s" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with pattern, integer and message
    test=$(wFatalF "${TEST_LOG_FILE}" "%s: %d-%s" "${TEST_LOG_MSG}" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_MSG}: ${TEST_LOG_NUM}-${TEST_LOG_MSG}" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1

    # Check with invalid formatstring
    test=$(wFatalF "${TEST_LOG_FILE}" "%s-%d" "${TEST_LOG_NUM}" "${TEST_LOG_MSG}")
    echo -n "-$?"
    [[ -z "$test" && "${TEST_LOG_NUM}-0" == "$(tail -n1 "${TEST_LOG_FILE}")" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "wInfo" "${TEST_LOG_W_INFO}" "$(test_wInfo)"
bashUnit "wInfoF" "${TEST_LOG_W_INFO_F}" "$(test_wInfoF)"
bashUnit "wWarn" "${TEST_LOG_W_WARN}" "$(test_wWarn)"
bashUnit "wWarnF" "${TEST_LOG_W_WARN_F}" "$(test_wWarnF)"
bashUnit "wError" "${TEST_LOG_W_ERROR}" "$(test_wError)"
bashUnit "wErrorF" "${TEST_LOG_W_ERROR_F}" "$(test_wErrorF)"
bashUnit "wFatal" "${TEST_LOG_W_FATAL}" "$(test_wFatal)"
bashUnit "wFatalF" "${TEST_LOG_W_FATAL_F}" "$(test_wFatalF)"