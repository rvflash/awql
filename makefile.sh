#!/usr/bin/env bash

##
# Install AWQL by creating a bash alias in BashRC
# Also create a configuration file with default method to get a valid access token
echo "Welcome to the process to install Awql, a Bash command line tools to request Google Adwords Reports API."

# Workspace
SCRIPT_ROOT=$(pwd)
AWQL_SHELL=$(if [[ -n "$ZSH_NAME" ]]; then echo "zsh"; else echo "bash"; fi)

source "${SCRIPT_ROOT}/conf/awql.sh"
source "${AWQL_INC_DIR}/common.sh"
source "${AWQL_BASH_PACKAGES_DIR}/term.sh"
source "${AWQL_BASH_PACKAGES_DIR}/time.sh"

# Bashrc file path (manage Linux & Unix)
if [[ "$AWQL_SHELL" == "bash" ]]; then
    if [[ "$AWQL_OS" == "Darwin" || "$AWQL_OS" == "FreeBSD" ]]; then
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
    if isUserTimeTodoExceeded "${AWQL_AUTH_DIR}/custom/auth.sh" "0.100"; then
        # Slow machine, do not load environment
        echo "alias awql='env -i bash ${SCRIPT_ROOT}/awql.sh'" >> "${BASHRC_FILE}"
    else
        echo "alias awql='${SCRIPT_ROOT}/awql.sh'" >> "${BASHRC_FILE}"
    fi
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

# Start creation of authentification file
DEVELOPER_TOKEN="$(dialog "Your Google developer token" 1 "$AWQL_PROMPT_REQUIRED")"

# Use Google auth or custom webservice to refresh Token
if confirm "Use Google to get access tokens" "$AWQL_CONFIRM"; then
    # Google Auth as provider
    CLIENT_ID="$(dialog "Your Google client ID" 1 "$AWQL_PROMPT_REQUIRED")"
    CLIENT_SECRET="$(dialog "Your Google client secret" 1 "$AWQL_PROMPT_REQUIRED")"
    REFRESH_TOKEN="$(dialog "Your Google refresh token" 1 "$AWQL_PROMPT_REQUIRED")"
    ${AWQL_AUTH_INIT_FILE} -a "$AUTH_GOOGLE_TYPE" -c "$CLIENT_ID" -s "$CLIENT_SECRET" -r "$REFRESH_TOKEN" -d "$DEVELOPER_TOKEN"
    printAndExitOnError "$?" "Use Google as token provider"
else
    # Custom webservice as token provider
    URL="$(dialog "Url of the web service to use to retrieve a Google access token" 1 "$AWQL_PROMPT_REQUIRED")"
    ${AWQL_AUTH_INIT_FILE} -a "$AUTH_CUSTOM_TYPE" -u "$URL" -d "$DEVELOPER_TOKEN"
    printAndExitOnError "$?" "Use a custom web service as token provider"
fi

echo "Installation successfull. Open a new terminal or reload your bash environment. Enjoy!"