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


readonly TEST_IMPORT="-11-11-01-01"

function test_import ()
{
     local test

    # Check nothing
    import
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with valid path and fake path
    import "${TEST_FILE_PATH_02}" "${TEST_FILE_FAKE_PATH}"
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check with both, valid relative path and valid absolute path
    import "${TEST_FILE_PATH_01}" "${TEST_FILE_PATH_02}"
    echo -n "-$?"
    [[ "$(test02)" == "$TEST_FILE_RETURN_02" ]] && echo -n 1

    # Check with redundant valid relative path and valid absolute path
    import "${TEST_FILE_PATH_01}" "${TEST_FILE_PATH_02}" "${TEST_FILE_PATH_02}"
    echo -n "-$?"
    [[ "$(test02)" == "$TEST_FILE_RETURN_02" ]] && echo -n 1
}


readonly TEST_INCLUDE="-11-01-01-11"

function test_include ()
{
     local test

    # Check nothing
    test=$(include)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check real path
    include "${TEST_FILE_PATH_01}"
    echo -n "-$?"
    [[ "$(test01)" == "$TEST_FILE_RETURN_01" ]] && echo -n 1

    # Check same real path
    include "${TEST_FILE_PATH_01}"
    echo -n "-$?"
    [[ "$(test01)" == "$TEST_FILE_RETURN_01" && "${BP_INCLUDE_FILE["$TEST_FILE_PATH_01"]}" -eq 2 ]] && echo -n 1

    # Check fake path
    test=$(include "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_INCLUDE_ONCE="-11-01-01-11"

function test_includeOnce ()
{
     local test

    # Check nothing
    test=$(includeOnce)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check relative path (absolute path was tested with include method)
    includeOnce "${TEST_FILE_PATH_02}"
    echo -n "-$?"
    [[ "$(test02)" == "$TEST_FILE_RETURN_02" ]] && echo -n 1

    # Check same real path
    includeOnce "${TEST_FILE_PATH_02}"
    echo -n "-$?"
    [[ "$(test02)" == "$TEST_FILE_RETURN_02" ]] && echo -n 1

    # Check fake path
    test=$(includeOnce "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1
}


readonly TEST_PHYSICAL_DIRNAME="-01-01-11-01"

function test_physicalDirname ()
{
    local test

    # Check nothing
    test=$(physicalDirname)
    echo -n "-$?"
    [[ "$test" == "$PWD" ]] && echo -n 1

    # Check real path
    test=$(physicalDirname "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_USER_HOME" ]] && echo -n 1

    # Check fake path
    test=$(physicalDirname "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check relative path
    test=$(physicalDirname "${TEST_FILE_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_BP_HOME" ]] && echo -n 1
}


readonly TEST_REALPATH="-11-01-11-01-01-01"

function test_realpath ()
{
    local test

    # Check nothing
    test=$(realpath)
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check real path
    test=$(realpath "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_USER_HOME" ]] && echo -n 1

    # Check fake path
    test=$(realpath "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check backward relative path
    test=$(realpath "${TEST_FILE_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$test" == "${TEST_FILE_BP_HOME}/${TEST_FILE_RELATIVE_PATH:3}" ]] && echo -n 1

    # Check relative path
    test=$(realpath "${TEST_FILE_CURRENT_FILE}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_CURRENT_FILEPATH" ]] && echo -n 1

    # Check home relative path
    test=$(realpath "${TEST_FILE_HOME_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$test" == "${TEST_FILE_USER_HOME}/${TEST_FILE_HOME_RELATIVE_PATH:2}" ]] && echo -n 1
}


readonly TEST_RESOLVE_PATH="-01-01-01-01-01-01-01"

function test_resolvePath ()
{
    local test

    # Check nothing
    test=$(resolvePath)
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_CURRENT_FILEPATH" ]] && echo -n 1

    # Check real path
    test=$(resolvePath "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_USER_HOME" ]] && echo -n 1

    # Check fake path
    test=$(resolvePath "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_FAKE_PATH" ]] && echo -n 1

    # Check backward relative path
    test=$(resolvePath "${TEST_FILE_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$test" == "${PWD}/${TEST_FILE_RELATIVE_PATH}" ]] && echo -n 1

    # Check relative path
    test=$(resolvePath "${TEST_FILE_CURRENT_FILE}")
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_CURRENT_FILEPATH" ]] && echo -n 1

    # Check home relative path
    test=$(resolvePath "${TEST_FILE_HOME_RELATIVE_PATH}")
    echo -n "-$?"
    [[ "$test" == "${TEST_FILE_USER_HOME}/${TEST_FILE_HOME_RELATIVE_PATH:2}" ]] && echo -n 1

    # Check relative path with sub folder
    test=$(resolvePath "${TEST_FILE_PATH_02}")
    echo -n "-$?"
    [[ "$test" == "${PWD}/${TEST_FILE_PATH_02}" ]] && echo -n 1
}


readonly TEST_SCAN_DIRECTORY="-01-01-11-01"

function test_scanDirectory ()
{
    local test

    # Check nothing
    test=$(scanDirectory)
    echo -n "-$?"
    [[ "$test" == "unit" ]] && echo -n 1

    # Check real path
    test=$(scanDirectory "${TEST_FILE_USER_HOME}")
    echo -n "-$?"
    [[ -n "$test" ]] && echo -n 1

    # Check fake path
    test=$(scanDirectory "${TEST_FILE_FAKE_PATH}")
    echo -n "-$?"
    [[ -z "$test" ]] && echo -n 1

    # Check relative path
    test=$(scanDirectory "../")
    echo -n "-$?"
    [[ -n "$test" ]] && echo -n 1
}


readonly TEST_USER_HOME="-01"

function test_userHome ()
{
    local test

    test=$(userHome)
    echo -n "-$?"
    [[ "$test" == "$TEST_FILE_USER_HOME" ]] && echo -n 1
}


# Launch all functional tests
bashUnit "import" "${TEST_IMPORT}" "$(test_import)"
bashUnit "include" "${TEST_INCLUDE}" "$(test_include)"
bashUnit "includeOnce" "${TEST_INCLUDE_ONCE}" "$(test_includeOnce)"
bashUnit "physicalDirname" "${TEST_PHYSICAL_DIRNAME}" "$(test_physicalDirname)"
bashUnit "realpath" "${TEST_REALPATH}" "$(test_realpath)"
bashUnit "resolvePath" "${TEST_RESOLVE_PATH}" "$(test_resolvePath)"
bashUnit "scanDirectory" "${TEST_SCAN_DIRECTORY}" "$(test_scanDirectory)"
bashUnit "userHome" "${TEST_USER_HOME}" "$(test_userHome)"