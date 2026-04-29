# 使用 GitHub Actions 自动构建 Docker 镜像

## 🎯 优势

- ✅ 不需要本地 Docker
- ✅ 不需要 Linux 服务器
- ✅ 代码推送后自动构建
- ✅ 自动推送到 Docker Hub
- ✅ 自动更新 ai-core.yaml

---

## 📋 配置步骤

### 步骤 1：添加 Docker Hub 凭证到 GitHub Secrets

1. **打开你的 GitHub 仓库**
   ```
   https://github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job
   ```

2. **进入 Settings → Secrets and variables → Actions**

   导航路径：
   ```
   仓库页面 → Settings (顶部菜单栏)
   → 左侧菜单 Secrets and variables
   → Actions
   ```

3. **点击 "New repository secret" 添加两个 Secret：**

   **Secret 1：**
   - Name: `DOCKER_USERNAME`
   - Value: `你的 Docker Hub 用户名`

   **Secret 2：**
   - Name: `DOCKER_PASSWORD`
   - Value: `你的 Docker Hub 密码或 Access Token`

   > 💡 推荐使用 Access Token 而不是密码：
   > 1. 登录 https://hub.docker.com/settings/security
   > 2. 创建 New Access Token
   > 3. 复制 Token 粘贴到 Secret 中

---

### 步骤 2：初始化 Git 并推送代码

在你的本机执行：

```bash
cd /Users/I060231/Desktop/git-SDC-GEA-LearningGroup/expense-audit-job

# 初始化 Git（如果还没有）
git init

# 添加远程仓库
git remote add origin https://github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job.git

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: AI Core Expense Audit Job"

# 推送到 GitHub（使用你的 SAP 账号）
git push -u origin main
```

如果主分支叫 `master` 而不是 `main`，使用：
```bash
git push -u origin master
```

---

### 步骤 3：GitHub Actions 自动构建

推送代码后，GitHub Actions 会自动：

1. ✅ 检出代码
2. ✅ 登录 Docker Hub
3. ✅ 构建 Docker 镜像
4. ✅ 推送到 Docker Hub
5. ✅ 更新 `ai-core.yaml` 中的镜像地址
6. ✅ 提交更新后的 `ai-core.yaml`

**查看构建进度：**
```
https://github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job/actions
```

---

### 步骤 4：等待构建完成

在 Actions 页面可以看到：
- 🟡 **黄色**：正在构建中
- ✅ **绿色**：构建成功
- ❌ **红色**：构建失败（点击查看日志）

构建通常需要 **3-5 分钟**。

---

### 步骤 5：拉取更新后的配置

构建成功后，`ai-core.yaml` 会被自动更新（包含正确的镜像地址）。

在本机拉取更新：

```bash
cd /Users/I060231/Desktop/git-SDC-GEA-LearningGroup/expense-audit-job
git pull origin main
```

---

### 步骤 6：部署到 AI Core

现在镜像已经在 Docker Hub 上了，可以部署：

```bash
# 1. 创建 HANA Secret
./create-hana-secret.sh

# 2. 部署到 AI Core
./aicore-cli.sh
# 选择 3: 注册 Workflow Template
# 选择 4: 创建 Execution
# 选择 6: 查看日志
```

---

## 🔄 后续更新流程

当你修改代码后：

```bash
# 1. 提交更改
git add .
git commit -m "Update: 描述你的更改"
git push

# 2. GitHub Actions 自动构建新镜像

# 3. 等待构建完成（3-5 分钟）

# 4. 拉取更新后的 ai-core.yaml
git pull

# 5. 在 AI Core 创建新的 Execution
./aicore-cli.sh
# 选择 4: 创建 Execution
```

---

## 🎯 触发构建的方式

### 方式 1：自动触发（推荐）

修改以下文件时自动触发：
- `app/` 目录下的任何文件
- `Dockerfile`
- `.github/workflows/docker-build.yml`

```bash
# 修改代码后
git add app/
git commit -m "Update audit logic"
git push
# GitHub Actions 自动开始构建
```

### 方式 2：手动触发

1. 打开 GitHub Actions 页面
2. 选择 "Build and Push Docker Image" workflow
3. 点击 "Run workflow"
4. 选择分支（main 或 master）
5. 点击绿色的 "Run workflow" 按钮

---

## 🐛 故障排查

### 问题 1：Actions 页面找不到

**原因**：公司 GitHub 可能默认关闭了 Actions

**解决**：
1. 进入 Settings → Actions → General
2. 启用 "Allow all actions and reusable workflows"

---

### 问题 2：构建失败 - Docker login failed

**原因**：Docker Hub 凭证配置错误

**解决**：
1. 检查 Secrets 中的 `DOCKER_USERNAME` 和 `DOCKER_PASSWORD`
2. 确保用户名和密码正确
3. 推荐使用 Access Token 而不是密码

---

### 问题 3：推送代码失败 - Authentication failed

**原因**：需要 SAP GitHub 认证

**解决**：
```bash
# 使用 Personal Access Token
# 1. 在 GitHub 创建 Token: Settings → Developer settings → Personal access tokens
# 2. 使用 Token 作为密码

git remote set-url origin https://YOUR_USERNAME@github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job.git
git push
```

---

### 问题 4：查看详细日志

点击 Actions 页面的具体构建 → 点击每个步骤查看详细输出

---

## 📊 工作流程图

```
本机修改代码
    ↓
git push 到 GitHub
    ↓
GitHub Actions 触发
    ↓
构建 Docker 镜像
    ↓
推送到 Docker Hub
    ↓
更新 ai-core.yaml
    ↓
提交回 GitHub
    ↓
本机 git pull
    ↓
部署到 AI Core
```

---

## 💡 小贴士

1. **第一次推送前**，确保已配置 Secrets
2. **构建时间**：通常 3-5 分钟
3. **查看镜像**：https://hub.docker.com/r/YOUR_USERNAME/expense-audit-job
4. **跳过 CI**：在 commit message 中加 `[skip ci]` 可以跳过构建

---

## ✅ 检查清单

- [ ] GitHub 仓库已创建
- [ ] Secrets 已配置（DOCKER_USERNAME, DOCKER_PASSWORD）
- [ ] 代码已推送到 GitHub
- [ ] GitHub Actions 已触发（查看 Actions 页面）
- [ ] 构建成功（绿色勾）
- [ ] Docker Hub 上可以看到镜像
- [ ] git pull 获取更新后的 ai-core.yaml
- [ ] 运行 create-hana-secret.sh
- [ ] 运行 aicore-cli.sh 部署

---

## 📞 需要帮助？

遇到问题可以：
1. 查看 GitHub Actions 的详细日志
2. 检查 Docker Hub 是否能访问
3. 确认 Secrets 配置正确

---

**下一步：配置 GitHub Secrets 并推送代码！** 🚀
