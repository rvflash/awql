#!/usr/bin/env bash

# @includeBy /inc/awql.sh
# Load configuration file if is not already loaded
if [[ -z "${AWQL_ROOT_DIR}" ]]; then
    declare -r AWQL_CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${AWQL_CUR_DIR}/../../conf/awql.sh"
fi

source "${AWQL_AUTH_DIR}/auth.sh"


##
# Send a curl request to Adwords API to get response for AWQL query
# @param string $1 Awql query
# @param string $2 Output filepath
# @param string $3 Api version
# @param string $4 Adwords ID
# @param arrayToString $5 Google authentification tokens
# @param arrayToString $6 Google request properties
# @return arrayToString response
# @returnStatus 2 If
# @returnStatus 1 If response is on error
function awqlSelect ()
{

auth=$(auth "$accessToken" "$developerToken")
        if [[ $? -gt 0 ]]; then
            echo "$auth"
            if [[ $? -eq 1 ]]; then
                exit 1
            elif [[ $? -gt 1 ]]; then
                return 1
            fi
        fi

    local query="$1"
    local file="$2"
    local apiVersion="$3"
    local adwordsId="$4"
    declare -A -r googleAuth="$5"
    declare -A -r googleRequest="$6"

    # Define curl default properties
    local options="--silent"
    if ! logIsMuted; then
        options+=" --trace-ascii ${file}${AWQL_HTTP_RESPONSE_EXT}"
    fi
    if [[ "${googleRequest["CONNECT_TIME_OUT"]}" -gt 0 ]]; then
        options+=" --connect-timeout ${googleRequest["CONNECT_TIME_OU"T]}"
    fi
    if [[ "${googleRequest["TIME_OUT"]}" -gt 0 ]]; then
        options+=" --max-time ${googleRequest["TIME_OUT"]}"
    fi

    # Send request to Google API Adwords
    local googleUrl="${googleRequest["PROTOCOL"]}://${googleRequest["HOSTNAME"]}${googleRequest["PATH"]}"
    local response=$(curl \
        --request "${googleRequest["METHOD"]}" "${googleUrl}${apiVersion}" \
        --data-urlencode "${googleRequest["RESPONSE_FORMAT"]}=CSV" \
        --data-urlencode "${googleRequest["AWQL_QUERY"]}=${query}" \
        --header "${googleRequest["AUTHORIZATION"]}:${googleAuth["TOKEN_TYPE"]} ${googleAuth["ACCESS_TOKEN"]}" \
        --header "${googleRequest["DEVELOPER_TOKEN"]}:${googleAuth["DEVELOPER_TOKEN"]}" \
        --header "${googleRequest["ADWORDS_ID"]}:${adwordsId}" \
        --output "$file" \
        --write-out "([FILE]=\"${file}\" [CACHED]=0 [HTTP_CODE]=%{http_code} [TIME_DURATION]='%{time_total}')" ${options}
    )

    declare -A -r responseInfo="$response"
    if [[ ${responseInfo["HTTP_CODE"]} -eq 0 || ${responseInfo["HTTP_CODE"]} -gt 400 ]]; then
        # A connexion error occured
        local errMsg="ConnexionError.NOT_FOUND with API ${apiVersion}"
        if ! logIsMuted; then
            errMsg+=" @source $FILE"
        fi
        echo "$errMsg"
        return 1
    elif [[ ${responseInfo["HTTP_CODE"]} -gt 300 ]]; then
        # A server error occured, extract type and others information from XML response
        local errType=$(awk -F 'type>|<\/type' '{print $2}' "$file")
        local errField=$(awk -F 'fieldPath>|<\/fieldPath' '{print $2}' "$file")
        if [[ -n "$errField" ]]; then
            echo "${errType} regarding field(s) named ${errField}"
        else
            echo "${errType} with API ${apiVersion}"
        fi
        # Except for authentification errors, does not exit on each error, just notice it
        if [[ "$errType"  == "AuthenticationError"* ]]; then
            return 1
        fi
        return 2
    else
        # Format CSV in order to improve re-using by removing first and last line
        # Do not use -i option for MacOs portability
        sed -e '$d; 1d' "$file" > "${file}-e" && mv "${file}-e" "${file}"
    fi

    echo "$response"
}