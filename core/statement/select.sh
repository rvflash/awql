#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi

# Import methods to get access token
source "${AWQL_AUTH_DIR}/access.sh"


##
# Retrieve an access token
# @return arrayToString
function __accessToken ()
{
    declare -A -r auth="$(yamlFileDecode "${AWQL_AUTH_FILE}")"
    if [[ "${AWQL_AUTH_GOOGLE_TYPE}" == "${auth["${AWQL_AUTH_TYPE}"]}" ]]; then
        declare -A access="$(authGoogleToken "${auth["${AWQL_AUTH_CLIENT_ID}"]}" "${auth["${AWQL_AUTH_CLIENT_SECRET}"]}" "${auth["${AWQL_REFRESH_TOKEN}"]}")"
    elif [[ "${AWQL_AUTH_CUSTOM_TYPE}" == "${auth["${AWQL_AUTH_TYPE}"]}" ]]; then
        local url="${auth["${AWQL_AUTH_PROTOCOL}"]}://${auth["${AWQL_AUTH_HOSTNAME}"]}:${auth["${AWQL_AUTH_PORT}"]}${auth["${AWQL_AUTH_PATH}"]}"
        declare -A access="$(authCustomToken "$url")"
    else
        declare -A access="(["${AWQL_ERROR_TOKEN}"]=\"${AWQL_AUTH_ERROR_INVALID_TYPE}\" )"
    fi

    if [[ -z "${access["${AWQL_ERROR_TOKEN}"]}" ]]; then
        access["${AWQL_DEVELOPER_TOKEN}"]="${auth["${AWQL_DEVELOPER_TOKEN}"]}"
    fi

    echo "$(arrayToString "$(declare -p access)")"
}

##
# Get authentification properties from Yaml file
# @example ([ACCESS_TOKEN]="..." [DEVELOPER_TOKEN]="...")
# @param string $1 Access token [optional]
# @param string $2 Developer token [optional]
# @return arrayToString
# @returnStatus 1 If auth file can not be retrieved
# @returnStatus 1 If auth file is not valid
# @returnStatus 1 If configuration auth file does not exist
function __oauth ()
{
    local accessToken="$1"
    local developerToken="$2"
    if [[ -z "$accessToken" || -z "$developerToken" ]]; then
        __accessToken
        return 0
    fi

    # Inline mode
    declare -A access=()
    access["${AWQL_TOKEN_TYPE}"]="${AWQL_TOKEN_TYPE_VALUE}"
    access["${AWQL_ACCESS_TOKEN}"]="$accessToken"
    access["${AWQL_DEVELOPER_TOKEN}"]="$developerToken"

    echo "$(arrayToString "$(declare -p access)")"
}

