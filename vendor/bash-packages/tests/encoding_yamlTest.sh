#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../encoding/yaml.sh

# ONE         : First value
# TWO         : Second
# THREE       : Third element
# FOUR        : Fourth

# Default entries
declare -r TEST_ENCODING_YAML_FILE_PATH="${PWD}/unit/yaml01.yaml"
declare -r TEST_ENCODING_YAML_BAD_FILE_PATH="${PWD}/unit/yaml02.yaml"
declare -r TEST_ENCODING_YAML_STRING="$(cat "${TEST_ENCODING_YAML_FILE_PATH}")"


readonly TEST_ENCODING_YAML_YAML_DECODE="-11-11-011"

function test_yamlDecode ()
{
    local TEST

    # Check nothing
    TEST=$(yamlDecode)
    echo -n "-$?"
    [[ "${TEST}" == "()" ]] && echo -n 1

    # Check invalid yaml (without at less " : ")
    TEST=$(yamlDecode "empty")
    echo -n "-$?"
    [[ "${TEST}" == "()" ]] && echo -n 1

    # Check yaml
    TEST=$(yamlDecode "$TEST_ENCODING_YAML_STRING")
    echo -n "-$?"
    [[ -n "${TEST}" ]] && echo -n 1
    declare -A YAML="${TEST}"
    [[ "First value" == "${YAML[ONE]}" && "Second" == "${YAML[TWO]}" && "Third element" == "${YAML[THREE]}" && "Fourth" == "${YAML[FOUR]}" ]] && echo -n 1
}


readonly TEST_ENCODING_YAML_YAML_FILE_DECODE="-11-11-011"

function test_yamlFileDecode ()
{
    local TEST

    # Check nothing
    TEST=$(yamlFileDecode)
    echo -n "-$?"
    [[ -z "${TEST}" ]] && echo -n 1

    # Check unexitant file path
    TEST=$(yamlFileDecode "${TEST_ENCODING_YAML_BAD_FILE_PATH}")
    echo -n "-$?"
    [[ -z "${TEST}" ]] && echo -n 1

    # Check valid yaml file path
    TEST=$(yamlFileDecode "${TEST_ENCODING_YAML_FILE_PATH}")
    echo -n "-$?"
    [[ -n "${TEST}" ]] && echo -n 1
    declare -A YAML="${TEST}"
    [[ "First value" == "${YAML[ONE]}" && "Second" == "${YAML[TWO]}" && "Third element" == "${YAML[THREE]}" && "Fourth" == "${YAML[FOUR]}" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "yamlDecode" "${TEST_ENCODING_YAML_YAML_DECODE}" "$(test_yamlDecode)"
bashUnit "yamlFileDecode" "${TEST_ENCODING_YAML_YAML_FILE_DECODE}" "$(test_yamlFileDecode)"
