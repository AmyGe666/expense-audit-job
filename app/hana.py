"""
SAP HANA Database Connector - 适配 Expense Management POC
只读取数据，不写入审计结果
"""
import logging
from typing import List, Dict, Any
from datetime import datetime
from hdbcli import dbapi

logger = logging.getLogger(__name__)


class HANAConnector:
    """SAP HANA 数据库连接器 - 适配版"""

    def __init__(self, host: str, port: int, user: str, password: str, schema: str):
        """
        初始化 HANA 连接

        Args:
            host: HANA 主机地址
            port: 端口号（通常为 443）
            user: 用户名
            password: 密码
            schema: Schema 名称 (EXPENSE_MANAGEMENT)
        """
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.schema = schema
        self.connection = None
        self._connect()

    def _connect(self):
        """建立数据库连接"""
        try:
            self.connection = dbapi.connect(
                address=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                encrypt=True,
                sslValidateCertificate=False
            )
            logger.info(f"Successfully connected to HANA at {self.host}")
        except Exception as e:
            logger.error(f"Failed to connect to HANA: {str(e)}")
            raise

    def get_expenses_by_status(self, status: str) -> List[Dict[str, Any]]:
        """
        根据状态获取费用记录
        从 EXPENSE_MANAGEMENT_EXPENSEHEADER 表读取

        Args:
            status: 费用状态（'Submitted' - 待审计）

        Returns:
            费用记录列表
        """
        cursor = self.connection.cursor()

        try:
            # 从 ExpenseHeader 表读取
            # 表名：EXPENSE_MANAGEMENT_EXPENSEHEADER
            query = f"""
                SELECT
                    ID as EXPENSE_ID,
                    EXPENSEID as EXPENSE_REF,
                    EMPLOYEE_ID,
                    EXPENSETYPE as EXPENSE_TYPE,
                    TOTALAMOUNT as AMOUNT,
                    CURRENCY,
                    SUBMITDATE as EXPENSE_DATE,
                    STATUS,
                    CREATEDAT as CREATED_AT
                FROM "{self.schema}_EXPENSEHEADER"
                WHERE STATUS = ?
                ORDER BY CREATEDAT ASC
                LIMIT 100
            """

            logger.info(f"Querying expenses with status: {status}")
            cursor.execute(query, (status,))

            # 获取列名
            columns = [desc[0] for desc in cursor.description]

            # 转换为字典列表
            results = []
            for row in cursor.fetchall():
                expense = dict(zip(columns, row))
                # 添加模拟字段（审计逻辑需要）
                expense['DESCRIPTION'] = f"Expense {expense['EXPENSE_REF']}"
                expense['RECEIPT_URL'] = None  # 模拟无发票
                results.append(expense)

            logger.info(f"Found {len(results)} expenses with status {status}")
            return results

        except Exception as e:
            logger.error(f"Failed to query expenses: {str(e)}")
            raise

        finally:
            cursor.close()

    def update_expense_audit_result(
        self,
        expense_id: str,
        status: str,
        risk_score: float,
        audit_notes: str,
        audited_at: datetime
    ):
        """
        更新费用审计结果 - 简化版
        只更新 STATUS 字段

        Args:
            expense_id: 费用 ID (UUID)
            status: 审计后的状态（'Audited' 或 'Rejected'）
            risk_score: 风险评分（0-100）
            audit_notes: 审计备注
            audited_at: 审计时间
        """
        cursor = self.connection.cursor()

        try:
            # 简化版：只更新状态
            # 如果风险评分 >= 70，状态改为 Rejected
            # 否则改为 Audited
            new_status = 'Rejected' if risk_score >= 70 else 'Audited'

            update_query = f"""
                UPDATE "{self.schema}_EXPENSEHEADER"
                SET
                    STATUS = ?,
                    MODIFIEDAT = CURRENT_TIMESTAMP
                WHERE ID = ?
            """

            cursor.execute(update_query, (new_status, expense_id))
            self.connection.commit()

            logger.info(
                f"Updated expense {expense_id}: "
                f"status={new_status}, risk_score={risk_score:.2f}"
            )

        except Exception as e:
            self.connection.rollback()
            logger.error(f"Failed to update expense {expense_id}: {str(e)}")
            raise

        finally:
            cursor.close()

    def close(self):
        """关闭数据库连接"""
        if self.connection:
            self.connection.close()
            logger.info("HANA connection closed")
