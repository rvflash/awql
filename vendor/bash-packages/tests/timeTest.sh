#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../time.sh

# Default entries
declare -r TEST_TIME_COMMAND="${PWD}/unit/test01.sh"
declare -r TEST_TIME_BAD_COMMAND="${PWD}/unit/test00.sh"
declare -r TEST_TIME_LOW_DURATION_COMMAND="0.001"
declare -r TEST_TIME_MEDIUM_DURATION_COMMAND="0.019"
declare -r TEST_TIME_HIGH_DURATION_COMMAND="0.101"
declare -r -i TEST_TIME_BAD_TIMESTAMP=123
declare -r TEST_TIME_BAD_TYPE_TIMESTAMP="12s"
declare -r -i TEST_TIME_VALID_TIMESTAMP=1453512051
declare -r TEST_TIME_VALID_DATETIME="2016-01-23T02:20:51+0100"


readonly TEST_TIME_TIMESTAMP="-01"

function test_timestamp ()
{
    local test

    # Check
    test=$(timestamp)
    echo -n "-$?"
    [[ "$test" -gt 0 ]] && echo -n 1
}


readonly TEST_TIME_TIME_TODO="-11-11-011"

function test_timeTodo ()
{
    local test

    # Check nothing
    test=$(timeTodo)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check bad command
    test=$(timeTodo "${TEST_TIME_BAD_COMMAND}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check command
    test=$(timeTodo "${TEST_TIME_COMMAND}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "("*")" ]] && echo -n 1
    declare -A TIMER="$test"
    [[ -n "${TIMER[user]}" && -n "${TIMER[sys]}" && -n "${TIMER[real]}" ]] && echo -n 1

}


readonly TEST_TIME_USER_TIME_TODO="-11-11-01"

function test_userTimeTodo ()
{
    # Check nothing
    test=$(userTimeTodo)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check bad command
    test=$(userTimeTodo "${TEST_TIME_BAD_COMMAND}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check command
    test=$(userTimeTodo "${TEST_TIME_COMMAND}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "0."* ]] && echo -n 1
}


readonly TEST_TIME_USER_TIME_TODO_EXCEEDED="-11-11-11-11-01"

function test_isUserTimeTodoExceeded ()
{
    local test

    # Check nothing
    test=$(isUserTimeTodoExceeded)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with one argument missing
    test=$(isUserTimeTodoExceeded "$TEST_TIME_COMMAND")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with duration exceeding the command's duration
    test=$(isUserTimeTodoExceeded "$TEST_TIME_COMMAND" "$TEST_TIME_HIGH_DURATION_COMMAND")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with medium duration
    test=$(isUserTimeTodoExceeded "$TEST_TIME_COMMAND" "$TEST_TIME_MEDIUM_DURATION_COMMAND")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with low duration
    test=$(isUserTimeTodoExceeded "$TEST_TIME_COMMAND" "$TEST_TIME_LOW_DURATION_COMMAND")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_TIME_UTC_DATE_TIME_FROM_TIMESTAMP="-11-11-01-01"

function test_utcDateTimeFromTimestamp ()
{
    local test

    # Check nothing
    test=$(utcDateTimeFromTimestamp)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check invalid timestamp
    test=$(utcDateTimeFromTimestamp "${TEST_TIME_BAD_TYPE_TIMESTAMP}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check bad timestamp
    test=$(utcDateTimeFromTimestamp "${TEST_TIME_BAD_TIMESTAMP}")
    echo -n "-$?"
    [[ "$test" == "1970"* ]] && echo -n 1

     # Check valid timestamp
    test=$(utcDateTimeFromTimestamp "${TEST_TIME_VALID_TIMESTAMP}")
    echo -n "-$?"
    [[ "$test" == "$TEST_TIME_VALID_DATETIME" ]] && echo -n 1
}


readonly TEST_TIME_TIMESTAMP_FROM_UTC_DATE_TIME="-11-11-01"

function test_timestampFromUtcDateTime ()
{
    local test

    # Check nothing
    test=$(timestampFromUtcDateTime)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check invalid datetime
    test=$(timestampFromUtcDateTime "${TEST_TIME_COMMAND}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

     # Check valid timestamp
    test=$(timestampFromUtcDateTime "${TEST_TIME_VALID_DATETIME}")
    echo -n "-$?"
    [[ "$test" == "$TEST_TIME_VALID_TIMESTAMP" ]] && echo -n 1
}

# Launch all functional tests
bashUnit "timestamp" "${TEST_TIME_TIMESTAMP}" "$(test_timestamp)"
bashUnit "timeTodo" "${TEST_TIME_TIME_TODO}" "$(test_timeTodo)"
bashUnit "userTimeTodo" "${TEST_TIME_USER_TIME_TODO}" "$(test_userTimeTodo)"
bashUnit "isUserTimeTodoExceeded" "${TEST_TIME_USER_TIME_TODO_EXCEEDED}" "$(test_isUserTimeTodoExceeded)"
bashUnit "utcDateTimeFromTimestamp" "${TEST_TIME_UTC_DATE_TIME_FROM_TIMESTAMP}" "$(test_utcDateTimeFromTimestamp)"
bashUnit "timestampFromUtcDateTime" "${TEST_TIME_TIMESTAMP_FROM_UTC_DATE_TIME}" "$(test_timestampFromUtcDateTime)"