#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace
source ../testing.sh
source ../file.sh

# Default entries
declare -r TEST_FILE_USER_HOME="/Users/hgouchet"
declare -r TEST_FILE_BP_HOME="$(dirname "$PWD")"
declare -r TEST_FILE_CURRENT_FILE="$(basename "$0")"
declare -r TEST_FILE_CURRENT_FILEPATH="${PWD}/${TEST_FILE_CURRENT_FILE}"
declare -r TEST_FILE_FAKE_PATH="/Rv/hgouchet"
declare -r TEST_FILE_RELATIVE_PATH="../README.md"
declare -r TEST_FILE_HOME_RELATIVE_PATH="~/.bash_history"
declare -r TEST_FILE_PATH_01="${PWD}/unit/test01.sh"
declare -r TEST_FILE_RETURN_01="test01"
declare -r TEST_FILE_PATH_02="unit/test02.sh"
declare -r TEST_FILE_RETURN_02="test02"

readonly TEST_INCLUDE="-11-01-01-11"

function test_include ()
{
     local TEST

    # Check nothing
    TEST=$(include)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check real path
    include "${TEST_FILE_PATH_01}"
    echo -n "-$?"
    [[ "$(test01)" == "$TEST_FILE_RETURN_01" ]] && echo -n 1

    # Check same real path
    include "${TEST_FILE_PATH_01}"
    echo -n "-$?"
    [[ "$(test01)" == "$TEST_FILE_RETURN_01" && "${BP_INCLUDE_FILE["$TEST_FILE_PATH_01"]}" -eq 2 ]] && echo -n 1

    # Check fake path
    TEST=$(include "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "$BP_FILE_NOT_EXISTS" ]] && echo -n 1
}


readonly TEST_INCLUDE_ONCE="-11-01-01-11"

function test_includeOnce ()
{
     local TEST

    # Check nothing
    TEST=$(includeOnce)
    echo -n "-$?"
    [[ "$TEST" == "$BP_FILE_NOT_EXISTS" ]] && echo -n 1

    # Check relative path (absolute path was tested with include method)
    includeOnce "${TEST_FILE_PATH_02}"
    echo -n "-$?"
    [[ "$(test02)" == "$TEST_FILE_RETURN_02" ]] && echo -n 1

    # Check same real path
    includeOnce "${TEST_FILE_PATH_02}"
    echo -n "-$?"
    [[ "$(test02)" == "$TEST_FILE_RETURN_02" ]] && echo -n 1

    # Check fake path
    TEST=$(includeOnce "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "$BP_FILE_NOT_EXISTS" ]] && echo -n 1
}


readonly TEST_REALPATH="-11-01-11-01-01-01"

function test_realpath ()
{
    local TEST

    # Check nothing
    TEST=$(realpath)
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check real path
    TEST=$(realpath "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_USER_HOME" ]] && echo -n 1

    # Check fake path
    TEST=$(realpath "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check backward relative path
    TEST=$(realpath "${TEST_FILE_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_FILE_BP_HOME}/${TEST_FILE_RELATIVE_PATH:3}" ]] && echo -n 1

    # Check relative path
    TEST=$(realpath "${TEST_FILE_CURRENT_FILE}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_CURRENT_FILEPATH" ]] && echo -n 1

    # Check home relative path
    TEST=$(realpath "${TEST_FILE_HOME_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_FILE_USER_HOME}/${TEST_FILE_HOME_RELATIVE_PATH:2}" ]] && echo -n 1
}


readonly TEST_RESOLVE_PATH="-01-01-01-01-01-01-01"

function test_resolvePath ()
{
    local TEST

    # Check nothing
    TEST=$(resolvePath)
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_CURRENT_FILEPATH" ]] && echo -n 1

    # Check real path
    TEST=$(resolvePath "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_USER_HOME" ]] && echo -n 1

    # Check fake path
    TEST=$(resolvePath "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_FAKE_PATH" ]] && echo -n 1

    # Check backward relative path
    TEST=$(resolvePath "${TEST_FILE_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "${PWD}/${TEST_FILE_RELATIVE_PATH}" ]] && echo -n 1

    # Check relative path
    TEST=$(resolvePath "${TEST_FILE_CURRENT_FILE}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_CURRENT_FILEPATH" ]] && echo -n 1

    # Check home relative path
    TEST=$(resolvePath "${TEST_FILE_HOME_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "${TEST_FILE_USER_HOME}/${TEST_FILE_HOME_RELATIVE_PATH:2}" ]] && echo -n 1

    # Check relative path with sub folder
    TEST=$(resolvePath "${TEST_FILE_PATH_02}")
    echo -n "-$?"
    [[ "$TEST" == "${PWD}/${TEST_FILE_PATH_02}" ]] && echo -n 1
}


readonly TEST_PHYSICAL_DIRNAME="-01-01-11-01"

function test_physicalDirname ()
{
    local TEST

    # Check nothing
    TEST=$(physicalDirname)
    echo -n "-$?"
    [[ "$TEST" == "$PWD" ]] && echo -n 1

    # Check real path
    TEST=$(physicalDirname "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_USER_HOME" ]] && echo -n 1

    # Check fake path
    TEST=$(physicalDirname "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$TEST" ]] && echo -n 1

    # Check relative path
    TEST=$(physicalDirname "${TEST_FILE_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_BP_HOME" ]] && echo -n 1
}


readonly TEST_USER_HOME="-01"

function test_userHome ()
{
    local TEST

    TEST=$(userHome)
    echo -n "-$?"
    [[ "$TEST" == "$TEST_FILE_USER_HOME" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "include" "${TEST_INCLUDE}" "$(test_include)"
bashUnit "includeOnce" "${TEST_INCLUDE_ONCE}" "$(test_includeOnce)"
bashUnit "realpath" "${TEST_REALPATH}" "$(test_realpath)"
bashUnit "resolvePath" "${TEST_RESOLVE_PATH}" "$(test_resolvePath)"
bashUnit "physicalDirname" "${TEST_PHYSICAL_DIRNAME}" "$(test_physicalDirname)"
bashUnit "userHome" "${TEST_USER_HOME}" "$(test_userHome)"