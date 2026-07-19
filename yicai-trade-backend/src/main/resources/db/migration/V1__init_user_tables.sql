-- =====================================================
-- 易采贸易平台数据库初始化脚本
-- Version: V1
-- Description: 创建用户认证相关表
-- =====================================================

-- 用户表
CREATE TABLE IF NOT EXISTS t_user (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(100) NOT NULL COMMENT '密码(BCrypt加密)',
    email VARCHAR(100) UNIQUE COMMENT '邮箱',
    phone VARCHAR(20) UNIQUE COMMENT '手机号',
    real_name VARCHAR(50) COMMENT '真实姓名',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    user_type VARCHAR(20) COMMENT '用户类型: BUYER/SUPPLIER/ADMIN',
    status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT '状态: ACTIVE/INACTIVE/BANNED',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at DATETIME COMMENT '删除时间',
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_phone (phone),
    INDEX idx_user_type (user_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 用户角色关联表
CREATE TABLE IF NOT EXISTS t_user_role (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    role_code VARCHAR(50) NOT NULL COMMENT '角色代码: ROLE_BUYER/ROLE_SUPPLIER/ROLE_ADMIN',
    INDEX idx_user_id (user_id),
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES t_user(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户角色关联表';

-- 刷新令牌表
CREATE TABLE IF NOT EXISTS t_refresh_token (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    token VARCHAR(500) NOT NULL COMMENT '刷新令牌',
    expires_at DATETIME NOT NULL COMMENT '过期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_token (token(255)),
    INDEX idx_user_id (user_id),
    CONSTRAINT fk_refresh_token_user FOREIGN KEY (user_id) REFERENCES t_user(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='刷新令牌表';

-- 供应商表
CREATE TABLE IF NOT EXISTS t_supplier (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE COMMENT '用户ID',
    company_name VARCHAR(200) NOT NULL COMMENT '公司名称',
    company_code VARCHAR(50) COMMENT '统一社会信用代码',
    business_license_url VARCHAR(255) COMMENT '营业执照URL',
    contact_person VARCHAR(50) COMMENT '联系人',
    contact_phone VARCHAR(20) COMMENT '联系电话',
    address VARCHAR(500) COMMENT '详细地址',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    district VARCHAR(50) COMMENT '区县',
    industry_category VARCHAR(100) COMMENT '行业分类',
    registered_capital DECIMAL(15,2) COMMENT '注册资本',
    establishment_date DATE COMMENT '成立日期',
    company_profile TEXT COMMENT '公司简介',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '状态: PENDING/APPROVED/REJECTED',
    rating_score DECIMAL(3,2) DEFAULT 5.00 COMMENT '履约评分',
    total_orders INT DEFAULT 0 COMMENT '累计订单数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_company_code (company_code),
    INDEX idx_status (status),
    INDEX idx_rating_score (rating_score),
    CONSTRAINT fk_supplier_user FOREIGN KEY (user_id) REFERENCES t_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='供应商表';

-- 供应商入驻申请表
CREATE TABLE IF NOT EXISTS t_supplier_application (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    company_name VARCHAR(200) NOT NULL COMMENT '公司名称',
    company_code VARCHAR(50) COMMENT '统一社会信用代码',
    company_type VARCHAR(50) COMMENT '公司类型',
    business_license_url VARCHAR(255) COMMENT '营业执照URL',
    contact_person VARCHAR(50) COMMENT '联系人',
    contact_phone VARCHAR(20) COMMENT '联系电话',
    contact_email VARCHAR(100) COMMENT '联系邮箱',
    address VARCHAR(500) COMMENT '详细地址',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    industry_category VARCHAR(100) COMMENT '行业分类',
    product_categories TEXT COMMENT '产品类目(JSON数组)',
    registered_capital DECIMAL(15,2) COMMENT '注册资本',
    company_profile TEXT COMMENT '公司简介',
    certifications TEXT COMMENT '资质证书(JSON数组)',
    audit_status VARCHAR(20) DEFAULT 'PENDING' COMMENT '审核状态: PENDING/APPROVED/REJECTED',
    audit_remark TEXT COMMENT '审核备注',
    auditor_id BIGINT COMMENT '审核人ID',
    audit_time DATETIME COMMENT '审核时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_audit_status (audit_status),
    CONSTRAINT fk_supplier_app_user FOREIGN KEY (user_id) REFERENCES t_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='供应商入驻申请表';

-- 供应商产品表
CREATE TABLE IF NOT EXISTS t_supplier_product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    product_name VARCHAR(200) NOT NULL COMMENT '产品名称',
    product_code VARCHAR(50) COMMENT '产品编码',
    category VARCHAR(100) COMMENT '产品分类',
    specs JSON COMMENT '产品规格(JSON)',
    unit_price DECIMAL(12,2) COMMENT '单价',
    min_order_quantity INT DEFAULT 1 COMMENT '最小起订量',
    lead_time_days INT COMMENT '交付周期(天)',
    images JSON COMMENT '产品图片(JSON数组)',
    description TEXT COMMENT '产品描述',
    status VARCHAR(20) DEFAULT 'ON_SHELF' COMMENT '状态: ON_SHELF/OFF_SHELF',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_category (category),
    INDEX idx_status (status),
    CONSTRAINT fk_product_supplier FOREIGN KEY (supplier_id) REFERENCES t_supplier(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='供应商产品表';

-- 采购商表
CREATE TABLE IF NOT EXISTS t_buyer (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE COMMENT '用户ID',
    company_name VARCHAR(200) COMMENT '公司名称',
    contact_person VARCHAR(50) COMMENT '联系人',
    contact_phone VARCHAR(20) COMMENT '联系电话',
    address VARCHAR(500) COMMENT '详细地址',
    province VARCHAR(50) COMMENT '省份',
    city VARCHAR(50) COMMENT '城市',
    district VARCHAR(50) COMMENT '区县',
    industry VARCHAR(100) COMMENT '所属行业',
    purchase_budget DECIMAL(15,2) COMMENT '采购预算',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    CONSTRAINT fk_buyer_user FOREIGN KEY (user_id) REFERENCES t_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购商表';

-- 采购商收藏表
CREATE TABLE IF NOT EXISTS t_buyer_favorite (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    target_type VARCHAR(20) NOT NULL COMMENT '收藏类型: SUPPLIER/PRODUCT',
    target_id BIGINT NOT NULL COMMENT '目标ID',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_target (target_type, target_id),
    UNIQUE KEY uk_buyer_target (buyer_id, target_type, target_id),
    CONSTRAINT fk_favorite_buyer FOREIGN KEY (buyer_id) REFERENCES t_buyer(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='采购商收藏表';

-- 插入默认管理员账号 (密码: admin123)
INSERT INTO t_user (username, password, email, user_type, status) VALUES 
('admin', '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO', 'admin@yicai.com', 'ADMIN', 'ACTIVE');

INSERT INTO t_user_role (user_id, role_code) VALUES 
(1, 'ROLE_ADMIN');
