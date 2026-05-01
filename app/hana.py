"""
SAP HANA client for AI Core Job.
Designed for HANA Cloud with HDI technical user.
"""
import logging
from typing import List, Dict, Any, Optional

from hdbcli import dbapi

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


class HanaClient:
    """
    SAP HANA client for AI Core Job.
    Designed for HANA Cloud with HDI technical user.
    """

    def __init__(self, host: str, port: int, user: str, password: str):
        """
        Initialize HANA connection.

        Args:
            host: HANA host (e.g. *.hanacloud.ondemand.com)
            port: HANA port (usually 443)
            user: HANA technical user (HDI)
            password: Password
        """
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.connection: Optional[dbapi.Connection] = None

        self._connect()

    # ---------------------------------------------------------------------
    # Connection handling
    # ---------------------------------------------------------------------

    def _connect(self) -> None:
        """Establish HANA connection."""
        try:
            self.connection = dbapi.connect(
                address=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                encrypt=True,
                sslValidateCertificate=False,
            )

            logger.info("Successfully connected to SAP HANA")

            # Debug aid: log current schema (HDI)
            with self.connection.cursor() as cursor:
                cursor.execute("SELECT CURRENT_SCHEMA FROM DUMMY")
                current_schema = cursor.fetchone()[0]
                logger.info(f"Current HANA schema: {current_schema}")

        except Exception as exc:
            logger.exception("Failed to connect to SAP HANA")
            raise RuntimeError("HANA connection failed") from exc

    def close(self) -> None:
        """Close HANA connection."""
        if self.connection:
            try:
                self.connection.close()
                logger.info("HANA connection closed")
            except Exception:
                logger.warning("Error while closing HANA connection")

    # ---------------------------------------------------------------------
    # Query helpers
    # ---------------------------------------------------------------------

    def get_expenses_by_status(self, status: str) -> List[Dict[str, Any]]:
        """
        Fetch expenses from EXPENSE_MANAGEMENT_EXPENSEHEADER by status.

        Args:
            status: Expense status (e.g. 'Submitted')

        Returns:
            List of expense records as dicts
        """
        query = """
            SELECT
                ID          AS EXPENSE_ID,
                EXPENSEID   AS BUSINESS_EXPENSE_ID,
                TOTALAMOUNT,
                CURRENCY,
                SUBMITDATE  AS EXPENSE_DATE,
                STATUS,
                CREATEDAT  AS CREATED_AT
            FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
            WHERE STATUS = ?
            ORDER BY CREATEDAT ASC
        """

        logger.info(f"Querying expenses with status='{status}'")

        try:
            with self.connection.cursor() as cursor:
                cursor.execute(query, (status,))
                rows = cursor.fetchall()

                columns = [col[0] for col in cursor.description]
                result = [dict(zip(columns, row)) for row in rows]

                logger.info(f"Fetched {len(result)} expense(s)")
                return result

        except Exception as exc:
            logger.exception("Failed to query expenses")
            raise RuntimeError("Expense query failed") from exc

    def update_expense_status(
        self,
        expense_id: str,
        new_status: str
    ) -> None:
        """
        Update expense status.

        Args:
            expense_id: Expense ID (UUID)
            new_status: New status (e.g. 'Audited', 'Rejected')
        """
        query = """
            UPDATE "EXPENSE_MANAGEMENT_EXPENSEHEADER"
            SET
                STATUS = ?,
                MODIFIEDAT = CURRENT_UTCTIMESTAMP
            WHERE ID = ?
        """

        try:
            with self.connection.cursor() as cursor:
                cursor.execute(query, (new_status, expense_id))
                self.connection.commit()

            logger.info(f"Updated expense {expense_id}: status={new_status}")

        except Exception as exc:
            if self.connection:
                self.connection.rollback()
            logger.exception("Failed to update expense status")
            raise RuntimeError("Update expense failed") from exc

    # ---------------------------------------------------------------------
    # Example: insert/update results
    # ---------------------------------------------------------------------

    def insert_signal_result(self, data: Dict[str, Any]) -> None:
        """
        Example method to insert a heuristic signal result.

        Args:
            data: Dict containing signal result fields
        """
        query = """
            INSERT INTO "EXPENSE_MANAGEMENT_HEURISTICSIGNALRESULT"
            (
                ID,
                SIGNALCODE,
                SIGNALLEVEL,
                DETECTEDVALUE,
                EXPLANATION,
                DETECTEDAT
            )
            VALUES (?, ?, ?, ?, ?, CURRENT_UTCTIMESTAMP)
        """

        try:
            with self.connection.cursor() as cursor:
                cursor.execute(
                    query,
                    (
                        data["id"],
                        data["signal_code"],
                        data["signal_level"],
                        data.get("detected_value"),
                        data.get("explanation"),
                    ),
                )
                self.connection.commit()

            logger.info("Heuristic signal result inserted")

        except Exception as exc:
            if self.connection:
                self.connection.rollback()
            logger.exception("Failed to insert signal result")
            raise RuntimeError("Insert signal result failed") from exc
