#!/usr/bin/env bash

##
# Send a curl request to Adwords API to get response for AWQL query
# @param string $1 Adwords ID
# @param stringableArray $2 Google authentification tokens
# @param stringableArray $3 Google request properties
# @param string $4 Awql query
# @param array $5 Output filepath
# @param array $6 verbose mode
function awqlSelect ()
{
    declare -A -r GOOGLE_AUTH="$2"
    declare -A -r GOOGLE_REQUEST="$3"

    local ADWORDS_ID="$1"
    local QUERY="$4"
    local FILE="$5"
    local VERBOSE="$6"

    # Define curl default properties
    local OPTIONS="--silent"
    if [[ "$VERBOSE" -eq 1 ]]; then
        OPTIONS="$OPTIONS --trace-ascii $FILE.debug"
    fi
    if [[ "${GOOGLE_REQUEST[CONNECT_TIME_OUT]}" -gt 0 ]]; then
        OPTIONS="$OPTIONS --connect-timeout ${GOOGLE_REQUEST[CONNECT_TIME_OUT]}"
    fi
    if [[ "${GOOGLE_REQUEST[TIME_OUT]}" -gt 0 ]]; then
        OPTIONS="$OPTIONS --max-time ${GOOGLE_REQUEST[TIME_OUT]}"
    fi

    # Send request to Google API Adwords
    local GOOGLE_URL="${GOOGLE_REQUEST[PROTOCOL]}://${GOOGLE_REQUEST[HOSTNAME]}${GOOGLE_REQUEST[PATH]}"
    local RESPONSE=$(curl \
        --request "${GOOGLE_REQUEST[METHOD]}" "${GOOGLE_URL}${AWQL_API_VERSION}" \
        --data-urlencode "${GOOGLE_REQUEST[RESPONSE_FORMAT]}=CSV" \
        --data-urlencode "${GOOGLE_REQUEST[AWQL_QUERY]}=$QUERY" \
        --header "${GOOGLE_REQUEST[AUTHORIZATION]}:${GOOGLE_AUTH[TOKEN_TYPE]} ${GOOGLE_AUTH[ACCESS_TOKEN]}" \
        --header "${GOOGLE_REQUEST[DEVELOPER_TOKEN]}:${GOOGLE_AUTH[DEVELOPER_TOKEN]}" \
        --header "${GOOGLE_REQUEST[ADWORDS_ID]}:$ADWORDS_ID" \
        --output "$FILE" \
        --write-out "([FILE]=\"${FILE}\" [CACHED]=0 [HTTP_CODE]=%{http_code} [TIME_DURATION]='%{time_total}')" ${OPTIONS}
    )
    declare -A -r RESPONSE_INFO="$RESPONSE"

    if [[ "${RESPONSE_INFO[HTTP_CODE]}" -eq 0 ]] || [[ "${RESPONSE_INFO[HTTP_CODE]}" -gt 400 ]]; then
        # A connexion error occured
        local ERR_MSG="ConnexionError.NOT_FOUND with API ${AWQL_API_VERSION}"
        if [ "$VERBOSE" -eq 1 ]; then
            ERR_MSG+=" @source $FILE"
        fi
        echo "$ERR_MSG"
        return 1
    elif [[ "${RESPONSE_INFO[HTTP_CODE]}" -gt 300 ]]; then
        # A server error occured, extract type and others informations from XML response
        local ERR_TYPE=$(awk -F 'type>|<\/type' '{print $2}' "$FILE")
        local ERR_FIELD=$(awk -F 'fieldPath>|<\/fieldPath' '{print $2}' "$FILE")
        if [[ "$ERR_FIELD" != "" ]]; then
            echo "$ERR_TYPE regarding field(s) named $ERR_FIELD"
        else
            echo "$ERR_TYPE with API ${AWQL_API_VERSION}"
        fi
        # Except for authentification errors, does not exit on each error, just notice it
        if [[ "$ERR_TYPE"  == "AuthenticationError"* ]]; then
            return 1
        fi
        return 2
    else
        # Format CSV in order to improve re-using by removing first and last line
        sed -i -e '$d; 1d' "$FILE"
    fi

    echo -n "$RESPONSE"
}