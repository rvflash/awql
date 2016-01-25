#!/usr/bin/env bash

##
# Get informations for authentification from yaml file
# @example ([ACCESS_TOKEN]="..." [DEVELOPER_TOKEN]="...")
# @param string $1 Access token (inline mode)
# @param string $2 Developer token (inline mode)
# @return arrayToString
function auth ()
{
    local ACCESS_TOKEN="$1"
    local DEVELOPER_TOKEN="$2"

    # Inline mode
    if [[ -n "$ACCESS_TOKEN" ]] && [[ -n "$DEVELOPER_TOKEN" ]]; then
        echo -n "([TOKEN_TYPE]=\"Bearer\" [ACCESS_TOKEN]=\"${ACCESS_TOKEN}\" [DEVELOPER_TOKEN]=\"${DEVELOPER_TOKEN}\")"
        return
    fi

    # Default configuration
    local AUTH
    AUTH="$(yamlFileDecode "${AWQL_AUTH_FILE}")"
    if [ $? -ne 0 ]; then
        echo "AuthenticationError.FILE_INVALID"
        return 1
    fi
    declare -A -r AUTH="$AUTH"

    local AUTH_FILE="${AWQL_AUTH_DIR}/${AUTH[AUTH_TYPE]}/auth.sh"
    local INVALID=0
    local ACCESS=""
    case "${AUTH[AUTH_TYPE]}" in
        ${AUTH_GOOGLE_TYPE})
            ACCESS=$(${AUTH_FILE} -c "${AUTH[CLIENT_ID]}" -s "${AUTH[CLIENT_SECRET]}" -r "${AUTH[REFRESH_TOKEN]}")
            INVALID=$?
            ;;
        ${AUTH_CUSTOM_TYPE})
            ACCESS=$(${AUTH_FILE} "${AUTH[PROTOCOL]}://${AUTH[HOSTNAME]}:${AUTH[PORT]}${AUTH[PATH]}")
            INVALID=$?
            ;;
        *)
            ACCESS="QueryError.UNKNOWN_AWQL_ACCESS_METHOD"
            INVALID=1
            ;;
    esac

    if [[ "$INVALID" -ne 0 ]]; then
        echo "$ACCESS"
        return 1
    fi
    declare -A ACCESS="$ACCESS"

    ACCESS[DEVELOPER_TOKEN]="${AUTH[DEVELOPER_TOKEN]}"

    echo -n "$(arrayToString "$(declare -p ACCESS)")"
}