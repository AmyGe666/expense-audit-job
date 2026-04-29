# SAP AI Core Expense Audit Job - 项目概览

## 📁 项目结构

```
expense-audit-job/
├── app/                    # 应用程序代码目录
│   ├── main.py            # Job 入口文件（读取 NEW 状态费用并执行审计）
│   ├── hana.py            # SAP HANA 数据库连接器
│   ├── audit.py           # 费用审计业务逻辑
│   └── requirements.txt   # Python 依赖包
│
├── Dockerfile             # Docker 镜像定义
├── ai-core.yaml          # AI Core Workflow Template 配置
├── deploy.sh             # 快速部署脚本
├── test_local.py         # 本地测试脚本（使用 Mock 数据）
├── setup_hana.sql        # HANA 数据库初始化脚本
│
├── README.md             # 项目说明文档
├── DEPLOYMENT.md         # 详细部署指南
├── .gitignore           # Git 忽略文件配置
└── OVERVIEW.md          # 本文档
```

## 🎯 核心功能

### 1. 自动化费用审计
- 从 HANA 数据库读取状态为 `NEW` 的费用记录
- 基于规则引擎进行自动审计
- 更新审计结果到 HANA（状态、风险评分、审计备注）

### 2. 多维度风险评估

| 审计维度 | 规则描述 | 风险权重 |
|---------|---------|---------|
| 💰 金额检查 | 金额 > 1000 USD | +30 分 |
| 📄 发票检查 | 无发票且金额 > 50 | +40 分 |
| 🔍 关键词检查 | 包含 `gift`, `personal`, `entertainment` | +20 分/词 |
| 📅 日期检查 | 未来日期 | +50 分 |
| 📆 周末检查 | 办公用品/软件在周末采购 | +15 分 |

### 3. 审计决策逻辑

```
风险评分 0-39   → APPROVED (自动批准)
风险评分 40-69  → NEEDS_REVIEW (需要人工审核)
风险评分 70-100 → REJECTED (自动拒绝)
```

## 🔧 技术栈

- **语言**: Python 3.11
- **数据库**: SAP HANA Cloud
- **容器**: Docker
- **编排**: SAP AI Core (Kubernetes/Argo Workflows)
- **依赖**:
  - `hdbcli` - SAP HANA 数据库客户端
  - `python-dateutil` - 日期处理工具

## 🚀 快速开始

### 方式 1: 使用部署脚本（推荐）

```bash
cd expense-audit-job
./deploy.sh
```

### 方式 2: 手动部署

```bash
# 1. 构建镜像
docker build -t your-registry/expense-audit-job:1.0.0 .

# 2. 推送镜像
docker push your-registry/expense-audit-job:1.0.0

# 3. 更新 ai-core.yaml 中的镜像地址

# 4. 部署到 AI Core
# 详见 DEPLOYMENT.md
```

### 本地测试

```bash
# 运行本地测试（不需要 HANA 连接）
python test_local.py
```

## 📊 数据流程图

```
┌─────────────────┐
│  HANA Database  │
│   EXPENSES表    │
│  (STATUS='NEW') │
└────────┬────────┘
         │
         │ 1. 查询待审计费用
         ▼
┌─────────────────┐
│  AI Core Job    │
│   main.py       │
└────────┬────────┘
         │
         │ 2. 逐条审计
         ▼
┌─────────────────┐
│ ExpenseAuditor  │
│   audit.py      │
│ ┌─────────────┐ │
│ │ 金额检查    │ │
│ │ 发票检查    │ │
│ │ 关键词检查  │ │
│ │ 日期检查    │ │
│ │ 周末检查    │ │
│ └─────────────┘ │
└────────┬────────┘
         │
         │ 3. 返回审计结果
         │    - status
         │    - risk_score
         │    - notes
         ▼
┌─────────────────┐
│  HANA Database  │
│  更新审计结果   │
│  (STATUS更新)   │
└─────────────────┘
```

## 🔐 安全配置

### HANA 连接信息（通过 AI Core Secret 注入）

```yaml
Secret Name: hana-credentials
Keys:
  - host: HANA 主机地址
  - port: 端口号（通常 443）
  - user: 数据库用户名
  - password: 数据库密码
```

### 环境变量

