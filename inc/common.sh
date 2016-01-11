#!/usr/bin/env bash

##
# Computes the difference of arrays
#
# @example inputs "v1 v2 v3" "v1"
# @example return "v2 v3"
#
# @param stringableArray $1
# @param stringableArray $2
# @return stringableArray
function arrayDiff ()
{
    local ARRAY_1="$1"
    local ARRAY_2="$2"
    if [[ -z "$ARRAY_1" ]]; then
        echo "()"
        return
    elif [[ -z "$ARRAY_2" ]]; then
        echo "($ARRAY_1)"
        return
    fi

    local SKIP
    local DIFFERENCE=()
    for I in ${ARRAY_1[@]}; do
        SKIP=0
        for J in ${ARRAY_2[@]}; do
            [[ "$I" == "$J" ]] && { SKIP=1; break; }
        done
        [[ "$SKIP" -eq 1 ]] || DIFFERENCE+=("$I")
    done

    echo "${DIFFERENCE[@]}"
}

##
# Calculate and return a checksum for one string
# @param string $1
# @return string
function checksum ()
{
    local CHECKSUM_FILE="${WRK_DIR}${RANDOM}.crc"
    echo -n "$1" > "$CHECKSUM_FILE"

    local CHECKSUM
    CHECKSUM=$(cksum "$CHECKSUM_FILE" | awk '{print $1}')
    if [[ $? -ne 0 || -z "$CHECKSUM" ]]; then
        return 1
    fi

    rm -f "$CHECKSUM_FILE"
    echo -n "$CHECKSUM"
}

##
# @example Are you sure ? [Y/N]
# @param string $1 Message
# @return 0 if yes, 1 otherwise
function confirm ()
{
    local CONFIRM

    while read -e -p "$1 ${AWQL_CONFIRM}? " CONFIRM; do
        if [[ "$CONFIRM" == [Yy] ]] || [[ "$CONFIRM" == [Yy][Ee][Ss] ]]; then
            return 0
        elif [[ "$CONFIRM" == [Nn] ]] || [[ "$CONFIRM" == [Nn][Oo] ]]; then
            return 1
        fi
    done
}

##
# Ask anything to user and get his response
# @param string $1 Message
# @param int $2 If 1 or undefined, a response is required, 0 otherwise
function dialog ()
{
    local MESSAGE="$1"
    local MANDATORY="$2"
    if [[ -z "$MANDATORY" ]] || [[ "$MANDATORY" -ne 0 ]]; then
        MANDATORY=1
    fi

    local COUNTER=0
    local MANDATORY_FIELD
    local RESPONSE
    while [[ "$MANDATORY" -ne -1 ]]; do
        if [[ "$MANDATORY" -eq 1 ]] && [[ "$COUNTER" -gt 0 ]]; then
            MANDATORY_FIELD=" (required)"
        fi
        read -e -p "${MESSAGE}${MANDATORY_FIELD}: " RESPONSE
        if [[ -n "$RESPONSE" ]] || [[ "$MANDATORY" -eq 0 ]]; then
            echo "$RESPONSE"
            MANDATORY=-1
        fi
        ((COUNTER++))
    done
}

