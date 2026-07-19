-- V10: 电子拍卖场功能增强
-- 1. 扩展拍卖主表字段（类型/币种/底价/邀请模式）
-- 2. 供应商邀请表
-- 3. 供应商黑白名单表
-- 4. 拍卖操作日志表
-- 5. 供应商综合评分表

-- ========== 1. 扩展 t_auction 主表 ==========
ALTER TABLE t_auction ADD COLUMN auction_type VARCHAR(30) DEFAULT 'REVERSE_AUCTION' COMMENT '拍卖类型: REVERSE_AUCTION(反向拍卖), TENDER(招标), INQUIRY(询比价)';
ALTER TABLE t_auction ADD COLUMN currency VARCHAR(10) DEFAULT 'CNY' COMMENT '币种: CNY/USD/EUR/GBP';
ALTER TABLE t_auction ADD COLUMN reserve_price DECIMAL(12,2) COMMENT '底价（隐藏），低于此价不接受';
ALTER TABLE t_auction ADD COLUMN show_reserve_price TINYINT(1) DEFAULT 0 COMMENT '是否公开底价';
ALTER TABLE t_auction ADD COLUMN invite_only TINYINT(1) DEFAULT 0 COMMENT '是否仅邀请制（0=公开报名 1=定向邀请）';
ALTER TABLE t_auction ADD COLUMN bid_cooldown_seconds INT DEFAULT 0 COMMENT '出价冷却时间（秒），防止恶意频繁改价';
ALTER TABLE t_auction ADD COLUMN reference_price DECIMAL(12,2) COMMENT '参考价（从成本核算系统导入）';
ALTER TABLE t_auction ADD COLUMN reference_source VARCHAR(200) COMMENT '参考价来源说明';
ALTER TABLE t_auction ADD COLUMN scoring_enabled TINYINT(1) DEFAULT 0 COMMENT '是否启用综合评分（0=仅价格 1=综合评分）';
ALTER TABLE t_auction ADD COLUMN price_weight INT DEFAULT 100 COMMENT '价格权重（百分比）';
ALTER TABLE t_auction ADD COLUMN delivery_weight INT DEFAULT 0 COMMENT '交期权重（百分比）';
ALTER TABLE t_auction ADD COLUMN quality_weight INT DEFAULT 0 COMMENT '质量权重（百分比）';
ALTER TABLE t_auction ADD COLUMN service_weight INT DEFAULT 0 COMMENT '服务权重（百分比）';

-- ========== 2. 供应商邀请表 ==========
CREATE TABLE t_auction_invitation (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    auction_id BIGINT NOT NULL COMMENT '拍卖ID',
    supplier_id BIGINT NOT NULL COMMENT '被邀请的供应商ID',
    supplier_company VARCHAR(200) COMMENT '供应商公司名称',
    invite_message VARCHAR(500) COMMENT '邀请说明',
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT 'PENDING(待回复)/ACCEPTED(已接受)/REJECTED(已拒绝)/EXPIRED(已过期)',
    responded_at DATETIME COMMENT '回复时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_auction_supplier (auction_id, supplier_id),
    INDEX idx_invitation_supplier (supplier_id),
    FOREIGN KEY (auction_id) REFERENCES t_auction(id)
) CHARSET=utf8mb4 COMMENT='拍卖邀请表';

-- ========== 3. 供应商黑白名单表 ==========
CREATE TABLE t_auction_supplier_list (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    buyer_id BIGINT NOT NULL COMMENT '采购商ID（名单所有者）',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    supplier_company VARCHAR(200) COMMENT '供应商公司名称',
    list_type VARCHAR(20) NOT NULL COMMENT 'WHITELIST(白名单)/BLACKLIST(黑名单)',
    reason VARCHAR(500) COMMENT '加入原因',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_buyer_supplier_type (buyer_id, supplier_id, list_type),
    INDEX idx_list_buyer (buyer_id),
    INDEX idx_list_supplier (supplier_id)
) CHARSET=utf8mb4 COMMENT='供应商黑白名单';

-- ========== 4. 拍卖操作日志表 ==========
CREATE TABLE t_auction_operation_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    auction_id BIGINT NOT NULL COMMENT '拍卖ID',
    auction_no VARCHAR(50) COMMENT '拍卖编号',
    operation_type VARCHAR(30) NOT NULL COMMENT '操作类型: CREATE/PUBLISH/APPROVE/REJECT/CANCEL/START/END/BID/SIGNUP/CONFIRM/EXTEND/FAIL/EXPORT/REAUCTION',
    from_status VARCHAR(20) COMMENT '操作前状态',
    to_status VARCHAR(20) COMMENT '操作后状态',
    operator_id BIGINT COMMENT '操作人ID',
    operator_name VARCHAR(100) COMMENT '操作人名称',
    detail VARCHAR(2000) COMMENT '操作详情（出价金额、驳回原因等）',
    ip_address VARCHAR(50) COMMENT '操作IP',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alog_auction (auction_id),
    INDEX idx_alog_type (operation_type),
    INDEX idx_alog_time (created_at)
) CHARSET=utf8mb4 COMMENT='拍卖操作日志（不可修改删除）';

-- ========== 5. 供应商综合评分表 ==========
CREATE TABLE t_auction_supplier_score (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    auction_id BIGINT NOT NULL COMMENT '拍卖ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    supplier_company VARCHAR(200) COMMENT '供应商名称',
    price_score DECIMAL(5,2) DEFAULT 0 COMMENT '价格得分（自动计算）',
    delivery_score DECIMAL(5,2) DEFAULT 0 COMMENT '交期得分（管理员评）',
    quality_score DECIMAL(5,2) DEFAULT 0 COMMENT '质量得分（管理员评）',
    service_score DECIMAL(5,2) DEFAULT 0 COMMENT '服务得分（管理员评）',
    total_score DECIMAL(5,2) DEFAULT 0 COMMENT '综合得分',
    ranking INT COMMENT '综合排名',
    scored_by BIGINT COMMENT '评分人ID',
    scored_at DATETIME COMMENT '评分时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_score_auction_supplier (auction_id, supplier_id),
    INDEX idx_score_auction (auction_id),
    FOREIGN KEY (auction_id) REFERENCES t_auction(id)
) CHARSET=utf8mb4 COMMENT='供应商综合评分';

-- ========== 6. 出价记录扩展 ==========
ALTER TABLE t_auction_bid ADD COLUMN total_amount DECIMAL(14,2) COMMENT '出价总额（单价*数量）';
ALTER TABLE t_auction_bid ADD COLUMN promised_delivery_days INT COMMENT '承诺交货天数';

-- ========== 7. 报名记录扩展 ==========
ALTER TABLE t_auction_signup ADD COLUMN invitation_id BIGINT COMMENT '关联的邀请ID（邀请制时）';
ALTER TABLE t_auction_signup ADD COLUMN audit_remark VARCHAR(500) COMMENT '审核备注';
ALTER TABLE t_auction_signup ADD COLUMN audited_at DATETIME COMMENT '审核时间';
ALTER TABLE t_auction_signup ADD COLUMN audited_by BIGINT COMMENT '审核人ID';
