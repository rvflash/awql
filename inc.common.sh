#!/usr/bin/env bash

# Constants
declare -r WRK_DIR="/tmp/awql/$(date +%Y%m%d)/"
declare -r API_DOC_DIR="adwords"
declare -r API_DOC_EXTRA_FILE_NAME="extra.yaml"
declare -r API_DOC_FIELDS_FILE_NAME="fields.yaml"
declare -r API_DOC_KEYS_FILE_NAME="keys.yaml"
declare -r API_DOC_TABLES_FILE_NAME="tables.yaml"
declare -r AUTH_FILE_NAME="auth.yaml"
declare -r REQUEST_FILE_NAME="request.yaml"
declare -r AWQL_FILE_EXT=".awql"
declare -r AWQL_HTTP_RESPONSE_EXT=".rsp"
declare -r ERR_FILE_EXT=".err"

declare -r AWQL_SORT_ORDER_ASC=0
declare -r AWQL_SORT_ORDER_DESC=1
declare -r AWQL_SORT_NUMERICS="Double Long Money Integer Byte int"

# MacOs portability, does not support case-insensitive matching
declare -r AWQL_QUERY_SHOW="[Ss][Hh][Oo][Ww] "
declare -r AWQL_QUERY_SHOW_FULL="[Ff][Uu][Ll][Ll] "
declare -r AWQL_QUERY_TABLES="[Tt][Aa][Bb][Ll][Ee][Ss]"
declare -r AWQL_QUERY_LIKE="[Ll][Ii][Kk][Ee]"
declare -r AWQL_QUERY_WITH="[Ww][Ii][Tt][Hh]"
declare -r AWQL_QUERY_DESC="[Dd][Ee][Ss][Cc] "
declare -r AWQL_QUERY_SELECT="[Ss][Ee][Ll][Ee][Cc][Tt] "
declare -r AWQL_QUERY_FROM=" [Ff][Rr][Oo][Mm] "
declare -r AWQL_QUERY_WHERE=" [Ww][Hh][Ee][Rr][Ee] "
declare -r AWQL_QUERY_DURING=" [Dd][Uu][Rr][Ii][Nn][Gg] "
declare -r AWQL_QUERY_ORDER_BY=" [Oo][Rr][Dd][Ee][Rr] [Bb][Yy] "
declare -r AWQL_QUERY_LIMIT=" [Ll][Ii][Mm][Ii][Tt] "

declare -r AWQL_TABLE_FIELD_NAME="Field"
declare -r AWQL_TABLE_FIELD_TYPE="Type"
declare -r AWQL_TABLE_FIELD_KEY="Key"
declare -r AWQL_TABLE_FIELD_EXTRA="Extra"
declare -r AWQL_FIELD_IS_KEY="MUL"
declare -r AWQL_TABLES_IN="Tables_in_"

##
# Check if a value is available in array
# @param string $1 Needle
# @param stringableArray $2 Haystack
# @return int O if found, 1 otherwise
function inArray ()
{
    local NEEDLE="$1"
    local HAYSTACK="$2"

    if [ -z "$NEEDLE" ] || [ -z "$HAYSTACK" ]; then
        return 1
    fi

    for VALUE in ${HAYSTACK[@]}; do
        if [[ ${VALUE} == ${NEEDLE} ]]; then
            return 0
        fi
    done

    return 1
}

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
# @param string $1 Yaml file path to parse
# @return string YAML_TO_ARRAY
function yamlToArray ()
{
    if [ "$1" != "" ] && [ -f "$1" ]; then
        # Remove comment lines, empty lines and format line to build associative array for bash (protect CSV output)
        YAML_TO_ARRAY=$(sed -e "/^#/d" \
                            -e "/^$/d" \
                            -e "s/\"/'/g" \
                            -e "s/,/;/g" \
                            -e "s/=//g" \
                            -e 's/\ :[^:\/\/]/="/g' \
                            -e 's/$/"/g' \
                            -e "s/ *=/]=/g" \
                            -e "s/^/[/g" "$1")
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