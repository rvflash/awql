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
declare -r TEST_AUTH_TOKEN_FILE="${TEST_AUTH_TEST_DIR}/google-token.json"
declare -r TEST_AUTH_ACCESS_TOKEN="ya29..ugLW0TRYr9EvBLAWm-9VXCCxTxqRMRKiCqj_9fzUYKdcLC4CvAaJEPS2GPu8s9AYRUKIrbY"
declare -r TEST_AUTH_DEPRECATED_TOKEN="([ACCESS_TOKEN]=\"${TEST_AUTH_ACCESS_TOKEN}\" [EXPIRE_AT]=\"2016-04-04T23:27:58+02:00\" [TOKEN_TYPE]=\"Bearer\" )"
declare -r TEST_AUTH_VALID_TOKEN="([ACCESS_TOKEN]=\"${TEST_AUTH_ACCESS_TOKEN}\" [EXPIRE_AT]=\"2066-04-04T23:27:58+02:00\" [TOKEN_TYPE]=\"Bearer\" )"
declare -r TEST_AUTH_JSON_TO_TRIMED=" {\"access_token\": \"${TEST_AUTH_ACCESS_TOKEN}\",\"expire_in\": 3600,\"token_type\": \"Bearer\"} "
declare -r TEST_AUTH_JSON_KNOWN_INDEX="access_token"
declare -r TEST_AUTH_JSON_UNKNOWN_INDEX="expire_at"

readonly TEST_AUTH_JSON_TOKEN_PARSER="-01-01-01-01-01"

function test_extractDataFromJson ()
{
    local test

    #1 Check nothing
    test=$(__extractDataFromJson)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with empty Json
    test=$(__extractDataFromJson "${TEST_AUTH_JSON_KNOWN_INDEX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with unknown index in json
    test=$(__extractDataFromJson "${TEST_AUTH_JSON_UNKNOWN_INDEX}" "${TEST_AUTH_JSON_TO_TRIMED}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with both valid parameters
    test=$(__extractDataFromJson "${TEST_AUTH_JSON_KNOWN_INDEX}" "${TEST_AUTH_JSON_TO_TRIMED}")
    echo -n "-$?"
    [[ -n "$test"  && "$test" == "${TEST_AUTH_ACCESS_TOKEN}"  ]] && echo -n 1

    #5 Check with Google token file
    test=$(__extractDataFromJson "${TEST_AUTH_JSON_KNOWN_INDEX}" "$(cat "${TEST_AUTH_TOKEN_FILE}")")
    echo -n "-$?"
    [[ -n "$test"  && "$test" == "${TEST_AUTH_ACCESS_TOKEN}"  ]] && echo -n 1
}


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
bashUnit "__extractDataFromJson" "${TEST_AUTH_JSON_TOKEN_PARSER}" "$(test_extractDataFromJson)"
bashUnit "tokenFromFile" "${TEST_AUTH_TOKEN_FROM_FILE}" "$(test_tokenFromFile)"