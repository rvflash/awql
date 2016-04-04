#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/auth/token.sh

# Default entries
declare -r TEST_AUTH_TEST_DIR="${PWD}/unit"
declare -r TEST_AUTH_UNKNOWN_FILE="${TEST_AUTH_TEST_DIR}/rv.json"
declare -r TEST_AUTH_INVALID_FILE="${TEST_AUTH_TEST_DIR}/invalid-token.json"
declare -r TEST_AUTH_DEPRECATED_FILE="${TEST_AUTH_TEST_DIR}/deprecated-token.json"
declare -r TEST_AUTH_FILE="${TEST_AUTH_TEST_DIR}/token.json"
declare -r TEST_AUTH_DEPRECATED_TOKEN='([ACCESS_TOKEN]="ya29..ugIZG3oY2eZtIOsg2WA1ToAEjH1EV_huFU379tjHjUMo29fqynCwSyrQa6nQE0F_HFtvRx4" [TOKEN_TYPE]="Bearer" [EXPIRE_AT]="2016-04-04T13:53:58+02:00")'
declare -r TEST_AUTH_VALID_TOKEN='([ACCESS_TOKEN]="ya29..ugIZG3oY2eZtIOsg2WA1ToAEjH1EV_huFU379tjHjUMo29fqynCwSyrQa6nQE0F_HFtvRx4" [TOKEN_TYPE]="Bearer" [EXPIRE_AT]="2066-04-04T13:53:58+02:00")'


readonly TEST_AUTH_TOKEN_FROM_FILE="-11-11-21-01-01"

function test_tokenFromFile ()
{
    local test

    #1 Check nothing
    test=$(tokenFromFile)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with unknown file path
    test=$(tokenFromFile "${TEST_AUTH_UNKNOWN_FILE}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with invalid format
    test=$(tokenFromFile "${TEST_AUTH_INVALID_FILE}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #5 Check with valid format but deprecated token
    test=$(tokenFromFile "${TEST_AUTH_DEPRECATED_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_DEPRECATED_TOKEN}"  ]] && echo -n 1

    #6 Check with valid token
    test=$(tokenFromFile "${TEST_AUTH_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_VALID_TOKEN}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "tokenFromFile" "${TEST_AUTH_TOKEN_FROM_FILE}" "$(test_tokenFromFile)"