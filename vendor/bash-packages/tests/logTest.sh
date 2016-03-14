#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../log/log.sh

declare -r TEST_LOG_PREFIX_USED="bp"


readonly TEST_LOG_IS_MUTED="-11-01-11"

function test_logIsMuted ()
{
    local test

    # Check default behavior
    test=$(logIsMuted)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check mute mode
    BP_LOG_MUTE=1
    test=$(logIsMuted)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check unmute mode
    BP_LOG_MUTE=0
    test=$(logIsMuted)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_LOG_MUTE="-01-01-01-01"

function test_logMute ()
{
    local test

    # Check nothing
    logMute
    echo -n "-$?"
    [[ ${BP_LOG_MUTE} -eq 0 ]] && echo -n 1

    # Check with 1
    logMute 1
    echo -n "-$?"
    [[ ${BP_LOG_MUTE} -eq 1 ]] && echo -n 1

    # Check with 0
    logMute 0
    echo -n "-$?"
    [[ ${BP_LOG_MUTE} -eq 0 ]] && echo -n 1

    # Check with anything
    logMute "F"
    echo -n "-$?"
    [[ ${BP_LOG_MUTE} -eq 0 ]] && echo -n 1
}


readonly TEST_LOG_PREFIX="-01-01"

function test_logPrefix ()
{
    local test

    # Check nothing
    BP_LOG_PREFIX=""
    test=$(logPrefix)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with string
    BP_LOG_PREFIX="${TEST_LOG_PREFIX_USED}"
    test=$(logPrefix)
    echo -n "-$?"
    [[ "$test" == "${TEST_LOG_PREFIX_USED}" ]] && echo -n 1
}


readonly TEST_LOG_USE_PREFIX="-01-01-01"

function test_logUsePrefix ()
{
    local test

    # Check nothing
    logUsePrefix
    echo -n "-$?"
    [[ -z "${BP_LOG_PREFIX}" ]] && echo -n 1

    # Check with string
    logUsePrefix "${TEST_LOG_PREFIX_USED}"
    echo -n "-$?"
    [[ "${TEST_LOG_PREFIX_USED} " == "${BP_LOG_PREFIX}" ]] && echo -n 1

    # Check empty string
    logUsePrefix ""
    echo -n "-$?"
    [[ -z "${BP_LOG_PREFIX}" ]] && echo -n 1
}


readonly TEST_LOG_USE_DATE_TIME="-01-01-01-01"

function test_logUseDateTime ()
{
    local test

    # Check nothing
    logUseDateTime
    echo -n "-$?"
    [[ ${BP_LOG_WITH_DATE_TIME} -eq 0 ]] && echo -n 1

    # Check with 1
    logUseDateTime 1
    echo -n "-$?"
    [[ ${BP_LOG_WITH_DATE_TIME} -eq 1 ]] && echo -n 1

    # Check with 0
    logUseDateTime 0
    echo -n "-$?"
    [[ ${BP_LOG_WITH_DATE_TIME} -eq 0 ]] && echo -n 1

    # Check with anything
    logUseDateTime "F"
    echo -n "-$?"
    [[ ${BP_LOG_WITH_DATE_TIME} -eq 0 ]] && echo -n 1
}


readonly TEST_LOG_USE_LEVEL="-01-01-01-01"

function test_logUseLevel ()
{
    local test

    # Check nothing
    logUseLevel
    echo -n "-$?"
    [[ ${BP_LOG_WITH_LEVEL} -eq 0 ]] && echo -n 1

    # Check with 1
    logUseLevel 1
    echo -n "-$?"
    [[ ${BP_LOG_WITH_LEVEL} -eq 1 ]] && echo -n 1

    # Check with 0
    logUseLevel 0
    echo -n "-$?"
    [[ ${BP_LOG_WITH_LEVEL} -eq 0 ]] && echo -n 1

    # Check with anything
    logUseLevel "F"
    echo -n "-$?"
    [[ ${BP_LOG_WITH_LEVEL} -eq 0 ]] && echo -n 1
}


readonly TEST_LOG_WITH_DATE_TIME="-11-01"

function test_logWithDateTime ()
{
    local test

    # Check nothing
    BP_LOG_WITH_DATE_TIME=0
    test=$(logWithDateTime)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with string
    BP_LOG_WITH_DATE_TIME=1
    test=$(logWithDateTime)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_LOG_WITH_LEVEL="-11-01"

function test_logWithLevel ()
{
    local test

    # Check nothing
    BP_LOG_WITH_LEVEL=0
    test=$(logWithLevel)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with string
    BP_LOG_WITH_LEVEL=1
    test=$(logWithLevel)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "logIsMuted" "${TEST_LOG_IS_MUTED}" "$(test_logIsMuted)"
bashUnit "logMute" "${TEST_LOG_MUTE}" "$(test_logMute)"
bashUnit "logPrefix" "${TEST_LOG_PREFIX}" "$(test_logPrefix)"
bashUnit "logUsePrefix" "${TEST_LOG_USE_PREFIX}" "$(test_logUsePrefix)"
bashUnit "logUseDateTime" "${TEST_LOG_USE_DATE_TIME}" "$(test_logUseDateTime)"
bashUnit "logUseLevel" "${TEST_LOG_USE_LEVEL}" "$(test_logUseLevel)"
bashUnit "logWithDateTime" "${TEST_LOG_WITH_DATE_TIME}" "$(test_logWithDateTime)"
bashUnit "logWithLevel" "${TEST_LOG_WITH_LEVEL}" "$(test_logWithLevel)"