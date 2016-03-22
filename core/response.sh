#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
fi


##
# Build a new AWQL file with only required data (between limits and with sort order requested)
# Only accepts file with .awql as extension
# @param string $1 File path
# @param string $2 Limit
# @param string $3 OrderBy
# @return string File path
# @returnStatus 1 If file is empty or do not exist
# @returnStatus 2 If file exists but it is empty
function __buildDataFile ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" || "$file" != *"${AWQL_FILE_EXT}" ]]; then
        return 1
    fi
    declare -i fileSize=$(wc -l < "$file")
    if [[ ${fileSize} -le 1 ]]; then
        # No result line in file
        return 2
    fi
    declare -a limit="($2)"
    declare -a orderBy="($3)"

    # Manage limit clause
    declare -i limitRange=${#limit[@]}
    if [[ ${limitRange} -gt 0 && ${limitRange} -le 2 ]]; then
        # Limit size of data to display
        local limits="${limit[@]}"
        local wrkLimitFile="${file//${AWQL_FILE_EXT}/_${limits/ /-}${AWQL_FILE_EXT}}"

        # Keep only first line for column names and lines in bounces
        if [[ ! -f "$wrkLimitFile" ]]; then
            if [[ ${limitRange} -eq 2 ]]; then
                limits="$((${limit[0]}+1)),$((${limit[0]}+${limit[1]}))"
                sed -n -e 1p -e "${limits}p" "$file" > "$wrkLimitFile"
            else
                limits="1,$((${limit[0]}+1))"
                sed -n -e "${limits}p" "$file" > "$wrkLimitFile"
            fi
        fi
        file="$wrkLimitFile"
    fi

    # Manage order clause
    if [[ ${#orderBy[@]} -eq 3 ]]; then
        local wrkOrderFile="${file//${AWQL_FILE_EXT}/_k${orderBy[1]}-${orderBy[2]}${AWQL_FILE_EXT}}"
        if [[ ! -f "$wrkOrderFile" ]]; then
            local sortOptions="-t, -k+${orderBy[1]} -${orderBy[0]}"
            if [[ ${orderBy[2]} -eq ${AWQL_SORT_ORDER_DESC} ]]; then
                sortOptions+=" -r"
            fi
            head -1 "$file" > "$wrkOrderFile"
            sed 1d "$file" | sort ${sortOptions} >> "$wrkOrderFile"
        fi
        file="$wrkOrderFile"
    fi

    echo "$file"
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

    printf "%s (%s sec) %s\n" "$size" "$duration" "$source"
}

##
# Print CSV file with ShCsv
#
# @param string $1 File path
# @param int $2 Vertical mode
# @return string
# @returnStatus 1 If file is empty or do not exist
function __printFile ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" ]]; then
        return 1
    fi
    declare -i vertical="$2"

    # Format CVS to print it in shell terminal
    local cvsOptions
    if [[ ${vertical} -eq 1 ]]; then
        cvsOptions="-g"
    fi
    echo -e "$(${AWQL_CSV_TOOL_FILE} ${cvsOptions} -f "$file")"
}

##
# Show response & info about it
# @param arrayToString $1 Request
# @param arrayToString $2 Response
# @return string
function print ()
{
    if [[ $1 != "("*")" || $2 != "("*")" ]]; then
        return 1
    fi
    declare -A request="$1"
    declare -A response="$2"

    # Print Awql response
    declare -i fileSize=0
    local file="${response["${AWQL_RESPONSE_FILE}"]}"
    file=$(__buildDataFile "$file" "${request["${AWQL_REQUEST_LIMIT}"]}" "${request["${AWQL_REQUEST_SORT_ORDER}"]}")
    if [[ $? -eq 0 ]]; then
        # File exists and has one result line at least
        __printFile "$file" "${request["${AWQL_REQUEST_VERTICAL}"]}"
        if [[ $? -ne 0 ]]; then
            echo "${AWQL_INTERNAL_ERROR_DATA_FILE}"
            return 1
        fi
        fileSize=$(wc -l < "$file")
        # With header line
        fileSize+=1
    fi

    # Add context (file size, time duration, etc.)
    local timeDuration="${response["${AWQL_RESPONSE_TIME_DURATION}"]}"
    declare -i cache=${response["${AWQL_RESPONSE_CACHED}"]}
    declare -i verbose=${request["${AWQL_REQUEST_VERBOSE}"]}

    __printContext "$file" ${fileSize} "$timeDuration" ${cache} ${verbose}
}