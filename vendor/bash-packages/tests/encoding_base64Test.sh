#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../encoding/base64.sh

# Default entries
declare -r TEST_ENCODING_STR="{\"i\":1, \"n\":\"name\"}"
declare -r TEST_ENCODING_ENCODED_STR="eyJpIjoxLCAibiI6Im5hbWUifQo="


readonly TEST_ENCODING_BASE64_DECODE="-11-01"

function test_base64Decode ()
{
    local TEST

    # Check nothing
    TEST=$(base64Decode)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check
    TEST=$(base64Decode "${TEST_ENCODING_ENCODED_STR}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ENCODING_STR}" ]] && echo -n 1
}


readonly TEST_ENCODING_BASE64_ENCODE="-11-01"

function test_base64Encode ()
{
    local TEST

    # Check nothing
    TEST=$(base64Encode)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check
    TEST=$(base64Encode "${TEST_ENCODING_STR}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_ENCODING_ENCODED_STR}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "base64Decode" "${TEST_ENCODING_BASE64_DECODE}" "$(test_base64Decode)"
bashUnit "base64Encode" "${TEST_ENCODING_BASE64_ENCODE}" "$(test_base64Encode)"
