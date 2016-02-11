#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../term.sh


readonly TEST_TERM_CONFIRM="-1"

function test_confirm ()
{
    echo "-1"
}


readonly TEST_TERM_DIALOG="-1"

function test_dialog ()
{
    echo "-1"
}


readonly TEST_TERM_WINDOW_SIZE="-011-01-01-011"

function test_windowSize ()
{
   local TEST

    # Check
    TEST=$(windowSize)
    echo -n "-$?"
    [[ -n "$TEST" ]] && echo -n 1
    declare -a SIZE="${TEST}"
    [[ "${#SIZE[@]}" -eq 2 && "${SIZE[0]}" -gt 0  && "${SIZE[1]}" -gt 0 ]] && echo -n 1

    # Check only width
    TEST=$(windowSize "width")
    echo -n "-$?"
    [[ "$TEST" -gt 0 ]] && echo -n 1

    # Check only height
    TEST=$(windowSize "height")
    echo -n "-$?"
    [[ "$TEST" -gt 0 ]] && echo -n 1

    # Check only anything
    TEST=$(windowSize "any")
    echo -n "-$?"
    [[ -n "$TEST" ]] && echo -n 1
    declare -a SIZE="${TEST}"
    [[ "${#SIZE[@]}" -eq 2 && "${SIZE[0]}" -gt 0  && "${SIZE[1]}" -gt 0 ]] && echo -n 1
}


# Launch all functional tests
bashUnit "confirm" "${TEST_TERM_CONFIRM}" "$(test_confirm)"
bashUnit "dialog" "${TEST_TERM_DIALOG}" "$(test_dialog)"
bashUnit "windowSize" "${TEST_TERM_WINDOW_SIZE}" "$(test_windowSize)"