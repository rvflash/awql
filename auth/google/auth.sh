#!/usr/bin/env bash

##
# Get a Access Token to Google Adwords by using a Google Refresh Token
# Require a CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN
#
# Get refresh token :
# https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=${CLIENT_ID}
#   &scope=https://www.googleapis.com/auth/adwords&response_type=code&redirect_uri=urn:ietf:wg:oauth:2.0:oob
#   &approval_prompt=force
#
# @example
# {
#     "access_token": "ya29.ExaMple",
#     "token_type": "Bearer",
#     "expire_in": 3600
# }

# Envionnement
SCRIPT=$(basename ${BASH_SOURCE[0]})
SCRIPT_PATH="$0"; while [[ -h "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_ROOT=$(dirname "$SCRIPT_PATH")

# Requires
source "${SCRIPT_ROOT}/../../conf/awql.sh"
source "${AWQL_INC_DIR}/common.sh"

# Workspace
CLIENT_ID=""
CLIENT_SECRET=""
REFRESH_TOKEN=""

# Help
function usage ()
{
    echo "Usage: ${SCRIPT} -c clientid -s clientsecret -r refreshtoken"
    echo "-c for Google client ID"
    echo "-s for Google client secret"
    echo "-r for refresh token"

    if [[ "$1" != "" ]]; then
        echo "> Mandatory field: $1"
    fi
}

# Script usage
if [[ $# -lt 3 ]]; then
    usage
    exit 1
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "c:s:r:" FLAG; do
    case "${FLAG}" in
        c) CLIENT_ID="$OPTARG" ;;
        s) CLIENT_SECRET="$OPTARG" ;;
        r) REFRESH_TOKEN="$OPTARG" ;;
        *) usage; exit 1 ;;
        ?) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [[ -z "$CLIENT_ID" ]]; then
    usage CLIENT_ID
    exit 1
elif [[ -z "$CLIENT_SECRET" ]]; then
    usage CLIENT_SECRET
    exit 1
elif [[ -z "$REFRESH_TOKEN" ]]; then
    usage REFRESH_TOKEN
    exit 1
fi

##
# Retrieve access token to Google
# @param string $1 CLIENT_ID
# @param string $2 CLIENT_SECRET
# @param string $3 REFRESH_TOKEN
# @return stringableArray
function auth ()
{
    local CLIENT_ID="$1"
    local CLIENT_SECRET="$2"
    local REFRESH_TOKEN="$3"
    local REQUEST_FILE="${AWQL_AUTH_DIR}/${AUTH_GOOGLE_TYPE}/${AWQL_REQUEST_FILE_NAME}"
    local FILE="${AWQL_WRK_DIR}/${AWQL_TOKEN_FILE_NAME}"

    # Check availibility of existing token in cache
    if [[ -f "$FILE" ]]; then
        local TOKEN="$(getTokenFromFile "$FILE")"
        if [[ $? -eq 0 ]]; then
            declare -A -r TOKEN="$TOKEN"
            local TIMESTAMP="$(getTimestampFromUtcDateTime "${TOKEN[EXPIRE_AT]}")"
            if [[ $? -eq 0 ]]; then
                local CURRENT_TIMESTAMP="$(getCurrentTimestamp)"
                if [[ $? -eq 0 ]] && [[ "$TIMESTAMP" -gt "$CURRENT_TIMESTAMP" ]]; then
                    echo -n "$(stringableArray "$(declare -p TOKEN)")"
                    return
                fi
            fi
        fi
        # Cached token is deprecated
        rm -f "$FILE"
    fi

    # Try to retrieve a fresh token
    refresh "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" "$REQUEST_FILE" "$FILE"
    if [[ $? -eq 0 ]]; then
        local AUTH="$(getTokenFromFile "$FILE")"
        if [[ $? -eq 0 ]]; then
            echo -n "$AUTH"
            return
        else
            # Invalid token
            echo "AccessAuthError.UNABLE_TO_FETCH"
            rm -f "$FILE"
        fi
    fi

    # Unable to retrieve a valid token
    return 1
}

##
# Send authentification request to Google API Account
# @param string $1 CLIENT_ID
# @param string $2 CLIENT_SECRET
# @param string $3 REFRESH_TOKEN
# @param string $4 REQUEST_FILE
# @param string $5 FILE
function refresh ()
{
    local CLIENT_ID="$1"
    local CLIENT_SECRET="$2"
    local REFRESH_TOKEN="$3"
    local REQUEST_FILE="$4"
    local FILE="$5"

    # Request configuration
    local REQUEST="$(yamlToArray "$REQUEST_FILE")"
    if [[ $? -ne 0 ]]; then
        echo "RefreshAuthError.INVALID_REQUEST_FILE"
        return 1
    fi
    declare -A -r GOOGLE_AUTH_REQUEST="$REQUEST"

    # Define curl default properties
    local OPTIONS="--silent"
    if [[ "${GOOGLE_AUTH_REQUEST[CONNECT_TIME_OUT]}" -gt 0 ]]; then
        OPTIONS="$OPTIONS --connect-timeout ${GOOGLE_AUTH_REQUEST[CONNECT_TIME_OUT]}"
    fi
    if [[ "${GOOGLE_AUTH_REQUEST[TIME_OUT]}" -gt 0 ]]; then
        OPTIONS="$OPTIONS --max-time ${GOOGLE_AUTH_REQUEST[TIME_OUT]}"
    fi

    # Connexion to Google Account
    local GOOGLE_URL="${GOOGLE_AUTH_REQUEST[PROTOCOL]}://${GOOGLE_AUTH_REQUEST[HOSTNAME]}${GOOGLE_AUTH_REQUEST[PATH]}"
    local HTTP_STATUS_CODE=$(curl \
        --request "${GOOGLE_AUTH_REQUEST[METHOD]}" "$GOOGLE_URL" \
        --data "${GOOGLE_AUTH_REQUEST[CLIENT_ID]}=${CLIENT_ID}" \
        --data "${GOOGLE_AUTH_REQUEST[CLIENT_SECRET]}=${CLIENT_SECRET}" \
        --data "${GOOGLE_AUTH_REQUEST[REFRESH_TOKEN]}=${REFRESH_TOKEN}" \
        --data "${GOOGLE_AUTH_REQUEST[GRANT_TYPE]}=${GOOGLE_AUTH_REQUEST[GRANT_TYPE_RT]}" \
        --output "$FILE" \
        --write-out "%{http_code}" ${OPTIONS}
    )

    if [[ "$HTTP_STATUS_CODE" -eq 0 ]] || [[ "$HTTP_STATUS_CODE" -gt 400 ]]; then
        echo "RefreshAuthError.GOOGLE_AUTH_REQUEST_FAIL"
        rm -f "$FILE"
        return 1
    elif [[ "$(grep "error" "$FILE" | wc -l)" -eq 1 ]]; then
        echo "RefreshAuthError.GOOGLE_AUTH_INVALID_GRANT"
        rm -f "$FILE"
        return 1
    else
        # Convert ExpiresIn to ExpireAt
        local CURRENT_TIMESTAMP="$(getCurrentTimestamp)"
        local UTC_DATETIME="$(getUtcDateTimeFromTimestamp $((${CURRENT_TIMESTAMP}+3600)))"
        if [[ $? -eq 0 ]]; then
            sed -i -e "s/\"expires_in\":3600/\"expire_at\":\"${UTC_DATETIME}\"/g" "$FILE"
        fi
    fi
}

auth "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN"
if [[ $? -ne 0 ]]; then
    exit 1
fi