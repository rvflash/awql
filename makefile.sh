#!/usr/bin/env bash

##
# Install AWQL by creating a bash alias in BashRC
# Also create a configuration file with default method to get a valid access token
echo "Welcome to the process to install Awql, a Bash command line tools to request Google Adwords Reports API."

# Workspace
SCRIPT_ROOT=$(pwd)
AWQL_SHELL=$(if [ ! -z "$ZSH_NAME" ]; then echo "zsh"; else echo "bash"; fi)

source "${SCRIPT_ROOT}/conf/awql.sh"
source "${AWQL_INC_DIR}/common.sh"

# Bashrc file path (manage Linux & Unix)
if [[ "$AWQL_SHELL" == "bash" ]]; then
    if [[ "$AWQL_OS" == "Darwin" ]] || [[ "$AWQL_OS" == "FreeBSD" ]]; then
        BASHRC_FILE="${AWQL_USER_HOME}/.profile"
    else
        BASHRC_FILE="${AWQL_USER_HOME}/.${AWQL_SHELL}rc"
    fi
else
    BASHRC_FILE="${AWQL_USER_HOME}/.${AWQL_SHELL}rc"
fi

# Add alias in bashrc
if [[ -z "$(grep "alias awql" ${BASHRC_FILE})" ]]; then
    echo >> "${BASHRC_FILE}"
    echo "# Added by AWQL makefile" >> "${BASHRC_FILE}"
    echo "alias awql='${SCRIPT_ROOT}/awql.sh'" >> "${BASHRC_FILE}"
    source ${BASHRC_FILE}
    STATUS=$?
else
    STATUS=0
fi
printAndExitOnError "$STATUS" "Add AWQL as bash alias"

# Create a history file for command lines
if [[ ! -f "${AWQL_HISTORY_FILE}" ]]; then
    echo > "${AWQL_HISTORY_FILE}"
    STATUS=$?
else
    STATUS=0
fi
printAndExitOnError "$STATUS" "Create history file for AWQL queries"

# Use Google auth or custom webservice to refresh Token
DEVELOPER_TOKEN="$(dialog "Your Google developer token")"
if confirm "Use Google to get access tokens"; then
    CLIENT_ID="$(dialog "Your Google client ID")"
    CLIENT_SECRET="$(dialog "Your Google client secret")"
    REFRESH_TOKEN="$(dialog "Your Google refresh token")"
    ${AWQL_AUTH_INIT_FILE} -a "$AUTH_GOOGLE_TYPE" -c "$CLIENT_ID" -s "$CLIENT_SECRET" -r "$REFRESH_TOKEN" -d "$DEVELOPER_TOKEN"
    printAndExitOnError "$?" "Use Google as token provider"
else
    URL="$(dialog "Url of the web service to use to retrieve a Google access token")"
    ${AWQL_AUTH_INIT_FILE} -a "$AUTH_CUSTOM_TYPE" -u "$URL" -d "$DEVELOPER_TOKEN"
    printAndExitOnError "$?" "Use a custom web service as token provider"
fi

echo "Installation successfull. Open a new terminal or reload your bash environment. Enjoy!"