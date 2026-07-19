-- V24: 清除第三方接口配置表中硬编码的AppCode
-- 安全修复：敏感信息不应存储在数据库初始化脚本中，应通过环境变量注入
UPDATE t_third_party_config SET app_code = '' WHERE config_key IN ('SMS_GATEWAY', 'LOGISTICS_API') AND app_code = 'f9cca3cfbe3c49eab64d085bf0e2c282';
