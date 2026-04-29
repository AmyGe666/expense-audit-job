# 在 GitHub 中配置 Secrets

## 🔐 什么是 GitHub Secrets？

GitHub Secrets 是用来**安全存储敏感信息**（如密码、API Key）的地方。

- ✅ 加密存储
- ✅ 不会出现在代码中
- ✅ 不会出现在日志中（自动隐藏）
- ✅ 只有仓库管理员可以修改

---

## 📋 配置步骤

### 步骤 1：打开你的 GitHub 仓库

访问：
```
https://github.tools.sap/SDC-GEA-LearningGroup/expense-audit-job
```

---

### 步骤 2：进入 Settings（设置）

点击仓库页面顶部的 **Settings** 按钮

```
[Code] [Issues] [Pull requests] [Actions] [Projects] [Wiki] [Settings] ← 点这里
```

---

### 步骤 3：找到 Secrets 设置

在左侧菜单中导航：

```
左侧菜单：
├─ General
├─ Collaborators
├─ ...
├─ Secrets and variables  ← 展开这个
│  ├─ Actions            ← 点击这个
│  ├─ Codespaces
│  └─ Dependabot
```

**完整路径**：Settings → Secrets and variables → Actions

---

### 步骤 4：添加 Secret

点击右上角的绿色按钮：**"New repository secret"**

---

### 步骤 5：添加第一个 Secret - Docker 用户名

在弹出的表单中填写：

| 字段 | 值 |
|------|-----|
| **Name** | `DOCKER_USERNAME` |
| **Secret** | 你的 Docker Hub 用户名 |

**示例：**
```
Name: DOCKER_USERNAME
Secret: johnsmith
```

点击 **"Add secret"** 保存。

---

### 步骤 6：添加第二个 Secret - Docker 密码

再次点击 **"New repository secret"**

| 字段 | 值 |
|------|-----|
| **Name** | `DOCKER_PASSWORD` |
| **Secret** | 你的 Docker Hub 密码或 Access Token（推荐） |

---

### 📝 如何获取 Docker Hub Access Token（推荐）

**为什么用 Token 而不是密码？**
- ✅ 更安全（可以随时撤销）
- ✅ 可以设置权限（只给需要的权限）
- ✅ 不会泄露真实密码

**步骤：**

1. **登录 Docker Hub**
   ```
   https://hub.docker.com
   ```

2. **进入安全设置**
   - 点击右上角头像
   - 选择 **Account Settings**
   - 左侧菜单点击 **Security**

3. **创建 Access Token**
   - 点击 **"New Access Token"**
   - 输入描述：`SAP AI Core GitHub Actions`
   - 权限选择：**Read & Write**（或 Read, Write, Delete）
   - 点击 **"Generate"**

4. **复制 Token**
   - ⚠️ **只显示一次！** 立即复制保存
   - 示例：`dckr_pat_xxxxxxxxxxxxxxxxxxxx`

5. **粘贴到 GitHub Secret**
   ```
   Name: DOCKER_PASSWORD
   Secret: dckr_pat_xxxxxxxxxxxxxxxxxxxx
   ```

点击 **"Add secret"** 保存。

---

### 步骤 7：确认 Secrets 已添加

在 **Actions secrets** 页面，你应该看到：

```
Repository secrets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name                    Updated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DOCKER_USERNAME         just now
DOCKER_PASSWORD         just now
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> 💡 注意：Secret 的值不会显示，只能看到名称和更新时间

---

## 🎯 为什么要用 Secrets？

### ❌ 不安全的方式（永远不要这样做）

```yaml
# 在代码中硬编码密码
env:
  DOCKER_USERNAME: johnsmith      # ❌ 所有人都能看到
  DOCKER_PASSWORD: mypassword123  # ❌ 密码泄露到 Git 历史！
