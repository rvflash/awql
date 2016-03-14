#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../term.sh

declare -r TEST_TERM_PROGRESS_BAR_NAME="Upload"
declare -r TEST_TERM_PROGRESS_BAR_0="$(echo -e "\rUpload [--------------------] 0%")"
declare -r TEST_TERM_PROGRESS_BAR_50="$(echo -e "\rUpload [++++++++++----------] 50%")"
declare -r TEST_TERM_PROGRESS_BAR_100="$(echo -e "\rUpload [++++++++++++++++++++] 100%")"
declare -r TEST_TERM_PROGRESS_ON_ERROR="$(echo -e " ${BP_ASCII_COLOR_RED}${BP_TERM_ERROR}${BP_ASCII_COLOR_OFF}")"


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


readonly TEST_TERM_PROGRESS_BAR="-11-01-01-01-01-01-11"

function test_progressBar ()
{
    local test

    # Check nothing
    test=$(progressBar)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with only a job name
    test=$(progressBar "${TEST_TERM_PROGRESS_BAR_NAME}")
    echo -n "-$?"
    [[ "$test" == "${TEST_TERM_PROGRESS_BAR_0}" ]] && echo -n 1

    # Check with a job name and a starting step
    test=$(progressBar "${TEST_TERM_PROGRESS_BAR_NAME}" 50)
    echo -n "-$?"
    [[ "$test" == "${TEST_TERM_PROGRESS_BAR_50}" ]] && echo -n 1

    # Check with starting job
    test=$(progressBar "${TEST_TERM_PROGRESS_BAR_NAME}" 0 100)
    echo -n "-$?"
    [[ "$test" == "${TEST_TERM_PROGRESS_BAR_0}" ]] && echo -n 1

    # Check with job at 50%
    test=$(progressBar "${TEST_TERM_PROGRESS_BAR_NAME}" 50 100)
    echo -n "-$?"
    [[ "$test" == "${TEST_TERM_PROGRESS_BAR_50}" ]] && echo -n 1

    # Check with ending job
    test=$(progressBar "${TEST_TERM_PROGRESS_BAR_NAME}" 100 100)
    echo -n "-$?"
    [[ "$test" == "${TEST_TERM_PROGRESS_BAR_100}" ]] && echo -n 1

    # Check with negative max data (error)
    test=$(progressBar "${TEST_TERM_PROGRESS_BAR_NAME}" 70 -1)
    echo -n "-$?"
    [[ "$test" == "${TEST_TERM_PROGRESS_ON_ERROR}" ]] && echo -n 1
}


readonly TEST_TERM_WINDOW_SIZE="-011-01-01-011"

function test_windowSize ()
{
   local test

    # Check
    test=$(windowSize)
    echo -n "-$?"
    [[ -n "$test" ]] && echo -n 1
    declare -a SIZE="${test}"
    [[ "${#SIZE[@]}" -eq 2 && "${SIZE[0]}" -gt 0  && "${SIZE[1]}" -gt 0 ]] && echo -n 1

    # Check only width
    test=$(windowSize "width")
    echo -n "-$?"
    [[ "$test" -gt 0 ]] && echo -n 1

    # Check only height
    test=$(windowSize "height")
    echo -n "-$?"
    [[ "$test" -gt 0 ]] && echo -n 1

    # Check only anything
    test=$(windowSize "any")
    echo -n "-$?"
    [[ -n "$test" ]] && echo -n 1
    declare -a SIZE="${test}"
    [[ "${#SIZE[@]}" -eq 2 && "${SIZE[0]}" -gt 0  && "${SIZE[1]}" -gt 0 ]] && echo -n 1
}


# Launch all functional tests
bashUnit "confirm" "${TEST_TERM_CONFIRM}" "$(test_confirm)"
bashUnit "dialog" "${TEST_TERM_DIALOG}" "$(test_dialog)"
bashUnit "progressBar" "${TEST_TERM_PROGRESS_BAR}" "$(test_progressBar)"
bashUnit "windowSize" "${TEST_TERM_WINDOW_SIZE}" "$(test_windowSize)"