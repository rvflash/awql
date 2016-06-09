#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package database/mysql
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

# Require mysql command line tool
declare -r -i BP_MYSQL="$(if [[ -z "$(type -p mysql)" ]]; then echo 0; else echo 1; fi)"
declare -r -i BP_MYSQL_DUMP="$(if [[ -z "$(type -p mysqldump)" ]]; then echo 0; else echo 1; fi)"
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
declare -r BP_MYSQL_CALL="[Cc][Aa][Ll][Ll]"
declare -r BP_MYSQL_AFFECTED_ROW_COUNT=";SELECT ROW_COUNT();"

# Constants
declare -r -i BP_MYSQL_HOST=0
declare -r -i BP_MYSQL_USER=1
declare -r -i BP_MYSQL_PASS=2
declare -r -i BP_MYSQL_DB=3
declare -r -i BP_MYSQL_TO=4
declare -r -i BP_MYSQL_CACHED=5
declare -r BP_MYSQL_RESULT_RAW="raw"
declare -r BP_MYSQL_RESULT_NUM="num"
declare -r BP_MYSQL_RESULT_ASSOC="assoc"
declare -r BP_MYSQL_UNKNOWN_METHOD=200
declare -r BP_MYSQL_SELECTING_METHOD=201
declare -r BP_MYSQL_AFFECTING_METHOD=202

##
# @param string $1 Query
# @returnStatus 1 If query method is not INSERT, UPDATE, REPLACE or DELETE
function __mysql_is_affecting_method ()
{
    local query="$1"

    if [[ "$query" == ${BP_MYSQL_INSERT}* || "$query" == ${BP_MYSQL_UPDATE}* || \
          "$query" == ${BP_MYSQL_REPLACE}* || "$query" == ${BP_MYSQL_DELETE}* \
    ]]; then
        return 0
    fi

    return 1
}

##
# @param string $1 Query
# @returnStatus 1 If query method is not CALL, SELECT, SHOW, DESCRIBE or EXPLAIN
function __mysql_is_selecting_method ()
{
    local query="$1"

    if [[ "$query" == ${BP_MYSQL_SELECT}* || "$query" == ${BP_MYSQL_SHOW}* || \
          "$query" == ${BP_MYSQL_DESC}* || "$query" == ${BP_MYSQL_EXPLAIN}* || "$query" == ${BP_MYSQL_CALL}* \
    ]]; then
        return 0
    fi

    return 1
}

##
# Calculate and return a checksum for the query
# @param string $1 Str
# @return string
# @returnStatus 1 If first parameter named string is empty
# @returnStatus 1 If checksum is empty or cksum methods returns in error
function __mysql_checksum ()
{
    local checksum="$1"
    if [[ -z "$checksum" ]]; then
        return 1
    fi

    checksum="$(cksum <<<"$checksum" | awk '{print $1}')"
    if [[ $? -ne 0 || -z "$checksum" ]]; then
        return 1
    fi

    echo -n "$checksum"
}

