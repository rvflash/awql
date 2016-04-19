#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../conf/awql.sh"
fi

# Clean history, only keep the last N queries
declare -- historyFile="${AWQL_HISTORY_FILE}"
declare -i historySize="$(wc -l < "$historyFile")"
if [[ -f "$historyFile" && ${historySize} -gt ${AWQL_HISTORY_SIZE} ]]; then
    tail -n ${AWQL_HISTORY_SIZE} "$historyFile" > "${historyFile}-e" && mv "${historyFile}-e" "$historyFile"
fi

# Constants
declare -i -r COMPLETION_DISABLED=0
declare -i -r COMPLETION_MODE_TABLES=1
declare -i -r COMPLETION_MODE_FIELDS=2
declare -i -r COMPLETION_MODE_DURING=3


##
# Return a list of options to propose as completion
# @param int $1 Mode
# @param string $2 Table name
# @param string $3 Api version
# @return string
# @returnStatus 1 If api version is empty
# @returnStatus 1 If adwords configuration table or field file does not exist
function __completeOptions ()
{
    declare -i mode="$1"
    if [[ ${mode} -eq ${COMPLETION_DISABLED} ]]; then
        return 0
    fi
    local table="$2"
    local apiVersion="$3"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        return 1
    fi

    if [[ ${mode} -eq ${COMPLETION_MODE_TABLES} ]]; then
        # Load tables
        declare -A -r awqlTables="$(awqlTables "$apiVersion")"
        if [[ "${#awqlTables[@]}" -eq 0 ]]; then
            return 1
        elif [[ -z "$table" ]]; then
            # List all available table names
            echo "${!awqlTables[@]}"
        else
            # List all table's fields
            echo "${awqlTables["$table"]}"
        fi
    elif [[ ${mode} -eq ${COMPLETION_MODE_FIELDS} ]]; then
        # Load fields
        declare -A -r awqlFields="$(awqlFields "$apiVersion")"
        if [[ "${#awqlFields[@]}" -eq 0 ]]; then
            return 1
        else
            # List all available fields
            echo "${!awqlFields[@]}"
        fi
    elif [[ ${mode} -eq ${COMPLETION_MODE_DURING} ]]; then
        # List all during literal terms
        echo "${AWQL_COMPLETE_DURING[@]}"
    fi
}

