#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
fi

##
# Manage aggregate methods (distinct, count, sum, min, max, avg and group by)
# @example ([DISTINCT]="1" [COUNT]="2 3" [SUM]="4")
# @example ([COUNT]="2" [GROUP_BY]="1")
# @example ([COUNT]="1")
# @param string $1 Filepath
# @param string $2 Aggregates
# @param string $3 Group
# @return string Filepath
function __aggregateRows ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" || "$file" != *"${AWQL_FILE_EXT}" ]]; then
        return 1
    fi
    if [[ -z "$2" ]]; then
        echo "$file"
        return 0
    elif [[ "$2" != "("*")" ]]; then
        return 1
    fi
    declare -A aggregates="$2"
    if [[ 0 -eq "${#aggregates[@]}" ]]; then
        echo "$file"
        return 0
    fi
    local groupBy="$3"

    local extendedFile=""
    declare -a aggregateOptions=()
    if [[ -n "$groupBy" ]]; then
        extendedFile+="${AWQL_AGGREGATE_GROUP}${groupBy/ /-}"
        aggregateOptions+=("-v groupByColumns=\"$groupBy\"")
    fi

    local type="" fields=""
    for type in "${!aggregates[@]}"; do
        fields="${aggregates["${type}"]}"
        if [[ -z "$fields" ]]; then
            return 1
        fi
        case "$type" in
            "${AWQL_AGGREGATE_AVG}")
                aggregateOptions+=("-v avgColumns=\"$fields\"")
                ;;
            "${AWQL_AGGREGATE_DISTINCT}")
                aggregateOptions+=("-v distinctColumns=\"$fields\"")
                ;;
            "${AWQL_AGGREGATE_COUNT}")
                aggregateOptions+=("-v countColumns=\"$fields\"")
                ;;
            "${AWQL_AGGREGATE_MAX}")
                aggregateOptions+=("-v maxColumns=\"$fields\"")
                ;;
            "${AWQL_AGGREGATE_MIN}")
                aggregateOptions+=("-v minColumns=\"$fields\"")
                ;;
            "${AWQL_AGGREGATE_SUM}")
                aggregateOptions+=("-v sumColumns=\"$fields\"")
                ;;
            *)
                return 1
                ;;
        esac
        extendedFile+="${type}${fields/ /-}"
    done

    local wrkFile="${file//${AWQL_FILE_EXT}/___${extendedFile}${AWQL_FILE_EXT}}"
    if [[ -f "$wrkFile" ]]; then
        # Job already done
        echo "$wrkFile"
        return 0
    fi

    awk -v ${aggregateOptions[@]} -f "${AWQL_TERM_TABLES_DIR}/aggregate.awk" "$file" > "$wrkFile"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo "$wrkFile"
}

##
# Manage limit clause
# @example 5 10
# @param string $1 Filepath
# @param string $2 Limits
# @return string Filepath
function __limitRows ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" || "$file" != *"${AWQL_FILE_EXT}" ]]; then
        return 1
    fi
    declare -a limit="($2)"
    declare -i limitRange="${#limit[@]}"
    if [[ 0 -eq ${limitRange} ]]; then
        echo "$file"
        return 0
    elif [[ ${limitRange} -ne 1 || ${limitRange} -ne 2 ]]; then
        return 1
    fi

    # Limit size of data to display
    local limits="${limit[@]}"
    local wrkFile="${file//${AWQL_FILE_EXT}/_${limits/ /-}${AWQL_FILE_EXT}}"
    if [[ -f "$wrkFile" ]]; then
        # Job already done
        echo "$wrkFile"
        return 0
    fi

    # Keep only first line for column names and lines in bounces
    declare -a limitOptions=()
    limitOptions+=("-v withHeader=1")
    if [[ ${limitRange} -eq 2 ]]; then
        limitOptions+=("-v rowOffset=${limit[0]}")
        limitOptions+=("-v rowCount=${limit[1]}")
    else
        limitOptions+=("-v rowCount=${limit[0]}")
    fi
    awk ${limitOptions[@]} -f "${AWQL_TERM_TABLES_DIR}/termTable.awk" "$file" > "$wrkFile"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo "$wrkFile"
}

