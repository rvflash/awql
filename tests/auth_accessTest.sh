#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../core/auth/access.sh

# Default entries
declare -A -r TEST_AUTH_CONF="$(yamlFileDecode "${AWQL_AUTH_FILE}")"
declare -r TEST_AUTH_TEST_DIR="${PWD}/unit"
declare -r TEST_AUTH_INVALID_URL="http:/invalid-token.json"
declare -r TEST_AUTH_ERROR_URL="http://www.google.com/error"
declare -r TEST_AUTH_TEST_FILE="/tmp/token.json"
declare -r TEST_AUTH_UNKNOWN_FILE="${TEST_AUTH_TEST_DIR}/rv.json"
declare -r TEST_AUTH_INVALID_FILE="${TEST_AUTH_TEST_DIR}/invalid-token.json"
declare -r TEST_AUTH_DEPRECATED_FILE="${TEST_AUTH_TEST_DIR}/deprecated-token.json"
declare -r TEST_AUTH_TOKEN_FILE="${TEST_AUTH_TEST_DIR}/token.json"
declare -r TEST_AUTH_DEPRECATED_TOKEN='([ACCESS_TOKEN]="ya29..ugLW0TRYr9EvBLAWm-9VXCCxTxqRMRKiCqj_9fzUYKdcLC4CvAaJEPS2GPu8s9AYRUKIrbY" [EXPIRE_AT]="2016-04-04T23:27:58+02:00" [TOKEN_TYPE]="Bearer" )'
declare -r TEST_AUTH_VALID_TOKEN='([ACCESS_TOKEN]="ya29..ugLW0TRYr9EvBLAWm-9VXCCxTxqRMRKiCqj_9fzUYKdcLC4CvAaJEPS2GPu8s9AYRUKIrbY" [EXPIRE_AT]="2066-04-04T23:27:58+02:00" [TOKEN_TYPE]="Bearer" )'
declare -r TEST_AUTH_INVALID_FILE_TOKEN='([ERROR]="AuthenticationError.INVALID_FILE" )'
declare -r TEST_AUTH_INVALID_URL_TOKEN='([ERROR]="AuthenticationError.INVALID_URL" )'
declare -r TEST_AUTH_INVALID_CLIENT_TOKEN='([ERROR]="AuthenticationError.INVALID_CLIENT" )'
declare -r TEST_AUTH_FAIL_AUTH_TOKEN='([ERROR]="AuthenticationError.FAIL" )'
declare -r TEST_AUTH_INVALID_CLIENT_ID="1234567890-rv.apps.googleusercontent.com"
declare -r TEST_AUTH_INVALID_REFRESH_TOKEN="4/Q4f1Gazd6çzdfwZ8E-ddad5zV-Rvt"


readonly TEST_AUTH_CUSTOM_REFRESH="-1-11-11-11-21-01"

