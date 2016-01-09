#!/usr/bin/env bash

# Environment
declare -r AWQL_OS=$(uname -s)
declare -r AWQL_UTC_DATE_FORMAT="%Y-%m-%dT%H:%M:%S%z"
declare -r AWQL_ERROR_STATUS="FAILED"
declare -r AWQL_SUCCESS_STATUS="OK"

# Worspace
declare -r AWQL_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
declare -r AWQL_WRK_DIR="/tmp/awql/$(date +%Y%m%d)"
declare -r AWQL_ADWORDS_DIR="${AWQL_ROOT_DIR}/adwords"
declare -r AWQL_INC_DIR="${AWQL_ROOT_DIR}/inc"
declare -r AWQL_CONF_DIR="${AWQL_ROOT_DIR}/conf"
declare -r AWQL_AUTH_DIR="${AWQL_ROOT_DIR}/auth"
declare -r AWQL_TOKEN_FILE_NAME="token.json"
declare -r AWQL_REQUEST_FILE_NAME="request.yaml"
declare -r AWQL_FILE_EXT=".awql"
declare -r AWQL_HTTP_RESPONSE_EXT=".rsp"
declare -r AWQL_CSV_TOOL_FILE="${AWQL_ROOT_DIR}/vendor/shcsv/csv.sh"

# Authentification
declare -r AWQL_AUTH_FILE="${AWQL_AUTH_DIR}/auth.yaml"
declare -r AWQL_AUTH_INIT_FILE="${AWQL_AUTH_DIR}/init.sh"
declare -r AUTH_GOOGLE_TYPE="google"
declare -r AUTH_CUSTOM_TYPE="custom"

# Adowrds API
declare -r AWQL_API_VERSION="v201509"
declare -r AWQL_API_DOC_EXTRA_FILE_NAME="extra.yaml"
declare -r AWQL_API_DOC_FIELDS_FILE_NAME="fields.yaml"
declare -r AWQL_API_DOC_KEYS_FILE_NAME="keys.yaml"
declare -r AWQL_API_DOC_TABLES_FILE_NAME="tables.yaml"
declare -r AWQL_API_DOC_BLACKLISTED_FIELDS_FILE_NAME="blacklisted_fields.yaml"
declare -r AWQL_API_DOC_COMPATIBILITY_DIR_NAME="compatibility"
declare -r AWQL_API_DOC_TABLES_TYPE_FILE_NAME="types.yaml"

# Query
declare -r AWQL_SORT_ORDER_ASC=0
declare -r AWQL_SORT_ORDER_DESC=1
declare -r AWQL_SORT_NUMERICS="Double Long Money Integer Byte int"

# MacOs portability, does not support case-insensitive matching
declare -r AWQL_QUERY_METHODS="select show desc"
declare -r AWQL_QUERY_SHOW="[Ss][Hh][Oo][Ww]"
declare -r AWQL_QUERY_FULL="[Ff][Uu][Ll][Ll]"
declare -r AWQL_QUERY_TABLES="[Tt][Aa][Bb][Ll][Ee][Ss]"
declare -r AWQL_QUERY_LIKE="[Ll][Ii][Kk][Ee]"
declare -r AWQL_QUERY_WITH="[Ww][Ii][Tt][Hh]"
declare -r AWQL_QUERY_DESC="[Dd][Ee][Ss][Cc]"
declare -r AWQL_QUERY_SELECT="[Ss][Ee][Ll][Ee][Cc][Tt]"
declare -r AWQL_QUERY_FROM="[Ff][Rr][Oo][Mm]"
#declare -r AWQL_QUERY_WHERE="[Ww][Hh][Ee][Rr][Ee]"
#declare -r AWQL_QUERY_DURING="[Dd][Uu][Rr][Ii][Nn][Gg]"
declare -r AWQL_QUERY_ORDER_BY="[Oo][Rr][Dd][Ee][Rr] [Bb][Yy]"
declare -r AWQL_QUERY_LIMIT="[Ll][Ii][Mm][Ii][Tt]"

# Prompt
declare -r AWQL_PROMPT="awql> "
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

# Workspace
if [ -n "$AWQL_WRK_DIR" ]; then
    mkdir -p "$AWQL_WRK_DIR"
fi