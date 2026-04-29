# 📁 项目结构总览

```
expense-audit-job/
│
├── 📱 应用代码
│   └── app/
│       ├── main.py                      # Job 主入口
│       ├── hana.py                      # HANA 连接器
│       ├── audit.py                     # 审计逻辑引擎
│       └── requirements.txt             # Python 依赖
│
├── 🐳 Docker 相关
│   ├── Dockerfile                       # 镜像构建定义
│   └── .dockerignore                    # Docker 忽略文件
│
├── ⚙️  AI Core 配置
│   └── ai-core.yaml                     # Workflow Template 定义
│
├── 🤖 GitHub Actions
│   └── .github/
│       └── workflows/
│           └── docker-build.yml         # 自动构建工作流
│
├── 🔧 脚本工具
│   ├── create-hana-secret.sh            # 创建 HANA Secret
│   ├── aicore-cli.sh                    # AI Core 管理工具
│   ├── deploy.sh                        # 本地构建脚本
│   └── delete_secret.sh                 # 删除 Secret 工具
│
├── 💾 数据库脚本
│   ├── setup_hana.sql                   # 创建新表结构
│   ├── adapt_existing_db.sql            # 适配现有数据库
│   └── check_hana_structure.py          # 检查数据库工具
│
├── 📚 文档中心
│   └── guide/
│       ├── README.md                    # 文档导航
│       ├── GITHUB_SECRETS_SETUP.md      # GitHub Secrets 配置 ⭐
│       ├── GITHUB_ACTIONS_GUIDE.md      # GitHub Actions 指南 ⭐
│       ├── DEPLOYMENT.md                # 完整部署指南
│       ├── AI_CORE_SECRET_EXPLAINED.md  # Secret 详解
│       ├── EXISTING_DB_CONFIG.md        # 现有数据库适配
│       ├── ADAPT_EXISTING_DB.md         # 数据库适配详解
│       ├── QUICKREF.md                  # 快速参考手册
│       ├── OVERVIEW.md                  # 项目架构概览
│       ├── CHECKLIST.md                 # 部署检查清单
│       └── PROJECT_SUMMARY.md           # 项目总结
│
├── 📖 主文档
│   ├── README.md                        # 快速入门指南 ⭐
│   └── STRUCTURE.md                     # 本文档
│
└── 🗑️  配置文件
    └── .gitignore                       # Git 忽略配置
```

---

## 🎯 快速定位

### 我想要...

#### 🚀 开始部署
- 👉 先看：[README.md](README.md)
- 👉 配置 GitHub：[guide/GITHUB_SECRETS_SETUP.md](guide/GITHUB_SECRETS_SETUP.md)
- 👉 自动构建：[guide/GITHUB_ACTIONS_GUIDE.md](guide/GITHUB_ACTIONS_GUIDE.md)

#### 🔧 修改代码
- 👉 审计逻辑：`app/audit.py`
- 👉 数据库操作：`app/hana.py`
- 👉 Job 主流程：`app/main.py`

#### 📖 查文档
- 👉 所有文档：[guide/README.md](guide/README.md)
- 👉 常用命令：[guide/QUICKREF.md](guide/QUICKREF.md)

#### 🐛 排查问题
- 👉 部署问题：[guide/DEPLOYMENT.md](guide/DEPLOYMENT.md) 的故障排查
- 👉 数据库问题：[guide/EXISTING_DB_CONFIG.md](guide/EXISTING_DB_CONFIG.md)

---

## 📊 文件统计

| 类型 | 数量 | 说明 |
|------|------|------|
| Python 代码 | 3 个 | main.py, hana.py, audit.py |
| 脚本工具 | 4 个 | Shell 脚本 |
| 配置文件 | 2 个 | Dockerfile, ai-core.yaml |
| SQL 脚本 | 2 个 | 数据库初始化和适配 |
| 文档 | 12 个 | Markdown 文档 |
| **总计** | **23+ 个文件** | 完整的项目结构 |

---

## 🔄 常用文件修改场景

### 场景 1：调整审计规则
```
修改文件：app/audit.py
影响范围：审计逻辑
是否需要重新构建：✅ 是
```

### 场景 2：修改数据库连接
```
修改文件：无（通过 Secret 配置）
操作方式：重新运行 create-hana-secret.sh
是否需要重新构建：❌ 否
```

### 场景 3：修改 AI Core 配置
```
修改文件：ai-core.yaml
影响范围：Job 资源配置
是否需要重新构建：❌ 否
操作：重新注册 Workflow Template
```

### 场景 4：更新 Docker 镜像
```
触发方式：git push（自动）
或手动：./deploy.sh
查看进度：GitHub Actions 页面
```

---

## 📦 核心组件说明

### 1. 应用代码 (`app/`)
- **main.py**: Job 启动入口，协调整个审计流程
- **hana.py**: 封装所有 HANA 数据库操作
- **audit.py**: 实现审计规则引擎
- **requirements.txt**: 定义 Python 依赖（hdbcli 等）

### 2. Docker 配置
- **Dockerfile**: 定义如何构建运行环境
- **.dockerignore**: 排除不需要打包的文件

### 3. AI Core 配置
- **ai-core.yaml**: 定义 Job 在 AI Core 中的运行方式

### 4. 自动化工具
- **GitHub Actions**: 代码推送后自动构建镜像
- **Shell 脚本**: 简化手动操作

### 5. 文档体系
- **guide/**: 完整的使用指南和参考文档
- **README.md**: 快速入门

---

## 🎓 最佳实践

### 文件组织
- ✅ 代码和文档分离
- ✅ 配置外部化（通过 Secret）
- ✅ 脚本工具化（自动化常见操作）

### 版本控制
- ✅ 使用 Git 管理所有代码和配置
- ✅ 通过 GitHub Actions 自动化 CI/CD
- ✅ 镜像使用语义化版本号

### 文档维护
- ✅ 每个功能都有对应文档
- ✅ 文档包含故障排查章节
- ✅ 提供快速参考和详细指南

---

**返回主文档**：[README.md](README.md) | **查看所有文档**：[guide/README.md](guide/README.md)