function test_customRefresh ()
{
    local test url

    #0 Check auth config
    [[ -n "${TEST_AUTH_CONF["${AWQL_AUTH_PROTOCOL}"]}" && -n "${TEST_AUTH_CONF["${AWQL_AUTH_HOSTNAME}"]}" && \
       -n "${TEST_AUTH_CONF["${AWQL_AUTH_PORT}"]}" && -n "${TEST_AUTH_CONF["${AWQL_AUTH_PATH}"]}" ]] && echo -n "-1"

    url="${TEST_AUTH_CONF["${AWQL_AUTH_PROTOCOL}"]}://${TEST_AUTH_CONF["${AWQL_AUTH_HOSTNAME}"]}"
    url+=":${TEST_AUTH_CONF["${AWQL_AUTH_PORT}"]}${TEST_AUTH_CONF["${AWQL_AUTH_PATH}"]}"

    #0 Cleans workspace
    rm -f "${TEST_AUTH_TEST_FILE}"

    #1 Check nothing
    test=$(__customRefresh)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #2 Check without file path
    test=$(__customRefresh "$url")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #3 Check with bad url file path
    test=$(__customRefresh "${TEST_AUTH_INVALID_URL}" "${TEST_AUTH_TEST_FILE}")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #4 Check with url in error and valid file path
    test=$(__customRefresh "${TEST_AUTH_ERROR_URL}" "${TEST_AUTH_TEST_FILE}")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #5 Check with both valid parameters
    test=$(__customRefresh "$url" "${TEST_AUTH_TEST_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1
}


readonly TEST_AUTH_GOOGLE_REFRESH="-1-11-11-11-11-21-31-01"

function test_googleRefresh ()
{
    local test

    declare -r clientId="${TEST_AUTH_CONF["${AWQL_AUTH_CLIENT_ID}"]}"
    declare -r clientSecret="${TEST_AUTH_CONF["${AWQL_AUTH_CLIENT_SECRET}"]}"
    declare -r refreshToken="${TEST_AUTH_CONF["${AWQL_REFRESH_TOKEN}"]}"

    #0 Check auth config
    [[ -n "$clientId" && -n "$clientSecret" && -n "$refreshToken" ]] && echo -n "-1"

    #0 Clean workspace
    rm -f "${TEST_AUTH_TEST_FILE}"

    #1 Check nothing
    test=$(__googleRefresh)
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #2 Check with only client ID
    test=$(__googleRefresh "$clientId")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #3 Check with only client ID & secret
    test=$(__googleRefresh "$clientId" "$clientSecret")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #4 Check without file path
    test=$(__googleRefresh "$clientId" "$clientSecret" "$refreshToken")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #5 Check with all valid parameters, except client id
    test=$(__googleRefresh "${TEST_AUTH_INVALID_CLIENT_ID}" "$clientSecret" "$refreshToken" "${TEST_AUTH_TEST_FILE}")
    echo -n "-$?"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #6 Check with all valid parameters, except refresh token
    test=$(__googleRefresh "$clientId" "$clientSecret" "${TEST_AUTH_INVALID_REFRESH_TOKEN}" "${TEST_AUTH_TEST_FILE}")
    echo -n "-$?$test"
    [[ -z "$test" && ! -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1

    #7 Check with all valid parameters
    test=$(__googleRefresh "$clientId" "$clientSecret" "$refreshToken" "${TEST_AUTH_TEST_FILE}")
    echo -n "-$?"
    [[ -z "$test" && -f "${TEST_AUTH_TEST_FILE}" ]] && echo -n 1
}


readonly TEST_AUTH_TOKEN="-11-11-11-01-01"

function test_token ()
{
    local test

    #1 Check nothing
    test=$(__token)
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_INVALID_FILE_TOKEN}" ]] && echo -n 1

    #2 Check with unknown file path
    test=$(__token "${TEST_AUTH_UNKNOWN_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_INVALID_FILE_TOKEN}" ]] && echo -n 1

    #3 Check with invalid format
    test=$(__token "${TEST_AUTH_INVALID_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_INVALID_FILE_TOKEN}" ]] && echo -n 1

    #5 Check with valid format but deprecated token
    test=$(__token "${TEST_AUTH_DEPRECATED_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_DEPRECATED_TOKEN}" ]] && echo -n 1

    #6 Check with valid token
    test=$(__token "${TEST_AUTH_TOKEN_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_VALID_TOKEN}" ]] && echo -n 1
}


readonly TEST_AUTH_TOKEN_CACHED="-11-11-11-11-01"

function test_tokenCached ()
{
    local test

    #1 Check nothing
    test=$(__tokenCached)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with unknown file path
    test=$(__tokenCached "${TEST_AUTH_UNKNOWN_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with invalid format
    test=$(__tokenCached "${TEST_AUTH_INVALID_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with valid format but deprecated token
    test=$(__tokenCached "${TEST_AUTH_DEPRECATED_FILE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with valid token
    test=$(__tokenCached "${TEST_AUTH_TOKEN_FILE}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_VALID_TOKEN}" ]] && echo -n 1
}


readonly TEST_AUTH_CUSTOM_TOKEN="-1-11-11-11-01-01"

function test_authCustomToken ()
{
    local test

    #0 Check auth config
    [[ -n "${TEST_AUTH_CONF["${AWQL_AUTH_PROTOCOL}"]}" && -n "${TEST_AUTH_CONF["${AWQL_AUTH_HOSTNAME}"]}" && \
       -n "${TEST_AUTH_CONF["${AWQL_AUTH_PORT}"]}" && -n "${TEST_AUTH_CONF["${AWQL_AUTH_PATH}"]}" ]] && echo -n "-1"

    url="${TEST_AUTH_CONF["${AWQL_AUTH_PROTOCOL}"]}://${TEST_AUTH_CONF["${AWQL_AUTH_HOSTNAME}"]}"
    url+=":${TEST_AUTH_CONF["${AWQL_AUTH_PORT}"]}${TEST_AUTH_CONF["${AWQL_AUTH_PATH}"]}"

    #0 Cleans workspace
    rm -f "${AWQL_WRK_DIR}/${AWQL_TOKEN_FILE_NAME}"

    #1 Check nothing
    test=$(authCustomToken)
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_INVALID_URL_TOKEN}" ]] && echo -n 1

    #2 Check with invalid format url
    test=$(authCustomToken "${TEST_AUTH_INVALID_URL}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_INVALID_URL_TOKEN}" ]] && echo -n 1

    #3 Check with url in error
    test=$(authCustomToken "${TEST_AUTH_ERROR_URL}")
    echo -n "-$?"
    [[ "$test" == "${TEST_AUTH_FAIL_AUTH_TOKEN}" ]] && echo -n 1

    #4 Check with url in error and valid file path
    test=$(authCustomToken "$url")
    echo -n "-$?"
    if [[ "$test" == "("*")" ]]; then
        declare -A testToken="$test"
        [[ "${#testToken[@]}" -eq 3 && -n "${testToken["ACCESS_TOKEN"]}" && "${testToken["EXPIRE_AT"]}" == *"T"* ]] && echo -n 1
    fi

    #5 Check again with url in error but with previous request in cache, no problem
    test=$(authCustomToken "${TEST_AUTH_ERROR_URL}")
    echo -n "-$?"
    if [[ "$test" == "("*")" ]]; then
        declare -A testToken="$test"
        [[ "${#testToken[@]}" -eq 3 && -n "${testToken["ACCESS_TOKEN"]}" && "${testToken["EXPIRE_AT"]}" == *"T"* ]] && echo -n 1
    fi
}


