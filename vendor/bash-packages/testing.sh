#!/usr/bin/env bash

##
# Basic function to test A with B and validate the behavior of a method
# @codeCoverageIgnore
# @param string $1 Method's name
# @param string $2 Expected string
# @param string $3 Received string to compare with expected string
function bashUnit ()
{
    local METHOD="$1"
    local EXPECTED="$2"
    local RECEIVED="$3"

    if [[ -z "$METHOD" || -z "$EXPECTED" || -z "$RECEIVED" ]]; then
        echo "Missing values for BashUnit testing tool"
        exit 1
    fi

    if [[ "${RECEIVED}" == "${EXPECTED}" ]]; then
        echo "Function ${METHOD}: OK"
    else
        echo "Function ${METHOD}: KO (Expected ${EXPECTED}, received ${RECEIVED})"
    fi
}