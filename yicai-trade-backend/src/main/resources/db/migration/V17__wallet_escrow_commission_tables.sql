-- =============================================================================
-- V17: 钱包、交易流水、平台佣金、订单托管 四张核心财务表
-- 支撑完整交易闭环: 支付 → 托管 → 佣金收取 → 释放 → 返佣
-- =============================================================================

-- 1. 零钱钱包表（三角色: BUYER / SUPPLIER / PLATFORM）
CREATE TABLE IF NOT EXISTS t_wallet (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    owner_id        BIGINT          NOT NULL COMMENT '所有者ID（用户ID / 供应商ID / 平台固定0）',
    owner_type      VARCHAR(20)     NOT NULL COMMENT '所有者类型: BUYER / SUPPLIER / PLATFORM',
    balance         DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '可用余额',
    frozen_amount   DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '冻结金额',
    total_income    DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '累计收入',
    total_expense   DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '累计支出',
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE' COMMENT '状态: ACTIVE / FROZEN / CLOSED',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_wallet_owner (owner_id, owner_type),
    INDEX idx_wallet_type (owner_type),
    INDEX idx_wallet_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='零钱钱包';

-- 2. 钱包交易流水表
CREATE TABLE IF NOT EXISTS t_wallet_transaction (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_no      VARCHAR(50)     NOT NULL COMMENT '交易单号',
    wallet_id           BIGINT          NOT NULL COMMENT '关联钱包ID',
    owner_id            BIGINT          NOT NULL,
    owner_type          VARCHAR(20)     NOT NULL,
    transaction_type    VARCHAR(30)     NOT NULL COMMENT '交易类型: COMMISSION_REBATE / COMMISSION_INCOME / CONTRACT_INCOME / WITHDRAW / RECHARGE / FREEZE / UNFREEZE / ADJUST',
    amount              DECIMAL(14,2)   NOT NULL COMMENT '交易金额（正=入账，负=出账）',
    balance_before      DECIMAL(14,2)   NOT NULL COMMENT '交易前余额',
    balance_after       DECIMAL(14,2)   NOT NULL COMMENT '交易后余额',
    contract_id         BIGINT          NULL COMMENT '关联合同ID',
    contract_no         VARCHAR(50)     NULL COMMENT '关联合同号',
    commission_id       BIGINT          NULL COMMENT '关联佣金记录ID',
    description         VARCHAR(500)    NULL COMMENT '交易说明',
    operator_id         BIGINT          NULL COMMENT '操作人ID',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_transaction_no (transaction_no),
    INDEX idx_tx_wallet (wallet_id),
    INDEX idx_tx_owner (owner_id, owner_type),
    INDEX idx_tx_type (transaction_type),
    INDEX idx_tx_contract (contract_id),
    INDEX idx_tx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='钱包交易流水';

-- 3. 平台佣金表（每笔合同一条记录，跟踪佣金收取和返佣）
CREATE TABLE IF NOT EXISTS t_platform_commission (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    commission_no       VARCHAR(50)     NOT NULL COMMENT '佣金单号',
    contract_id         BIGINT          NOT NULL COMMENT '关联合同ID',
    contract_no         VARCHAR(50)     NULL COMMENT '关联合同号',
    buyer_id            BIGINT          NOT NULL COMMENT '采购商ID',
    supplier_id         BIGINT          NOT NULL COMMENT '供应商ID',
    contract_amount     DECIMAL(14,2)   NOT NULL COMMENT '合同总金额',
    platform_rate       DECIMAL(5,4)    NOT NULL DEFAULT 0.0200 COMMENT '平台固定佣金比例 2%',
    platform_fee        DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '平台佣金金额',
    rebate_rate         DECIMAL(5,4)    NOT NULL DEFAULT 0.0100 COMMENT '客户返佣比例 1%-10%',
    rebate_amount       DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '返佣金额',
    total_service_fee   DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '平台服务费总额',
    status              VARCHAR(20)     NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING / COLLECTED / REBATED / CANCELLED',
    collected_at        DATETIME        NULL COMMENT '服务费收取时间',
    rebated_at          DATETIME        NULL COMMENT '返佣执行时间',
    remark              TEXT            NULL COMMENT '备注',
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_commission_no (commission_no),
    UNIQUE KEY uk_commission_contract (contract_id),
    INDEX idx_commission_buyer (buyer_id),
    INDEX idx_commission_supplier (supplier_id),
    INDEX idx_commission_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='平台佣金';

-- 4. 订单托管表（每笔订单一条记录，担保交易资金托管）
CREATE TABLE IF NOT EXISTS t_order_escrow (
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    escrow_no                   VARCHAR(50)     NOT NULL COMMENT '托管单号',
    order_id                    BIGINT          NOT NULL COMMENT '订单ID',
    order_no                    VARCHAR(50)     NULL COMMENT '订单号',
    buyer_id                    BIGINT          NOT NULL COMMENT '采购商ID',
    supplier_id                 BIGINT          NOT NULL COMMENT '供应商ID',
    order_amount                DECIMAL(14,2)   NOT NULL COMMENT '订单总金额',
    escrow_amount               DECIMAL(14,2)   NOT NULL COMMENT '实际托管金额（扣除佣金和返佣后）',
    commission_amount           DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '平台佣金金额',
    rebate_amount               DECIMAL(14,2)   NOT NULL DEFAULT 0.00 COMMENT '返佣金额',
    status                      VARCHAR(20)     NOT NULL DEFAULT 'FROZEN' COMMENT '状态: FROZEN / RELEASING / RELEASED / REFUNDED',
    release_days                INT             NULL DEFAULT 7 COMMENT '计划释放天数',
    auto_release_at             DATETIME        NULL COMMENT '计划自动释放时间',
    released_at                 DATETIME        NULL COMMENT '实际释放时间',
    early_release_reason        VARCHAR(500)    NULL COMMENT '提前释放申请原因',
    early_release_requested_at  DATETIME        NULL COMMENT '提前释放申请时间',
    approved_by                 BIGINT          NULL COMMENT '审批人ID',
    approval_remark             VARCHAR(500)    NULL COMMENT '审批意见',
    created_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_escrow_no (escrow_no),
    UNIQUE KEY uk_escrow_order (order_id),
    INDEX idx_escrow_buyer (buyer_id),
    INDEX idx_escrow_supplier (supplier_id),
    INDEX idx_escrow_status (status),
    INDEX idx_escrow_auto_release (status, auto_release_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单资金托管';

-- 5. 初始化平台钱包账户
INSERT IGNORE INTO t_wallet (owner_id, owner_type, balance, frozen_amount, total_income, total_expense, status)
VALUES (0, 'PLATFORM', 0.00, 0.00, 0.00, 0.00, 'ACTIVE');
