# 部署到 SAP AI Core 完整指南

## 前置条件

1. ✅ SAP AI Core 实例已创建
2. ✅ Docker Registry 可访问（如 Docker Hub、SAP Container Registry）
3. ✅ SAP HANA Cloud 实例已配置
4. ✅ AI Core CLI 或访问 AI Core API 的凭证

## 步骤 1：准备 HANA 数据库

### 1.1 连接到 HANA Cloud

使用 SAP HANA Database Explorer 或 hdbsql 连接。

### 1.2 创建表结构

```sql
-- 创建 Schema
CREATE SCHEMA "EXPENSE_SCHEMA";

-- 创建费用表
CREATE TABLE "EXPENSE_SCHEMA"."EXPENSES" (
    "EXPENSE_ID" NVARCHAR(50) PRIMARY KEY,
    "EMPLOYEE_ID" NVARCHAR(50) NOT NULL,
    "EXPENSE_TYPE" NVARCHAR(50),
    "AMOUNT" DECIMAL(10, 2) NOT NULL,
    "CURRENCY" NVARCHAR(3) DEFAULT 'USD',
    "EXPENSE_DATE" DATE,
    "DESCRIPTION" NVARCHAR(500),
    "RECEIPT_URL" NVARCHAR(500),
    "STATUS" NVARCHAR(20) DEFAULT 'NEW',
    "RISK_SCORE" DECIMAL(5, 2),
    "AUDIT_NOTES" NVARCHAR(1000),
    "AUDITED_AT" TIMESTAMP,
    "CREATED_AT" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "UPDATED_AT" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引以提高查询性能
CREATE INDEX "IDX_EXPENSE_STATUS" ON "EXPENSE_SCHEMA"."EXPENSES"("STATUS");
CREATE INDEX "IDX_EXPENSE_DATE" ON "EXPENSE_SCHEMA"."EXPENSES"("EXPENSE_DATE");
```

### 1.3 插入测试数据

```sql
-- 插入测试费用记录
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES" VALUES
('EXP001', 'EMP001', 'TRAVEL', 150.00, 'USD', '2024-01-15', 'Flight to customer site', 'https://receipts.com/001.pdf', 'NEW', NULL, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('EXP002', 'EMP002', 'MEAL', 75.50, 'USD', '2024-01-16', 'Business lunch', NULL, 'NEW', NULL, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('EXP003', 'EMP003', 'ENTERTAINMENT', 500.00, 'USD', '2024-01-17', 'Client gift', 'https://receipts.com/003.pdf', 'NEW', NULL, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

## 步骤 2：构建并推送 Docker 镜像

### 2.1 登录 Docker Registry

```bash
# Docker Hub
docker login

# 或 SAP Container Registry
docker login <your-sap-registry-url>
```

### 2.2 构建镜像

```bash
cd expense-audit-job

# 构建镜像（替换 your-username）
docker build -t your-username/expense-audit-job:1.0.0 .

# 验证镜像
docker images | grep expense-audit-job
```

### 2.3 推送镜像

```bash
# 推送到 Docker Hub
docker push your-username/expense-audit-job:1.0.0

# 或推送到私有 Registry
docker tag your-username/expense-audit-job:1.0.0 <registry-url>/expense-audit-job:1.0.0
docker push <registry-url>/expense-audit-job:1.0.0
```

## 步骤 3：配置 SAP AI Core

### 3.1 获取 AI Core 凭证

从 SAP BTP Cockpit 获取 AI Core 服务密钥：

```json
{
  "url": "https://api.ai.prod.eu-central-1.aws.ml.hana.ondemand.com",
  "clientid": "...",
  "clientsecret": "...",
  "identityzone": "..."
}
```

### 3.2 获取 Access Token

```bash
# 设置变量
export AI_CORE_CLIENT_ID="<your-client-id>"
export AI_CORE_CLIENT_SECRET="<your-client-secret>"
export AI_CORE_AUTH_URL="<your-auth-url>"
export AI_CORE_API_URL="<your-api-url>"

# 获取 token
export ACCESS_TOKEN=$(curl -X POST "$AI_CORE_AUTH_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$AI_CORE_CLIENT_ID" \
  -d "client_secret=$AI_CORE_CLIENT_SECRET" \
  | jq -r '.access_token')

echo "Token: $ACCESS_TOKEN"
```

### 3.3 创建 Resource Group（如果不存在）

```bash
curl -X POST "$AI_CORE_API_URL/v2/admin/resourceGroups" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceGroupId": "expense-audit-rg"
  }'
```

### 3.4 创建 HANA Credentials Secret

```bash
# Base64 编码 HANA 凭证
export HANA_HOST_B64=$(echo -n "your-hana-host.hanacloud.ondemand.com" | base64)
export HANA_PORT_B64=$(echo -n "443" | base64)
export HANA_USER_B64=$(echo -n "your-hana-user" | base64)
export HANA_PASSWORD_B64=$(echo -n "your-hana-password" | base64)

