#!/usr/bin/env bash
#set -o nounset -o errexit -o pipefail -o errtrace

##
# Provide interface to request Google Adwords reports with AWQL queries
#
# @copyright 2015-2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/awql

# Envionnement
SCRIPT_PATH="$0"; while [[ -h "$SCRIPT_PATH" ]]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
SCRIPT_ROOT=$(dirname "$SCRIPT_PATH")

# Import
source "${SCRIPT_ROOT}/conf/awql.sh"
source "${AWQL_BASH_PACKAGES_DIR}/array.sh"
source "${AWQL_BASH_PACKAGES_DIR}/file.sh"
source "${AWQL_BASH_PACKAGES_DIR}/term.sh"
source "${AWQL_BASH_PACKAGES_DIR}/encoding/yaml.sh"
source "${AWQL_BASH_PACKAGES_DIR}/strings.sh"
source "${AWQL_INC_DIR}/common.sh"
source "${AWQL_INC_DIR}/awql.sh"
source "${AWQL_INC_DIR}/print.sh"
source "${AWQL_INC_DIR}/query.sh"
source "${AWQL_AUTH_DIR}/auth.sh"

# Default values
ADWORDS_ID=""
ACCESS_TOKEN=""
DEVELOPER_TOKEN=""
QUERY=""
SAVE_FILE=""
CACHING=0
VERBOSE=0
AUTO_REHASH=1
API_VERSION="${AWQL_API_LAST_VERSION}"

##
# Returns list of API versions supported
# @return string
function versions ()
{
    echo -n $(ls -d "${AWQL_ADWORDS_DIR}/"* | sed -n -e 's/^.*\///p')
}

##
# Help
# @return string
function usage ()
{
    local ERROR_NAME="$1"

    echo "Usage: awql -i adwordsid [-a accesstoken] [-d developertoken] [-e query] [-s savefilepath] [-V apiversion] [-c] [-v] [-A]"
    echo "-i for Google Adwords account ID"
    echo "-a for Google Adwords access token"
    echo "-d for Google developer token"
    echo "-e for AWQL query, if not set here, a prompt will be launch"
    echo "-s to append a copy of output to the given file"
    echo "-c used to enable cache"
    echo "-v used to print more informations"
    echo "-A Disable automatic rehashing. This option is on by default, which enables table and column name completion"
    echo "-V Google API version, by default ${AWQL_API_LAST_VERSION}"

    if [[ "${ERROR_NAME}" == "CURL" ]]; then
        echo "> CURL in command line is required"
    elif [[ "${ERROR_NAME}" == "API_VERSION" ]]; then
        echo "> Only supported versions of API: $(versions)"
    elif [[ -n "${ERROR_NAME}" ]]; then
        echo "> Mandatory field: ${ERROR_NAME}"
    fi
}

##
# Welcome message in prompt mode
# @return string
function welcome ()
{
    local API_VERSION="$1"

    echo "Welcome to the AWQL monitor. Commands end with ; or \g."
    echo "Your AWQL version: ${API_VERSION}"
    echo
    echo "Reading table information for completion of table and column names."
    echo "You can turn off this feature to get a quicker startup with -A"
    echo
    echo "Type 'help;' or '\h' for help. Type '\c' to clear the current input statement."
}

# Script usage & check if mysqldump is availabled
if [[ $# -lt 1 ]]; then
    usage
    exit 1
elif ! CURL_PATH="$(type -p curl)" || [[ -z "$CURL_PATH" ]]; then
    usage "CURL"
    exit 2
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "i::a::d::s:e::V:cvA" FLAG; do
    case "${FLAG}" in
        i) ADWORDS_ID="$OPTARG" ;;
        a) ACCESS_TOKEN="$OPTARG" ;;
        d) DEVELOPER_TOKEN="$OPTARG" ;;
        e) QUERY="$OPTARG" ;;
        s) if [[ "${OPTARG:0:1}" = "/" ]]; then SAVE_FILE="$OPTARG"; else SAVE_FILE="${SCRIPT_ROOT}${OPTARG}"; fi ;;
        c) CACHING=1 ;;
        v) VERBOSE=1 ;;
        A) AUTO_REHASH=0 ;;
        V) API_VERSION="$OPTARG" ;;
        *) usage; exit 1 ;;
        ?) exit  ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [[ -z "${ADWORDS_ID}" ]]; then
    usage "ADWORDS_ID"
    exit 2
elif [[ ! -d "${AWQL_ADWORDS_DIR}/${API_VERSION}" ]]; then
    usage "API_VERSION"
    exit 2
else
    # Retrieve Google request configuration
    REQUEST=$(yamlFileDecode "${AWQL_CONF_DIR}/${AWQL_REQUEST_FILE_NAME}")
    if exitOnError "$?" "InternalError.INVALID_CONFIG_FOR_REQUEST" "$VERBOSE"; then
        return 1
    fi

    # Only keep the last N queries in history
    if [[ -f "$AWQL_HISTORY_FILE" && "$(wc -l < "$AWQL_HISTORY_FILE")" -gt ${AWQL_HISTORY_SIZE} ]]; then
        tail -n ${AWQL_HISTORY_SIZE} "$AWQL_HISTORY_FILE" > "${AWQL_HISTORY_FILE}-e"
        if [[ $? -eq 0 ]]; then
            mv "${AWQL_HISTORY_FILE}-e" "${AWQL_HISTORY_FILE}"
        fi
    fi
fi

if [[ -z "$QUERY" ]]; then
    # Import complete and read packages
    if [[ ${AUTO_REHASH} -eq 1 ]]; then
        source "${AWQL_INC_DIR}/completion.sh"
    fi
    source "${AWQL_INC_DIR}/reader.sh"

    welcome "${API_VERSION}"
    while true; do
        awqlRead "$AUTO_REHASH" "$API_VERSION" "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$REQUEST" "$SAVE_FILE" "$VERBOSE" "$CACHING"
    done
else
    awql "$QUERY" "$API_VERSION" "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$REQUEST" "$SAVE_FILE" "$VERBOSE" "$CACHING"
fi