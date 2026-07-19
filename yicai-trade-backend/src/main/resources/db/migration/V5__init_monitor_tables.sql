-- =====================================================
-- 易采贸易平台数据库迁移脚本
-- Version: V5
-- Description: 创建生产监控相关表（三方闭环：供应商上传、采购商查看、平台管理）
-- =====================================================

-- 生产监控配置表（订单级别的监控要求）
CREATE TABLE IF NOT EXISTS t_monitor_setting (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE COMMENT '关联订单ID',
    contract_id BIGINT COMMENT '关联合同ID',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    
    -- 监控要求
    upload_frequency VARCHAR(20) DEFAULT 'WEEKLY' COMMENT '上传频率: DAILY/TWICE_WEEKLY/WEEKLY/BIWEEKLY',
    min_uploads_per_period INT DEFAULT 1 COMMENT '每周期最少上传次数',
    require_photo BOOLEAN DEFAULT TRUE COMMENT '是否需要图片',
    require_video BOOLEAN DEFAULT FALSE COMMENT '是否需要视频',
    require_description BOOLEAN DEFAULT TRUE COMMENT '是否需要文字描述',
    
    -- 监控阶段
    monitor_stages JSON COMMENT '监控阶段定义: ["备料","加工","组装","测试","包装"]',
    current_stage VARCHAR(50) COMMENT '当前阶段',
    
    -- 状态
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否启用监控',
    start_date DATE COMMENT '监控开始日期',
    end_date DATE COMMENT '监控结束日期',
    
    -- 评分权重
    weight_in_score INT DEFAULT 20 COMMENT '在供应商评分中的权重(百分比)',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_order_id (order_id),
    INDEX idx_contract_id (contract_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='生产监控配置表';

-- 生产监控上传记录表
CREATE TABLE IF NOT EXISTS t_production_monitor (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    monitor_setting_id BIGINT NOT NULL COMMENT '关联监控配置ID',
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    
    -- 上传内容
    title VARCHAR(200) NOT NULL COMMENT '监控标题',
    description TEXT COMMENT '进度描述',
    stage VARCHAR(50) COMMENT '生产阶段',
    progress_percent INT DEFAULT 0 COMMENT '完成进度百分比(0-100)',
    
    -- 媒体文件（JSON数组存储多个文件）
    photos JSON COMMENT '图片URL数组: [{"url":"xxx","thumbnail":"xxx","size":1024}]',
    videos JSON COMMENT '视频URL数组: [{"url":"xxx","thumbnail":"xxx","duration":60}]',
    attachments JSON COMMENT '其他附件URL数组',
    
    -- 上传信息
    upload_type VARCHAR(20) DEFAULT 'SCHEDULED' COMMENT '上传类型: SCHEDULED/EXTRA/URGENT',
    uploader_id BIGINT COMMENT '上传人ID',
    uploader_name VARCHAR(100) COMMENT '上传人姓名',
    
    -- 审核状态（平台审核）
    review_status VARCHAR(20) DEFAULT 'PENDING' COMMENT '审核状态: PENDING/APPROVED/REJECTED',
    reviewer_id BIGINT COMMENT '审核人ID',
    reviewer_name VARCHAR(100) COMMENT '审核人姓名',
    reviewed_at DATETIME COMMENT '审核时间',
    review_note TEXT COMMENT '审核意见',
    
    -- 采购商查看
    buyer_viewed BOOLEAN DEFAULT FALSE COMMENT '采购商是否已查看',
    buyer_viewed_at DATETIME COMMENT '采购商查看时间',
    buyer_feedback TEXT COMMENT '采购商反馈',
    buyer_rating INT COMMENT '采购商评分(1-5)',
    
    -- 预警标记
    is_overdue BOOLEAN DEFAULT FALSE COMMENT '是否逾期上传',
    overdue_days INT DEFAULT 0 COMMENT '逾期天数',
    has_quality_issue BOOLEAN DEFAULT FALSE COMMENT '是否有质量问题标记',
    quality_issue_note TEXT COMMENT '质量问题说明',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_setting_id (monitor_setting_id),
    INDEX idx_order_id (order_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_stage (stage),
    INDEX idx_review_status (review_status),
    INDEX idx_created_at (created_at),
    
    CONSTRAINT fk_monitor_setting FOREIGN KEY (monitor_setting_id) REFERENCES t_monitor_setting(id),
    CONSTRAINT fk_monitor_order FOREIGN KEY (order_id) REFERENCES t_order(id),
    CONSTRAINT fk_monitor_supplier FOREIGN KEY (supplier_id) REFERENCES t_supplier(id),
    CONSTRAINT fk_monitor_buyer FOREIGN KEY (buyer_id) REFERENCES t_buyer(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='生产监控上传记录表';

-- 质检报告表
CREATE TABLE IF NOT EXISTS t_quality_report (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    monitor_id BIGINT COMMENT '关联监控记录ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    
    -- 报告信息
    report_no VARCHAR(50) NOT NULL UNIQUE COMMENT '报告编号',
    report_type VARCHAR(20) DEFAULT 'INTERIM' COMMENT '报告类型: INTERIM/FINAL/SPECIAL',
    report_title VARCHAR(200) NOT NULL COMMENT '报告标题',
    
    -- 检验信息
    inspection_date DATE NOT NULL COMMENT '检验日期',
    inspector_name VARCHAR(100) COMMENT '检验员',
    sample_count INT COMMENT '抽检数量',
    pass_count INT COMMENT '合格数量',
    fail_count INT COMMENT '不合格数量',
    pass_rate DECIMAL(5,2) COMMENT '合格率(%)',
    
    -- 检验项目明细（JSON数组）
    inspection_items JSON COMMENT '检验项目: [{"item":"外观","standard":"无划痕","result":"合格"}]',
    
    -- 结论
    conclusion VARCHAR(20) DEFAULT 'PENDING' COMMENT '结论: PASS/CONDITIONAL_PASS/FAIL/PENDING',
    conclusion_note TEXT COMMENT '结论说明',
    
    -- 文件
    report_pdf_url VARCHAR(500) COMMENT '报告PDF文件URL',
    photos JSON COMMENT '检验图片',
    
    -- 状态
    status VARCHAR(20) DEFAULT 'DRAFT' COMMENT '状态: DRAFT/SUBMITTED/REVIEWED',
    reviewed_by BIGINT COMMENT '审核人ID',
    reviewed_at DATETIME COMMENT '审核时间',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_order_id (order_id),
    INDEX idx_monitor_id (monitor_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_report_no (report_no),
    INDEX idx_conclusion (conclusion),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='质检报告表';

-- 监控预警表
CREATE TABLE IF NOT EXISTS t_monitor_alert (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    monitor_setting_id BIGINT COMMENT '关联监控配置ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    
    -- 预警信息
    alert_type VARCHAR(30) NOT NULL COMMENT '预警类型: UPLOAD_OVERDUE/QUALITY_ISSUE/PROGRESS_DELAY/LOW_SCORE',
    alert_level VARCHAR(20) DEFAULT 'WARNING' COMMENT '预警级别: INFO/WARNING/URGENT/CRITICAL',
    alert_title VARCHAR(200) NOT NULL COMMENT '预警标题',
    alert_content TEXT COMMENT '预警内容',
    
    -- 处理状态
    status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT '状态: ACTIVE/ACKNOWLEDGED/RESOLVED/IGNORED',
    resolved_by BIGINT COMMENT '处理人ID',
    resolved_at DATETIME COMMENT '处理时间',
    resolution_note TEXT COMMENT '处理说明',
    
    -- 通知
    buyer_notified BOOLEAN DEFAULT FALSE COMMENT '是否已通知采购商',
    supplier_notified BOOLEAN DEFAULT FALSE COMMENT '是否已通知供应商',
    platform_notified BOOLEAN DEFAULT FALSE COMMENT '是否已通知平台',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_order_id (order_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_alert_level (alert_level),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='监控预警表';

-- 供应商评分明细表（与监控关联）
CREATE TABLE IF NOT EXISTS t_supplier_score_detail (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    order_id BIGINT COMMENT '关联订单ID',
    
    -- 评分维度
    score_type VARCHAR(30) NOT NULL COMMENT '评分类型: MONITOR_UPLOAD/QUALITY/DELIVERY/SERVICE/BUYER_RATING',
    score_value INT NOT NULL COMMENT '得分(0-100)',
    weight INT DEFAULT 20 COMMENT '权重(%)',
    weighted_score DECIMAL(5,2) COMMENT '加权得分',
    
    -- 评分说明
    score_reason TEXT COMMENT '评分原因',
    reference_id BIGINT COMMENT '关联记录ID(如监控ID、质检ID)',
    
    -- 评分人
    scorer_type VARCHAR(20) DEFAULT 'SYSTEM' COMMENT '评分方: SYSTEM/BUYER/PLATFORM',
    scorer_id BIGINT COMMENT '评分人ID',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_order_id (order_id),
    INDEX idx_score_type (score_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='供应商评分明细表';
