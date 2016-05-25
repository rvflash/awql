#!/usr/bin/env bash

# @includeBy /core/query.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Return the list of field indexes to use as group, separated by space
# @param string $1 List of column to use as group, separated by comma
# @param string $2 List of column names to fetch, separated by space
# @param array $3 Aggregate columns list by type
# @return string
# @returnStatus 1 If query has no field
# @returnStatus 1 If third parameter named aggregates is not an array
function __queryGroupBy ()
{
    local groupQuery="$1"
    if [[ -z "$groupQuery" ]]; then
        return 0
    fi
    local fieldsQuery="$2"
    if [[ -z "$fieldsQuery"  ]]; then
        return 1
    fi
    if [[ "$3" != "("*")" ]]; then
        return 1
    fi
    declare -A aggregates="$3"

    local group=""
    declare -a fields=() groupFields=() groupBy=()
    IFS=" " read -a fields <<<"$fieldsQuery"
    IFS="," read -a groupFields <<<"$groupQuery"
    declare -i pos=0 groupColumn=0 numberGroups="${#groupFields[@]}" fieldsLength="${#fields[@]}"
    for (( pos=0; pos < ${numberGroups}; pos++ )); do
        group="$(trim "${groupFields[${pos}]}")"
        if [[ "$group" =~ ^[0-9]+$ ]]; then
            # Group by N
            groupColumn="$group"
            if [[ ${groupColumn} -le 0 || ${groupColumn} -gt ${fieldsLength} ]]; then
                echo "${AWQL_QUERY_ERROR_GROUP} with index '$group'"
                return 2
            fi
        else
            # Group by columnName
            groupColumn=$(arraySearch "$group" "$fieldsQuery")
            if [[ $? -ne 0 ]]; then
                echo "${AWQL_QUERY_ERROR_GROUP} on '$group'"
                return 2
            fi
            # Increment array key index
            groupColumn+=1
        fi

        # Check if we can group on this field
        if  inArray ${groupColumn} "${aggregates["${AWQL_AGGREGATE_AVG}"]}" || \
            inArray ${groupColumn} "${aggregates["${AWQL_AGGREGATE_DISTINCT}"]}" || \
            inArray ${groupColumn} "${aggregates["${AWQL_AGGREGATE_COUNT}"]}" || \
            inArray ${groupColumn} "${aggregates["${AWQL_AGGREGATE_MAX}"]}" || \
            inArray ${groupColumn} "${aggregates["${AWQL_AGGREGATE_MIN}"]}" || \
            inArray ${groupColumn} "${aggregates["${AWQL_AGGREGATE_SUM}"]}";
        then
            echo "${AWQL_QUERY_ERROR_GROUP} on aggregated field named '$group'"
            return 2
        fi

        # @fields CampaignId, CampaignName
        # @groupBy CampaignId
        # @example 1
        groupBy+=(${groupColumn})
    done
    echo "${groupBy[@]}"
}

##
# Get query sort order
# @param string $1 Requested sort order
# @return int 1 for DESC, 0 for ASC
# @returnStatus 1 if sort order is not ASC or DESC
function __queryOrder ()
{
    if [[ "$1" == ${AWQL_QUERY_DESC} ]]; then
        echo "${AWQL_SORT_ORDER_DESC}"
    elif [[ -z "$1" || "$1" == ${AWQL_QUERY_ASC} ]]; then
        echo "${AWQL_SORT_ORDER_ASC}"
    else
        return 1
    fi
}

##
# Return sort order (n for numeric, d for others)
# @param $1 Column data type
# @return string
function __queryOrderType ()
{
    if inArray "$1" "${AWQL_SORT_NUMERICS}"; then
        # Numeric order
        echo "n"
    else
        echo "d"
    fi
}

