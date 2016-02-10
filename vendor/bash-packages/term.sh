#!/usr/bin/env bash

##
# @example Are you sure ? [Y/N]
# @codeCoverageIgnore
# @param string $1 Message
# @param string $2 Default message to add after confirm request [optional]
# @returnStatus 0 I answer is YES
# @returnStatus 1 I answer is NO
function confirm ()
{
    local DEFAULT_MESSAGE="$2"

    local CONFIRM
    while read -e -p "$1 ${DEFAULT_MESSAGE}? " CONFIRM; do
        if [[ "$CONFIRM" == [Yy] || "$CONFIRM" == [Yy][Ee][Ss] ]]; then
            return 0
        elif [[ "$CONFIRM" == [Nn] || "$CONFIRM" == [Nn][Oo] ]]; then
            return 1
        fi
    done
}

##
# Ask anything to user and get his response
# @codeCoverageIgnore
# @param string $1 Message
# @param int $2 If 1 or undefined, a response is required, 0 otherwise [optional]
# @param string $3 Mandatory text [optional]
# return string
function dialog ()
{
    local MESSAGE="$1"
    local MANDATORY="$2"
    if [[ -z "$MANDATORY" || "$MANDATORY" -ne 0 ]]; then
        MANDATORY=1
    fi
    local MANDATORY_MESSAGE="$3"

    local COUNTER=0
    local MANDATORY_FIELD
    local RESPONSE
    while [[ "$MANDATORY" -ne -1 ]]; do
        if [[ "$MANDATORY" -eq 1 && "$COUNTER" -gt 0 && -n "$MANDATORY_MESSAGE" ]]; then
            MANDATORY_FIELD=" ${MANDATORY_MESSAGE}"
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
# Get width or height or both of a terminal window
#
# @example return width
# @example return width height
#
# @param string $1 Type width or height [optional]
# @return arrayToString
function windowSize ()
{
    local TYPE="$1"
    declare -a SIZE="($(echo -ne "cols\nlines" | tput -S))"

    case "$TYPE" in
        "width" ) echo -n "${SIZE[0]}" ;;
        "height") echo -n "${SIZE[1]}" ;;
        *       ) echo -n "${SIZE[@]}" ;;
    esac
}