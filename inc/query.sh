#!/usr/bin/env bash

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

    declare -a COLUMNS="($(echo "$2" | sed -e "s/${AWQL_QUERY_SELECT} //g" -e "s/${AWQL_QUERY_FROM} .*//g" -e "s/,/ /g"))"
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
    if [[ "$1" == "DESC" ]] || [[ "$1" == "desc" ]]; then
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
    inArray "$1" "$AWQL_SORT_NUMERICS"
    if [[ $? -eq 0 ]]; then
        echo -n "n"
    else
        echo -n "d"
    fi
}

##
# Check query to verify structure & limits
# @param string $1 Adwords ID
# @param string $2 Awql query
# @return stringableArray REQUEST
function query ()
{
    local ADWORDS_ID="$1"
    local QUERY="$(trim "$2")"

    declare -A REQUEST="([VERTICAL_MODE]=0 [LIMIT_QUERY]=\"\" [ORDER_QUERY]=\"\")"

    local QUERY_ORIGIN="$QUERY"
    local QUERY_METHOD=$(echo "$QUERY" | awk '{ print tolower($1) }')

    # Manage vertical mode, also named G modifier
    if [[ "${QUERY:${#QUERY}-1}" == "g" ]] || [[ "${QUERY:${#QUERY}-1}" == "G" ]]; then
        if [[ "${QUERY:${#QUERY}-2:1}" == "\\" ]]; then
            QUERY="${QUERY::-2}"
        else
            # Prompt mode
            QUERY="${QUERY::-1}"
        fi
        REQUEST["VERTICAL_MODE"]=1
        QUERY_ORIGIN="$QUERY"
    elif [[ "${QUERY:${#QUERY}-1}" == ";" ]]; then
        QUERY="${QUERY::-1}"
        QUERY_ORIGIN="$QUERY"
    fi

    # Management by query method
    if [[ -z "$QUERY_ORIGIN" ]]; then
        echo "QueryError.MISSING"
        return 1
    elif ! inArray "$QUERY_METHOD" "$AWQL_QUERY_METHODS"; then
        echo "QueryError.INVALID_QUERY_METHOD"
        return 1
    fi

    # Dedicated behavior for select method
    if [[ "$QUERY_METHOD" == "select" ]]; then
        # Manage Limit (remove it from query)
        QUERY=$(echo "$QUERY" | sed -e "s/ ${AWQL_QUERY_LIMIT} \([0-9;, ]*\)$//g")
        local LIMIT="${QUERY_ORIGIN:${#QUERY}}"
        if [[ "${#LIMIT}" -gt 0 ]]; then
            REQUEST["LIMIT_QUERY"]="$(echo "$LIMIT" | sed 's/[^0-9,]*//g' | sed 's/,/ /g')"
            QUERY_ORIGIN="$QUERY"
        fi

        # Manage Order by (remove it from query)
        QUERY=$(echo "$QUERY" | sed -e "s/ ${AWQL_QUERY_ORDER_BY} .*//g")
        local ORDER_BY="${QUERY_ORIGIN:${#QUERY}}"
        if [[ "${#ORDER_BY}" -gt 0 ]]; then
            if [[ "$ORDER_BY" == *","* ]]; then
                echo "QueryError.MULTIPLE_ORDER_BY_NOT_AVAILABLE_YET"
                return 1
            else
                local AWQL_FIELDS=$(awqlFields "${AWQL_API_VERSION}")
                if [[ $? -ne 0 ]]; then
                    echo "QueryError.ORDER_COLUMN_UNDEFINED"
                    return 1
                fi
                declare -A -r AWQL_FIELDS="$AWQL_FIELDS"
                declare -a ORDER="(${ORDER_BY:9})"

                REQUEST["ORDER_QUERY"]=$(queryOrder "${ORDER[0]}" "$QUERY")
                if [[ $? -ne 0 ]]; then
                    echo "QueryError.ORDER_COLUMN_UNKNOWN_IN_QUERY_FIELDS"
                    return 1
                fi
                REQUEST["ORDER_QUERY"]="$(querySortOrderType "${AWQL_FIELDS[${ORDER[0]}]}") ${REQUEST["ORDER_QUERY"]} $(querySortOrder "${ORDER[1]}")"
            fi
        fi
    fi

    # Calculate a checksum for this query (usefull for unique identifier)
    REQUEST[CHECKSUM]=$(checksum "$ADWORDS_ID $QUERY")
    if [[ $? -ne 0 ]]; then
        echo "QueryError.MISSING_CHECKSUM"
        return 1
    fi

    # And save query
    REQUEST[QUERY]="$QUERY"

    echo -n $(stringableArray "$(declare -p REQUEST)")
}