#!/usr/bin/env bash
set -o errexit -o pipefail -o errtrace

declare -r BP_UNIT_PACKAGE_NAME="Package"
declare -r BP_UNIT_TEST_FILE_SUFFIX="Test.sh"

function launchAllTests ()
{
    declare -a BASH_FILES="($(find "${PWD}" -iname "*${BP_UNIT_TEST_FILE_SUFFIX}" -type f 2>> /dev/null))"
    declare -i TEST
    local FILE_NAME

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

launchAllTests