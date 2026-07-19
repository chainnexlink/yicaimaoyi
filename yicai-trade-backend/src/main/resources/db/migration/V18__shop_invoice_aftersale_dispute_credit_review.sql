-- V18: 新增发票、售后、纠纷、店铺、营销推广、信用评级、订单评价、验厂审核表
-- 涵盖供应商生态、交易闭环、信任风控三大体系

-- ========================================
-- 1. 发票管理表 (t_invoice)
-- ========================================
CREATE TABLE IF NOT EXISTS t_invoice (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE,
    order_id BIGINT,
    order_no VARCHAR(50),
    contract_id BIGINT,
    buyer_id BIGINT,
    buyer_name VARCHAR(200),
    supplier_id BIGINT,
    supplier_name VARCHAR(200),
    invoice_type VARCHAR(30) DEFAULT 'NORMAL' COMMENT 'NORMAL/VAT_SPECIAL/PROFORMA/COMMERCIAL',
    amount DECIMAL(14,2),
    tax_rate DECIMAL(5,4),
    tax_amount DECIMAL(14,2),
    total_amount DECIMAL(14,2),
    currency VARCHAR(3) DEFAULT 'CNY',
    title VARCHAR(300),
    tax_no VARCHAR(50),
    bank_name VARCHAR(200),
    bank_account VARCHAR(50),
    register_address VARCHAR(500),
    register_phone VARCHAR(30),
    file_url VARCHAR(500),
    issue_date DATE,
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/ISSUED/SENT/RECEIVED/CANCELLED/VOID',
    remark VARCHAR(500),
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_invoice_order ON t_invoice(order_id);
CREATE INDEX idx_invoice_buyer ON t_invoice(buyer_id);
CREATE INDEX idx_invoice_supplier ON t_invoice(supplier_id);
CREATE INDEX idx_invoice_status ON t_invoice(status);

-- ========================================
-- 2. 售后服务表 (t_aftersale)
-- ========================================
CREATE TABLE IF NOT EXISTS t_aftersale (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    aftersale_no VARCHAR(50) UNIQUE,
    order_id BIGINT,
    order_no VARCHAR(50),
    buyer_id BIGINT,
    supplier_id BIGINT,
    type VARCHAR(20) COMMENT 'RETURN/EXCHANGE/REPAIR/REFUND_ONLY',
    reason_type VARCHAR(50) COMMENT 'QUALITY/WRONG_ITEM/DAMAGED/MISSING/SPEC_MISMATCH/OTHER',
    reason VARCHAR(1000),
    evidence_urls VARCHAR(2000),
    refund_amount DECIMAL(14,2),
    return_tracking_no VARCHAR(50),
    return_carrier VARCHAR(50),
    exchange_tracking_no VARCHAR(50),
    exchange_carrier VARCHAR(50),
    status VARCHAR(20) DEFAULT 'PENDING',
    supplier_remark VARCHAR(1000),
    platform_remark VARCHAR(1000),
    resolved_at DATETIME,
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_aftersale_order ON t_aftersale(order_id);
CREATE INDEX idx_aftersale_buyer ON t_aftersale(buyer_id);
CREATE INDEX idx_aftersale_supplier ON t_aftersale(supplier_id);
CREATE INDEX idx_aftersale_status ON t_aftersale(status);

-- ========================================
-- 3. 售后操作日志表 (t_aftersale_log)
-- ========================================
CREATE TABLE IF NOT EXISTS t_aftersale_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    aftersale_id BIGINT,
    operator_id BIGINT,
    operator_name VARCHAR(100),
    operator_role VARCHAR(20) COMMENT 'BUYER/SUPPLIER/PLATFORM',
    action VARCHAR(30),
    from_status VARCHAR(20),
    to_status VARCHAR(20),
    remark VARCHAR(1000),
    created_at DATETIME
);
CREATE INDEX idx_aftersale_log_as ON t_aftersale_log(aftersale_id);

-- ========================================
-- 4. 纠纷处理表 (t_dispute)
-- ========================================
CREATE TABLE IF NOT EXISTS t_dispute (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    dispute_no VARCHAR(50) UNIQUE,
    order_id BIGINT,
    order_no VARCHAR(50),
    aftersale_id BIGINT,
    initiator_id BIGINT,
    initiator_role VARCHAR(20),
    respondent_id BIGINT,
    respondent_role VARCHAR(20),
    dispute_type VARCHAR(30) COMMENT 'QUALITY/DELIVERY/PAYMENT/CONTRACT/FRAUD/OTHER',
    severity VARCHAR(10) DEFAULT 'NORMAL' COMMENT 'LOW/NORMAL/HIGH/CRITICAL',
    description VARCHAR(2000),
    evidence_urls VARCHAR(2000),
    claim_amount DECIMAL(14,2),
    awarded_amount DECIMAL(14,2),
    ruling_type VARCHAR(30) COMMENT 'FULL_REFUND/PARTIAL_REFUND/COMPENSATION/REJECT/MEDIATION',
    ruling_reason VARCHAR(2000),
    assigned_to BIGINT,
    status VARCHAR(20) DEFAULT 'OPEN' COMMENT 'OPEN/UNDER_REVIEW/MEDIATION/RULING/ENFORCING/CLOSED/WITHDRAWN',
    ruled_at DATETIME,
    closed_at DATETIME,
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_dispute_order ON t_dispute(order_id);
CREATE INDEX idx_dispute_initiator ON t_dispute(initiator_id);
CREATE INDEX idx_dispute_respondent ON t_dispute(respondent_id);
CREATE INDEX idx_dispute_status ON t_dispute(status);
CREATE INDEX idx_dispute_assigned ON t_dispute(assigned_to);

-- ========================================
-- 5. 纠纷沟通消息表 (t_dispute_message)
-- ========================================
CREATE TABLE IF NOT EXISTS t_dispute_message (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    dispute_id BIGINT,
    sender_id BIGINT,
    sender_role VARCHAR(20),
    content VARCHAR(2000),
    attachment_urls VARCHAR(2000),
    msg_type VARCHAR(20) DEFAULT 'TEXT' COMMENT 'TEXT/EVIDENCE/RULING/SYSTEM',
    created_at DATETIME
);
CREATE INDEX idx_dispute_msg_dispute ON t_dispute_message(dispute_id);

-- ========================================
-- 6. 供应商店铺表 (t_shop)
-- ========================================
CREATE TABLE IF NOT EXISTS t_shop (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT UNIQUE,
    shop_name VARCHAR(200),
    shop_logo VARCHAR(500),
    shop_banner VARCHAR(500),
    shop_description VARCHAR(2000),
    main_products VARCHAR(500),
    industry VARCHAR(100),
    province VARCHAR(50),
    city VARCHAR(50),
    detail_address VARCHAR(500),
    contact_name VARCHAR(50),
    contact_phone VARCHAR(30),
    contact_email VARCHAR(100),
    theme_color VARCHAR(20) DEFAULT '#1a73e8',
    custom_css VARCHAR(5000),
    sections_config TEXT,
    seo_title VARCHAR(200),
    seo_keywords VARCHAR(500),
    seo_description VARCHAR(500),
    visit_count BIGINT DEFAULT 0,
    product_count INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE/SUSPENDED/CLOSED',
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_shop_supplier ON t_shop(supplier_id);
CREATE INDEX idx_shop_industry ON t_shop(industry);

-- ========================================
-- 7. 店铺每日统计表 (t_shop_stats_daily)
-- ========================================
CREATE TABLE IF NOT EXISTS t_shop_stats_daily (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shop_id BIGINT,
    supplier_id BIGINT,
    stat_date DATE,
    page_views INT DEFAULT 0,
    unique_visitors INT DEFAULT 0,
    inquiry_count INT DEFAULT 0,
    order_count INT DEFAULT 0,
    order_amount DECIMAL(14,2) DEFAULT 0,
    product_click_count INT DEFAULT 0,
    favorite_count INT DEFAULT 0,
    created_at DATETIME
);
CREATE INDEX idx_shop_stats_shop_date ON t_shop_stats_daily(shop_id, stat_date);
CREATE INDEX idx_shop_stats_supplier ON t_shop_stats_daily(supplier_id);

-- ========================================
-- 8. 营销推广表 (t_promotion)
-- ========================================
CREATE TABLE IF NOT EXISTS t_promotion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT,
    title VARCHAR(200),
    promo_type VARCHAR(30) COMMENT 'KEYWORD_BID/BANNER_AD/PRODUCT_BOOST/EVENT_SIGNUP/COUPON',
    target_type VARCHAR(30) COMMENT 'PRODUCT/SHOP/CATEGORY',
    target_id BIGINT,
    keywords VARCHAR(500),
    bid_amount DECIMAL(10,2),
    daily_budget DECIMAL(10,2),
    total_budget DECIMAL(12,2),
    spent_amount DECIMAL(12,2) DEFAULT 0,
    impressions BIGINT DEFAULT 0,
    clicks BIGINT DEFAULT 0,
    conversions BIGINT DEFAULT 0,
    start_time DATETIME,
    end_time DATETIME,
    status VARCHAR(20) DEFAULT 'DRAFT' COMMENT 'DRAFT/PENDING_REVIEW/ACTIVE/PAUSED/EXPIRED/REJECTED',
    reject_reason VARCHAR(500),
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_promotion_supplier ON t_promotion(supplier_id);
CREATE INDEX idx_promotion_status ON t_promotion(status);
CREATE INDEX idx_promotion_type ON t_promotion(promo_type);

-- ========================================
-- 9. 平台活动表 (t_platform_event)
-- ========================================
CREATE TABLE IF NOT EXISTS t_platform_event (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(200),
    event_type VARCHAR(30) COMMENT 'TRADE_FAIR/FLASH_SALE/GROUP_BUY/SEASONAL',
    description VARCHAR(2000),
    banner_url VARCHAR(500),
    rules VARCHAR(3000),
    max_participants INT,
    current_participants INT DEFAULT 0,
    signup_start DATETIME,
    signup_end DATETIME,
    event_start DATETIME,
    event_end DATETIME,
    status VARCHAR(20) DEFAULT 'DRAFT' COMMENT 'DRAFT/SIGNUP_OPEN/SIGNUP_CLOSED/ACTIVE/ENDED',
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_event_status ON t_platform_event(status);

-- ========================================
-- 10. 活动报名表 (t_event_signup)
-- ========================================
CREATE TABLE IF NOT EXISTS t_event_signup (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_id BIGINT,
    supplier_id BIGINT,
    product_ids VARCHAR(500),
    application_note VARCHAR(1000),
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/REJECTED',
    reject_reason VARCHAR(500),
    created_at DATETIME
);
CREATE INDEX idx_signup_event ON t_event_signup(event_id);
CREATE INDEX idx_signup_supplier ON t_event_signup(supplier_id);

-- ========================================
-- 11. 供应商信用评分表 (t_supplier_credit)
-- ========================================
CREATE TABLE IF NOT EXISTS t_supplier_credit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT UNIQUE,
    credit_score DECIMAL(5,2) DEFAULT 100.00 COMMENT '综合信用分 0-100',
    credit_level VARCHAR(10) DEFAULT 'A' COMMENT 'AAA/AA/A/B/C/D',
    delivery_score DECIMAL(5,2) DEFAULT 100.00 COMMENT '交付得分',
    quality_score DECIMAL(5,2) DEFAULT 100.00 COMMENT '质量得分',
    service_score DECIMAL(5,2) DEFAULT 100.00 COMMENT '服务得分',
    dispute_score DECIMAL(5,2) DEFAULT 100.00 COMMENT '纠纷得分',
    total_orders INT DEFAULT 0,
    completed_orders INT DEFAULT 0,
    on_time_deliveries INT DEFAULT 0,
    late_deliveries INT DEFAULT 0,
    quality_pass_count INT DEFAULT 0,
    quality_fail_count INT DEFAULT 0,
    total_disputes INT DEFAULT 0,
    lost_disputes INT DEFAULT 0,
    total_aftersales INT DEFAULT 0,
    avg_response_hours DECIMAL(6,2) DEFAULT 0,
    avg_buyer_rating DECIMAL(3,2) DEFAULT 5.00 COMMENT '买家平均评分 1-5',
    total_reviews INT DEFAULT 0,
    last_calculated_at DATETIME,
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_credit_supplier ON t_supplier_credit(supplier_id);
CREATE INDEX idx_credit_level ON t_supplier_credit(credit_level);
CREATE INDEX idx_credit_score ON t_supplier_credit(credit_score DESC);

-- ========================================
-- 12. 信用变更记录表 (t_credit_change_log)
-- ========================================
CREATE TABLE IF NOT EXISTS t_credit_change_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT,
    change_type VARCHAR(30) COMMENT 'ORDER_COMPLETE/LATE_DELIVERY/QUALITY_PASS/QUALITY_FAIL/DISPUTE_WIN/DISPUTE_LOSE/BUYER_REVIEW/AFTERSALE/MANUAL_ADJUST',
    dimension VARCHAR(20) COMMENT 'DELIVERY/QUALITY/SERVICE/DISPUTE/OVERALL',
    old_score DECIMAL(5,2),
    new_score DECIMAL(5,2),
    change_amount DECIMAL(5,2),
    related_id BIGINT,
    related_type VARCHAR(30) COMMENT 'ORDER/DISPUTE/AFTERSALE/REVIEW',
    reason VARCHAR(500),
    created_at DATETIME
);
CREATE INDEX idx_credit_log_supplier ON t_credit_change_log(supplier_id);
CREATE INDEX idx_credit_log_type ON t_credit_change_log(change_type);

-- ========================================
-- 13. 订单评价表 (t_order_review)
-- ========================================
CREATE TABLE IF NOT EXISTS t_order_review (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT,
    order_no VARCHAR(50),
    buyer_id BIGINT,
    buyer_name VARCHAR(100),
    supplier_id BIGINT,
    overall_rating INT COMMENT '综合评分 1-5',
    quality_rating INT COMMENT '质量评分 1-5',
    delivery_rating INT COMMENT '交付评分 1-5',
    service_rating INT COMMENT '服务评分 1-5',
    price_rating INT COMMENT '价格评分 1-5',
    content VARCHAR(2000),
    image_urls VARCHAR(2000),
    is_anonymous BOOLEAN DEFAULT FALSE,
    supplier_reply VARCHAR(1000),
    replied_at DATETIME,
    status VARCHAR(20) DEFAULT 'PUBLISHED' COMMENT 'PUBLISHED/HIDDEN/APPEALED',
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_review_order ON t_order_review(order_id);
CREATE INDEX idx_review_buyer ON t_order_review(buyer_id);
CREATE INDEX idx_review_supplier ON t_order_review(supplier_id);
CREATE INDEX idx_review_status ON t_order_review(status);

-- ========================================
-- 14. 验厂审核表 (t_factory_audit)
-- ========================================
CREATE TABLE IF NOT EXISTS t_factory_audit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    audit_no VARCHAR(50) UNIQUE,
    supplier_id BIGINT,
    company_name VARCHAR(200),
    factory_address VARCHAR(500),
    audit_type VARCHAR(30) DEFAULT 'INITIAL' COMMENT 'INITIAL/ANNUAL/SPOT_CHECK/RENEWAL',
    audit_items VARCHAR(3000) COMMENT 'JSON格式检查项',
    auditor_name VARCHAR(100),
    auditor_id BIGINT,
    audit_date DATE,
    production_capacity VARCHAR(200),
    employee_count INT,
    factory_area INT COMMENT '平方米',
    equipment_list VARCHAR(2000),
    quality_system VARCHAR(200) COMMENT 'ISO9001/ISO14001等',
    photos VARCHAR(2000) COMMENT 'JSON格式照片URL',
    overall_score INT COMMENT '总分 0-100',
    conclusion VARCHAR(2000),
    status VARCHAR(20) DEFAULT 'SCHEDULED' COMMENT 'SCHEDULED/IN_PROGRESS/COMPLETED/PASSED/FAILED',
    next_audit_date DATE,
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX idx_factory_audit_supplier ON t_factory_audit(supplier_id);
CREATE INDEX idx_factory_audit_status ON t_factory_audit(status);