##
# Check if a value is available in array
# @param string $1 Needle
# @param stringableArray $2 Haystack
# @return int O if found, 1 otherwise
function inArray ()
{
    local NEEDLE="$1"
    local HAYSTACK="$2"

    if [[ -z "$NEEDLE" ]] || [[ -z "$HAYSTACK" ]]; then
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
# Exit in case of error, if $1 is not equals to 0
# @param string $1 return code of previous step
# @param string $2 message to log
# @param string $3 verbose mode
# @return int
function exitOnError ()
{
    local ERR_CODE="$1"
    local ERR_MSG="$2"
    local ERR_LOG="$3"

    if [[ "$ERR_CODE" -ne 0 ]]; then
        if [[ -n "$ERR_MSG" && -n "$ERR_LOG" ]]; then
            echo "$ERR_MSG"
        fi
        if [[ "$ERR_CODE" -eq 1 ]]; then
            exit 1
        fi
        return 0
    fi

    return 1
}

##
# Exit in case of error, if $1 is not equals to 0 and print formated message
# @example Message -------------------------------- OK
# @param string $1 return code of previous step
# @param string $2 message to display
function printAndExitOnError ()
{
    # In
    local STATUS="$AWQL_SUCCESS_STATUS"
    if [[ "$1" -ne 0 ]]; then
        STATUS="$AWQL_ERROR_STATUS"
    fi
    local MESSAGE="$2"

    # Out
    local PAD_LENGTH=60
    local PAD=$(printf '%0.1s' "-"{1..80})

    printf '%s ' "$MESSAGE"
    printf '%*.*s' 0 $((PAD_LENGTH - ${#MESSAGE})) "$PAD"
    printf ' %s\n' "$STATUS"

    if [[ "$1" -ne 0 ]]; then
        exit 1
    fi
}

##
# Parse a URL and return its components
# @example http://login:password@example.com/dir/file.ext?a=sth&b=std
# @return stringable (SCHEME:"http" USER:"login" PASS:"password" HOST:"example.com" PORT:80 PATH:"/dir/file.ext" QUERY:"a=sth&b=std")
function parseUrl ()
{
    local URL="$1"

    local HOST=""
    local PATH=""
    local PORT=80
    local SCHEME="${URL%%:*}"
    local CURRENT_POSITION="${#SCHEME}"
    if [[ "$CURRENT_POSITION" -gt 0 ]]; then
        # Manage :// after scheme
        CURRENT_POSITION=$((CURRENT_POSITION+3))

        # Manage pass & user
        local PASS=""
        local USER="${URL%:*}"
        if [[ "$SCHEME" != "$USER" ]] && [[ "$URL" == *"@"* ]]; then
            USER="${USER:$CURRENT_POSITION}"
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

##
# Remove leading and trailing whitespace
# @param string $1
# @return string
function trim ()
{
    echo "$1" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//"
}

##
# Get printed array string with declare method and convert it in stringableArray
#
# @example input declare -A rv='([k]="v")'
# @example code
#   declare -A rv
#   rv[k]="v"
#   stringableArray "$(declare -p rv)"
# @example return ([k]=v)
#
# @param string $1 STRINGABLE_ARRAY
# @return string
function stringableArray ()
{
    local STRINGABLE_ARRAY="$1"

    # Remove declare -OPTIONS ='(
    STRINGABLE_ARRAY="${STRINGABLE_ARRAY#*(}"
    # Remove )'
    STRINGABLE_ARRAY="${STRINGABLE_ARRAY%)*}"
    # Remove escaping of single quote (') by declare function
    STRINGABLE_ARRAY="${STRINGABLE_ARRAY//\\\'\'/}"

    echo -n "(${STRINGABLE_ARRAY})"
}

##
# Convert a Yaml file into readable string for array convertion
# @example '([K1]="V1" [K2]="V2")'
# @param string $1 Yaml file path to parse
# @return stringableArray YAML_TO_ARRAY
function yamlToArray ()
{
    if [[ -n "$1" ]] && [[ -f "$1" ]]; then
        # Remove comment lines, empty lines and format line to build associative array for bash (protect CSV output)
        local YAML_TO_ARRAY
        YAML_TO_ARRAY=$(sed -e "/^#/d" \
                            -e "/^$/d" \
                            -e "s/\"/'/g" \
                            -e "s/,/;/g" \
                            -e "s/=//g" \
                            -e "s/\ :[^:\/\/]/=\"/g" \
                            -e "s/$/\"/g" \
                            -e "s/ *=/]=/g" \
                            -e "s/^/[/g" "$1")
        if [[ $? -eq 0 ]]; then
            echo -n "(${YAML_TO_ARRAY})"
            return
        fi
    fi

    return 1
}

##
# Parse a JSON Google token to extract ACCESS_TOKEN, EXPIRES_IN, etc.
# ExpiresIn from Google token was converted in ExpireAt by this tool to manage expire date
# @param string TOKEN_FILE
# @example source
# {
#   "access_token" : "ya29.TgI73hCO7G3OaWdfJ2HTZNCnUlPFS91Ciud6TcoXV0Wg6n7qlI2Bl5H51EnqyyALIFOONYg",
#   "token_type" : "Bearer",
#   "expire_at": "2015-12-19T01:28:58+01:00"
# }
# @example return
# ([ACCESS_TOKEN]="ya29.TgI73hCO7G3OaWdfJ2HTZNCnUlPFS91Ciud6TcoXV0Wg6n7qlI2Bl5H51EnqyyALIFOONYg" [TOKEN_TYPE]=Bearer...)
# @return stringableArray
function getTokenFromFile ()
{
    local TOKEN_FILE="$1"

    # Set the option for extended regexp for MacOs portability
    local OPTIONS="-r"
    if [[ "${AWQL_OS}" == 'Darwin' ]]; then
       OPTIONS="-E"
    fi

    if [[ -f "$TOKEN_FILE" ]]; then
        local TOKEN
        TOKEN=$(cat "$TOKEN_FILE" | tr "\n" " " | tr -d " ")
        if [[ $? -ne 0 || "$TOKEN" != *"token_type"* || "$TOKEN" != *"access_token"* || "$TOKEN" != *"expire_at"* ]]; then
            return 1
        fi
        local TOKEN_TYPE=$(echo "$TOKEN" | sed ${OPTIONS} "s/.*\"token_type\":\"([^\"]+)\".*/\1/")
        local ACCESS_TOKEN=$(echo "$TOKEN" | sed ${OPTIONS} "s/.*\"access_token\":\"([^\"]+)\".*/\1/")
        local EXPIRE_AT=$(echo "$TOKEN" | sed ${OPTIONS} "s/.*\"expire_at\":\"([^\"]+)\".*/\1/")

        echo -n "([ACCESS_TOKEN]=\"${ACCESS_TOKEN}\" [TOKEN_TYPE]=\"${TOKEN_TYPE}\" [EXPIRE_AT]=\"${EXPIRE_AT}\")"
    else
        return 1
    fi
}

##
# Get current timestamp
# @example 1450485413
# @return int
function getCurrentTimestamp ()
{
    local CURRENT_TIMESTAMP

    CURRENT_TIMESTAMP=$(date +"%s" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo -n "$CURRENT_TIMESTAMP"
}

##
# Convert a Timestamp to UTC datetime
# @use AWQL_OS AWQL_UTC_DATE_FORMAT
# @example 2015-12-19T01:28:58+01:00
# @param int $1 TIMESTAMP
# @return string
function getUtcDateTimeFromTimestamp ()
{
    local TIMESTAMP="$1"

    # Data check
    local REGEX='^-?[0-9]+$'
    if [[ -z "$TIMESTAMP" ]] || ! [[ "$TIMESTAMP" =~ ${REGEX} ]]; then
        return 1
    fi

    # MacOs portability
    local OPTIONS="-d @"
    if [[ "${AWQL_OS}" == 'Darwin' ]]; then
       OPTIONS="-r"
    fi

    local UTC_DATETIME
    UTC_DATETIME=$(date ${OPTIONS}${TIMESTAMP} "+${AWQL_UTC_DATE_FORMAT}" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo -n "$UTC_DATETIME"
}

##
# Convert a UTC datetime to Timestamp
# @use AWQL_OS AWQL_UTC_DATE_FORMAT
# @example 1450485413 => 2015-12-19T01:28:58+01:00
# @param string $1 UTC_DATETIME
# @return int
function getTimestampFromUtcDateTime ()
{
    local UTC_DATETIME="$1"
    local TIMESTAMP=O

    # Data check
    if [[ -z "$UTC_DATETIME" ]] || ! [[ "$UTC_DATETIME" == *"T"* ]]; then
        return 1
    fi

    # MacOs portability
    if [[ "${AWQL_OS}" == 'Darwin' ]]; then
        TIMESTAMP=$(date -j -f "${AWQL_UTC_DATE_FORMAT}" "${UTC_DATETIME}" "+%s" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    else
        TIMESTAMP=$(date -d "${UTC_DATETIME}" "+%s" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    echo -n "$TIMESTAMP"
}