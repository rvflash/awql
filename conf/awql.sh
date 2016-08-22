#!/usr/bin/env bash

# Environment
declare -r AWQL_SUCCESS_STATUS="OK"
declare -r AWQL_ERROR_STATUS="FAILED"
declare -r AWQL_USER_NAME="$(logname)"
declare -r AWQL_USER_HOME="$(sudo -u ${AWQL_USER_NAME} -H sh -c 'echo "$HOME"')"
declare -r AWQL_OS="$(uname -s)"

# Workspace
declare -r -i AWQL_HISTORY_SIZE=250
declare -r -i AWQL_API_RETRY_NB=3
declare -r AWQL_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
declare -r AWQL_WRK_DIR="/tmp/awql/$(date +%Y%m%d)"
declare -r AWQL_USER_DIR="${AWQL_USER_HOME}/.awql"
declare -r AWQL_ADWORDS_DIR="${AWQL_ROOT_DIR}/adwords"
declare -r AWQL_VIEWS_DIR_NAME="views"
declare -r AWQL_VIEWS_DIR="${AWQL_ADWORDS_DIR}/${AWQL_VIEWS_DIR_NAME}"
declare -r AWQL_USER_VIEWS_DIR="${AWQL_USER_DIR}/${AWQL_VIEWS_DIR_NAME}"
declare -r AWQL_USER_CACHE_VIEWS_FILE="${AWQL_USER_VIEWS_DIR}/.cache"
declare -r AWQL_HISTORY_FILE="${AWQL_USER_DIR}/history"
declare -r AWQL_INC_DIR="${AWQL_ROOT_DIR}/core"
declare -r AWQL_STATEMENT_DIR="${AWQL_INC_DIR}/statement"
declare -r AWQL_QUERY_DIR="${AWQL_INC_DIR}/query"
declare -r AWQL_CONF_DIR="${AWQL_ROOT_DIR}/conf"
declare -r AWQL_AUTH_DIR="${AWQL_INC_DIR}/auth"
declare -r AWQL_TOKEN_FILE_NAME="token.json"
declare -r AWQL_REQUEST_FILE_NAME="request.yaml"
declare -r AWQL_FILE_EXT=".awql"
declare -r AWQL_HTTP_RESPONSE_EXT=".rsp"
declare -r AWQL_TERM_TABLES_DIR="${AWQL_ROOT_DIR}/vendor/termtables"
declare -r AWQL_BASH_PACKAGES_DIR="${AWQL_ROOT_DIR}/vendor/bash-packages"
declare -r AWQL_AUTH_FILE="${AWQL_CONF_DIR}/auth.yaml"
declare -r AWQL_AUTH_INIT_FILE="${AWQL_AUTH_DIR}/init.sh"

# Adwords API
declare -r AWQL_API_ID_REGEX="^[[:digit:]]{3}-[[:digit:]]{3}-[[:digit:]]{4}$"
declare -r AWQL_API_VERSION_REGEX="^v[[:digit:]]{6}$"
declare -r AWQL_API_URL_REGEX='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
declare -r AWQL_API_LAST_VERSION="v201607"
declare -r AWQL_API_DOC_EXTRA_FILE_NAME="extra.yaml"
declare -r AWQL_API_DOC_FIELDS_FILE_NAME="fields.yaml"
declare -r AWQL_API_DOC_KEYS_FILE_NAME="keys.yaml"
declare -r AWQL_API_DOC_TABLES_FILE_NAME="tables.yaml"
declare -r AWQL_API_DOC_COMPATIBILITY_DIR_NAME="compatibility"
declare -r AWQL_API_DOC_TABLES_TYPE_FILE_NAME="types.yaml"
declare -r AWQL_API_DOC_PRIMARY_KEYS_FILE_NAME="primary_keys.yaml"

# Query sort
declare -r AWQL_SORT_ORDER_ASC=0
declare -r AWQL_SORT_ORDER_DESC=1
declare -r AWQL_SORT_NUMERICS="Double Long Money Integer Byte int"