```

**问题：**
- ❌ 密码明文存储在代码中
- ❌ 推送到 GitHub 后，所有有权限的人都能看到
- ❌ 即使删除提交，密码仍在 Git 历史中
- ❌ 可能被搜索引擎索引（如果是公开仓库）

---

### ✅ 安全的方式（使用 Secrets）

```yaml
# 使用 Secrets 引用
env:
  DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}  # ✅ 加密存储
  DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}  # ✅ 安全
```

**好处：**
- ✅ 加密存储在 GitHub 服务器
- ✅ 不会出现在代码和 Git 历史中
- ✅ 日志中自动隐藏为 `***`
- ✅ 只有仓库管理员可以修改
- ✅ 可以随时更新，不影响代码

---

## 🔍 如何在 GitHub Actions 中使用 Secrets

在 `.github/workflows/docker-build.yml` 中：

```yaml
steps:
  - name: Login to Docker Hub
    uses: docker/login-action@v2
    with:
      username: ${{ secrets.DOCKER_USERNAME }}  # ← 引用 Secret
      password: ${{ secrets.DOCKER_PASSWORD }}  # ← 引用 Secret
```

**运行时：**
- GitHub 会自动替换为实际的值
- 日志中显示为 `***` 避免泄露

---

## 📸 可视化导航

```
GitHub 仓库页面
    ↓
点击顶部 "Settings"
    ↓
左侧菜单 "Secrets and variables"
    ↓
点击 "Actions"
    ↓
右上角 "New repository secret"
    ↓
填写 Name 和 Secret
    ↓
点击 "Add secret"
    ↓
重复添加第二个 Secret
    ↓
✅ 完成！
```

---

## ✅ 配置完成检查清单

- [ ] 访问 GitHub 仓库
- [ ] 进入 Settings → Secrets and variables → Actions
- [ ] 添加 `DOCKER_USERNAME`（值：你的 Docker Hub 用户名）
- [ ] 添加 `DOCKER_PASSWORD`（值：Docker Hub Token）
- [ ] 看到两个 Secrets 已列出
- [ ] Secret 值已隐藏（只显示名称）

---

## 🚀 配置好 Secrets 后

现在可以推送代码，触发 GitHub Actions：

```bash
cd /Users/I060231/Desktop/git-SDC-GEA-LearningGroup/expense-audit-job

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: AI Core Expense Audit Job"

# 推送到 GitHub
git push -u origin master

# 🎉 GitHub Actions 会自动开始构建 Docker 镜像！
```

---

## 🐛 常见问题

### Q1: 找不到 Settings 按钮？

**A:** 可能权限不够。确保你是仓库的管理员或有相应权限。

---

### Q2: Secret 添加后能修改吗？

**A:** 可以！
1. 进入 Secrets 页面
2. 点击 Secret 名称旁的 **Update**
3. 输入新值
4. 保存

---

### Q3: Secret 可以查看吗？

**A:** 不可以！为了安全，Secret 的值一旦保存就无法查看，只能：
- 看到 Secret 名称
- 看到最后更新时间
- 更新为新值
- 删除 Secret

---

### Q4: 日志中会显示 Secret 吗？

**A:** 不会！GitHub 会自动检测并隐藏 Secret，显示为 `***`

示例：
```
Login to Docker Hub
Username: johnsmith
Password: ***  ← 自动隐藏
Login Succeeded
```

---

### Q5: 可以在多个仓库共享 Secret 吗？

**A:** 可以！使用 **Organization secrets**：
- Settings → Secrets and variables → Actions
- 点击 **Organization secrets** 标签
- 添加 Secret 并选择哪些仓库可以访问

---

## 📞 需要帮助？

- 获取 Docker Hub Token 有问题？查看 [Docker Hub 文档](https://docs.docker.com/docker-hub/access-tokens/)
- GitHub Secrets 配置问题？查看 [GitHub 文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

## 🎓 延伸阅读

- [GitHub Actions 最佳实践](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [环境变量与 Secrets 的区别](https://docs.github.com/en/actions/learn-github-actions/variables)

---

**下一步：** 推送代码，让 GitHub Actions 自动构建你的 Docker 镜像！🚀
