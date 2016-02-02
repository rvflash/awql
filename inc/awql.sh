#!/usr/bin/env bash

declare AWQL_EXTRA AWQL_FIELDS AWQL_BLACKLISTED_FIELDS AWQL_UNCOMPATIBLE_FIELDS AWQL_KEYS AWQL_TABLES AWQL_TABLES_TYPE

##
# Get all field names with for each, their description
# @example ([AccountDescriptiveName]="The descriptive name...")
# @use AWQL_EXTRA
function awqlExtra ()
{
    if [[ -z "$AWQL_EXTRA" ]]; then
        AWQL_EXTRA=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_EXTRA_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_EXTRA_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_EXTRA"
}

##
# Get all fields names with for each, the type of data
# @example ([AccountDescriptiveName]="String")
# @use AWQL_FIELDS
function awqlFields ()
{
    if [[ -z "$AWQL_FIELDS" ]]; then
        AWQL_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_FIELDS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_FIELDS"
}

##
# Get all table names with for each, the list of their blacklisted fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
# @use AWQL_BLACKLISTED_FIELDS
function awqlBlacklistedFields ()
{
    if [[ -z "$AWQL_BLACKLISTED_FIELDS" ]]; then
        AWQL_BLACKLISTED_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_BLACKLISTED_FIELDS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_BLACKLISTED_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_BLACKLISTED_FIELDS"
}

##
# Get all fields names with for each, the list of their incompatible fields
# @example ([AccountDescriptiveName]="Hour")
# @use AWQL_UNCOMPATIBLE_FIELDS
function awqlUncompatibleFields ()
{
    local TABLE="$1"

    if [[ -z "$AWQL_UNCOMPATIBLE_FIELDS" ]]; then
        AWQL_UNCOMPATIBLE_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_COMPATIBILITY_DIR_NAME}/${TABLE}.yaml")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_UNCOMPATIBLE_FIELDS"
            return 1
        fi
    fi
    echo -n "$AWQL_UNCOMPATIBLE_FIELDS"
}

##
# Get all table names with for each, their structuring keys
# @example ([PRODUCT_PARTITION_REPORT]="ClickType Date...")
# @use AWQL_KEYS
function awqlKeys ()
{
    if [[ -z "$AWQL_KEYS" ]]; then
        AWQL_KEYS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_KEYS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_KEYS"
            return 1
        fi
    fi
    echo -n "$AWQL_KEYS"
}

##
# Get all table names with for each, the list of their fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
# @use AWQL_TABLES
function awqlTables ()
{
    if [[ -z "$AWQL_TABLES" ]]; then
        AWQL_TABLES=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_TABLES_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_TABLES"
            return 1
        fi
    fi
    echo -n "$AWQL_TABLES"
}

##
# Get all table names with for each, their type
# @example ([PRODUCT_PARTITION_REPORT]="SHOPPING")
# @use AWQL_TABLES_TYPE
function awqlTablesType ()
{
    if [[ -z "$AWQL_TABLES_TYPE" ]]; then
        AWQL_TABLES_TYPE=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${AWQL_API_VERSION}/${AWQL_API_DOC_TABLES_TYPE_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "InternalError.INVALID_AWQL_TABLES_TYPE"
            return 1
        fi
    fi
    echo -n "$AWQL_TABLES_TYPE"
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
# @param arrayToString $2 User request
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
                includeOnce "${AWQL_INC_DIR}/awql_select.sh"
                RESPONSE=$(awqlSelect "$ADWORDS_ID" "$AUTH" "$SERVER" "${REQUEST[QUERY]}" "$FILE" "$VERBOSE")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_DESC})
                includeOnce "${AWQL_INC_DIR}/awql_desc.sh"
                RESPONSE=$(awqlDesc "${REQUEST[QUERY]}" "$FILE")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_SHOW})
                includeOnce "${AWQL_INC_DIR}/awql_show.sh"
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
# @param string $1 Query
# @param string $2 Adwords ID
# @param string $3 Google Access Token
# @param string $4 Google Developer Token
# @param arrayToString $5 Google request configuration
# @param string $6 Save file path
# @param int $7 Cachine mode
# @param int $8 Verbose mode
function awql ()
{
    local QUERY="$1"
    local ADWORDS_ID="$2"
    local ACCESS_TOKEN="$3"
    local DEVELOPER_TOKEN="$4"
    local REQUEST="$5"
    local SAVE_FILE="$6"
    local VERBOSE="$7"
    local CACHING="$8"

    # Prepare and validate query, manage all extended behaviors to AWQL basics
    QUERY=$(query "$ADWORDS_ID" "$QUERY")
    if exitOnError "$?" "$QUERY" "$VERBOSE"; then
        return 1
    fi

    # Retrieve Google tokens (only if HTTP call is needed)
    local AUTH
    if [[ "$QUERY" == *"\"select\""* ]]; then
        AUTH=$(auth "$ACCESS_TOKEN" "$DEVELOPER_TOKEN")
        if exitOnError "$?" "$AUTH" "$VERBOSE"; then
            return 1
        fi
    fi

    # Send request to Adwords or local cache to get report
    local RESPONSE
    RESPONSE=$(get "$ADWORDS_ID" "$QUERY" "$AUTH" "$REQUEST" "$VERBOSE" "$CACHING")
    if exitOnError "$?" "$RESPONSE" "$VERBOSE"; then
        return 1
    fi

    # Print response
    print "$QUERY" "$RESPONSE" "$SAVE_FILE" "$VERBOSE"
}

##
# Read user prompt to retrieve AWQL query.
# Enable up and down arrow keys to navigate in history of queries.
# @param string $1 Adwords ID
# @param string $2 Google Access Token
# @param string $3 Google Developer Token
# @param arrayToString $4 Google request configuration
# @param string $5 Save file path
# @param int $6 Cachine mode
# @param int $7 Verbose mode
# @param int $8 Auto rehash for completion
function awqlRead ()
{
    local ADWORDS_ID="$1"
    local ACCESS_TOKEN="$2"
    local DEVELOPER_TOKEN="$3"
    local REQUEST="$4"
    local SAVE_FILE="$5"
    local VERBOSE="$6"
    local CACHING="$7"
    local AUTO_REHASH="$8"

    # Open a prompt (with auto-completion ?)
    reader QUERY_STRING "${AUTO_REHASH}"

    # Process query
    awql "$QUERY_STRING" "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$REQUEST" "$SAVE_FILE" "$VERBOSE" "$CACHING"
}