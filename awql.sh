#!/usr/bin/env bash

##
# Provide interface to request Google Adwords with AWQL queries

source inc.common.sh

# Envionnement
getDirectoryPath "${BASH_SOURCE[0]}"
SCRIPT_ROOT="$DIRECTORY_PATH"
SCRIPT=$(basename ${BASH_SOURCE[0]})
mkdir -p "$WRK_DIR"

# Default values
AUTH_FILE="${SCRIPT_ROOT}${AUTH_FILE_NAME}"
AWQL_FILE=""
QUERY=""
VERBOSE=0

function usage ()
{
    echo "Usage: ${SCRIPT} -i adwordsid [-a authfilepath] [-f awqlfilename] [-e query] [-v]"
    echo "-i for Adwords account ID"
    echo "-a for Yaml authorization file path with access and developper tokens"
    echo "-f for the filepath to save raw AWQL response"
    echo "-e for AWQL query, if not set here, a prompt will be launch"
    echo "-v used to print more informations"

    if [ "$1" != "" ]; then
        echo "> Mandatory field: $1"
    fi
}

##
# Get informations for authentification from yaml file
# @example ([ACCESS_TOKEN]="..." [DEVELOPER_TOKEN]="...")
# @return string ERR_MSG in case of return code greater than 0
# @return string AUTH with formated string for array bash from yaml file
function auth ()
{
    yamlToArray "$1"
    if [ $? -ne 0 ]; then
        ERR_MSG="AuthenticationError.FILE_INVALID"
        return 1
    fi
    AUTH="$YAML_TO_ARRAY"
}

##
# Build a call to Google Adwords and retrieve report for the AWQL query
# @param string $1 Adwords ID
# @param string $2 Query
# @param string $3 Yaml authenfication filepath
# @param string $4 Awql filepath to store response
# @param string $5 Verbose mode
function awql ()
{
    local ADWORDS_ID=$1
    local QUERY=$2
    local AUTH_PATH=$3
    local AWQL_FILE=$4
    local VERBOSE=$5

    # Get a query validated and manage query limits
    checkQuery "$QUERY"
    exitOnError $? "$ERR_MSG" "$VERBOSE"

    # Calculate a checksum for this query (usefull for unique identifier)
    checksum "$ADWORDS_ID $QUERY"

    # Retrieve Google tokens
    auth "$AUTH_PATH"
    exitOnError $? "$ERR_MSG" "$VERBOSE"

    # Get Google request prperties
    request
    exitOnError $? "$ERR_MSG" "$VERBOSE"

    # Send request to Adwords or local cache to get report
    call "$ADWORDS_ID" "$QUERY" "$AUTH" "$REQUEST" "$CHECKSUM"
    local ERR_TYPE="$?"

    if [ "$ERR_TYPE" -ne 0 ]; then
        exitOnError "$ERR_TYPE" "$ERR_MSG" "$VERBOSE"
    else
        # Save response in an dedicated file
        if [ "$AWQL_FILE" != "" ]; then
            cp "$OUTPUT_FILE" "$AWQL_FILE"
            exitOnError $? "FileError.UNABLE_TO_SAVE" "$VERBOSE"
        fi

        # Print response
        print "$OUTPUT_FILE" "$OUTPUT_CACHED" "$TIME_DURATION" "$LIMIT_QUERY" "$VERBOSE"
    fi
}

##
# Get data from cache if available
# @param string $1 Query checksum
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
function cached ()
{
    local CHECKSUM="$1"

    OUTPUT_FILE="${WRK_DIR}${CHECKSUM}${AWQL_FILE_EXT}"

    if [ -z "$CHECKSUM" ]; then
        ERR_MSG="ReportDownloadError.INVALID_CACHE"
        return 1
    elif [ ! -f "$OUTPUT_FILE" ]; then
        ERR_MSG="ReportDownloadError.UNKNOWN_CACHE"
        return 1
    fi
}

