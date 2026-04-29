#!/bin/bash
AI_CORE_AUTH_URL="https://cn-sdc-subaccount-eu12-oi6oims3.authentication.eu12.hana.ondemand.com"
AI_CORE_CLIENT_ID="sb-20f547cf-44f3-420f-9832-03baa36f1e19!b1421301|xsuaa_std!b318061"
AI_CORE_CLIENT_SECRET="c16b32e9-929d-420c-b9c4-c5e92d43eb21\$7_wwxYwYy2kMRt5OjgYZayVXnfdMxU0SjwhwD2LqX3o="
AI_CORE_API_URL="https://api.ai.intprod-eu12.eu-central-1.aws.ml.hana.ondemand.com"

echo "获取 Access Token..."
TOKEN_RESPONSE=$(curl -s -X POST "$AI_CORE_AUTH_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=$AI_CORE_CLIENT_ID" \
    -d "client_secret=$AI_CORE_CLIENT_SECRET")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ 获取 Token 失败"
    echo "$TOKEN_RESPONSE"
    exit 1
fi

echo "✓ Token 已获取"
echo ""
echo "删除 Secret..."

DELETE_RESPONSE=$(curl -s -X DELETE "$AI_CORE_API_URL/v2/admin/secrets/hana-credentials" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "AI-Resource-Group: default")

echo "$DELETE_RESPONSE"

if echo "$DELETE_RESPONSE" | grep -q '"error"'; then
    echo "❌ 删除失败"
else
    echo "✓ Secret 已删除"
fi
