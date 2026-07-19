-- V22: Fix missing t_buyer records for existing BUYER users

-- Insert Buyer records for BUYER users who don't have one
INSERT INTO t_buyer (user_id, contact_person, contact_phone, created_at, updated_at)
SELECT u.id, u.real_name, u.phone, NOW(), NOW()
FROM t_user u
WHERE u.user_type = 'BUYER'
AND NOT EXISTS (SELECT 1 FROM t_buyer b WHERE b.user_id = u.id);