# 创建 Secret
curl -X POST "$AI_CORE_API_URL/v2/admin/secrets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "hana-credentials",
    "data": {
      "host": "'$HANA_HOST_B64'",
      "port": "'$HANA_PORT_B64'",
      "user": "'$HANA_USER_B64'",
      "password": "'$HANA_PASSWORD_B64'"
    }
  }'
```

### 3.5 配置 Docker Registry Secret（如果是私有仓库）

```bash
# 创建 Docker Registry Secret
curl -X POST "$AI_CORE_API_URL/v2/admin/dockerRegistrySecrets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-docker-registry",
    "data": {
      ".dockerconfigjson": "<base64-encoded-docker-config>"
    }
  }'
```

## 步骤 4：注册 Workflow Template

### 4.1 更新 ai-core.yaml

确保镜像地址正确：

```yaml
image: your-username/expense-audit-job:1.0.0
```

### 4.2 注册 Application

```bash
# 创建 Application
curl -X POST "$AI_CORE_API_URL/v2/admin/applications" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/json" \
  -d '{
    "applicationName": "expense-audit-app",
    "repositoryUrl": "https://github.com/your-org/expense-audit-job",
    "revision": "main",
    "path": "/"
  }'
```

### 4.3 注册 Scenario

```bash
curl -X POST "$AI_CORE_API_URL/v2/lm/scenarios" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "expense-audit",
    "description": "Automated Expense Audit"
  }'
```

### 4.4 上传 Workflow Template

```bash
curl -X POST "$AI_CORE_API_URL/v2/lm/workflowtemplates" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/yaml" \
  --data-binary @ai-core.yaml
```

## 步骤 5：运行 Job

### 5.1 创建 Execution

```bash
curl -X POST "$AI_CORE_API_URL/v2/lm/executions" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/json" \
  -d '{
    "scenarioId": "expense-audit",
    "executableId": "expense-audit-job",
    "parameters": {
      "batch-size": "100"
    }
  }'
```

### 5.2 查看 Execution 状态

```bash
# 获取 Execution ID（从上一步返回）
export EXECUTION_ID="<execution-id>"

# 查看状态
curl "$AI_CORE_API_URL/v2/lm/executions/$EXECUTION_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"
```

### 5.3 查看日志

```bash
# 查看实时日志
curl "$AI_CORE_API_URL/v2/lm/executions/$EXECUTION_ID/logs" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"
```

## 步骤 6：验证结果

### 6.1 检查 HANA 数据

```sql
-- 查看审计后的费用记录
SELECT
    EXPENSE_ID,
    STATUS,
    RISK_SCORE,
    AUDIT_NOTES,
    AUDITED_AT
FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE STATUS IN ('APPROVED', 'REJECTED', 'NEEDS_REVIEW')
ORDER BY AUDITED_AT DESC;
```

### 6.2 查看统计

```sql
-- 审计结果统计
SELECT
    STATUS,
    COUNT(*) AS COUNT,
    AVG(RISK_SCORE) AS AVG_RISK_SCORE
FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE AUDITED_AT IS NOT NULL
GROUP BY STATUS;
```

## 步骤 7：设置定时执行（可选）

### 7.1 创建 Schedule

```bash
curl -X POST "$AI_CORE_API_URL/v2/lm/schedules" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "expense-audit-daily",
    "scenarioId": "expense-audit",
    "executableId": "expense-audit-job",
    "cron": "0 2 * * *",
    "parameters": {
      "batch-size": "100"
    }
  }'
```

## 故障排查

### 问题 1：Job 启动失败

```bash
# 检查 Workflow Template
curl "$AI_CORE_API_URL/v2/lm/workflowtemplates" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"

# 检查 Secret
curl "$AI_CORE_API_URL/v2/admin/secrets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"
```

### 问题 2：HANA 连接失败

- 检查 HANA 防火墙规则
- 验证 IP 白名单
- 确认用户权限

### 问题 3：Docker 镜像拉取失败

- 验证镜像地址
- 检查 Registry Secret 配置
- 确认镜像可访问性

## 清理资源

```bash
# 删除 Execution
curl -X DELETE "$AI_CORE_API_URL/v2/lm/executions/$EXECUTION_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"

# 删除 Schedule
curl -X DELETE "$AI_CORE_API_URL/v2/lm/schedules/<schedule-id>" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"
```

## 下一步

- ✅ 添加更多审计规则
- ✅ 集成 SAP Build Process Automation 进行人工审核
- ✅ 配置告警和监控
- ✅ 优化性能和批处理逻辑