readonly TEST_AUTH_GOOGLE_TOKEN="-1-11-11-11-11-01-01"

function test_authGoogleToken ()
{
    local test

    declare -r clientId="${TEST_AUTH_CONF["${AWQL_AUTH_CLIENT_ID}"]}"
    declare -r clientSecret="${TEST_AUTH_CONF["${AWQL_AUTH_CLIENT_SECRET}"]}"
    declare -r refreshToken="${TEST_AUTH_CONF["${AWQL_REFRESH_TOKEN}"]}"

    #0 Check auth config
    [[ -n "$clientId" && -n "$clientSecret" && -n "$refreshToken" ]] && echo -n "-1"

    #0 Cleans workspace
    if [[ -n "${AWQL_WRK_DIR}" && -n "${AWQL_TOKEN_FILE_NAME}" ]]; then
        rm -f "${AWQL_WRK_DIR}/${AWQL_TOKEN_FILE_NAME}"
    fi

    #1 Check nothing
    test=$(authGoogleToken)
    echo -n "-$?"
    [[ "$test"  == "${TEST_AUTH_INVALID_CLIENT_TOKEN}" ]] && echo -n 1

    #2 Check with only client id
    test=$(authGoogleToken "$clientId")
    echo -n "-$?"
    [[ "$test"  == "${TEST_AUTH_INVALID_CLIENT_TOKEN}" ]] && echo -n 1

    #3 Check without refresh token
    test=$(authGoogleToken "$clientId" "$clientSecret")
    echo -n "-$?"
    [[ "$test"  == "${TEST_AUTH_INVALID_CLIENT_TOKEN}" ]] && echo -n 1

    #4 Check with invalid refresh token
    test=$(authGoogleToken "$clientId" "$clientSecret" "${TEST_AUTH_INVALID_REFRESH_TOKEN}")
    echo -n "-$?"
    [[ "$test"  == "${TEST_AUTH_FAIL_AUTH_TOKEN}" ]] && echo -n 1

    #5 Check with all valid parameters
    test=$(authGoogleToken "$clientId" "$clientSecret" "$refreshToken")
    echo -n "-$?"
    if [[ "$test" == "("*")" ]]; then
        declare -A testToken="$test"
        [[ "${#testToken[@]}" -eq 3 && "${testToken["ACCESS_TOKEN"]}" == "ya29."* && "${testToken["EXPIRE_AT"]}" == *"T"* ]] && echo -n 1
    fi

    #6 Check with invalid refresh token but with previous request in cache, no problem
    test=$(authGoogleToken "$clientId" "$clientSecret" "${TEST_AUTH_INVALID_REFRESH_TOKEN}")
    echo -n "-$?"
    if [[ "$test" == "("*")" ]]; then
        declare -A testToken="$test"
        [[ "${#testToken[@]}" -eq 3 && "${testToken["ACCESS_TOKEN"]}" == "ya29."* && "${testToken["EXPIRE_AT"]}" == *"T"* ]] && echo -n 1
    fi
}


# Launch all functional tests
bashUnit "__customRefresh" "${TEST_AUTH_CUSTOM_REFRESH}" "$(test_customRefresh)"
bashUnit "__googleRefresh" "${TEST_AUTH_GOOGLE_REFRESH}" "$(test_googleRefresh)"
bashUnit "__token" "${TEST_AUTH_TOKEN}" "$(test_token)"
bashUnit "__tokenCached" "${TEST_AUTH_TOKEN_CACHED}" "$(test_tokenCached)"
bashUnit "authCustomToken" "${TEST_AUTH_CUSTOM_TOKEN}" "$(test_authCustomToken)"
bashUnit "authGoogleToken" "${TEST_AUTH_GOOGLE_TOKEN}" "$(test_authGoogleToken)"