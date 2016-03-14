#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package net
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

##
# Parse a URL and return its components
# @example http://login:password@example.com/dir/file.ext?a=sth&b=std
#     (SCHEME:"http" USER:"login" PASS:"password" HOST:"example.com" PORT:80 PATH:"/dir/file.ext" QUERY:"a=sth&b=std")
# @return arrayToString
# @returnStatus 1 If Url is empty or invalid
function parseUrl ()
{
    local url="$1"
    if [[ -z "$url" || "$url" != *"://"* ]]; then
        return 1
    fi

    local scheme="${url%%:*}"
    local host=""
    declare -i port=80
    if [[ "ftp" == "$scheme" ]]; then
        port=21
    elif [[ "https" == "$scheme" ]]; then
        port=443
    fi
    local path=""
    declare -i currentPos="${#scheme}"
    if [[ "$currentPos" -gt 0 ]]; then
        # Manage :// after scheme
        currentPos=$((currentPos+3))

        # Manage pass & user
        local pass=""
        local user="${url:$currentPos}"
        if [[ "$url" == *"@"* ]]; then
            user="${user%%:*}"
            # Manage ":" between username and password
            currentPos=$((currentPos+${#user}+1))
            # Get the password to use with
            pass="${url:$currentPos}"
            pass="${pass%%@*}"
            # Manage "@" between password and domain
            currentPos=$((currentPos+${#pass}+1))
        else
            user=""
        fi

        # Manage host & path
        if [[ "$url" == *"?"* ]]; then
            path="${url%%\?*}"
            path="${path:$currentPos}"
        else
            path="${url:$currentPos}"
        fi
        currentPos=$((currentPos+${#path}))
        host="${path%%/*}"
        path="${path:${#host}}"

        # Manage host
        if [[ "$host" == *":"* ]]; then
            port="$((${host##*:}+0))"
            host="${host%%:*}"
        fi

        # Manage query
        local query=""
        local fragment=""
        if [[ "${url:$currentPos}" == "?"* ]]; then
            query="${url:$currentPos+1}"
        fi

        # Manage fragment
        if [[ "$query" == *"#"* ]]; then
            fragment="${query##*#}"
            query="${query%%#*}"
        elif [[ "$path" == *"#"* ]]; then
            fragment="${path##*#}"
            path="${path%%#*}"
        fi
        if [[ -z "$path" ]]; then
            path="/"
        fi
    fi

    # Check url compliance
    if [[ "$currentPos" -eq 0 ]] || [[ "$host" == "" ]]; then
        return 1
    fi

    echo -n "(" \
        "[SCHEME]=\"${scheme}\"" \
        "[USER]=\"${user}\"" \
        "[PASS]=\"${pass}\"" \
        "[HOST]=\"${host}\"" \
        "[PORT]=${port}" \
        "[PATH]=\"${path}\"" \
        "[QUERY]=\"${query}\"" \
        "[FRAGMENT]=\"${fragment}\"" \
    ")"
}