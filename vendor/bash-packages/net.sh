#!/usr/bin/env bash

##
# Parse a URL and return its components
# @example http://login:password@example.com/dir/file.ext?a=sth&b=std
# @return stringable (SCHEME:"http" USER:"login" PASS:"password" HOST:"example.com" PORT:80 PATH:"/dir/file.ext" QUERY:"a=sth&b=std")
function parseUrl ()
{
    local URL="$1"
    if [[ -z "$URL" || "$URL" != *"://"* ]]; then
        return 1
    fi

    local SCHEME="${URL%%:*}"
    local HOST=""
    declare -i PORT=80
    if [[ "ftp" == "$SCHEME" ]]; then
        PORT=21
    elif [[ "https" == "$SCHEME" ]]; then
        PORT=443
    fi
    local PATH=""
    local CURRENT_POSITION="${#SCHEME}"
    if [[ "$CURRENT_POSITION" -gt 0 ]]; then
        # Manage :// after scheme
        CURRENT_POSITION=$((CURRENT_POSITION+3))

        # Manage pass & user
        local PASS=""
        local USER="${URL:$CURRENT_POSITION}"
        if [[ "$URL" == *"@"* ]]; then
            USER="${USER%%:*}"
            # Manage ":" between username and password
            CURRENT_POSITION=$((CURRENT_POSITION+${#USER}+1))
            # Get the password to use with
            PASS="${URL:$CURRENT_POSITION}"
            PASS="${PASS%%@*}"
            # Manage "@" between password and domain
            CURRENT_POSITION=$((CURRENT_POSITION+${#PASS}+1))
        else
            USER=""
        fi

        # Manage host & path
        if [[ "$URL" == *"?"* ]]; then
            PATH="${URL%%\?*}"
            PATH="${PATH:$CURRENT_POSITION}"
        else
            PATH="${URL:$CURRENT_POSITION}"
        fi
        CURRENT_POSITION=$((CURRENT_POSITION+${#PATH}))
        HOST="${PATH%%/*}"
        PATH="${PATH:${#HOST}}"

        # Manage host
        if [[ "$HOST" == *":"* ]]; then
            PORT="$((${HOST##*:}+0))"
            HOST="${HOST%%:*}"
        fi

        # Manage query
        local QUERY=""
        local FRAGMENT=""
        if [[ "${URL:$CURRENT_POSITION}" == "?"* ]]; then
            QUERY="${URL:$CURRENT_POSITION+1}"
        fi

        # Manage fragment
        if [[ "$QUERY" == *"#"* ]]; then
            FRAGMENT="${QUERY##*#}"
            QUERY="${QUERY%%#*}"
        elif [[ "$PATH" == *"#"* ]]; then
            FRAGMENT="${PATH##*#}"
            PATH="${PATH%%#*}"
        fi
        if [[ -z "$PATH" ]]; then
            PATH="/"
        fi
    fi

    # Check URL compliance
    if [[ "$CURRENT_POSITION" -eq 0 ]] || [[ "$HOST" == "" ]]; then
        return 1
    fi

    echo -n "(" \
        "[SCHEME]=\"${SCHEME}\"" \
        "[USER]=\"${USER}\"" \
        "[PASS]=\"${PASS}\"" \
        "[HOST]=\"${HOST}\"" \
        "[PORT]=${PORT}" \
        "[PATH]=\"${PATH}\"" \
        "[QUERY]=\"${QUERY}\"" \
        "[FRAGMENT]=\"${FRAGMENT}\"" \
    ")"
}