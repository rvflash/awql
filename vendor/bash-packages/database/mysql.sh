#!/usr/bin/env bash

# Require mysql command line tool
declare -r -i BP_MYSQL="$(if [[ -z "$(type -p mysql)" ]]; then echo 0; else echo 1; fi)"
declare -r -i BP_MYSQL_WRK=${RANDOM}
declare -r BP_MYSQL_COLUMN_NAMES_OPTS="--skip-column-names"
declare -r BP_MYSQL_OPTS="--batch --unbuffered --quick --show-warnings"
declare -r BP_MYSQL_BASIC_OPTS="${BP_MYSQL_OPTS} ${BP_MYSQL_COLUMN_NAMES_OPTS}"
declare -r BP_MYSQL_WRK_DIR="/tmp/bp_mysql"
declare -r BP_MYSQL_CONNECT_EXT=".cnx"
declare -r BP_MYSQL_RESULT_EXT=".res"
declare -r BP_MYSQL_COLUMN_NAMES_EXT=".nms"
declare -r BP_MYSQL_AFFECTED_ROW_EXT=".afr"
declare -r BP_MYSQL_ERROR_EXT=".err"
declare -r BP_MYSQL_CHK_SEP="::"
declare -r BP_MYSQL_SELECT="[Ss][Ee][Ll][Ee][Cc][Tt]"
declare -r BP_MYSQL_SHOW="[Ss][Hh][Oo][Ww]"
declare -r BP_MYSQL_DESC="[Dd][Ee][Ss][Cc]"
declare -r BP_MYSQL_EXPLAIN="[Ee][Xx][Pp][Ll][Aa][Ii][Nn]"
declare -r BP_MYSQL_INSERT="[Ii][Nn][Ss][Ee][Rr][Tt]"
declare -r BP_MYSQL_UPDATE="[Uu][Pp][Dd][Aa][Tt][Ee]"
declare -r BP_MYSQL_REPLACE="[Rr][Ee][Pp][Ll][Aa][Cc][Ee]"
declare -r BP_MYSQL_DELETE="[Dd][Ee][Ll][Ee][Tt][Ee]"
declare -r BP_MYSQL_AFFECTED_ROW_COUNT=";SELECT ROW_COUNT();"

# Constants
declare -r -i BP_MYSQL_HOST=0
declare -r -i BP_MYSQL_USER=1
declare -r -i BP_MYSQL_PASS=2
declare -r -i BP_MYSQL_DB=3
declare -r -i BP_MYSQL_TO=4
declare -r -i BP_MYSQL_CACHED=5
declare -r -i BP_MYSQL_RESULT_RAW=100
declare -r -i BP_MYSQL_RESULT_NUM=101
declare -r -i BP_MYSQL_RESULT_ASSOC=102
declare -r -i BP_MYSQL_UNKNOWN_METHOD=200
declare -r -i BP_MYSQL_SELECTING_METHOD=201
declare -r -i BP_MYSQL_AFFECTING_METHOD=202

##
# @returnStatus 1 If query method is not INSERT, UPDATE, REPLACE or DELETE
function __mysql_is_affecting_method ()
{
    local MYSQL_QUERY="$1"

    if [[ "${MYSQL_QUERY}" == ${BP_MYSQL_INSERT}* || "${MYSQL_QUERY}" == ${BP_MYSQL_UPDATE}* || \
          "${MYSQL_QUERY}" == ${BP_MYSQL_REPLACE}* || "${MYSQL_QUERY}" == ${BP_MYSQL_DELETE}* \
    ]]; then
        return 0
    fi

    return 1
}

##
# @returnStatus 1 If query method is not SELECT, SHOW, DESCRIBE or EXPLAIN
function __mysql_is_selecting_method ()
{
    local MYSQL_QUERY="$1"

    if [[ "${MYSQL_QUERY}" == ${BP_MYSQL_SELECT}* || "${MYSQL_QUERY}" == ${BP_MYSQL_SHOW}* || \
          "${MYSQL_QUERY}" == ${BP_MYSQL_DESC}* || "${MYSQL_QUERY}" == ${BP_MYSQL_EXPLAIN}* \
    ]]; then
        return 0
    fi

    return 1
}

