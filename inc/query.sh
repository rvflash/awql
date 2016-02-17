#!/usr/bin/env bash

# @includeBy /inc/awql.sh

##
# Return position of column to used as sort order
# @param string $1 Column order's name
# @param string $2 AWQL Query
# @return int
# @returnStatus 1 If query has no valid order column
function queryOrder ()
{
    local ORDER_COLUMN=0
    local ORDER="$1"
    if [[ -z "$ORDER" ]]; then
        return 1
    fi

    declare -a COLUMNS="($(echo "$2" | sed -e "s/${AWQL_QUERY_SELECT}[[:space:]]*//g" -e "s/[[:space:]]*${AWQL_QUERY_FROM}[[:space:]]*.*//g" -e "s/,/ /g"))"
    for COLUMN in "${COLUMNS[@]}"; do
        ORDER_COLUMN=$((ORDER_COLUMN+1))
        if [[ "$COLUMN" = "$ORDER" ]]; then
            echo "$ORDER_COLUMN"
            return
        fi
    done

    return 1
}

##
# Return sort order (1 for DESC, 0 for ASC)
# @param $1 Requested sort order
# @return int
function querySortOrder ()
{
    if [[ "$1" == "DESC" || "$1" == "desc" ]]; then
        echo -n "$AWQL_SORT_ORDER_DESC"
    else
        echo -n "$AWQL_SORT_ORDER_ASC"
    fi
}

##
# Return sort order (n for numeric, d for others)
# @param $1 Column data type
# @return string
function querySortOrderType ()
{
    if inArray "$1" "$AWQL_SORT_NUMERICS"; then
        echo -n "n"
    else
        echo -n "d"
    fi
}

