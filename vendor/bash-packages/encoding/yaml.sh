#!/usr/bin/env bash

##
# Decodes a YAML string
# @return arrayToString
function yamlDecode ()
{
    local YAML="$1"
    if [[ -z "$YAML" || "$YAML" != *" : "* ]]; then
        echo -n "()"
        return 1
    fi

    # Remove comment lines, empty lines and format line to build associative array for bash (protect CSV output)
    YAML=$(echo -n "${YAML}" | sed -e "/^#/d" -e "/^$/d" -e "s/\"/'/g" -e "s/,/;/g" -e "s/=//g" -e "s/\ :[^:\/\/]/=\"/g" -e "s/$/\"/g" -e "s/ *=/]=/g" -e "s/^/[/g")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo -n "(${YAML})"
}

##
# Convert a Yaml file into readable string for array convertion
# @example '([K1]="V1" [K2]="V2")'
# @param string $1 Yaml file path to parse
# @return arrayToString
function yamlFileDecode ()
{
    local FILE_PATH="$1"
    if [[ -n "${FILE_PATH}" && -f "${FILE_PATH}" ]]; then
        local YAML
        YAML=$(yamlDecode "$(cat "${FILE_PATH}")")
        if [[ $? -eq 0 ]]; then
            echo -n "${YAML}"
            return
        fi
    fi

    return 1
}