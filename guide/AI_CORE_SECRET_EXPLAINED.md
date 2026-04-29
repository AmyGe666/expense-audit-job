# AI Core Secret 详解

## 🎯 什么是 AI Core Secret？

**AI Core Secret 是一个安全的密钥存储机制，用于让运行在 AI Core 中的 Job 可以安全地访问外部资源（如 HANA 数据库）。**

---

## 📊 完整工作流程

```
┌─────────────────────────────────────────────────────────────┐
│  你的笔记本电脑                                              │
│  ├─ 通过 API 在 AI Core 中创建 Secret                      │
│  │  名称: hana-credentials                                 │
│  │  内容: host, port, user, password (Base64 编码)        │
│  └─ 部署 ai-core.yaml 到 AI Core                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  SAP AI Core (Kubernetes)                                   │
│                                                             │
│  ┌─────────────────────────────────────────┐               │
│  │  Job Pod (你的 Python 容器)             │               │
│  │                                         │               │
│  │  环境变量（自动注入）:                   │               │
│  │  HANA_HOST = "95fac...hana.com"        │  ← 从 Secret  │
│  │  HANA_USER = "DBADMIN"                 │     读取      │
│  │  HANA_PASSWORD = "***"                 │               │
│  │                                         │               │
│  │  app/main.py 读取环境变量 →            │               │
│  │  app/hana.py 连接 HANA                 │               │
│  └─────────────┬───────────────────────────┘               │
│                │                                           │
└────────────────┼───────────────────────────────────────────┘
                 │
                 │ 通过网络连接
                 ↓
┌─────────────────────────────────────────────────────────────┐
│  SAP HANA Cloud                                             │
│  95fac287-84a9-45e1-89a1-c88d5fd6c10e.hana.prod-eu12...    │
│                                                             │
│  ┌──────────────────────────────────────┐                  │
│  │  EXPENSE_SCHEMA.EXPENSES 表          │                  │
│  │  ├─ 读取 NEW 状态的费用              │                  │
│  │  └─ 更新审计结果                     │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 AI Core Secret 的创建方式

### ❌ 方式 1：BTP Cockpit UI（不支持）

**AI Core 的 Secret 无法通过 BTP Cockpit UI 创建！**

在 BTP Cockpit 中：
- ✅ 你可以看到 AI Core 服务实例
- ✅ 你可以创建 Service Key
- ❌ **但是没有 UI 界面来创建 Secret**

### ✅ 方式 2：通过 AI Core API 创建（唯一方式）

**必须通过 REST API 调用来创建 Secret**。

---

## 📝 手工创建 Secret 的步骤

### 步骤 1: 获取 Access Token

```bash
curl -X POST "https://cn-sdc-subaccount-eu12-oi6oims3.authentication.eu12.hana.ondemand.com/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=sb-20f547cf-44f3-420f-9832-03baa36f1e19!b1421301|xsuaa_std!b318061" \
  -d "client_secret=c16b32e9-929d-420c-b9c4-c5e92d43eb21\$7_wwxYwYy2kMRt5OjgYZayVXnfdMxU0SjwhwD2LqX3o="
```

**返回示例：**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 43199
}
```

### 步骤 2: Base64 编码你的 HANA 凭证

```bash
# Host（已知）
echo -n "95fac287-84a9-45e1-89a1-c88d5fd6c10e.hana.prod-eu12.hanacloud.ondemand.com" | base64
# 结果: OTVmYWMyODctODRhOS00NWUxLTg5YTEtYzg4ZDVmZDZjMTBlLmhhbmEucHJvZC1ldTEyLmhhbmFjbG91ZC5vbmRlbWFuZC5jb20=

# Port（已知）
echo -n "443" | base64
# 结果: NDQz

# 用户名（替换为你的）
echo -n "DBADMIN" | base64

# 密码（替换为你的）
echo -n "YourPassword123" | base64

# Schema（可选）
echo -n "EXPENSE_SCHEMA" | base64
```

### 步骤 3: 调用 AI Core API 创建 Secret

```bash
curl -X POST "https://api.ai.intprod-eu12.eu-central-1.aws.ml.hana.ondemand.com/v2/admin/secrets" \
  -H "Authorization: Bearer <步骤1获取的access_token>" \
  -H "AI-Resource-Group: default" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "hana-credentials",
    "data": {
      "host": "OTVmYWMyODctODRhOS00NWUxLTg5YTEtYzg4ZDVmZDZjMTBlLmhhbmEucHJvZC1ldTEyLmhhbmFjbG91ZC5vbmRlbWFuZC5jb20=",
      "port": "NDQz",
      "user": "<base64编码的用户名>",
      "password": "<base64编码的密码>",
      "schema": "<base64编码的schema>"
    }
  }'
```

---

## 🤔 为什么需要脚本？

### 手工操作的问题

**手工操作需要 4 个步骤，容易出错：**

1. ❌ 获取 Token（需要复制 `access_token`）
2. ❌ Base64 编码 5 个字段（容易拼写错误）
3. ❌ 手动构造 JSON（容易格式错误）
4. ❌ 发送 curl 请求（需要替换多个占位符）

### 脚本的价值

**自动化脚本 = 1 个命令完成所有步骤：**

```bash
./create-hana-secret.sh
```

脚本会：
- ✅ 自动获取 Access Token
- ✅ 自动 Base64 编码所有字段
- ✅ 自动构造正确的 JSON
- ✅ 自动发送 API 请求
- ✅ 显示成功或失败信息

---

## 🔐 Secret 的用途：安全传递密码