##
# Calculate and return a checksum for the query
# @param string $1 String
# @return string
# @returnStatus 1 If first parameter named string is empty
# @returnStatus If checkum is empty or cksum methods returns in error
function __mysql_checksum ()
{
    local MYSQL_CHECKSUM="$1"
    if [[ -z "${MYSQL_CHECKSUM}" ]]; then
        return 1
    fi

    MYSQL_CHECKSUM="$(cksum <<<"${MYSQL_CHECKSUM}" | awk '{print $1}')"
    if [[ $? -ne 0 || -z "${MYSQL_CHECKSUM}" ]]; then
        return 1
    fi

    echo -n "${MYSQL_CHECKSUM}"
}

##
# Build basic options for mysql command line tool
# @return string
function __mysql_options ()
{
    local MYSQL_HOST="$1"
    local MYSQL_USER="$2"
    local MYSQL_PASS="$3"
    declare -i MYSQL_TO="$4"

    local MYSQL_OPTIONS=""
    if [[ -n "${MYSQL_HOST}" ]]; then
        MYSQL_OPTIONS+=" --host=${MYSQL_HOST}"
    fi
    if [[ -n "${MYSQL_USER}" ]]; then
        MYSQL_OPTIONS+=" --user=${MYSQL_USER}"
    fi
    if [[ -n "${MYSQL_PASS}" ]]; then
        MYSQL_OPTIONS+=" --password=${MYSQL_PASS}"
    fi
    if [[ "${MYSQL_TO}" -gt 0 ]]; then
        # The number of seconds before connection timeout. (Default value is 0.)
        MYSQL_OPTIONS+=" --connect_timeout=${MYSQL_TO}"
    fi

    echo -n "${MYSQL_OPTIONS}"
}
##
# Performs a query on the database and return results in variable named in first parameter
# @param int Database link
# @param string Query
# @param string Options
# @return int Result link (only in case of non DML queries)
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function __mysql_query ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_CONNECT_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_CONNECT_EXT}"
    if [[ ${BP_MYSQL} -eq 0 || -z "${MYSQL_CHECKSUM}" || ! -f "${MYSQL_CONNECT_FILE}" ]]; then
        return 1
    else
        declare -a MYSQL_LINK
        mapfile -t MYSQL_LINK < "${MYSQL_CONNECT_FILE}"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    local MYSQL_QUERY="$2"
    if [[ -z "${MYSQL_QUERY}" ]]; then
        return 1
    fi

    local MYSQL_OPTIONS="$3"
    MYSQL_OPTIONS+=" $(__mysql_options "${MYSQL_LINK[${BP_MYSQL_HOST}]}" "${MYSQL_LINK[${BP_MYSQL_USER}]}" "${MYSQL_LINK[${BP_MYSQL_PASS}]}" "${MYSQL_LINK[${BP_MYSQL_TO}]}")"

    local MYSQL_QUERY_CHECKSUM="${MYSQL_CHECKSUM}"
    MYSQL_QUERY_CHECKSUM+=$(__mysql_checksum "${MYSQL_CHECKSUM}${BP_MYSQL_CHK_SEP}${MYSQL_QUERY}")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    local MYSQL_AFFECTED_ROW_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_AFFECTED_ROW_EXT}"
    local MYSQL_QUERY_RESULT_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_RESULT_EXT}"
    if [[ -f "${MYSQL_QUERY_RESULT_FILE}" && "${MYSQL_LINK[${BP_MYSQL_CACHED}]}" -eq 1 ]]; then
        # Query already in cache
        echo -n "${MYSQL_QUERY_CHECKSUM}"
        return 0
    fi

    local MYSQL_METHOD
    if __mysql_is_affecting_method "${MYSQL_QUERY}"; then
        MYSQL_METHOD=${BP_MYSQL_AFFECTING_METHOD}
        # Add ROW_COUNT query to known the number of affected rows
        MYSQL_QUERY+="${BP_MYSQL_AFFECTED_ROW_COUNT}"
    elif __mysql_is_selecting_method "${MYSQL_QUERY}"; then
        MYSQL_METHOD=${BP_MYSQL_SELECTING_METHOD}
    else
        MYSQL_METHOD=${BP_MYSQL_UNKNOWN_METHOD}
    fi

    local MYSQL_RESULT
    MYSQL_RESULT=$(mysql ${MYSQL_OPTIONS} ${MYSQL_LINK["${BP_MYSQL_DB}"]} -e "${MYSQL_QUERY}" 2>&1)
    if [[ $? -ne 0 ]]; then
        # An error occured
        echo "${MYSQL_RESULT}" > "${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_ERROR_EXT}"
        return 1
    elif [[ ${MYSQL_METHOD} -eq ${BP_MYSQL_AFFECTING_METHOD} ]]; then
        # Extract result of the last query to get affected row count
        echo "${MYSQL_RESULT}" | tail -n 1 > "${MYSQL_AFFECTED_ROW_FILE}"
    elif [[ ${MYSQL_METHOD} -eq ${BP_MYSQL_SELECTING_METHOD} ]]; then
        if [[ "${MYSQL_OPTIONS}" == *"${BP_MYSQL_COLUMN_NAMES_OPTS}"* ]]; then
            echo "${MYSQL_RESULT}" > "${MYSQL_QUERY_RESULT_FILE}"
        else
            # Extract header with columns names in dedicated file
            echo "${MYSQL_RESULT}" | head -n 1 > "${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_COLUMN_NAMES_EXT}"
            # Keep only datas
            echo "${MYSQL_RESULT}" | sed 1d > "${MYSQL_QUERY_RESULT_FILE}"
        fi
        echo -n "${MYSQL_QUERY_CHECKSUM}"
    fi
}

