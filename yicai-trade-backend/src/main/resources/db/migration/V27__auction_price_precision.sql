-- Cross-border sourcing often quotes low-value components below USD 0.01 per unit.
-- Preserve four decimal places throughout the reverse-auction lifecycle.
ALTER TABLE t_auction MODIFY COLUMN starting_price DECIMAL(16,4) NULL;
ALTER TABLE t_auction MODIFY COLUMN current_lowest_price DECIMAL(16,4) NULL;
ALTER TABLE t_auction MODIFY COLUMN min_decrement DECIMAL(16,4) DEFAULT 1.0000;
ALTER TABLE t_auction MODIFY COLUMN reserve_price DECIMAL(16,4) NULL;
ALTER TABLE t_auction MODIFY COLUMN reference_price DECIMAL(16,4) NULL;
ALTER TABLE t_auction MODIFY COLUMN winning_price DECIMAL(16,4) NULL;
ALTER TABLE t_auction_bid MODIFY COLUMN bid_price DECIMAL(16,4) NOT NULL;
ALTER TABLE t_auction_bid MODIFY COLUMN total_amount DECIMAL(18,4) NULL;
