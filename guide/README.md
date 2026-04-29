# 📚 Documentation Guide

欢迎来到 SAP AI Core Expense Audit Job 的文档中心！

## 🎯 文档分类

### 🚀 快速开始（新手必读）

| 文档 | 说明 | 阅读时间 |
|------|------|---------|
| [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) | **如何在 GitHub 中配置 Docker Hub 凭证** | 5 分钟 |
| [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) | **使用 GitHub Actions 自动构建镜像** | 10 分钟 |

**推荐阅读顺序**：
1. 先看 GITHUB_SECRETS_SETUP.md 配置凭证
2. 再看 GITHUB_ACTIONS_GUIDE.md 了解自动构建
3. 回到根目录的 README.md 开始部署

---

### 📖 详细指南（深入了解）

| 文档 | 说明 | 适合场景 |
|------|------|----------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | **完整的手动部署步骤** | 需要完全控制部署流程 |
| [AI_CORE_SECRET_EXPLAINED.md](AI_CORE_SECRET_EXPLAINED.md) | **Secret 是什么？为什么需要？** | 想理解 Secret 的工作原理 |
| [EXISTING_DB_CONFIG.md](EXISTING_DB_CONFIG.md) | **如何适配现有 HANA 数据库** | 已有数据库，不想新建表 |
| [ADAPT_EXISTING_DB.md](ADAPT_EXISTING_DB.md) | **数据库适配详细说明** | EXISTING_DB_CONFIG.md 的补充 |

---

### 📋 参考资料（日常使用）

| 文档 | 说明 | 何时查看 |
|------|------|----------|
| [QUICKREF.md](QUICKREF.md) | **常用命令速查表** | 忘记命令时快速查找 |
| [OVERVIEW.md](OVERVIEW.md) | **项目架构和技术细节** | 想了解系统设计 |
| [CHECKLIST.md](CHECKLIST.md) | **部署前检查清单** | 部署前确认所有步骤 |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | **项目总结和统计** | 向领导汇报项目进展 |

---

## 🗺️ 学习路径推荐

### 路径 1：第一次部署（零基础）

```
1. 📖 README.md (根目录)
   └─ 了解项目是什么

2. 📖 GITHUB_SECRETS_SETUP.md
   └─ 配置 Docker Hub 凭证

3. 📖 GITHUB_ACTIONS_GUIDE.md
   └─ 自动构建 Docker 镜像

4. 📖 QUICKREF.md
   └─ 查看常用命令

5. ✅ 开始部署！
```

### 路径 2：已有数据库

```
1. 📖 EXISTING_DB_CONFIG.md
   └─ 了解如何适配现有数据库

2. 📖 ADAPT_EXISTING_DB.md
   └─ 查看 SQL 脚本和详细步骤

3. 📖 GITHUB_ACTIONS_GUIDE.md
   └─ 自动构建镜像

4. ✅ 开始部署！
```

### 路径 3：想深入了解原理

```
1. 📖 OVERVIEW.md
   └─ 了解项目架构

2. 📖 AI_CORE_SECRET_EXPLAINED.md
   └─ 理解 Secret 的工作原理

3. 📖 DEPLOYMENT.md
   └─ 查看完整的手动部署流程

4. 📖 CHECKLIST.md
   └─ 了解生产环境部署要求
```

### 路径 4：日常运维

```
1. 📖 QUICKREF.md
   └─ 快速查找常用命令

2. 📖 CHECKLIST.md
   └─ 部署前检查

3. 📖 PROJECT_SUMMARY.md
   └─ 项目状态总结
```

---

## 🔍 快速查找

### 我想知道...

- **如何配置 GitHub Secrets？**
  → [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

- **如何自动构建 Docker 镜像？**
  → [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md)

- **什么是 AI Core Secret？**
  → [AI_CORE_SECRET_EXPLAINED.md](AI_CORE_SECRET_EXPLAINED.md)

- **如何手动部署？**
  → [DEPLOYMENT.md](DEPLOYMENT.md)

- **我有现成的数据库怎么办？**
  → [EXISTING_DB_CONFIG.md](EXISTING_DB_CONFIG.md)

- **常用命令有哪些？**
  → [QUICKREF.md](QUICKREF.md)

- **项目的架构是什么样的？**
  → [OVERVIEW.md](OVERVIEW.md)

- **部署前要检查什么？**
  → [CHECKLIST.md](CHECKLIST.md)

---

## 📊 文档完整度

| 类别 | 完成度 | 说明 |
|------|--------|------|
| 快速开始 | ✅ 100% | 已完成 |
| 详细指南 | ✅ 100% | 已完成 |
| 参考资料 | ✅ 100% | 已完成 |
| 代码示例 | ✅ 100% | 已完成 |
| 故障排查 | ✅ 100% | 已完成 |

---

## 💡 使用建议

1. **第一次部署**：按顺序阅读"快速开始"分类的文档
2. **遇到问题**：先查看对应文档的"故障排查"章节
3. **日常使用**：把 QUICKREF.md 收藏起来
4. **深入学习**：阅读"详细指南"分类的所有文档

---

## 🆘 需要帮助？

- 📖 所有文档都包含详细的步骤说明
- 💡 每个文档都有故障排查章节
- 📧 遇到问题可以提 Issue 或联系团队

---

**返回上级**：[← 返回项目根目录](../README.md)