# MacOs portability, does not support case-insensitive matching
declare -r AWQL_QUERY_METHODS="select show desc create"
declare -r AWQL_QUERY_SELECT="[Ss][Ee][Ll][Ee][Cc][Tt]"
declare -r AWQL_QUERY_CREATE="[Cc][Rr][Ee][Aa][Tt][Ee]"
declare -r AWQL_QUERY_REPLACE="[Rr][Ee][Pp][Ll][Aa][Cc][Ee]"
declare -r AWQL_QUERY_VIEW="[Vv][Ii][Ee][Ww]"
declare -r AWQL_QUERY_AS="[Aa][Ss]"
declare -r AWQL_QUERY_ASC="[Aa][Ss][Cc]"
declare -r AWQL_QUERY_DESC="[Dd][Ee][Ss][Cc]"
declare -r AWQL_QUERY_SHOW="[Ss][Hh][Oo][Ww]"
declare -r AWQL_QUERY_FULL="[Ff][Uu][Ll][Ll]"
declare -r AWQL_QUERY_TABLES="[Tt][Aa][Bb][Ll][Ee][Ss]"
declare -r AWQL_QUERY_LIKE="[Ll][Ii][Kk][Ee]"
declare -r AWQL_QUERY_WITH="[Ww][Ii][Tt][Hh]"
declare -r AWQL_QUERY_FROM="[Ff][Rr][Oo][Mm]"
declare -r AWQL_QUERY_WHERE="[Ww][Hh][Ee][Rr][Ee]"
declare -r AWQL_QUERY_DURING="[Dd][Uu][Rr][Ii][Nn][Gg]"
declare -r AWQL_QUERY_GROUP="[Gg][Rr][Oo][Uu][Pp]"
declare -r AWQL_QUERY_ORDER="[Oo][Rr][Dd][Ee][Rr]"
declare -r AWQL_QUERY_BY="[Bb][Yy]"
declare -r AWQL_QUERY_GROUP_BY="${AWQL_QUERY_GROUP} ${AWQL_QUERY_BY}"
declare -r AWQL_QUERY_ORDER_BY="${AWQL_QUERY_ORDER} ${AWQL_QUERY_BY}"
declare -r AWQL_QUERY_LIMIT="[Ll][Ii][Mm][Ii][Tt]"
declare -r AWQL_QUERY_OR="[Oo][Rr]"
declare -r AWQL_QUERY_AND="[Aa][Nn][Dd]"
declare -r AWQL_QUERY_CLEAR="[Cc][Ll][Ee][Aa][Rr]"
declare -r AWQL_QUERY_EXIT="[Ee][Xx][Ii][Tt]"
declare -r AWQL_QUERY_QUIT="[Qq][Uu][Ii][Tt]"
declare -r AWQL_QUERY_HELP="[Hh][Ee][Ll][Pp]"
declare -r AWQL_FUNCTION_COUNT="[Cc][Oo][Uu][Nn][Tt]"
declare -r AWQL_FUNCTION_SUM="[Ss][Uu][Mm]"
declare -r AWQL_FUNCTION_MAX="[Mm][Aa][Xx]"
declare -r AWQL_FUNCTION_MIN="[Mm][Ii][Nn]"
declare -r AWQL_FUNCTION_DISTINCT="[Dd][Ii][Ss][Tt][Ii][Nn][Cc][Tt]"

# Request properties
declare -r AWQL_REQUEST_QUERY="AWQL_QUERY"
declare -r AWQL_REQUEST_QUERY_SOURCE="QUERY"
declare -r AWQL_REQUEST_TYPE="METHOD"
declare -r AWQL_REQUEST_STATEMENT="STATEMENT"
declare -r AWQL_REQUEST_FIELD="FIELD"
declare -r AWQL_REQUEST_FIELDS="FIELDS"
declare -r AWQL_REQUEST_FIELD_NAMES="FIELD_NAMES"
declare -r AWQL_REQUEST_HEADERS="HEADERS"
declare -r AWQL_REQUEST_AGGREGATES="AGGREGATES"
declare -r AWQL_REQUEST_TABLE="TABLE"
declare -r AWQL_REQUEST_WHERE="WHERE"
declare -r AWQL_REQUEST_DURING="DURING"
declare -r AWQL_REQUEST_GROUP="GROUP"
declare -r AWQL_REQUEST_ORDER="ORDER"
declare -r AWQL_REQUEST_LIMIT="LIMIT"
declare -r AWQL_REQUEST_UNKNOWN="UNKNOWN"
declare -r AWQL_REQUEST_VERTICAL="VERTICAL_MODE"
declare -r AWQL_REQUEST_CHECKSUM="CHECKSUM"
declare -r AWQL_REQUEST_ID="ADWORDS_ID"
declare -r AWQL_REQUEST_VERSION="API_VERSION"
declare -r AWQL_REQUEST_VERBOSE="VERBOSE"
declare -r AWQL_REQUEST_CACHED="CACHING"
declare -r AWQL_REQUEST_RAW="RAW"
declare -r AWQL_REQUEST_LIKE="LIKE"
declare -r AWQL_REQUEST_WITH="WITH"
declare -r AWQL_REQUEST_FULL="FULL"
declare -r AWQL_REQUEST_VIEW="VIEW"
declare -r AWQL_REQUEST_REPLACE="REPLACE"
declare -r AWQL_REQUEST_DEFINITION="DEFINITION"
declare -r AWQL_REQUEST_ACCESS="ACCESS_TOKEN"
declare -r AWQL_REQUEST_DEV_TOKEN="DEVELOPER_TOKEN"
declare -r AWQL_REQUEST_DEBUG="DEBUG"

