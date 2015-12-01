#!/usr/bin/env bash

# Constants
declare -r TMP_DIR='/tmp/'
declare -r CURDATE=`date +%Y%m%d%H%M%S`
declare -r AUTH_FILE_NAME="auth.yaml"
declare -r REQUEST_FILE_NAME="request.yaml"

##
# Resolve $1 or current path until the file is no longer a symlink
# @param string $1 path
# @return string DIRECTORY_PATH
function getDirectoryPath ()
{
    local SOURCE="$1"
    while [ -h "$SOURCE" ]; do
      local DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
      SOURCE="$(readlink "$SOURCE")"
      # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
      [[ ${SOURCE} != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

    if [ "$DIR" = "" ]; then
        exit 1;
    fi
    DIRECTORY_PATH="$DIR/"
}

##
# Exit in error case, if $1 is not equals to 0
# @param string $1 return code of previous step
# @param string $2 message to log
# @param string $3 verbose mode
# @param string $4 filepath for logs
function exitOnError ()
{
    local ERR_CODE="$1"
    local ERR_MSG="$2"
    local ERR_LOG="$3"
    local ERR_FILE="$4"

    if [ "$ERR_CODE" != "0" ]; then
        if [ "$ERR_MSG" != "" ] && [ "$ERR_FILE" != "" ]; then
            echo "$ERR_MSG" >> ${ERR_FILE}
        fi
        if [ "$ERR_LOG" != "" ]; then
            if [ -z "$ERR_FILE" ]; then
                echo "$ERR_MSG"
            else
                cat ${ERR_FILE} | while  read ERR_LINE; do
                    echo "$ERR_LINE"
                done
            fi
        fi
        exit 1;
    fi
}

##
# Convert a Yaml file into readable string for array convertion
# @example '([K1]="V1" [K2]="V2")'
# @param string $1 ymal file path to parse
# @return string YAML_TO_ARRAY
function yamlToArray ()
{
    if [ "$1" != "" ] && [ -f "$1" ]; then
        YAML_TO_ARRAY=$(sed -e '/^$/d' -e 's/:[^:\/\/]/="/g' -e 's/$/"/g' -e 's/ *=/]=/g' -e 's/^/[/g' ${1})
        YAML_TO_ARRAY="($YAML_TO_ARRAY)"
    else
        return 1
    fi
}