-- =====================================================
-- V14: 消息对接（QQ/企业微信）+ 订阅计费
-- =====================================================

-- 1. 全局配置表
CREATE TABLE IF NOT EXISTS t_message_bridge_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(50) NOT NULL,
    config_value VARCHAR(500) NOT NULL DEFAULT '',
    description VARCHAR(500),
    updated_by BIGINT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO t_message_bridge_config (config_key, config_value, description) VALUES
('BRIDGE_MONTHLY_PRICE', '99.00', '消息对接月度费用（元）'),
('BRIDGE_SERVICE_ENABLED', 'true', '消息对接服务全局开关'),
('BRIDGE_TRIAL_DAYS', '7', '免费试用天数'),
('WECHAT_WORK_CORP_ID', '', '企业微信企业ID'),
('WECHAT_WORK_AGENT_ID', '', '企业微信应用AgentId'),
('WECHAT_WORK_SECRET', '', '企业微信应用Secret'),
('QQ_BOT_APP_ID', '', 'QQ机器人AppID'),
('QQ_BOT_TOKEN', '', 'QQ机器人Token'),
('BRIDGE_MAX_FORWARD_PER_DAY', '500', '每供应商每日最大转发数');

-- 2. 订阅记录表
CREATE TABLE IF NOT EXISTS t_message_bridge_subscription (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    subscription_no VARCHAR(50) NOT NULL,
    supplier_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    channel_type VARCHAR(20) NOT NULL COMMENT 'WECHAT_WORK / QQ_BOT / ALL',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/ACTIVE/EXPIRED/CANCELLED',
    amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    payment_id BIGINT COMMENT '关联t_payment.id',
    start_date DATE,
    end_date DATE,
    auto_renew TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_subscription_no (subscription_no),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 渠道绑定表
CREATE TABLE IF NOT EXISTS t_message_bridge_binding (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    channel_type VARCHAR(20) NOT NULL COMMENT 'WECHAT_WORK / QQ_BOT',
    channel_user_id VARCHAR(100) COMMENT '外部平台用户标识',
    channel_username VARCHAR(100) COMMENT '外部平台显示名',
    bind_status VARCHAR(20) NOT NULL DEFAULT 'UNBOUND' COMMENT 'UNBOUND/PENDING/BOUND/REVOKED',
    verification_code VARCHAR(20),
    verification_expire DATETIME,
    bound_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_supplier_channel (supplier_id, channel_type),
    INDEX idx_user_id (user_id),
    INDEX idx_bind_status (bind_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 转发日志表
CREATE TABLE IF NOT EXISTS t_message_bridge_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id BIGINT COMMENT '关联t_message.id',
    supplier_id BIGINT NOT NULL,
    channel_type VARCHAR(20) NOT NULL COMMENT 'WECHAT_WORK / QQ_BOT',
    direction VARCHAR(10) NOT NULL COMMENT 'OUTBOUND / INBOUND',
    content_summary VARCHAR(500),
    external_msg_id VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING/SUCCESS/FAILED',
    error_message VARCHAR(1000),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_message_id (message_id),
    INDEX idx_channel_type (channel_type),
    INDEX idx_direction (direction),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 修改t_payment表，允许order_id为NULL（支持非订单类支付如订阅）
ALTER TABLE t_payment MODIFY COLUMN order_id BIGINT NULL;