# Aggregates
declare -r AWQL_AGGREGATE_AVG="AVG"
declare -r AWQL_AGGREGATE_DISTINCT="DISTINCT"
declare -r AWQL_AGGREGATE_COUNT="COUNT"
declare -r AWQL_AGGREGATE_MAX="MAX"
declare -r AWQL_AGGREGATE_MIN="MIN"
declare -r AWQL_AGGREGATE_SUM="SUM"
declare -r AWQL_AGGREGATE_GROUP="GROUP"

# Response properties
declare -r AWQL_RESPONSE_FILE="FILE"
declare -r AWQL_RESPONSE_CACHED="CACHING"
declare -r AWQL_RESPONSE_HTTP_CODE="HTTP_CODE"
declare -r AWQL_RESPONSE_TIME_DURATION="TIME_DURATION"

# View properties
declare -r AWQL_VIEW_ORIGIN="ORIGIN"
declare -r AWQL_VIEW_NAMES="NAMES"
declare -r AWQL_VIEW_FIELDS="FIELDS"
declare -r AWQL_VIEW_TABLE="TABLE"
declare -r AWQL_VIEW_WHERE="WHERE"
declare -r AWQL_VIEW_DURING="DURING"
declare -r AWQL_VIEW_GROUP="GROUP"
declare -r AWQL_VIEW_ORDER="ORDER"
declare -r AWQL_VIEW_LIMIT="LIMIT"

# Token properties
declare -r AWQL_TOKEN_TYPE_VALUE="Bearer"
declare -r AWQL_AUTH_GOOGLE_TYPE="google"
declare -r AWQL_AUTH_CUSTOM_TYPE="custom"
declare -r AWQL_TOKEN_TYPE="TOKEN_TYPE"
declare -r AWQL_ACCESS_TOKEN="ACCESS_TOKEN"
declare -r AWQL_DEVELOPER_TOKEN="DEVELOPER_TOKEN"
declare -r AWQL_REFRESH_TOKEN="REFRESH_TOKEN"
declare -r AWQL_ERROR_TOKEN="ERROR"
declare -r AWQL_TOKEN_EXPIRE_AT="EXPIRE_AT"
declare -r AWQL_AUTH_TYPE="AUTH_TYPE"
declare -r AWQL_AUTH_CLIENT_ID="CLIENT_ID"
declare -r AWQL_AUTH_CLIENT_SECRET="CLIENT_SECRET"
declare -r AWQL_AUTH_PROTOCOL="PROTOCOL"
declare -r AWQL_AUTH_HOSTNAME="HOSTNAME"
declare -r AWQL_AUTH_PATH="PATH"
declare -r AWQL_AUTH_PORT="PORT"
declare -r AWQL_GRANT_TYPE="GRANT_TYPE"
declare -r AWQL_GRANT_REFRESH_TOKEN="GRANT_TYPE_RT"
declare -r AWQL_JSON_TOKEN_TYPE="token_type"
declare -r AWQL_JSON_ACCESS_TOKEN="access_token"
declare -r AWQL_JSON_EXPIRE_AT="expire_at"
declare -r AWQL_JSON_EXPIRE_IN="expire_in"

