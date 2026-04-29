# 使用现有 HANA 数据库配置指南

## 🎯 你的情况

你已经有一个 POC 部署在 BTP 上，数据库和数据都已经存在，不需要创建。

---

## ✅ 配置步骤

### 步骤 1: 检查现有数据库结构

运行检查工具：

```bash
export HANA_USER="your_user"
export HANA_PASSWORD="your_password"
python check_hana_structure.py
```

这个工具会显示：
- ✅ 所有的 Schema 列表
- ✅ 指定 Schema 下的所有表
- ✅ 表的字段结构
- ✅ 示例数据

**记录以下信息：**
- Schema 名称（如：`MY_SCHEMA`）
- 表名称（如：`EXPENSES` 或 `EXPENSE_REPORTS`）
- 状态字段名（如：`STATUS` 或 `APPROVAL_STATUS`）
- 关键字段名

---

### 步骤 2: 根据实际情况选择配置方式

## 📋 情况 A：表结构完全匹配（推荐）

### 如果你的表结构是这样的：

```sql
CREATE TABLE "YOUR_SCHEMA"."EXPENSES" (
    "EXPENSE_ID" ...,
    "EMPLOYEE_ID" ...,
    "AMOUNT" ...,
    "STATUS" ...,      -- 状态字段：NEW, APPROVED, REJECTED
    "RISK_SCORE" ...,  -- 风险评分字段
    "AUDIT_NOTES" ..., -- 审计备注字段
    "AUDITED_AT" ...,  -- 审计时间字段
    ...
);
```

### ✅ 需要的配置：

#### 1. 运行 `create-hana-secret.sh`
```bash
./create-hana-secret.sh

# 当提示时输入实际的 Schema 名称
HANA Schema (默认: EXPENSE_SCHEMA): YOUR_ACTUAL_SCHEMA_NAME
```

#### 2. **跳过** `setup_hana.sql`
因为表已经存在，不需要创建！

#### 3. 确保表中有以下字段
```sql
-- 必须有的字段：
STATUS          -- 用于筛选待审计的记录
RISK_SCORE      -- 用于存储风险评分
AUDIT_NOTES     -- 用于存储审计备注
AUDITED_AT      -- 用于存储审计时间

-- 如果没有这些字段，需要添加：
ALTER TABLE "YOUR_SCHEMA"."EXPENSES" ADD ("RISK_SCORE" DECIMAL(5, 2));
ALTER TABLE "YOUR_SCHEMA"."EXPENSES" ADD ("AUDIT_NOTES" NVARCHAR(1000));
ALTER TABLE "YOUR_SCHEMA"."EXPENSES" ADD ("AUDITED_AT" TIMESTAMP);
```

#### 4. 部署
```bash
./deploy.sh
./aicore-cli.sh
```

✅ **完成！**

---

## 📋 情况 B：表名或字段名不同

### 如果你的表结构是这样的：

```sql
-- 表名不同
CREATE TABLE "MY_SCHEMA"."EXPENSE_REPORTS" (  -- ← 不是 EXPENSES
    "ID" ...,                    -- ← 不是 EXPENSE_ID
    "EMP_ID" ...,               -- ← 不是 EMPLOYEE_ID
    "APPROVAL_STATUS" ...,      -- ← 不是 STATUS
    ...
);
```

### ✅ 需要修改代码：

#### 修改 1: `app/hana.py` - 表名和字段名

找到所有 SQL 查询，替换为你的实际表名和字段名：

```python
# 原代码（第 60 行左右）
query = f"""
    SELECT
        EXPENSE_ID,
        EMPLOYEE_ID,
        EXPENSE_TYPE,
        AMOUNT,
        ...
    FROM "{self.schema}"."EXPENSES"  # ← 改成你的表名
    WHERE STATUS = ?                 # ← 改成你的字段名
    ...
"""

# 修改后
query = f"""
    SELECT
        ID as EXPENSE_ID,              # ← 使用 AS 映射
        EMP_ID as EMPLOYEE_ID,         # ← 使用 AS 映射
        EXPENSE_TYPE,
        AMOUNT,
        ...
    FROM "{self.schema}"."EXPENSE_REPORTS"  # ← 你的表名
    WHERE APPROVAL_STATUS = ?               # ← 你的字段名
    ...
"""
```

#### 修改 2: `app/hana.py` - 更新语句

