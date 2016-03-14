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
declare -r TEST_ENCODING_YAML_TMP_FILE_PATH="/tmp/bp.yaml"
declare -r TEST_ENCODING_YAML_STRING="$(cat "${TEST_ENCODING_YAML_FILE_PATH}")"
declare -r TEST_ENCODING_YAML_ARRAY="([ONE]=\"First value\" [TWO]=\"Second\" [THREE]=\"Third element\" [FOUR]=\"Fourth\")"


readonly TEST_ENCODING_YAML_YAML_DECODE="-11-11-011"

function test_yamlDecode ()
{
    local test

    # Check nothing
    test=$(yamlDecode)
    echo -n "-$?"
    [[ "${test}" == "()" ]] && echo -n 1

    # Check invalid yaml (without at less " : ")
    test=$(yamlDecode "empty")
    echo -n "-$?"
    [[ "${test}" == "()" ]] && echo -n 1

    # Check yaml
    test=$(yamlDecode "$TEST_ENCODING_YAML_STRING")
    echo -n "-$?"
    [[ -n "${test}" ]] && echo -n 1
    declare -A YAML="${test}"
    [[ "First value" == "${YAML[ONE]}" && "Second" == "${YAML[TWO]}" && "Third element" == "${YAML[THREE]}" && "Fourth" == "${YAML[FOUR]}" ]] && echo -n 1
}


readonly TEST_ENCODING_YAML_YAML_ENCODE="-11-11-01-01"

function test_yamlEncode ()
{
    local test
    declare -A TEST_ARRAY="${TEST_ENCODING_YAML_ARRAY}"

    # Check nothing
    test=$(yamlEncode)
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check empty array
    test=$(yamlEncode "()")
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check invalid yaml array
    test=$(yamlEncode "empty")
    echo -n "-$?"
    [[ "${test}" == "0 : empty" ]] && echo -n 1

    # Check yaml
    test=$(yamlEncode "${TEST_ENCODING_YAML_ARRAY}")
    echo -n "-$?"
    [[ -n "${test}" && $(wc -l <<< "${test}") -eq "${#TEST_ARRAY[@]}" ]] && echo -n 1
}


readonly TEST_ENCODING_YAML_YAML_FILE_DECODE="-11-11-011"

function test_yamlFileDecode ()
{
    local test

    # Check nothing
    test=$(yamlFileDecode)
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check unexitant file path
    test=$(yamlFileDecode "${TEST_ENCODING_YAML_BAD_FILE_PATH}")
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check valid yaml file path
    test=$(yamlFileDecode "${TEST_ENCODING_YAML_FILE_PATH}")
    echo -n "-$?"
    [[ -n "${test}" ]] && echo -n 1
    declare -A YAML="${test}"
    [[ "First value" == "${YAML[ONE]}" && "Second" == "${YAML[TWO]}" && "Third element" == "${YAML[THREE]}" && "Fourth" == "${YAML[FOUR]}" ]] && echo -n 1
}


readonly TEST_ENCODING_YAML_YAML_FILE_ENCODE="-11-11-11-11-11-01"

function test_yamlFileEncode ()
{
    local test
    declare -A TEST_ARRAY="${TEST_ENCODING_YAML_ARRAY}"

    # Check nothing
    test=$(yamlFileEncode)
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check with just arrayToString
    test=$(yamlFileEncode "${TEST_ENCODING_YAML_ARRAY}")
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check with valid arrayToString and invalid path
    test=$(yamlFileEncode "${TEST_ENCODING_YAML_ARRAY}" "${PWD}")
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check with empty value and valid path
    test=$(yamlFileEncode "" "${TEST_ENCODING_YAML_TMP_FILE_PATH}")
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check with empty array and valid path
    test=$(yamlFileEncode "()" "${TEST_ENCODING_YAML_TMP_FILE_PATH}")
    echo -n "-$?"
    [[ -z "${test}" ]] && echo -n 1

    # Check with valid arrayToString and valid path
    if [[ -f "${TEST_ENCODING_YAML_TMP_FILE_PATH}" ]]; then
        rm -f "${TEST_ENCODING_YAML_TMP_FILE_PATH}"
    fi
    test=$(yamlFileEncode "${TEST_ENCODING_YAML_ARRAY}" "${TEST_ENCODING_YAML_TMP_FILE_PATH}")
    echo -n "-$?"
    [[ -z "${test}" && $(wc -l < "${TEST_ENCODING_YAML_TMP_FILE_PATH}") -eq "${#TEST_ARRAY[@]}" ]] && echo -n 1

    # Clean workspace
    if [[ -f "${TEST_ENCODING_YAML_TMP_FILE_PATH}" ]]; then
        rm -f "${TEST_ENCODING_YAML_TMP_FILE_PATH}"
    fi
}


# Launch all functional tests
bashUnit "yamlDecode" "${TEST_ENCODING_YAML_YAML_DECODE}" "$(test_yamlDecode)"
bashUnit "yamlEncode" "${TEST_ENCODING_YAML_YAML_ENCODE}" "$(test_yamlEncode)"
bashUnit "yamlFileDecode" "${TEST_ENCODING_YAML_YAML_FILE_DECODE}" "$(test_yamlFileDecode)"
bashUnit "yamlFileEncode" "${TEST_ENCODING_YAML_YAML_FILE_ENCODE}" "$(test_yamlFileEncode)"
