"""
SAP AI Core Job - Expense Audit Main Entry Point
简化版：适配 Expense Management POC
"""
import os
import logging
from datetime import datetime
from hana import HANAConnector
from audit import ExpenseAuditor

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main():
    """Job 主入口函数"""
    try:
        logger.info("=== Expense Audit Job Started (Simplified Version) ===")
        logger.info("Purpose: Demo AI Core Job execution")

        # 1. 初始化 HANA 连接
        logger.info("Connecting to SAP HANA...")
        hana = HANAConnector(
            host=os.getenv('HANA_HOST'),
            port=int(os.getenv('HANA_PORT', '443')),
            user=os.getenv('HANA_USER'),
            password=os.getenv('HANA_PASSWORD'),
            schema=os.getenv('HANA_SCHEMA', 'EXPENSE_MANAGEMENT')
        )

        # 2. 获取待审计的费用记录（状态为 Submitted）
        logger.info("Fetching expenses with status 'Submitted'...")
        submitted_expenses = hana.get_expenses_by_status('Submitted')
        logger.info(f"Found {len(submitted_expenses)} Submitted expense records")

        if not submitted_expenses:
            logger.info("No Submitted expenses to audit. Job completed.")
            return

        # 3. 初始化审计器
        auditor = ExpenseAuditor()

        # 4. 逐条审计
        success_count = 0
        failed_count = 0
        approved_count = 0
        rejected_count = 0

        for expense in submitted_expenses:
            try:
                expense_id = expense['EXPENSE_ID']
                expense_ref = expense.get('EXPENSE_REF', 'N/A')
                logger.info(f"Auditing expense: {expense_ref} (ID: {expense_id})")

                # 执行审计
                audit_result = auditor.audit(expense)

                # 更新 HANA 中的审计结果（只更新 STATUS）
                hana.update_expense_audit_result(
                    expense_id=expense_id,
                    status=audit_result['status'],
                    risk_score=audit_result['risk_score'],
                    audit_notes=audit_result['notes'],
                    audited_at=datetime.now()
                )

                success_count += 1

                if audit_result['status'] == 'Audited':
                    approved_count += 1
                else:
                    rejected_count += 1

                logger.info(
                    f"Expense {expense_ref} audited: {audit_result['status']} "
                    f"(risk: {audit_result['risk_score']:.2f})"
                )

            except Exception as e:
                failed_count += 1
                logger.error(
                    f"Failed to audit expense {expense.get('EXPENSE_REF', 'unknown')}: {str(e)}"
                )

        # 5. 汇总结果
        logger.info("=== Audit Summary ===")
        logger.info(f"Total processed: {len(submitted_expenses)}")
        logger.info(f"Success: {success_count}")
        logger.info(f"  - Audited (approved): {approved_count}")
        logger.info(f"  - Rejected: {rejected_count}")
        logger.info(f"Failed: {failed_count}")
        logger.info("=== Expense Audit Job Completed ===")

    except Exception as e:
        logger.error(f"Job failed with error: {str(e)}", exc_info=True)
        raise

    finally:
        # 关闭数据库连接
        if 'hana' in locals():
            hana.close()


if __name__ == "__main__":
    main()
