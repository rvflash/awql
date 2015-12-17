#!/usr/bin/env bash

# Refresh an authorization token for Google
# Require a CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN

# Envionnement
SCRIPT=$(basename ${BASH_SOURCE[0]})
SCRIPT_PATH="$0"; while [ -h "$SCRIPT_PATH" ]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
ROOT_DIR=$(dirname $SCRIPT_PATH)

# Requires
source "${ROOT_DIR}/../../conf/common.sh"

# Workspace
CLIENT_ID=""
CLIENT_SECRET=""
REFRESH_TOKEN=""

# Help
function usage ()
{
    echo "Usage: ${SCRIPT} -c clientid [-s clientsecret] [-r refreshtoken]"
    echo "-c for Google client ID"
    echo "-s for Google client secret"
    echo "-r for refresh token"

    if [ "$1" != "" ]; then
        echo "> Mandatory field: $1"
    fi
}

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "c:s:t:" FLAG; do
    case "${FLAG}" in
        c) CLIENT_ID="$OPTARG" ;;
        s) CLIENT_SECRET="$OPTARG" ;;
        t) REFRESH_TOKEN="$OPTARG" ;;
        *) usage; exit 1 ;;
        ?) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [ -z "$CLIENT_ID" ]; then
    usage CLIENT_ID
    exit 1
elif [ -z "$CLIENT_SECRET" ]; then
    usage CLIENT_SECRET
    exit 1
elif [ -z "$REFRESH_TOKEN" ]; then
    usage REFRESH_TOKEN
    exit 1
fi

yamlToArray "${ROOT_DIR}/conf/${REQUEST_FILE_NAME}"
    exitOnError $? "$ERR_MSG" "$VERBOSE"
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

if [ $? -ne 0 ]; then
    ERR_MSG="QueryError.INVALID_CONF_REQUEST"
    return 1
fi
REQUEST="$YAML_TO_ARRAY"

TOKEN_RESPONSE=$(curl -X "POST" \
		-d "client_id=$GOAUTH_CLIENT_ID" \
		-d "client_secret=$GOAUTH_CLIENT_SECRET" \
		-d "refresh_token=$REFRESH_TOKEN" \
		-d "grant_type=refresh_token" \
	$TOKEN_ENDPOINT 2>/dev/null`
	echo $TOKEN_RESPONSE

	function getTokenFromFile {
	if [ -f $TOKENFILE ]
		then
		TOKENFILESTR=`cat $TOKENFILE | tr "\n" " " | tr -d " "`
		TOKEN=`echo $TOKENFILESTR | sed $ESED "s/.*\"access_token\":\"([^\"]+)\".*/\1/"`
		REFRESH_TOKEN=`echo $TOKENFILESTR | sed $ESED "s/.*\"refresh_token\":\"([^\"]+)\".*/\1/"`
	fi
}

 date +"%s"

