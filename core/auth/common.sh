#!/usr/bin/env bash

##
# Parse a JSON Google token to extract ACCESS_TOKEN, EXPIRES_IN, etc.
# ExpiresIn from Google token was converted in ExpireAt by this tool to manage expire date
# @param string TOKEN_FILE
# @example source
# {
#   "access_token" : "ya29.TgI73hCO7G3OaWdfJ2HTZNCnUlPFS91Ciud6TcoXV0Wg6n7qlI2Bl5H51EnqyyALIFOONYg",
#   "token_type" : "Bearer",
#   "expire_at": "2015-12-19T01:28:58+01:00"
# }
# @example return
# ([ACCESS_TOKEN]="ya29.TgI73hCO7G3OaWdfJ2HTZNCnUlPFS91Ciud6TcoXV0Wg6n7qlI2Bl5H51EnqyyALIFOONYg" [TOKEN_TYPE]=Bearer...)
# @return arrayToString
# @returnStatus 1 If token has invalid format
function tokenFromFile ()
{
    local TOKEN_FILE="$1"

    # Set the option for extended regexp for MacOs portability
    local OPTIONS="-r"
    if [[ "${AWQL_OS}" == 'Darwin' ]]; then
       OPTIONS="-E"
    fi

    if [[ -f "$TOKEN_FILE" ]]; then
        local TOKEN
        TOKEN=$(cat "$TOKEN_FILE" | tr "\n" " " | tr -d " ")
        if [[ $? -ne 0 || "$TOKEN" != *"token_type"* || "$TOKEN" != *"access_token"* || "$TOKEN" != *"expire_at"* ]]; then
            return 1
        fi
        local TOKEN_TYPE=$(echo "$TOKEN" | sed ${OPTIONS} "s/.*\"token_type\":\"([^\"]+)\".*/\1/")
        local ACCESS_TOKEN=$(echo "$TOKEN" | sed ${OPTIONS} "s/.*\"access_token\":\"([^\"]+)\".*/\1/")
        local EXPIRE_AT=$(echo "$TOKEN" | sed ${OPTIONS} "s/.*\"expire_at\":\"([^\"]+)\".*/\1/")

        echo -n "([ACCESS_TOKEN]=\"${ACCESS_TOKEN}\" [TOKEN_TYPE]=\"${TOKEN_TYPE}\" [EXPIRE_AT]=\"${EXPIRE_AT}\")"
    else
        return 1
    fi
}