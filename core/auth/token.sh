#!/usr/bin/env bash

# @includeBy /core/auth/access.sh or /core/auth/init.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi


##
# Extract part from a JSON token
#
# @param string $1 Element to extract
# @param string $2 Json
# @return string
function __extractDataFromJson ()
{
    local extract="$1"
    local json="$(echo "$2" | tr "\n" " " | tr -d " ")"
    if [[ -z "$extract" || -z "$json" || "$json" != "{"*"}" ]]; then
        return 0
    fi

    # Set the option for extended regexp for MacOs portability
    local options="-r"
    if [[ "${AWQL_OS}" == 'Darwin' ]]; then
       options="-E"
    fi

    local data="$(echo "$json" | sed ${options} "s/.*\"${extract}\":\"([^\"]+)\".*/\1/")"
    if [[ "$data" == "$json" ]]; then
        # Data not found
        return 0
    fi

    echo "$data"
}

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
    local token="$(cat "$file")"
    if [[ "$token" != *"${AWQL_JSON_TOKEN_TYPE}"* || "$token" != *"${AWQL_JSON_ACCESS_TOKEN}"* || "$token" != *"${AWQL_JSON_EXPIRE_AT}"* ]]; then
        echo "()"
        return 2
    fi

    local type="$(__extractDataFromJson "${AWQL_JSON_TOKEN_TYPE}" "$token" )"
    local access="$(__extractDataFromJson "${AWQL_JSON_ACCESS_TOKEN}" "$token" )"
    local expire="$(__extractDataFromJson "${AWQL_JSON_EXPIRE_AT}" "$token" )"

    echo "([${AWQL_ACCESS_TOKEN}]=\"${access}\" [${AWQL_TOKEN_EXPIRE_AT}]=\"${expire}\" [${AWQL_TOKEN_TYPE}]=\"${type}\" )"
}