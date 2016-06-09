#!/usr/bin/env bash

##
# Install AWQL by creating a bash alias in BashRC
# Also create a configuration file with default method to get a valid access token
echo "Welcome to the process to install Awql, a Bash command line tool to request Google Adwords Reports API."
echo "----------"
echo

# Workspace
rootDir=$(pwd)
shell=$(if [ ! -z "$ZSH_NAME" ]; then echo 'zsh'; else echo 'bash'; fi)
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

# Add alias in bashrc
if [[ ! -f "$bashFile" ]]; then
    pFatal "Fail to detect shell environment, installation aborded"
elif [[ -z "$(grep "alias awql" ${bashFile})" ]]; then
    echo >> "$bashFile"
    if [[ $? -ne 0 ]]; then
        pFatal "Fail to create alias to AWQL command in path: ${bashFile}"
    fi

    echo "# Added by AWQL makefile" >> "$bashFile"
    if isUserTimeTodoExceeded "${AWQL_AUTH_DIR}/custom/auth.sh" "0.100"; then
        # Slow machine, do not load current environment
        echo "alias awql='env -i bash ${rootDir}/awql.sh'" >> "$bashFile"
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