| 变量名 | 描述 | 必需 | 默认值 |
|--------|------|------|--------|
| `HANA_HOST` | HANA 主机地址 | ✅ | - |
| `HANA_PORT` | HANA 端口 | ❌ | 443 |
| `HANA_USER` | 用户名 | ✅ | - |
| `HANA_PASSWORD` | 密码 | ✅ | - |
| `HANA_SCHEMA` | Schema 名称 | ❌ | EXPENSE_SCHEMA |
| `BATCH_SIZE` | 批处理大小 | ❌ | 100 |

## 📈 监控与日志

### 日志级别
- **INFO**: 常规操作日志（连接、查询、更新）
- **ERROR**: 错误信息（连接失败、审计失败）

### 关键日志示例

```log
2024-01-20 10:00:00 - root - INFO - === Expense Audit Job Started ===
2024-01-20 10:00:01 - root - INFO - Connecting to SAP HANA...
2024-01-20 10:00:02 - hana - INFO - Successfully connected to HANA at xxx.hanacloud.ondemand.com
2024-01-20 10:00:03 - root - INFO - Found 5 NEW expense records
2024-01-20 10:00:04 - root - INFO - Auditing expense ID: EXP001
2024-01-20 10:00:04 - audit - INFO - Audit result: {'status': 'APPROVED', 'risk_score': 10.0, 'notes': 'Auto-approved'}
2024-01-20 10:00:05 - hana - INFO - Updated expense EXP001 with status APPROVED
2024-01-20 10:00:10 - root - INFO - === Audit Summary ===
2024-01-20 10:00:10 - root - INFO - Total: 5
2024-01-20 10:00:10 - root - INFO - Success: 5
2024-01-20 10:00:10 - root - INFO - Failed: 0
```

## 🔄 扩展与自定义

### 添加新的审计规则

编辑 `app/audit.py` 文件：

```python
def audit(self, expense: Dict[str, Any]) -> Dict[str, Any]:
    risk_score = 0.0
    notes = []

    # 添加你的自定义规则
    if your_condition:
        risk_score += 25
        notes.append("Your custom rule triggered")

    # ... 其他规则
```

### 集成外部 API

```python
# 在 audit.py 中添加
import requests

def check_vendor_blacklist(self, vendor_name: str) -> bool:
    """检查供应商黑名单"""
    response = requests.get(f"https://api.example.com/vendors/{vendor_name}")
    return response.json().get('is_blacklisted', False)
```

### 添加机器学习模型

```python
# 集成 SAP AI Core 模型
from ai_api_client_sdk.models.serving import Serving

def ml_risk_prediction(self, expense: Dict) -> float:
    """使用 ML 模型预测风险"""
    # 调用已部署的 ML 模型
    pass
```

## 📅 定时执行配置

### 每日执行（凌晨 2 点）

```yaml
apiVersion: ai.sap.com/v1alpha1
kind: Schedule
metadata:
  name: expense-audit-daily
spec:
  cron: "0 2 * * *"
  workflowName: expense-audit-job
  scenarioId: expense-audit
```

### 其他 Cron 表达式示例

- 每小时: `"0 * * * *"`
- 每周一: `"0 9 * * 1"`
- 每月 1 号: `"0 0 1 * *"`

## 🧪 测试策略

### 单元测试（未来计划）

```bash
# 安装测试依赖
pip install pytest pytest-cov

# 运行测试
pytest tests/ --cov=app
```

### 集成测试

```bash
# 使用 test_local.py 进行本地集成测试
python test_local.py
```

### 性能测试

- 目标：处理 1000 条费用记录 < 5 分钟
- 资源：1 CPU, 2Gi 内存

## 📖 相关文档

- [README.md](README.md) - 项目说明
- [DEPLOYMENT.md](DEPLOYMENT.md) - 详细部署指南
- [SAP AI Core 官方文档](https://help.sap.com/docs/ai-core)
- [SAP HANA Python Client](https://pypi.org/project/hdbcli/)

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📝 版本历史

- **v1.0.0** (2024-01)
  - 初始版本
  - 基础审计规则实现
  - HANA 集成
  - AI Core Job 配置

## 🐛 已知问题

- [ ] 大批量数据（>10000条）处理可能超时
- [ ] 未实现审计日志的归档功能

## 🎯 未来计划

- [ ] 集成 SAP Build Process Automation 进行人工审核
- [ ] 添加机器学习模型支持
- [ ] 实现审计规则的可视化配置
- [ ] 添加 Webhook 通知功能
- [ ] 支持多币种转换

## 📞 支持

如有问题，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至团队邮箱
- 查阅 SAP Community

---

**最后更新**: 2024-01-20
**维护者**: Your Team
**许可**: MIT License (或根据你的需求修改)
