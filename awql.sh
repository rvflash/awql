#!/usr/bin/env bash

##
# Provide interface to request Google Adwords with AWQL queries

source inc.common.sh
source vendor/shcsv/cvs.sh

# Envionnement
getDirectoryPath "${BASH_SOURCE[0]}"
SCRIPT_ROOT="$DIRECTORY_PATH"
SCRIPT=`basename ${BASH_SOURCE[0]}`

# Default values
AWQL_FILE_PATH="${TMP_DIR}${CURDATE}_awql.csv"
AUTH_FILE_PATH="${SCRIPT_ROOT}${AUTH_FILE_NAME}"
ERR_FILE="/tmp/${CURDATE}_awql.err"
QUERY=""
VERBOSE=""

function usage ()
{
    echo "Usage: ${SCRIPT} -i adwordsid [-a authfilepath] [-f awqlfilename] [-e query] [-v]"
    echo "-i for Adwords account ID"
    echo "-a for yaml authorization file path with access and developper tokens"
    echo "-f for the name of the AWQL file (CSV format)"
    echo "-e for AWQL query, if not set here, a prompt will be launch"
    echo "-v used to print more informations"

    if [ "$1" != "" ]; then
        echo "> Mandatory field: $1"
    fi
}

##
# Get informations for authentification from yaml file
# @example ([ACCESS_TOKEN]="..." [DEVELOPER_TOKEN]="...")
# @return string AUTH with formated string for array bash from yaml file
function auth ()
{
    yamlToArray "$1"
    if [ $? -ne 0 ]; then
        return 1
    fi
    AUTH="$YAML_TO_ARRAY"
}

##
# Get informations for build Google Adwords request from Yaml file
# @example ([HOSTNAME]="..." [PATH]="..." [API_VERSION]="...")
# @return string REQUEST with formated string for array bash from Yaml file
function request ()
{
    yamlToArray "${SCRIPT_ROOT}${REQUEST_FILE_NAME}"
    if [ $? -ne 0 ]; then
        return 1
    fi
    REQUEST="$YAML_TO_ARRAY"
}

##
# Send a curl request to Adwords API to get response for AWQL query
# @param string $1 Adwords ID
# @param string $2 Awql query
# @param array $3 Google authentification tokens
# @param array $4 Google request properties
# @param array $5 Write into this file instead of stdout
# @param array $6 Verbose mode
# @param array $7 Log traceroute
# @return string ERR_MSG
# @return string REPORT
function report ()
{
    declare -A GOOGLE_AUTH="$3"
    declare -A GOOGLE_REQUEST="$4"

    local ADWORDS_ID="$1"
    local QUERY="$2"
    local OUTPUT_FILE="$5"
    local ERR_FILE="$7"
    local VERBOSE="$6"

    # Last check on query
    if [ -z "$QUERY" ]; then
        ERR_MSG="ReportDownloadError.MISSING_QUERY with API ${GOOGLE_REQUEST[API_VERSION]}"
        return 1
    fi

    # Define curl default properties
    local OPTIONS="--silent"
    if [ "$VERBOSE" != "" ] && [ "$ERR_FILE" != "" ]; then
        OPTIONS="$OPTIONS --trace-ascii ${ERR_FILE}"
    fi
    if [ "${GOOGLE_REQUEST[CONNECT_TIME_OUT]}" -gt 0 ]; then
        OPTIONS="$OPTIONS --connect-timeout ${GOOGLE_REQUEST[CONNECT_TIME_OUT]}"
    fi
    if [ "${GOOGLE_REQUEST[TIME_OUT]}" -gt 0 ]; then
        OPTIONS="$OPTIONS --max-time ${GOOGLE_REQUEST[TIME_OUT]}"
    fi

    # Send request to Google API Adwords
    local GOOGLE_URL="${GOOGLE_REQUEST[PROTOCOL]}://${GOOGLE_REQUEST[HOSTNAME]}${GOOGLE_REQUEST[PATH]}"
    local RESPONSE=$(curl \
        --request "${GOOGLE_REQUEST[METHOD]}" "$GOOGLE_URL${GOOGLE_REQUEST[API_VERSION]}" \
        --data-urlencode "${GOOGLE_REQUEST[RESPONSE_FORMAT]}=CSV" \
        --data-urlencode "${GOOGLE_REQUEST[AWQL_QUERY]}=$QUERY" \
        --header "${GOOGLE_REQUEST[AUTHORIZATION]}:${GOOGLE_REQUEST[TOKEN_TYPE]} ${GOOGLE_AUTH[ACCESS_TOKEN]}" \
        --header "${GOOGLE_REQUEST[DEVELOPER_TOKEN]}:${GOOGLE_AUTH[DEVELOPER_TOKEN]}" \
        --header "${GOOGLE_REQUEST[ADWORDS_ID]}:$ADWORDS_ID" \
        --output "$OUTPUT_FILE" \
        --write-out "([HTTP_CODE]=%{http_code} [TIME_TOTAL]='%{time_total}')" ${OPTIONS}
    )
    declare -A RESPONSE_INFO="$RESPONSE"

    if [ "${#RESPONSE_INFO[@]}" -ne 2 ] || [ "${RESPONSE_INFO[HTTP_CODE]}" -eq 0 ] || [ "${RESPONSE_INFO[HTTP_CODE]}" -gt 400 ]; then
        # A fatal error occured
        exitOnError 1 "Unable to get response from Google API ${GOOGLE_REQUEST[API_VERSION]}" "$VERBOSE" "$ERR_FILE"
    elif [ "${RESPONSE_INFO[HTTP_CODE]}" -gt 300 ]; then
        # An error occured, extract type and others informations from XML response
        ERR_TYPE=$(awk -F 'type>|<\/type' '{print $2}' "$OUTPUT_FILE")
        ERR_FIELD=$(awk -F 'fieldPath>|<\/fieldPath' '{print $2}' "$OUTPUT_FILE")
        if [ "$ERR_FIELD" != "" ]; then
            ERR_MSG="$ERR_TYPE regarding field(s) named $ERR_FIELD"
        fi
        ERR_MSG="$ERR_TYPE with API ${GOOGLE_REQUEST[API_VERSION]}"
        return 1
    else
        # Format CSV in order to improve re-using by removing first and last line
        sed -i -e '$d; 1d' "$OUTPUT_FILE"

        # Check length of the response
        local RESPONSE_SIZE=$(wc -l < "$OUTPUT_FILE")
        if [ "$RESPONSE_SIZE" -gt 1 ]; then
            REPORT=$(csvToPrintableArray "$OUTPUT_FILE")
        fi

        # Add informations about context of the query (time duration & number of lines)
        # @example 2 rows in set (0.93 sec)
        if [ "$RESPONSE_SIZE" -lt 2 ]; then
            REPORT_INFO="Empty set"
        elif [ "$RESPONSE_SIZE" -eq 3 ]; then
            REPORT_INFO="1 row in set"
        else
            REPORT_INFO="$(($RESPONSE_SIZE-1)) rows in set"
        fi
        REPORT_INFO="$REPORT_INFO (${RESPONSE_INFO[TIME_TOTAL]} sec)"
        REPORT="${REPORT}\n${REPORT_INFO}"
    fi
}

