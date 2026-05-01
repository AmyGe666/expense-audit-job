#!/bin/bash

# ============================================
# Recreate HANA Secret with HDI Runtime User
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Recreate HANA Secret with HDI Runtime User          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# Pre-filled configuration
# ============================================
AI_CORE_API_URL="https://api.ai.intprod-eu12.eu-central-1.aws.ml.hana.ondemand.com"
AI_CORE_CLIENT_ID="sb-20f547cf-44f3-420f-9832-03baa36f1e19!b1421301|xsuaa_std!b318061"
AI_CORE_CLIENT_SECRET="c16b32e9-929d-420c-b9c4-c5e92d43eb21\$7_wwxYwYy2kMRt5OjgYZayVXnfdMxU0SjwhwD2LqX3o="
AI_CORE_AUTH_URL="https://cn-sdc-subaccount-eu12-oi6oims3.authentication.eu12.hana.ondemand.com"

HANA_HOST="95fac287-84a9-45e1-89a1-c88d5fd6c10e.hana.prod-eu12.hanacloud.ondemand.com"
HANA_PORT="443"

# HDI Runtime User from Service Key
HANA_USER="E8808B8B8A16431A91D03554AFF236E9_39RFUDR92ND7JP4FRFPT7341G_RT"

echo -e "${GREEN}✓ Configuration loaded${NC}"
echo "  Host: $HANA_HOST"
echo "  Port: $HANA_PORT"
echo "  User: $HANA_USER"
echo ""

# ============================================
# Ask for password
# ============================================
echo -e "${YELLOW}Please enter HDI Runtime User password:${NC}"
echo -e "${YELLOW}(Copy from Service Key 'password' field)${NC}"
read -s -p "Password: " HANA_PASSWORD
echo ""

if [ -z "$HANA_PASSWORD" ]; then
    echo -e "${RED}❌ Password cannot be empty${NC}"
    exit 1
fi

# Resource Group
read -p "Resource Group (default: default): " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-default}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ============================================
# Get Access Token
# ============================================
echo ""
echo -e "${BLUE}[1/3] Getting AI Core Access Token...${NC}"

TOKEN_RESPONSE=$(curl -s -X POST "$AI_CORE_AUTH_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=$AI_CORE_CLIENT_ID" \
    -d "client_secret=$AI_CORE_CLIENT_SECRET")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo -e "${RED}❌ Failed to get Access Token${NC}"
    echo "$TOKEN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Access Token obtained${NC}"

# ============================================
# Encode credentials
# ============================================
echo ""
echo -e "${BLUE}[2/3] Encoding credentials...${NC}"

HANA_HOST_B64=$(echo -n "$HANA_HOST" | base64)
HANA_PORT_B64=$(echo -n "$HANA_PORT" | base64)
HANA_USER_B64=$(echo -n "$HANA_USER" | base64)
HANA_PASSWORD_B64=$(echo -n "$HANA_PASSWORD" | base64)

echo -e "${GREEN}✓ Credentials encoded${NC}"
echo "  Host (base64): $HANA_HOST_B64"
echo "  User (base64): $HANA_USER_B64"
echo "  Password length: ${#HANA_PASSWORD} chars"

# ============================================
# Delete existing secret first
# ============================================
echo ""
echo -e "${BLUE}[3a/4] Deleting existing secret (if any)...${NC}"

DELETE_RESPONSE=$(curl -s -X DELETE "$AI_CORE_API_URL/v2/admin/secrets/hana-credentials" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "AI-Resource-Group: $RESOURCE_GROUP")

if echo "$DELETE_RESPONSE" | grep -q '"error"'; then
    echo -e "${YELLOW}No existing secret to delete (this is OK)${NC}"
else
    echo -e "${GREEN}✓ Existing secret deleted${NC}"
fi

# ============================================
# Create new secret (without schema key)
# ============================================
echo ""
echo -e "${BLUE}[3b/4] Creating new Secret...${NC}"

SECRET_RESPONSE=$(curl -s -X POST "$AI_CORE_API_URL/v2/admin/secrets" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "AI-Resource-Group: $RESOURCE_GROUP" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "hana-credentials",
        "data": {
            "host": "'"$HANA_HOST_B64"'",
            "port": "'"$HANA_PORT_B64"'",
            "user": "'"$HANA_USER_B64"'",
            "password": "'"$HANA_PASSWORD_B64"'"
        }
    }')

if echo "$SECRET_RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}❌ Failed to create Secret${NC}"
    echo "$SECRET_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Secret created successfully${NC}"

# ============================================
# Test base64 decoding
# ============================================
echo ""
echo -e "${BLUE}[4/4] Verifying Secret encoding...${NC}"

DECODED_USER=$(echo "$HANA_USER_B64" | base64 -d)
DECODED_HOST=$(echo "$HANA_HOST_B64" | base64 -d)

if [ "$DECODED_USER" = "$HANA_USER" ]; then
    echo -e "${GREEN}✓ User encoding verified${NC}"
else
    echo -e "${RED}❌ User encoding mismatch!${NC}"
fi

if [ "$DECODED_HOST" = "$HANA_HOST" ]; then
    echo -e "${GREEN}✓ Host encoding verified${NC}"
else
    echo -e "${RED}❌ Host encoding mismatch!${NC}"
fi

# ============================================
# Done
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✓ Secret Created!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Secret Details:${NC}"
echo "  Name: hana-credentials"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Keys: host, port, user, password (NO schema key)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. The Docker image with refactored code is already built"
echo "  2. Create a new execution in SAP AI Core to test"
echo ""
echo -e "${BLUE}Note: This Secret uses HDI Runtime User without schema parameter${NC}"
echo ""
