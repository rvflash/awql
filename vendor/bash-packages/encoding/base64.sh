#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package encoding/base64
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

declare -r -i BP_BASE64="$(if [[ -z "$(type -p base64)" ]]; then echo 0; else echo 1; fi)"


##
# Decodes data encoded with MIME base64
# @return string
# @returnStatus 2 If base64 command line tool is not available
# @returnStatus 1 If first parameter named str is empty
function base64Decode ()
{
    # base64 command line tool is required
    if [[ ${BP_BASE64} -eq 0 ]]; then
        return 2
    elif [[ -z "$1" ]]; then
        return 1
    fi

    base64 --decode <<<"${1}"
}

##
# Encodes data with MIME base64
# @return string
# @returnStatus 2 If base64 command line tool is not available
# @returnStatus 1 If first parameter named str is empty
function base64Encode ()
{
    # base64 command line tool is required
    if [[ ${BP_BASE64} -eq 0 ]]; then
        return 2
    elif [[ -z "$1" ]]; then
        return 1
    fi

    base64 <<<"${1}"
}