# Adwords API request
declare -r AWQL_API_CONNECT_TO="CONNECT_TIME_OUT"
declare -r AWQL_API_TO="TIME_OUT"
declare -r AWQL_API_PROTOCOL="PROTOCOL"
declare -r AWQL_API_HOST="HOSTNAME"
declare -r AWQL_API_PATH="PATH"
declare -r AWQL_API_METHOD="METHOD"
declare -r AWQL_API_RESPONSE="RESPONSE_FORMAT"
declare -r AWQL_API_QUERY="AWQL_QUERY"
declare -r AWQL_API_AUTH="AUTHORIZATION"
declare -r AWQL_API_TOKEN="DEVELOPER_TOKEN"
declare -r AWQL_API_ID="ADWORDS_ID"
declare -r AWQL_API_SKIP_HEADER="SKIP_HEADER"
declare -r AWQL_API_REPORT_HEADER="REPORT_HEADER"
declare -r AWQL_API_SKIP_SUMMARY="SKIP_SUMMARY"
declare -r AWQL_API_REPORT_SUMMARY="REPORT_SUMMARY"
declare -r AWQL_API_WITH_ZERO_IMPRESSION="ZERO_IMPRESSION"
declare -r AWQL_API_REPORT_ZERO_IMPRESSION="REPORT_ZERO"

# Prompt
declare -r AWQL_PROMPT="awql> "
declare -r AWQL_PROMPT_NEW_LINE="   -> "
declare -r AWQL_PROMPT_EXIT="Bye"
declare -r AWQL_PROMPT_REQUIRED="(required)"
declare -r AWQL_TABLE_FIELD_NAME="Field"
declare -r AWQL_TABLE_FIELD_TYPE="Type"
declare -r AWQL_TABLE_FIELD_KEY="Key"
declare -r AWQL_TABLE_FIELD_EXTRA="Extra"
declare -r AWQL_TABLE_FIELD_UNCOMPATIBLES="Not_compatible_with"
declare -r AWQL_TABLE_TYPE="Table_type"
declare -r AWQL_FIELD_IS_KEY="MUL"
declare -r AWQL_TABLES_IN="Tables_in_"
declare -r AWQL_TABLES_WITH="_with_"
declare -r AWQL_CONFIRM="(Y/N)"
declare -r AWQL_COMPLETION_CONFIRM="Display all %s possibilities?"

declare -r AWQL_COMMAND_CLEAR="c"
declare -r AWQL_COMMAND_HELP="h"
declare -r AWQL_COMMAND_EXIT="q"
declare -r AWQL_TEXT_COMMAND_CLEAR="clear"
declare -r AWQL_TEXT_COMMAND_HELP="help"
declare -r AWQL_TEXT_COMMAND_EXIT="exit"
declare -r AWQL_TEXT_COMMAND_QUIT="quit"

# Error message

# > Internal errors
declare -r AWQL_INTERNAL_ERROR_API_VERSION="InternalError.UNKNOWN_API_VERSION"
declare -r AWQL_INTERNAL_ERROR_COLUMN_TYPE="InternalError.INVALID_AWQL_COLUMN"
declare -r AWQL_INTERNAL_ERROR_DATA_FILE="InternalError.UNKNOWN_DATA_FILE"
declare -r AWQL_INTERNAL_ERROR_WRITE_FILE="InternalError.WRITE_FILE_PERMISSION"
declare -r AWQL_INTERNAL_ERROR_ID="InternalError.INVALID_ADWORDS_ID"
declare -r AWQL_INTERNAL_ERROR_INVALID_TABLES="InternalError.INVALID_AWQL_TABLES"
declare -r AWQL_INTERNAL_ERROR_INVALID_FIELDS="InternalError.INVALID_AWQL_FIELDS"
declare -r AWQL_INTERNAL_ERROR_INVALID_TYPES="InternalError.INVALID_AWQL_TABLE_TYPES"
declare -r AWQL_INTERNAL_ERROR_INVALID_KEYS="InternalError.INVALID_AWQL_KEY_FIELDS"
declare -r AWQL_INTERNAL_ERROR_CLASH_FIELDS="InternalError.INVALID_AWQL_INCOMPATIBLE_FIELDS"
declare -r AWQL_INTERNAL_ERROR_QUERY="InternalError.QUERY_MISSING"
declare -r AWQL_INTERNAL_ERROR_QUERY_CHECKSUM="InternalError.QUERY_CHECKSUM"
declare -r AWQL_INTERNAL_ERROR_QUERY_COMPONENT="InternalError.QUERY_COMPONENT"
declare -r AWQL_INTERNAL_ERROR_CONFIG="InternalError.INVALID_REQUEST"
declare -r AWQL_INTERNAL_ERROR_INVALID_VIEWS="InternalError.INVALID_AWQL_VIEWS"
declare -r AWQL_INTERNAL_ERROR_AGGREGATES="InternalError.INVALID_GROUP_BY"
declare -r AWQL_INTERNAL_ERROR_ORDER="InternalError.INVALID_ORDER"
declare -r AWQL_INTERNAL_ERROR_LIMIT="InternalError.INVALID_LIMIT"

