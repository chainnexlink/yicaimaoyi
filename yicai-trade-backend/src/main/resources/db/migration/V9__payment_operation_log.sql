-- =====================================================
-- V9: 支付操作日志表
-- =====================================================

CREATE TABLE IF NOT EXISTS t_payment_operation_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_id BIGINT COMMENT '支付ID',
    payment_no VARCHAR(50) COMMENT '支付流水号',
    refund_id BIGINT COMMENT '退款ID',
    refund_no VARCHAR(50) COMMENT '退款单号',
    operation_type VARCHAR(30) NOT NULL COMMENT '操作类型: CREATE/CONFIRM/CANCEL/EXPIRE/REFUND_CREATE/REFUND_APPROVE/REFUND_REJECT/REFUND_PROCESS',
    from_status VARCHAR(20) COMMENT '原状态',
    to_status VARCHAR(20) COMMENT '新状态',
    operator_id BIGINT COMMENT '操作人ID',
    operator_name VARCHAR(100) COMMENT '操作人名称',
    remark TEXT COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payment_id (payment_id),
    INDEX idx_refund_id (refund_id),
    INDEX idx_operation_type (operation_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付操作日志表';
