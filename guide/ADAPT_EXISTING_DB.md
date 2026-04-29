# 🎯 你的现有数据库结构适配方案

## 📊 你的 CDS Schema 分析

根据你的 `schema.cds` 文件，我看到：

### 核心实体
- **Namespace**: `expense.management`
- **主表**: `ExpenseHeader` (费用报销单头)
- **明细表**: `ExpenseItem` (费用明细)
- **审计信号**: `HeuristicSignalResult`

### ExpenseHeader 结构
```javascript
entity ExpenseHeader : cuid, managed {
    expenseID    : String(50)        // 费用单号
    employee     : Association       // 员工
    expenseType  : String(50)        // 费用类型
    totalAmount  : Decimal(15, 2)    // 总金额
    currency     : String(3)         // 币种 (默认 CNY)
    status       : String(20)        // 状态
    submitDate   : Date              // 提交日期
    approvedDate : Date              // 批准日期
    approvedBy   : String(100)       // 批准人
}
```

### 状态枚举
```
Draft     = 'Draft'      (草稿)
Submitted = 'Submitted'  (已提交)
Approved  = 'Approved'   (已批准)
Rejected  = 'Rejected'   (已拒绝)
Audited   = 'Audited'    (已审计)
```

---

## ✅ 适配方案

### 方案选择

由于你的表结构与 AI Core Job 期望的不太一样，我推荐：

**✅ 方案 1：创建视图映射（最简单，无需改代码）**

在 HANA 中创建一个视图，把你的 CDS 实体映射到 Job 期望的结构。

---

## 📝 实施步骤

### 步骤 1：确认 HANA 中的实际表名

CDS 编译后，HANA 中的表名会是：

```
Namespace.Entity
↓
EXPENSE_MANAGEMENT_EXPENSEHEADER
EXPENSE_MANAGEMENT_EXPENSEITEM
EXPENSE_MANAGEMENT_EMPLOYEE
```

### 步骤 2：在 HANA 中创建映射视图

在 HANA Database Explorer 的 SQL Console 中执行：

```sql
-- 创建用于审计的视图
-- 映射你的 ExpenseHeader 到 Job 期望的 EXPENSES 结构

CREATE VIEW "EXPENSE_MANAGEMENT"."EXPENSES" AS
SELECT
    -- 主键和标识
    ID as EXPENSE_ID,                    -- cuid 生成的 ID
    EXPENSEID as EXPENSE_REF,            -- 你的费用单号

    -- 员工信息
    EMPLOYEE_ID as EMPLOYEE_ID,          -- 员工 ID (Association)

    -- 费用信息
    EXPENSETYPE as EXPENSE_TYPE,         -- 费用类型
    TOTALAMOUNT as AMOUNT,               -- 总金额
    CURRENCY as CURRENCY,                -- 币种
    SUBMITDATE as EXPENSE_DATE,          -- 费用日期

    -- 描述（如果有的话，可以从明细聚合）
    CAST(NULL AS NVARCHAR(500)) as DESCRIPTION,  -- 暂时设为空
    CAST(NULL AS NVARCHAR(500)) as RECEIPT_URL,  -- 暂时设为空

    -- 状态信息
    STATUS as STATUS,                    -- 状态字段

    -- 审计字段（需要添加到原表）
    CAST(NULL AS DECIMAL(5, 2)) as RISK_SCORE,
    CAST(NULL AS NVARCHAR(1000)) as AUDIT_NOTES,
    CAST(NULL AS TIMESTAMP) as AUDITED_AT,

    -- 时间戳
    CREATEDAT as CREATED_AT,
    MODIFIEDAT as UPDATED_AT

FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
WHERE STATUS = 'Submitted';  -- 只审计已提交的费用
```

### 步骤 3：添加审计字段到原表

在你的 CDS schema 中添加审计字段：

```javascript
// 在 ExpenseHeader 实体中添加
entity ExpenseHeader : cuid, managed {
    // ... 现有字段 ...

    // 添加审计相关字段
    riskScore    : Decimal(5, 2) @title: 'Risk Score';
    auditNotes   : String(1000) @title: 'Audit Notes';
    auditedAt    : DateTime @title: 'Audited At';
    auditedBy    : String(100) @title: 'Audited By';
}
```

然后重新部署你的 CAP 应用，CDS 会自动添加这些字段到 HANA 表。

### 步骤 4：更新视图（如果添加了字段）

如果你添加了审计字段，更新视图：

```sql
-- 删除旧视图
DROP VIEW "EXPENSE_MANAGEMENT"."EXPENSES";

-- 重新创建视图
CREATE VIEW "EXPENSE_MANAGEMENT"."EXPENSES" AS
SELECT
    ID as EXPENSE_ID,
    EXPENSEID as EXPENSE_REF,
    EMPLOYEE_ID as EMPLOYEE_ID,
    EXPENSETYPE as EXPENSE_TYPE,
    TOTALAMOUNT as AMOUNT,
    CURRENCY as CURRENCY,
    SUBMITDATE as EXPENSE_DATE,
    CAST(NULL AS NVARCHAR(500)) as DESCRIPTION,
    CAST(NULL AS NVARCHAR(500)) as RECEIPT_URL,
    STATUS as STATUS,
    RISKSCORE as RISK_SCORE,      -- 新字段
    AUDITNOTES as AUDIT_NOTES,    -- 新字段
    AUDITEDAT as AUDITED_AT,      -- 新字段
    CREATEDAT as CREATED_AT,
    MODIFIEDAT as UPDATED_AT
FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
WHERE STATUS = 'Submitted';
```

