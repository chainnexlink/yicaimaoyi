-- V20: 合同签章简化 + 纸质合同上传审核
-- 1. 合同表添加纸质合同上传和审核字段
ALTER TABLE t_contract ADD COLUMN physical_contract_url VARCHAR(500) DEFAULT NULL COMMENT '纸质合同扫描件URL';
ALTER TABLE t_contract ADD COLUMN physical_contract_uploaded_at DATETIME DEFAULT NULL COMMENT '纸质合同上传时间';
ALTER TABLE t_contract ADD COLUMN contract_review_status VARCHAR(20) DEFAULT NULL COMMENT '合同审核状态: PENDING_UPLOAD/PENDING_REVIEW/APPROVED/REJECTED';
ALTER TABLE t_contract ADD COLUMN contract_reviewed_by BIGINT DEFAULT NULL COMMENT '合同审核人ID';
ALTER TABLE t_contract ADD COLUMN contract_reviewed_at DATETIME DEFAULT NULL COMMENT '合同审核时间';
ALTER TABLE t_contract ADD COLUMN contract_review_note TEXT DEFAULT NULL COMMENT '合同审核备注';
ALTER TABLE t_contract ADD COLUMN buyer_sign_ip VARCHAR(50) DEFAULT NULL COMMENT '采购商签署IP';
ALTER TABLE t_contract ADD COLUMN supplier_sign_ip VARCHAR(50) DEFAULT NULL COMMENT '供应商签署IP';

-- 2. 订单表添加合同审核相关状态
ALTER TABLE t_order ADD COLUMN contract_review_status VARCHAR(20) DEFAULT NULL COMMENT '关联合同审核状态';
