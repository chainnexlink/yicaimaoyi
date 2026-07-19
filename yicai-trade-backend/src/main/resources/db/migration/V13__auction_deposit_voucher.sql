-- ========== 电子反拍押金 & 抵用券系统 ==========

-- 押金配置表（系统级别配置）
CREATE TABLE IF NOT EXISTS t_auction_deposit_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(50) NOT NULL UNIQUE,
    config_value VARCHAR(200) NOT NULL,
    description VARCHAR(500),
    updated_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认押金配置
INSERT INTO t_auction_deposit_config (config_key, config_value, description) VALUES
('BUYER_DEPOSIT_AMOUNT', '50.00', '采购商发布反拍押金(USD)'),
('SUPPLIER_DEPOSIT_AMOUNT', '10.00', '供应商竞拍押金(USD)'),
('DEPOSIT_CURRENCY', 'USD', '押金币种'),
('BUYER_REGISTER_VOUCHERS', '3', '新用户(采购商)注册赠送押金抵用券数量'),
('SUPPLIER_REGISTER_VOUCHERS', '10', '供应商注册赠送拍卖押金抵用券数量'),
('VOUCHER_VALIDITY_DAYS', '365', '抵用券有效期(天)'),
('DEPOSIT_REFUND_DAYS', '7', '拍卖结束后押金退还期限(天)'),
('AUTO_REFUND_ON_COMPLETE', 'true', '拍卖完成后是否自动退还押金');

-- 押金记录表
CREATE TABLE IF NOT EXISTS t_auction_deposit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    deposit_no VARCHAR(50) NOT NULL UNIQUE,
    auction_id BIGINT,
    auction_no VARCHAR(50),
    user_id BIGINT NOT NULL,
    user_type VARCHAR(20) NOT NULL,
    company_name VARCHAR(200),
    amount DECIMAL(14,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    voucher_id BIGINT,
    payment_method VARCHAR(30) DEFAULT 'WALLET',
    status VARCHAR(20) NOT NULL DEFAULT 'PAID',
    paid_at TIMESTAMP,
    refunded_at TIMESTAMP,
    refund_reason VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_deposit_auction ON t_auction_deposit(auction_id);
CREATE INDEX idx_deposit_user ON t_auction_deposit(user_id);
CREATE INDEX idx_deposit_status ON t_auction_deposit(status);

-- 抵用券表
CREATE TABLE IF NOT EXISTS t_deposit_voucher (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    voucher_no VARCHAR(50) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    user_type VARCHAR(20) NOT NULL,
    voucher_type VARCHAR(30) NOT NULL DEFAULT 'AUCTION_DEPOSIT',
    face_value DECIMAL(14,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    source VARCHAR(50) DEFAULT 'REGISTER',
    used_auction_id BIGINT,
    used_deposit_id BIGINT,
    expires_at TIMESTAMP,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    issued_by BIGINT,
    remark VARCHAR(500)
);
CREATE INDEX idx_voucher_user ON t_deposit_voucher(user_id);
CREATE INDEX idx_voucher_status ON t_deposit_voucher(status);
CREATE INDEX idx_voucher_type ON t_deposit_voucher(voucher_type);
