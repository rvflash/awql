#!/usr/bin/env bash

##
# Install AWQL by creating a bash alias in BashRC
# Also create a configuration file with default method to get a valid access token
echo "Welcome to the process to install Awql, a Bash command line tool to request Google Adwords Reports API."
echo "----------"
echo

# Workspace
declare -r rootDir=$(pwd)
declare -r shell=$(if [ ! -z "$ZSH_NAME" ]; then echo 'zsh'; else echo 'bash'; fi)
declare -r -i hasAwk="$(if [[ -z "$(type -p awk)" ]]; then echo 0; else echo 1; fi)"
declare -i error=0

source "${rootDir}/conf/awql.sh"
source "${AWQL_BASH_PACKAGES_DIR}/time.sh"
source "${AWQL_BASH_PACKAGES_DIR}/log/print.sh"

# bashrc file path (manage Linux & Unix)
if [[ "$shell" == "bash" ]]; then
    if [[ "${AWQL_OS}" == "Darwin" || "${AWQL_OS}" == "FreeBSD" ]]; then
        bashFile="${AWQL_USER_HOME}/.profile"
    else
        bashFile="${AWQL_USER_HOME}/.${shell}rc"
    fi
else
    bashFile="${AWQL_USER_HOME}/.${shell}rc"
fi

# Check for AWK version
# @see http://www.unix.com/shell-programming-and-scripting/142154-mawk-does-not-support-length-array.html
if [[ ${hasAwk} -eq 0 || "$(awk 'BEGIN { a[1]="string"; print length(a) }')" != 1 ]]; then
    pError "Awk is a mandatory tool, please install it and retry installation after it."
    if [[ "${AWQL_OS}" == "Darwin" ]]; then
        command="brew install gawk"
    else
        command="sudo apt-get update; sudo apt-get install gawk"
    fi
    pInfo "You can use the following command for that: ${command}"
    exit 1
fi

# Add alias in bashrc
if [[ ! -f "$bashFile" ]]; then
    pFatal "Fail to detect shell environment, installation aborded"
elif [[ -z "$(grep "alias awql" ${bashFile})" ]]; then
    echo >> "$bashFile"
    if [[ $? -ne 0 ]]; then
        pError "Fail to create alias to AWQL command in path: ${bashFile}"
    fi

    echo "# Added by AWQL makefile" >> "$bashFile"
    if isUserTimeTodoExceeded "${AWQL_AUTH_DIR}/init.sh" "0.050"; then
        # Slow machine, do not load current environment, just keep TERM variable for tput command
        echo "alias awql='env -i TERM=${TERM} bash ${rootDir}/awql.sh'" >> "$bashFile"
    else
        echo "alias awql='${rootDir}/awql.sh'" >> "$bashFile"
    fi
fi

# Create a history file for command lines
if [[ ! -f "${AWQL_HISTORY_FILE}" ]]; then
    echo > "${AWQL_HISTORY_FILE}"
    if [[ $? -ne 0 ]]; then
        pError "Can not create AWQL history file in path: ${AWQL_HISTORY_FILE}"
        error+=1
    fi
fi

# Start creation of authentification file
developerToken="$(dialog "Your Google developer token" 1 "${AWQL_PROMPT_REQUIRED}")"

# Use Google auth or custom webservice to refresh Token
if confirm "Use Google to get access tokens" "${AWQL_CONFIRM}"; then
    # Google Auth as provider
    clientId="$(dialog "Your Google client ID" 1 "${AWQL_PROMPT_REQUIRED}")"
    clientSecret="$(dialog "Your Google client secret" 1 "${AWQL_PROMPT_REQUIRED}")"
    refreshToken="$(dialog "Your Google refresh token" 1 "${AWQL_PROMPT_REQUIRED}")"
    ${AWQL_AUTH_INIT_FILE} -a "${AWQL_AUTH_GOOGLE_TYPE}" -c "$clientId" -s "$clientSecret" -r "$refreshToken" -d "$developerToken"
    if [[ $? -ne 0 ]]; then
        pError "Fail to get a valid access token from Google"
        error+=1
    fi
else
    # Custom webservice as token provider
    url="$(dialog "Url of the web service to use to retrieve a Google access token" 1 "${AWQL_PROMPT_REQUIRED}")"
    ${AWQL_AUTH_INIT_FILE} -a "${AWQL_AUTH_CUSTOM_TYPE}" -u "$url" -d "$developerToken"
    if [[ $? -ne 0 ]]; then
        pError "Fail to get a valid access token with the custom web service"
        error+=1
    fi
fi

if [[ ${error} -eq 0 ]]; then
    pInfo "Installation successfull. Open a new terminal or reload your bash environment. Enjoy!"
else
    pWarn "AWQL is now install, but some errors must be resolved in order to use all these features."
fi