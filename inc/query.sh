#!/usr/bin/env bash

# @includeBy /inc/awql.sh

##
# Return position of column to used as sort order
# @param string $1 Column order's name
# @param string $2 AWQL Query
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
function querySortOrderType ()
{
    if inArray "$1" "$AWQL_SORT_NUMERICS"; then
        echo -n "n"
    else
        echo -n "d"
    fi
}

##
# Display information about available AWQL commmands
function help ()
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
# Check query to verify structure & limits
# @param string $1 Adwords ID
# @param string $2 Awql query
# @return arrayToString REQUEST
function query ()
{
    local ADWORDS_ID="$1"
    local QUERY=$(trim "$2")
    local QUERY_ORIGIN="$QUERY"

    declare -A REQUEST="([VERTICAL_MODE]=0 [LIMIT]=\"\" [ORDER]=\"\")"
    REQUEST["METHOD"]=$(echo "$QUERY" | awk '{ print tolower($1) }')

    # Manage vertical mode, also named G modifier
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
        # Empty query
        return 2
    fi

    # Protection against mal-formatted requests (space before (;) for example)
    QUERY="$(trim "$QUERY")"
    QUERY_ORIGIN="$QUERY"

    # Management by query method
    if [[ -z "$QUERY_ORIGIN" ]]; then
        echo "QueryError.MISSING"
        return 2
    elif [[ "$QUERY_ORIGIN" == ${AWQL_QUERY_EXIT} || "$QUERY_ORIGIN" == ${AWQL_QUERY_QUIT} ]]; then
        # Awql command: Exit
        echo "${AWQL_PROMPT_EXIT}"
        return 1
    elif [[ "$QUERY_ORIGIN" == ${AWQL_QUERY_HELP} ]]; then
        # Awql command: Help
        help
        return 2
    elif ! inArray "${REQUEST[METHOD]}" "$AWQL_QUERY_METHODS"; then
        echo "QueryError.INVALID_QUERY_METHOD"
        return 2
    fi

    # Dedicated behavior for select method
    if [[ "${REQUEST[METHOD]}" == "select" ]]; then
        # Manage the shorthand * to select all columns (without blacklisted fields)
        if [[ "$QUERY" == ${AWQL_QUERY_SELECT}[[:space:]]*"*"[[:space:]]*${AWQL_QUERY_FROM}* ]]; then
            QUERY=$(echo "$QUERY" | sed -e "s/^${AWQL_QUERY_SELECT}[[:space:]]*\*[[:space:]]*${AWQL_QUERY_FROM}[[:space:]]*//g")

            # Load table inormations
            local AWQL_TABLES
            AWQL_TABLES=$(awqlTables)
            if [[ $? -ne 0 ]]; then
                echo "$AWQL_TABLES"
                return 1
            fi
            declare -A -r AWQL_TABLES="$AWQL_TABLES"

            # Load list of blacklisted fields
            local AWQL_BLACKLISTED_FIELDS
            AWQL_BLACKLISTED_FIELDS=$(awqlBlacklistedFields)
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
            FIELDS=$(arrayDiff "$FIELDS" "${AWQL_BLACKLISTED_FIELDS[$TABLE]}")
            QUERY="SELECT ${FIELDS// /, } FROM $QUERY"
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
                AWQL_FIELDS=$(awqlFields)
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
    REQUEST["CHECKSUM"]=$(checksum "$ADWORDS_ID $QUERY")
    if [[ $? -ne 0 ]]; then
        echo "QueryError.MISSING_CHECKSUM"
        return 1
    fi

    # And the last but not the least
    REQUEST["QUERY"]="$QUERY"

    echo -n "$(arrayToString "$(declare -p REQUEST)")"
}