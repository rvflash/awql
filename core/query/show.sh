#!/usr/bin/env bash

# @includeBy /core/query.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi

##
# Parse a AWQL SHOW query to split it by its component
#
# Order: SHOW [FULL] TABLES [LIKE|WITH] ...
#
# @response
# > STATEMENT       : SHOW TABLES
# > FULL            : 0
# > LIKE            : CAMPAIGN_%
# > WITH            :
# > VERTICAL_MODE   : 1
# > QUERY           : SHOW TABLES LIKE "CAMPAIGN_%"\g;
#
# @param string $1 Query
# @return arrayToString Query component
# @returnStatus 1 If query is malformed
# @returnStatus 1 If api version is invalid
# @returnStatus 1 If query is empty
# @returnStatus 2 In query error case
function awqlShowQuery ()
{
    local queryStr="$(trim "$1")"
    if [[ -z "$queryStr" ]]; then
        echo "${AWQL_INTERNAL_ERROR_QUERY}"
        return 1
    fi

    # Query components
    declare -i queryLength=${#queryStr}
    declare -A components
    declare -i fullQuery=0

    # Parse query char by char
    local name="${AWQL_REQUEST_STATEMENT}"
    local char part
    declare -i pos
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
                    if [[ "$part" == ${AWQL_QUERY_SHOW} && -z "${components["$name"]}" ]]; then
                        components["$name"]="$part"
                        part=""
                    elif [[ "$part" == ${AWQL_QUERY_FULL} && ${components["$name"]} == ${AWQL_QUERY_SHOW} ]]; then
                        components["$name"]+=" $part"
                        fullQuery=1
                        part=""
                    elif [[ "$part" == ${AWQL_QUERY_TABLES} && ${components["$name"]} == ${AWQL_QUERY_SHOW}* ]]; then
                        components["$name"]+=" $part"
                        part=""
                        name="${AWQL_REQUEST_LIKE}"
                    else
                        echo "${AWQL_QUERY_ERROR_METHOD}"
                        return 2
                    fi
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_LIKE})
                 if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$char" == " " && "$part" == ${AWQL_QUERY_WITH} ]]; then
                        name=${AWQL_REQUEST_WITH}
                    elif [[ "$part" != ${AWQL_QUERY_LIKE}  ]]; then
                        if [[ -n "${components["$name"]}" ]]; then
                            echo "${AWQL_QUERY_ERROR_SYNTAX}"
                            return 2
                        fi
                        # Trim on left and right chars " and '
                        components["$name"]="$(trim "$part" "\"\'")"
                    fi
                    part=""
                elif [[ "$char" != " " ]]; then
                    part+="$char"
                fi
                ;;
            ${AWQL_REQUEST_WITH})
                if [[ "$char" == " " && -n "$part" ]]; then
                    if [[ "$part" != ${AWQL_QUERY_LIKE} ]]; then
                        if [[ -n "${components["$name"]}" ]]; then
                            echo "${AWQL_QUERY_ERROR_SYNTAX}"
                            return 2
                        fi
                        # Trim on left and right chars " and '
                        components["$name"]="$(trim "$part" "\"\'")"
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
    if [[ "${components["${AWQL_REQUEST_STATEMENT}"]}" !=  ${AWQL_QUERY_SHOW}*${AWQL_QUERY_TABLES} ]]; then
        echo "${AWQL_QUERY_ERROR_SYNTAX}"
        return 2
    elif [[ ! ${components["${AWQL_REQUEST_LIKE}"]+rv} && "$queryStr" == *" "${AWQL_QUERY_LIKE}* ]]; then
        echo "${AWQL_QUERY_ERROR_SYNTAX}"
        return 2
    elif [[ ! ${components["${AWQL_REQUEST_WITH}"]+rv} && "$queryStr" == *" "${AWQL_QUERY_WITH}* ]]; then
        echo "${AWQL_QUERY_ERROR_SYNTAX}"
        return 2
    fi

    components["${AWQL_REQUEST_QUERY_SOURCE}"]="$queryStr"
    components["${AWQL_REQUEST_FULL}"]=${fullQuery}
    components["${AWQL_REQUEST_TYPE}"]="show"

    arrayToString "$(declare -p components)"
}