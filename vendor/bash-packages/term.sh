#!/usr/bin/env bash

declare -r -i BP_BC="$(if [[ BP_BC_PATH="$(type -p bc)" || -z "$BP_BC_PATH" ]]; then echo "0"; else echo "1"; fi)"

##
# @example Are you sure ? [Y/N]
# @param string $1 Message
# @param string $2 Default message to add after confirm request
# @return 0 if yes, 1 otherwise
function confirm ()
{
    local DEFAULT_MESSAGE="$2"
    local CONFIRM

    while read -e -p "$1 ${DEFAULT_MESSAGE}? " CONFIRM; do
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
# @param string $3 Mandatory text
function dialog ()
{
    local MESSAGE="$1"
    local MANDATORY="$2"
    if [[ -z "$MANDATORY" ]] || [[ "$MANDATORY" -ne 0 ]]; then
        MANDATORY=1
    fi
    local MANDATORY_MESSAGE="$3"

    local COUNTER=0
    local MANDATORY_FIELD
    local RESPONSE
    while [[ "$MANDATORY" -ne -1 ]]; do
        if [[ "$MANDATORY" -eq 1 && "$COUNTER" -gt 0 && -z "$MANDATORY_MESSAGE" ]]; then
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
# @param string [$1] optional, accepted values: width or height
# @return stringable
function windowSize ()
{
    local TYPE="$1"
    declare -a SIZE="($(echo -n $(echo -ne "cols\nlines" | tput -S)))"

    case "$TYPE" in
        "width" ) echo -n "${SIZE[0]}" ;;
        "height") echo -n "${SIZE[1]}" ;;
        *       ) echo -n "${SIZE[@]}" ;;
    esac
}