##
# Check query to verify structure & limits
# @param string $1 Adwords ID
# @param string $2 Awql query
# @param string $3 API version
# @param int $4 Verbose
# @param int $5 Caching
# @return arrayToString Request
# @returnStatus 2 If query is empty
# @returnStatus 2 If query is not a valid AWQL method
# @returnStatus 2 If query is not a report table
# @returnStatus 1 If AdwordsId or apiVersion are invalids
function query ()
{
    local ADWORDS_ID="$1"
    local API_VERSION="$3"
    if [[ -z "${ADWORDS_ID}" || -z "${API_VERSION}" ]]; then
        return 1
    fi
    declare -A REQUEST="([LIMIT]=\"\" [ORDER]=\"\" [VERTICAL_MODE]=0)"

    # Manage vertical mode, also named G modifier
    local QUERY=$(trim "$2")
    local QUERY_ORIGIN="$QUERY"
    if [[ "${QUERY:${#QUERY}-1}" == [gG] ]]; then
        if [[ "${QUERY:${#QUERY}-2:1}" == "\\" ]]; then
            QUERY="${QUERY::-2}"
        else
            # Prompt mode
            QUERY="${QUERY::-1}"
        fi
        REQUEST["VERTICAL_MODE"]=1
    elif [[ "${QUERY:${#QUERY}-1}" == ";" ]]; then
        QUERY="${QUERY::-1}"
    elif [[ -z "$QUERY" ]]; then
        return 2
    fi

    # Protection against mal-formatted requests (space before (;) for example)
    QUERY="$(trim "$QUERY")"
    QUERY_ORIGIN="$QUERY"

    # Build all query properties
    declare -i VERBOSE="$4"
    declare -i CACHING="$5"
    REQUEST["VERBOSE"]=${VERBOSE}
    REQUEST["CACHING"]=${CACHING}
    REQUEST["ADWORDS_ID"]="${ADWORDS_ID}"
    REQUEST["API_VERSION"]="${API_VERSION}"
    REQUEST["METHOD"]="$(echo "$QUERY" | awk '{ print tolower($1) }')"

    # Management by query method
    if [[ -z "$QUERY_ORIGIN" ]]; then
        echo -n "QueryError.MISSING"
        return 2
    elif [[ "$QUERY_ORIGIN" == ${AWQL_QUERY_EXIT} || "$QUERY_ORIGIN" == ${AWQL_QUERY_QUIT} ]]; then
        # Awql command: Exit
        echo -n "${AWQL_PROMPT_EXIT}"
        return 1
    elif [[ "$QUERY_ORIGIN" == ${AWQL_QUERY_HELP} ]]; then
        # Awql command: Help
        awqlHelp
        return 2
    elif ! inArray "${REQUEST[METHOD]}" "$AWQL_QUERY_METHODS"; then
        echo -n "QueryError.INVALID_QUERY_METHOD"
        return 2
    fi

    # Dedicated behavior for select method
    if [[ "${REQUEST[METHOD]}" == "select" ]]; then
        # Manage the shorthand * to select all columns (without blacklisted fields)
        if [[ "$QUERY" == ${AWQL_QUERY_SELECT}[[:space:]]*"*"[[:space:]]*${AWQL_QUERY_FROM}* ]]; then
            QUERY=$(echo "$QUERY" | sed -e "s/^${AWQL_QUERY_SELECT}[[:space:]]*\*[[:space:]]*${AWQL_QUERY_FROM}[[:space:]]*//g")

            # Load table inormations
            local AWQL_TABLES
            AWQL_TABLES="$(awqlTables "${API_VERSION}")"
            if [[ $? -ne 0 ]]; then
                echo "$AWQL_TABLES"
                return 1
            fi
            declare -A -r AWQL_TABLES="$AWQL_TABLES"

            # Load list of blacklisted fields
            local AWQL_BLACKLISTED_FIELDS
            AWQL_BLACKLISTED_FIELDS="$(awqlBlacklistedFields "${API_VERSION}")"
            if [[ $? -ne 0 ]]; then
                echo "$AWQL_BLACKLISTED_FIELDS"
                return 1
            fi
            declare -A -r AWQL_BLACKLISTED_FIELDS="$AWQL_BLACKLISTED_FIELDS"

            local TABLE="${QUERY%% *}"
            if [[ -z "$TABLE" ]]; then
                echo "QueryError.INVALID_SELECT_CLAUSE"
                return 2
            fi
            local FIELDS="${AWQL_TABLES[$TABLE]}"
            if [[ -z "$FIELDS" ]]; then
                echo "QueryError.UNKNOWN_TABLE"
                return 2
            fi

            declare -ar TABLE_FIELDS=$(arrayDiff "$FIELDS" "${AWQL_BLACKLISTED_FIELDS[$TABLE]}")
            FIELDS="${TABLE_FIELDS[@]}"
            QUERY="SELECT ${FIELDS// /, } FROM ${QUERY}"
            QUERY_ORIGIN="$QUERY"
        fi

        # Manage Limit (remove it from query)
        QUERY=$(echo "$QUERY" | sed -e "s/[[:space:]]*${AWQL_QUERY_LIMIT}[[:space:]]*\([0-9;, ]*\)$//g")
        local LIMIT="${QUERY_ORIGIN:${#QUERY}}"
        if [[ "${#LIMIT}" -gt 0 ]]; then
            REQUEST["LIMIT"]="$(echo "$LIMIT" | sed 's/[^0-9,]*//g' | sed 's/,/ /g')"
            QUERY_ORIGIN="$QUERY"
        fi

        # Manage Order by (remove it from query)
        QUERY=$(echo "$QUERY" | sed -e "s/[[:space:]]*${AWQL_QUERY_ORDER_BY}[[:space:]]*.*//g")
        local ORDER_BY="${QUERY_ORIGIN:${#QUERY}}"
        if [[ "${#ORDER_BY}" -gt 0 ]]; then
            if [[ "$ORDER_BY" == *","* ]]; then
                echo "QueryError.MULTIPLE_ORDER_BY_NOT_AVAILABLE_YET"
                return 2
            else
                local AWQL_FIELDS
                AWQL_FIELDS="$(awqlFields "${API_VERSION}")"
                if [[ $? -ne 0 ]]; then
                    echo "QueryError.ORDER_COLUMN_UNDEFINED"
                    return 2
                fi
                declare -A -r AWQL_FIELDS="$AWQL_FIELDS"
                declare -a ORDER="(${ORDER_BY:9})"

                REQUEST["ORDER"]=$(queryOrder "${ORDER[0]}" "$QUERY")
                if [[ $? -ne 0 ]]; then
                    echo "QueryError.ORDER_COLUMN_UNKNOWN_IN_QUERY_FIELDS"
                    return 2
                fi
                REQUEST["ORDER"]="$(querySortOrderType "${AWQL_FIELDS[${ORDER[0]}]}") ${REQUEST["ORDER"]}"
                REQUEST["ORDER"]="${REQUEST["ORDER"]} $(querySortOrder "${ORDER[1]}")"
            fi
        fi
    fi

    # Calculate a unique identifier for the query
    REQUEST["CHECKSUM"]="$(checksum "$ADWORDS_ID $QUERY")"
    if [[ $? -ne 0 ]]; then
        echo "QueryError.MISSING_CHECKSUM"
        return 1
    fi

    # And the last but not the least
    REQUEST["QUERY"]="$QUERY"

    echo -n "$(arrayToString "$(declare -p REQUEST)")"
}