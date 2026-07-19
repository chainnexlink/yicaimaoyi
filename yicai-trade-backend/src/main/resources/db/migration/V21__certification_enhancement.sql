-- 企业资质认证表增强：增加详细的企业信息、法人信息、联系人信息字段
ALTER TABLE t_certification
    ADD COLUMN user_id BIGINT COMMENT '申请用户ID' AFTER cert_no,
    ADD COLUMN credit_code VARCHAR(30) COMMENT '统一社会信用代码' AFTER company_name,
    ADD COLUMN company_type VARCHAR(50) COMMENT '企业类型' AFTER credit_code,
    ADD COLUMN registered_capital VARCHAR(50) COMMENT '注册资本' AFTER company_type,
    ADD COLUMN found_date DATE COMMENT '成立日期' AFTER registered_capital,
    ADD COLUMN company_address VARCHAR(500) COMMENT '企业地址' AFTER found_date,
    ADD COLUMN legal_name VARCHAR(50) COMMENT '法人姓名' AFTER company_address,
    ADD COLUMN legal_id_number VARCHAR(30) COMMENT '法人身份证号' AFTER legal_name,
    ADD COLUMN legal_phone VARCHAR(20) COMMENT '法人手机号' AFTER legal_id_number,
    ADD COLUMN legal_id_front VARCHAR(500) COMMENT '法人身份证正面照URL' AFTER legal_phone,
    ADD COLUMN legal_id_back VARCHAR(500) COMMENT '法人身份证反面照URL' AFTER legal_id_front,
    ADD COLUMN business_license VARCHAR(500) COMMENT '营业执照URL' AFTER legal_id_back,
    ADD COLUMN other_certs VARCHAR(2000) COMMENT '其他资质证书URL(JSON数组)' AFTER business_license,
    ADD COLUMN contact_name VARCHAR(50) COMMENT '联系人姓名' AFTER other_certs,
    ADD COLUMN contact_title VARCHAR(50) COMMENT '联系人职务' AFTER contact_name,
    ADD COLUMN contact_phone VARCHAR(20) COMMENT '联系人手机' AFTER contact_title,
    ADD COLUMN contact_email VARCHAR(100) COMMENT '联系人邮箱' AFTER contact_phone,
    ADD COLUMN audited_by VARCHAR(50) COMMENT '审核人' AFTER audit_remark;

CREATE INDEX idx_cert_user ON t_certification (user_id);
