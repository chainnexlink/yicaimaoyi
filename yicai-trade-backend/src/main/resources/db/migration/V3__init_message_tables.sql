-- =====================================================
-- 易采贸易平台数据库迁移脚本
-- Version: V3
-- Description: 创建消息和即时通讯相关表
-- =====================================================

-- 站内消息表
CREATE TABLE IF NOT EXISTS t_message (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    receiver_id BIGINT NOT NULL COMMENT '接收人ID',
    sender_id BIGINT COMMENT '发送人ID',
    message_type VARCHAR(20) NOT NULL COMMENT '消息类型: SYSTEM/ORDER/INQUIRY/MATCH',
    title VARCHAR(200) COMMENT '标题',
    content TEXT COMMENT '内容',
    related_type VARCHAR(20) COMMENT '关联类型: ORDER/INQUIRY/SUPPLIER',
    related_id BIGINT COMMENT '关联业务ID',
    is_read TINYINT(1) DEFAULT 0 COMMENT '是否已读',
    read_at DATETIME COMMENT '阅读时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_receiver_id (receiver_id),
    INDEX idx_is_read (is_read),
    INDEX idx_message_type (message_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='站内消息表';

-- 通知设置表
CREATE TABLE IF NOT EXISTS t_notification_setting (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    notification_type VARCHAR(50) NOT NULL COMMENT '通知类型',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    INDEX idx_user_id (user_id),
    UNIQUE KEY uk_user_type (user_id, notification_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知设置表';

-- 聊天室表
CREATE TABLE IF NOT EXISTS t_chat_room (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_type VARCHAR(20) DEFAULT 'PRIVATE' COMMENT '聊天室类型: PRIVATE/GROUP',
    room_name VARCHAR(100) COMMENT '聊天室名称',
    participant_ids JSON COMMENT '参与者ID数组',
    related_type VARCHAR(20) COMMENT '关联类型: ORDER/INQUIRY',
    related_id BIGINT COMMENT '关联业务ID',
    last_message_at DATETIME COMMENT '最后消息时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_related (related_type, related_id),
    INDEX idx_last_message (last_message_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天室表';

-- 聊天记录表
CREATE TABLE IF NOT EXISTS t_chat_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT NOT NULL COMMENT '聊天室ID',
    sender_id BIGINT NOT NULL COMMENT '发送人ID',
    sender_name VARCHAR(50) COMMENT '发送人名称',
    message_type VARCHAR(20) DEFAULT 'TEXT' COMMENT '消息类型: TEXT/IMAGE/FILE',
    message_content TEXT COMMENT '消息内容',
    attachment_url VARCHAR(500) COMMENT '附件URL',
    attachment_name VARCHAR(200) COMMENT '附件名称',
    is_read TINYINT(1) DEFAULT 0 COMMENT '是否已读',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_room_id (room_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_created_at (created_at),
    CONSTRAINT fk_chat_room FOREIGN KEY (room_id) REFERENCES t_chat_room(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天记录表';

-- 询价单表
CREATE TABLE IF NOT EXISTS t_inquiry (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    inquiry_no VARCHAR(50) NOT NULL UNIQUE COMMENT '询价单号',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    supplier_id BIGINT COMMENT '指定供应商ID(可空)',
    product_category VARCHAR(100) COMMENT '产品类目',
    product_requirements TEXT COMMENT '产品需求描述',
    quantity INT COMMENT '数量',
    target_price_min DECIMAL(12,2) COMMENT '目标价格下限',
    target_price_max DECIMAL(12,2) COMMENT '目标价格上限',
    delivery_deadline DATE COMMENT '交付截止日期',
    status VARCHAR(20) DEFAULT 'OPEN' COMMENT '状态: OPEN/QUOTED/ACCEPTED/CLOSED/CANCELLED',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_inquiry_no (inquiry_no),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='询价单表';

-- 报价单表
CREATE TABLE IF NOT EXISTS t_quotation (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    quotation_no VARCHAR(50) NOT NULL UNIQUE COMMENT '报价单号',
    inquiry_id BIGINT NOT NULL COMMENT '询价单ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    quoted_price DECIMAL(12,2) NOT NULL COMMENT '报价金额',
    delivery_days INT COMMENT '交付周期(天)',
    payment_terms VARCHAR(200) COMMENT '付款条款',
    quotation_detail TEXT COMMENT '报价详情',
    valid_until DATE COMMENT '报价有效期',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '状态: PENDING/ACCEPTED/REJECTED',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_inquiry_id (inquiry_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_status (status),
    CONSTRAINT fk_quotation_inquiry FOREIGN KEY (inquiry_id) REFERENCES t_inquiry(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报价单表';

-- 智能匹配历史表
CREATE TABLE IF NOT EXISTS t_match_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    match_condition JSON COMMENT '匹配条件',
    match_result JSON COMMENT '匹配结果',
    match_count INT DEFAULT 0 COMMENT '匹配数量',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='智能匹配历史表';
