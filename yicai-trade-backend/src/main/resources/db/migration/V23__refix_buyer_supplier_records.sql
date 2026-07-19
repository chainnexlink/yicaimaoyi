-- V23: Re-fix missing t_buyer/t_supplier records for existing users

-- Insert Buyer records for BUYER users who don't have a buyer profile
INSERT INTO t_buyer (user_id, contact_person, contact_phone, created_at, updated_at)
SELECT u.id, COALESCE(u.real_name, u.username), u.phone, NOW(), NOW()
FROM t_user u
WHERE u.user_type = 'BUYER'
AND NOT EXISTS (SELECT 1 FROM t_buyer b WHERE b.user_id = u.id);

-- Insert Supplier records for SUPPLIER users who don't have a supplier profile
INSERT INTO t_supplier (user_id, company_name, contact_person, contact_phone, status, created_at, updated_at)
SELECT u.id, CONCAT(COALESCE(u.real_name, u.username), '的公司'), COALESCE(u.real_name, u.username), u.phone, 'PENDING', NOW(), NOW()
FROM t_user u
WHERE u.user_type = 'SUPPLIER'
AND NOT EXISTS (SELECT 1 FROM t_supplier s WHERE s.user_id = u.id);
