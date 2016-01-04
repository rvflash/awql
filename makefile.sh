#!/usr/bin/env bash

##
# Install AWQL by creating a bash alias in BashRC
# Also create a configuration file with default method to get a valid access token

echo "Welcome to the process to install Awql, a Bash command line tools to request Google Adwords Reports API."

# Workspace
SCRIPT_ROOT=$(pwd)
USER_NAME=$(logname)
USER_HOME=$(sudo -u ${USER_NAME} -H sh -c 'echo "$HOME"')
CURRENT_SHELL=$(if [ ! -z "$ZSH_NAME" ]; then echo "zsh"; else echo "bash"; fi)
CURRENT_OS=$(uname -s)

# Bashrc file path (manage Linux & Unix)
if [[ "$CURRENT_SHELL" == "bash" ]]; then
    if [[ "$CURRENT_OS" == "Darwin" ]] || [[ "$CURRENT_OS" == "FreeBSD" ]]; then
        BASH_RC="${USER_HOME}/.profile"
    else
        BASH_RC="${USER_HOME}/.${CURRENT_SHELL}rc"
    fi
else
    BASH_RC="${USER_HOME}/.${CURRENT_SHELL}rc"
fi
source "${SCRIPT_ROOT}/conf/awql.sh"
source "${AWQL_INC_DIR}/common.sh"

# Add alias in bashrc
if [[ -z "$(grep "alias awql" ${BASH_RC})" ]]; then
    echo "" >> ${BASH_RC}
    echo "# Added by AWQL makefile" >> ${BASH_RC}
    echo "alias awql='${SCRIPT_ROOT}/awql.sh'" >> ${BASH_RC}
    source ${BASH_RC}
fi
printAndExitOnError "$STATUS" "Add awql as bash alias"

# Use Google auth or custom webservice to refresh Token
DEVELOPER_TOKEN="$(dialog "Your Google developer token")"
if confirm "Use Google to get access tokens"; then
    CLIENT_ID="$(dialog "Your Google client ID")"
    CLIENT_SECRET="$(dialog "Your Google client secret")"
    REFRESH_TOKEN="$(dialog "Your Google refresh token")"
    $(${AWQL_AUTH_INIT_FILE} -a "$AUTH_GOOGLE_TYPE" -c "$CLIENT_ID" -s "$CLIENT_SECRET" -r "$REFRESH_TOKEN" -d "$DEVELOPER_TOKEN")
    printAndExitOnError "$?" "Use Google as token provider"
else
    URL="$(dialog "Url of the web service to use to retrieve a Google access token")"
    $(${AWQL_AUTH_INIT_FILE} -a "$AUTH_CUSTOM_TYPE" -u "$URL" -d "$DEVELOPER_TOKEN")
    printAndExitOnError "$?" "Use a custom web service as token provider"
fi

echo "Installation successfull. Open a new terminal or reload your bash environment. Enjoy!"