#!/usr/bin/env bash

##
# bash-packages
#
# Part of bash-packages project.
#
# @package file
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/bash-packages

declare BP_USER_HOME
declare -A -i BP_INCLUDE_FILE
declare -r BP_USER_NAME="$(logname)"


##
# The include statement includes and evaluates the specified file.
# @param string $1 File
# @param int $2 OnceMode If 1, enabled once mode [optional]
# @returnStatus 1 If first parameter named path does not exist
function include ()
{
    local filePath
    filePath="$(realpath "$1")"
    if [[ $? -ne 0 || ! -f "$filePath" ]]; then
        return  1
    fi

    declare -i ONCE="$2"
    if [[ -z "${BP_INCLUDE_FILE["$filePath"]}" ]]; then
        BP_INCLUDE_FILE["$filePath"]=1
    elif [[ "$ONCE" -eq 0 ]]; then
        BP_INCLUDE_FILE["$filePath"]+=1
    else
        return 0
    fi

    source "$filePath"
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
# The import statement includes once and evaluates all files specified in arguments
# @param string $@ Paths
# @returnStatus 1 If there is no file path in entry
# @returnStatus 1 If one of the file path can not be evaluated
function import ()
{
    if [[ $# -eq 0 ]]; then
        return 1
    fi

    local filePath
    for filePath in "$@"; do
        includeOnce "$filePath"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    done
}

##
# Returns the complete directory's path
# @param string $1 Filepath
# @return string Dir
# @returnStatus 1 If first parameter named dir does not exists
function physicalDirname ()
{
    local dir="$1"
    if [[ -z "$dir" ]]; then
        # Get current directory path
        dir="$PWD"
    elif [[ ! -d "$dir" ]]; then
        # DirPath is not a directory
        dir="$(dirname "$dir")"
    fi

    dir="$(cd "$dir" 2>/dev/null && pwd -P)"
    if [[ $? -eq 0 && -n "$dir" ]]; then
        echo -n "${dir}"
    else
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
    local dstPath="$1"
    if [[ -z "$dstPath" ]]; then
        return 1
    fi
    local srcDir="$(physicalDirname "$0")"
    if [[ $? -ne 0 || -z "$srcDir" ]]; then
        return 1
    fi

    # Transform relative path to physical path
    dstPath=$(resolvePath "$dstPath" "$srcDir")
    if [[ -z "$dstPath" ]]; then
        return 1
    fi

    local dstDir="$(physicalDirname "$dstPath")"
    if [[ $? -ne 0 || -z "$dstDir" ]]; then
        # No directory
        return 1
    elif [[ -d "$dstPath" ]]; then
        # Directory
        echo -n ${dstDir}
    elif [[ ! -f "$dstPath" ]]; then
        # No file
        return 1
    else
        # File
        echo -n "${dstDir}/$(basename "$dstPath")"
    fi
}

##
# Resolve all shortcut patterns in a path (.. | ~/ | etc.)
# To check if the path is valid, see realpath function
# @param string $1 Path [optional]
# @param string $2 SourceDir [optional]
# @return string
function resolvePath ()
{
    local dstPath dstFile dstDir srcDir

    if [[ -z "$1" ]]; then
        # Current path
        dstDir="$PWD"
        dstFile="$(basename "$0")"
        dstPath="${dstDir}/${dstFile}"
        srcDir="$dstDir"
    else
        dstPath="$1"
        dstDir="$(dirname "$dstPath")"
        dstFile="$(basename "$dstPath")"
        srcDir="$2"
        if [[ -z "$srcDir" ]]; then
            srcDir="$(physicalDirname "$0")"
            if [[ $? -ne 0 ]]; then
                return 0
            fi
        fi
    fi

    if [[ "$dstPath" == "."* ]]; then
        # ../test.sh
        dstPath="${srcDir}/${dstDir}/${dstFile}"
    elif [[ "$dstPath" == "~/"* ]]; then
        # ~/test.sh
        dstPath="$(userHome)/${dstPath:2}"
        if [[ $? -ne 0 ]]; then
            return 0
        fi
    elif [[ "$dstPath" != "/"* ]]; then
        if [[ "$dstDir" == "." ]]; then
            # test.sh
            dstPath="${srcDir}/${dstFile}"
        else
            # test/test.sh
            dstPath="${srcDir}/${dstDir}/${dstFile}"
        fi
    fi

    # /test.sh
    echo -n "$dstPath"
}

##
# List files and directories inside the specified path
# @param string $1 Path
# @param int $2 WithFile If O, list only directories, otherwise list all files and directories [optional]
# @param int $2 CompletePath If 0, list only the directory or files names, otherwise the complete path [optional]
# @return string
# @returnStatus 1 If first parameter named path does not exist or not a folder
function scanDirectory ()
{
    local srcDir="$1"
    if [[ -z "$srcDir" ]]; then
        srcDir="$(dirname "$0")"
    fi
    srcDir="$(realpath "$srcDir")"
    if [[ $? -ne 0 || -z "$srcDir" ]]; then
        return 1
    fi
    declare -i withFile="$2"
    declare -i completePath="$3"

    local scanDir
    if [[ ${withFile} -eq 0 ]]; then
        scanDir=$(ls -d "$srcDir"/*/ 2>/dev/null)
    else
        scanDir=$(ls -d "$srcDir"/* 2>/dev/null)
    fi

    if [[ ${completePath} -eq 0 ]]; then
        echo -e "$scanDir" | sed -e "s/\/$//g" -e "s/^.*\///g"
    else
        echo -e "$scanDir"
    fi
}

##
# Returns path to user home
# @return string
# @returnStatus 1 If logname method fails
# @returnStatus 1 If sudo to get home path fails
function userHome ()
{
    if [[ -z "${BP_USER_NAME}" ]]; then
        return 1
    elif [[ -z "${BP_USER_HOME}" ]]; then
        BP_USER_HOME="$(sudo -u ${BP_USER_NAME} -H sh -c 'echo "$HOME"')"
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi

    if [[ -n "${BP_USER_HOME}" ]]; then
        echo -n "${BP_USER_HOME}"
    else
        return 1
    fi
}