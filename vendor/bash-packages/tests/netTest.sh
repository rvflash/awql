#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../net.sh

# Default entries
declare -r TEST_NET_LOCAL_HTTP="http://localhost"
declare -r TEST_NET_HTTPS="https://test.hgouchet.lan:8961/google-token"
declare -r TEST_NET_FTP="ftp://user:password@ftp.hgouchet.lan:21/token"
declare -r TEST_NET_HTTP="http://login:password@example.com/dir/file.ext?a=sth&b=std"
declare -r TEST_NET_BAD="http:/"


readonly TEST_NET_PARSE_URL="-11-011-011-011-011-11"

function test_parseUrl ()
{
    local test

    # Check nothing
    test=$(parseUrl)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check local http url
    test=$(parseUrl "${TEST_NET_LOCAL_HTTP}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "("*")" ]] && echo -n 1
    declare -A URL="$test"
    [[ "http" == "${URL[SCHEME]}" && "localhost" == "${URL[HOST]}" && "/" == "${URL[PATH]}" ]] && echo -n 1

    # Check https url
    test=$(parseUrl "${TEST_NET_HTTPS}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "("*")" ]] && echo -n 1
    declare -A URL="$test"
    [[ "https" == "${URL[SCHEME]}" && "test.hgouchet.lan" == "${URL[HOST]}" && "8961" == "${URL[PORT]}" && "/google-token" == "${URL[PATH]}" ]] && echo -n 1

    # Check ftp url
    test=$(parseUrl "${TEST_NET_FTP}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "("*")" ]] && echo -n 1
    declare -A URL="$test"
    [[ "ftp" == "${URL[SCHEME]}" && "user" == "${URL[USER]}" && "password" == "${URL[PASS]}" && "ftp.hgouchet.lan" == "${URL[HOST]}" && "21" == "${URL[PORT]}" && "/token" == "${URL[PATH]}" ]] && echo -n 1

    # Check http url
    test=$(parseUrl "${TEST_NET_HTTP}")
    echo -n "-$?"
    [[ -n "$test" && "$test" == "("*")" ]] && echo -n 1
    declare -A URL="$test"
    [[ "http" == "${URL[SCHEME]}" && "login" == "${URL[USER]}" && "password" == "${URL[PASS]}" && "example.com" == "${URL[HOST]}" && "/dir/file.ext" == "${URL[PATH]}" && "a=sth&b=std" == "${URL[QUERY]}" ]] && echo -n 1

    # Check bad url
    test=$(parseUrl "${TEST_NET_BAD}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "parseUrl" "${TEST_NET_PARSE_URL}" "$(test_parseUrl)"