### ❌ 不好的做法：硬编码密码

```python
# app/hana.py
connection = dbapi.connect(
    address='95fac287-84a9-45e1-89a1-c88d5fd6c10e.hana.prod-eu12...',
    user='DBADMIN',
    password='MyPassword123'  # ❌ 明文密码在代码里！
)
```

**问题：**
- ❌ 密码暴露在代码中
- ❌ 推送到 Git 仓库 → 泄露
- ❌ Docker 镜像里包含密码 → 不安全
- ❌ 任何能访问镜像的人都能看到密码

### ✅ 好的做法：使用 Secret

**第 1 步：代码从环境变量读取**

```python
# app/hana.py
import os

connection = dbapi.connect(
    address=os.getenv('HANA_HOST'),      # ← 从环境变量读取
    user=os.getenv('HANA_USER'),         # ← 从环境变量读取
    password=os.getenv('HANA_PASSWORD')  # ← 从环境变量读取
)
```

**第 2 步：ai-core.yaml 引用 Secret**

```yaml
env:
  - name: HANA_HOST
    valueFrom:
      secretKeyRef:
        name: hana-credentials  # ← 引用 Secret 名称
        key: host               # ← 引用 Secret 中的 key

  - name: HANA_USER
    valueFrom:
      secretKeyRef:
        name: hana-credentials
        key: user

  - name: HANA_PASSWORD
    valueFrom:
      secretKeyRef:
        name: hana-credentials
        key: password
```

**第 3 步：运行时自动注入**

当 Job 在 AI Core 中运行时：
1. AI Core 读取 `hana-credentials` Secret
2. 自动解码 Base64
3. 注入到容器的环境变量中
4. 你的代码通过 `os.getenv()` 读取

---

## 💡 类比理解

**Secret 就像一个保险箱：**

### 步骤 1：把密码锁在保险箱里

```bash
# 使用脚本或 API 创建 Secret
./create-hana-secret.sh
```

### 步骤 2：告诉 AI Core "我需要用保险箱里的密码"

```yaml
# ai-core.yaml
env:
  - name: HANA_PASSWORD
    valueFrom:
      secretKeyRef:
        name: hana-credentials  # 保险箱名称
        key: password           # 保险箱里的某个格子
```

### 步骤 3：AI Core 自动打开保险箱

```bash
# Job 容器内部（AI Core 自动完成）
export HANA_PASSWORD="MyPassword123"
```

### 步骤 4：你的代码读取环境变量

```python
# app/hana.py
password = os.getenv('HANA_PASSWORD')  # 读取到 "MyPassword123"
```

---

## 🔒 安全性对比

| 方式 | 密码存储位置 | Git 仓库 | Docker 镜像 | 安全性 |
|------|-------------|---------|------------|--------|
| **硬编码** | 代码文件 | ❌ 会泄露 | ❌ 会泄露 | 🔴 很不安全 |
| **环境变量（明文）** | ai-core.yaml | ⚠️ 可能泄露 | ✅ 不会 | 🟡 不太安全 |
| **Secret（推荐）** | AI Core 加密存储 | ✅ 不会 | ✅ 不会 | 🟢 安全 |

---

## 📋 Secret 创建方式对比

| 操作 | BTP Cockpit UI | AI Core API | 脚本 |
|------|----------------|-------------|------|
| 创建 Secret | ❌ 不支持 | ✅ 唯一方式 | ✅ 自动化 API |
| 难度 | - | 🔴 复杂（4步） | 🟢 简单（1步） |
| 耗时 | - | ⏱️ 5-10 分钟 | ⏱️ 1 分钟 |
| 出错概率 | - | 🔴 高 | 🟢 低 |

---

## 🎯 Secret 工作原理总结

```
┌──────────────────────────────────────────────────────────┐
│ 1. 你创建 Secret (通过脚本或 API)                        │
│    名称: hana-credentials                                │
│    内容: {host, port, user, password} (Base64 编码)     │
└───────────────────────┬──────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ 2. Secret 加密存储在 AI Core                             │
└───────────────────────┬──────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ 3. ai-core.yaml 引用 Secret                              │
│    env:                                                  │
│      - name: HANA_PASSWORD                               │
│        valueFrom:                                        │
│          secretKeyRef:                                   │
│            name: hana-credentials                        │
│            key: password                                 │
└───────────────────────┬──────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ 4. Job 运行时，AI Core 自动解码并注入环境变量            │
│    容器内部: export HANA_PASSWORD="MyPassword123"        │
└───────────────────────┬──────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ 5. 你的代码读取环境变量                                   │
│    password = os.getenv('HANA_PASSWORD')                 │
└──────────────────────────────────────────────────────────┘
```

---

## 📝 总结

### Secret 的作用

**= 安全地给 Job 提供 HANA 密码**

- ✅ 密码不在代码里
- ✅ 密码不在 Docker 镜像里
- ✅ 密码加密存储在 AI Core
- ✅ 运行时自动注入到环境变量
- ✅ 代码通过 `os.getenv()` 读取

### 创建 Secret 的方式

1. **手工方式**：4 个步骤，容易出错
2. **脚本方式**：1 个命令，自动完成 ✅ 推荐

### 使用 Secret

```yaml
# ai-core.yaml 中引用 Secret
env:
  - name: HANA_PASSWORD
    valueFrom:
      secretKeyRef:
        name: hana-credentials
        key: password
```

```python
# 代码中读取
password = os.getenv('HANA_PASSWORD')
```

---

**这就是 AI Core Secret 的完整工作原理！** 🎉