# > Query errors
declare -r AWQL_QUERY_ERROR_SYNTAX="QueryError.SYNTAX"
declare -r AWQL_QUERY_ERROR="QueryError.INVALID"
declare -r AWQL_QUERY_ERROR_DURING="QueryError.DURING"
declare -r AWQL_QUERY_ERROR_LIMIT="QueryError.LIMIT"
declare -r AWQL_QUERY_ERROR_MULTIPLE_ORDER="QueryError.MULTIPLE_ORDER"
declare -r AWQL_QUERY_ERROR_METHOD="QueryError.UNKNOWN_QUERY_METHOD"
declare -r AWQL_QUERY_ERROR_MISSING="QueryError.MISSING"
declare -r AWQL_QUERY_ERROR_WHERE="QueryError.WHERE"
declare -r AWQL_QUERY_ERROR_PRIMARY_KEY="QueryError.MISSING_PRIMARY_KEY"
declare -r AWQL_QUERY_ERROR_GROUP="QueryError.GROUP_BY"
declare -r AWQL_QUERY_ERROR_ORDER="QueryError.ORDER_BY"
declare -r AWQL_QUERY_ERROR_TABLE="QueryError.TABLE_NAME"
declare -r AWQL_QUERY_ERROR_VIEW="QueryError.VIEW_NAME"
declare -r AWQL_QUERY_ERROR_SELECT_ALL="QueryError.ALL_COLUMNS_NOT_SUPPORTED"
declare -r AWQL_QUERY_ERROR_UNKNOWN_TABLE="QueryError.UNKNOWN_TABLE_NAME"
declare -r AWQL_QUERY_ERROR_UNKNOWN_FIELD="QueryError.UNKNOWN_TABLE_FIELD"
declare -r AWQL_QUERY_ERROR_COLUMNS_NOT_MATCH="QueryError.COLUMNS_DO_NOT_MATCH"
declare -r AWQL_QUERY_ERROR_SOURCE_IS_VIEW="QueryError.VIEW_IN_VIEW"
declare -r AWQL_QUERY_ERROR_MISSING_SOURCE="QueryError.MISSING_QUERY_SOURCE"
declare -r AWQL_QUERY_ERROR_INVALID_SOURCE="QueryError.INVALID_QUERY_SOURCE"
declare -r AWQL_QUERY_ERROR_VIEW_ALREADY_EXISTS="QueryError.VIEW_ALREADY_EXISTS"
declare -r AWQL_QUERY_ERROR_FUNCTION="QueryError.UNKNOWN_FUNCTION"
declare -r AWQL_QUERY_ERROR_DISTINCT="QueryError.DISTINCT"

# > Response errors
declare -r AWQL_AUTH_ERROR_INVALID="AuthenticationError.INVALID"
declare -r AWQL_AUTH_ERROR_INVALID_TYPE="AuthenticationError.INVALID_TYPE"
declare -r AWQL_AUTH_ERROR_INVALID_FILE="AuthenticationError.INVALID_FILE"
declare -r AWQL_AUTH_ERROR_INVALID_URL="AuthenticationError.INVALID_URL"
declare -r AWQL_AUTH_ERROR_INVALID_CLIENT="AuthenticationError.INVALID_CLIENT"
declare -r AWQL_AUTH_ERROR_INVALID_DEVELOPER_TOKEN="AuthenticationError.MISSING_DEVELOPER_TOKEN"
declare -r AWQL_AUTH_ERROR_BUILD_FILE="AuthenticationError.UNABLE_TO_BUILD_FILE"
declare -r AWQL_AUTH_ERROR="AuthenticationError.FAIL"
declare -r AWQL_RESP_ERROR_NO_CONNEXION="ConnexionError.NOT_FOUND"
declare -r AWQL_RESP_ERROR_CONNEXION="ConnexionError.SERVER"

