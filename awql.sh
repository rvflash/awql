#!/usr/bin/env bash

##
# Provide interface to request Google Adwords with AWQL queries

# Envionnement
SCRIPT=$(basename ${BASH_SOURCE[0]})
SCRIPT_PATH="$0"; while [ -h "$SCRIPT_PATH" ]; do SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"; done
ROOT_DIR=$(dirname $SCRIPT_PATH)

# Requires
source "${ROOT_DIR}/conf/awql.sh"
source "${ROOT_DIR}/inc.common.sh"

# Default values
AUTH_FILE="${ROOT_DIR}/${AUTH_FILE_NAME}"
AWQL_FILE=""
QUERY=""
VERBOSE=0
CACHING=0

# Usage
function usage ()
{
    echo "Usage: ${SCRIPT} -i adwordsid [-a authfilepath] [-f awqlfilename] [-e query] [-c] [-v]"
    echo "-i for Adwords account ID"
    echo "-a for Yaml authorization file path with access and developper tokens"
    echo "-f for the filepath to save raw AWQL response"
    echo "-e for AWQL query, if not set here, a prompt will be launch"
    echo "-c used to enable cache"
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
# @param string $5 Enable caching
function awql ()
{
    local ADWORDS_ID="$1"
    local QUERY="$2"
    local AUTH_PATH="$3"
    local AWQL_FILE="$4"
    local VERBOSE="$5"
    local CACHING="$6"

    # Retrieve Google tokens
    auth "$AUTH_PATH"
    exitOnError $? "$ERR_MSG" "$VERBOSE"

    # Get Google request prperties
    request
    exitOnError $? "$ERR_MSG" "$VERBOSE"

    # Get a query validated and manage query limits
    checkQuery "$QUERY" "$REQUEST"
    exitOnError $? "$ERR_MSG" "$VERBOSE"

    # Calculate a checksum for this query (usefull for unique identifier)
    checksum "$ADWORDS_ID $QUERY"

    # Send request to Adwords or local cache to get report
    call "$ADWORDS_ID" "$QUERY" "$AUTH" "$REQUEST" "$CHECKSUM" "$VERBOSE" "$CACHING"
    local ERR_TYPE="$?"

    if [ "$ERR_TYPE" -ne 0 ]; then
        exitOnError "$ERR_TYPE" "$ERR_MSG" "$VERBOSE"
    else
        # Save response in an dedicated file
        if [ "$AWQL_FILE" != "" ] && [ ! -f "$AWQL_FILE" ]; then
            cp "$OUTPUT_FILE" "$AWQL_FILE"
            exitOnError $? "FileError.UNABLE_TO_SAVE" "$VERBOSE"
        fi
        # Print response
        print "$OUTPUT_FILE" "$OUTPUT_CACHED" "$TIME_DURATION" "$LIMIT_QUERY" "$ORDER_QUERY" "$VERBOSE"
    fi
}

##
# Get all fields names with for each, their description
# @example ([AccountDescriptiveName]="The descriptive name...")
# @param string $1 API version
# @return string ERR_MSG in case of return code greater than 0
# @return string AWQL_EXTRA with formated string for array bash from yaml file
function awqlExtra ()
{
    yamlToArray "${ROOT_DIR}/${API_DOC_DIR_NAME}/$1/${API_DOC_EXTRA_FILE_NAME}"
    if [ $? -ne 0 ]; then
        ERR_MSG="InternalError.INVALID_CONF_EXTRA"
        return 1
    fi
    AWQL_EXTRA="$YAML_TO_ARRAY"
}

##
# Get all fields names with for each, the type of data
# @example ([AccountDescriptiveName]="String")
# @param string $1 API version
# @return string ERR_MSG in case of return code greater than 0
# @return string AWQL_FIELDS with formated string for array bash from yaml file
function awqlFields ()
{
    yamlToArray "${ROOT_DIR}/${API_DOC_DIR_NAME}/$1/${API_DOC_FIELDS_FILE_NAME}"
    if [ $? -ne 0 ]; then
        ERR_MSG="InternalError.INVALID_CONF_FIELDS"
        return 1
    fi
    AWQL_FIELDS="$YAML_TO_ARRAY"
}

##
# Get all table names with for each, their structuring keys
# @example ([PRODUCT_PARTITION_REPORT]="ClickType Date...")
# @param string $1 API version
# @return string ERR_MSG in case of return code greater than 0
# @return string AWQL_KEYS with formated string for array bash from yaml file
function awqlKeys ()
{
    yamlToArray "${ROOT_DIR}/${API_DOC_DIR_NAME}/$1/${API_DOC_KEYS_FILE_NAME}"
    if [ $? -ne 0 ]; then
        ERR_MSG="InternalError.INVALID_CONF_KEYS"
        return 1
    fi
    AWQL_KEYS="$YAML_TO_ARRAY"
}

##
# Get all table names with for each, the list of fields
# @example ([PRODUCT_PARTITION_REPORT]="AccountDescriptiveName AdGroupId...")
# @param string $1 API version
# @return string ERR_MSG in case of return code greater than 0
# @return string AWQL_TABLES with formated string for array bash from yaml file
function awqlTables ()
{
    yamlToArray "${ROOT_DIR}/${API_DOC_DIR_NAME}/$1/${API_DOC_TABLES_FILE_NAME}"
    if [ $? -ne 0 ]; then
        ERR_MSG="InternalError.INVALID_CONF_TABLES"
        return 1
    fi
    AWQL_TABLES="$YAML_TO_ARRAY"
}

##
# Get data from cache if available
# @param string $1 Query checksum
# @param string $2 Enable caching
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
function cached ()
{
    local CHECKSUM="$1"
    local ENABLED="$2"

    OUTPUT_FILE="${WRK_DIR}/${CHECKSUM}${AWQL_FILE_EXT}"

    if [ -z "$CHECKSUM" ]; then
        ERR_MSG="CacheError.INVALID_KEY"
        return 1
    elif [ ! -f "$OUTPUT_FILE" ]; then
        ERR_MSG="CacheError.UNKNOWN_KEY"
        return 1
    elif [ "$ENABLED" -eq 0 ]; then
        ERR_MSG="CacheError.DISABLED"
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
# @param array $6 Verbose mode
# @param array $7 Enable caching
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
# @return bool OUTPUT_CACHED if 1, datas from local cache
function call ()
{
    cached "$5" "$7"
    if [ $? -gt 0 ]; then
        OUTPUT_CACHED=0
        declare -A -r GOOGLE_REQUEST="$4"
        local API_VERSION=${GOOGLE_REQUEST[API_VERSION]}
        local QUERY_METHOD=$(echo "$QUERY" | awk '{ print tolower($1) }')
        if [ "$QUERY_METHOD" = "select" ]; then
            download "$1" "$2" "$3" "$4" "$5" "$6"
        elif [ "$QUERY_METHOD" = "desc" ]; then
            desc "$2" "${API_VERSION}" "$5" "$6"
        elif [ "$QUERY_METHOD" = "show" ]; then
            show "$2" "${API_VERSION}" "$5" "$6"
        fi
        local ERR_TYPE="$?"
        if [ ${ERR_TYPE} -ne 0 ]; then
            # An error occured, remove cache file
            rm -f "${WRK_DIR}/${5}${AWQL_FILE_EXT}"
            return ${ERR_TYPE}
        fi
    else
        OUTPUT_CACHED=1
    fi
}

##
# Check query to verify structure & limits
# @param string $1 Awql query
# @param array $2 Google request properties
# @return string ERR_MSG in case of return code greater than 0
# @return string QUERY
# @return stringableArray LIMIT_QUERY
# @return int ORDER_QUERY
function checkQuery ()
{
    QUERY="$1"
    LIMIT_QUERY="()"
    ORDER_QUERY="()"

    local QUERY_ORIGIN="$QUERY"
    local QUERY_METHOD=$(echo "$QUERY" | awk '{ print tolower($1) }')

    if [ -z "$QUERY" ]; then
        ERR_MSG="QueryError.MISSING"
        return 1
    elif [ "$QUERY_METHOD" = "select" ]; then
        # Manage Limit (remove it from query)
        QUERY=$(echo "$QUERY" | sed -e "s/${AWQL_QUERY_LIMIT}\([0-9;, ]*\)$//g")
        local LIMIT="${QUERY_ORIGIN:${#QUERY}}"
        if [ "${#LIMIT}" -gt 0 ]; then
            LIMIT_QUERY="($(echo "$LIMIT" | sed 's/[^0-9,]*//g' | sed 's/,/ /g'))"
            QUERY_ORIGIN="$QUERY"
        fi
        # Manage Order by (remove it from query)
        QUERY=$(echo "$QUERY" | sed -e "s/${AWQL_QUERY_ORDER_BY}.*//g")
        local ORDER_BY="${QUERY_ORIGIN:${#QUERY}}"
        if [ "${#ORDER_BY}" -gt 0 ]; then
            if [[ "$ORDER_BY" == *","* ]]; then
                ERR_MSG="QueryError.MULTIPLE_ORDER_BY"
                return 1
            else
                declare -A -r GOOGLE_REQUEST="$2"
                awqlFields "${GOOGLE_REQUEST[API_VERSION]}"
                if [ $? -ne 0 ]; then
                    ERR_MSG="QueryError.ORDER_COLUMN_UNDEFINED"
                    return 1
                fi
                declare -A -r AWQL_FIELDS="$AWQL_FIELDS"
                declare -a ORDER="(${ORDER_BY:9})"

                ORDER_QUERY=$(queryOrder "${ORDER[0]}" "$QUERY")
                if [ $? -ne 0 ]; then
                    ERR_MSG="QueryError.ORDER_COLUMN_UNDEFINED"
                    return 1
                fi
                ORDER_QUERY="($(querySortOrderType "${AWQL_FIELDS[${ORDER[0]}]}") ${ORDER_QUERY} $(querySortOrder "${ORDER[1]}"))"
            fi
        fi
    elif [ "$QUERY_METHOD" != "desc" ] && [ "$QUERY_METHOD" != "show" ]; then
        ERR_MSG="QueryError.INVALID_QUERY_METHOD"
        return 1
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
    if [ -z "$TIME_DURATION" ]; then
        TIME_DURATION="0.01"
    fi
    CONTEXT="$CONTEXT ($TIME_DURATION sec)"

    if [ "$VERBOSE" -eq 1 ]; then
        # Source
        if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
            CONTEXT="$CONTEXT @source $FILE_PATH"

            # From cache ?
            if [ "$CACHED" -eq 1 ]; then
                CONTEXT="$CONTEXT @cached"
            fi
        fi
    fi
    echo -en "$CONTEXT\n"
}

##
# Allow access to table structure
# @param string $1 Awql query
# @param array $2 Google request properties
# @param array $3 Query checksum
# @param array $4 Verbose mode
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
function desc ()
{
    declare -a QUERY="($(echo "$1" | sed -e "s/${AWQL_QUERY_DESC}//g" -e "s/;//g"))"
    local TABLE="${QUERY[0]}"
    local COLUMN="${QUERY[1]}"
    local API_VERSION="$2"
    local CHECKSUM="$3"
    local OUTPUT_FILE="${WRK_DIR}/${CHECKSUM}${AWQL_FILE_EXT}"
    local VERBOSE="$4"

    awqlTables "${API_VERSION}"
    exitOnError $? "$ERR_MSG" "$VERBOSE"
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    awqlFields "${API_VERSION}"
    exitOnError $? "$ERR_MSG" "$VERBOSE"
    declare -A -r AWQL_FIELDS="$AWQL_FIELDS"

    awqlKeys "${API_VERSION}"
    exitOnError $? "$ERR_MSG" "$VERBOSE"
    declare -A -r AWQL_KEYS="$AWQL_KEYS"

    if [ -n "${AWQL_TABLES[$TABLE]}" ]; then
        # Desc header
        echo "${AWQL_TABLE_FIELD_NAME},${AWQL_TABLE_FIELD_TYPE},${AWQL_TABLE_FIELD_KEY}" > "$OUTPUT_FILE"
        # Give properties about each fields of this table
        local FIELD_IS_KEY=""
        local FIELDS="${AWQL_TABLES[$TABLE]}"
        for FIELD in ${FIELDS[@]}; do
            if [ -n "${AWQL_FIELDS[$FIELD]}" ] && ([ -z "$COLUMN" ] || [ "$COLUMN" = "$FIELD" ]); then
                inArray "$FIELD" "${AWQL_KEYS[$TABLE]}"
                if [ $? -eq 0 ]; then
                    FIELD_IS_KEY="${AWQL_FIELD_IS_KEY}"
                else
                    FIELD_IS_KEY=""
                fi
                echo "${FIELD},${AWQL_FIELDS[$FIELD]},${FIELD_IS_KEY}" >> "$OUTPUT_FILE"
            fi
        done
    else
        ERR_MSG="QueryError.UNEXISTANT_TABLE"
        return 1
    fi
}

##
# Send a curl request to Adwords API to get response for AWQL query
# @param string $1 Adwords ID
# @param string $2 Awql query
# @param array $3 Google authentification tokens
# @param array $4 Google request properties
# @param array $5 Query checksum
# @param array $6 verbose mode
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
# @retrun string TIME_DURATION Time duration in milliseconds
function download ()
{
    declare -A -r GOOGLE_AUTH="$3"
    declare -A -r GOOGLE_REQUEST="$4"

    local ADWORDS_ID="$1"
    local QUERY="$2"
    local CHECKSUM="$5"
    local OUTPUT_FILE="${WRK_DIR}/${CHECKSUM}${AWQL_FILE_EXT}"
    local VERBOSE="$6"

    # Define curl default properties
    local OPTIONS="--silent"
    if [ "$VERBOSE" -eq 1 ]; then
        OPTIONS="$OPTIONS --trace-ascii ${WRK_DIR}/${CHECKSUM}${AWQL_HTTP_RESPONSE_EXT}"
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
        --header "${GOOGLE_REQUEST[AUTHORIZATION]}:${GOOGLE_AUTH[TOKEN_TYPE]} ${GOOGLE_AUTH[ACCESS_TOKEN]}" \
        --header "${GOOGLE_REQUEST[DEVELOPER_TOKEN]}:${GOOGLE_AUTH[DEVELOPER_TOKEN]}" \
        --header "${GOOGLE_REQUEST[ADWORDS_ID]}:$ADWORDS_ID" \
        --output "$OUTPUT_FILE" \
        --write-out "([HTTP_CODE]=%{http_code} [TIME_TOTAL]='%{time_total}')" ${OPTIONS}
    )
    declare -A -r RESPONSE_INFO="$RESPONSE"

    if [ "${RESPONSE_INFO[HTTP_CODE]}" -eq 0 ] || [ "${RESPONSE_INFO[HTTP_CODE]}" -gt 400 ]; then
        ERR_MSG="ConnexionError.NOT_FOUND with API ${GOOGLE_REQUEST[API_VERSION]}"
        if [ "$VERBOSE" -eq 1 ]; then
            ERR_MSG+=" @source ${WRK_DIR}/${CHECKSUM}${AWQL_HTTP_RESPONSE_EXT}"
        fi
        return 1
    elif [ "${RESPONSE_INFO[HTTP_CODE]}" -gt 300 ]; then
        # An error occured, extract type and others informations from XML response
        ERR_TYPE=$(awk -F 'type>|<\/type' '{print $2}' "$OUTPUT_FILE")
        ERR_FIELD=$(awk -F 'fieldPath>|<\/fieldPath' '{print $2}' "$OUTPUT_FILE")
        if [ "$ERR_FIELD" != "" ]; then
            ERR_MSG="$ERR_TYPE regarding field(s) named $ERR_FIELD"
        fi
        ERR_MSG="$ERR_TYPE with API ${GOOGLE_REQUEST[API_VERSION]}"

        # Except for authentification errors, does not exit on each error, just notice it
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
# @param int $5 Order (ColumnName ColumnPosition SortOrder)
# @param string $7 Verbose mode
#
function print ()
{
    local WRK_FILE="$1"
    local FILE_SIZE=0
    local TIME_DURATION="$3"
    local CACHED="$2"
    local VERBOSE="$6"

    if [ -n "$WRK_FILE" ] && [ -f "$WRK_FILE" ]; then
        declare -a LIMIT_QUERY="$4"
        declare -a ORDER_QUERY="$5"

        local LIMIT_QUERY_SIZE="${#LIMIT_QUERY[@]}"
        local WRK_PRINTABLE_FILE="${WRK_FILE/.awql/.pcsv}"

        FILE_SIZE=$(wc -l < "$WRK_FILE")
        if [ "$FILE_SIZE" -gt 1 ]; then

            # Manage LIMIT queries
            if [ "$LIMIT_QUERY_SIZE" -eq 1 ] || [ "$LIMIT_QUERY_SIZE" -eq 2 ]; then
                # Limit size of datas to display (@see limit Adwords on daily report)
                local LIMITS="${LIMIT_QUERY[@]}"
                local WRK_PARTIAL_FILE="${WRK_FILE/.awql/_${LIMITS/ /-}.awql}"

                # Keep only first line for column names and lines in bounces
                if [ ! -f "$WRK_PARTIAL_FILE" ]; then
                    if [ "$LIMIT_QUERY_SIZE" -eq 2 ]; then
                        LIMITS="$((${LIMIT_QUERY[0]}+1)),$((${LIMIT_QUERY[0]}+${LIMIT_QUERY[1]}))"
                        sed -n -e 1p -e "${LIMITS}p" "$WRK_FILE" > "$WRK_PARTIAL_FILE"
                    else
                        LIMITS="1,$((${LIMIT_QUERY[0]}+1))"
                        sed -n -e "${LIMITS}p" "$WRK_FILE" > "$WRK_PARTIAL_FILE"
                    fi
                fi
                WRK_FILE="$WRK_PARTIAL_FILE"

                # Change file size
                if [ "$LIMIT_QUERY_SIZE" -eq 2 ]; then
                    FILE_SIZE="${LIMIT_QUERY[1]}"
                else
                    FILE_SIZE="${LIMIT_QUERY[0]}"
                fi
                FILE_SIZE="$((${FILE_SIZE}+1))"
            fi

            # Manage SORT ORDER queries
            if [ "${#ORDER_QUERY[@]}" -ne 0 ]; then
                local WRK_ORDERED_FILE="${WRK_FILE/.awql/_k${ORDER_QUERY[1]}-${ORDER_QUERY[2]}.awql}"
                if [ ! -f "$WRK_ORDERED_FILE" ]; then
                    local SORT_OPTIONS="-t, -k+${ORDER_QUERY[1]} -${ORDER_QUERY[0]}"
                    if [ "${ORDER_QUERY[2]}" -eq "$AWQL_SORT_ORDER_DESC" ]; then
                        SORT_OPTIONS+=" -r"
                    fi
                    head -1 "$WRK_FILE" > "$WRK_ORDERED_FILE"
                    sed 1d "$WRK_FILE" | sort ${SORT_OPTIONS} >> "$WRK_ORDERED_FILE"
                fi
                WRK_FILE="$WRK_ORDERED_FILE"
            fi

            # Format CVS to print it in shell terminal
            $(${ROOT_DIR}/vendor/shcsv/csv.sh -f "$WRK_FILE" -t "$WRK_PRINTABLE_FILE" -q)
            cat "$WRK_PRINTABLE_FILE"
        fi
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
    yamlToArray "${ROOT_DIR}/${REQUEST_FILE_NAME}"
    if [ $? -ne 0 ]; then
        ERR_MSG="QueryError.INVALID_CONF_REQUEST"
        return 1
    fi
    REQUEST="$YAML_TO_ARRAY"
}

##
# Allow access to table listing
# @param string $1 Awql query
# @param array $2 Google request properties
# @param array $3 Query checksum
# @param array $4 Verbose mode
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
function show ()
{
    # Removes mandatory or optionnal SQL terms
    declare -a QUERY="($(echo "$1" | sed -e "s/${AWQL_QUERY_SHOW}${AWQL_QUERY_SHOW_FULL}//g" -e "s/${AWQL_QUERY_SHOW}//g" -e "s/;//g"))"

    if [ -n "$(echo "${QUERY[0]}" | sed -e "s/${AWQL_QUERY_TABLES}//g")" ]; then
        ERR_MSG="QueryError.INVALID_SHOW_TABLES"
        return 1
    elif [ -z "$(echo "${QUERY[1]}" | sed -e "s/${AWQL_QUERY_LIKE}//g")" ]; then
        showLike "${QUERY[2]}" "$2" "$3" "$4"
    elif [ -z "$(echo "${QUERY[1]}" | sed -e "s/${AWQL_QUERY_WITH}//g")" ]; then
        showWith "${QUERY[2]}" "$2" "$3" "$4"
    else
        ERR_MSG="QueryError.INVALID_SHOW_TABLES_METHOD"
        return 1
    fi
}

##
# Allow access to table listing with method LIKE
# @param string $1 Table name or if empty it is means all tables
# @param array $2 Google Adwords API version
# @param array $3 Query checksum
# @param array $4 Verbose mode
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
function showLike ()
{
    local QUERY="$1"
    local API_VERSION="$2"
    local CHECKSUM="$3"
    local OUTPUT_FILE="${WRK_DIR}/${CHECKSUM}${AWQL_FILE_EXT}"
    local VERBOSE="$4"

    awqlTables "${API_VERSION}"
    exitOnError $? "$ERR_MSG" "$VERBOSE"
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    # List tables that match the search terms
    local SHOW_TABLES=""
    for TABLE in "${!AWQL_TABLES[@]}"; do
        # Also manage Like with %
        if [ -z "${QUERY#%}" ] || [ "${QUERY#%}" = "$TABLE" ] ||
           ([[ "$QUERY" == "%"*"%" ]] && [[ "$TABLE" == *"${QUERY:1:-1}"* ]]) ||
           ([[ "$QUERY" == "%"* ]] && [[ "$TABLE" == *"${QUERY:1}" ]]) ||
           ([[ "$QUERY" == *"%" ]] && [[ "$TABLE" == "${QUERY::-1}"* ]]); then

            if [ -n "$SHOW_TABLES" ]; then
                SHOW_TABLES+="\n"
            fi
            SHOW_TABLES+="${TABLE}"
        fi
    done

    if [ -n "$SHOW_TABLES" ]; then
        if [ -n "$QUERY" ]; then
            QUERY=" (${QUERY})"
        fi
        echo -e "${AWQL_TABLES_IN}${API_VERSION}${QUERY}" > "$OUTPUT_FILE"
        echo -e "${SHOW_TABLES}" | sort -t, -k+1 -d >> "$OUTPUT_FILE"
    fi
}

##
# Allow access to table listing with method WITH column_name
# @param string $1 Awql query
# @param array $2 Google Adwords API version
# @param array $3 Query checksum
# @param array $4 Verbose mode
# @return string ERR_MSG in case of return code greater than 0
# @return string OUTPUT_FILE Raw CSV filepath
function showWith ()
{
    local COLUMN="$1"
    if [ -z "$COLUMN" ]; then
        ERR_MSG="QueryError.MISSING_COLUMN_NAME"
        return 1
    fi

    local API_VERSION="$2"
    local CHECKSUM="$3"
    local OUTPUT_FILE="${WRK_DIR}/${CHECKSUM}${AWQL_FILE_EXT}"
    local VERBOSE="$4"

    awqlTables "${API_VERSION}"
    exitOnError $? "$ERR_MSG" "$VERBOSE"
    declare -A -r AWQL_TABLES="$AWQL_TABLES"

    # List tables that expose this column name
    local SHOW_TABLES=""
    for TABLE in "${!AWQL_TABLES[@]}"; do
        # Also manage Like with %
        inArray "$COLUMN" "${AWQL_TABLES[$TABLE]}"
        if [ $? -eq 0 ]; then
            if [ -n "$SHOW_TABLES" ]; then
                SHOW_TABLES+="\n"
            fi
            SHOW_TABLES+="${TABLE}"
        fi
    done

    if [ -n "$SHOW_TABLES" ]; then
        echo -e "${AWQL_TABLES_IN}${API_VERSION}${AWQL_TABLES_WITH}${COLUMN}" > "$OUTPUT_FILE"
        echo -e "${SHOW_TABLES}" | sort -t, -k+1 -d >> "$OUTPUT_FILE"
    fi
}

##
# Return position of column to used as sort order
# @param $1 Column order name
# @param $2 Query
function queryOrder ()
{
    local ORDER_COLUMN=0
    local ORDER="$1"
    if [ -z "$ORDER" ]; then
        return 1
    fi

    declare -a COLUMNS="($(echo "$2" | sed -e "s/${AWQL_QUERY_SELECT}//g" -e "s/${AWQL_QUERY_FROM}.*//g" -e "s/,/ /g"))"
    for COLUMN in "${COLUMNS[@]}"; do
        ORDER_COLUMN=$((ORDER_COLUMN+1))
        if [ "$COLUMN" = "$ORDER" ]; then
            echo "$ORDER_COLUMN"
            return
        fi
    done

    return 1
}

##
# Return sort order
# @param $1 Requested sort order
function querySortOrder ()
{
    if [ "$1" = "DESC" ] || [ "$1" = "desc" ]; then
        echo -n "$AWQL_SORT_ORDER_DESC"
    else
        echo -n "$AWQL_SORT_ORDER_ASC"
    fi
}

##
# Return sort order
# @param $1 Column data type
function querySortOrderType ()
{
    inArray "$1" "$AWQL_SORT_NUMERICS"
    if [ $? -eq 0 ]; then
        # Numeric sort
        echo -n "n"
    else
        echo -n "d"
    fi
}

# Script usage & check if mysqldump is availabled
if [ $# -lt 1 ] ; then
    usage
    exit 1
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "i::a::f::e:cv" FLAG; do
    case "${FLAG}" in
        i) ADWORDS_ID="$OPTARG" ;;
        a) if [ "${OPTARG:0:1}" = "/" ]; then AUTH_FILE="$OPTARG"; else AUTH_FILE="${ROOT_DIR}/${OPTARG}"; fi ;;
        f) if [ "${OPTARG:0:1}" = "/" ]; then AWQL_FILE="$OPTARG"; else AWQL_FILE="${ROOT_DIR}/${OPTARG}"; fi ;;
        e) QUERY="$OPTARG" ;;
        c) CACHING=1 ;;
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
        awql "$ADWORDS_ID" "$QUERY" "$AUTH_FILE" "$AWQL_FILE" "$VERBOSE" "$CACHING"
    done
else
    awql "$ADWORDS_ID" "$QUERY" "$AUTH_FILE" "$AWQL_FILE" "$VERBOSE" "$CACHING"
fi