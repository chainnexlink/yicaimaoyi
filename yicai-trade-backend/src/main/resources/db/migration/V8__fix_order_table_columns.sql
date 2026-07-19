-- =====================================================
-- V8: 修复订单相关表字段不匹配问题
-- =====================================================

-- 1. 为 t_order_item 添加缺失的 unit 列
ALTER TABLE t_order_item ADD COLUMN unit VARCHAR(20) DEFAULT '件' COMMENT '单位' AFTER quantity;

-- 2. 为 t_order 添加缺失的 shipping_address 列
-- 注意：V2迁移使用的是 delivery_address，Entity使用 shipping_address
-- 这里添加 shipping_address 列并从 delivery_address 复制数据
ALTER TABLE t_order ADD COLUMN shipping_address VARCHAR(500) COMMENT '收货地址';
UPDATE t_order SET shipping_address = delivery_address WHERE shipping_address IS NULL AND delivery_address IS NOT NULL;
