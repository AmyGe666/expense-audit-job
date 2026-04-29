"""
本地测试脚本 - 不连接真实 HANA 数据库
使用 Mock 数据进行测试
"""
import sys
import logging
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Mock 数据
MOCK_EXPENSES = [
    {
        'EXPENSE_ID': 'EXP001',
        'EMPLOYEE_ID': 'EMP001',
        'EXPENSE_TYPE': 'TRAVEL',
        'AMOUNT': 150.00,
        'CURRENCY': 'USD',
        'EXPENSE_DATE': datetime(2024, 1, 15),
        'DESCRIPTION': 'Flight to customer site',
        'RECEIPT_URL': 'https://receipts.com/001.pdf',
        'STATUS': 'NEW'
    },
    {
        'EXPENSE_ID': 'EXP002',
        'EMPLOYEE_ID': 'EMP002',
        'EXPENSE_TYPE': 'MEAL',
        'AMOUNT': 75.50,
        'CURRENCY': 'USD',
        'EXPENSE_DATE': datetime(2024, 1, 16),
        'DESCRIPTION': 'Business lunch',
        'RECEIPT_URL': None,  # 无发票
        'STATUS': 'NEW'
    },
    {
        'EXPENSE_ID': 'EXP003',
        'EMPLOYEE_ID': 'EMP003',
        'EXPENSE_TYPE': 'ENTERTAINMENT',
        'AMOUNT': 500.00,
        'CURRENCY': 'USD',
        'EXPENSE_DATE': datetime(2024, 1, 17),
        'DESCRIPTION': 'Client gift',  # 包含可疑关键词
        'RECEIPT_URL': 'https://receipts.com/003.pdf',
        'STATUS': 'NEW'
    },
    {
        'EXPENSE_ID': 'EXP004',
        'EMPLOYEE_ID': 'EMP004',
        'EXPENSE_TYPE': 'OFFICE_SUPPLIES',
        'AMOUNT': 1500.00,  # 高金额
        'CURRENCY': 'USD',
        'EXPENSE_DATE': datetime(2024, 1, 20),  # 假设是周六
        'DESCRIPTION': 'New laptop',
        'RECEIPT_URL': None,  # 高金额无发票
        'STATUS': 'NEW'
    }
]


def test_audit_logic():
    """测试审计逻辑"""
    from audit import ExpenseAuditor

    logger.info("=== 测试审计逻辑 ===")
    auditor = ExpenseAuditor()

    for expense in MOCK_EXPENSES:
        logger.info(f"\n测试费用: {expense['EXPENSE_ID']}")
        logger.info(f"  金额: {expense['AMOUNT']} {expense['CURRENCY']}")
        logger.info(f"  类型: {expense['EXPENSE_TYPE']}")
        logger.info(f"  描述: {expense['DESCRIPTION']}")
        logger.info(f"  发票: {'有' if expense['RECEIPT_URL'] else '无'}")

        result = auditor.audit(expense)

        logger.info(f"  --- 审计结果 ---")
        logger.info(f"  状态: {result['status']}")
        logger.info(f"  风险评分: {result['risk_score']}")
        logger.info(f"  备注: {result['notes']}")


def main():
    """测试主函数"""
    logger.info("=== 开始本地测试 ===")

    try:
        test_audit_logic()
        logger.info("\n=== 测试完成 ===")

    except Exception as e:
        logger.error(f"测试失败: {str(e)}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
