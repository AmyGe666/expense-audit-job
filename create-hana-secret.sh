#!/bin/bash

# ============================================
# SAP AI Core - 创建 HANA Credentials Secret
# 自动化创建用于 Expense Audit Job 的数据库凭证
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SAP AI Core - 创建 HANA Credentials Secret          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# AI Core 配置（已自动填入）
# ============================================
AI_CORE_API_URL="https://api.ai.intprod-eu12.eu-central-1.aws.ml.hana.ondemand.com"
AI_CORE_CLIENT_ID="sb-20f547cf-44f3-420f-9832-03baa36f1e19!b1421301|xsuaa_std!b318061"
AI_CORE_CLIENT_SECRET="c16b32e9-929d-420c-b9c4-c5e92d43eb21\$7_wwxYwYy2kMRt5OjgYZayVXnfdMxU0SjwhwD2LqX3o="
AI_CORE_AUTH_URL="https://cn-sdc-subaccount-eu12-oi6oims3.authentication.eu12.hana.ondemand.com"

# ============================================
# HANA 配置（已自动填入）
# ============================================
HANA_HOST="95fac287-84a9-45e1-89a1-c88d5fd6c10e.hana.prod-eu12.hanacloud.ondemand.com"
HANA_PORT="443"

echo -e "${GREEN}✓ AI Core 配置（已加载）${NC}"
echo "  API URL: $AI_CORE_API_URL"
echo ""
echo -e "${GREEN}✓ HANA 配置（已加载）${NC}"
echo "  Host: $HANA_HOST"
echo "  Port: $HANA_PORT"
echo ""

# ============================================
# 询问用户输入
# ============================================
echo -e "${YELLOW}请提供以下信息：${NC}"
echo ""

# Resource Group
read -p "Resource Group 名称 (默认: default): " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-default}

# HANA 用户信息
read -p "HANA 用户名 (如 DBADMIN): " HANA_USER
if [ -z "$HANA_USER" ]; then
    echo -e "${RED}❌ 用户名不能为空${NC}"
    exit 1
fi

read -s -p "HANA 密码: " HANA_PASSWORD
echo ""
if [ -z "$HANA_PASSWORD" ]; then
    echo -e "${RED}❌ 密码不能为空${NC}"
    exit 1
fi

read -p "HANA Schema (默认: EXPENSE_SCHEMA): " HANA_SCHEMA
HANA_SCHEMA=${HANA_SCHEMA:-EXPENSE_SCHEMA}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ============================================
# 步骤 1: 获取 Access Token
# ============================================
echo ""
echo -e "${BLUE}[1/3] 获取 AI Core Access Token...${NC}"

TOKEN_RESPONSE=$(curl -s -X POST "$AI_CORE_AUTH_URL/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=$AI_CORE_CLIENT_ID" \
    -d "client_secret=$AI_CORE_CLIENT_SECRET")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
    echo -e "${RED}❌ 获取 Access Token 失败${NC}"
    echo "$TOKEN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Access Token 已获取${NC}"

# ============================================
# 步骤 2: 编码 HANA 凭证
# ============================================
echo ""
echo -e "${BLUE}[2/3] 编码 HANA 凭证...${NC}"

HANA_HOST_B64=$(echo -n "$HANA_HOST" | base64)
HANA_PORT_B64=$(echo -n "$HANA_PORT" | base64)
HANA_USER_B64=$(echo -n "$HANA_USER" | base64)
HANA_PASSWORD_B64=$(echo -n "$HANA_PASSWORD" | base64)
HANA_SCHEMA_B64=$(echo -n "$HANA_SCHEMA" | base64)

echo -e "${GREEN}✓ 凭证已编码${NC}"

# ============================================
# 步骤 3: 创建或更新 Secret
# ============================================
echo ""
echo -e "${BLUE}[3/3] 在 AI Core 中创建/更新 Secret...${NC}"

# 先尝试创建
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
            "password": "'"$HANA_PASSWORD_B64"'",
            "schema": "'"$HANA_SCHEMA_B64"'"
        }
    }')

# 如果 Secret 已存在，尝试更新
if echo "$SECRET_RESPONSE" | grep -q '"code": "409"'; then
    echo -e "${YELLOW}Secret 已存在，尝试更新...${NC}"

    SECRET_RESPONSE=$(curl -s -X PATCH "$AI_CORE_API_URL/v2/admin/secrets/hana-credentials" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "AI-Resource-Group: $RESOURCE_GROUP" \
        -H "Content-Type: application/json" \
        -d '{
            "data": {
                "host": "'"$HANA_HOST_B64"'",
                "port": "'"$HANA_PORT_B64"'",
                "user": "'"$HANA_USER_B64"'",
                "password": "'"$HANA_PASSWORD_B64"'",
                "schema": "'"$HANA_SCHEMA_B64"'"
            }
        }')

    if echo "$SECRET_RESPONSE" | grep -q '"error"'; then
        echo -e "${RED}❌ 更新 Secret 失败${NC}"
        echo "$SECRET_RESPONSE"
        exit 1
    fi

    echo -e "${GREEN}✓ Secret 更新成功${NC}"
elif echo "$SECRET_RESPONSE" | grep -q '"error"'; then
    echo -e "${RED}❌ 创建 Secret 失败${NC}"
    echo "$SECRET_RESPONSE"
    exit 1
else
    echo -e "${GREEN}✓ Secret 创建成功${NC}"
fi

# ============================================
# 完成信息
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✓ 配置完成！                             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Secret 信息：${NC}"
echo "  名称: hana-credentials"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  包含的 Key:"
echo "    - host"
echo "    - port"
echo "    - user"
echo "    - password"
echo "    - schema"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo "  1. 运行: ./deploy.sh (构建并推送 Docker 镜像)"
echo "  2. 运行: ./aicore-cli.sh (注册 Workflow 和创建 Execution)"
echo ""
echo -e "${BLUE}提示：ai-core.yaml 已配置为使用此 Secret${NC}"
echo ""