##
# Convert tabulated string values to indexed array
# @return string
function __mysql_fetch_array ()
{
    local MYSQL_QUERY_CHECKSUM="$1"
    local MYSQL_SRC_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_RESULT_EXT}"
    if [[ -z "${MYSQL_QUERY_CHECKSUM}" || ! -f "${MYSQL_SRC_FILE}" ]]; then
        return 1
    fi
    local MYSQL_DST_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}-${BP_MYSQL_RESULT_NUM}${BP_MYSQL_RESULT_EXT}"

    if [[ ! -f "${MYSQL_DST_FILE}" ]]; then
        awk 'BEGIN { FS="\x09" }
        {
            printf("(")
            for (i=1;i<=NF;i++) {
                gsub("\"","\\\"",$i)
                printf("[%d]=\"%s\" ", (i-1), $i)
            }
            printf(")\n")
        }' "${MYSQL_SRC_FILE}" > "${MYSQL_DST_FILE}"
    fi

    cat "${MYSQL_DST_FILE}"
}

##
# Convert tabulated string values to associative array
# @return string
function __mysql_fetch_assoc ()
{
    local MYSQL_QUERY_CHECKSUM="$1"
    local MYSQL_SRC_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_RESULT_EXT}"
    local MYSQL_NMS_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_COLUMN_NAMES_EXT}"
    if [[ -z "${MYSQL_QUERY_CHECKSUM}" || ! -f "${MYSQL_SRC_FILE}" || ! -f "${MYSQL_NMS_FILE}" ]]; then
        return 1
    fi
    local MYSQL_COLUMN_NAMES=$(cat "${MYSQL_NMS_FILE}")
    local MYSQL_DST_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}-${BP_MYSQL_RESULT_ASSOC}${BP_MYSQL_RESULT_EXT}"
rm -f "${MYSQL_DST_FILE}"
    if [[ ! -f "${MYSQL_DST_FILE}" ]]; then
        awk -v cn="${MYSQL_COLUMN_NAMES}" '
        BEGIN {
            FS="\x09"
            split(cn, h, " ");
        }
        {
            printf("(")
            for (i=1;i<=NF;i++) {
                gsub("\"","\\\"",$i)
                printf("[%s]=\"%s\" ", h[i], $i)
            }
            printf(")\n")
        }' "${MYSQL_SRC_FILE}" > "${MYSQL_DST_FILE}"
    fi

    cat "${MYSQL_DST_FILE}"
}

##
# Gets the number of affected rows in a previous MySQL operation
# Returns the number of rows affected by the last INSERT, UPDATE, REPLACE or DELETE query.
# With ON DUPLICATE KEY UPDATE, the affected-rows value per row is 1
# If the row is inserted as a new row and 2 if an existing row is updated.
#
# If link does not exist or no affected query on this connexion, -1 is returned
# @param string $1 Database Link
# @return int
function mysqlAffectedRows ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_AFFECTED_ROW_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_AFFECTED_ROW_EXT}"
    if [[ -z "${MYSQL_CHECKSUM}" || ! -f "${MYSQL_AFFECTED_ROW_FILE}" ]]; then
        echo -n "-1"
    else
        cat "${MYSQL_AFFECTED_ROW_FILE}"
    fi
}

