-- =====================================================
-- 易采贸易平台数据库迁移脚本
-- Version: V4
-- Description: 创建合同管理相关表
-- =====================================================

-- 合同主表
CREATE TABLE IF NOT EXISTS t_contract (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_no VARCHAR(50) NOT NULL UNIQUE COMMENT '合同编号',
    inquiry_id BIGINT COMMENT '关联询价单ID',
    quotation_id BIGINT COMMENT '关联报价单ID',
    buyer_id BIGINT NOT NULL COMMENT '采购商ID',
    supplier_id BIGINT NOT NULL COMMENT '供应商ID',
    
    -- 合同基本信息
    contract_type VARCHAR(20) DEFAULT 'PURCHASE' COMMENT '合同类型: PURCHASE/SERVICE/FRAME',
    contract_title VARCHAR(200) NOT NULL COMMENT '合同标题',
    total_amount DECIMAL(12,2) NOT NULL COMMENT '合同总金额',
    currency VARCHAR(10) DEFAULT 'CNY' COMMENT '币种',
    
    -- 合同内容
    contract_content TEXT COMMENT '合同正文内容',
    template_id BIGINT COMMENT '使用的模板ID',
    
    -- 签署状态
    status VARCHAR(20) DEFAULT 'DRAFT' COMMENT '合同状态: DRAFT/PENDING_BUYER/PENDING_SUPPLIER/SIGNED/EXECUTING/COMPLETED/TERMINATED/CANCELLED',
    buyer_signed BOOLEAN DEFAULT FALSE COMMENT '采购商是否已签署',
    buyer_signed_at DATETIME COMMENT '采购商签署时间',
    buyer_signature TEXT COMMENT '采购商签名数据',
    supplier_signed BOOLEAN DEFAULT FALSE COMMENT '供应商是否已签署',
    supplier_signed_at DATETIME COMMENT '供应商签署时间',
    supplier_signature TEXT COMMENT '供应商签名数据',
    
    -- 履约信息
    start_date DATE COMMENT '合同生效日期',
    end_date DATE COMMENT '合同到期日期',
    delivery_date DATE COMMENT '约定交付日期',
    payment_terms TEXT COMMENT '付款条款（JSON格式）',
    quality_standards TEXT COMMENT '质量标准',
    
    -- 文件存储
    contract_pdf_url VARCHAR(500) COMMENT '合同PDF文件URL',
    contract_hash VARCHAR(128) COMMENT '合同内容哈希（防篡改）',
    
    -- 关联订单
    order_id BIGINT COMMENT '关联订单ID',
    
    -- 平台监管
    platform_reviewed BOOLEAN DEFAULT FALSE COMMENT '平台是否审核',
    platform_reviewer_id BIGINT COMMENT '平台审核人ID',
    platform_reviewed_at DATETIME COMMENT '平台审核时间',
    platform_review_note TEXT COMMENT '平台审核意见',
    
    remark TEXT COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_contract_no (contract_no),
    INDEX idx_inquiry_id (inquiry_id),
    INDEX idx_quotation_id (quotation_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_order_id (order_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    
    CONSTRAINT fk_contract_buyer FOREIGN KEY (buyer_id) REFERENCES t_buyer(id),
    CONSTRAINT fk_contract_supplier FOREIGN KEY (supplier_id) REFERENCES t_supplier(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易合同主表';

-- 合同变更记录表
CREATE TABLE IF NOT EXISTS t_contract_change_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL COMMENT '合同ID',
    change_type VARCHAR(20) NOT NULL COMMENT '变更类型: AMENDMENT/TERMINATION/EXTENSION/PRICE_ADJUSTMENT',
    change_reason TEXT COMMENT '变更原因',
    initiator_type VARCHAR(20) NOT NULL COMMENT '发起方: BUYER/SUPPLIER/PLATFORM',
    initiator_id BIGINT COMMENT '发起人ID',
    initiator_name VARCHAR(100) COMMENT '发起人姓名',
    
    old_content TEXT COMMENT '变更前内容（JSON格式）',
    new_content TEXT COMMENT '变更后内容（JSON格式）',
    
    status VARCHAR(20) DEFAULT 'PENDING' COMMENT '变更状态: PENDING/APPROVED/REJECTED/CANCELLED',
    approver_id BIGINT COMMENT '审批人ID',
    approver_name VARCHAR(100) COMMENT '审批人姓名',
    approved_at DATETIME COMMENT '审批时间',
    approval_note TEXT COMMENT '审批意见',
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_contract_id (contract_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    
    CONSTRAINT fk_change_contract FOREIGN KEY (contract_id) REFERENCES t_contract(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='合同变更记录表';

-- 合同模板表
CREATE TABLE IF NOT EXISTS t_contract_template (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL COMMENT '模板名称',
    template_code VARCHAR(50) NOT NULL UNIQUE COMMENT '模板代码',
    template_type VARCHAR(20) DEFAULT 'STANDARD' COMMENT '模板类型: STANDARD/CUSTOM/INDUSTRY',
    
    template_content TEXT NOT NULL COMMENT '模板内容（支持变量替换）',
    template_variables JSON COMMENT '模板变量定义',
    
    category VARCHAR(50) COMMENT '适用品类',
    industry VARCHAR(50) COMMENT '适用行业',
    
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否启用',
    is_default BOOLEAN DEFAULT FALSE COMMENT '是否默认模板',
    version VARCHAR(20) DEFAULT '1.0' COMMENT '版本号',
    
    description TEXT COMMENT '模板说明',
    
    created_by BIGINT COMMENT '创建人ID',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_template_code (template_code),
    INDEX idx_category (category),
    INDEX idx_is_active (is_active),
    INDEX idx_is_default (is_default)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='合同模板表';

-- 插入默认合同模板
INSERT INTO t_contract_template (template_name, template_code, template_type, template_content, template_variables, category, is_active, is_default, version, description)
VALUES 
('标准采购合同模板', 'STANDARD_PURCHASE', 'STANDARD', 
'【采购合同】

甲方（采购商）：{{buyerName}}
联系地址：{{buyerAddress}}
联系电话：{{buyerPhone}}

乙方（供应商）：{{supplierName}}
联系地址：{{supplierAddress}}
联系电话：{{supplierPhone}}

根据《中华人民共和国合同法》及相关法律法规，甲乙双方在平等、自愿的基础上，就采购事宜达成如下协议：

第一条 产品信息
产品名称：{{productName}}
产品规格：{{productSpecs}}
数量：{{quantity}} {{unit}}
单价：{{unitPrice}} {{currency}}
合同总金额：{{totalAmount}} {{currency}}

第二条 质量标准
产品质量应符合国家相关标准及以下约定：
{{qualityStandards}}

第三条 交付条款
交付日期：{{deliveryDate}}
交付地点：{{deliveryAddress}}
运输方式：{{shippingMethod}}
运费承担：{{freightTerms}}

第四条 付款方式
{{paymentTerms}}

第五条 验收标准
1. 甲方应在收货后{{inspectionDays}}个工作日内完成验收
2. 验收不合格的，乙方应在{{rectificationDays}}个工作日内完成整改或更换

第六条 违约责任
1. 乙方逾期交付的，每逾期一日应向甲方支付合同总额{{penaltyRate}}%的违约金
2. 甲方逾期付款的，每逾期一日应向乙方支付应付金额{{penaltyRate}}%的滞纳金

第七条 争议解决
因本合同引起的或与本合同有关的争议，双方应友好协商解决；协商不成的，提交平台调解或向合同签订地人民法院起诉。

第八条 其他约定
{{otherTerms}}

本合同自双方签署之日起生效。

甲方（采购商）电子签名：{{buyerSignature}}
签署时间：{{buyerSignedAt}}

乙方（供应商）电子签名：{{supplierSignature}}
签署时间：{{supplierSignedAt}}

【平台监管】易采贸易平台
合同编号：{{contractNo}}
生成时间：{{createdAt}}', 
'{"buyerName": "采购商名称", "buyerAddress": "采购商地址", "buyerPhone": "采购商电话", "supplierName": "供应商名称", "supplierAddress": "供应商地址", "supplierPhone": "供应商电话", "productName": "产品名称", "productSpecs": "产品规格", "quantity": "数量", "unit": "单位", "unitPrice": "单价", "currency": "币种", "totalAmount": "总金额", "qualityStandards": "质量标准", "deliveryDate": "交付日期", "deliveryAddress": "交付地址", "shippingMethod": "运输方式", "freightTerms": "运费条款", "paymentTerms": "付款条款", "inspectionDays": "验收天数", "rectificationDays": "整改天数", "penaltyRate": "违约金率", "otherTerms": "其他约定", "contractNo": "合同编号", "createdAt": "创建时间"}',
NULL, TRUE, TRUE, '1.0', '适用于一般产品采购的标准合同模板');
