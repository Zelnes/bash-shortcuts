#!/bin/bash

API_DOMAINS="domains"
API_ORGA="organizations/ce5b09a0-a252-4199-a8bf-0630f1e59134/domains"
LOCALHOST_AUTHORISATION="Basic YXBpOmFwaQ=="
LOG_CURL_STUDIO="/tmp/studio_curl_requests.jsonc"

curl_studio() {
    echo "/* -- NEW curl_studio run : $**/" >> "$LOG_CURL_STUDIO"

    local location="$1"
    local requestType="$2"
    shift 2

    curl \
        --silent \
        --location "http://localhost:8000/api/v3/$location" \
        --request "$requestType" \
        --header 'Content-Type: application/octet-stream' \
        --header 'Accept: application/json' \
        --header 'Authorization: Basic YXBpOmFwaQ==' \
        "$@" $EXTRA_ARGS \
        | jq \
        | tee -a "$LOG_CURL_STUDIO" \
        | head

}

create_ap() {
    local file="$(realpath "$1")"
    local domain="${2:-$API_DOMAINS}"
    curl_studio "$domain" POST --data-binary "@$file"
}

update_ap() {
    local file="$(realpath "$1")"
    local domain="${2:-$API_DOMAINS}"
    curl_studio "$domain" PUT --data-binary "@$file"
}