##
# Clean workspace of opened database connections and results
# @param int $1 Database link
# @returnStatus 1 If workspace does not exist
function mysqlClose ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_CONNECT_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_CONNECT_EXT}"
    if [[ -z "${MYSQL_CHECKSUM}" || ! -f "${MYSQL_CONNECT_FILE}" ]]; then
        return 1
    fi

    # Remove connection file
    rm -f "${MYSQL_CONNECT_FILE}"
    # Remove all result files
    rm -f "${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}*${BP_MYSQL_RESULT_EXT}"
    # Remove last error file
    rm -f "${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_ERROR_EXT}"
}

##
# Registry to save connection informations to a mysql server
# @param string $1 Host
# @param string $2 Username
# @param string $3 password
# @param string $4 Database
# @param int $5 Connect timeout
# @param int $6 Cache enabled
# @return int Database link
# @returnStatus 2 If mysql command line tool is not available
# @returnStatus 1 If host, username or database named are empty
# @returnStatus 1 If connection failed
function mysqlConnect ()
{
    local MYSQL_HOST="$1"
    local MYSQL_USER="$2"
    local MYSQL_PASS="$3"
    local MYSQL_DB="$4"
    declare -i MYSQL_TO=0
    declare -i MYSQL_CACHED=0

    if [[ ${BP_MYSQL} -eq 0 ]]; then
        # Mysql as command line is required
        return 2
    elif [[ -z "${MYSQL_HOST}" || -z "${MYSQL_USER}" || -z "${MYSQL_DB}" ]]; then
        # Only password can be empty (usefull for local access on unsecure database)
        return 1
    fi
    if [[ -n "$5" ]]; then
        MYSQL_TO="$5"
    fi
    if [[ -n "$6" ]]; then
        MYSQL_CACHED="$6"
    fi

    # Create workspace directory
    if [[ ! -d "${BP_MYSQL_WRK_DIR}" ]]; then
        mkdir -p "${BP_MYSQL_WRK_DIR}"
    fi

    # Create connection
    local MYSQL_CHECKSUM="${MYSQL_HOST}${BP_MYSQL_CHK_SEP}${MYSQL_USER}${BP_MYSQL_CHK_SEP}${MYSQL_PASS}${BP_MYSQL_CHK_SEP}${MYSQL_DB}"
    MYSQL_CHECKSUM=$(__mysql_checksum "${MYSQL_CHECKSUM}")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local MYSQL_CHECKSUM_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_CONNECT_EXT}"
    if [[ ! -f "${MYSQL_CHECKSUM_FILE}" ]]; then
        # Try to connect to mysql server and use database
        local MYSQL_OPTIONS MYSQL_DRYRUN
        MYSQL_OPTIONS=$(__mysql_options "${MYSQL_HOST}" "${MYSQL_USER}" "${MYSQL_PASS}" "${MYSQL_TO}")
        MYSQL_DRYRUN=$(mysql ${MYSQL_OPTIONS} -e "USE ${MYSQL_DB};" 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        # Create link for this connection and save properties
        echo -e "${MYSQL_HOST}\n${MYSQL_USER}\n${MYSQL_PASS}\n${MYSQL_DB}\n${MYSQL_TO}\n${MYSQL_CACHED}" > "${MYSQL_CHECKSUM_FILE}"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    echo -n "${MYSQL_CHECKSUM}"
}

##
# Returns a string description of the last error
# If link is on error or there is no affected rows for this connexion
# @param int Database link
# @return string
function mysqlLastError ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_ERROR_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_ERROR_EXT}"
    if [[ -z "${MYSQL_CHECKSUM}" || ! -f "${MYSQL_ERROR_FILE}" ]]; then
        return 0
    fi

    cat "${MYSQL_ERROR_FILE}"
}

##
# Escapes special characters in a string for use in an SQL statement
# Characters encoded are NUL (ASCII 0), \n, \r, \, ', "
# @param string $1 Var
# @return string
function mysqlEscapeString ()
{
    echo -n "$1" | tr "\r\n" "§" | sed -e 's/\\/\\\\/g' -e "s/§/\\\n/g" -e 's/"/\\\"/g' -e "s/'/\\\'/g" -e "s/\\x00/\\\'/g"
}

