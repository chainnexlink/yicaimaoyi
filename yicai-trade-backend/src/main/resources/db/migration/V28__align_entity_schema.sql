-- Align the production MySQL schema with the JPA model.
-- This migration is intentionally idempotent because MySQL DDL is non-transactional.

DELIMITER $$

CREATE PROCEDURE add_column_if_missing_v28(
    IN p_table_name VARCHAR(64),
    IN p_column_name VARCHAR(64),
    IN p_column_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table_name
          AND column_name = p_column_name
    ) THEN
        SET @ddl_v28 = CONCAT(
            'ALTER TABLE `', REPLACE(p_table_name, '`', '``'),
            '` ADD COLUMN `', REPLACE(p_column_name, '`', '``'),
            '` ', p_column_definition
        );
        PREPARE stmt_v28 FROM @ddl_v28;
        EXECUTE stmt_v28;
        DEALLOCATE PREPARE stmt_v28;
    END IF;
END$$

DELIMITER ;

CREATE TABLE IF NOT EXISTS t_industry (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    name_en VARCHAR(100) NOT NULL,
    sort_order INT NULL,
    status VARCHAR(20) NULL,
    created_at DATETIME(6) NULL,
    updated_at DATETIME(6) NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CALL add_column_if_missing_v28('t_buyer', 'description', 'VARCHAR(1000) NULL');

CALL add_column_if_missing_v28('t_buyer_favorite', 'favorite_type', 'VARCHAR(20) NULL');
CALL add_column_if_missing_v28('t_buyer_favorite', 'product_id', 'BIGINT NULL');
CALL add_column_if_missing_v28('t_buyer_favorite', 'supplier_id', 'BIGINT NULL');

CALL add_column_if_missing_v28('t_contract', 'procurement_mode', 'VARCHAR(30) NULL');
CALL add_column_if_missing_v28('t_contract', 'recommended_suppliers', 'TEXT NULL');
CALL add_column_if_missing_v28('t_contract', 'smart_match_category_code', 'VARCHAR(50) NULL');
CALL add_column_if_missing_v28('t_contract', 'smart_match_product_name', 'VARCHAR(200) NULL');
CALL add_column_if_missing_v28('t_contract', 'smart_match_session_id', 'VARCHAR(100) NULL');

CALL add_column_if_missing_v28('t_inquiry', 'deadline', 'DATETIME(6) NULL');
CALL add_column_if_missing_v28('t_inquiry', 'description', 'VARCHAR(2000) NULL');
CALL add_column_if_missing_v28('t_inquiry', 'expected_quantity', 'INT NULL');
CALL add_column_if_missing_v28('t_inquiry', 'title', 'VARCHAR(200) NOT NULL');
CALL add_column_if_missing_v28('t_inquiry', 'unit', 'VARCHAR(20) NULL');

CALL add_column_if_missing_v28('t_message', 'message_no', 'VARCHAR(30) NULL');
CALL add_column_if_missing_v28('t_message', 'read_time', 'DATETIME(6) NULL');
CALL add_column_if_missing_v28('t_message', 'receiver_name', 'VARCHAR(50) NULL');
CALL add_column_if_missing_v28('t_message', 'sender_name', 'VARCHAR(50) NULL');
CALL add_column_if_missing_v28('t_message', 'status', 'VARCHAR(20) NULL');
CALL add_column_if_missing_v28('t_message', 'type', 'VARCHAR(50) NULL');

CALL add_column_if_missing_v28('t_news', 'auto_generated', 'BIT(1) NULL');
CALL add_column_if_missing_v28('t_news', 'industry_id', 'BIGINT NULL');
CALL add_column_if_missing_v28('t_news', 'industry_name', 'VARCHAR(100) NULL');
CALL add_column_if_missing_v28('t_news', 'lang', 'VARCHAR(10) NULL');

CALL add_column_if_missing_v28('t_quotation', 'description', 'VARCHAR(2000) NULL');
CALL add_column_if_missing_v28('t_quotation', 'total_price', 'DECIMAL(38,2) NULL');
CALL add_column_if_missing_v28('t_quotation', 'unit_price', 'DECIMAL(38,2) NULL');

CALL add_column_if_missing_v28('t_supplier_application', 'business_license', 'VARCHAR(255) NULL');
CALL add_column_if_missing_v28('t_supplier_application', 'description', 'VARCHAR(1000) NULL');
CALL add_column_if_missing_v28('t_supplier_application', 'reject_reason', 'VARCHAR(500) NULL');
CALL add_column_if_missing_v28('t_supplier_application', 'status', 'VARCHAR(20) NULL');

CALL add_column_if_missing_v28('t_supplier', 'business_license', 'VARCHAR(255) NULL');
CALL add_column_if_missing_v28('t_supplier', 'description', 'VARCHAR(1000) NULL');

CALL add_column_if_missing_v28('t_supplier_product', 'image_url', 'VARCHAR(500) NULL');
CALL add_column_if_missing_v28('t_supplier_product', 'min_order_qty', 'INT NULL');
CALL add_column_if_missing_v28('t_supplier_product', 'price', 'DECIMAL(12,2) NULL');
CALL add_column_if_missing_v28('t_supplier_product', 'unit', 'VARCHAR(20) NULL');

DROP PROCEDURE add_column_if_missing_v28;
