"""
Expense Audit Logic - 简化版
只进行基本的规则检查，不需要完整的字段
"""
import logging
from typing import Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)


class ExpenseAuditor:
    """费用审计器 - 简化版"""

    # 审计规则配置
    HIGH_RISK_THRESHOLD = 1000.0  # 高风险金额阈值（人民币）

    def __init__(self):
        """初始化审计器"""
        logger.info("ExpenseAuditor initialized (simplified version)")

    def audit(self, expense: Dict[str, Any]) -> Dict[str, Any]:
        """
        执行费用审计 - 简化版
        只检查金额，不检查发票、关键词等

        Args:
            expense: 费用记录字典

        Returns:
            审计结果字典，包含：
            - status: 'Audited' 或 'Rejected'
            - risk_score: 风险评分（0-100）
            - notes: 审计备注
        """
        risk_score = 0.0
        notes = []

        # 获取金额和币种
        amount = float(expense.get('AMOUNT', 0))
        currency = expense.get('CURRENCY', 'CNY')

        logger.info(f"Auditing expense {expense.get('EXPENSE_ID')}: {amount} {currency}")

        # 规则 1: 检查金额（高金额风险）
        if amount > self.HIGH_RISK_THRESHOLD:
            risk_score += 40
            notes.append(f"High amount: {amount} {currency}")
            logger.info(f"  → High amount detected")

        # 规则 2: 检查币种（非人民币略微风险）
        if currency != 'CNY':
            risk_score += 10
            notes.append(f"Non-CNY currency: {currency}")
            logger.info(f"  → Non-CNY currency")

        # 规则 3: 检查费用类型（某些类型需要特别注意）
        expense_type = expense.get('EXPENSE_TYPE', '')
        high_risk_types = ['entertainment', 'gift', 'other']

        if any(risk_type in expense_type.lower() for risk_type in high_risk_types):
            risk_score += 30
            notes.append(f"High-risk expense type: {expense_type}")
            logger.info(f"  → High-risk type")

        # 规则 4: 检查费用日期（未来日期）
        expense_date = expense.get('EXPENSE_DATE')
        if expense_date:
            if isinstance(expense_date, str):
                try:
                    expense_date = datetime.strptime(expense_date, '%Y-%m-%d')
                except:
                    pass

            if isinstance(expense_date, datetime) and expense_date > datetime.now():
                risk_score += 50
                notes.append("Future expense date")
                logger.info(f"  → Future date detected")

        # 确保风险评分在 0-100 之间
        risk_score = min(risk_score, 100.0)

        # 根据风险评分决定状态
        if risk_score >= 70:
            status = 'Rejected'
        else:
            status = 'Audited'

        audit_result = {
            'status': status,
            'risk_score': risk_score,
            'notes': '; '.join(notes) if notes else 'Auto-approved - low risk'
        }

        logger.info(
            f"Audit result for {expense.get('EXPENSE_ID')}: "
            f"status={status}, risk_score={risk_score:.2f}"
        )

        return audit_result
