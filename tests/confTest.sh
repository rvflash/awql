#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../conf/awql.sh

# Default entries
declare -r TEST_CONF_API_VERSION="v201605"
declare -r TEST_CONF_BAD_API_VERSION="v0883"
declare -r TEST_CONF_TABLE="CAMPAIGN_PERFORMANCE_REPORT"
declare -r TEST_CONF_VIEW="CAMPAIGN_REPORT"
declare -r TEST_CONF_BAD_TABLE="RV_REPORT"
declare -r TEST_CONF_TEST_DIR="${PWD}/unit"
declare -r TEST_CONF_AWQL_FIELDS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-fields.txt"
declare -r TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-uncompatible-fields.txt"
declare -r TEST_CONF_AWQL_KEYS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-keys.txt"
declare -r TEST_CONF_AWQL_PRIMARY_KEYS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-primary-keys.txt"
declare -r TEST_CONF_AWQL_TABLES_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-tables.txt"
declare -r TEST_CONF_AWQL_TABLES_TYPE_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-tables-type.txt"
declare -r TEST_CONF_AWQL_VIEWS_FILE="${TEST_CONF_TEST_DIR}/fields.txt"
declare -r TEST_CONF_AWQL_QUERY_SELECT="SELECT"
declare -r TEST_CONF_AWQL_QUERY_CREATE="create"
declare -r TEST_CONF_AWQL_QUERY_REPLACE="Replace"
declare -r TEST_CONF_AWQL_QUERY_VIEW="view"
declare -r TEST_CONF_AWQL_QUERY_AS="AS"
declare -r TEST_CONF_AWQL_QUERY_DESC="desc"
declare -r TEST_CONF_AWQL_QUERY_SHOW="SHOW"
declare -r TEST_CONF_AWQL_QUERY_FULL="fuLl"
declare -r TEST_CONF_AWQL_QUERY_TABLES="Tables"
declare -r TEST_CONF_AWQL_QUERY_LIKE="LIKE"
declare -r TEST_CONF_AWQL_QUERY_WITH="with"
declare -r TEST_CONF_AWQL_QUERY_FROM="FROM"
declare -r TEST_CONF_AWQL_QUERY_WHERE="WHERE"
declare -r TEST_CONF_AWQL_QUERY_DURING="during"
declare -r TEST_CONF_AWQL_QUERY_ORDER="ORDER"
declare -r TEST_CONF_AWQL_QUERY_BY="by"
declare -r TEST_CONF_AWQL_QUERY_LIMIT="LIMIT"
declare -r TEST_CONF_AWQL_QUERY_OR="OR"
declare -r TEST_CONF_AWQL_QUERY_AND="and"
declare -r TEST_CONF_AWQL_QUERY_CLEAR="Clear"
declare -r TEST_CONF_AWQL_QUERY_EXIT="EXIT"
declare -r TEST_CONF_AWQL_QUERY_QUIT="QUIT"
declare -r TEST_CONF_AWQL_QUERY_HELP="help"
declare -r TEST_CONF_AWQL_FUNCTION_COUNT="COUNT"
declare -r TEST_CONF_AWQL_FUNCTION_SUM="sum"
declare -r TEST_CONF_AWQL_FUNCTION_MIN="MIN"
declare -r TEST_CONF_AWQL_FUNCTION_MAX="max"
declare -r TEST_CONF_AWQL_FUNCTION_DISTINCT="DISTINCT"


readonly TEST_CONF_AWQL_FIELDS="-11-11-01"

