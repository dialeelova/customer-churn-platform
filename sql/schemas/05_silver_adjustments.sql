-- Silver adjustments made after inspecting the loaded data
-- Prices include sub-cent values, so keep four decimals
ALTER TABLE silver.transactions ALTER COLUMN unit_price TYPE NUMERIC(12,4);
-- Exact duplicate lines are flagged, not deleted
ALTER TABLE silver.transactions ADD COLUMN IF NOT EXISTS is_duplicate BOOLEAN NOT NULL DEFAULT FALSE;
