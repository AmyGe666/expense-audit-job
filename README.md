# SAP AI Core Expense Audit Job

自动化费用审计 Job，用于在 SAP AI Core 中运行。

## 📁 项目结构

```
expense-audit-job/
├─ app/                    # 应用程序代码
│  ├─ main.py             # Job 入口文件
│  ├─ hana.py             # HANA 数据库连接器
│  ├─ audit.py            # 审计逻辑
│  └─ requirements.txt    # Python 依赖
├─ guide/                  # 📚 完整文档目录
│  ├─ GITHUB_SECRETS_SETUP.md        # GitHub Secrets 配置指南
│  ├─ GITHUB_ACTIONS_GUIDE.md        # GitHub Actions 使用指南
│  ├─ DEPLOYMENT.md                  # 详细部署步骤
│  ├─ AI_CORE_SECRET_EXPLAINED.md    # AI Core Secret 详解
│  ├─ EXISTING_DB_CONFIG.md          # 适配现有数据库指南
│  ├─ QUICKREF.md                    # 快速参考手册
│  ├─ OVERVIEW.md                    # 项目架构概览
│  ├─ CHECKLIST.md                   # 部署检查清单
│  └─ PROJECT_SUMMARY.md             # 项目总结
├─ .github/
│  └─ workflows/
│     └─ docker-build.yml # GitHub Actions 工作流
├─ Dockerfile              # Docker 镜像定义
├─ ai-core.yaml           # AI Core Job 配置
├─ create-hana-secret.sh  # 创建 HANA Secret 脚本
├─ aicore-cli.sh          # AI Core 管理工具
└─ README.md              # 本文档（快速入门）
```

## 📚 文档导航

| 文档 | 用途 | 适合人群 |
|------|------|----------|
| **快速开始** | | |
| [README.md](README.md) | 快速入门指南 | 所有人 |
| [guide/GITHUB_SECRETS_SETUP.md](guide/GITHUB_SECRETS_SETUP.md) | GitHub Secrets 配置 | 首次部署 |
| [guide/GITHUB_ACTIONS_GUIDE.md](guide/GITHUB_ACTIONS_GUIDE.md) | GitHub Actions 自动构建 | 首次部署 |
| **详细指南** | | |
| [guide/DEPLOYMENT.md](guide/DEPLOYMENT.md) | 完整部署步骤 | 运维/部署人员 |
| [guide/AI_CORE_SECRET_EXPLAINED.md](guide/AI_CORE_SECRET_EXPLAINED.md) | Secret 工作原理 | 想深入了解的人 |
| [guide/EXISTING_DB_CONFIG.md](guide/EXISTING_DB_CONFIG.md) | 适配现有数据库 | 有现成数据库的人 |
| **参考资料** | | |
| [guide/OVERVIEW.md](guide/OVERVIEW.md) | 项目架构和技术细节 | 开发人员 |
| [guide/QUICKREF.md](guide/QUICKREF.md) | 常用命令速查 | 日常使用者 |
| [guide/CHECKLIST.md](guide/CHECKLIST.md) | 部署前检查清单 | 项目经理/QA |
| [guide/PROJECT_SUMMARY.md](guide/PROJECT_SUMMARY.md) | 项目总结 | 项目经理 |

## 🚀 快速开始（3 步部署）

### 方式 1：使用 GitHub Actions 自动构建（推荐）✅

**无需本地 Docker 环境，代码推送后自动构建镜像！**

#### 步骤 1：配置 GitHub Secrets
```bash
# 1. 打开你的 GitHub 仓库
https://github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job

# 2. 进入 Settings → Secrets and variables → Actions
# 3. 添加两个 Secrets：
#    - DOCKER_USERNAME: 你的 Docker Hub 用户名
#    - DOCKER_PASSWORD: 你的 Docker Hub Token
```

📖 **详细步骤**：[guide/GITHUB_SECRETS_SETUP.md](guide/GITHUB_SECRETS_SETUP.md)

#### 步骤 2：推送代码，自动构建镜像
```bash
cd /Users/I060231/Desktop/git-SDC-GEA-LearningGroup/expense-audit-job

git add .
git commit -m "Initial commit: AI Core Expense Audit Job"
git push -u origin master

# 🎉 GitHub Actions 会自动构建并推送 Docker 镜像！
# 查看进度：https://github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job/actions
```

