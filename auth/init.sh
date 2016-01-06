#!/usr/bin/env bash

##
# Init auth environment by creating auth yaml file with defaut configuration
#
# @raw
# AUTH_TYPE         : __AUTH_TYPE__
# TOKEN_TYPE        : Bearer

## Google account
# CLIENT_ID         : __CLIENT_ID__
# CLIENT_SECRET     : __CLIENT_SECRET__
# REFRESH_TOKEN     : __REFRESH_TOKEN__
# DEVELOPER_TOKEN   : __DEVELOPER_TOKEN__
#
## Custom web service
# PROTOCOL          : __PROTOCOL__
# HOSTNAME          : __HOSTNAME__
# PATH              : __PATH__
# PORT              : __PORT__

# Envionnement
SCRIPT=$(basename ${BASH_SOURCE[0]})
SCRIPT_PATH="$0"; while [[ -h "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_ROOT=$(dirname "$SCRIPT_PATH")

# Requires
source "${SCRIPT_ROOT}/../conf/awql.sh"
source "${AWQL_INC_DIR}/common.sh"

# Workspace
AUTH_TYPE=""
CLIENT_ID=""
CLIENT_SECRET=""
REFRESH_TOKEN=""
DEVELOPER_TOKEN=""
URL=""
VERBOSE=0

# Help
function usage ()
{
    echo "Usage: ${SCRIPT} -a authtype [-c clientid] [-s clientsecret] [-r refreshtoken] [-d developertoken] [-u url]"
    echo "-a for authentification type [ ${AUTH_GOOGLE_TYPE} | ${AUTH_CUSTOM_TYPE} ]"
    echo "-c for Google client ID"
    echo "-s for Google client secret"
    echo "-r for refresh token"
    echo "-d for developer token"
    echo "-u for url of custom web service"
    echo "-v used to print more informations"

    if [[ "$1" != "" ]]; then
        echo "> Mandatory field: $1"
    fi
}

# Script usage
if [ $# -lt 1 ] ; then
    usage
    exit 1
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "a::c::s::r::d::u:v" FLAG; do
    case "${FLAG}" in
        a) if [[ "$OPTARG" == "$AUTH_GOOGLE_TYPE" ]] || [[ "$OPTARG" == "$AUTH_CUSTOM_TYPE" ]]; then AUTH_TYPE="$OPTARG"; fi ;;
        c) CLIENT_ID="$OPTARG" ;;
        s) CLIENT_SECRET="$OPTARG" ;;
        r) REFRESH_TOKEN="$OPTARG" ;;
        d) DEVELOPER_TOKEN="$OPTARG" ;;
        u) URL="$OPTARG" ;;
        v) VERBOSE=1 ;;
        *) usage; exit 1 ;;
        ?) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [[ -z "$AUTH_TYPE" ]]; then
    usage AUTH_TYPE
    exit 1
elif [[ -z "$DEVELOPER_TOKEN" ]]; then
    usage DEVELOPER_TOKEN
    exit 1
elif [[ "$AUTH_TYPE" == "$AUTH_GOOGLE_TYPE" ]]; then
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
elif [[ -z "$URL" ]]; then
    usage URL
    exit 1
fi

##
# Build a authenfication file with parameters to use to refresh the access token of Google with a custom web service
# @param string $1 Web service url
# @param string $2 Google developer token
# @param int $3 Verbose mode
function initCustom ()
{
    local DEVELOPER_TOKEN="$2"
    local VERBOSE="$3"

    local URL
    URL="$(parseUrl "$1")"
    if exitOnError "$?" "AuthenticationError.INVALID_URL" "$VERBOSE"; then
        return 1
    fi

    declare -A -r URL="$URL"
    local PROTOCOL="${URL[SCHEME]}"
    local HOSTNAME="${URL[HOST]}"
    local URLPATH="${URL[PATH]}"
    local PORT="${URL[PORT]}"

    sed -e "s/__AUTH_TYPE__/${AUTH_CUSTOM_TYPE}/g" \
        -e "s/__DEVELOPER_TOKEN__/${DEVELOPER_TOKEN//\//\\/}/g" \
        -e "s/__PROTOCOL__/${PROTOCOL}/g" \
        -e "s/__HOSTNAME__/${HOSTNAME}/g" \
        -e "s/__PATH__/${URLPATH//\//\\/}/g" \
        -e "s/__PORT__/${PORT}/g" \
        "${AWQL_AUTH_FILE/.yaml/-dist.yaml}" 1>"${AWQL_AUTH_FILE}" 2>/dev/null

    if exitOnError exitOnError "$?" "AuthenticationError.UNABLE_TO_BUILD_FILE" "$VERBOSE"; then
        return 1
    fi
}

##
# Build a authenfication file with parameters to use to refresh the access token with a Google refresh token
# @param string $1 Google client ID
# @param string $2 Google client secret
# @param string $3 Google refresh token
# @param string $4 Google developer token
# @param string $5 Verbose mode
function initGoogle ()
{
    local CLIENT_ID="$1"
    local CLIENT_SECRET="$2"
    local REFRESH_TOKEN="$3"
    local DEVELOPER_TOKEN="$4"
    local VERBOSE="$5"

    sed -e "s/__AUTH_TYPE__/${AUTH_GOOGLE_TYPE}/g" \
        -e "s/__DEVELOPER_TOKEN__/${DEVELOPER_TOKEN//\//\\/}/g" \
        -e "s/__CLIENT_ID__/${CLIENT_ID//\//\\/}/g" \
        -e "s/__CLIENT_SECRET__/${CLIENT_SECRET//\//\\/}/g" \
        -e "s/__REFRESH_TOKEN__/${REFRESH_TOKEN//\//\\/}/g" \
        "${AWQL_AUTH_FILE/.yaml/-dist.yaml}" 1>"${AWQL_AUTH_FILE}" 2>/dev/null

    if exitOnError "$?" "AuthenticationError.UNABLE_TO_BUILD_FILE" "$VERBOSE"; then
        return 1
    fi
}

if [[ "$AUTH_TYPE" == "$AUTH_GOOGLE_TYPE" ]]; then
    initGoogle "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" "$DEVELOPER_TOKEN" "$VERBOSE"
else
    initCustom "$URL" "$DEVELOPER_TOKEN" "$VERBOSE"
fi