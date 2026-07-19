-- 扩展用户表：邮箱验证、手机验证、微信第三方登录
ALTER TABLE t_user ADD COLUMN email_verified TINYINT(1) DEFAULT 0 COMMENT '邮箱是否已验证: 0=未验证, 1=已验证';
ALTER TABLE t_user ADD COLUMN phone_verified TINYINT(1) DEFAULT 0 COMMENT '手机号是否已验证: 0=未验证, 1=已验证';
ALTER TABLE t_user ADD COLUMN wechat_open_id VARCHAR(100) COMMENT '微信OpenID';
ALTER TABLE t_user ADD COLUMN wechat_union_id VARCHAR(100) COMMENT '微信UnionID';
ALTER TABLE t_user ADD COLUMN login_type VARCHAR(20) DEFAULT 'PASSWORD' COMMENT '注册方式: PASSWORD/EMAIL/PHONE/WECHAT';

CREATE INDEX idx_wechat_open_id ON t_user (wechat_open_id);
CREATE INDEX idx_wechat_union_id ON t_user (wechat_union_id);

-- 第三方接口配置表（后台管理用）
CREATE TABLE IF NOT EXISTS t_third_party_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(50) NOT NULL UNIQUE COMMENT '配置标识: SMS_GATEWAY/EMAIL_SERVICE/WECHAT_OAUTH/LOGISTICS_API',
    config_name VARCHAR(100) NOT NULL COMMENT '配置名称',
    provider VARCHAR(100) COMMENT '服务提供商',
    api_url VARCHAR(500) COMMENT 'API地址',
    app_key VARCHAR(200) COMMENT 'AppKey',
    app_secret VARCHAR(200) COMMENT 'AppSecret',
    app_code VARCHAR(200) COMMENT 'AppCode',
    extra_config TEXT COMMENT '扩展配置(JSON)',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    total_quota INT DEFAULT 0 COMMENT '总配额',
    used_quota INT DEFAULT 0 COMMENT '已使用配额',
    expires_at DATETIME COMMENT '到期时间',
    remark VARCHAR(500) COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key),
    INDEX idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方接口配置表';

-- 第三方接口调用日志表
CREATE TABLE IF NOT EXISTS t_third_party_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(50) NOT NULL COMMENT '配置标识',
    action VARCHAR(50) NOT NULL COMMENT '操作类型: SEND_SMS/SEND_EMAIL/WECHAT_LOGIN/QUERY_LOGISTICS',
    target VARCHAR(200) COMMENT '目标(手机号/邮箱/单号)',
    request_data TEXT COMMENT '请求数据',
    response_data TEXT COMMENT '响应数据',
    success TINYINT(1) DEFAULT 0 COMMENT '是否成功',
    error_msg VARCHAR(500) COMMENT '错误信息',
    cost_ms INT COMMENT '耗时(毫秒)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at),
    INDEX idx_success (success)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='第三方接口调用日志表';

-- 初始化第三方接口配置数据
INSERT INTO t_third_party_config (config_key, config_name, provider, api_url, app_code, enabled, total_quota, used_quota, expires_at, remark) VALUES
('SMS_GATEWAY', '短信验证码服务', '杭州数脉科技(阿里云API市场)', 'https://gyytz.market.alicloudapi.com/sms/smsSend', 'f9cca3cfbe3c49eab64d085bf0e2c282', 1, 20, 0, '2026-04-21 00:00:00', '数脉API三网短信-试用套餐20次'),
('LOGISTICS_API', '全球快递物流查询', '四川涪繁大数据(阿里云API市场)', 'https://wuliu.market.alicloudapi.com/kdi', 'f9cca3cfbe3c49eab64d085bf0e2c282', 1, 100, 0, '2026-04-21 00:00:00', '全球快递物流查询-试用套餐100次'),
('EMAIL_SERVICE', '邮件验证服务', 'SMTP邮件服务', '', '', 0, 0, 0, NULL, '需配置SMTP邮箱信息'),
('WECHAT_OAUTH', '微信开放平台登录', '微信开放平台', 'https://open.weixin.qq.com', '', 0, 0, 0, NULL, '需申请微信开放平台应用');
