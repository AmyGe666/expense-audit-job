-- =============================================
-- 适配现有 Expense Management 数据库
-- 为 AI Core Audit Job 准备数据结构
-- =============================================

-- 注意：执行前请确认实际的表名
-- CDS 编译后的表名通常是：NAMESPACE_ENTITY
-- 例如：EXPENSE_MANAGEMENT_EXPENSEHEADER

-- =============================================
-- 步骤 1：添加审计字段到 ExpenseHeader 表
-- =============================================

-- 添加风险评分字段
ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("RISKSCORE" DECIMAL(5, 2));

-- 添加审计备注字段
ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("AUDITNOTES" NVARCHAR(1000));

-- 添加审计时间字段
ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("AUDITEDAT" TIMESTAMP);

-- 添加审计人字段（可选）
ALTER TABLE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
ADD ("AUDITEDBY" NVARCHAR(100));

-- =============================================
-- 步骤 2：创建映射视图
-- 将 ExpenseHeader 映射到 Job 期望的 EXPENSES 结构
-- =============================================

CREATE OR REPLACE VIEW "EXPENSE_MANAGEMENT"."EXPENSES" AS
SELECT
    -- 主键和标识
    ID as EXPENSE_ID,                           -- cuid 生成的 UUID
    EXPENSEID as EXPENSE_REF,                   -- 你的费用单号

    -- 员工信息
    EMPLOYEE_ID as EMPLOYEE_ID,                 -- 员工 ID

    -- 费用信息
    EXPENSETYPE as EXPENSE_TYPE,                -- 费用类型
    TOTALAMOUNT as AMOUNT,                      -- 总金额
    CURRENCY as CURRENCY,                       -- 币种
    SUBMITDATE as EXPENSE_DATE,                 -- 费用日期

    -- 描述和发票（暂时设为空，可以后续从明细表聚合）
    CAST(NULL AS NVARCHAR(500)) as DESCRIPTION, -- 描述
    CAST(NULL AS NVARCHAR(500)) as RECEIPT_URL, -- 发票 URL

    -- 状态信息
    STATUS as STATUS,                           -- 状态字段

    -- 审计字段
    RISKSCORE as RISK_SCORE,                    -- 风险评分
    AUDITNOTES as AUDIT_NOTES,                  -- 审计备注
    AUDITEDAT as AUDITED_AT,                    -- 审计时间

    -- 时间戳
    CREATEDAT as CREATED_AT,                    -- 创建时间
    MODIFIEDAT as UPDATED_AT                    -- 更新时间

FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
WHERE STATUS IN ('Submitted', 'Approved', 'Rejected', 'Audited');

-- =============================================
-- 步骤 3：创建索引以提高查询性能
-- =============================================

-- 状态字段索引（用于快速筛选待审计记录）
CREATE INDEX "IDX_EXPENSEHEADER_STATUS"
ON "EXPENSE_MANAGEMENT_EXPENSEHEADER"("STATUS");

-- 审计时间索引（可选，用于查询已审计记录）
CREATE INDEX "IDX_EXPENSEHEADER_AUDITEDAT"
ON "EXPENSE_MANAGEMENT_EXPENSEHEADER"("AUDITEDAT");

-- =============================================
-- 步骤 4：验证配置
-- =============================================

-- 查看统计信息
SELECT
    STATUS,
    COUNT(*) as COUNT,
    SUM(TOTALAMOUNT) as TOTAL_AMOUNT
FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
GROUP BY STATUS
ORDER BY STATUS;

-- 查看视图中的数据
SELECT
    COUNT(*) as TOTAL_IN_VIEW,
    SUM(CASE WHEN STATUS = 'Submitted' THEN 1 ELSE 0 END) as SUBMITTED_COUNT
FROM "EXPENSE_MANAGEMENT"."EXPENSES";

-- 查看示例数据
SELECT
    EXPENSE_ID,
    EXPENSE_TYPE,
    AMOUNT,
    CURRENCY,
    STATUS,
    EXPENSE_DATE
FROM "EXPENSE_MANAGEMENT"."EXPENSES"
WHERE STATUS = 'Submitted'
LIMIT 5;

-- =============================================
-- 步骤 5：测试更新（可选）
-- =============================================

-- 测试更新审计字段（不要在生产环境执行）
/*
UPDATE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
SET
    RISKSCORE = 25.5,
    AUDITNOTES = 'Test audit note',
    AUDITEDAT = CURRENT_TIMESTAMP
WHERE ID = '<some_test_id>';
*/

-- 验证更新是否反映在视图中
/*
SELECT * FROM "EXPENSE_MANAGEMENT"."EXPENSES"
WHERE EXPENSE_ID = '<some_test_id>';
*/

-- =============================================
-- 完成提示
-- =============================================

-- 如果上述所有步骤执行成功，你应该看到：
-- 1. ✅ ExpenseHeader 表已添加审计字段
-- 2. ✅ EXPENSES 视图已创建
-- 3. ✅ 索引已创建
-- 4. ✅ 可以查询到待审计的数据

-- 下一步：
-- 1. 运行 create-hana-secret.sh (Schema: EXPENSE_MANAGEMENT)
-- 2. 修改 app/main.py 中的状态 'NEW' -> 'Submitted'
-- 3. 部署 AI Core Job

COMMIT;
