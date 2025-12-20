#!/bin/bash

# Generate JWT token for App Store Connect API
# Used for authentication with Apple's API

set -e

API_KEY="PR62QK662L"
API_ISSUER="0556f8c8-6856-4d6e-95dc-85d88dcba11f"
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY}.p8"

# Check if API key exists
if [ ! -f "$API_KEY_PATH" ]; then
    echo "Error: API key not found at $API_KEY_PATH" >&2
    exit 1
fi

# JWT Header
header=$(echo -n '{"alg":"ES256","kid":"'$API_KEY'","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

# JWT Payload
iat=$(date +%s)
exp=$((iat + 1200)) # Valid for 20 minutes
payload=$(echo -n '{"iss":"'$API_ISSUER'","iat":'$iat',"exp":'$exp',"aud":"appstoreconnect-v1"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

# Create signature
signature=$(echo -n "${header}.${payload}" | openssl dgst -sha256 -sign "$API_KEY_PATH" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

# Complete JWT
jwt="${header}.${payload}.${signature}"

echo "$jwt"

