#!/usr/bin/env bash

##
# Print a CSV file in Shell with readable columns and lines like Mysql command line
#
# @copyright 2015-2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/shcsv

# Constants
declare -r CSV_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
declare -r CSV_WRK_DIR="/tmp/shcsv"
declare -r CVS_EXT="csv"
declare -r CSV_PRINT_SEP_COLUMN="|"
declare -r CSV_PRINT_COLUMN_BOUNCE="+"
declare -r CSV_PRINT_COLUMN_BREAK_LINE="-"
declare -r CSV_VERTICAL_START_SEP="***************************"
declare -r CSV_VERTICAL_END_SEP=". row ***************************"


##
# Print a break line for table
# @example +-------+----+-------+
# @param string $1 Line
# @return string
function csvBreakLine ()
{
    local LINE=""
    declare -a COLUMNS
    IFS="${CSV_PRINT_SEP_COLUMN}" read -ra COLUMNS <<< "$1"
    if [[ "${#COLUMNS[@]}" -gt 0 ]]; then
        local COLUMN
        for COLUMN in "${COLUMNS[@]}"; do
            LINE+="${CSV_PRINT_COLUMN_BOUNCE}"
            LINE+=$(printf "%0.s${CSV_PRINT_COLUMN_BREAK_LINE}" $(seq 1 ${#COLUMN}))
        done
        LINE+="${CSV_PRINT_COLUMN_BOUNCE}"
    fi

    echo "${LINE}"
}

##
# Build a CSV file in vertical mode, ready to print in terminal
#
# @example
# +-------+----+-------+
# | Head  | Rv | Next  |
# +-------+----+-------+
# | Col 1 | 2b | 32    |
# +-------+----+-------+
#
# @param string $1 CSV source file path
# @param string $2 CSV destination file path
# @param int $3 Use to force silent mode
# @param string $4 String to use as column separator, by default comma
# @return string
function csvHorizontalMode ()
{
    local FILE="$1"
    if [[ ! -f "${FILE}" ]]; then
        return 1
    fi
    local PRINT_FILE="$2"
    declare -i SILENT="$3"
    local SEP_COLUMN="$4"
    if [[ -z "${SEP_COLUMN}" ]]; then
        SEP_COLUMN=","
    fi

    declare -i CLEAN_WRK=0
    if [[ -z "${PRINT_FILE}" ]]; then
        if [[ ${SILENT} -eq 1 ]]; then
            return 2
        fi
        PRINT_FILE="${CSV_WRK_DIR}/$(basename ${CSV_FILE} .${CVS_EXT}).p${CVS_EXT}"
        CLEAN_WRK=1
    fi
    local WRK_FILE="${CSV_WRK_DIR}/${RANDOM}.w${CVS_EXT}"

    # Add a empty column, manage columns empty or not, and ignore empty lines
    sed -e "s/$/${SEP_COLUMN}/g" \
        -e "s/${SEP_COLUMN}${SEP_COLUMN}/${SEP_COLUMN} ${SEP_COLUMN}/g" \
        -e "s/^/${CSV_PRINT_SEP_COLUMN} /g"  \
        -e "s/${SEP_COLUMN}/${SEP_COLUMN}${CSV_PRINT_SEP_COLUMN} /g" "${FILE}" | column -s, -t > "${WRK_FILE}"

    # Build with the head line as model  +-----+--+-----+
    local SEP=$(head -n 1 "${WRK_FILE}" | sed -e "s/^${CSV_PRINT_SEP_COLUMN}//g" -e "s/${CSV_PRINT_SEP_COLUMN} $//g")
    SEP=$(csvBreakLine "${SEP}")

    # Add break line at first, third and last line
    { echo "${SEP}"; head -n 1 "${WRK_FILE}"; echo "${SEP}"; tail -n +2 "${WRK_FILE}"; echo "${SEP}"; } > "${PRINT_FILE}"
    if [[ $? -ne 0 ]]; then
        return 1
    elif [[ ${SILENT} -eq 0 ]]; then
        cat "${PRINT_FILE}"
    fi

    # Clean workspace
    if [[ ${CLEAN_WRK} -eq 1 ]]; then
        rm -f "${PRINT_FILE}"
    fi
}

##
# Build a CSV file in horizontal mode, ready to print in terminal
#
# @example
# *************************** 1. row ***************************
#   Head: Col 1
#     Rv: 2b
#   Next: 32
#
# @param string $1 CSV source file path
# @param string $2 CSV destination file path
# @param int $3 Use to force silent mode
# @param string $4 String to use as column separator, default comma
# @return string
function csvVerticalMode ()
{
    local FILE="$1"
    if [[ ! -f "${FILE}" ]]; then
        return 1
    fi
    local PRINT_FILE="$2"
    declare -i SILENT="$3"
    local SEP_COLUMN="$4"
    if [[ -z "${SEP_COLUMN}" ]]; then
        SEP_COLUMN=","
    fi

    declare -i CLEAN_WRK=0
    if [[ -z "${PRINT_FILE}" ]]; then
        if [[ ${SILENT} -eq 1 ]]; then
            return 2
        fi
        PRINT_FILE="${CSV_WRK_DIR}/$(basename ${FILE} .${CVS_EXT}).p${CVS_EXT}"
        CLEAN_WRK=1
    fi

    # Extract header to get all column names
    local HEADER_LINE=$(head -n 1 "$FILE")
    declare -a HEADER=($(echo "$HEADER_LINE" | sed -e "s/ /_/g" -e "s/${SEP_COLUMN}/ /g"))
    declare -i HEADER_NB="${#HEADER[@]}"
    declare -i COLUMN_MAX_SIZE=0
    local COLUMN
    for COLUMN in "${HEADER[@]}"; do
        if [ ${#COLUMN} -gt ${COLUMN_MAX_SIZE} ]; then
            COLUMN_MAX_SIZE=${#COLUMN}
        fi
    done

    # Explode each column as line and build vertical display
    sed 1d "${FILE}" | \
    awk -v vs="${CSV_VERTICAL_START_SEP}" \
        -v ve="${CSV_VERTICAL_END_SEP}" \
        -v vh="${HEADER_LINE}" \
        -v vhs="${HEADER_NB}" \
        -v vcs="${COLUMN_MAX_SIZE}" \
        -v sep="${SEP_COLUMN}" \
        '
        {
            split(vh, k, sep);
            printf("%s %d%s\n", vs, NR, ve, $0);
        }
        {
            split($0, v, ",");
            for (i=1; i<=vhs; i++) printf("%*s: %s\n", vcs, k[i], v[i]);
        }
        ' > "${PRINT_FILE}"
    if [[ $? -ne 0 ]]; then
        return 1
    elif [[ ${SILENT} -eq 0 ]]; then
        cat "${PRINT_FILE}"
    fi

    # Clean workspace
    if [[ ${CLEAN_WRK} -eq 1 ]]; then
        rm -f "${PRINT_FILE}"
    fi
}

##
# Help
# @return string
function usage ()
{
    echo "Usage: csv.sh -f csvsourcefile [-t csvsavefile] [-s columnseparator] [-g] [-q]"
    echo "-f for CSV source file path"
    echo "-t for save result in this file path"
    echo "-s to define column separator, by default: comma"
    echo "-g for enable vertical mode"
    echo "-q for does not print result"
}

# Script is not sourced ?
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script usage & check if mysqldump is availabled
    if [[ $# -lt 1 ]] ; then
        usage
        exit 1
    fi

    # Default values
    declare CSV_FILE=""
    declare CSV_PRINT_FILE=""
    declare CSV_SEP_COLUMN=","
    declare -i CSV_VERTICAL_MODE=0
    declare -i CSV_QUIET_MODE=0

    # Read the options
    # Use getopts vs getopt for MacOs portability
    while getopts "f::t::s:gq" FLAG; do
        case "${FLAG}" in
            f)
                CSV_FILE="$OPTARG"
                if [[ "${CSV_FILE:0:1}" != "/" ]]; then
                    CSV_FILE="${CSV_ROOT_DIR}/${CSV_FILE}"
                fi
                ;;
            t)
                CSV_PRINT_FILE="$OPTARG"
                if [[ "${CSV_PRINT_FILE:0:1}" != "/" ]]; then
                    CSV_PRINT_FILE="${CSV_ROOT_DIR}/${CSV_PRINT_FILE}"
                fi
                ;;
            s) if [[ -n "${OPTARG}" ]]; then CSV_SEP_COLUMN="$OPTARG"; fi ;;
            g) CSV_VERTICAL_MODE=1 ;;
            q) CSV_QUIET_MODE=1 ;;
            *) usage; exit 1 ;;
            ?) exit 2 ;;
        esac
    done
    shift $(( OPTIND - 1 ));

    # Mandatory options
    if [[ -z "${CSV_FILE}" ]]; then
        echo "Please give a CSV file path in input"
        exit 1
    elif [[ ! -f "${CSV_FILE}" ]]; then
        echo "File ${CSV_FILE} does not exist"
        exit 1
    elif [[ ${CSV_QUIET_MODE} -eq 1 && -z "${CSV_PRINT_FILE}" ]]; then
        echo "With these options, no action to do"
        exit 1
    elif [[ ! -d "$CSV_WRK_DIR" ]]; then
        mkdir -p "$CSV_WRK_DIR"
    fi

    # Build or print CSV file
    if [[ "${CSV_VERTICAL_MODE}" -eq 0 ]]; then
        csvHorizontalMode "${CSV_FILE}" "${CSV_PRINT_FILE}" "${CSV_QUIET_MODE}" "${CSV_SEP_COLUMN}"
    else
        csvVerticalMode "${CSV_FILE}" "${CSV_PRINT_FILE}" "${CSV_QUIET_MODE}" "${CSV_SEP_COLUMN}"
    fi
fi