##
# Manage order clause
# @example d 2 0
# @param string $1 Filepath
# @param string $2 OrderBy
# @return string Filepath
function __sortingRows ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" || "$file" != *"${AWQL_FILE_EXT}" ]]; then
        return 1
    fi
    declare -a orders
    IFS="," read -a orders <<<"$2"
    declare -i numberOrders="${#orders[@]}"
    if [[ 0 -eq ${numberOrders} ]]; then
        echo "$file"
        return 0
    fi

    local wrkFile="${file//${AWQL_FILE_EXT}/__${orders/ /-}${AWQL_FILE_EXT}}"
    if [[ -f "$wrkFile" ]]; then
        # Job already done
        echo "$wrkFile"
        return 0
    fi

    # Input field separator
    declare -a sortOptions=()
    sortOptions+=("-t,")

    local sort=""
    declare -i pos=0
    for (( pos=0; pos < ${numberOrders}; pos++ )); do
        declare -a order="(${orders[${pos}]})"
        if [[ 3 -ne "${#order[@]}" ]]; then
            return 1
        fi

        # Also see syntax: -k+${order[1]} -${order[0]} [-r]
        sort="-k${order[1]},${order[1]}${order[0]}"
        if [[ ${AWQL_SORT_ORDER_DESC} -eq ${order[2]} ]]; then
            sort+=("r")
        fi
        sortOptions+=("$sort")
    done

    head -1 "$file" > "$wrkFile" && sed 1d "$file" | sort ${sortOptions[@]} >> "$wrkFile"
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo "$wrkFile"
}

##
# Add context of the query (time duration & number of lines)
# @example 2 rows in set (0.93 sec)
#
# @param string $1 File path
# @param int $2 Number of line
# @param float $3 Time duration in milliseconds to get the data
# @param int $4 Caching
# @param int $5 Verbose
# @return string
function __printContext ()
{
    local file="$1"
    declare -i fileSize="$2"
    local timeDuration="$3"
    declare -i cache="$4"
    declare -i verbose="$5"

    # Size
    local size
    if [[ ${fileSize} -lt 2 ]]; then
        size="Empty set"
    elif [[ ${fileSize} -eq 2 ]]; then
        size="1 row in set"
    else
        # Exclude header line
        size="$(($fileSize-1)) rows in set"
    fi

    # Time duration
    local duration
    if [[ -z "$timeDuration" ]]; then
        timeDuration="0.00"
    fi
    duration="${timeDuration/,/.}"

    # File path & cache
    local source
    if [[ ${verbose} -eq 1 ]]; then
        if [[ -n "$file" && -f "$file" ]]; then
            source="@source ${file}"
            if [[ ${cache} -eq 1 ]]; then
                source="${source} @cached"
            fi
        fi
    fi

    printf "%s (%s sec) %s\n\n" "$size" "$duration" "$source"
}

##
# Print CSV file with termTables
#
# @param string $1 File path
# @param int $2 Vertical mode
# @param string $3 Headers
# @return string
# @returnStatus 1 If file is empty or do not exist
function __printFile ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" ]]; then
        return 1
    fi
    declare -i vertical="$2"
    local headers="$3"

    # Format CVS to display it in a shell terminal
    declare -a csvOptions=()
    if [[ ${vertical} -eq 1 ]]; then
        csvOptions+=("-v verticalMode=1")
    fi
    # Change some columns names
    if [[ -n "$headers" ]]; then
        csvOptions+=("-v fieldNames=\"${headers}\"")
    fi

    awk ${csvOptions[@]} -f "${AWQL_TERM_TABLES_DIR}/termTable.awk" "$file"
}

##
# Show response & info about it
# @param arrayToString $1 Request
# @param arrayToString $2 Response
# @return string
function awqlResponse ()
{
    if [[ $1 != "("*")" || $2 != "("*")" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi
    declare -A request="$1"
    declare -A response="$2"

    # Print Awql response
    declare -i fileSize=0
    local file="${response["${AWQL_RESPONSE_FILE}"]}"
    if [[ -f "$file" ]]; then
        fileSize="$(wc -l < "$file")"
    fi
    if [[ ${fileSize} -le 1 ]]; then
        # No result in file
        return 2
    fi

    # Manage group by, avg, distinct, count or sum methods
    file=$(__aggregateRows "$file" "${request["${AWQL_REQUEST_AGGREGATES}"]}" "${request["${AWQL_REQUEST_GROUP}"]}")
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_AGGREGATES}"
        return 1
    fi

    # Manage order clause
    file=$(__sortingRows "$file" "${request["${AWQL_REQUEST_SORT_ORDER}"]}")
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_ORDER}"
        return 1
    fi

    # Manage limit clause
    file=$(__limitRows "$file" "${request["${AWQL_REQUEST_LIMIT}"]}")
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_LIMIT}"
        return 1
    fi

    # At least one result line to display
    __printFile "$file" "${request["${AWQL_REQUEST_VERTICAL}"]}" "${request["${AWQL_REQUEST_HEADERS}"]}"
    if [[ $? -ne 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_DATA_FILE}"
        return 1
    fi

    # Add context (file size, time duration, etc.)
    local timeDuration="${response["${AWQL_RESPONSE_TIME_DURATION}"]}"
    declare -i cache=${response["${AWQL_RESPONSE_CACHED}"]}
    declare -i verbose=${request["${AWQL_REQUEST_VERBOSE}"]}

    __printContext "$file" ${fileSize} "$timeDuration" ${cache} ${verbose}
}