##
# Fetch cache or send request to Adwords
# @param string $1 Adwords ID
# @param string $2 Awql query
# @param array $3 Google authentification tokens
# @param array $4 Google request properties
# @param array $5 Query checksum
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
# @return bool OUTPUT_CACHED if 1, datas from local cache
function call ()
{
    cached "$5"
    if [ $? -gt 0 ]; then
        download "$1" "$2" "$3" "$4" "$5"
        local ERR_TYPE="$?"
        if [ ${ERR_TYPE} -ne 0 ]; then
            # An error occured, remove cache file
            rm -f "${WRK_DIR}${5}${AWQL_FILE_EXT}"
            return ${ERR_TYPE}
        fi
    else
        OUTPUT_CACHED=1
    fi
}
##
# Check query to verify structure & limits
# @param string $1 Query
# @return string ERR_MSG in case of return code greater than 0
# @return string QUERY
# @return stringableArray LIMIT_QUERY
function checkQuery ()
{
    QUERY="$1"
    LIMIT_QUERY="()"

    local QUERY_ORIGIN="$QUERY"
    local QUERY_METHOD=$(echo "$QUERY" | awk '{ print tolower($1) }')

    if [ -z "$QUERY" ]; then
        ERR_MSG="ReportDownloadError.MISSING_QUERY"
        return 1
    elif [ "$QUERY_METHOD" != "select" ]; then
        ERR_MSG="ReportDownloadError.INVALID_QUERY_METHOD"
        return 1
    fi

    # Adwords does not accept LIMIT on daily reports
    if [[ "$QUERY" == *"_REPORT"* ]]; then
        QUERY=$(echo "$QUERY" | sed -e "s/[Ll][Ii][Mm][Ii][Tt] \([0-9;, ]*\)$//g")
        # Increment limits to manage header
        local LIMIT="${QUERY_ORIGIN:${#QUERY}}"
        if [ "${#LIMIT}" -gt 0 ]; then
            LIMIT_QUERY="($(echo "$LIMIT" | sed 's/[^0-9,]*//g' | sed 's/,/ /g'))"
        fi
    fi
}

##
# Add informations about context of the query (time duration & number of lines)
# @example 2 rows in set (0.93 sec)
# @param string $1 AWQL filepath
# @param int $2 Number of line
# @param float $3 Time duration in milliseconds
# @param bool $4 If 1, data source is cached
# @param string $5 Verbose mode
# @return string CONTEXT
function context ()
{
    local FILE_PATH="$1"
    local FILE_SIZE="$2"
    local TIME_DURATION="$3"
    local CACHED="$4"
    local VERBOSE="$5"

    # Size
    if [ "$FILE_SIZE" -lt 2 ]; then
        CONTEXT="Empty set"
    elif [ "$FILE_SIZE" -eq 2 ]; then
        CONTEXT="1 row in set"
    else
        CONTEXT="$(($FILE_SIZE-1)) rows in set"
    fi
    # Time duration
    if [ "$TIME_DURATION" != "" ]; then
        CONTEXT="$CONTEXT ($TIME_DURATION sec)"
    fi
    if [ "$VERBOSE" -eq 1 ]; then
        # Source
        if [ -f "$FILE_PATH" ]; then
            CONTEXT="$CONTEXT @source $FILE_PATH"
        fi
        # From cache ?
        if [ "$CACHED" -eq 1 ]; then
            CONTEXT="$CONTEXT @cached"
        fi
    fi
    echo -en "$CONTEXT\n"
}

##
# Send a curl request to Adwords API to get response for AWQL query
# @param string $1 Adwords ID
# @param string $2 Awql query
# @param array $3 Google authentification tokens
# @param array $4 Google request properties
# @param array $5 Query checksum
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
# @retrun string TIME_DURATION Time duration in milliseconds
function download ()
{
    declare -A GOOGLE_AUTH="$3"
    declare -A GOOGLE_REQUEST="$4"

    local ADWORDS_ID="$1"
    local QUERY="$2"
    local OUTPUT_FILE="${WRK_DIR}${CHECKSUM}${AWQL_FILE_EXT}"

    # Define curl default properties
    local OPTIONS="--silent"
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

    if [ "${RESPONSE_INFO[HTTP_CODE]}" -eq 0 ] || [ "${RESPONSE_INFO[HTTP_CODE]}" -gt 400 ]; then
        ERR_MSG="ConnexionError.NOT_FOUND with API ${GOOGLE_REQUEST[API_VERSION]}"
        return 1
    elif [ "${RESPONSE_INFO[HTTP_CODE]}" -gt 300 ]; then
        # An error occured, extract type and others informations from XML response
        ERR_TYPE=$(awk -F 'type>|<\/type' '{print $2}' "$OUTPUT_FILE")
        ERR_FIELD=$(awk -F 'fieldPath>|<\/fieldPath' '{print $2}' "$OUTPUT_FILE")
        if [ "$ERR_FIELD" != "" ]; then
            ERR_MSG="$ERR_TYPE regarding field(s) named $ERR_FIELD"
        fi
        ERR_MSG="$ERR_TYPE with API ${GOOGLE_REQUEST[API_VERSION]}"

        # Except for authentification errors, do not exit
        if [[ "$ERR_TYPE"  == "AuthenticationError"* ]]; then
            return 1
        fi
        return 2
    else
        # Format CSV in order to improve re-using by removing first and last line
        sed -i -e '$d; 1d' "$OUTPUT_FILE"
        TIME_DURATION="${RESPONSE_INFO[TIME_TOTAL]}"
    fi
}

