#!/bin/bash

# SAP AI Core API 调用脚本
# 用于快速执行常用的 AI Core API 操作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置文件（可选）
CONFIG_FILE=".aicore.config"

# 函数：打印带颜色的消息
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# 函数：检查必需工具
check_dependencies() {
    info "检查依赖工具..."
    for cmd in curl jq base64; do
        if ! command -v $cmd &> /dev/null; then
            error "$cmd 未安装"
            exit 1
        fi
    done
    success "所有依赖工具已安装"
}

# 函数：加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        info "加载配置文件: $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        warning "配置文件不存在，将交互式输入配置"
    fi
}

# 函数：保存配置
save_config() {
    cat > "$CONFIG_FILE" <<EOF
# SAP AI Core Configuration
AI_CORE_AUTH_URL="$AI_CORE_AUTH_URL"
AI_CORE_API_URL="$AI_CORE_API_URL"
AI_CORE_CLIENT_ID="$AI_CORE_CLIENT_ID"
AI_CORE_CLIENT_SECRET="$AI_CORE_CLIENT_SECRET"
RESOURCE_GROUP="$RESOURCE_GROUP"
EOF
    success "配置已保存到 $CONFIG_FILE"
}

# 函数：获取 Access Token
get_token() {
    info "获取 Access Token..."

    response=$(curl -s -X POST "$AI_CORE_AUTH_URL/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=client_credentials" \
        -d "client_id=$AI_CORE_CLIENT_ID" \
        -d "client_secret=$AI_CORE_CLIENT_SECRET")

    ACCESS_TOKEN=$(echo "$response" | jq -r '.access_token')

    if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
        error "获取 Access Token 失败"
        echo "$response" | jq .
        exit 1
    fi

    success "Access Token 已获取"
    export ACCESS_TOKEN
}

# 函数：创建 HANA Secret
create_hana_secret() {
    info "创建 HANA Credentials Secret..."

    read -p "HANA Host: " HANA_HOST
    read -p "HANA Port (默认 443): " HANA_PORT
    HANA_PORT=${HANA_PORT:-443}
    read -p "HANA User: " HANA_USER
    read -s -p "HANA Password: " HANA_PASSWORD
    echo ""

    # Base64 编码
    HANA_HOST_B64=$(echo -n "$HANA_HOST" | base64)
    HANA_PORT_B64=$(echo -n "$HANA_PORT" | base64)
    HANA_USER_B64=$(echo -n "$HANA_USER" | base64)
    HANA_PASSWORD_B64=$(echo -n "$HANA_PASSWORD" | base64)

    response=$(curl -s -X POST "$AI_CORE_API_URL/v2/admin/secrets" \
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

    if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        error "创建 Secret 失败"
        echo "$response" | jq .
        exit 1
    else
        success "HANA Secret 已创建"
    fi
}

# 函数：注册 Workflow Template
register_workflow() {
    info "注册 Workflow Template..."

    if [ ! -f "ai-core.yaml" ]; then
        error "ai-core.yaml 文件不存在"
        exit 1
    fi

    response=$(curl -s -X POST "$AI_CORE_API_URL/v2/lm/workflowtemplates" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "AI-Resource-Group: $RESOURCE_GROUP" \
        -H "Content-Type: application/yaml" \
        --data-binary @ai-core.yaml)

    echo "$response"

    if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        error "注册 Workflow Template 失败"
        echo "$response" | jq .
        exit 1
    else
        success "Workflow Template 已注册"
    fi
}

# 函数：创建 Execution
create_execution() {
    info "创建 Execution..."

    read -p "Scenario ID (默认 expense-audit): " SCENARIO_ID
    SCENARIO_ID=${SCENARIO_ID:-expense-audit}

    read -p "Workflow Name (默认 expense-audit-job): " WORKFLOW_NAME
    WORKFLOW_NAME=${WORKFLOW_NAME:-expense-audit-job}

    response=$(curl -s -X POST "$AI_CORE_API_URL/v2/lm/executions" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "AI-Resource-Group: $RESOURCE_GROUP" \
        -H "Content-Type: application/json" \
        -d '{
            "scenarioId": "'"$SCENARIO_ID"'",
            "executableId": "'"$WORKFLOW_NAME"'",
            "parameters": {
                "batch-size": "100"
            }
        }')

    EXECUTION_ID=$(echo "$response" | jq -r '.id')

    if [ "$EXECUTION_ID" = "null" ] || [ -z "$EXECUTION_ID" ]; then
        error "创建 Execution 失败"
        echo "$response" | jq .
        exit 1
    else
        success "Execution 已创建: $EXECUTION_ID"
        echo "$EXECUTION_ID" > .last_execution_id
    fi
}

# 函数：查看 Execution 状态
check_execution() {
    if [ -z "$1" ]; then
        if [ -f ".last_execution_id" ]; then
            EXECUTION_ID=$(cat .last_execution_id)
            info "使用上次的 Execution ID: $EXECUTION_ID"
        else
            read -p "Execution ID: " EXECUTION_ID
        fi
    else
        EXECUTION_ID=$1
    fi

    info "查询 Execution 状态..."

    response=$(curl -s "$AI_CORE_API_URL/v2/lm/executions/$EXECUTION_ID" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "AI-Resource-Group: $RESOURCE_GROUP")

    echo "$response" | jq .

    status=$(echo "$response" | jq -r '.status')
    case $status in
        "COMPLETED")
            success "Execution 已完成"
            ;;
        "RUNNING")
            warning "Execution 正在运行中"
            ;;
        "FAILED")
            error "Execution 执行失败"
            ;;
        *)
            info "状态: $status"
            ;;
    esac
}

