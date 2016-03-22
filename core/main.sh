#!/usr/bin/env bash

##
# Get data from cache if available
# @param string $1 FilePath
# @param string $2 Caching enabled
# @return string
# @returnStatus 1 If data is not cached
function getFromCache ()
{
    local file="$1"
    declare -i cache="$2"

    if [[ ${cache} -eq 0 ]]; then
        echo "CacheError.DISABLED"
        return 1
    elif [[ -z "$file" || ! -f "$file" ]]; then
        echo "CacheError.UNKNOWN_KEY"
        return 1
    fi

    echo -n "([FILE]=\"${file}\" [CACHED]=1)"
}

##
# Fetch internal cache or send request to Adwords to get results
# @param arrayToString $1 User request
# @param arrayToString $2 Google authentification tokens
# @param arrayToString $3 Google request properties
# @param string
# @returnStatus 2 If query is invalid
# @returnStatus 1 If case of fatal error
function get ()
{
    # In
    declare -A request="$1"
    local auth="$2"
    local server="$3"

    # Out
    local file="${AWQL_WRK_DIR}/${request['CHECKSUM']}${AWQL_FILE_EXT}"

    # Overload caching mode for local database AWQL methods
    declare -i cache=${request['CACHING']}
    if [[ "${request['METHOD']}" != ${AWQL_QUERY_SELECT} ]]; then
        cache=1
    fi

    local response
    response=$(getFromCache "$file" "$cache")
    declare -i errType=$?
    if [[ ${errType} -ne 0 ]]; then
        case "${request['METHOD']}" in
            ${AWQL_QUERY_SELECT})
                includeOnce "${AWQL_INC_DIR}/awql_select.sh"
                response=$(awqlSelect "${request['QUERY']}" "$file" "${request['API_VERSION']}" "${request['ADWORDS_ID']}" "$auth" "$server" "${request['VERBOSE']}")
                errType=$?
                ;;
            ${AWQL_QUERY_DESC})
                includeOnce "${AWQL_INC_DIR}/awql_desc.sh"
                response=$(awqlDesc "${request['QUERY']}" "$file" "${request['API_VERSION']}")
                errType=$?
                ;;
            ${AWQL_QUERY_SHOW})
                includeOnce "${AWQL_INC_DIR}/awql_show.sh"
                response=$(awqlShow "${request['QUERY']}" "$file" "${request['API_VERSION']}")
                errType=$?
                ;;
            *)
                response="QueryError.UNKNOWN_AWQL_METHOD"
                errType=2
                ;;
        esac

        # An error occured, remove cache file and return with error code
        if [[ ${errType} -ne 0 ]]; then
            # @see command protected by /dev/null exit
            if [[ -z "$response" ]]; then
                response="QueryError.AWQL_SYNTAX_ERROR"
                errType=2
            fi
            rm -f "$file"
        fi
    fi

    echo "$response"

    return ${errType}
}

##
# Build a call to Google Adwords and retrieve report for the AWQL query
# @param string $1 Query
# @param string $2 Api version
# @param string $3 Adwords ID
# @param string $4 Google Access Token
# @param string $5 Google Developer Token
# @param arrayToString $6 Google request configuration
# @param int $7 Caching mode
# @param string
# @returnStatus 1 If query is invalid
function awql ()
{
    local query="$1"
    local apiVersion="$2"
    local adwordsId="$3"
    local accessToken="$4"
    local developerToken="$5"
    local request="$6"
    declare -i cache="$7"
query "$adwordsId" "$query" "$apiVersion" "$verbose" "$cache"
exit
    # Prepare and validate query, manage all extended behaviors to AWQL basics
    query=$(query "$adwordsId" "$query" "$apiVersion" "$cache")
    if [[ $? -gt 0 ]]; then
        echo "$query"
        if [[ $? -eq 1 ]]; then
            exit 1
        elif [[ $? -gt 1 ]]; then
            return 1
        fi
    fi

    # Retrieve Google tokens (only if HTTP call is needed)
    local auth
    if [[ "$query" == *"\"select\""* ]]; then
        auth=$(auth "$accessToken" "$developerToken")
        if [[ $? -gt 0 ]]; then
            echo "$auth"
            if [[ $? -eq 1 ]]; then
                exit 1
            elif [[ $? -gt 1 ]]; then
                return 1
            fi
        fi
    fi

    # Send request to Adwords or local cache to get report
    local response
    response=$(get "$query" "$auth" "$request")
    if [[ $? -gt 0 ]]; then
        echo "$response"
        if [[ $? -eq 1 ]]; then
            exit 1
        elif [[ $? -gt 1 ]]; then
            return 1
        fi
    fi

    # Print response
    print "$query" "$response"
}

##
# Read user prompt to retrieve AWQL query.
# Enable up and down arrow keys to navigate in history of queries.
# @param string $1 Auto rehash for completion
# @param string $2 Api version
# @param string $3 Adwords ID
# @param string $4 Google Access Token
# @param string $5 Google Developer Token
# @param arrayToString $6 Google request configuration
# @param int $7 Caching mode
# @param string
# @returnStatus 1 If query is invalid
function awqlRead ()
{
    declare -i autoRehash="$1"
    local apiVersion="$2"
    local adwordsId="$3"
    local accessToken="$4"
    local developerToken="$5"
    local request="$6"
    declare -i cache="$7"

    # Open a prompt (with auto-completion ?)
    local queryStr
    reader queryStr "$autoRehash" "$apiVersion"

    # Process query
    awql "$queryStr" "$apiVersion" "$adwordsId" "$accessToken" "$developerToken" "$request" "$cache"
}