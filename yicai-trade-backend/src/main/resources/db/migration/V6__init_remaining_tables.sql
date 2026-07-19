-- ===========================================================================
-- V6: 补全所有缺失的业务表（拍卖、产品、需求、内容、评论、工单、会员、认证、物流）
-- ===========================================================================

-- ===== 1. 电子拍卖主表 =====
CREATE TABLE IF NOT EXISTS t_auction (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    auction_no VARCHAR(50) NOT NULL UNIQUE COMMENT '拍卖编号',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    buyer_company VARCHAR(200) COMMENT '采购商公司',
    product_name VARCHAR(200) NOT NULL COMMENT '产品名称',
    product_category VARCHAR(100) COMMENT '产品分类',
    specification VARCHAR(2000) COMMENT '规格描述',
    quantity INT NOT NULL COMMENT '采购数量',
    unit VARCHAR(20) DEFAULT '件' COMMENT '单位',
    starting_price DECIMAL(12,2) COMMENT '起拍价/最高限价',
    current_lowest_price DECIMAL(12,2) COMMENT '当前最低出价',
    min_decrement DECIMAL(10,2) DEFAULT 1.00 COMMENT '最低降价幅度',
    signup_start_time DATETIME COMMENT '报名开始',
    signup_end_time DATETIME COMMENT '报名结束',
    signup_count INT DEFAULT 0 COMMENT '报名数',
    start_time DATETIME NOT NULL COMMENT '竞价开始',
    end_time DATETIME NOT NULL COMMENT '竞价结束',
    original_end_time DATETIME COMMENT '原始结束时间',
    min_participants INT DEFAULT 3 COMMENT '最少参与数',
    extension_minutes INT DEFAULT 5 COMMENT '延时分钟',
    extension_trigger_minutes INT DEFAULT 5 COMMENT '触发延时的剩余分钟',
    max_extensions INT DEFAULT 10 COMMENT '最大延时次数',
    current_extensions INT DEFAULT 0 COMMENT '当前延时次数',
    show_ranking TINYINT(1) DEFAULT 1 COMMENT '是否显示排名',
    show_lowest_price TINYINT(1) DEFAULT 1 COMMENT '是否显示最低价',
    status VARCHAR(20) DEFAULT 'DRAFT' NOT NULL COMMENT '状态',
    approver_id BIGINT COMMENT '审核人ID',
    approved_at DATETIME COMMENT '审核时间',
    approval_remark VARCHAR(500) COMMENT '审核备注',
    winner_supplier_id BIGINT COMMENT '中标供应商ID',
    winner_company VARCHAR(200) COMMENT '中标供应商名',
    winning_price DECIMAL(12,2) COMMENT '中标价格',
    bid_count INT DEFAULT 0 COMMENT '出价总次数',
    participant_count INT DEFAULT 0 COMMENT '参与供应商数',
    confirm_deadline DATETIME COMMENT '确认截止时间',
    buyer_confirmed TINYINT(1) DEFAULT 0 COMMENT '采购商是否确认',
    buyer_confirmed_at DATETIME COMMENT '采购商确认时间',
    supplier_confirmed TINYINT(1) DEFAULT 0 COMMENT '供应商是否确认',
    supplier_confirmed_at DATETIME COMMENT '供应商确认时间',
    order_id BIGINT COMMENT '关联订单ID',
    contract_id BIGINT COMMENT '关联合同ID',
    delivery_address VARCHAR(500) COMMENT '交货地址',
    required_delivery_date DATE COMMENT '要求交货日期',
    payment_terms VARCHAR(500) COMMENT '付款方式',
    remark VARCHAR(2000) COMMENT '备注',
    cover_image VARCHAR(500) COMMENT '封面图',
    attachments VARCHAR(2000) COMMENT '附件JSON',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_auction_buyer (buyer_id),
    INDEX idx_auction_status (status),
    INDEX idx_auction_time (start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='电子反拍/拍卖';

-- ===== 2. 拍卖出价记录 =====
CREATE TABLE IF NOT EXISTS t_auction_bid (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    auction_id BIGINT NOT NULL COMMENT '拍卖ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    supplier_company VARCHAR(200) COMMENT '供应商公司',
    bid_price DECIMAL(12,2) NOT NULL COMMENT '出价金额',
    bid_sequence INT COMMENT '出价序号',
    is_lowest TINYINT(1) DEFAULT 0 COMMENT '是否当前最低',
    is_winner TINYINT(1) DEFAULT 0 COMMENT '是否中标',
    remark VARCHAR(500) COMMENT '备注',
    bid_ip VARCHAR(50) COMMENT '出价IP',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bid_auction (auction_id),
    INDEX idx_bid_supplier (supplier_id),
    CONSTRAINT fk_bid_auction FOREIGN KEY (auction_id) REFERENCES t_auction(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='拍卖出价记录';

-- ===== 3. 拍卖报名记录 =====
CREATE TABLE IF NOT EXISTS t_auction_signup (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    auction_id BIGINT NOT NULL COMMENT '拍卖ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    supplier_company VARCHAR(200) COMMENT '供应商公司',
    contact_name VARCHAR(50) COMMENT '联系人',
    contact_phone VARCHAR(20) COMMENT '联系电话',
    status VARCHAR(20) DEFAULT 'APPROVED' COMMENT 'PENDING/APPROVED/REJECTED',
    remark VARCHAR(500) COMMENT '备注',
    qualification_promise VARCHAR(2000) COMMENT '资质承诺JSON',
    signup_ip VARCHAR(50) COMMENT '报名IP',
    has_bid TINYINT(1) DEFAULT 0 COMMENT '是否已出价',
    last_bid_time DATETIME COMMENT '最后出价时间',
    bid_count INT DEFAULT 0 COMMENT '出价次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_auction_supplier (auction_id, supplier_id),
    INDEX idx_signup_auction (auction_id),
    INDEX idx_signup_supplier (supplier_id),
    CONSTRAINT fk_signup_auction FOREIGN KEY (auction_id) REFERENCES t_auction(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='拍卖报名记录';

-- ===== 4. 产品管理 =====
CREATE TABLE IF NOT EXISTS t_product (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_no VARCHAR(30) UNIQUE COMMENT '产品编号',
    name VARCHAR(200) NOT NULL COMMENT '产品名称',
    supplier_id BIGINT COMMENT '供应商ID',
    supplier_name VARCHAR(100) COMMENT '供应商名称',
    category VARCHAR(50) COMMENT '分类',
    price DECIMAL(12,2) COMMENT '价格',
    min_order_quantity INT COMMENT '最小起订量',
    unit VARCHAR(20) COMMENT '单位',
    stock INT COMMENT '库存',
    description VARCHAR(1000) COMMENT '描述',
    image_url VARCHAR(500) COMMENT '图片URL',
    audit_status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/REJECTED',
    audit_remark VARCHAR(500) COMMENT '审核备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product_supplier (supplier_id),
    INDEX idx_product_audit (audit_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品管理';

-- ===== 5. 需求论坛 =====
CREATE TABLE IF NOT EXISTS t_demand (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    demand_no VARCHAR(30) UNIQUE COMMENT '需求编号',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    buyer_company_name VARCHAR(200) COMMENT '采购商公司',
    title VARCHAR(200) NOT NULL COMMENT '标题',
    description TEXT COMMENT '描述',
    category_code VARCHAR(50) COMMENT '品类编码',
    category_name VARCHAR(100) COMMENT '品类名称',
    quantity INT COMMENT '数量',
    unit VARCHAR(20) COMMENT '单位',
    budget DECIMAL(15,2) COMMENT '预算',
    expected_delivery_days INT COMMENT '期望交期天数',
    response_count INT DEFAULT 0 COMMENT '响应数',
    view_count INT DEFAULT 0 COMMENT '浏览量',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/ACTIVE/MATCHED/CLOSED',
    audit_status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/REJECTED',
    audit_remark VARCHAR(500) COMMENT '审核备注',
    auditor_id BIGINT COMMENT '审核人ID',
    audit_time DATETIME COMMENT '审核时间',
    expire_time DATETIME COMMENT '过期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_demand_buyer (buyer_id),
    INDEX idx_demand_status (status, audit_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='需求论坛';

-- ===== 6. 资讯管理 =====
CREATE TABLE IF NOT EXISTS t_news (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    news_no VARCHAR(30) UNIQUE COMMENT '资讯编号',
    title VARCHAR(200) NOT NULL COMMENT '标题',
    summary VARCHAR(500) COMMENT '摘要',
    content TEXT COMMENT '内容',
    cover_image VARCHAR(500) COMMENT '封面图',
    category VARCHAR(50) DEFAULT 'NEWS' COMMENT 'NEWS/ANNOUNCEMENT/POLICY',
    view_count INT DEFAULT 0 COMMENT '浏览量',
    is_top TINYINT(1) DEFAULT 0 COMMENT '是否置顶',
    is_recommend TINYINT(1) DEFAULT 0 COMMENT '是否推荐',
    status VARCHAR(20) DEFAULT 'DRAFT' COMMENT 'DRAFT/PUBLISHED/ARCHIVED',
    publish_time DATETIME COMMENT '发布时间',
    author_id BIGINT COMMENT '作者ID',
    author_name VARCHAR(50) COMMENT '作者名',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_news_status (status),
    INDEX idx_news_publish (publish_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='资讯管理';

-- ===== 7. Banner管理 =====
CREATE TABLE IF NOT EXISTS t_banner (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL COMMENT '标题',
    image_url VARCHAR(500) COMMENT '图片URL',
    link_url VARCHAR(500) COMMENT '跳转链接',
    position VARCHAR(50) DEFAULT 'HOME' COMMENT 'HOME/MOBILE/CATEGORY',
    sort_order INT DEFAULT 0 COMMENT '排序',
    status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE/INACTIVE/DRAFT',
    start_time DATETIME COMMENT '开始展示时间',
    end_time DATETIME COMMENT '结束展示时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Banner管理';

-- ===== 8. 评论管理 =====
CREATE TABLE IF NOT EXISTS t_comment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT COMMENT '用户ID',
    user_name VARCHAR(100) COMMENT '用户名',
    source_type VARCHAR(30) COMMENT 'NEWS/SUPPLIER/ORDER/DEMAND',
    source_id BIGINT COMMENT '来源ID',
    content VARCHAR(1000) COMMENT '内容',
    rating INT COMMENT '评分1-5',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/HIDDEN',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_comment_source (source_type, source_id),
    INDEX idx_comment_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论管理';

-- ===== 9. 工单管理 =====
CREATE TABLE IF NOT EXISTS t_ticket (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticket_no VARCHAR(30) UNIQUE COMMENT '工单编号',
    user_id BIGINT COMMENT '用户ID',
    user_name VARCHAR(100) COMMENT '用户名',
    ticket_type VARCHAR(30) COMMENT 'ACCOUNT/ORDER/PAYMENT/LOGISTICS/CERT/TECH/COMPLAINT',
    title VARCHAR(200) NOT NULL COMMENT '标题',
    content VARCHAR(2000) COMMENT '内容',
    priority VARCHAR(10) DEFAULT 'NORMAL' COMMENT 'LOW/NORMAL/HIGH/URGENT',
    status VARCHAR(20) DEFAULT 'OPEN' COMMENT 'OPEN/PROCESSING/CLOSED',
    reply_content VARCHAR(2000) COMMENT '回复',
    replied_at DATETIME COMMENT '回复时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ticket_user (user_id),
    INDEX idx_ticket_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单管理';

-- ===== 10. 会员管理 =====
CREATE TABLE IF NOT EXISTS t_membership (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT COMMENT '用户ID',
    user_name VARCHAR(100) COMMENT '用户名',
    company_name VARCHAR(200) COMMENT '公司名',
    level VARCHAR(20) DEFAULT 'NORMAL' COMMENT 'NORMAL/VIP/DIAMOND',
    points INT DEFAULT 0 COMMENT '当前积分',
    total_points INT DEFAULT 0 COMMENT '累计积分',
    expire_at DATETIME COMMENT '到期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_membership_user (user_id),
    INDEX idx_membership_level (level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员管理';

-- ===== 11. 企业认证 =====
CREATE TABLE IF NOT EXISTS t_certification (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cert_no VARCHAR(30) UNIQUE COMMENT '认证编号',
    company_id BIGINT COMMENT '企业ID',
    company_name VARCHAR(200) COMMENT '企业名称',
    cert_type VARCHAR(50) COMMENT 'REAL_NAME/ISO9001/PRODUCTION/VIP',
    materials VARCHAR(2000) COMMENT '材料JSON',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/APPROVED/REJECTED',
    audit_remark VARCHAR(500) COMMENT '审核备注',
    audited_at DATETIME COMMENT '审核时间',
    expire_at DATETIME COMMENT '到期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cert_company (company_id),
    INDEX idx_cert_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='企业认证';

-- ===== 12. 物流管理 =====
CREATE TABLE IF NOT EXISTS t_logistics (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tracking_no VARCHAR(50) UNIQUE COMMENT '物流单号',
    order_id BIGINT COMMENT '订单ID',
    order_no VARCHAR(30) COMMENT '订单编号',
    sender_name VARCHAR(100) COMMENT '发件人',
    sender_address VARCHAR(500) COMMENT '发件地址',
    receiver_name VARCHAR(100) COMMENT '收件人',
    receiver_address VARCHAR(500) COMMENT '收件地址',
    carrier VARCHAR(50) COMMENT '承运商',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING/SHIPPING/DELIVERED/EXCEPTION',
    shipped_at DATETIME COMMENT '发货时间',
    delivered_at DATETIME COMMENT '签收时间',
    remark VARCHAR(500) COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_logistics_order (order_id),
    INDEX idx_logistics_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物流管理';
