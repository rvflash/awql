#!/usr/bin/env bash

declare AWQL_EXTRA AWQL_FIELDS AWQL_BLACKLISTED_FIELDS AWQL_UNCOMPATIBLE_FIELDS AWQL_KEYS AWQL_TABLES AWQL_TABLES_TYPE

##
# Display information about available AWQL commmands
# return string
function awqlHelp ()
{
    echo "The AWQL command line tool is developed by Hervé GOUCHET."
    echo "For developer information, visit:"
    echo "    https://github.com/rvflash/awql/"
    echo "For information about AWQL language, visit:"
    echo "    https://developers.google.com/adwords/api/docs/guides/awql"
    echo
    echo "List of all AWQL commands:"
    echo "Note that all text commands must be first on line and end with ';'"
    printLeftPad "${AWQL_TEXT_COMMAND_CLEAR}" 10 " "
    echo "(\\${AWQL_COMMAND_CLEAR}) Clear the current input statement."
    printLeftPad "${AWQL_TEXT_COMMAND_EXIT}" 10 " "
    echo "(\\${AWQL_COMMAND_EXIT}) Exit awql. Same as quit."
    printLeftPad "${AWQL_TEXT_COMMAND_HELP}" 10 " "
    echo "(\\${AWQL_COMMAND_HELP}) Display this help."
    printLeftPad "${AWQL_TEXT_COMMAND_QUIT}" 10 " "
    echo "(\\${AWQL_COMMAND_EXIT}) Quit awql command line tool."
}

##
# Get all field names with for each, their description
# @example ([AccountDescriptiveName]="The descriptive name...")
# @use AWQL_EXTRA
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
# @notUsedYet
function awqlExtra ()
{
    local API_VERSION="$1"
    if [[ -z "$AWQL_EXTRA" ]]; then
        AWQL_EXTRA=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_EXTRA_FILE_NAME}")
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
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlFields ()
{
    local API_VERSION="$1"
    if [[ -z "$AWQL_FIELDS" ]]; then
        AWQL_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_FIELDS_FILE_NAME}")
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
# @param string $1 API version
# @return string
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlBlacklistedFields ()
{
    local API_VERSION="$1"
    if [[ -z "$AWQL_BLACKLISTED_FIELDS" ]]; then
        AWQL_BLACKLISTED_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_BLACKLISTED_FIELDS_FILE_NAME}")
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
# @param string $1 Table
# @param string $2 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlUncompatibleFields ()
{
    local TABLE="$1"
    local API_VERSION="$2"

    if [[ -z "$AWQL_UNCOMPATIBLE_FIELDS" ]]; then
        AWQL_UNCOMPATIBLE_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_COMPATIBILITY_DIR_NAME}/${TABLE}.yaml")
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
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlKeys ()
{
    local API_VERSION="$1"
    if [[ -z "$AWQL_KEYS" ]]; then
        AWQL_KEYS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_KEYS_FILE_NAME}")
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
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlTables ()
{
    local API_VERSION="$1"
    if [[ -z "$AWQL_TABLES" ]]; then
        AWQL_TABLES=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_TABLES_FILE_NAME}")
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
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlTablesType ()
{
    local API_VERSION="$1"
    if [[ -z "$AWQL_TABLES_TYPE" ]]; then
        AWQL_TABLES_TYPE=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${API_VERSION}/${AWQL_API_DOC_TABLES_TYPE_FILE_NAME}")
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
# @return string
# @returnStatus 1 If data is not cached
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
# @param arrayToString $1 User request
# @param arrayToString $2 Google authentification tokens
# @param arrayToString $3 Google request properties
# @param string
# @returnStatus 2 If query is invalid
# @returnStatus 1 If case of fatal error
function get ()
{
    # In
    declare -A REQUEST="$1"
    local AUTH="$2"
    local SERVER="$3"

    # Out
    local FILE="${AWQL_WRK_DIR}/${REQUEST[CHECKSUM]}${AWQL_FILE_EXT}"

    # Overload caching mode for local database AWQL methods
    declare -i CACHING="${REQUEST[CACHING]}"
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
                RESPONSE=$(awqlSelect "${REQUEST[QUERY]}" "$FILE" "${REQUEST[API_VERSION]}" "${REQUEST[ADWORDS_ID]}" "$AUTH" "$SERVER" "${REQUEST[VERBOSE]}" )
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_DESC})
                includeOnce "${AWQL_INC_DIR}/awql_desc.sh"
                RESPONSE=$(awqlDesc "${REQUEST[QUERY]}" "$FILE" "${REQUEST[API_VERSION]}")
                ERR_TYPE=$?
                ;;
            ${AWQL_QUERY_SHOW})
                includeOnce "${AWQL_INC_DIR}/awql_show.sh"
                RESPONSE=$(awqlShow "${REQUEST[QUERY]}" "$FILE" "${REQUEST[API_VERSION]}")
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
# @param string $2 Api version
# @param string $3 Adwords ID
# @param string $4 Google Access Token
# @param string $5 Google Developer Token
# @param arrayToString $6 Google request configuration
# @param string $7 Save file path
# @param int $8 Cachine mode
# @param int $9 Verbose mode
# @param string
# @returnStatus 1 If query is invalid
function awql ()
{
    local QUERY="$1"
    local API_VERSION="$2"
    local ADWORDS_ID="$3"
    local ACCESS_TOKEN="$4"
    local DEVELOPER_TOKEN="$5"
    local REQUEST="$6"
    local SAVE_FILE="$7"
    local VERBOSE="$8"
    local CACHING="$9"

    # Prepare and validate query, manage all extended behaviors to AWQL basics
    QUERY=$(query "$ADWORDS_ID" "$QUERY" "$API_VERSION" "$VERBOSE" "$CACHING")
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
    RESPONSE=$(get "$QUERY" "$AUTH" "$REQUEST")
    if exitOnError "$?" "$RESPONSE" "$VERBOSE"; then
        return 1
    fi

    # Print response
    print "$QUERY" "$RESPONSE" "$SAVE_FILE" "$VERBOSE"
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
# @param string $7 Save file path
# @param int $8 Cachine mode
# @param int $9 Verbose mode
# @param string
# @returnStatus 1 If query is invalid
function awqlRead ()
{
    local AUTO_REHASH="$1"
    local API_VERSION="$2"
    local ADWORDS_ID="$3"
    local ACCESS_TOKEN="$4"
    local DEVELOPER_TOKEN="$5"
    local REQUEST="$6"
    local SAVE_FILE="$7"
    local VERBOSE="$8"
    local CACHING="$9"

    # Open a prompt (with auto-completion ?)
    local QUERY_STRING
    reader QUERY_STRING "${AUTO_REHASH}" "${API_VERSION}"

    # Process query
    awql "$QUERY_STRING" "$ADWORDS_ID" "$ACCESS_TOKEN" "$DEVELOPER_TOKEN" "$REQUEST" "$SAVE_FILE" "$VERBOSE" "$CACHING" "$API_VERSION"
}