##
# Build basic options for mysql command line tool
# @param string $1 Host
# @param string $2 User
# @param string $3 Pass
# @param int $4 Timeout
# @return string
function __mysql_options ()
{
    local host="$1"
    local user="$2"
    local pass="$3"
    declare -i timeOut="$4"

    local options=""
    if [[ -n "$host" ]]; then
        options+=" --host=${host}"
    fi
    if [[ -n "$user" ]]; then
        options+=" --user=${user}"
    fi
    if [[ -n "$pass" ]]; then
        options+=" --password=${pass}"
    fi
    if [[ "$timeOut" -gt 0 ]]; then
        # The number of seconds before connection timeOut. (Default value is 0.)
        options+=" --connect_timeout=${timeOut}"
    fi

    echo -n "$options"
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
    declare -a link
    declare -i checksum="$1"
    local errorFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_ERROR_EXT}"
    local connectFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_CONNECT_EXT}"
    if [[ ${BP_MYSQL} -eq 0 || "$checksum" -eq 0 || ! -f "$connectFile" ]]; then
        return 1
    else
        mapfile -t link < "$connectFile"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    local query="$2"
    if [[ -z "$query" ]]; then
        return 1
    fi

    local options="$3"
    options+=" $(__mysql_options "${link[${BP_MYSQL_HOST}]}" "${link[${BP_MYSQL_USER}]}" "${link[${BP_MYSQL_PASS}]}" "${link[${BP_MYSQL_TO}]}")"

    declare -i queryChecksum="$checksum"
    queryChecksum+=$(__mysql_checksum "${checksum}${BP_MYSQL_CHK_SEP}${query}")
    if [[ $? -ne 0 || "$queryChecksum" -eq 0 ]]; then
        return 1
    fi
    local affectedRowFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_AFFECTED_ROW_EXT}"
    local queryResultFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_RESULT_EXT}"
    if [[ -f "$queryResultFile" && "${link[${BP_MYSQL_CACHED}]}" -eq 1 ]]; then
        # Query already in cache
        echo -n "$queryChecksum"
        return 0
    fi

    declare -i method
    if __mysql_is_affecting_method "$query"; then
        method=${BP_MYSQL_AFFECTING_METHOD}
        # Add ROW_COUNT query to known the number of affected rows
        query+="${BP_MYSQL_AFFECTED_ROW_COUNT}"
    elif __mysql_is_selecting_method "$query"; then
        method=${BP_MYSQL_SELECTING_METHOD}
    else
        method=${BP_MYSQL_UNKNOWN_METHOD}
    fi

    local result
    result=$(mysql ${options} ${link["${BP_MYSQL_DB}"]} -e "$query" 2>"$errorFile")
    if [[ $? -ne 0 ]]; then
        # An error occured
        return 1
    elif [[ ${method} -eq ${BP_MYSQL_AFFECTING_METHOD} ]]; then
        # Extract result of the last query to get affected row count
        echo "$result" | tail -n 1 > "$affectedRowFile"
    elif [[ ${method} -eq ${BP_MYSQL_SELECTING_METHOD} ]]; then
        if [[ "$options" == *"${BP_MYSQL_COLUMN_NAMES_OPTS}"* ]]; then
            echo "$result" > "$queryResultFile"
        else
            # Extract header with columns names in dedicated file
            echo "$result" | head -n 1 > "${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_COLUMN_NAMES_EXT}"
            # Keep only datas
            echo "$result" | sed 1d > "$queryResultFile"
        fi
        echo -n "$queryChecksum"
    fi
}

##
# Convert tabulated string values to indexed array
# @param int Database link
# @return string
function __mysql_fetch_array ()
{
    declare -i queryChecksum="$1"
    local srcFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_RESULT_EXT}"
    if [[ "$queryChecksum" -eq 0 || ! -f "$srcFile" ]]; then
        return 1
    fi
    local dstFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}-${BP_MYSQL_RESULT_NUM}${BP_MYSQL_RESULT_EXT}"

    if [[ ! -f "$dstFile" ]]; then
        awk 'BEGIN { FS="\x09" }
        {
            printf("(")
            for (i=1;i<=NF;i++) {
                gsub("\"","\\\"",$i)
                printf("[%d]=\"%s\" ", (i-1), $i)
            }
            printf(")\n")
        }' "$srcFile" > "$dstFile"
    fi

    cat "$dstFile"
}

##
# Convert tabulated string values to associative array
# @param int Database link
# @return string
function __mysql_fetch_assoc ()
{
    declare -i queryChecksum="$1"
    local srcFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_RESULT_EXT}"
    local nmsFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_COLUMN_NAMES_EXT}"
    if [[ "$queryChecksum" -eq 0 || ! -f "$srcFile" || ! -f "$nmsFile" ]]; then
        return 1
    fi
    local MYSQL_COLUMN_NAMES=$(cat "$nmsFile")
    local dstFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}-${BP_MYSQL_RESULT_ASSOC}${BP_MYSQL_RESULT_EXT}"

    if [[ ! -f "$dstFile" ]]; then
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
        }' "$srcFile" > "$dstFile"
    fi

    cat "$dstFile"
}

##
# Gets the number of affected rows in a previous MySQL operation
# Returns the number of rows affected by the last INSERT, UPDATE, REPLACE or DELETE query.
# With ON DUPLICATE KEY UPDATE, the affected-rows value per row is 1
# If the row is inserted as a new row and 2 if an existing row is updated.
#
# If link does not exist or no affected query on this connexion, -1 is returned
# @param int $1 Database Link
# @return int
function mysqlAffectedRows ()
{
    declare -i checksum="$1"
    local affectedRowFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_AFFECTED_ROW_EXT}"
    if [[ "$checksum" -eq 0 || ! -f "$affectedRowFile" ]]; then
        echo -n "-1"
    else
        cat "$affectedRowFile"
    fi
}

##
# Clean workspace of opened database connections and results
# @param int $1 Database link
# @returnStatus 1 If workspace does not exist
function mysqlClose ()
{
    declare -i checksum="$1"
    local connectFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_CONNECT_EXT}"
    if [[ "$checksum" -eq 0 || ! -f "$connectFile" ]]; then
        return 1
    fi

    # Remove connection file
    rm -f "$connectFile"
    # Remove all result files
    rm -f "${BP_MYSQL_WRK_DIR}/${checksum}*${BP_MYSQL_RESULT_EXT}"
    # Remove last error file
    rm -f "${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_ERROR_EXT}"
}