function test_awqlFields ()
{
    local test

    #1 Check nothing
    test=$(awqlFields)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlFields "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlFields "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_FIELDS_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_FIELDS_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS="-11-11-11-11-01"

function test_awqlUncompatibleFields ()
{
    local test

    #1 Check nothing
    test=$(awqlUncompatibleFields)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with only table name
    test=$(awqlUncompatibleFields "${TEST_CONF_TABLE}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with valid table name and invalid api version
    test=$(awqlUncompatibleFields "${TEST_CONF_TABLE}" "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #4 Check with invalid table name and valid api version
    test=$(awqlUncompatibleFields "${TEST_CONF_BAD_TABLE}" "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #5 Check with valid table name and api version
    test=$(awqlUncompatibleFields "${TEST_CONF_TABLE}" "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_KEYS="-11-11-01"

function test_awqlKeys ()
{
    local test

    #1 Check nothing
    test=$(awqlKeys)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlKeys "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlKeys "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_KEYS_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_KEYS_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_PRIMARY_KEYS="-11-11-01"

function test_awqlPrimaryKeys ()
{
    local test

    #1 Check nothing
    test=$(awqlPrimaryKeys)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlPrimaryKeys "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlPrimaryKeys "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_PRIMARY_KEYS_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_PRIMARY_KEYS_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_TABLES="-11-11-01"

function test_awqlTables ()
{
    local test

    #1 Check nothing
    test=$(awqlTables)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlTables "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlTables "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_TABLES_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_TABLES_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_TABLES_TYPE="-11-11-01"

function test_awqlTablesType ()
{
    local test

    #1 Check nothing
    test=$(awqlTablesType)
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlTablesType "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ "$test" == "()" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlTablesType "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_TABLES_TYPE_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_TABLES_TYPE_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_VIEWS="-011"

function test_awqlViews ()
{
    local test

    #1 Check nothing
    test=$(awqlViews)
    echo -n "-$?"
    declare -A testViews="$test"
    [[ -n "$test" && -n "${testViews["${TEST_CONF_VIEW}"]}" ]] && echo -n 1
    declare -A testView="${testViews["${TEST_CONF_VIEW}"]}"
    [[ "${#testView[@]}" -eq 7 && "${testView["${AWQL_REQUEST_TABLE}"]}" == "${TEST_CONF_TABLE}" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_CLEAR_CACHE_VIEWS="-001"

function test_awqlClearCacheViews ()
{
    local test testFile

    #1 Check nothing
    testFile="${AWQL_USER_CACHE_VIEWS_FILE}"
    [[  -n "$testFile" && "$testFile" == *".cache" ]] && echo -n "-0"

    #1 Init workspace
    echo "()" > "$testFile"
    echo -n "$?"

    #2 Clear cache
    test=$(awqlClearCacheViews)
    [[  -z "$test" && ! -f "$testFile" ]] && echo -n "1"
}


readonly TEST_CONF_AWQL_RESERVED_WORD="-11-11-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01-01"

function test_awqlReservedWord ()
{
    local test

    #1 Check nothing
    test=$(awqlReservedWord)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with lambda keyword
    test=$(awqlReservedWord "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with select keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_SELECT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with create keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_CREATE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with replace keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_REPLACE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with view keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_VIEW}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #7 Check with as keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_AS}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #8 Check with desc keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_DESC}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #9 Check with show keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_SHOW}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #10 Check with full keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_FULL}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #11 Check with tables keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_TABLES}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #12 Check with like keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_LIKE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #13 Check with with keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_WITH}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #14 Check with from keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_FROM}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #15 Check with where keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_WHERE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #16 Check with during keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_DURING}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #17 Check with order keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_ORDER}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #18 Check with bye keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_BY}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #19 Check with limit keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_LIMIT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #20 Check with or keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_OR}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #21 Check with and keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_AND}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #22 Check with clear keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_CLEAR}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #23 Check with exit keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_EXIT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #24 Check with quit keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_QUIT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #25 Check with help keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_QUERY_HELP}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #26 Check with count keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_COUNT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #27 Check with sum keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_SUM}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #28 Check with min keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_MIN}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #29 Check with max keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_MAX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #30 Check with distinct keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_DISTINCT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_FUNCTION="-11-11-01-01-01-01-01"

function test_awqlFunction ()
{
    local test

    #1 Check nothing
    test=$(awqlReservedWord)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with lambda keyword
    test=$(awqlReservedWord "rv")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with count keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_COUNT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with sum keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_SUM}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #5 Check with min keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_MIN}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #6 Check with max keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_MAX}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #7 Check with distinct keyword
    test=$(awqlReservedWord "${TEST_CONF_AWQL_FUNCTION_DISTINCT}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}

# Launch all functional tests
bashUnit "awqlFields" "${TEST_CONF_AWQL_FIELDS}" "$(test_awqlFields)"
bashUnit "awqlUncompatibleFields" "${TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS}" "$(test_awqlUncompatibleFields)"
bashUnit "awqlKeys" "${TEST_CONF_AWQL_KEYS}" "$(test_awqlKeys)"
bashUnit "awqlPrimaryKeys" "${TEST_CONF_AWQL_PRIMARY_KEYS}" "$(test_awqlPrimaryKeys)"
bashUnit "awqlTables" "${TEST_CONF_AWQL_TABLES}" "$(test_awqlTables)"
bashUnit "awqlTablesType" "${TEST_CONF_AWQL_TABLES_TYPE}" "$(test_awqlTablesType)"
bashUnit "awqlViews" "${TEST_CONF_AWQL_VIEWS}" "$(test_awqlViews)"
bashUnit "awqlClearCacheViews" "${TEST_CONF_AWQL_CLEAR_CACHE_VIEWS}" "$(test_awqlClearCacheViews)"
bashUnit "awqlReservedWord" "${TEST_CONF_AWQL_RESERVED_WORD}" "$(test_awqlReservedWord)"
bashUnit "awqlFunction" "${TEST_CONF_AWQL_FUNCTION}" "$(test_awqlFunction)"