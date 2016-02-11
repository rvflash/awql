#!/usr/bin/env bash

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
# Format message with left padding
# @example Message --------------------------------
# @param string $1 message to display
# @param int $2 padding length
# @param string $3 padding char
function printLeftPad ()
{
    local MESSAGE="$1"
    declare -i MESSAGE_LENGTH="${#MESSAGE}"
    declare -i PAD_LENGTH="$2"
    if [[ "$PAD_LENGTH" -eq 0 ]]; then
        PAD_LENGTH=100
    fi
    local PAD="$3"
    if [[ -z "$PAD" ]]; then
        PAD=" "
    fi

    echo -n "${MESSAGE} "
    if [[ "$PAD_LENGTH" -gt "$MESSAGE_LENGTH" ]]; then
        PAD=$(printf '%0.1s' "${PAD}"{1..500})
        printf '%*.*s' 0 $((PAD_LENGTH - $MESSAGE_LENGTH)) "$PAD"
    fi
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
    printLeftPad "$MESSAGE" 60 "-"
    printf ' %s\n' "$STATUS"

    if [[ "$1" -ne 0 ]]; then
        exit 1
    fi
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
# @return arrayToString
function tokenFromFile ()
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