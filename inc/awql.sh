#!/usr/bin/env bash

##
# Get all field names with for each, their description
# @example ([AccountDescriptiveName]="The descriptive name...")
function awqlExtra ()
{
    local AWQL

    AWQL=$(yamlToArray "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_EXTRA_FILE_NAME}")
    if [[ $? -ne 0 ]]; then
        echo "InternalError.INVALID_AWQL_EXTRA_FIELDS"
        return 1
    fi

    echo -n "$AWQL"
}

##
# Get all fields names with for each, the type of data
# @example ([AccountDescriptiveName]="String")
function awqlFields ()
{
    local AWQL

    AWQL=$(yamlToArray "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_FIELDS_FILE_NAME}")
    if [[ $? -ne 0 ]]; then
        echo "InternalError.INVALID_AWQL_FIELDS"
        return 1
    fi

    echo -n "$AWQL"
}

##
# Get all table names with for each, their structuring keys
# @example ([PRODUCT_PARTITION_REPORT]="ClickType Date...")
function awqlKeys ()
{
    local AWQL

    AWQL=$(yamlToArray "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_KEYS_FILE_NAME}")
    if [[ $? -ne 0 ]]; then
        echo "InternalError.INVALID_AWQL_KEYS"
        return 1
    fi

    echo -n "$AWQL"
}

##
# Get all table names with for each, the list of their fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
function awqlTables ()
{
    local AWQL

    AWQL=$(yamlToArray "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_TABLES_FILE_NAME}")
    if [[ $? -ne 0 ]]; then
        echo "InternalError.INVALID_AWQL_TABLES"
        return 1
    fi

    echo -n "$AWQL"
}

##
# Get data from cache if available
# @param string $1 FilePath
# @param string $2 Caching enabled
function getFromCache ()
{
    local FILE="$1"
    local CACHING="$2"

    if [[ "$CACHING" -eq 0 ]]; then
        echo "CacheError.DISABLED"
        return 1
    elif [[ ! -f "$FILE" ]]; then
        echo "CacheError.UNKNOWN_KEY"
        return 1
    fi

    echo -n "([FILE]=\"${FILE}\" [CACHED]=1)"
}

##
# Fetch internal cache or send request to Adwords to get results
# @param string $1 Adwords ID
# @param stringableArray $2 Request
# @param array $3 Google authentification tokens
# @param array $4 Google request properties
# @param array $5 Verbose mode
# @param array $6 Enable caching
function get ()
{
    # In
    local ADWORDS_ID="$1"
    declare -A REQUEST="$2"
    local AUTH="$3"
    local SERVER="$4"
    local VERBOSE="$5"
    local CACHING="$6"

    # Out
    local FILE="${AWQL_WRK_DIR}/${REQUEST[CHECKSUM]}${AWQL_FILE_EXT}"

    # Overload caching mode for local database AWQL methods
    if [[ "${REQUEST[METHOD]}" != ${AWQL_QUERY_SELECT} ]]; then
        CACHING=1
    fi

    local RESPONSE=""
    RESPONSE=$(getFromCache "$FILE" "$CACHING")
    local ERR_TYPE=$?
    if [[ "$ERR_TYPE" -ne 0 ]]; then
        case "${REQUEST[METHOD]}" in
            ${AWQL_QUERY_SELECT})
                source "${AWQL_INC_DIR}/awql_select.sh"
                RESPONSE=$(awqlSelect "$ADWORDS_ID" "$AUTH" "$SERVER" "${REQUEST[QUERY]}" "$FILE" "$VERBOSE")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_DESC})
                source "${AWQL_INC_DIR}/awql_desc.sh"
                RESPONSE=$(awqlDesc "${REQUEST[QUERY]}" "$FILE")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_SHOW})
                source "${AWQL_INC_DIR}/awql_show.sh"
                RESPONSE=$(awqlShow "${REQUEST[QUERY]}" "$FILE")
                ERR_TYPE=$?
                ;;
            *)
                RESPONSE="QueryError.UNKNOWN_AWQL_METHOD"
                ERR_TYPE=2
                ;;
        esac

        # An error occured, remove cache file and return with error code
        if [[ "$ERR_TYPE" -ne 0 ]]; then
            # @see command protected by /dev/null exit
            if [[ -z "$RESPONSE" ]]; then
                RESPONSE="QueryError.AWQL_SYNTAX_ERROR"
                ERR_TYPE=2
            fi
            rm -f "$FILE"
        fi
    fi

    echo "$RESPONSE"

    return "$ERR_TYPE"
}


##
# Build a call to Google Adwords and retrieve report for the AWQL query
# @param string $1 ADWORDS_ID
# @param string $2 ACCESS_TOKEN
# @param string $3 DEVELOPER_TOKEN
# @param string $4 QUERY
# @param string $5 SAVE_FILE
# @param int $6 CACHING
# @param int $7 VERBOSE
function awql ()
{
    local ADWORDS_ID="$1"
    local ACCESS_TOKEN="$2"
    local DEVELOPER_TOKEN="$3"
    local QUERY="$4"
    local SAVE_FILE="$5"
    local VERBOSE="$6"
    local CACHING="$7"

    # Prepare and validate query, manage all extended behaviors to AWQL basics
    QUERY=$(query "$ADWORDS_ID" "$QUERY")
    if exitOnError "$?" "$QUERY" "$VERBOSE"; then
        return
    fi

    # Retrieve Google tokens (only if HTTP call is needed)
    local AUTH=""
    if [[ "$QUERY" == *"\"select\""* ]]; then
        AUTH=$(auth "$ACCESS_TOKEN" "$DEVELOPER_TOKEN")
        if exitOnError "$?" "$AUTH" "$VERBOSE"; then
            return
        fi
    fi

    # Send request to Adwords or local cache to get report
    local RESPONSE=""
    RESPONSE=$(get "$ADWORDS_ID" "$QUERY" "$AUTH" "$REQUEST" "$VERBOSE" "$CACHING")
    if exitOnError "$?" "$RESPONSE" "$VERBOSE"; then
        return
    fi

    # Print response
    print "$QUERY" "$RESPONSE" "$SAVE_FILE" "$VERBOSE"
}
