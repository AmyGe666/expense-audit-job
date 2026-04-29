# 🚀 快速参考

## 常用命令

### 本地开发
```bash
# 本地测试（不需要 HANA）
python test_local.py

# 安装依赖
pip install -r app/requirements.txt

# 设置环境变量后运行
export HANA_HOST="your-host"
export HANA_USER="your-user"
export HANA_PASSWORD="your-password"
python app/main.py
```

### Docker 操作
```bash
# 构建镜像
docker build -t expense-audit-job:latest .

# 本地运行测试
docker run --rm \
  -e HANA_HOST="your-host" \
  -e HANA_USER="your-user" \
  -e HANA_PASSWORD="your-password" \
  expense-audit-job:latest

# 推送镜像
docker push your-registry/expense-audit-job:1.0.0
```

### AI Core 操作
```bash
# 获取 Access Token
export ACCESS_TOKEN=$(curl -X POST "$AI_CORE_AUTH_URL/oauth/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  | jq -r '.access_token')

# 创建 Secret
curl -X POST "$API_URL/v2/admin/secrets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -d @secret.json

# 注册 Workflow Template
curl -X POST "$API_URL/v2/lm/workflowtemplates" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  --data-binary @ai-core.yaml

# 创建 Execution
curl -X POST "$API_URL/v2/lm/executions" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg" \
  -d '{
    "scenarioId": "expense-audit",
    "executableId": "expense-audit-job"
  }'

# 查看日志
curl "$API_URL/v2/lm/executions/$EXECUTION_ID/logs" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "AI-Resource-Group: expense-audit-rg"
```

### HANA 操作
```bash
# 连接 HANA
hdbsql -n your-host:443 -u YOUR_USER -p YOUR_PASSWORD -d YOUR_DB

# 查看待审计费用
SELECT * FROM "EXPENSE_SCHEMA"."EXPENSES" WHERE STATUS = 'NEW';

# 查看审计结果
SELECT STATUS, COUNT(*), AVG(RISK_SCORE)
FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE AUDITED_AT IS NOT NULL
GROUP BY STATUS;

# 重置测试数据
UPDATE "EXPENSE_SCHEMA"."EXPENSES"
SET STATUS = 'NEW', RISK_SCORE = NULL, AUDIT_NOTES = NULL, AUDITED_AT = NULL
WHERE EXPENSE_ID IN ('EXP001', 'EXP002', 'EXP003');
```

## 审计规则权重参考

| 条件 | 风险分 | 说明 |
|------|--------|------|
| 金额 > 1000 | +30 | 高金额费用 |
| 无发票 + 金额 > 50 | +40 | 缺少凭证 |
| 无发票 + 金额 ≤ 50 | +10 | 小额缺凭证 |
| 可疑关键词 | +20/词 | gift, personal, entertainment |
| 未来日期 | +50 | 日期异常 |
| 周末办公采购 | +15 | 时间可疑 |

## 决策阈值

```
0-39:   APPROVED (✅ 自动批准)
40-69:  NEEDS_REVIEW (⚠️  人工审核)
70-100: REJECTED (❌ 自动拒绝)
```

## 目录结构速查

```
expense-audit-job/
├── app/
│   ├── main.py          ← Job 入口
│   ├── hana.py          ← 数据库连接
│   ├── audit.py         ← 审计逻辑
│   └── requirements.txt ← Python 依赖
├── Dockerfile           ← 镜像定义
├── ai-core.yaml        ← AI Core 配置
├── deploy.sh           ← 部署脚本
└── test_local.py       ← 本地测试
```

## 环境变量

| 变量 | 必需 | 默认值 |
|------|------|--------|
| HANA_HOST | ✅ | - |
| HANA_PORT | ❌ | 443 |
| HANA_USER | ✅ | - |
| HANA_PASSWORD | ✅ | - |
| HANA_SCHEMA | ❌ | EXPENSE_SCHEMA |

## 故障排查

### Job 启动失败
```bash
# 检查 Pod 日志
kubectl logs -n <namespace> <pod-name>

# 检查 Workflow
kubectl get workflow -n <namespace>

# 查看 Secret
curl "$API_URL/v2/admin/secrets" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### HANA 连接失败
- ✅ 检查 IP 白名单
- ✅ 验证用户权限
- ✅ 确认 Secret 配置正确
- ✅ 测试网络连通性

### 镜像拉取失败
- ✅ 验证镜像地址
- ✅ 检查 Registry Secret
- ✅ 确认镜像已推送

## 有用的 SQL 查询

```sql
-- 高风险费用
SELECT * FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE RISK_SCORE > 70
ORDER BY RISK_SCORE DESC;

-- 今日审计统计
SELECT STATUS, COUNT(*)
FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE CAST(AUDITED_AT AS DATE) = CURRENT_DATE
GROUP BY STATUS;

-- 特定员工的费用
SELECT * FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE EMPLOYEE_ID = 'EMP001'
ORDER BY CREATED_AT DESC;
```

## 联系方式

- 📧 Email: your-team@example.com
- 📚 文档: [DEPLOYMENT.md](DEPLOYMENT.md)
- 🐛 问题: [GitHub Issues](https://github.com/your-org/expense-audit-job/issues)
