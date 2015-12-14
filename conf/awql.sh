#!/usr/bin/env bash

# Constants
declare -r WRK_DIR="/tmp/awql/$(date +%Y%m%d)"
declare -r API_DOC_DIR_NAME="adwords"
declare -r API_DOC_EXTRA_FILE_NAME="extra.yaml"
declare -r API_DOC_FIELDS_FILE_NAME="fields.yaml"
declare -r API_DOC_KEYS_FILE_NAME="keys.yaml"
declare -r API_DOC_TABLES_FILE_NAME="tables.yaml"
declare -r AUTH_FILE_NAME="auth.yaml"
declare -r REQUEST_FILE_NAME="request.yaml"
declare -r ERR_FILE_EXT=".err"
declare -r AWQL_FILE_EXT=".awql"
declare -r AWQL_HTTP_RESPONSE_EXT=".rsp"

declare -r AWQL_SORT_ORDER_ASC=0
declare -r AWQL_SORT_ORDER_DESC=1
declare -r AWQL_SORT_NUMERICS="Double Long Money Integer Byte int"

# MacOs portability, does not support case-insensitive matching
declare -r AWQL_QUERY_SHOW="[Ss][Hh][Oo][Ww] "
declare -r AWQL_QUERY_SHOW_FULL="[Ff][Uu][Ll][Ll] "
declare -r AWQL_QUERY_TABLES="[Tt][Aa][Bb][Ll][Ee][Ss]"
declare -r AWQL_QUERY_LIKE="[Ll][Ii][Kk][Ee]"
declare -r AWQL_QUERY_WITH="[Ww][Ii][Tt][Hh]"
declare -r AWQL_QUERY_DESC="[Dd][Ee][Ss][Cc] "
declare -r AWQL_QUERY_SELECT="[Ss][Ee][Ll][Ee][Cc][Tt] "
declare -r AWQL_QUERY_FROM=" [Ff][Rr][Oo][Mm] "
declare -r AWQL_QUERY_WHERE=" [Ww][Hh][Ee][Rr][Ee] "
declare -r AWQL_QUERY_DURING=" [Dd][Uu][Rr][Ii][Nn][Gg] "
declare -r AWQL_QUERY_ORDER_BY=" [Oo][Rr][Dd][Ee][Rr] [Bb][Yy] "
declare -r AWQL_QUERY_LIMIT=" [Ll][Ii][Mm][Ii][Tt] "

declare -r AWQL_TABLE_FIELD_NAME="Field"
declare -r AWQL_TABLE_FIELD_TYPE="Type"
declare -r AWQL_TABLE_FIELD_KEY="Key"
declare -r AWQL_TABLE_FIELD_EXTRA="Extra"
declare -r AWQL_FIELD_IS_KEY="MUL"
declare -r AWQL_TABLES_IN="Tables_in_"
declare -r AWQL_TABLES_WITH="_with_"
declare -r AWQL_GO_MODIFIER="\G"

# Workspace
if [ -n "$WRK_DIR" ]; then
    mkdir -p "$WRK_DIR"
fi