##
# Registry to save connection properties to a mysql server
# @param string $1 Host
# @param string $2 Username
# @param string $3 password
# @param string $4 Database
# @param int $5 Connect timeOut
# @param int $6 Enable cache
# @return int Database link
# @returnStatus 2 If mysql command line tool is not available
# @returnStatus 1 If host, username or database named are empty
# @returnStatus 1 If connection failed
function mysqlConnect ()
{
    local host="$1"
    local user="$2"
    local pass="$3"
    local db="$4"
    declare -i timeOut=0
    declare -i cached=0

    if [[ ${BP_MYSQL} -eq 0 ]]; then
        # Mysql as command line is required
        return 2
    elif [[ -z "$host" || -z "$user" || -z "$db" ]]; then
        # Only password can be empty (usefull for local access on insecure database)
        return 1
    fi
    if [[ -n "$5" ]]; then
        timeOut="$5"
    fi
    if [[ -n "$6" ]]; then
        cached="$6"
    fi

    # Create workspace directory
    if [[ ! -d "${BP_MYSQL_WRK_DIR}" ]]; then
        mkdir -p "${BP_MYSQL_WRK_DIR}"
    fi

    # Create connection
    local checksum="${host}${BP_MYSQL_CHK_SEP}${user}${BP_MYSQL_CHK_SEP}${pass}${BP_MYSQL_CHK_SEP}${db}"
    checksum=$(__mysql_checksum "$checksum")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local checksumFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_CONNECT_EXT}"
    if [[ ! -f "${checksumFile}" ]]; then
        # Try to connect to mysql server and use database
        local options dryRun
        options=$(__mysql_options "$host" "$user" "$pass" "$timeOut")
        dryRun=$(mysql $options -e "USE ${db};" 2>&1 >/dev/null)
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        # Create link for this connection and save properties
        echo -e "${host}\n${user}\n${pass}\n${db}\n${timeOut}\n${cached}" > "${checksumFile}"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    echo -n "$checksum"
}

##
# Performs logical backups, producing a set of SQL statements that can be run to reproduce the original schema objects,
# table data, or both. It dumps one or more MySQL database for backup or transfer to another SQL server.
# @param int $1 Database link
# @param string $2 Table name
# @param string $3 Options
# @return string
# @returnStatus 2 If mysqldump command line is not available
# @returnStatus 1 If connection or dump fails
function mysqlDump ()
{
    declare -a link
    declare -i checksum="$1"
    local errorFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_ERROR_EXT}"
    local connectFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_CONNECT_EXT}"
    if [[ ${BP_MYSQL_DUMP} -eq 0 || "$checksum" -eq 0 || ! -f "$connectFile" ]]; then
        return 1
    else
        mapfile -t link < "$connectFile"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    local table="$2"
    local options="$3"
    options+=" $(__mysql_options "${link[${BP_MYSQL_HOST}]}" "${link[${BP_MYSQL_USER}]}" "${link[${BP_MYSQL_PASS}]}")"

    local result
    result=$(mysqldump ${options} ${link["${BP_MYSQL_DB}"]} ${table} 2>"$errorFile")
    if [[ $? -ne 0 ]]; then
        # An error occured
        return 1
    else
        echo "$result"
    fi
}

##
# Returns a string description of the last error
# If link is on error or there is no affected rows for this connexion
# @param int Database link
# @return string
function mysqlLastError ()
{
    declare -i checksum="$1"
    local errorFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_ERROR_EXT}"
    if [[ "$checksum" -eq 0 || ! -f "$errorFile" ]]; then
        return 0
    fi

    cat "$errorFile"
}

##
# Load a SQL file into the database
# @param int $1 Database link
# @param string $2 File path
# @returnStatus 1 If first parameter named filePath does not exist
# @returnStatus 1 If connection failed
# @returnStatus 1 If data loading failed
function mysqlLoad ()
{
    declare -a link
    declare -i checksum="$1"
    local errorFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_ERROR_EXT}"
    local connectFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_CONNECT_EXT}"
    if [[ ${BP_MYSQL} -eq 0 || "$checksum" -eq 0 || ! -f "$connectFile" ]]; then
        return 1
    else
        mapfile -t link < "$connectFile"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    local filePath="$2"
    if [[ -z "$filePath" || ! -f "$filePath" ]]; then
        return 1
    fi

    local options="$(__mysql_options "${link[${BP_MYSQL_HOST}]}" "${link[${BP_MYSQL_USER}]}" "${link[${BP_MYSQL_PASS}]}" "${link[${BP_MYSQL_TO}]}")"

    local result
    result=$(mysql ${options} ${link["${BP_MYSQL_DB}"]} < "$filePath" 2>"$errorFile")
    if [[ $? -ne 0 ]]; then
        # An error occured
        return 1
    fi
}