##
# Return the list of field indexes, with type and order to use as sort order, separated by comma
# @param string $1 List of column to use as sort order, separated by comma
# @param string $2 List of column names to fetch, separated by space
# @param string $3 List of column to fetch, separated by space
# @param string $4 Api version
# @return string
# @returnStatus 1 If query has no field
# @returnStatus 1 If api version is not valid
function __querySortOrder ()
{
    local orderQuery="$1"
    if [[ -z "$orderQuery" ]]; then
        return 0
    fi
    local fieldsQuery="$2"
    if [[ -z "$fieldsQuery" ]]; then
        return 1
    fi
    declare -a fields
    IFS=" " read -a fields <<<"$3"
    declare -i fieldsLength="${#fields[@]}"
    if [[ 0 -eq ${fieldsLength} ]]; then
        return 1
    fi
    local apiVersion="$4"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        return 1
    fi

    local type="" orderBy=""
    declare -A fieldsType="$(awqlFields "$apiVersion")"
    declare -a orderFields=()
    IFS="," read -a orderFields <<<"$orderQuery"
    declare -i pos=0 numberOrders="${#orderFields[@]}" orderColumn=0 sortOrder=0
    for (( pos=0; pos < ${numberOrders}; pos++ )); do
        declare -a order="(${orderFields[${pos}]})"
        if [[ "${order[0]}" =~ ^[0-9]+$ ]]; then
            # Order by N
            orderColumn="${order[0]}"
            if [[ ${orderColumn} -eq 0 || ${orderColumn} -gt ${fieldsLength} ]]; then
                echo "${AWQL_QUERY_ERROR_ORDER} with index '${orderColumn}'"
                return 2
            fi
        else
            # Order by columnName
            orderColumn=$(arraySearch "${order[0]}" "$fieldsQuery")
            if [[ $? -ne 0 ]]; then
                echo "${AWQL_QUERY_ERROR_ORDER} on '${order[0]}' (only query field names are available)"
                return 2
            fi
            # Increment array key index
            orderColumn+=1
        fi
        type="${fieldsType["${fields[$((${orderColumn}-1))]}"]}"
        if [[ -z "$type" ]]; then
            echo "${AWQL_QUERY_ERROR_COLUMN_TYPE} with '${fields[$((${orderColumn}-1))]}'"
            return 1
        fi
        sortOrder="$(__queryOrder "${order[1]}")"
        if [[ $? -ne 0 ]]; then
            echo "${AWQL_QUERY_ERROR_ORDER} with '${orderFields[${pos}]}'"
            return 2
        fi

        # @fields CampaignId, CampaignName
        # @orderBy CampaignName ASC
        # @example d 2 0
        if [[ -n "$orderBy" ]]; then
            orderBy+=","
        fi
        orderBy+="$(__queryOrderType "$type") $orderColumn $sortOrder"
    done

    echo "$orderBy"
}

