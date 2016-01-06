#!/usr/bin/env bash

##
# Provide interface to request Google Adwords with AWQL queries
#
# @copyright 2015 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0

# Envionnement
SCRIPT_PATH="$0"; while [[ -h "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_ROOT=$(dirname "$SCRIPT_PATH")

# Requires
source "${SCRIPT_ROOT}/conf/awql.sh"
source "${AWQL_INC_DIR}/common.sh"
source "${AWQL_INC_DIR}/awql.sh"
source "${AWQL_INC_DIR}/query.sh"
source "${AWQL_INC_DIR}/print.sh"
source "${AWQL_AUTH_DIR}/auth.sh"

# Default values
ADWORDS_ID=""
ACCESS_TOKEN=""
DEVELOPER_TOKEN=""
QUERY=""
SAVE_FILE=""
CACHING=0
VERBOSE=0

# Help
function usage ()
{
    echo "Usage: awql -i adwordsid [-a accesstoken] [-d developertoken] [-e query] [-s savefilepath] [-c] [-v]"
    echo "-i for Google Adwords account ID"
    echo "-a for Google Adwords access token"
    echo "-d for Google developer token"
    echo "-e for AWQL query, if not set here, a prompt will be launch"
    echo "-s to append a copy of output to the given file"
    echo "-c used to enable cache"
    echo "-v used to print more informations"

    if [[ "$1" == "CURL" ]]; then
        echo "> CURL in command line is required"
    elif [[ "$1" != "" ]]; then
        echo "> Mandatory field: $1"
    fi
}

# Welcome message in prompt mode
function welcome ()
{
    echo "Welcome to the AWQL monitor. Commands end with ; or \g."
    echo "Your AWQL version: ${AWQL_API_VERSION}"
}

# Script usage & check if mysqldump is availabled
if [[ $# -lt 1 ]]; then
    usage
    exit 1
elif ! CURL_PATH="$(type -p curl)" || [[ -z "$CURL_PATH" ]]; then
    usage CURL
    exit 2
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "i::a::d::s:e:cv" FLAG; do
    case "${FLAG}" in
        i) ADWORDS_ID="$OPTARG" ;;
        a) ACCESS_TOKEN="$OPTARG" ;;
        d) DEVELOPER_TOKEN="$OPTARG" ;;
        e) QUERY="$OPTARG" ;;
        s) if [[ "${OPTARG:0:1}" = "/" ]]; then SAVE_FILE="$OPTARG"; else SAVE_FILE="${SCRIPT_ROOT}${OPTARG}"; fi ;;
        c) CACHING=1 ;;
        v) VERBOSE=1 ;;
        *) usage; exit 1 ;;
        ?) exit  ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [[ -z "$ADWORDS_ID" ]]; then
    usage ADWORDS_ID
    exit 2
else
    REQUEST=$(yamlToArray "${AWQL_CONF_DIR}/${AWQL_REQUEST_FILE_NAME}")
    if exitOnError $? "InternalError.INVALID_CONF_REQUEST" "$VERBOSE"; then
        return 1
    fi
fi

if [[ -z "$QUERY" ]]; then
    welcome
    while true; do
        read -e -p "$AWQL_PROMPT" QUERY
        awql "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$QUERY" "$SAVE_FILE" "$VERBOSE" "$CACHING"
    done
else
    awql "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$QUERY" "$SAVE_FILE" "$VERBOSE" "$CACHING"
fi