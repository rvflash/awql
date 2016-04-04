#!/usr/bin/env bash

##
# Get a Access Token for Google Adwords by using a dedicated custom Web Service
#
# @example of HTTP response
# {
#     "access_token": "ya29.ExaMple",
#     "token_type": "Bearer",
#     "expire_at": "2015-12-20T00:35:58+01:00"
# }

# @includeBy /core/statement/select.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi

# Import
source "${AWQL_AUTH_DIR}/token.sh"
source "${AWQL_BASH_PACKAGES_DIR}/time.sh"


##
# Send request to custom Web Service to retrieve a Google Access Token
# @param string $1 Url
# @param string $2 File
# @returnStatus 1 If request can not be performed
# @returnStatus 2 If request fails
function __customRefresh ()
{
    local url="$1"
    local file="$2"
    if [[ -z "$url" || ! "$url" =~ ${AWQL_API_URL_REGEX} || -z "$file" ]]; then
        return 1
    fi

    # Connexion to Google Account
    declare -i httpCode="$(curl \
        --silent --connect-timeout 1 --max-time 2000 \
        --request "GET" "$url" \
        --output "$file" \
        --write-out "%{http_code}"
    )"

    if [[ ${httpCode} -eq 0 || ${httpCode} -gt 400 ]]; then
        rm "$file"
        return 2
    fi
}

##
# Send authentification request to Google API Account
#
# Get refresh token :
# https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=${CLIENT_ID}
#   &scope=https://www.googleapis.com/auth/adwords&response_type=code&redirect_uri=urn:ietf:wg:oauth:2.0:oob
#   &approval_prompt=force
#
# @param string $1 Client ID
# @param string $2 Client secret
# @param string $3 Refresh token
# @param string $5 File
# @return void
# @returnStatus 1 If request can not be performed
# @returnStatus 2 If request fails
# @returnStatus 3 If case of response in error
function __googleRefresh ()
{
    local clientId="$1"
    local clientSecret="$2"
    local refreshToken="$3"
    local file="$4"
    if [[ -z "$clientId" ||  -z "$clientSecret" ||  -z "$refreshToken" ||  -z "$file" ]]; then
        return 1
    fi

    # Google refresh token properties
    declare -A -r request="$(yamlFileDecode "${AWQL_AUTH_DIR}/${AUTH_GOOGLE_TYPE}/${AWQL_REQUEST_FILE_NAME}")"
    if [[ "${#request[@]}" -eq 0 ]]; then
        return 1
    fi

    # Define curl default properties
    local options="--silent"
    if [[ "${request["${AWQL_API_CONNECT_TO}"]}" -gt 0 ]]; then
        options+=" --connect-timeout ${request["${AWQL_API_CONNECT_TO}"]}"
    fi
    if [[ "${request["${AWQL_API_TO}"]}" -gt 0 ]]; then
        options+=" --max-time ${request["${AWQL_API_TO}"]}"
    fi

    # Connexion to Google Account
    local url="${request["${AWQL_API_PROTOCOL}"]}://${request["${AWQL_API_HOST}"]}${request["${AWQL_API_PATH}"]}"
    declare -i httpCode="$(curl \
        --request "${request["${AWQL_API_METHOD}"]}" "$url" \
        --data "${request["${AWQL_AUTH_CLIENT_ID}"]}=${CLIENT_ID}" \
        --data "${request["${AWQL_AUTH_CLIENT_SECRET}"]}=${CLIENT_SECRET}" \
        --data "${request["${AWQL_REFRESH_TOKEN}"]}=${REFRESH_TOKEN}" \
        --data "${request["${AWQL_GRANT_TYPE}"]}=${request["${AWQL_GRANT_REFRESH_TOKEN}"]}" \
        --output "$file" \
        --write-out "%{http_code}" ${options}
    )"

    if [[ ${httpCode} -eq 0 || ${httpCode} -gt 400 ]]; then
        rm "$file"
        return 2
    elif [[ "$(grep "error" "$file" | wc -l)" -eq 1 ]]; then
        rm "$file"
        return 3
    fi

    # Convert ExpiresIn to ExpireAt
    declare -i curTs="$(timestamp)"
    local utc
    utc="$(utcDateTimeFromTimestamp "$((${curTs}+3600))")"
    if [[ $? -eq 0 ]]; then
        sed -e "s/\"expires_in\":3600/\"expire_at\":\"${utc}\"/g" "$file" > "${file}-e" && mv "${file}-e" "$file"
    fi
}

