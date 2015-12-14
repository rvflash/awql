#!/usr/bin/env bash

# Workspace
ROOT_DIR=$(pwd)
LIBRARY_FILE="${ROOT_DIR}/inc.common.sh"
USER_NAME=$(logname)
USER_HOME=$(sudo -u ${USER_NAME} -H sh -c 'echo "$HOME"')
CURRENT_SHELL=$(if [ ! -z "$ZSH_NAME" ]; then echo "zsh"; else echo "bash"; fi)
CURRENT_OS=$(uname -s)

# Bashrc file path (manage Linux & Unix)
if [ "$CURRENT_SHELL" = "bash" ]; then
    if [ "$CURRENT_OS" = "Darwin" ] || [ "$CURRENT_OS" = "FreeBSD" ]; then
        BASH_RC="${USER_HOME}/.profile"
    else
        BASH_RC="${USER_HOME}/.${CURRENT_SHELL}rc"
    fi
else
    BASH_RC="${USER_HOME}/.${CURRENT_SHELL}rc"
fi

source ${LIBRARY_FILE}

if [ -z "$(grep "alias awql" ${BASH_RC})" ]; then
    # Add alias in bashrc
    echo "" >> ${BASH_RC}
    echo "# Added by AWQL makefile" >> ${BASH_RC}
    echo "alias awql='${ROOT_DIR}/awql.sh'" >> ${BASH_RC}
    source ${BASH_RC}
    exitOnError $? "InstallationError.BASHRC_NOT_UPGRADED"
fi

echo "Installation.Successfull"