### 步骤 5：配置 AI Core Job

运行 `create-hana-secret.sh` 时：

```bash
./create-hana-secret.sh

# 输入：
Resource Group: default
HANA 用户名: <your_user>
HANA 密码: <your_password>
HANA Schema: EXPENSE_MANAGEMENT  # ← 你的 Schema
```

### 步骤 6：调整状态映射

由于你的状态是 `Submitted` 而不是 `NEW`，需要修改代码：

编辑 `app/main.py`，把状态从 `NEW` 改为 `Submitted`：

```python
# 原代码（第 24 行左右）
new_expenses = hana.get_expenses_by_status('NEW')

# 改为
new_expenses = hana.get_expenses_by_status('Submitted')
```

---

## 🎯 完整的 SQL 脚本

将以下脚本保存为 `adapt_existing_db.sql` 并在 HANA 中执行：

```sql
-- =============================================
-- 适配现有 Expense Management 数据库
-- =============================================

-- 1. 添加审计字段到 ExpenseHeader 表（如果还没有的话）
-- 注意：CDS 编译后的表名可能是 EXPENSE_MANAGEMENT_EXPENSEHEADER
ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("RISKSCORE" DECIMAL(5, 2));

ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("AUDITNOTES" NVARCHAR(1000));

ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("AUDITEDAT" TIMESTAMP);

ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("AUDITEDBY" NVARCHAR(100));

-- 2. 创建映射视图
CREATE OR REPLACE VIEW "EXPENSE_MANAGEMENT"."EXPENSES" AS
SELECT
    ID as EXPENSE_ID,
    EXPENSEID as EXPENSE_REF,
    EMPLOYEE_ID as EMPLOYEE_ID,
    EXPENSETYPE as EXPENSE_TYPE,
    TOTALAMOUNT as AMOUNT,
    CURRENCY as CURRENCY,
    SUBMITDATE as EXPENSE_DATE,
    CAST(NULL AS NVARCHAR(500)) as DESCRIPTION,
    CAST(NULL AS NVARCHAR(500)) as RECEIPT_URL,
    STATUS as STATUS,
    RISKSCORE as RISK_SCORE,
    AUDITNOTES as AUDIT_NOTES,
    AUDITEDAT as AUDITED_AT,
    CREATEDAT as CREATED_AT,
    MODIFIEDAT as UPDATED_AT
FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
WHERE STATUS IN ('Submitted', 'Approved', 'Rejected');

-- 3. 创建索引以提高查询性能
CREATE INDEX "IDX_EXPENSEHEADER_STATUS"
ON "EXPENSE_MANAGEMENT_EXPENSEHEADER"("STATUS");

-- 4. 验证视图
SELECT COUNT(*) as TOTAL_EXPENSES,
       SUM(CASE WHEN STATUS = 'Submitted' THEN 1 ELSE 0 END) as SUBMITTED_COUNT
FROM "EXPENSE_MANAGEMENT"."EXPENSES";

-- 5. 查看示例数据
SELECT * FROM "EXPENSE_MANAGEMENT"."EXPENSES" LIMIT 5;
```

---

## 🔄 工作流程

```
┌─────────────────────────────────────┐
│ 你的 CAP 应用                        │
│ ├─ ExpenseHeader (原始表)           │
│ │  ├─ Status: Submitted            │
│ │  └─ 等待审计...                  │
│ └─ CDS 定义                         │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ HANA Cloud                           │
│ ├─ EXPENSE_MANAGEMENT_EXPENSEHEADER │
│ │  (原始表，添加审计字段)           │
│ │                                   │
│ └─ EXPENSE_MANAGEMENT.EXPENSES      │
│    (视图：映射到 Job 期望的格式)   │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ AI Core Job                          │
│ ├─ 读取: Status = 'Submitted'      │
│ ├─ 审计: 计算 riskScore            │
│ └─ 更新: Status, riskScore, etc.   │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ 审计结果                             │
│ ├─ Status: Audited / Rejected       │
│ ├─ riskScore: 0-100                 │
│ └─ auditNotes: 审计备注              │
└─────────────────────────────────────┘
```

---

## 📋 部署清单

- [ ] 1. 在 HANA 中执行 `adapt_existing_db.sql`
- [ ] 2. 验证视图创建成功
- [ ] 3. （可选）在 CDS schema 中添加审计字段
- [ ] 4. 修改 `app/main.py` 中的状态为 `Submitted`
- [ ] 5. 运行 `create-hana-secret.sh`（Schema: EXPENSE_MANAGEMENT）
- [ ] 6. 运行 `deploy.sh`
- [ ] 7. 运行 `aicore-cli.sh` 部署 Job
- [ ] 8. 测试审计功能

---

## 🎉 总结

### Schema 名称
✅ `EXPENSE_MANAGEMENT`

### 表名（通过视图映射）
✅ `EXPENSES` (视图)

### 关键字段
- **状态字段**: `STATUS`
- **状态值**: `Submitted` (待审计), `Audited` (已审计), `Rejected` (拒绝)
- **金额字段**: `AMOUNT`
- **审计字段**: `RISK_SCORE`, `AUDIT_NOTES`, `AUDITED_AT`

### 需要修改的代码
✅ `app/main.py` 第 24 行：`'NEW'` → `'Submitted'`

就这样！你的现有数据库完全可以用了！🎉
