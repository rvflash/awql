#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../vendor/bash-packages/testing.sh
source ../conf/awql.sh

# Default entries
declare -r TEST_CONF_API_VERSION="v201601"
declare -r TEST_CONF_BAD_API_VERSION="v0883"
declare -r TEST_CONF_TABLE="CRITERIA_PERFORMANCE_REPORT"
declare -r TEST_CONF_BAD_TABLE="RV_REPORT"
declare -r TEST_CONF_TEST_DIR="${PWD}/unit"
declare -r TEST_CONF_AWQL_FIELDS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-fields.txt"
declare -r TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-uncompatible-fields.txt"
declare -r TEST_CONF_AWQL_KEYS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-keys.txt"
declare -r TEST_CONF_AWQL_TABLES_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-tables.txt"
declare -r TEST_CONF_AWQL_TABLES_TYPE_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-tables-type.txt"
declare -r TEST_CONF_AWQL_BLACKLISTED_FIELDS_FILE="${TEST_CONF_TEST_DIR}/${TEST_CONF_API_VERSION}-uncompatiblefields.txt"
declare -r TEST_CONF_AWQL_VIEWS_FILE="${TEST_CONF_TEST_DIR}/fields.txt"


readonly TEST_CONF_AWQL_FIELDS="-11-11-01"

function test_awqlFields ()
{
    local test

    #1 Check nothing
    test=$(awqlFields)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlFields "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

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
    [[ -z "$test" ]] && echo -n 1

    #2 Check with only table name
    test=$(awqlUncompatibleFields "${TEST_CONF_TABLE}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid table name and invalid api version
    test=$(awqlUncompatibleFields "${TEST_CONF_TABLE}" "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #4 Check with invalid table name and valid api version
    test=$(awqlUncompatibleFields "${TEST_CONF_BAD_TABLE}" "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

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
    [[ -z "$test" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlKeys "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlKeys "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_KEYS_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_KEYS_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_TABLES="-11-11-01"

function test_awqlTables ()
{
    local test

    #1 Check nothing
    test=$(awqlTables)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlTables "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

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
    [[ -z "$test" ]] && echo -n 1

    #2 Check with invalid api version
    test=$(awqlTablesType "${TEST_CONF_BAD_API_VERSION}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    #3 Check with valid api version
    test=$(awqlTablesType "${TEST_CONF_API_VERSION}")
    echo -n "-$?"
    [[ -n "$test" && -f "${TEST_CONF_AWQL_TABLES_TYPE_FILE}" && -z "$(diff -b "${TEST_CONF_AWQL_TABLES_TYPE_FILE}" <(echo "$test"))" ]] && echo -n 1
}


readonly TEST_CONF_AWQL_VIEWS="-0"

function test_awqlViews ()
{
    local test

    #1 Check nothing
    test=$(awqlViews)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "awqlFields" "${TEST_CONF_AWQL_FIELDS}" "$(test_awqlFields)"
bashUnit "awqlUncompatibleFields" "${TEST_CONF_AWQL_UNCOMPATIBLE_FIELDS}" "$(test_awqlUncompatibleFields)"
bashUnit "awqlKeys" "${TEST_CONF_AWQL_KEYS}" "$(test_awqlKeys)"
bashUnit "awqlTables" "${TEST_CONF_AWQL_TABLES}" "$(test_awqlTables)"
bashUnit "awqlTablesType" "${TEST_CONF_AWQL_TABLES_TYPE}" "$(test_awqlTablesType)"
bashUnit "awqlViews" "${TEST_CONF_AWQL_VIEWS}" "$(test_awqlViews)"