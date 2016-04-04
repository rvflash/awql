#!/usr/bin/env bash

# @includeBy /core/auth/access.sh or /core/auth/init.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Parse a JSON Google token to extract ACCESS_token, EXPIRES_IN, etc.
# ExpiresIn from Google token was converted in ExpireAt by this tool to manage expire date
# 
# @example source
# {
#   "access_token" : "ya29.TgI73hCO7G3OaWdfJ2HTZNCnUlPFS91Ciud6TcoXV0Wg6n7qlI2Bl5H51EnqyyALIFOONYg",
#   "token_type" : "Bearer",
#   "expire_at": "2015-12-19T01:28:58+01:00"
# }
# 
# @example return
# ([ACCESS_token]="ya29.TgI73hCO7G3OaWdfJ2HTZNCnUlPFS91Ciud6TcoXV0Wg6n7qlI2Bl5H51EnqyyALIFOONYg" [token_TYPE]=Bearer...)
# 
# @param string File
# @return arrayToString
# @returnStatus 1 If the token file path is invalid
# @returnStatus 1 If the token file to parse has not the valid format
function tokenFromFile ()
{
    local file="$1"
    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "()"
        return 1
    fi

    # Set the option for extended regexp for MacOs portability
    local options="-r"
    if [[ "${AWQL_OS}" == 'Darwin' ]]; then
       options="-E"
    fi
    local token
    token=$(cat "$file" | tr "\n" " " | tr -d " ")
    if [[ $? -ne 0 || "$token" != *"token_type"* || "$token" != *"access_token"* || "$token" != *"expire_at"* ]]; then
        echo "()"
        return 2
    fi

    local type="$(echo "$token" | sed ${options} "s/.*\"token_type\":\"([^\"]+)\".*/\1/")"
    local access="$(echo "$token" | sed ${options} "s/.*\"access_token\":\"([^\"]+)\".*/\1/")"
    local expire="$(echo "$token" | sed ${options} "s/.*\"expire_at\":\"([^\"]+)\".*/\1/")"

    echo "([${AWQL_ACCESS_TOKEN}]=\"${access}\" [${AWQL_TOKEN_TYPE}]=\"${type}\" [${AWQL_TOKEN_EXPIRE_AT}]=\"${expire}\")"
}