#!/bin/bash

# SAP AI Core Expense Audit Job - 快速部署脚本

set -e

echo "🚀 SAP AI Core Expense Audit Job - 部署脚本"
echo "================================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查必需的工具
echo "📋 检查必需工具..."
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker 未安装${NC}"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo -e "${RED}❌ curl 未安装${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}❌ jq 未安装${NC}"; exit 1; }
echo -e "${GREEN}✅ 所有必需工具已安装${NC}"

# 读取配置
echo ""
echo "📝 请输入配置信息："
read -p "Docker Registry (例如: docker.io/yourname): " DOCKER_REGISTRY
read -p "镜像名称 (默认: expense-audit-job): " IMAGE_NAME
IMAGE_NAME=${IMAGE_NAME:-expense-audit-job}
read -p "镜像标签 (默认: 1.0.0): " IMAGE_TAG
IMAGE_TAG=${IMAGE_TAG:-1.0.0}

FULL_IMAGE="$DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo ""
echo "🐳 构建 Docker 镜像..."
echo "镜像: $FULL_IMAGE"
docker build -t "$FULL_IMAGE" .

echo -e "${GREEN}✅ 镜像构建成功${NC}"

read -p "是否推送镜像到 Registry? (y/n): " PUSH_IMAGE
if [ "$PUSH_IMAGE" = "y" ]; then
    echo "📤 推送镜像..."
    docker push "$FULL_IMAGE"
    echo -e "${GREEN}✅ 镜像推送成功${NC}"
fi

echo ""
echo "📝 更新 ai-core.yaml..."
# 使用 sed 更新镜像地址
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|image:.*|image: $FULL_IMAGE|g" ai-core.yaml
else
    # Linux
    sed -i "s|image:.*|image: $FULL_IMAGE|g" ai-core.yaml
fi
echo -e "${GREEN}✅ ai-core.yaml 已更新${NC}"

echo ""
echo "================================================"
echo -e "${GREEN}✅ 本地部署完成！${NC}"
echo ""
echo "📋 下一步："
echo "1. 在 SAP AI Core 中创建 Secret 'hana-credentials'"
echo "2. 注册 Workflow Template: kubectl apply -f ai-core.yaml"
echo "3. 创建 Execution 运行 Job"
echo ""
echo "详细步骤请参考 DEPLOYMENT.md 文档"
echo "================================================"
