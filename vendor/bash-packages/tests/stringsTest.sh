#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../strings.sh

# Default entries
declare -r TEST_STRINGS_MASK="()"
declare -r -i TEST_STRINGS_CHK=3159589107
declare -r TEST_STRINGS_BOX_SIZE=60
declare -r TEST_STRINGS_WITH_LEADING_DOT_PAD="................... Text without leading or trailing spaces"
declare -r TEST_STRINGS_WITH_TRAILING_DOT_PAD="Text without leading or trailing spaces ..................."
declare -r TEST_STRINGS_WITHOUT_SPACES="Text without leading or trailing spaces"
declare -r TEST_STRINGS_WITH_LEADING_SPACES=" ${TEST_STRINGS_WITHOUT_SPACES}"
declare -r TEST_STRINGS_WITH_TRAILING_SPACES="${TEST_STRINGS_WITHOUT_SPACES} "
declare -r TEST_STRINGS_WITH_SPACES=" ${TEST_STRINGS_WITHOUT_SPACES} "
declare -r TEST_STRINGS_WITH_TABS_AND_SPACES="  ${TEST_STRINGS_WITHOUT_SPACES} "
declare -r TEST_STRINGS_WITH_SPACES_AND_MASK=" ( ${TEST_STRINGS_WITHOUT_SPACES} )"

readonly TEST_STRINGS_CHECKSUM="-11-01-01-01-01"

function test_checksum ()
{
    local test CONFIRM_TEST

    # Check nothing
    test=$(checksum)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check
    test=$(checksum "${TEST_STRINGS_WITHOUT_SPACES}")
    echo -n "-$?"
    [[ "$test" -gt 0 ]] && echo -n 1

    # Confirm previous check
    CONFIRM_TEST=$(checksum "${TEST_STRINGS_WITHOUT_SPACES}")
    echo -n "-$?"
    [[ "$test" == "$CONFIRM_TEST" && "$test" -eq ${TEST_STRINGS_CHK} ]] && echo -n 1

    # Check with leading spaces and expect no change
    test=$(checksum "${TEST_STRINGS_WITH_LEADING_SPACES}")
    echo -n "-$?"
    [[ "$test" == "$CONFIRM_TEST" && "$test" -eq ${TEST_STRINGS_CHK} ]] && echo -n 1

    # Check with an other text and expect new hash
    CONFIRM_TEST=$(checksum "${TEST_STRINGS_WITHOUT_SPACES:10}")
    echo -n "-$?"
    [[ "$CONFIRM_TEST" -gt 0 && "$test" != "$CONFIRM_TEST" && "$test" -eq ${TEST_STRINGS_CHK} ]] && echo -n 1
}

readonly TEST_STRINGS_EMPTY="-01-01-01-01-01-01-11"

function test_isEmpty ()
{
    local test

    # Check nothing
    test=$(isEmpty)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check isEmpty string
    test=$(isEmpty "")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check isEmpty array
    test=$(isEmpty "()")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check zero as int
    test=$(isEmpty "0")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check zero as float
    test=$(isEmpty "0.0")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check boolean
    test=$(isEmpty false)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check not nothing
    test=$(isEmpty true)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_STRINGS_PRINT_LEFT_PADDING="-01-01-01"

function test_printLeftPadding ()
{
    local test

    # Check nothing
    test=$(printLeftPadding)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with one leading space
    test=$(printLeftPadding "${TEST_STRINGS_WITHOUT_SPACES}" 1)
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITH_LEADING_SPACES" ]] && echo -n 1

    # Check with one leading dash
    test=$(printLeftPadding "${TEST_STRINGS_WITHOUT_SPACES}" 20 ".")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITH_LEADING_DOT_PAD" ]] && echo -n 1

}


readonly TEST_STRINGS_PRINT_RIGHT_PADDING="-01-01-01"

function test_printRightPadding ()
{
    local test

    # Check nothing
    test=$(printRightPadding)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with one trailing space
    test=$(printRightPadding "${TEST_STRINGS_WITHOUT_SPACES}" 1)
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITH_TRAILING_SPACES" ]] && echo -n 1

    # Check with one leading dash
    test=$(printRightPadding "${TEST_STRINGS_WITHOUT_SPACES}" 20 ".")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITH_TRAILING_DOT_PAD" ]] && echo -n 1
}


readonly TEST_STRINGS_TRIM="-01-01-01-01-01-01"

function test_trim ()
{
    local test

    # Check nothing
    test=$(trim)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with leading spaces
    test=$(trim "${TEST_STRINGS_WITH_LEADING_SPACES}")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITHOUT_SPACES" ]] && echo -n 1

    # Check with trailing spaces
    test=$(trim "${TEST_STRINGS_WITH_TRAILING_SPACES}")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITHOUT_SPACES" ]] && echo -n 1

    # Check with leading and trailing spaces
    test=$(trim "${TEST_STRINGS_WITH_SPACES}")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITHOUT_SPACES" ]] && echo -n 1

    # Check with leading and trailing spaces or tabs
    test=$(trim "${TEST_STRINGS_WITH_TABS_AND_SPACES}")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITHOUT_SPACES" ]] && echo -n 1

    # Check with leading and trailing spaces and masks
    test=$(trim "${TEST_STRINGS_WITH_SPACES_AND_MASK}" "${TEST_STRINGS_MASK}")
    echo -n "-$?"
    [[ "$test" == "$TEST_STRINGS_WITHOUT_SPACES" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "checksum" "${TEST_STRINGS_CHECKSUM}" "$(test_checksum)"
bashUnit "isEmpty" "${TEST_STRINGS_EMPTY}" "$(test_isEmpty)"
bashUnit "printLeftPadding" "${TEST_STRINGS_PRINT_LEFT_PADDING}" "$(test_printLeftPadding)"
bashUnit "printRightPadding" "${TEST_STRINGS_PRINT_RIGHT_PADDING}" "$(test_printRightPadding)"
bashUnit "trim" "${TEST_STRINGS_TRIM}" "$(test_trim)"