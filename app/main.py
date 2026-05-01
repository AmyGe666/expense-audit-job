"""
SAP AI Core Job - Expense Audit Main Entry Point
"""
import os
import logging
from datetime import datetime
from hana import HanaClient
from audit import ExpenseAuditor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main():
    """Job main entry point"""
    try:
        logger.info("=== Expense Audit Job Started ===")

        # 1. Initialize HANA connection (no schema parameter needed!)
        logger.info("Connecting to SAP HANA...")
        hana = HanaClient(
            host=os.environ["HANA_HOST"],
            port=int(os.environ.get("HANA_PORT", "443")),
            user=os.environ["HANA_USER"],
            password=os.environ["HANA_PASSWORD"],
        )

        # 2. Fetch expenses with status 'Submitted'
        logger.info("Fetching expenses with status 'Submitted'...")
        submitted_expenses = hana.get_expenses_by_status('Submitted')
        logger.info(f"Found {len(submitted_expenses)} Submitted expense records")

        if not submitted_expenses:
            logger.info("No Submitted expenses to audit. Job completed.")
            return

        # 3. Initialize auditor
        auditor = ExpenseAuditor()

        # 4. Audit each expense
        success_count = 0
        failed_count = 0
        approved_count = 0
        rejected_count = 0

        for expense in submitted_expenses:
            try:
                expense_id = expense['EXPENSE_ID']
                business_id = expense.get('BUSINESS_EXPENSE_ID', 'N/A')
                logger.info(f"Auditing expense: {business_id} (ID: {expense_id})")

                # Perform audit
                audit_result = auditor.audit(expense)

                # Update HANA with audit result
                hana.update_expense_status(
                    expense_id=expense_id,
                    new_status=audit_result['status']
                )

                success_count += 1

                if audit_result['status'] == 'Audited':
                    approved_count += 1
                else:
                    rejected_count += 1

                logger.info(
                    f"Expense {business_id} audited: {audit_result['status']} "
                    f"(risk: {audit_result['risk_score']:.2f})"
                )

            except Exception as e:
                failed_count += 1
                logger.error(
                    f"Failed to audit expense {expense.get('BUSINESS_EXPENSE_ID', 'unknown')}: {str(e)}"
                )

        # 5. Summary
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
        # Close database connection
        if 'hana' in locals():
            hana.close()


if __name__ == "__main__":
    main()
