-- 禁用仍保留初始公开密码哈希的管理员。
-- 已经修改过密码的真实管理员不会受影响；新部署也不会留下可登录的默认管理员。
UPDATE t_user
SET status = 'DISABLED'
WHERE username = 'admin'
  AND password = '$2a$10$tF6JB4fPNrrSnGBF78iyq.B0OmNci7eeF1xDAPBj7bOF57bbEX1xO';
