#!/usr/bin/env bash

##
# Init auth environment by creating auth Yaml file with default configuration
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

# Environment
scriptPath="$0"; while [[ -h "$scriptPath" ]]; do scriptPath="$(readlink "$scriptPath")"; done
rootDir=$(dirname "$scriptPath")

# Import
source "${rootDir}/../../conf/awql.sh"
source "${AWQL_AUTH_DIR}/token.sh"
source "${AWQL_BASH_PACKAGES_DIR}/net.sh"


# Workspace
declare -- authType=""
declare -- clientId=""
declare -- clientSecret=""
declare -- refreshToken=""
declare -- developerToken=""
declare -- url=""
declare -i verbose=0
declare -- auth=""

# Help
# @return string
function usage ()
{
    echo "usage: init.sh -a authType [-c clientId] [-s clientSecret] [-r refreshToken] [-d developerToken] [-u url]"
    echo "-a for authentification type [ ${AWQL_AUTH_GOOGLE_TYPE} | ${AWQL_AUTH_CUSTOM_TYPE} ]"
    echo "-c for Google client ID"
    echo "-s for Google client secret"
    echo "-r for refresh token"
    echo "-d for developer token"
    echo "-u for url of custom web service"
    echo "-v used to print more information"

    if [[ -n "$1" ]]; then
        echo -e "\n> Mandatory field: $1"
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
        a)
            if [[ "${AWQL_AUTH_GOOGLE_TYPE}" == "$OPTARG" || "${AWQL_AUTH_CUSTOM_TYPE}" == "$OPTARG" ]]; then
                authType="$OPTARG"
            fi
            ;;
        c) clientId="$OPTARG" ;;
        s) clientSecret="$OPTARG" ;;
        r) refreshToken="$OPTARG" ;;
        d) developerToken="$OPTARG" ;;
        u) url="$OPTARG" ;;
        v) verbose=1 ;;
        *) usage; exit 1 ;;
        ?) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [[ -z "$authType" ]]; then
    usage "authType"
    exit 1
elif [[ -z "$developerToken" ]]; then
    usage "developerToken"
    exit 1
elif [[ "${AWQL_AUTH_GOOGLE_TYPE}" == "$authType" ]]; then
    if [[ -z "$clientId" ]]; then
        usage "clientId"
        exit 1
    elif [[ -z "$clientSecret" ]]; then
        usage "clientSecret"
        exit 1
    elif [[ -z "$refreshToken" ]]; then
        usage "refreshToken"
        exit 1
    fi
elif [[ -z "$url" ]]; then
    usage "url"
    exit 1
fi


##
# Build a authentification file with parameters to use to refresh the access token of Google with a custom web service
# @param string $1 Web service url
# @param string $2 Google developer token
# @returnStatus 1 If auth file can not be saved
# @returnStatus 1 If url is not wellformed
function authCustomToken ()
{
    local strUrl="$(parseUrl "$1")"
    if [[ -z "$strUrl" ]]; then
        echo "${AWQL_AUTH_ERROR_INVALID_URL}"
        return 1
    fi
    local developerToken="$2"
    if [[ -z "$developerToken" ]]; then
        echo "${AWQL_AUTH_ERROR_INVALID_DEVELOPER_TOKEN}"
        return 1
    fi
    declare -A -r url="$strUrl"

    sed -e "s/__${AWQL_AUTH_TYPE}__/${AWQL_AUTH_CUSTOM_TYPE}/g" \
        -e "s/__${AWQL_DEVELOPER_TOKEN}__/${developerToken//\//\\/}/g" \
        -e "s/__${AWQL_AUTH_PROTOCOL}__/${url["SCHEME"]}/g" \
        -e "s/__${AWQL_AUTH_HOSTNAME}__/${url["HOST"]}/g" \
        -e "s/__${AWQL_AUTH_PATH}__/${url["PATH"]//\//\\/}/g" \
        -e "s/__${AWQL_AUTH_PORT}__/${url["PORT"]}/g" \
        "${AWQL_AUTH_FILE/.yaml/-dist.yaml}" 1>"${AWQL_AUTH_FILE}" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "${AWQL_AUTH_ERROR_BUILD_FILE}"
        return 1
    fi
}

##
# Build a authentification file with parameters to use to refresh the access token with a Google refresh token
# @param string $1 Google client ID
# @param string $2 Google client secret
# @param string $3 Google refresh token
# @param string $4 Google developer token
# @returnStatus 1 If auth file can not be saved
function authGoogleToken ()
{
    local clientId="$1"
    local clientSecret="$2"
    local refreshToken="$3"
    local developerToken="$4"
    if [[ -z "$clientId" || -z "$clientSecret" || -z "$refreshToken" || -z "$developerToken" ]]; then
        echo "${AWQL_AUTH_ERROR_BUILD_FILE}"
        return 1
    fi

    sed -e "s/__${AWQL_AUTH_TYPE}__/${AWQL_AUTH_GOOGLE_TYPE}/g" \
        -e "s/__${AWQL_DEVELOPER_TOKEN}__/${developerToken//\//\\/}/g" \
        -e "s/__${AWQL_AUTH_CLIENT_ID}__/${clientId//\//\\/}/g" \
        -e "s/__${AWQL_AUTH_CLIENT_SECRET}__/${clientSecret//\//\\/}/g" \
        -e "s/__${AWQL_REFRESH_TOKEN}__/${refreshToken//\//\\/}/g" \
        "${AWQL_AUTH_FILE/.yaml/-dist.yaml}" 1>"${AWQL_AUTH_FILE}" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "${AWQL_AUTH_ERROR_BUILD_FILE}"
        return 1
    fi
}

# Create auth Yaml file
if [[ "${AWQL_AUTH_GOOGLE_TYPE}" == "$authType" ]]; then
    auth="$(authGoogleToken "$clientId" "$clientSecret" "$refreshToken" "$developerToken")"
else
    auth="$(authCustomToken "$url" "$developerToken")"
fi

# Output
if [[ $? -ne 0 ]]; then
    if [[ ${verbose} -eq 1 ]]; then
        echo "$auth"
    fi
    return 1
fi

echo "$auth"