##
# Escapes special characters in a string for use in an SQL statement
# Characters encoded are NUL (ASCII 0), \n, \r, \, ', "
# @param string $1 Str
# @return string
function mysqlEscapeString ()
{
    echo -n "$1" | tr "\r\n" "§" | sed -e 's/\\/\\\\/g' -e "s/§/\\\n/g" -e 's/"/\\\"/g' -e "s/'/\\\'/g" -e "s/\\x00/\\\'/g"
}

##
# Fetches all result rows as an associative array, a numeric array, or raw (csv with tabs)
# @param int $1 Database link
# @param string $2 Query
# @param string $3 Result mode, numeric index as default mode
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchAll ()
{
    declare -i checksum="$1"
    local query="$2"
    local resultMode="$3"
    local options
    case "${resultMode}" in
        ${BP_MYSQL_RESULT_ASSOC}) options=${BP_MYSQL_OPTS} ;;
        *) options=${BP_MYSQL_BASIC_OPTS} ;;
    esac

    local queryChecksum
    queryChecksum=$(__mysql_query "$checksum" "$query" "$options")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    case "${resultMode}" in
        ${BP_MYSQL_RESULT_RAW})
            cat "${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_RESULT_EXT}"
            ;;
        ${BP_MYSQL_RESULT_ASSOC})
            __mysql_fetch_assoc "$queryChecksum"
            ;;
        ${BP_MYSQL_RESULT_NUM}|*)
            __mysql_fetch_array "$queryChecksum"
            ;;
    esac
}

##
# Fetch results as an associative array
# @param int $1 Database link
# @param string $2 Query
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchAssoc ()
{
    declare -i checksum="$1"
    local query="$2"

    mysqlFetchAll "$checksum" "$query" "${BP_MYSQL_RESULT_ASSOC}"
}

##
# Get results as an enumerated array
# @param int $1 Database link
# @param string $2 Query
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchArray ()
{
    declare -i checksum="$1"
    local query="$2"

    mysqlFetchAll "$checksum" "$query" "${BP_MYSQL_RESULT_NUM}"
}

##
# Fetch a result row as an associative array
# @param int $1 Database link
# @param string $2 Query
# @return string
# @returnStatus 1 If first parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlFetchRaw ()
{
    declare -i checksum="$1"
    local query="$2"

    mysqlFetchAll "$checksum" "$query" "${BP_MYSQL_RESULT_RAW}"
}

##
# Gets the number of rows in a result
# If link does not exist or no result was returned on this connexion, -1 is returned
# @param int $1 Result Link
# @return int
function mysqlNumRows ()
{
    declare -i queryChecksum="$1"
    local queryResultFile="${BP_MYSQL_WRK_DIR}/${queryChecksum}${BP_MYSQL_RESULT_EXT}"
    if [[ "$queryChecksum" -eq 0 || ! -f "$queryResultFile" ]]; then
        echo -n "-1"
    else
        echo -n $(wc -l < "$queryResultFile")
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
    declare -i checksum="$1"
    local connectFile="${BP_MYSQL_WRK_DIR}/${checksum}${BP_MYSQL_CONNECT_EXT}"
    if [[ "$checksum" -eq 0 || ! -f "$connectFile" || -z "$2" || -z "$3" ]]; then
        return 1
    fi

    declare -i option="$2"
    case "${option}" in
        ${BP_MYSQL_TO})
            declare -i timeOut="$3"
            sed -e $((${BP_MYSQL_TO}+1))'s/.*/'${timeOut}'/' "$connectFile" > "${connectFile}-e" && mv "${connectFile}-e" "$connectFile"
            ;;
        ${BP_MYSQL_CACHED})
            declare -i cached="$3"
            sed -e $((${BP_MYSQL_CACHED}+1))'s/.*/'${cached}'/' "$connectFile" > "${connectFile}-e" && mv "${connectFile}-e" "$connectFile"
            ;;
        *) return 1 ;;
    esac
}

##
# Performs a query on the database
# For successful SELECT, SHOW, DESCRIBE or EXPLAIN queries, return a result link.
# For other successful queries, just returns with status 0.
# @param int $1 Database link
# @param string $2 Query
# @return int Result link (only in case of non DML queries)
# @returnStatus 1 If second parameter named query is empty
# @returnStatus 1 If database's host is unknown
# @returnStatus 1 If query failed
function mysqlQuery ()
{
    declare -i checksum="$1"
    local query="$2"

    __mysql_query "$checksum" "$query" "${BP_MYSQL_BASIC_OPTS}"
}