# Workspace
if [[ -n "${AWQL_WRK_DIR}" && ! -d "${AWQL_WRK_DIR}" ]]; then
    mkdir -p "${AWQL_WRK_DIR}"
fi
if [[ -n "${AWQL_USER_VIEWS_DIR}" && ! -d "${AWQL_USER_VIEWS_DIR}" ]]; then
    mkdir -p "${AWQL_USER_VIEWS_DIR}"
fi

# Import
source "${AWQL_BASH_PACKAGES_DIR}/file.sh"
source "${AWQL_BASH_PACKAGES_DIR}/array.sh"
source "${AWQL_BASH_PACKAGES_DIR}/strings.sh"
source "${AWQL_BASH_PACKAGES_DIR}/term.sh"
source "${AWQL_BASH_PACKAGES_DIR}/encoding/yaml.sh"

# AWQL syntax
source "${AWQL_CONF_DIR}/completion.sh"

# AWQL reports
declare -- AWQL_FIELDS AWQL_BLACKLISTED_FIELDS AWQL_UNCOMPATIBLE_FIELDS AWQL_KEYS AWQL_PRIMARY_KEYS AWQL_TABLES AWQL_TABLES_TYPE

##
# Get all fields names with for each, the type of data
# @example ([AccountDescriptiveName]="String")
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlFields ()
{
    local apiVersion="$1"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "()"
        return 1
    fi
    if [[ -z "${AWQL_FIELDS}" ]]; then
        AWQL_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${apiVersion}/${AWQL_API_DOC_FIELDS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    echo "${AWQL_FIELDS}"
}

##
# Get all fields names with for each, the list of their incompatible fields
# @example ([AccountDescriptiveName]="Hour")
# @param string $1 Table
# @param string $2 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlUncompatibleFields ()
{
    local table="$1"
    local apiVersion="$2"
    if [[ -z "$table" || "$table" == *"*"* || ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "()"
        return 1
    fi
    if [[ -z "${AWQL_UNCOMPATIBLE_FIELDS}" ]]; then
        AWQL_UNCOMPATIBLE_FIELDS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${apiVersion}/${AWQL_API_DOC_COMPATIBILITY_DIR_NAME}/${table}.yaml")
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    echo "${AWQL_UNCOMPATIBLE_FIELDS}"
}

##
# Get all table names with for each, their structuring keys
# @example ([PRODUCT_PARTITION_REPORT]="ClickType Date...")
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlKeys ()
{
    local apiVersion="$1"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "()"
        return 1
    fi
    if [[ -z "${AWQL_KEYS}" ]]; then
        AWQL_KEYS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${apiVersion}/${AWQL_API_DOC_KEYS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    echo "${AWQL_KEYS}"
}

##
# Get primary key for all tables
# @example ([PRODUCT_PARTITION_REPORT]="Id")
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlPrimaryKeys ()
{
    local apiVersion="$1"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "()"
        return 1
    fi
    if [[ -z "${AWQL_PRIMARY_KEYS}" ]]; then
        AWQL_PRIMARY_KEYS=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${apiVersion}/${AWQL_API_DOC_PRIMARY_KEYS_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    echo "${AWQL_PRIMARY_KEYS}"
}

##
# Get all table names with for each, the list of their fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlTables ()
{
    local apiVersion="$1"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "()"
        return 1
    fi
    if [[ -z "${AWQL_TABLES}" ]]; then
        AWQL_TABLES=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${apiVersion}/${AWQL_API_DOC_TABLES_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    echo "${AWQL_TABLES}"
}

##
# Get all table names with for each, their type
# @example ([PRODUCT_PARTITION_REPORT]="SHOPPING")
# @param string $1 API version
# @return string
# @returnStatus 1 If adwords yaml file does not exit
function awqlTablesType ()
{
    local apiVersion="$1"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "()"
        return 1
    fi
    if [[ -z "${AWQL_TABLES_TYPE}" ]]; then
        AWQL_TABLES_TYPE=$(yamlFileDecode "${AWQL_ADWORDS_DIR}/${apiVersion}/${AWQL_API_DOC_TABLES_TYPE_FILE_NAME}")
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    echo "${AWQL_TABLES_TYPE}"
}

##
# Remove user file dedicated to cache list of views
# @return void
function awqlClearCacheViews ()
{
    if [[ -f "${AWQL_USER_CACHE_VIEWS_FILE}" ]]; then
        rm -f "${AWQL_USER_CACHE_VIEWS_FILE}"
    fi
}

##
# Get all view names with for each, the list of their properties
# @example ([CAMPAIGN_REPORT]="([origin]=\"SELECT AdGroupId...)
# @return string
# @returnStatus 2 If view yaml file is invalid
# @returnStatus 1 If cache file for view can not be built
function awqlViews ()
{
    if [[ ! -f "${AWQL_USER_CACHE_VIEWS_FILE}" ]]; then
        # Awql views
        declare -A views
        local viewFile
        for viewFile in $(scanDirectory "${AWQL_VIEWS_DIR}" 1); do
            views["${viewFile/.yaml/}"]="$(yamlFileDecode "${AWQL_VIEWS_DIR}/${viewFile}")"
            if [[ $? -ne 0 ]]; then
                echo "()"
                return 2
            fi
        done
        # Local views
        for viewFile in $(scanDirectory "${AWQL_USER_VIEWS_DIR}" 1); do
            views["${viewFile/.yaml/}"]="$(yamlFileDecode "${AWQL_USER_VIEWS_DIR}/${viewFile}")"
            if [[ $? -ne 0 ]]; then
                echo "()"
                return 2
            fi
        done
        # Build cache file
        arrayToString "$(declare -p views)" > "${AWQL_USER_CACHE_VIEWS_FILE}"
        if [[ $? -ne 0 ]]; then
            echo "()"
            return 1
        fi
    fi

    cat "${AWQL_USER_CACHE_VIEWS_FILE}"
}

##
# Check if word is known as an awql function
# @param string $1 Str
# @returnStatus 0 In case of match
# @returnStatus 1 If word is not an AWQL reserved word
function awqlFunction ()
{
    local str="$1"
    if [[ -z "$str" ]]; then
        return 1
    fi

    case "$str" in
        ${AWQL_FUNCTION_COUNT}|${AWQL_FUNCTION_SUM}|${AWQL_FUNCTION_MIN}|${AWQL_FUNCTION_MAX}|${AWQL_FUNCTION_DISTINCT})
            # Aggregate
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

##
# Check if word is a awql or reserved word
# @param string $1 Str
# @returnStatus 0 In case of match
# @returnStatus 1 If word is not an AWQL reserved word
function awqlReservedWord ()
{
    local str="$1"
    if [[ -z "$str" ]]; then
        return 1
    elif awqlFunction "$str"; then
        return 0
    fi

    case "$str" in
        ${AWQL_QUERY_DESC}|${AWQL_QUERY_FULL})
            # Desc
            return 0
            ;;
        ${AWQL_QUERY_SHOW}|${AWQL_QUERY_TABLES}|${AWQL_QUERY_LIKE}|${AWQL_QUERY_WITH})
            # Show
            return 0
            ;;
        ${AWQL_QUERY_SELECT}|${AWQL_QUERY_FROM}|${AWQL_QUERY_WHERE}|${AWQL_QUERY_DURING}|${AWQL_QUERY_ORDER}|${AWQL_QUERY_BY}|${AWQL_QUERY_LIMIT})
            # Select
            return 0
            ;;
        ${AWQL_QUERY_CREATE}|${AWQL_QUERY_REPLACE}|${AWQL_QUERY_VIEW}|${AWQL_QUERY_AS})
            # Views
            return 0
            ;;
        ${AWQL_QUERY_AND}|${AWQL_QUERY_OR})
            # Condition
            return 0
            ;;
        ${AWQL_QUERY_CLEAR}|${AWQL_QUERY_EXIT}|${AWQL_QUERY_QUIT}|${AWQL_QUERY_HELP})
            # Internal
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}