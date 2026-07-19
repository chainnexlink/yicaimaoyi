-- V11: 合同与拍卖关联字段
-- 为合同表添加拍卖ID关联字段，支持从拍卖自动生成合同

-- 1. 为t_contract表添加auction_id字段
ALTER TABLE t_contract ADD COLUMN auction_id BIGINT COMMENT '关联拍卖ID';

-- 2. 添加索引以优化查询
ALTER TABLE t_contract ADD INDEX idx_contract_auction_id (auction_id);
