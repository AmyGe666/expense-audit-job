-- HANA 数据库初始化脚本
-- 用于创建费用审计所需的表和测试数据

-- =============================================
-- 1. 创建 Schema
-- =============================================
CREATE SCHEMA "EXPENSE_SCHEMA";

-- =============================================
-- 2. 创建费用表
-- =============================================
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

-- =============================================
-- 3. 创建索引
-- =============================================
CREATE INDEX "IDX_EXPENSE_STATUS" ON "EXPENSE_SCHEMA"."EXPENSES"("STATUS");
CREATE INDEX "IDX_EXPENSE_DATE" ON "EXPENSE_SCHEMA"."EXPENSES"("EXPENSE_DATE");
CREATE INDEX "IDX_EMPLOYEE_ID" ON "EXPENSE_SCHEMA"."EXPENSES"("EMPLOYEE_ID");

-- =============================================
-- 4. 创建审计日志表（可选）
-- =============================================
CREATE TABLE "EXPENSE_SCHEMA"."AUDIT_LOGS" (
    "LOG_ID" INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "EXPENSE_ID" NVARCHAR(50),
    "ACTION" NVARCHAR(50),
    "OLD_STATUS" NVARCHAR(20),
    "NEW_STATUS" NVARCHAR(20),
    "RISK_SCORE" DECIMAL(5, 2),
    "NOTES" NVARCHAR(1000),
    "CREATED_AT" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. 插入测试数据
-- =============================================

-- 正常费用（应该被自动批准）
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES"
("EXPENSE_ID", "EMPLOYEE_ID", "EXPENSE_TYPE", "AMOUNT", "CURRENCY", "EXPENSE_DATE", "DESCRIPTION", "RECEIPT_URL", "STATUS")
VALUES
('EXP001', 'EMP001', 'TRAVEL', 150.00, 'USD', '2024-01-15', 'Flight to customer site', 'https://receipts.com/001.pdf', 'NEW');

-- 无发票的小额费用（应该被标记）
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES"
("EXPENSE_ID", "EMPLOYEE_ID", "EXPENSE_TYPE", "AMOUNT", "CURRENCY", "EXPENSE_DATE", "DESCRIPTION", "RECEIPT_URL", "STATUS")
VALUES
('EXP002', 'EMP002', 'MEAL', 75.50, 'USD', '2024-01-16', 'Business lunch', NULL, 'NEW');

-- 包含可疑关键词的费用（应该被审核）
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES"
("EXPENSE_ID", "EMPLOYEE_ID", "EXPENSE_TYPE", "AMOUNT", "CURRENCY", "EXPENSE_DATE", "DESCRIPTION", "RECEIPT_URL", "STATUS")
VALUES
('EXP003', 'EMP003', 'ENTERTAINMENT', 500.00, 'USD', '2024-01-17', 'Client gift', 'https://receipts.com/003.pdf', 'NEW');

-- 高金额无发票（应该被拒绝）
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES"
("EXPENSE_ID", "EMPLOYEE_ID", "EXPENSE_TYPE", "AMOUNT", "CURRENCY", "EXPENSE_DATE", "DESCRIPTION", "RECEIPT_URL", "STATUS")
VALUES
('EXP004', 'EMP004', 'OFFICE_SUPPLIES', 1500.00, 'USD', '2024-01-20', 'New laptop', NULL, 'NEW');

-- 周末办公用品采购（可疑）
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES"
("EXPENSE_ID", "EMPLOYEE_ID", "EXPENSE_TYPE", "AMOUNT", "CURRENCY", "EXPENSE_DATE", "DESCRIPTION", "RECEIPT_URL", "STATUS")
VALUES
('EXP005', 'EMP005', 'SOFTWARE', 299.00, 'USD', '2024-01-21', 'Software license', 'https://receipts.com/005.pdf', 'NEW');

-- 个人费用关键词（应该被拒绝）
INSERT INTO "EXPENSE_SCHEMA"."EXPENSES"
("EXPENSE_ID", "EMPLOYEE_ID", "EXPENSE_TYPE", "AMOUNT", "CURRENCY", "EXPENSE_DATE", "DESCRIPTION", "RECEIPT_URL", "STATUS")
VALUES
('EXP006', 'EMP006', 'OTHER', 120.00, 'USD', '2024-01-18', 'Personal items for office', 'https://receipts.com/006.pdf', 'NEW');

-- =============================================
-- 6. 创建视图（可选 - 用于报表）
-- =============================================
CREATE VIEW "EXPENSE_SCHEMA"."V_AUDIT_SUMMARY" AS
SELECT
    STATUS,
    COUNT(*) AS COUNT,
    SUM(AMOUNT) AS TOTAL_AMOUNT,
    AVG(RISK_SCORE) AS AVG_RISK_SCORE,
    MIN(AUDITED_AT) AS FIRST_AUDIT,
    MAX(AUDITED_AT) AS LAST_AUDIT
FROM "EXPENSE_SCHEMA"."EXPENSES"
WHERE AUDITED_AT IS NOT NULL
GROUP BY STATUS;

-- =============================================
-- 7. 查询脚本
-- =============================================

-- 查看所有待审计的费用
-- SELECT * FROM "EXPENSE_SCHEMA"."EXPENSES" WHERE STATUS = 'NEW';

-- 查看审计结果统计
-- SELECT * FROM "EXPENSE_SCHEMA"."V_AUDIT_SUMMARY";

-- 查看高风险费用
-- SELECT * FROM "EXPENSE_SCHEMA"."EXPENSES"
-- WHERE RISK_SCORE > 50
-- ORDER BY RISK_SCORE DESC;

-- 查看需要人工审核的费用
-- SELECT * FROM "EXPENSE_SCHEMA"."EXPENSES"
-- WHERE STATUS = 'NEEDS_REVIEW'
-- ORDER BY CREATED_AT DESC;

COMMIT;
