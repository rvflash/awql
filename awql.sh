#!/usr/bin/env bash
#set -o nounset -o errexit -o pipefail -o errtrace

##
# Provide interface to request Google Adwords reports with AWQL queries
#
# @copyright 2015-2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/awql

# Environment
scriptPath="$0"; while [[ -h "$scriptPath" ]]; do scriptPath="$(readlink "$scriptPath")"; done
rootDir=$(dirname "$scriptPath")

# Import
source "${rootDir}/conf/awql.sh"
source "${AWQL_AUTH_DIR}/main.sh"

# Default values
declare -- adwordsId=""
declare -- accessToken=""
declare -- developerToken=""
declare -- query=""
declare -i cache=0
declare -i autoRehash=1
declare -i verbose=0
declare -- apiVersion="${AWQL_API_LAST_VERSION}"


##
# Returns list of API versions supported
# @return string
function versions ()
{
    echo -n $(scanDirectory "${AWQL_ADWORDS_DIR}" | sed -e "s/${AWQL_VIEWS_DIR_NAME}//g")
}

##
# Welcome message in prompt mode
# @param string $1 Api version
# @return string
function welcome ()
{
    local apiVersion="$1"

    echo "Welcome to the AWQL monitor. Commands end with ; or \g."
    echo "Your AWQL version: ${apiVersion}"
    echo
    echo "Reading table information for completion of table and column names."
    echo "You can turn off this feature to get a quicker startup with -A"
    echo
    echo "Type 'help;' or '\h' for help. Type '\c' to clear the current input statement."
}

##
# Help
# @param string $1 Error
# @return string
function usage ()
{
    local error="$1"

    echo "usage: awql -i adwordsId [-a accessToken] [-d developerToken] [-e query] [-V apiVersion] [-c] [-v] [-A]"
    echo "-i for Google Adwords account ID"
    echo "-a for Google Adwords access token"
    echo "-d for Google developer token"
    echo "-e for AWQL query, if not set here, a prompt will be launch"
    echo "-c used to enable cache"
    echo "-v used to print more information"
    echo "-A Disable automatic rehashing. This option is on by default, which enables table and column name completion"
    echo "-V Google API version, by default '${AWQL_API_LAST_VERSION}'"

    if [[ "$error" == "curl" ]]; then
        echo -e "\n> CURL in command line is required"
    elif [[ "$error" == "apiVersion" ]]; then
        echo -e "\n> Only supported versions of API: $(versions)"
    elif [[ -n "$error" ]]; then
        echo -e "\n> Mandatory field: $error"
    fi
}

# Script usage & check if curl is availabled
if [[ $# -lt 1 ]]; then
    usage
    exit 1
elif [[ -z "$(type -p curl)" ]]; then
    usage "curl"
    exit 2
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "i::a::d::s:e::V:cvA" FLAG; do
    case "${FLAG}" in
        i) adwordsId="$OPTARG" ;;
        a) accessToken="$OPTARG" ;;
        d) developerToken="$OPTARG" ;;
        e) query="$OPTARG" ;;
        c) cache=1 ;;
        v) verbose=0 ;;
        A) autoRehash=0 ;;
        V) apiVersion="$OPTARG" ;;
        *) usage; exit 1 ;;
        ?) exit  ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [[ -z "$adwordsId" ]]; then
    usage "adwordsId"
    exit 2
elif [[ -z "$apiVersion" || ! -d "${AWQL_ADWORDS_DIR}/${apiVersion}" ]]; then
    usage "apiVersion"
    exit 2
fi

# Launch process
if [[ -z "$query" ]]; then
    if [[ ${autoRehash} -eq 1 ]]; then
        source "${AWQL_INC_DIR}/complete.sh"
    fi
    source "${AWQL_INC_DIR}/read.sh"
    welcome "$apiVersion"

    while true; do
        awqlRead query ${autoRehash} "$apiVersion"
        awql "$query" "$apiVersion" "$adwordsId" "$accessToken" "$developerToken" ${cache} ${verbose}
    done
else
    awql "$query" "$apiVersion" "$adwordsId" "$accessToken" "$developerToken" ${cache} ${verbose} 1
fi