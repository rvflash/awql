#!/usr/bin/env bash

declare BP_USER_HOME
declare -A -i BP_INCLUDE_FILE
declare -r BP_USER_NAME="$(logname)"

##
# The include statement includes and evaluates the specified file.
# @param string $1 File
# @param int $2 OnceMode If 1, enabled once mode
# @returnStatus 1 If first parameter named path does not exist
function include ()
{
    local FILE_PATH
    FILE_PATH="$(realpath "$1")"
    if [[ $? -ne 0 || ! -f "$FILE_PATH" ]]; then
        return  1
    fi

    declare -i ONCE="$2"
    if [[ -z "${BP_INCLUDE_FILE["$FILE_PATH"]}" ]]; then
        BP_INCLUDE_FILE["$FILE_PATH"]=1
    elif [[ "$ONCE" -eq 0 ]]; then
        BP_INCLUDE_FILE["$FILE_PATH"]+=1
    else
        return 0
    fi

    source "$FILE_PATH"
}

##
# The include_once statement includes and evaluates the specified file during the execution of the script.
# This is a behavior similar to the include statement, with the only difference being that if the code from a file
# has already been included, it will not be included again, and include_once returns TRUE.
# As the name suggests, the file will be included just once.
# @param string $1 Path
# @returnStatus 1 If first parameter named path does not exist
function includeOnce ()
{
    include "$1" 1
    if [[ $? -ne 0 ]]; then
        return 1
    fi
}

##
# Returns canonicalized absolute pathname
# Expands all symbolic links and resolves references to '/./', '/../' and extra '/' characters in the input path
# @param string $1 path
# @return string
# @returnStatus 1 If first parameter named path is empty
# @returnStatus 1 If first parameter named path does not exist
function realpath ()
{
    local DEST_PATH="$1"
    if [[ -z "$DEST_PATH" ]]; then
        return 1
    fi
    local SOURCE_DIR="$(physicalDirname "$0")"
    if [[ $? -ne 0 || -z "$SOURCE_DIR" ]]; then
        return 1
    fi

    # Transform relative path to physical path
    DEST_PATH=$(resolvePath "$DEST_PATH" "$SOURCE_DIR")
    if [[ -z "$DEST_PATH" ]]; then
        return 1
    fi

    local DEST_DIR="$(physicalDirname "$DEST_PATH")"
    if [[ $? -ne 0 || -z "$DEST_DIR" ]]; then
        # No directory
        return 1
    elif [[ -d "$DEST_PATH" ]]; then
        # Directory
        echo -n ${DEST_DIR}
    elif [[ ! -f "$DEST_PATH" ]]; then
        # No file
        return 1
    else
        # File
        echo -n "${DEST_DIR}/$(basename "$DEST_PATH")"
    fi
}

##
# Resolve all shortcut patterns in a path (.. | ~/ | etc.)
# To check if the path is valid, see realpath function
# @param string $1 Path
# @param string $2 SourceDir
# @return string
function resolvePath ()
{
    local DEST_PATH DEST_FILE DEST_DIR SOURCE_DIR

    if [[ -z "$1" ]]; then
        # Current path
        DEST_DIR="$PWD"
        DEST_FILE="$(basename "$0")"
        DEST_PATH="${DEST_DIR}/${DEST_FILE}"
        SOURCE_DIR="$DEST_DIR"
    else
        DEST_PATH="$1"
        DEST_DIR="$(dirname "$DEST_PATH")"
        DEST_FILE="$(basename "$DEST_PATH")"
        SOURCE_DIR="$2"
        if [[ -z "$SOURCE_DIR" ]]; then
            SOURCE_DIR="$(physicalDirname "$0")"
            if [[ $? -ne 0 ]]; then
                return 0
            fi
        fi
    fi

    if [[ "$DEST_PATH" == "."* ]]; then
        # ../test.sh
        DEST_PATH="${SOURCE_DIR}/${DEST_DIR}/${DEST_FILE}"
    elif [[ "$DEST_PATH" == "~/"* ]]; then
        # ~/test.sh
        DEST_PATH="$(userHome)/${DEST_PATH:2}"
        if [[ $? -ne 0 ]]; then
            return 0
        fi
    elif [[ "$DEST_PATH" != "/"* ]]; then
        if [[ "$DEST_DIR" == "." ]]; then
            # test.sh
            DEST_PATH="${SOURCE_DIR}/${DEST_FILE}"
        else
            # test/test.sh
            DEST_PATH="${SOURCE_DIR}/${DEST_DIR}/${DEST_FILE}"
        fi
    fi

    # /test.sh
    echo -n "$DEST_PATH"
}

##
# Returns the complete directory's path
# @param string $1 Filepath
# @return string Dir
# @returnStatus 1 If first parameter named dir does not exists
function physicalDirname ()
{
    local DIR="$1"
    if [[ -z "$DIR" ]]; then
        # Get current directory path
        DIR="$PWD"
    elif [[ ! -d "$DIR" ]]; then
        # DirPath is not a directory
        DIR="$(dirname "$DIR")"
    fi

    DIR="$(cd "$DIR" 2>/dev/null && pwd -P)"
    if [[ $? -eq 0 && -n "$DIR" ]]; then
        echo -n "${DIR}"
    else
        return 1
    fi
}


##
# Returns path to user home
# @return string
# @returnStatus 1 If logname method fails
# @returnStatus 1 If sudo to get home path fails
function userHome ()
{
    if [[ -z "$BP_USER_NAME" ]]; then
        return 1
    elif [[ -z "$BP_USER_HOME" ]]; then
        BP_USER_HOME="$(sudo -u ${BP_USER_NAME} -H sh -c 'echo "$HOME"')"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    if [[ -n "$BP_USER_HOME" ]]; then
        echo -n "$BP_USER_HOME"
    else
        return 1
    fi
}