```python
# 原代码（第 95 行左右）
update_query = f"""
    UPDATE "{self.schema}"."EXPENSES"  # ← 改成你的表名
    SET
        STATUS = ?,           # ← 改成你的字段名
        RISK_SCORE = ?,
        AUDIT_NOTES = ?,
        AUDITED_AT = ?,
        ...
    WHERE EXPENSE_ID = ?      # ← 改成你的字段名
"""

# 修改后
update_query = f"""
    UPDATE "{self.schema}"."EXPENSE_REPORTS"  # ← 你的表名
    SET
        APPROVAL_STATUS = ?,  # ← 你的字段名
        RISK_SCORE = ?,
        AUDIT_NOTES = ?,
        AUDITED_AT = ?,
        ...
    WHERE ID = ?              # ← 你的字段名
"""
```

#### 修改 3: `app/audit.py` - 字段名映射

如果字段名不同，确保 audit.py 中引用的字段名也对应：

```python
# 检查所有 expense.get('FIELD_NAME') 的地方
amount = float(expense.get('AMOUNT', 0))  # ← 确保字段名匹配
```

---

## 📋 情况 C：字段类型不同

如果你的字段类型不完全一样，比如：

```sql
-- 你的表
"AMOUNT" INTEGER        -- 而不是 DECIMAL(10, 2)
"STATUS" CHAR(1)        -- 而不是 NVARCHAR(20)
```

### ✅ 需要调整：

#### 1. 在 `create-hana-secret.sh` 中添加状态映射

或者在代码中处理：

```python
# app/hana.py
def get_expenses_by_status(self, status: str):
    # 如果你的状态是 'N' 而不是 'NEW'
    status_mapping = {
        'NEW': 'N',
        'APPROVED': 'A',
        'REJECTED': 'R'
    }
    actual_status = status_mapping.get(status, status)

    query = f"""
        SELECT ...
        FROM "{self.schema}"."EXPENSES"
        WHERE STATUS = ?
    """
    cursor.execute(query, (actual_status,))
    ...
```

---

## 🎯 快速决策树

```
你的表结构？
│
├─ 表名是 EXPENSES，字段名都匹配
│  └─ ✅ 只需配置 Schema 名称，直接部署
│
├─ 表名不同，或部分字段名不同
│  └─ ⚠️  需要修改 app/hana.py 中的 SQL
│
└─ 字段类型或状态值不同
   └─ ⚠️  需要修改代码添加映射逻辑
```

---

## 📝 最简单的方式

### 方案 1：添加审计字段到现有表（推荐）

如果你的表已经有 `STATUS` 字段，只需添加审计相关字段：

```sql
-- 在现有表中添加审计字段
ALTER TABLE "YOUR_SCHEMA"."YOUR_TABLE" ADD ("RISK_SCORE" DECIMAL(5, 2));
ALTER TABLE "YOUR_SCHEMA"."YOUR_TABLE" ADD ("AUDIT_NOTES" NVARCHAR(1000));
ALTER TABLE "YOUR_SCHEMA"."YOUR_TABLE" ADD ("AUDITED_AT" TIMESTAMP);
```

然后只修改代码中的表名和字段名。

### 方案 2：创建视图映射（最灵活）

如果不想修改代码，可以在 HANA 中创建一个视图：

```sql
-- 创建视图，映射字段名
CREATE VIEW "YOUR_SCHEMA"."EXPENSES" AS
SELECT
    ID as EXPENSE_ID,
    EMP_ID as EMPLOYEE_ID,
    APPROVAL_STATUS as STATUS,
    -- ... 其他字段映射
FROM "YOUR_SCHEMA"."YOUR_ACTUAL_TABLE";
```

这样代码完全不用改，只需配置 Schema 名称！

---

## 🤔 需要你提供的信息

为了给你最准确的配置建议，请告诉我：

1. **Schema 名称是什么？**
2. **表名是什么？**
3. **状态字段叫什么？可能的值是什么？**（如 NEW, APPROVED, REJECTED）
4. **是否已经有 RISK_SCORE, AUDIT_NOTES, AUDITED_AT 这些字段？**

或者直接运行：
```bash
python check_hana_structure.py
```

把输出发给我，我可以帮你生成精确的配置！

---

## 📞 下一步

1. 运行 `check_hana_structure.py` 检查数据库结构
2. 告诉我你的表结构
3. 我帮你生成具体的配置或代码修改