#### 步骤 3：部署到 AI Core
```bash
# 1. 创建 HANA Secret
./create-hana-secret.sh
# 输入：Resource Group (default)、HANA 用户名、密码、Schema (EXPENSE_MANAGEMENT)

# 2. 注册 Workflow 并运行 Job
./aicore-cli.sh
# 选择 3: 注册 Workflow Template
# 选择 4: 创建 Execution
# 选择 6: 查看日志
```

📖 **完整指南**：[guide/GITHUB_ACTIONS_GUIDE.md](guide/GITHUB_ACTIONS_GUIDE.md)

---

### 方式 2：本地构建（需要 Docker 环境）

如果你有本地 Docker 环境且能访问 Docker Hub：

```bash
# 1. 构建并推送镜像
./deploy.sh

# 2. 创建 HANA Secret
./create-hana-secret.sh

# 3. 部署到 AI Core
./aicore-cli.sh
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "hana-credentials",
    "data": {
      "host": "<base64-encoded-host>",
      "port": "<base64-encoded-port>",
      "user": "<base64-encoded-user>",
      "password": "<base64-encoded-password>"
    }
  }'
```

### 3. 更新 ai-core.yaml

修改 `ai-core.yaml` 中的镜像地址：

```yaml
image: your-registry/expense-audit-job:1.0.0
```

### 4. 注册 Workflow Template

```bash
# 使用 AI Core CLI 或 API 注册
kubectl apply -f ai-core.yaml

# 或使用 AI Core API
curl -X POST "https://<ai-core-api-url>/v2/lm/workflowtemplates" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/yaml" \
  --data-binary @ai-core.yaml
```

### 5. 创建 Execution (运行 Job)

```bash
# 通过 AI Core API 创建 Execution
curl -X POST "https://<ai-core-api-url>/v2/lm/executions" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "scenarioId": "expense-audit",
    "workflowName": "expense-audit-job",
    "parameters": {
      "batch-size": "100"
    }
  }'
```

## 📊 审计规则

当前实现的审计规则：

1. **金额检查**：金额超过 1000 增加风险分
2. **发票检查**：无发票且金额 > 50 将被标记
3. **关键词检查**：描述中包含 `gift`、`personal`、`entertainment` 等可疑词汇
4. **日期检查**：未来日期的费用记录
5. **周末检查**：办公用品/软件在周末购买可能可疑

### 风险评分规则

- **0-39**：自动批准 (`APPROVED`)
- **40-69**：需要人工审核 (`NEEDS_REVIEW`)
- **70-100**：自动拒绝 (`REJECTED`)

## 🗄️ 数据库表结构

预期的 HANA 表结构：

```sql
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
```

## 🔧 配置环境变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `HANA_HOST` | HANA 主机地址 | - |
| `HANA_PORT` | HANA 端口 | 443 |
| `HANA_USER` | HANA 用户名 | - |
| `HANA_PASSWORD` | HANA 密码 | - |
| `HANA_SCHEMA` | Schema 名称 | EXPENSE_SCHEMA |
| `BATCH_SIZE` | 批处理大小 | 100 |

## 📝 日志查看

在 AI Core 中查看 Job 日志：

```bash
# 获取 Execution ID 后查看日志
curl "https://<ai-core-api-url>/v2/lm/executions/<execution-id>/logs" \
  -H "Authorization: Bearer <token>"
```

## 🧪 本地测试

在本地测试前，设置环境变量：

```bash
export HANA_HOST="your-hana-host"
export HANA_PORT="443"
export HANA_USER="your-user"
export HANA_PASSWORD="your-password"
export HANA_SCHEMA="EXPENSE_SCHEMA"

# 安装依赖
pip install -r app/requirements.txt

# 运行
python app/main.py
```

## 🔄 定时执行

如需定时执行，可以使用 AI Core 的 Schedule 功能：

```yaml
apiVersion: ai.sap.com/v1alpha1
kind: Schedule
metadata:
  name: expense-audit-schedule
spec:
  cron: "0 2 * * *"  # 每天凌晨 2 点执行
  workflowName: expense-audit-job
  scenarioId: expense-audit
```

## 📈 监控和告警

建议配置：
- Job 执行失败告警
- 处理时间超时告警
- 高风险费用数量告警

## 🛠️ 自定义审计规则

修改 `app/audit.py` 中的 `ExpenseAuditor` 类来添加自定义规则：

```python
def audit(self, expense: Dict[str, Any]) -> Dict[str, Any]:
    # 添加你的自定义规则
    pass
```

## 📞 支持

如有问题，请联系开发团队或查看 SAP AI Core 文档。
