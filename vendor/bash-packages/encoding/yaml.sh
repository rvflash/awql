#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package encoding/yaml
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

##
# Decodes a Yaml string
# @example
#     K1    : Value 1
#     K2    : V2
#
#     > '([K1]="Value 1" [K2]="V2")'
#
# @param string $1 Str Yaml string to parse
# @return arrayToString
# @returnStatus 1 If first parameter named str is empty or invalid
function yamlDecode ()
{
    local str="$1"
    if [[ -z "$str" || "$str" != *" : "* ]]; then
        echo -n "()"
        return 1
    fi

    # Remove comment lines, empty lines and format line to build associative array for bash
    str=$(echo "$str" | sed -e "/^#/d" -e "/^$/d" -e "s/\"/'/g" -e "s/=//g" -e "s/\ :[^:\/\/]/=\"/g" -e "s/$/\"/g" -e "s/ *=/]=/g" -e "s/^/[/g")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo -n "(${str})"
}

##
# Encodes a bash associative array as Yaml string
# @example '([K1]="Value 1" [K2]="V2")'
# @param arrayToString $1 Associative array
# @return string
# @returnStatus 1 If first parameter named str is empty
function yamlEncode ()
{
    local str="$1"
    if [[ -z "$str" || "()" == "$str" ]]; then
        return 1
    fi
    declare -A yaml="$str"

    # Get left column padding
    local key
    declare -i pad=0
    for key in "${!yaml[@]}"; do
        if [[ ${pad} -lt "${#key}" ]]; then
            pad="${#key}"
        fi
    done

    # Print associative array as Yaml string
    for key in "${!yaml[@]}"; do
        echo $(printf "%-${pad}s" "$key"; echo -n " : ${yaml[$key]}")
    done
}

##
# Convert a Yaml file into readable string for array convertion
# @example '([K1]="V1" [K2]="V2")'
# @param string $1 Yaml file path to parse
# @return arrayToString
# @returnStatus 1 If first parameter named filePath is empty or unexisting
# @returnStatus 1 If Yaml file is invalid
function yamlFileDecode ()
{
    local filePath="$1"
    if [[ -n "$filePath" && -f "$filePath" ]]; then
        local yaml
        yaml=$(yamlDecode "$(cat "$filePath")")
        if [[ $? -eq 0 ]]; then
            echo -n "$yaml"
            return
        fi
    fi

    return 1
}

##
# Encodes a bash associative array and save it as Yaml file
# @param arrayToString $1 Associative array
# @param string $2 Yaml file path to create
# @return void
# @returnStatus 1 If first parameter named str is empty
# @returnStatus 1 If second parameter named filePath is empty or invalid
function yamlFileEncode ()
{
    local yaml="$1"
    local filePath="$2"

    if [[ -n "$filePath" && ! -d "$filePath" ]]; then
        yaml=$(yamlEncode "$yaml")
        if [[ $? -eq 0 && -n "$yaml" ]]; then
            echo "$yaml" > "$filePath"
            if [[ $? -eq 0 ]]; then
                return
            fi
        fi
    fi

    return 1
}