##
# Fetches all result rows as an associative array, a numeric array, or raw (csv with tabs)
# @param string $1 Result link
# @param string $2 Query
# @param string $3 Result mode, numeric index as default mode
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchAll ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_QUERY="$2"
    local MYSQL_RESULT_MODE="$3"
    local MYSQL_OPTIONS
    case "${MYSQL_RESULT_MODE}" in
        ${BP_MYSQL_RESULT_ASSOC}) MYSQL_OPTIONS=${BP_MYSQL_OPTS} ;;
        *) MYSQL_OPTIONS=${BP_MYSQL_BASIC_OPTS} ;;
    esac

    local MYSQL_QUERY_CHECKSUM
    MYSQL_QUERY_CHECKSUM=$(__mysql_query "${MYSQL_CHECKSUM}" "${MYSQL_QUERY}" "${MYSQL_OPTIONS}")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    case "${MYSQL_RESULT_MODE}" in
        ${BP_MYSQL_RESULT_RAW})
            cat "${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_RESULT_EXT}"
            return $?
            ;;
        ${BP_MYSQL_RESULT_ASSOC})
            __mysql_fetch_assoc "${MYSQL_QUERY_CHECKSUM}"
            return $?
            ;;
        ${BP_MYSQL_RESULT_NUM}|*)
            __mysql_fetch_array "${MYSQL_QUERY_CHECKSUM}"
            return $?
            ;;
    esac
}

##
# Fetch results as an associative array
# @param string $1 Result link
# @param string $2 Query
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchAssoc ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_QUERY="$2"

    mysqlFetchAll "${MYSQL_CHECKSUM}" "${MYSQL_QUERY}" "${BP_MYSQL_RESULT_ASSOC}"
    return $?
}

##
# Get results as an enumerated array
# @param string $1 Result link
# @param string $2 Query
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchArray ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_QUERY="$2"

    mysqlFetchAll "${MYSQL_CHECKSUM}" "${MYSQL_QUERY}" "${BP_MYSQL_RESULT_NUM}"
    return $?
}

##
# Fetch a result row as an associative array
# @param string $1 Result link
# @param string $2 Query
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchRaw ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_QUERY="$2"

    mysqlFetchAll "${MYSQL_CHECKSUM}" "${MYSQL_QUERY}" "${BP_MYSQL_RESULT_RAW}"
    return $?
}

##
# Gets the number of rows in a result
# If link does not exist or no result was returned on this connexion, -1 is returned
# @param string $1 Result Link
# @return int
function mysqlNumRows ()
{
    local MYSQL_QUERY_CHECKSUM="$1"
    local MYSQL_QUERY_RESULT_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_QUERY_CHECKSUM}${BP_MYSQL_RESULT_EXT}"
    if [[ -z "${MYSQL_QUERY_CHECKSUM}" || ! -f "${MYSQL_QUERY_RESULT_FILE}" ]]; then
        echo -n "-1"
    else
        echo -n $(wc -l < "${MYSQL_QUERY_RESULT_FILE}")
    fi
}

##
# Set options
# @param int Database link
# @param int $2 Option
# @param mixed $3 Value
# @returnStatus 1 If link does not exist
# @returnStatus 1 If option does not exist
function mysqlOption ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_CONNECT_FILE="${BP_MYSQL_WRK_DIR}/${MYSQL_CHECKSUM}${BP_MYSQL_CONNECT_EXT}"
    if [[ -z "${MYSQL_CHECKSUM}" || ! -f "${MYSQL_CONNECT_FILE}" || -z "$2" || -z "$3" ]]; then
        return 1
    fi

    local MYSQL_OPTION="$2"
    case "${MYSQL_OPTION}" in
        ${BP_MYSQL_TO})
            declare -i CONNECT_TIMEOUT="$3"
            sed -i -e $((${BP_MYSQL_TO}+1))'s/.*/'${CONNECT_TIMEOUT}'/' "${MYSQL_CONNECT_FILE}"
            ;;
        ${BP_MYSQL_CACHED})
            declare -i CACHED="$3"
            sed -i -e $((${BP_MYSQL_CACHED}+1))'s/.*/'${CACHED}'/' "${MYSQL_CONNECT_FILE}"
            ;;
        *) return 1 ;;
    esac
}

##
# Performs a query on the database
# For successful SELECT, SHOW, DESCRIBE or EXPLAIN queries, return a result link.
# For other successful queries, just returns with status 0.
# @param string $1 Database link
# @param string $2 Query
# @return int Result link (only in case of non DML queries)
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlQuery ()
{
    local MYSQL_CHECKSUM="$1"
    local MYSQL_QUERY="$2"

    __mysql_query "${MYSQL_CHECKSUM}" "${MYSQL_QUERY}" "${BP_MYSQL_BASIC_OPTS}"
    return $?
}