-- Gold adjustments
-- Keep four decimals on prices, as in silver
ALTER TABLE gold.fact_sales ALTER COLUMN unit_price TYPE NUMERIC(12,4);
-- Carry the non-product flag so revenue can exclude postage and fees on purpose
ALTER TABLE gold.fact_sales ADD COLUMN IF NOT EXISTS is_product_line BOOLEAN NOT NULL DEFAULT TRUE;
