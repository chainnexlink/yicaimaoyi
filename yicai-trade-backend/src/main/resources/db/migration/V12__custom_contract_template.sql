-- =====================================================
-- 易采贸易平台数据库迁移脚本
-- Version: V12
-- Description: 合同模板增加自定义上传与平台审核功能
-- =====================================================

-- 扩展合同模板表，支持采购商/供应商上传自定义模板并提交平台审核
ALTER TABLE t_contract_template
    ADD COLUMN submitter_type VARCHAR(20) DEFAULT 'PLATFORM' COMMENT '提交方类型: PLATFORM/BUYER/SUPPLIER',
    ADD COLUMN submitter_id BIGINT COMMENT '提交人用户ID',
    ADD COLUMN submitter_name VARCHAR(100) COMMENT '提交人名称（企业名/个人名）',
    ADD COLUMN file_url VARCHAR(500) COMMENT '上传的合同模板文件URL（.docx/.pdf）',
    ADD COLUMN file_name VARCHAR(200) COMMENT '上传文件原始名称',
    ADD COLUMN file_size BIGINT COMMENT '文件大小（字节）',
    ADD COLUMN audit_status VARCHAR(20) DEFAULT 'APPROVED' COMMENT '审核状态: PENDING/APPROVED/REJECTED',
    ADD COLUMN audit_by BIGINT COMMENT '审核人ID',
    ADD COLUMN audit_name VARCHAR(100) COMMENT '审核人姓名',
    ADD COLUMN audit_at DATETIME COMMENT '审核时间',
    ADD COLUMN audit_note TEXT COMMENT '审核意见/驳回原因',
    ADD COLUMN usage_count INT DEFAULT 0 COMMENT '使用次数';

-- 添加索引
ALTER TABLE t_contract_template
    ADD INDEX idx_submitter_type (submitter_type),
    ADD INDEX idx_submitter_id (submitter_id),
    ADD INDEX idx_audit_status (audit_status);
