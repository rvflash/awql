#!/usr/bin/env bash

declare -r BP_UNIT_PACKAGE_NAME="Package"
declare -r BP_UNIT_TEST_FILE_SUFFIX="Test.sh"

##
# Basic function to test A with B and validate the behavior of a method
# @codeCoverageIgnore
# @param string $1 Method's name
# @param string $2 Expected string
# @param string $3 Received string to compare with expected string
# @exit 1 If one the three parameters are empty
function bashUnit ()
{
    local METHOD="$1"
    local EXPECTED="$2"
    local RECEIVED="$3"

    if [[ -z "$METHOD" || -z "$EXPECTED" || -z "$RECEIVED" ]]; then
        echo "Missing values for BashUnit testing tool"
        exit 1
    fi

    if [[ "${RECEIVED}" == "${EXPECTED}" ]]; then
        echo "Function ${METHOD}: OK"
    else
        echo "Function ${METHOD}: KO (Expected ${EXPECTED}, received ${RECEIVED})"
    fi
}

##
# Lauch all bash file with suffix Test.sh in directory passed as first parameter
# @codeCoverageIgnore
# @param string TestsDir
# @return string
function launchAllTests ()
{
    local TESTS_DIR="$1"
    if [[ -z "$TESTS_DIR" || ! -d "$TESTS_DIR" ]]; then
        return 1
    fi

    local FILE_NAME
    declare -i TEST
    declare -a BASH_FILES="($(find "${TESTS_DIR}" -iname "*${BP_UNIT_TEST_FILE_SUFFIX}" -type f 2>> /dev/null))"
    for BASH_FILE in ${BASH_FILES[@]}; do
        if [[ ${TEST} -gt 0 ]]; then
            echo
        fi
        TEST+=1

        FILE_NAME="$(basename "${BASH_FILE}" "${BP_UNIT_TEST_FILE_SUFFIX}")"
        echo "${BP_UNIT_PACKAGE_NAME} ${FILE_NAME/_/\/}"
        echo -e "$(${BASH_FILE})"
    done
}