# 函数：查看日志
view_logs() {
    if [ -z "$1" ]; then
        if [ -f ".last_execution_id" ]; then
            EXECUTION_ID=$(cat .last_execution_id)
            info "使用上次的 Execution ID: $EXECUTION_ID"
        else
            read -p "Execution ID: " EXECUTION_ID
        fi
    else
        EXECUTION_ID=$1
    fi

    info "获取 Execution 日志..."

    curl -s "$AI_CORE_API_URL/v2/lm/executions/$EXECUTION_ID/logs" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "AI-Resource-Group: $RESOURCE_GROUP" \
        | jq -r '.data.result'
}

# 函数：列出所有 Executions
list_executions() {
    info "列出所有 Executions..."

    response=$(curl -s "$AI_CORE_API_URL/v2/lm/executions" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "AI-Resource-Group: $RESOURCE_GROUP")

    echo "$response" | jq '.resources[] | {id: .id, status: .status, scenario: .scenarioId, created: .createdAt}'
}

# 主菜单
show_menu() {
    echo ""
    echo "=================================="
    echo "SAP AI Core - Expense Audit Job"
    echo "=================================="
    echo "1. 配置 AI Core 连接"
    echo "2. 创建 HANA Secret"
    echo "3. 注册 Workflow Template"
    echo "4. 创建 Execution"
    echo "5. 查看 Execution 状态"
    echo "6. 查看日志"
    echo "7. 列出所有 Executions"
    echo "0. 退出"
    echo "=================================="
    read -p "请选择操作 (0-7): " choice
}

# 主程序
main() {
    check_dependencies
    load_config

    while true; do
        show_menu

        case $choice in
            1)
                read -p "Auth URL: " AI_CORE_AUTH_URL
                read -p "API URL: " AI_CORE_API_URL
                read -p "Client ID: " AI_CORE_CLIENT_ID
                read -s -p "Client Secret: " AI_CORE_CLIENT_SECRET
                echo ""
                read -p "Resource Group: " RESOURCE_GROUP
                save_config
                get_token
                ;;
            2)
                get_token
                create_hana_secret
                ;;
            3)
                get_token
                register_workflow
                ;;
            4)
                get_token
                create_execution
                ;;
            5)
                get_token
                check_execution
                ;;
            6)
                get_token
                view_logs
                ;;
            7)
                get_token
                list_executions
                ;;
            0)
                info "退出"
                exit 0
                ;;
            *)
                error "无效选择"
                ;;
        esac
    done
}

# 如果作为脚本运行
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
