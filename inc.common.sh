#!/usr/bin/env bash

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