##
# Improve completion by completing current string at the maximum as we can
#
# @example "Camp" "CampaignId CampaignName"
#        > Campaign
# @param string Word to complete
# @param string Completion reply
# @return string
function __completeWord ()
{
    local str="$1"
    declare -i pos="${#str}"
    local replyStr="$2"
    if [[ ${pos} -eq 0 || -z "$replyStr" ]]; then
        echo "$replyStr"
        return 0
    fi

    declare -a compReply
    IFS=" " read -a compReply <<< "$replyStr"
    declare -i nbCompReply="${#compReply[@]}"
    if [[ ${nbCompReply} -eq 1 ]]; then
        replyStr="${compReply[0]:$pos}"
    else
        declare -i I Y nbWords
        declare -i suggestPos=$(($pos+1))
        declare -i suggestSize=${#compReply[0]}

        replyStr=""
        for (( Y=${suggestPos}; Y < ${suggestSize}; Y++ )); do
            nbWords=$(($Y-$pos))
            for (( I=1; I < ${nbCompReply}; I++ )); do
                if [[ "${compReply[$I]:$pos:${nbWords}}" != "${compReply[0]:$pos:${nbWords}}" ]]; then
                    break 2
                fi
            done
            replyStr="${compReply[0]:$pos:${nbWords}}"
        done

        if [[ -z "$replyStr" ]]; then
            replyStr="${compReply[@]}"
        fi
    fi

    echo -n "$replyStr"
}

##
# Complete current query with table or column names and with AWQL keywords.
# @param string $1 Words to complete
# @param string $2 Api version
# @return string
# @returnStatus 1 If word to complete is empty
# @returnStatus 1 If api version is invalid
function awqlComplete ()
{
    local str="$1"
    if [[ -z "$str" ]]; then
        return 1
    fi
    local apiVersion="$2"
    if [[ ! "$apiVersion" =~ ${AWQL_API_VERSION_REGEX} ]]; then
        return 1
    fi

    # Prepare query to improve parsing
    local strF=${str//,/ , }
    strF=${strF//\>/ \> }
    strF=${strF//\</ \< }
    strF=${strF//=/ \= }

    declare -a words
    IFS=" " read -a words <<< "$strF"
    declare -i nbWords="${#words[@]}"
    if [[ ${nbWords} -eq 0 ]]; then
        return 1
    fi

    # Extract query fields and search position of FROM clause (to improve in order to manage function and field alias)
    declare -a fields
    declare -i fromPosition=0
    if [[ "${words[0]}" == ${AWQL_QUERY_SELECT} ]]; then
        local field
        declare -i pos
        for ((pos=1; ${pos} < ${nbWords}; pos++)); do
            if [[ "${words[${pos}]}" == "," && -n "$field" ]]; then
                fields+=("$field")
                field=""
            elif [[ "${words[${pos}]}" == ${AWQL_QUERY_FROM} ]]; then
                fields+=("$field")
                fromPosition=$((${pos}+1))
                break
            elif [[ -z "$field" ]]; then
                field="${words[${pos}]}"
            else
                field+=" ${words[${pos}]}"
            fi
        done
    fi

    # Terms to complete
    local curStr
    if [[ "${str: -1}" == [\ ,\<\>=] ]]; then
        # Last char is a space or operator, so add it as a word
        words[${nbWords}]=""
        nbWords+=1
    fi
    curStr="${words[$(($nbWords-1))]}"

    # All available words to use as completion
    declare -i mode
    local table options
    if [[ "$str" == *";" || "$str" == *"\\"[gG] ]]; then
        # The end
        return 0
    elif [[ "$str" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_LIMIT}[[:space:]]* ]]; then
        # Nothing to do after limit
        return 0
    elif [[ "$str" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_ORDER_BY}[[:space:]]* ]]; then
        # Get only columns used in query to complete order by
        options="${fields[@]}"
    elif [[ "$str" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_DURING}[[:space:]]* ]]; then
        # During
        mode=${COMPLETION_MODE_DURING}
    elif [[ "$str" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_WHERE}[[:space:]]* ]]; then
        # Where
        if [[ ${fromPosition} -gt 0 ]]; then
            table="${words[${fromPosition}]}"
        fi
        mode=${COMPLETION_MODE_TABLES}
    elif [[ "$str" == ${AWQL_QUERY_SELECT}[[:space:]]**${AWQL_QUERY_FROM}[[:space:]]* ]]; then
        # From
        mode=${COMPLETION_MODE_TABLES}
    elif [[ "$str" == ${AWQL_QUERY_SELECT}[[:space:]]** ]]; then
        # Select
        mode=${COMPLETION_MODE_FIELDS}
    elif [[ "$str" == ${AWQL_QUERY_DESC}[[:space:]]*${AWQL_QUERY_FULL}[[:space:]]* ]]; then
        # Desc full
        if [[ ${nbWords} -eq 3 ]]; then
            mode=${COMPLETION_MODE_TABLES}
        elif [[ ${nbWords} -eq 4 ]]; then
            table="${words[2]}"
            mode=${COMPLETION_MODE_TABLES}
        fi
    elif [[ "$str" == ${AWQL_QUERY_DESC}[[:space:]]* ]]; then
        # Desc
        if [[ ${nbWords} -eq 2 ]]; then
            mode=${COMPLETION_MODE_TABLES}
        elif [[ ${nbWords} -eq 3 ]]; then
            table="${words[1]}"
            mode=${COMPLETION_MODE_TABLES}
        fi
    fi

    if [[ -z "$options" ]]; then
        # Use default configuration and not information in query
        options=$(__completeOptions ${mode} "$table" "$apiVersion")
        if [[ $? -ne 0 ]]; then
            return 0
        fi
    fi

    declare -a compReply
    if [[ -n "$options" ]]; then
        compReply=( $(compgen -W "$options" -- "$curStr") )
    fi
    local replyStr="${compReply[@]}"
    if [[ "${#compReply[@]}" -eq 0 ]] || ([[ "${#compReply[@]}" -eq 1 && "$replyStr" == "$curStr" ]]); then
        return 0
    fi

    __completeWord "$curStr" "$replyStr"
}