#!/usr/bin/env bash

##
# Print a CVS file in Shell with readable columns and lines like Mysql command line

# Constants
declare -r CURDATE=$(date +%Y%m%d)
declare -r TMP_DIR="/tmp/shcsv/${CURDATE}/"
declare -r CVS_EXT=".csv"
declare -r CVS_PRINTABLE_EXT=".pcsv"
declare -r CVS_PRINTABLE_WRK_EXT=".tpcsv"
declare -r CSV_PRINT_SEP_COLUMN="|"
declare -r CSV_PRINT_COLUMN_BOUNCE="+"
declare -r CSV_PRINT_COLUMN_BREAK_LINE="-"
declare -r CSV_VERTICAL_START_SEP="***************************"
declare -r CSV_VERTICAL_END_SEP=". row ***************************"

##
# Resolve $1 or current path until the file is no longer a symlink
# @param string $1 path
# @return string DIRECTORY_PATH
function getDirectoryPath ()
{
    local SOURCE="$1"
    while [ -h "$SOURCE" ]; do
        local DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
        [[ ${SOURCE} != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

    if [ "$DIR" = "" ]; then
        exit 1;
    fi
    DIRECTORY_PATH="$DIR/"
}

##
# @example +-------+----+-------+
# @param string $1 Array with size as values for each column
# @print Print a break line for table
function printCsvBreakLine ()
{
    local CVS_LINE=""

    IFS="$CSV_PRINT_SEP_COLUMN" read -ra COLUMNS <<< "$1"
    if [ "${#COLUMNS[@]}" -gt 0 ]; then
        for COLUMN in "${COLUMNS[@]}"; do
            CVS_LINE+="$CSV_PRINT_COLUMN_BOUNCE"
            CVS_LINE+=$(printf "%0.s${CSV_PRINT_COLUMN_BREAK_LINE}" $(seq 1 ${#COLUMN}))
        done
        CVS_LINE+="$CSV_PRINT_COLUMN_BOUNCE"
    fi
    echo "$CVS_LINE"
}

# Default values
getDirectoryPath "${BASH_SOURCE[0]}"
SCRIPT_ROOT="$DIRECTORY_PATH"
SCRIPT=$(basename ${BASH_SOURCE[0]})

CSV_SEP_COLUMN=","
CSV_FILE=""
CSV_PRINT_FILE=""
CLEAN_WRK=0
VERTICAL_MODE=0
SILENT=0

# Help
function usage ()
{
    echo "Usage: ${SCRIPT} -f csvsourcefile [-t csvsavefile] [-s columnseparator] [-g] [-q]"
    echo "-f for CSV source file"
    echo "-t for save result"
    echo "-s to define column separator, by default comma"
    echo "-g for enable vertical mode"
    echo "-q for do not print result"
}

# Script usage & check if mysqldump is availabled
if [ $# -lt 1 ] ; then
    usage
    exit 1
fi

# Read the options
# Use getopts vs getopt for MacOs portability
while getopts "f::t::s:gq" FLAG; do
    case "${FLAG}" in
        f) if [ "${OPTARG:0:1}" = "/" ]; then CSV_FILE="$OPTARG"; else CSV_FILE="${SCRIPT_ROOT}${OPTARG}"; fi ;;
        t) if [ "${OPTARG:0:1}" = "/" ]; then CSV_PRINT_FILE="$OPTARG"; else CSV_PRINT_FILE="${SCRIPT_ROOT}${OPTARG}"; fi ;;
        s) if [ "$OPTARG" != "" ]; then CSV_SEP_COLUMN="$OPTARG"; fi ;;
        g) VERTICAL_MODE=1 ;;
        q) SILENT=1 ;;
        *) usage; exit 1 ;;
        ?) exit 2 ;;
    esac
done
shift $(( OPTIND - 1 ));

# Mandatory options
if [ -z "$CSV_FILE" ]; then
    echo "Please give a CSV file path in input"
    exit 1
elif [ ! -f "$CSV_FILE" ]; then
    echo "File $CSV_FILE does not exist"
    exit 1
fi

# Save process in file
if [ -z "$CSV_PRINT_FILE" ]; then
    mkdir -p "$TMP_DIR"
    CSV_PRINT_FILE="$TMP_DIR$(basename ${CSV_FILE} ${CVS_EXT})${CVS_PRINTABLE_EXT}"
    CSV_PRINT_WRK_FILE="$TMP_DIR$(basename ${CSV_FILE} ${CVS_EXT})${CVS_PRINTABLE_WRK_EXT}"
    CLEAN_WRK=1
fi

if [ "$VERTICAL_MODE" -eq 0 ]; then
    # Add a empty column, manage empty columns and others and ignore empty lines
    sed -e "s/$/${CSV_SEP_COLUMN}/g" \
        -e "s/${CSV_SEP_COLUMN}${CSV_SEP_COLUMN}/${CSV_SEP_COLUMN} ${CSV_SEP_COLUMN}/g" \
        -e "s/^/${CSV_PRINT_SEP_COLUMN} /g"  \
        -e "s/${CSV_SEP_COLUMN}/${CSV_SEP_COLUMN}${CSV_PRINT_SEP_COLUMN} /g" "$CSV_FILE" | column -s, -t > "$CSV_PRINT_WRK_FILE"

    # Build with the head line as model  +-----+--+-----+
    BREAK_LINE=$(head -n 1 "$CSV_PRINT_WRK_FILE" | sed -e "s/^${CSV_PRINT_SEP_COLUMN}//g" -e "s/${CSV_PRINT_SEP_COLUMN} $//g")
    BREAK_LINE=$(printCsvBreakLine "$BREAK_LINE")

    # Add breakline at first, third and last line
    sed -e "1i\\
${BREAK_LINE}" \
        -e "2i\\
${BREAK_LINE}" \
        -e "\$a\\
${BREAK_LINE}" \
        "$CSV_PRINT_WRK_FILE" > "$CSV_PRINT_FILE"
    if [ $? -eq 0 ]; then
        rm -f "$CSV_PRINT_WRK_FILE"
    fi
else
    HEADER_LINE=$(head -n 1 "$CSV_FILE")
    declare -a HEADER=($(echo "$HEADER_LINE" | sed -e "s/ /_/g" -e "s/${CSV_SEP_COLUMN}/ /g"))
    HEADER_NB=${#HEADER[@]}
    COLUMN_MAX_SIZE=0
    for COLUMN in ${HEADER[@]}; do
        if [ ${#COLUMN} -gt ${COLUMN_MAX_SIZE} ]; then
            COLUMN_MAX_SIZE=${#COLUMN}
        fi
    done

    sed 1d "$CSV_FILE" | \
    awk -v vs="${CSV_VERTICAL_START_SEP}" \
        -v ve="${CSV_VERTICAL_END_SEP}" \
        -v vh="$HEADER_LINE" \
        -v vhs="$HEADER_NB" \
        -v vcs="$COLUMN_MAX_SIZE" \
        '
        { printf("%s %d%s\n", vs, NR, ve, $0) }
        { split(vh, k, ","); split($0, v, ","); for(i=1; i<=vhs; i++) printf("%*s: %s\n", vcs, k[i], v[i]); }
        ' > "$CSV_PRINT_FILE"
fi

if [ "$SILENT" -eq 0 ]; then
    cat "$CSV_PRINT_FILE"
fi
if [ "$CLEAN_WRK" -eq 1 ]; then
    rm -f "$CSV_PRINT_FILE"
fi
