#!/usr/bin/env bash

# Constants
declare -r WRK_DIR="/tmp/awql/$(date +%Y%m%d)/"
declare -r AUTH_FILE_NAME="auth.yaml"
declare -r REQUEST_FILE_NAME="request.yaml"
declare -r AWQL_FILE_EXT=".awql"
declare -r ERR_FILE_EXT=".err"

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
function exitOnError ()
{
    local ERR_CODE="$1"
    local ERR_MSG="$2"
    local ERR_LOG="$3"

    if [ "$ERR_CODE" -ne 0 ]; then
        if [ "$ERR_LOG" != "" ]; then
            echo "$ERR_MSG"
        fi
        if [ "$ERR_CODE" -eq 1 ]; then
            exit 1;
        fi
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
        YAML_TO_ARRAY=$(sed -e "/^$/d" -e 's/:[^:\/\/]/="/g' -e 's/$/"/g' -e "s/ *=/]=/g" -e "s/^/[/g" ${1})
        YAML_TO_ARRAY="($YAML_TO_ARRAY)"
    else
        return 1
    fi
}

##
# Calculate a checksum on a string
# @param string $1
# @return string CHECKSUM
function checksum ()
{
    local CHECKSUM_FILE="${WRK_DIR}${RANDOM}.crc"
    echo -n "$1" > "$CHECKSUM_FILE"

    CHECKSUM=$(cksum "$CHECKSUM_FILE" | awk '{print $1}')

    # Clean workspace
    rm -f "$CHECKSUM_FILE"
}