##
# Get token file content as array
# @return arrayToString
function __token ()
{
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "([${AWQL_ERROR_TOKEN}]=\"${AWQL_AUTH_ERROR_INVALID_FILE}\" )"
        return 1
    fi
    local auth="$(tokenFromFile "$file")"
    if [[ $? -ne 0 ]]; then
        echo "([${AWQL_ERROR_TOKEN}]=\"${AWQL_AUTH_ERROR_INVALID_FILE}\" )"
        return 1
    fi

    echo -n "$auth"
}

##
# Check if there has a valid token in cache
# @param string $1 File
# @returnStatus 1 If not cached, 0 otherwise
function __tokenCached ()
{
    local file="$1"
    if [[ -z "$file" ]]; then
        return 1
    fi
echo "v${file}v"
    # Check if valid token exists in cache
    if [[ -f "$file" ]]; then
        declare -A token="$(tokenFromFile "$file")"
        echo "r${#token[@]}v"
        if [[ "${#token[@]}" -gt 0 ]]; then
            declare -i ts="$(timestampFromUtcDateTime "${token["${AWQL_TOKEN_EXPIRE_AT}"]}")"
            if [[ ${ts} -gt 0 ]]; then
                declare -i curTs="$(timestamp)"
                if [[ ${curTs} -gt 0 && ${ts} -gt ${curTs} ]]; then
                    echo -n "$(arrayToString "$(declare -p token)")"
                    return 0
                fi
            fi
        fi
    fi

    return 1
}

##
# Retrieve access token by calling a custom web service
# @param string $1 Url
# @return arrayToString
# @returnStatus 1 If valid token can not be retrieved
function authCustomToken ()
{
    local url="$1"
    if [[ -z "$url" || ! "$url" =~ ${AWQL_API_URL_REGEX} ]]; then
        echo "([${AWQL_ERROR_TOKEN}]=\"${AWQL_AUTH_ERROR_REQUEST_FAIL}\" )"
        return 1
    fi
    local file="${AWQL_WRK_DIR}/${AWQL_TOKEN_FILE_NAME}"

    __tokenCached "$file"
    if [[ $? -eq 0 ]]; then
        return 0
    fi

    # Try to retrieve a fresh token
    __customRefresh "$url" "$file"
    if [[ $? -ne 0 ]]; then
        echo "([${AWQL_ERROR_TOKEN}]=\"${AWQL_AUTH_ERROR_REQUEST_FAIL}\" )"
        return 1
    fi

    __token "$file"
}

##
#
#
function authGoogleToken ()
{
    local clientId="$1"
    local clientSecret="$2"
    local refreshToken="$3"
    if [[ -z "$clientId" || -z "$clientSecret" || -z "$refreshToken" ]]; then
        echo "([${AWQL_ERROR_TOKEN}]=\"${AWQL_AUTH_ERROR_REQUEST_FAIL}\" )"
        return 1
    fi
    local file="${AWQL_WRK_DIR}/${AWQL_TOKEN_FILE_NAME}"

    __tokenCached "$file"
    if [[ $? -eq 0 ]]; then
        return 0
    fi

    # Try to retrieve a fresh token
    __googleRefresh "$clientId" "$clientSecret" "$refreshToken" "$file"
    if [[ $? -ne 0 ]]; then
        echo "([${AWQL_ERROR_TOKEN}]=\"${AWQL_AUTH_ERROR_REQUEST_FAIL}\" )"
        return 1
    fi

    __token "$file"
}