## Show response & info about it
# @param string $1 Raw CSV file path
# @param bool $2 Cached data
# @param float $3 Time duration to fetch response
# @param stringableArray $4 Limit to apply on response
# @param string $5 Verbose mode
#
function print ()
{
    local WRK_FILE="$1"
    local WRK_PRINTABLE_FILE="${WRK_FILE/.awql/.pcsv}"
    local FILE_SIZE=$(wc -l < "$WRK_FILE")
    local TIME_DURATION="$3"
    local CACHED="$2"
    local VERBOSE="$5"

    declare -a LIMIT_QUERY="$4"
    local LIMIT_QUERY_SIZE="${#LIMIT_QUERY[@]}"

    if [ "$FILE_SIZE" -gt 1 ]; then
        if [ "$LIMIT_QUERY_SIZE" -eq 1 ] || [ "$LIMIT_QUERY_SIZE" -eq 2 ]; then
            # Limit size of datas to display (@see limit Adwords on daily report)
            local LIMITS="${LIMIT_QUERY[@]}"
            local WRK_PARTIAL_FILE="${WRK_FILE/.awql/_${LIMITS/ /-}.awql}"

            # Keep only first line for column names and lines in bounces
            if [ "$LIMIT_QUERY_SIZE" -eq 2 ]; then
                LIMITS="$((${LIMIT_QUERY[0]}+1)),$((${LIMIT_QUERY[0]}+${LIMIT_QUERY[1]}))"
                FILE_SIZE="${LIMIT_QUERY[1]}"
                sed -n -e 1p -e "${LIMITS}p" "$WRK_FILE" > "$WRK_PARTIAL_FILE"
            else
                LIMITS="1,$((${LIMIT_QUERY[0]}+1))"
                FILE_SIZE="${LIMIT_QUERY[0]}"
                sed -n -e "${LIMITS}p" "$WRK_FILE" > "$WRK_PARTIAL_FILE"
            fi
            WRK_FILE="$WRK_PARTIAL_FILE"
            FILE_SIZE="$((${FILE_SIZE}+1))"
        fi

        # Format CVS to print it in shell terminal
        $(vendor/shcsv/csv.sh -f "$WRK_FILE" -t "$WRK_PRINTABLE_FILE" -q)
        cat "$WRK_PRINTABLE_FILE"
    fi
    # Add context (file size, time duration, etc.)
    context "$WRK_FILE" "$FILE_SIZE" "$TIME_DURATION" "$CACHED" "$VERBOSE"
}
##
# Get informations for build Google Adwords request from Yaml file
# @example ([HOSTNAME]="..." [PATH]="..." [API_VERSION]="...")
# @return string REQUEST with formated string for array bash from Yaml file
function request ()
{
    yamlToArray "${SCRIPT_ROOT}${REQUEST_FILE_NAME}"
    if [ $? -ne 0 ]; then
        ERR_MSG="QueryError.INVALID_REQUEST"
        return 1
    fi
    REQUEST="$YAML_TO_ARRAY"
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
        a) if [ "${OPTARG:0:1}" = "/" ]; then AUTH_FILE="$OPTARG"; else AUTH_FILE="${SCRIPT_ROOT}${OPTARG}"; fi ;;
        f) if [ "${OPTARG:0:1}" = "/" ]; then AWQL_FILE="$OPTARG"; else AWQL_FILE="${SCRIPT_ROOT}${OPTARG}"; fi ;;
        e) QUERY="$OPTARG" ;;
        v) VERBOSE=1 ;;
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
        awql "$ADWORDS_ID" "$QUERY" "$AUTH_FILE" "$AWQL_FILE" "$VERBOSE"
    done
else
    awql "$ADWORDS_ID" "$QUERY" "$AUTH_FILE" "$AWQL_FILE" "$VERBOSE"
fi