##
# Parse a AWQL SELECT query to split it by its component
#
# Order: SELECT...FROM...WHERE...DURING...ORDER BY...LIMIT...
#
# @response
# > STATEMENT       : SELECT
# > FIELD_NAMES     : CampaignId, Name, Status, Impressions, Clicks
# > FIELDS          : CampaignId CampaignName CampaignStatus Impressions Clicks
# > HEADERS         : ,Name,Status,,
# > TABLE           : CAMPAIGN_PERFORMANCE_REPORT
# > WHERE           : Impressions > O
# > DURING          :
# > GROUP           : 1
# > ORDER           : Clicks DESC
# > LIMIT           : 5
# > VIEW            : 0
# > QUERY           : SELECT CampaignId, CampaignName AS Name, CampaignStatus AS Status, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O GROUP BY Id ORDER BY Clicks DESC
# > AWQL_QUERY      : SELECT CampaignId, CampaignName, CampaignStatus, Impressions, Clicks FROM CAMPAIGN_PERFORMANCE_REPORT WHERE Impressions > O
#
# @param string $1 Query
# @param string $2 Api version
# @return arrayToString Query component
# @returnStatus 1 If query is malformed
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If query is empty
function awqlSelectQuery ()
{
    local queryStr="$(trim "$1")"
    if [[ -z "$queryStr" ]]; then
        echo "${AWQL_INTERNAL_ERROR_QUERY}"
        return 1
    fi
    local apiVersion="$2"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        echo "${AWQL_INTERNAL_ERROR_API_VERSION}"
        return 1
    fi

    # Query components
    declare -a queryFields
    declare -A components

    # During literal dates
    local duringLiteral="${AWQL_COMPLETE_DURING[@]}"

    # Parse query char by char
    local name="${AWQL_REQUEST_STATEMENT}"
    local char part
    declare -i pos=0 queryLength="${#queryStr}"
    for (( pos = 0; pos <= ${queryLength}; ++pos )); do
        # Manage end of query
        if [[ ${pos} -lt ${queryLength} ]]; then
            char="${queryStr:$pos:1}"
            if [[ "$char" == [[:space:]] ]]; then
                char=" "
            fi
        else
            char=" "
        fi
        # Split by components
        case "$name" in
            ${AWQL_REQUEST_STATEMENT})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_SELECT} ]]; then
                        components["$name"]="$part"
                        part=""
                        name=${AWQL_REQUEST_FIELDS}
                    else
                        echo "${AWQL_QUERY_ERROR_METHOD}"
                        return 2
                    fi
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_FIELDS})
                if [[ "$part" == *[[:space:]]*${AWQL_QUERY_FROM} ]]; then
                    # Get rest of fields without from method
                    queryFields+=("${part%%\ ${AWQL_QUERY_FROM}*}")
                    part=""
                    name=${AWQL_REQUEST_TABLE}
                elif [[ "$char" == "," ]]; then
                    if [[ -n "$part" ]]; then
                        queryFields+=("$part")
                        part=""
                    fi
                elif [[ -n "$part" || "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_TABLE})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ -z "${components["$name"]}" ]]; then
                        components["$name"]="$part"
                    elif [[ "$part" == ${AWQL_QUERY_WHERE} ]]; then
                        name=${AWQL_REQUEST_WHERE}
                    elif [[ "$part" == ${AWQL_QUERY_DURING} ]]; then
                        name=${AWQL_REQUEST_DURING}
                    elif [[ "$part" == ${AWQL_QUERY_GROUP} ]]; then
                        name=${AWQL_REQUEST_GROUP}
                    elif [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_WHERE})
                 if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_DURING} ]]; then
                        name=${AWQL_REQUEST_DURING}
                    elif [[ "$part" == ${AWQL_QUERY_GROUP} ]]; then
                        name=${AWQL_REQUEST_GROUP}
                    elif [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif [[ -n "${components["$name"]}" ]]; then
                        components["$name"]+=" $part"
                    else
                        components["$name"]="$part"
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_DURING})
                if ([[ "$char" == " " || "$char" == "," ]]) && [[ -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_GROUP} ]]; then
                        name=${AWQL_REQUEST_GROUP}
                    elif [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif inArray "$part" "$duringLiteral"; then
                        components["$name"]="$part"
                    elif [[ "$part" =~ ^[[:digit:]]{8}$ ]]; then
                        if [[ -n "${components["$name"]}" ]]; then
                            components["$name"]+=" $part"
                        else
                            components["$name"]="$part"
                        fi
                    else
                        echo "${AWQL_QUERY_ERROR_DURING}"
                        return 2
                    fi
                    part=""
                elif [[ "$char" != " " && "$char" != "," ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_GROUP})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_ORDER} ]]; then
                        name=${AWQL_REQUEST_ORDER}
                    elif [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif [[ ! ${components["$name"]+rv} ]]; then
                        if [[ "$part" != ${AWQL_QUERY_BY} ]]; then
                            echo "${AWQL_QUERY_ERROR_GROUP}"
                            return 2
                        else
                            components["$name"]=""
                        fi
                    elif [[ -n "${components["$name"]}" ]]; then
                        components["$name"]+="$part"
                    else
                        components["$name"]="$part"
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_ORDER})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" == ${AWQL_QUERY_LIMIT} ]]; then
                        name=${AWQL_REQUEST_LIMIT}
                    elif [[ ! ${components["$name"]+rv} ]]; then
                        if [[ "$part" != ${AWQL_QUERY_BY} ]]; then
                            echo "${AWQL_QUERY_ERROR_ORDER}"
                            return 2
                        else
                            components["$name"]=""
                        fi
                    elif [[ -n "${components["$name"]}" ]]; then
                        components["$name"]+=" $part"
                    else
                        components["$name"]="$part"
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_LIMIT})
                if ([[ "$char" == " " || "$char" == "," ]]) && [[ -n "$part" ]]; then
                    if [[ "$part" =~ ^[0-9]+$ ]]; then
                        if [[ -n "${components["$name"]}" ]]; then
                            components["$name"]+=" $part"
                        else
                            components["$name"]="$part"
                        fi
                    else
                        echo "${AWQL_QUERY_ERROR_LIMIT}"
                        return 2
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            *)
                echo "${AWQL_INTERNAL_ERROR_QUERY_COMPONENT}"
                return 1
                ;;
        esac
    done

    # Empty query
    declare -i fieldsLength="${#queryFields[@]}"
    if [[ -z "${components["${AWQL_REQUEST_TABLE}"]}" || ${fieldsLength} -eq 0 ]]; then
        echo "${AWQL_QUERY_ERROR_SYNTAX}"
        return 2
    fi

    # Check if it is a valid report table or view
    declare -i isView=0
    declare -A -r views="$(awqlViews)"
    declare -A -r primaryKeys="$(awqlPrimaryKeys "$apiVersion")"
    declare -A -r tables="$(awqlTables "$apiVersion")"
    if [[ 0 -eq "${#tables[@]}" ]]; then
        echo "${AWQL_INTERNAL_ERROR_INVALID_TABLES}"
        return 1
    fi
    local tableNames="${!tables[@]}"
    if inArray "${components["${AWQL_REQUEST_TABLE}"]}" "$tableNames"; then
        declare -A -r tableFields="$(arrayFillKeys "${tables["${components["${AWQL_REQUEST_TABLE}"]}"]}" 1)"
    else
        # Here also check for view
        if [[ -z "${views["${components["${AWQL_REQUEST_TABLE}"]}"]}" ]]; then
            echo "${AWQL_QUERY_ERROR_TABLE}"
            return 2
        fi
        isView=1

        declare -A -r view="${views["${components["${AWQL_REQUEST_TABLE}"]}"]}"
        declare -A -r tableFields="$(arrayCombine "${view["${AWQL_VIEW_NAMES}"]}" "${view["${AWQL_VIEW_FIELDS}"]}")"
        declare -A -r viewFields="$(arrayCombine "${view["${AWQL_VIEW_FIELDS}"]}" "${view["${AWQL_VIEW_NAMES}"]}")"
        # Overload query table name by view name
        components["${AWQL_REQUEST_TABLE}"]="${view["${AWQL_VIEW_TABLE}"]}"
    fi

    # Awql fields
    if [[ 1 -eq ${fieldsLength} && "*" == "${queryFields[0]}" ]]; then
        # All pattern is only allowed on table view
        if [[ 0 -eq ${isView} ]]; then
            echo "${AWQL_QUERY_ERROR_SELECT_ALL}"
            return 2
        fi
        IFS=" " read -a queryFields <<<"${view["${AWQL_VIEW_NAMES}"]}"
        fieldsLength="${#queryFields[@]}"
    fi

    # > Extract function, user alias name and column name for each field
    local field fieldName func headers
    declare -A aggregates=()
    declare -a fields fieldNames
    declare -i pos fieldPos
    for (( pos=0; pos < ${fieldsLength}; pos++ )); do
        # Data field
        field="${queryFields[${pos}]}"
        fieldPos=$((${pos}+1))

        # Invalid query pattern
        if [[ "$field" == "*" ]]; then
            echo "${AWQL_QUERY_ERROR_SYNTAX}"
            return 2
        fi

        # Manage alias name like `CampaignId AS Id`
        if [[ "$field" == *\ ${AWQL_QUERY_AS}\ * ]]; then
            fieldName="${field##*\ ${AWQL_QUERY_AS}\ }"
            field="${field%%\ ${AWQL_QUERY_AS}\ *}"
        else
            fieldName=""
        fi

        # Manage query methods (SUM, COUNT, MAX, MIN, AVG, DISTINCT)
        if [[ "$field" == *[\(\)]* ]]; then
            # Is a valid function ?
            func="$(toUpper "${field%%\(*}")"
            if ! awqlFunction "$func"; then
                echo "${AWQL_QUERY_ERROR_FUNCTION} named '${func}'"
                return 2
            fi
            # Extract only value between parentheses
            field="${field##*\(}"
            field="${field%%\)*}"
            if [[ "$field" == ${AWQL_FUNCTION_DISTINCT}\ * ]]; then
                if [[ "$func" != ${AWQL_FUNCTION_COUNT} ]]; then
                    echo "${AWQL_QUERY_ERROR_DISTINCT} near '${field}'"
                    return 2
                fi
                if [[ -n "${aggregates["${AWQL_AGGREGATE_DISTINCT}"]}" ]]; then
                    aggregates["${AWQL_AGGREGATE_DISTINCT}"]+=" ${fieldPos}"
                else
                    aggregates["${AWQL_AGGREGATE_DISTINCT}"]="${fieldPos}"
                fi
                field="${field##*${AWQL_FUNCTION_DISTINCT}\ }"
            fi
            # Try to also manage shortcut's keyword like `COUNT(1`) or `COUNT(*)`
            if [[ "$field" =~ [1-9\*]+ ]]; then
                # Get the primary key of the current table as field value
                field="${primaryKeys["${components["${AWQL_REQUEST_TABLE}"]}"]}"
                if [[ ${isView} -eq 1 && -z "${tableFields["${field}"]}" ]]; then
                    # Manage case when the primary is renamed in view
                    if [[ -z "${viewFields["${field}"]}" ]]; then
                        echo "${AWQL_QUERY_ERROR_PRIMARY_KEY} named '${field}'"
                        return 2
                    fi
                    fieldName="$field"
                    field="${viewFields["${field}"]}"
                fi
            fi
            if [[ -n "${aggregates["$func"]}" ]]; then
                aggregates["$func"]+=" ${fieldPos}"
            else
                aggregates["$func"]="${fieldPos}"
            fi
        elif [[ "$field" == ${AWQL_FUNCTION_DISTINCT}\ * ]]; then
            if [[ 1 -gt ${fieldPos} ]]; then
                echo "${AWQL_QUERY_ERROR_DISTINCT} near '${field}'"
                return 2
            fi
            if [[ -n "${aggregates["${AWQL_AGGREGATE_DISTINCT}"]}" ]]; then
                aggregates["${AWQL_AGGREGATE_DISTINCT}"]+=" ${fieldPos}"
            else
                aggregates["${AWQL_AGGREGATE_DISTINCT}"]="${fieldPos}"
            fi
            field="${field##*${AWQL_FUNCTION_DISTINCT}\ }"
        fi

        # Validate field's name
        if [[ -z "${tableFields["$field"]}" ]]; then
            echo "${AWQL_QUERY_ERROR_UNKNOWN_FIELD} named '${field}'"
            return 2
        elif [[ ${isView} -eq 1 && "$field" != "${tableFields["$field"]}" ]]; then
            fieldName="$field"
            field="${tableFields["$field"]}"
        fi

        # Headers
        if [[ -z "$fieldName" ]]; then
            fieldName="$field"
        else
            # Protect CSV fields
            if [[ "$fieldName" == *","* ]]; then
                fieldName="\"${fieldName}\""
            fi
            headers+="${fieldName}"
        fi
        if [[ ${fieldPos} -lt ${fieldsLength} ]]; then
            headers+=","
        fi
        fieldNames+=("$fieldName")
        fields+=("$field")
    done

    # Fields
    local fieldsList="${fields[@]}"
    local fieldNamesList="${fieldNames[@]}"
    local aggregateFieldsList="$(arrayToString "$(declare -p aggregates)")"
    if ! [[ "$headers" =~ ^[,]+$ ]]; then
        components["${AWQL_REQUEST_HEADERS}"]="$headers"
    fi
    components["${AWQL_REQUEST_FIELDS}"]="$fieldsList"
    components["${AWQL_REQUEST_FIELD_NAMES}"]="$fieldNamesList"
    components["${AWQL_REQUEST_AGGREGATES}"]="$aggregateFieldsList"

    # Where
    if [[ ${isView} -eq 1 && -n "${view["${AWQL_VIEW_WHERE}"]}" ]]; then
        if [[ -n "${components["${AWQL_REQUEST_WHERE}"]}" ]]; then
            components["${AWQL_REQUEST_WHERE}"]="(${components["${AWQL_REQUEST_WHERE}"]}) AND "
        fi
        components["${AWQL_REQUEST_WHERE}"]+="${view["${AWQL_VIEW_WHERE}"]}"
    fi

    # During
    if [[ ${isView} -eq 1 && -n "${view["${AWQL_VIEW_DURING}"]}" ]]; then
        # Try to optimize it by managing difference between during ranges
        components["${AWQL_REQUEST_DURING}"]="${view["${AWQL_VIEW_DURING}"]}"
    fi
    declare -a durings
    IFS=" " read -a durings <<<"${components["${AWQL_REQUEST_DURING}"]}"
    declare -i numberDuring="${#durings[@]}"
    if ([[ 1 -eq ${numberDuring} && "${durings[0]}" =~ ^[[:digit:]]{8}$ ]]) || [[ ${numberDuring} -gt 2 ]]; then
        echo "${AWQL_QUERY_ERROR_DURING}"
        return 2
    fi

    # Group by
    local groups
    groups="$(__queryGroupBy "${components["${AWQL_REQUEST_GROUP}"]}" "$fieldNamesList" "$aggregateFieldsList")"
    if [[ $? -gt 0 ]]; then
        echo "$groups"
        return 2
    fi
    # to do : use #${view["${AWQL_VIEW_GROUP}"]} in case of view
    components["${AWQL_REQUEST_GROUP}"]="$groups"

    # Order by
    local orders
    orders="$(__querySortOrder "${components["${AWQL_REQUEST_ORDER}"]}" "$fieldNamesList" "$fieldsList" "$apiVersion")"
    if [[ $? -gt 0 ]]; then
        echo "$orders"
        return 2
    fi
    # to do : use #${view["${AWQL_VIEW_ORDER}"]} in case of view
    components["${AWQL_REQUEST_ORDER}"]="$orders"

    # Build AWQL query: SELECT...FROM...WHERE...DURING...
    declare -a awqlQuery
    awqlQuery+=("${components["${AWQL_REQUEST_STATEMENT}"]}")
    awqlQuery+=("${fieldsList// /,}")
    awqlQuery+=("FROM ${components["${AWQL_REQUEST_TABLE}"]}")
    if [[ -n "${components["${AWQL_REQUEST_WHERE}"]}" ]]; then
        awqlQuery+=("${AWQL_REQUEST_WHERE} ${components["${AWQL_REQUEST_WHERE}"]}")
    fi
    if [[ -n "${components["${AWQL_REQUEST_DURING}"]}" ]]; then
        awqlQuery+=("${AWQL_REQUEST_DURING} ${components["${AWQL_REQUEST_DURING}"]// /,}")
    fi
    components["${AWQL_REQUEST_QUERY}"]="${awqlQuery[@]}"
    components["${AWQL_REQUEST_QUERY_SOURCE}"]="$queryStr"
    components["${AWQL_REQUEST_VIEW}"]=${isView}
    components["${AWQL_REQUEST_TYPE}"]="select"

    arrayToString "$(declare -p components)"
}