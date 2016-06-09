#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package testing
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Constant
declare -r BP_TESTING_PACKAGE_NAME="Package"
declare -r BP_TESTING_UNIT_FILE_SUFFIX="Test.sh"

# Load ascii file if is not already loaded
if [[ -z "${BP_ASCII_COLOR_OFF}" ]]; then
    declare -r BP_TESTING_FILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${BP_TESTING_FILE_DIR}/encoding/ascii.sh"
fi

##
# Basic function to test A with B and validate the behavior of a method
# @codeCoverageIgnore
# @param string $1 Method's name
# @param string $2 Expected string
# @param string $3 Received string to compare with expected string
# @exit 1 If one of the three parameters are empty
function bashUnit ()
{
    local method="$1"
    local expected="$2"
    local received="$3"

    if [[ -z "$method" || -z "$expected" || -z "$received" ]]; then
        echo -i "${BP_ASCII_COLOR_RED}Missing values for BashUnit testing tool${BP_ASCII_COLOR_OFF}"
        exit 1
    fi

    echo -ne "${BP_ASCII_COLOR_GRAY}Function${BP_ASCII_COLOR_OFF} ${method}: "

    if [[ "$received" == "$expected" ]]; then
        echo -ne "${BP_ASCII_COLOR_GREEN}OK${BP_ASCII_COLOR_OFF}\n"
    else
        echo -ne "${BP_ASCII_COLOR_YELLOW}KO${BP_ASCII_COLOR_OFF}\n"
        echo -ne "    > ${BP_ASCII_COLOR_GREEN}Expected:${BP_ASCII_COLOR_OFF} ${BP_ASCII_COLOR_GREEN_BG}${expected}${BP_ASCII_COLOR_OFF}\n"
        echo -ne "    > ${BP_ASCII_COLOR_RED}Received:${BP_ASCII_COLOR_OFF} ${BP_ASCII_COLOR_RED_BG}${received}${BP_ASCII_COLOR_OFF}\n"
    fi
}

##
# Launch all bash file with suffix Test.sh in directory passed as first parameter
# @codeCoverageIgnore
# @param string TestsDir
# @return string
function launchAllTests ()
{
    local dir="$1"
    if [[ -z "$dir" || ! -d "$dir" ]]; then
        return 1
    fi

    local fileName bashFile
    declare -a bashFiles="($(find "${dir}" -iname "*${BP_TESTING_UNIT_FILE_SUFFIX}" -type f 2>> /dev/null))"

    # Integrety check
    echo -ne "Expecting ${#bashFiles[@]} tests\n"

    declare -i count
    for bashFile in "${bashFiles[@]}"; do
        count+=1
        fileName="$(basename "${bashFile}" "${BP_TESTING_UNIT_FILE_SUFFIX}")"
        echo -e "\n#${count} ${BP_TESTING_PACKAGE_NAME} ${BP_ASCII_COLOR_BLUE}${fileName/_/\/}${BP_ASCII_COLOR_OFF}"
        echo -e "$(${bashFile})"
    done
}