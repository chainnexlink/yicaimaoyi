-- =====================================================
-- 易采贸易平台数据库迁移脚本
-- Version: V7
-- Description: 创建支付相关表
-- =====================================================

-- 支付流水表
CREATE TABLE IF NOT EXISTS t_payment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_no VARCHAR(50) NOT NULL UNIQUE COMMENT '支付流水号',
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    order_no VARCHAR(50) COMMENT '关联订单号',
    payer_id BIGINT NOT NULL COMMENT '付款方用户ID',
    payer_name VARCHAR(100) COMMENT '付款方名称',
    payee_id BIGINT NOT NULL COMMENT '收款方用户ID',
    payee_name VARCHAR(100) COMMENT '收款方名称',
    amount DECIMAL(12,2) NOT NULL COMMENT '支付金额',
    payment_method VARCHAR(50) NOT NULL COMMENT '支付方式: BANK_TRANSFER/ALIPAY/WECHAT/CREDIT',
    payment_channel VARCHAR(50) COMMENT '支付渠道',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '支付状态: PENDING/PROCESSING/SUCCESS/FAILED/CANCELLED',
    transaction_id VARCHAR(100) COMMENT '第三方交易号',
    bank_account VARCHAR(50) COMMENT '银行账号(后四位)',
    bank_name VARCHAR(100) COMMENT '银行名称',
    remark TEXT COMMENT '备注',
    paid_at DATETIME COMMENT '支付成功时间',
    expired_at DATETIME COMMENT '支付过期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_payment_no (payment_no),
    INDEX idx_order_id (order_id),
    INDEX idx_payer_id (payer_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付流水表';

-- 退款记录表
CREATE TABLE IF NOT EXISTS t_refund (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    refund_no VARCHAR(50) NOT NULL UNIQUE COMMENT '退款单号',
    payment_id BIGINT NOT NULL COMMENT '关联支付ID',
    payment_no VARCHAR(50) COMMENT '关联支付流水号',
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    order_no VARCHAR(50) COMMENT '关联订单号',
    applicant_id BIGINT NOT NULL COMMENT '申请人ID',
    applicant_name VARCHAR(100) COMMENT '申请人名称',
    refund_amount DECIMAL(12,2) NOT NULL COMMENT '退款金额',
    refund_reason VARCHAR(500) NOT NULL COMMENT '退款原因',
    refund_type VARCHAR(20) DEFAULT 'FULL' COMMENT '退款类型: FULL/PARTIAL',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '退款状态: PENDING/APPROVED/REJECTED/PROCESSING/SUCCESS/FAILED',
    auditor_id BIGINT COMMENT '审核人ID',
    auditor_name VARCHAR(100) COMMENT '审核人名称',
    audit_remark TEXT COMMENT '审核备注',
    audited_at DATETIME COMMENT '审核时间',
    transaction_id VARCHAR(100) COMMENT '退款交易号',
    refunded_at DATETIME COMMENT '退款成功时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_refund_no (refund_no),
    INDEX idx_payment_id (payment_id),
    INDEX idx_order_id (order_id),
    INDEX idx_applicant_id (applicant_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='退款记录表';

-- 物流轨迹表
CREATE TABLE IF NOT EXISTS t_logistics_track (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    logistics_id BIGINT NOT NULL COMMENT '物流ID',
    tracking_no VARCHAR(50) COMMENT '物流单号',
    node_time DATETIME NOT NULL COMMENT '节点时间',
    location VARCHAR(200) COMMENT '节点位置',
    status VARCHAR(50) COMMENT '节点状态',
    description VARCHAR(500) COMMENT '节点描述',
    operator VARCHAR(100) COMMENT '操作人',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_logistics_id (logistics_id),
    INDEX idx_tracking_no (tracking_no),
    INDEX idx_node_time (node_time),
    CONSTRAINT fk_track_logistics FOREIGN KEY (logistics_id) REFERENCES t_logistics(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物流轨迹表';

-- 积分流水表
CREATE TABLE IF NOT EXISTS t_points_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    membership_id BIGINT COMMENT '会员ID',
    change_type VARCHAR(20) NOT NULL COMMENT '变动类型: EARN/SPEND/EXPIRE/ADJUST',
    change_amount INT NOT NULL COMMENT '变动积分(正为增加/负为减少)',
    balance_before INT COMMENT '变动前余额',
    balance_after INT COMMENT '变动后余额',
    source_type VARCHAR(50) COMMENT '来源类型: ORDER/SIGN_IN/ACTIVITY/EXCHANGE/ADMIN',
    source_id BIGINT COMMENT '来源ID',
    description VARCHAR(500) COMMENT '描述',
    operator_id BIGINT COMMENT '操作人ID(管理员调整时)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_membership_id (membership_id),
    INDEX idx_change_type (change_type),
    INDEX idx_source (source_type, source_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分流水表';

-- 更新会员等级定义 (扩展为5级)
-- 注：实际等级定义在代码枚举中，此处仅为说明
-- NORMAL (普通会员) -> BRONZE (铜牌会员) -> SILVER (银牌会员) -> GOLD (金牌会员) -> DIAMOND (钻石会员)