##
# Send a curl request to Adwords API to get response for AWQL query
# @param string $1 Request
# @param string $2 Output filepath
# @return arrayToString Response
# @returnStatus 1 In case of fatal error
# @returnStatus 2 In case of error
function awqlSelect ()
{
    if [[ -z "$1" || "$1" != "("*")" ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi
    declare -A -r request="$1"
    if [[ -z "${request["${AWQL_REQUEST_ID}"]}" ]]; then
        echo "${AWQL_INTERNAL_ERROR_ID}"
        return 1
    fi
    local file="$2"
    if [[ -z "$file" || "$file" != *"${AWQL_FILE_EXT}" ]]; then
        echo "${AWQL_INTERNAL_ERROR_DATA_FILE}"
        return 1
    fi

    # Get a valid access token
    declare -A -r token="$(__oauth "${request["${AWQL_REQUEST_ACCESS}"]}" "${request["${AWQL_REQUEST_DEV_TOKEN}"]}")"
    if [[ "${#token[@]}" -eq 0 ]]; then
        echo "${AWQL_AUTH_ERROR_INVALID_FILE}"
        return 1
    elif [[ -n "${token["${AWQL_ERROR_TOKEN}"]}" ]]; then
        echo "${token["${AWQL_ERROR_TOKEN}"]}"
        return 2
    fi

    # Get properties about Google Adwords APi
    declare -A -r api="$(yamlFileDecode "${AWQL_CONF_DIR}/${AWQL_REQUEST_FILE_NAME}")"
    if [[ "${#api[@]}" -eq 0 ]]; then
        echo "${AWQL_INTERNAL_ERROR_CONFIG}"
        return 1
    fi

    # Define curl default properties
    local options="--silent"
    if [[ "${request["${AWQL_REQUEST_VERBOSE}"]}" -eq 1 ]]; then
        options+=" --trace-ascii ${file}${AWQL_HTTP_RESPONSE_EXT}"
    fi
    if [[ "${api["${AWQL_API_CONNECT_TO}"]}" -gt 0 ]]; then
        options+=" --connect-timeout ${api["${AWQL_API_CONNECT_TO}"]}"
    fi
    if [[ "${api["${AWQL_API_TO}"]}" -gt 0 ]]; then
        options+=" --max-time ${api["${AWQL_API_TO}"]}"
    fi

    # Prepare and format the response
    local out
    out+="[${AWQL_RESPONSE_FILE}]=\"${file}\" "
    out+="[${AWQL_RESPONSE_CACHED}]=0 "
    out+="[${AWQL_RESPONSE_HTTP_CODE}]=%{http_code} "
    out+="[${AWQL_RESPONSE_TIME_DURATION}]=\"%{time_total}\" "
    out="(${out})"

    # Retry the connexion to Adwords ?
    local response
    declare -i retry=0
    while [[ ${retry} -lt ${AWQL_API_RETRY_NB} ]]; do
        # Send request to Google API Adwords
        local url="${api["${AWQL_API_PROTOCOL}"]}://${api["${AWQL_API_HOST}"]}${api["${AWQL_API_PATH}"]}"
        response="$(curl \
            --request "${api["${AWQL_API_METHOD}"]}" "${url}${request["${AWQL_REQUEST_VERSION}"]}" \
            --data-urlencode "${api["${AWQL_API_RESPONSE}"]}=CSV" \
            --data-urlencode "${api["${AWQL_API_QUERY}"]}=${request["${AWQL_REQUEST_QUERY}"]}" \
            --header "${api["${AWQL_API_AUTH}"]}:${token["${AWQL_TOKEN_TYPE}"]} ${token["${AWQL_ACCESS_TOKEN}"]}" \
            --header "${api["${AWQL_API_TOKEN}"]}:${token["${AWQL_DEVELOPER_TOKEN}"]}" \
            --header "${api["${AWQL_API_ID}"]}:${request["${AWQL_REQUEST_ID}"]}" \
            --output "$file" --write-out "$out" ${options}
        )"
        declare -A resp="$response"
        if [[ ${resp["${AWQL_RESPONSE_HTTP_CODE}"]} -gt 0 && ${resp["${AWQL_RESPONSE_HTTP_CODE}"]} -lt 500 ]]; then
            retry=${AWQL_API_RETRY_NB}
        else
            sleep ${retry}
            retry+=1
        fi
    done

    # An error occured with HTTP call
    if [[ ${resp["${AWQL_RESPONSE_HTTP_CODE}"]} -ne 200 ]]; then
        local errMsg
        declare -i error=2
        if [[ ${resp["${AWQL_RESPONSE_HTTP_CODE}"]} -eq 0 ]]; then
            # No connexion / timeout
            errMsg="${AWQL_RESP_ERROR_NO_CONNEXION}"
        elif [[ ${resp["${AWQL_RESPONSE_HTTP_CODE}"]} -eq 400 ]]; then
            # API error: check for any issues in the XML
            errMsg="$(awk -F 'type>|</type' '{print $2}' "$file")"
            local errField="$(awk -F 'fieldPath>|</fieldPath' '{print $2}' "$file")"
            if [[ -n "$errField" ]]; then
                errMsg+=" regarding field(s) named ${errField}"
            fi
            # Except for authentification errors, does not exit on each error, just notice it
            if [[ "$errMsg" == "AuthenticationError"* ]]; then
                error=1
            fi
        else
            # Temporary problem with the server
            errMsg="${AWQL_RESP_ERROR_CONNEXION}"
        fi
        # Force cache cleaning
        rm  -f "$file"
        echo "$errMsg"
        return ${error}
    fi

    # Format CSV in order to improve re-using by removing first and last line
    # Do not use -i option for MacOs portability
    sed -e '$d; 1d' "$file" > "${file}-e" && mv "${file}-e" "$file"
    echo "$response"
}