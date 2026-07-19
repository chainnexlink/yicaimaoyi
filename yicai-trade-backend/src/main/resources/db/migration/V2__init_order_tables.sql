-- =====================================================
-- 易采贸易平台数据库迁移脚本
-- Version: V2
-- Description: 创建订单相关表
-- =====================================================

-- 订单主表
CREATE TABLE IF NOT EXISTS t_order (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(50) NOT NULL UNIQUE COMMENT '订单号',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT '订单总金额',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '订单状态: PENDING/CONFIRMED/PRODUCTION/SHIPPED/COMPLETED/CANCELLED',
    payment_status VARCHAR(20) DEFAULT 'UNPAID' COMMENT '支付状态: UNPAID/PAID',
    payment_method VARCHAR(50) COMMENT '支付方式',
    delivery_address VARCHAR(500) COMMENT '收货地址',
    contact_person VARCHAR(50) COMMENT '联系人',
    contact_phone VARCHAR(20) COMMENT '联系电话',
    required_delivery_date DATE COMMENT '要求交付日期',
    estimated_delivery_date DATE COMMENT '预计交付日期',
    actual_delivery_date DATE COMMENT '实际交付日期',
    tracking_number VARCHAR(100) COMMENT '物流单号',
    logistics_company VARCHAR(100) COMMENT '物流公司',
    contract_url VARCHAR(255) COMMENT '合同URL',
    invoice_url VARCHAR(255) COMMENT '发票URL',
    remark TEXT COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_no (order_no),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    CONSTRAINT fk_order_buyer FOREIGN KEY (buyer_id) REFERENCES t_buyer(id),
    CONSTRAINT fk_order_supplier FOREIGN KEY (supplier_id) REFERENCES t_supplier(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单主表';

-- 订单明细表
CREATE TABLE IF NOT EXISTS t_order_item (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT '订单ID',
    product_id BIGINT COMMENT '产品ID',
    product_name VARCHAR(200) NOT NULL COMMENT '产品名称',
    product_specs VARCHAR(500) COMMENT '产品规格',
    quantity INT NOT NULL DEFAULT 1 COMMENT '数量',
    unit_price DECIMAL(12,2) NOT NULL COMMENT '单价',
    subtotal DECIMAL(12,2) NOT NULL COMMENT '小计',
    remark VARCHAR(500) COMMENT '备注',
    INDEX idx_order_id (order_id),
    CONSTRAINT fk_item_order FOREIGN KEY (order_id) REFERENCES t_order(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单明细表';

-- 订单状态流转日志表
CREATE TABLE IF NOT EXISTS t_order_status_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT '订单ID',
    from_status VARCHAR(20) COMMENT '原状态',
    to_status VARCHAR(20) NOT NULL COMMENT '新状态',
    operator_id BIGINT COMMENT '操作人ID',
    operator_name VARCHAR(50) COMMENT '操作人姓名',
    remark TEXT COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    CONSTRAINT fk_log_order FOREIGN KEY (order_id) REFERENCES t_order(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单状态流转日志表';

-- 订单文件表
CREATE TABLE IF NOT EXISTS t_order_file (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT '订单ID',
    file_type VARCHAR(20) NOT NULL COMMENT '文件类型: CONTRACT/INVOICE/CERTIFICATE/OTHER',
    file_name VARCHAR(200) NOT NULL COMMENT '文件名',
    file_url VARCHAR(500) NOT NULL COMMENT '文件URL',
    file_size BIGINT COMMENT '文件大小(字节)',
    uploaded_by BIGINT COMMENT '上传人ID',
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
    INDEX idx_order_id (order_id),
    CONSTRAINT fk_file_order FOREIGN KEY (order_id) REFERENCES t_order(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单文件表';
