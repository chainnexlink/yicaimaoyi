-- Preserve the meaning of existing amounts while allowing all newly-created
-- orders to explicitly select an ISO-4217 currency in application code.
ALTER TABLE t_order ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'CNY';
ALTER TABLE t_payment ADD COLUMN currency VARCHAR(3) NOT NULL DEFAULT 'CNY';

