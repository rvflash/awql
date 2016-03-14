#!/usr/bin/env bash

##
# Print a CSV file in Shell with readable columns and lines like Mysql command line
#
# @copyright 2015-2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/shcsv

# Constants
declare -r CVS_EXT="csv"
declare -r CSV_PRINT_SEP_REPLACER="§"
declare -r CSV_PRINT_SEP_COLUMN="|"
declare -r CSV_PRINT_COLUMN_BOUNCE="+"
declare -r CSV_PRINT_COLUMN_BREAK_LINE="-"
declare -r CSV_VERTICAL_START_SEP="***************************"
declare -r CSV_VERTICAL_END_SEP=". row ***************************"
declare -r CSV_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
declare -r CSV_WRK_DIR="/tmp/shcsv"

if [[ ! -d "${CSV_WRK_DIR}" ]]; then
    mkdir -p "${CSV_WRK_DIR}"
fi

##
# Print a break line for table
# @example +-------+----+-------+
# @param string $1 Line
# @return string
function csvBreakLine ()
{
    local line column

    declare -a columns
    IFS="${CSV_PRINT_SEP_COLUMN}" read -ra columns <<< "$1"
    if [[ "${#columns[@]}" -gt 0 ]]; then
        for column in "${columns[@]}"; do
            line+="${CSV_PRINT_COLUMN_BOUNCE}"
            line+=$(printf "%0.s${CSV_PRINT_COLUMN_BREAK_LINE}" $(seq 1 ${#column}))
        done
        line+="${CSV_PRINT_COLUMN_BOUNCE}"
    fi

    echo "$line"
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
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    local printFile="$2"
    declare -i silent="$3"
    local columnSep="$4"
    if [[ -z "${columnSep}" ]]; then
        columnSep=","
    fi

    declare -i cleanWrk=0
    if [[ -z "$printFile" ]]; then
        if [[ ${silent} -eq 1 ]]; then
            return 2
        fi
        printFile="${CSV_WRK_DIR}/$(basename "$file" ".${CVS_EXT}").p${CVS_EXT}"
        cleanWrk=1
    fi
    local wrkFile="${CSV_WRK_DIR}/${RANDOM}.w${CVS_EXT}"

    # Add a leading separator delimiter
    # Manage columns empty or not
    # Protect separator protected by quotes
    # Ignore empty lines
    sed -e "s/\"\(.*\)${columnSep}\(.*\)\"/\1${CSV_PRINT_SEP_REPLACER}\2/g" \
        -e "s/$/${columnSep}/g" \
        -e "s/${columnSep}${columnSep}/${columnSep} ${columnSep}/g" \
        -e "s/^/${CSV_PRINT_SEP_COLUMN} /g" \
        -e "s/${columnSep}/${columnSep}${CSV_PRINT_SEP_COLUMN} /g" "$file" | \
        column -s, -t | tr "${CSV_PRINT_SEP_REPLACER}" "$columnSep" > "$wrkFile"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Build with the head line as model  +-----+--+-----+
    local lineSep=$(head -n 1 "$wrkFile" | sed -e "s/^${CSV_PRINT_SEP_COLUMN}//g" -e "s/${CSV_PRINT_SEP_COLUMN} $//g")
    lineSep=$(csvBreakLine "$lineSep")

    # Add break line at first, third and last line
    { echo "$lineSep"; head -n 1 "$wrkFile"; echo "$lineSep"; tail -n +2 "$wrkFile"; echo "$lineSep"; } > "$printFile"
    if [[ $? -ne 0 ]]; then
        return 1
    elif [[ ${silent} -eq 0 ]]; then
        cat "$printFile"
    fi

    # Clean workspace
    if [[ ${cleanWrk} -eq 1 ]]; then
        rm -f "$printFile"
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
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    local printFile="$2"
    declare -i silent="$3"
    local columnSep="$4"
    if [[ -z "${columnSep}" ]]; then
        columnSep=","
    fi

    declare -i cleanWrk=0
    if [[ -z "${printFile}" ]]; then
        if [[ ${silent} -eq 1 ]]; then
            return 2
        fi
        printFile="${CSV_WRK_DIR}/$(basename "$file" ".${CVS_EXT}").p${CVS_EXT}"
        cleanWrk=1
    fi

    # Extract header to get all column names
    local lineHead=$(head -n 1 "$file")
    declare -a columns=($(echo "$lineHead" | sed -e "s/ /_/g" -e "s/${columnSep}/ /g"))
    declare -i columnSize="${#columns[@]}"
    declare -i columnMaxSize=0
    local column
    for column in "${columns[@]}"; do
        if [ ${#column} -gt ${columnMaxSize} ]; then
            columnMaxSize=${#column}
        fi
    done

    # Explode each column as line and build vertical display
    sed -e "s/\"\(.*\)${columnSep}\(.*\)\"/\1${CSV_PRINT_SEP_REPLACER}\2/g" -e "1d" "$file" | \
    awk -v vs="${CSV_VERTICAL_START_SEP}" \
        -v ve="${CSV_VERTICAL_END_SEP}" \
        -v vh="$lineHead" \
        -v vhs="$columnSize" \
        -v vcs="$columnMaxSize" \
        -v sep="$columnSep" \
        '
        {
            split(vh, k, sep);
            printf("%s %d%s\n", vs, NR, ve, $0);
        }
        {
            split($0, v, sep);
            for (i=1; i<=vhs; i++) printf("%*s: %s\n", vcs, k[i], v[i]);
        }
        ' | \
    tr "${CSV_PRINT_SEP_REPLACER}" "$columnSep" > "$printFile"

    if [[ $? -ne 0 ]]; then
        return 1
    elif [[ ${silent} -eq 0 ]]; then
        cat "$printFile"
    fi

    # Clean workspace
    if [[ ${cleanWrk} -eq 1 ]]; then
        rm -f "$printFile"
    fi
}

##
# Help
# @return string
function usage ()
{
    echo "usage: csv.sh -f csvSourceFile [-t csvSaveFile] [-s columnSeparator] [-g] [-q]"
    echo "-f for CSV source file path"
    echo "-t for save result in this file path"
    echo "-s to define column separator, by default: comma"
    echo "-g for enable vertical mode"
    echo "-q for does not print result"
}

# Script is not sourced ?
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Script usage & check if mysqldump is availabled
    if [[ $# -lt 1 ]] ; then
        usage
        exit 1
    fi

    # Default values
    declare -- csvFile=""
    declare -- csvPrintFile=""
    declare -- csvColumnSep=","
    declare -i csvVerticalMode=0
    declare -i csvSilentMode=0

    # Read the options
    # Use getopts vs getopt for MacOs portability
    while getopts "f::t::s:gq" FLAG; do
        case "${FLAG}" in
            f)
                csvFile="$OPTARG"
                if [[ "${csvFile:0:1}" != "/" ]]; then
                    csvFile="${CSV_ROOT_DIR}/${csvFile}"
                fi
                ;;
            t)
                csvPrintFile="$OPTARG"
                if [[ "${csvPrintFile:0:1}" != "/" ]]; then
                    csvPrintFile="${CSV_ROOT_DIR}/${csvPrintFile}"
                fi
                ;;
            s) if [[ -n "${OPTARG}" ]]; then csvColumnSep="$OPTARG"; fi ;;
            g) csvVerticalMode=1 ;;
            q) csvSilentMode=1 ;;
            *) usage; exit 1 ;;
            ?) exit 2 ;;
        esac
    done
    shift $(( OPTIND - 1 ));

    # Mandatory options
    if [[ -z "$csvFile" ]]; then
        echo "Please give a CSV file path in input"
        exit 1
    elif [[ ! -f "$csvFile" ]]; then
        echo "File ${csvFile} does not exist"
        exit 1
    elif [[ ${csvSilentMode} -eq 1 && -z "$csvPrintFile" ]]; then
        echo "With these options, no action to do"
        exit 1
    fi

    # Build or print CSV file
    if [[ ${csvVerticalMode} -eq 0 ]]; then
        csvHorizontalMode "$csvFile" "$csvPrintFile" "$csvSilentMode" "$csvColumnSep"
    else
        csvVerticalMode "$csvFile" "$csvPrintFile" "$csvSilentMode" "$csvColumnSep"
    fi
fi