##
# Build a call to Google Adwords and retrieve report for the AWQL query
# @param string $1 Adwords ID
# @param string $2 Query
# @param string $3 Yaml authenfication filepath
# @param string $4 Awql filepath to store response
# @param string $5 Verbose mode
# @param string $6 Error filepath
function awql ()
{
    local ADWORDS_ID=$1
    local QUERY=$2
    local AUTH_PATH=$3
    local OUTPUT_FILE=$4
    local VERBOSE=$5
    local ERR_FILE=$6

    # Google tokens
    auth "$AUTH_PATH"
    exitOnError $? "Unable to load authenfication file: $AUTH_PATH" "$VERBOSE" "$ERR_FILE"

    # Google request
    request
    exitOnError $? "Unable to get request's configuration" "$VERBOSE" "$ERR_FILE"

    # Send request to Adwords to get report
    report "$ADWORDS_ID" "$QUERY" "$AUTH" "$REQUEST" "$OUTPUT_FILE" "$VERBOSE" "$ERR_FILE"
    if [ $? -gt 0 ]; then
        echo "$ERR_MSG"
    else
        echo -e "$REPORT"
    fi
}

# Script usage & check if mysqldump is availabled
if [ $# -lt 1 ] ; then
    usage
    exit 1
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "i::a::f::e:v" FLAG; do
    case "${FLAG}" in
        i) ADWORDS_ID="$OPTARG" ;;
        a) if [ "$OPTARG" != "" ]; then AUTH_FILE_PATH="$OPTARG"; fi ;;
        f) if [ "$OPTARG" != "" ]; then AWQL_FILE_PATH="$OPTARG"; fi ;;
        e) QUERY="$OPTARG" ;;
        v) VERBOSE="-v" ;;
        *) usage; exit 1 ;;
        ?) exit  ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [ -z "$ADWORDS_ID" ]; then
    usage ADWORDS_ID
    exit 2
fi

if [ -z "$QUERY" ]; then
    while true; do
        read -p "> " QUERY
        awql "$ADWORDS_ID" "$QUERY" "$AUTH_FILE_PATH" "$AWQL_FILE_PATH" "$VERBOSE" "$ERR_FILE"
    done
else
    awql "$ADWORDS_ID" "$QUERY" "$AUTH_FILE_PATH" "$AWQL_FILE_PATH" "$VERBOSE" "$ERR_FILE"
fi