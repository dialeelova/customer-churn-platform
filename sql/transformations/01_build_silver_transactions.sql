-- Build silver.transactions from bronze.online_retail_raw
-- Casts text to proper types, trims text, and adds two flags.
-- Nothing is dropped here except rows missing a required field.
-- Safe to rerun: the table is emptied first.

TRUNCATE TABLE silver.transactions;

INSERT INTO silver.transactions (
    invoice_no, stock_code, description, quantity, invoice_ts,
    unit_price, customer_id, country, line_amount,
    is_cancellation, is_product_line
)
SELECT
    TRIM(invoice),
    UPPER(TRIM(stock_code)),
    NULLIF(TRIM(description), ''),
    quantity::numeric::int,
    invoice_date::timestamp,
    price::numeric,
    NULLIF(TRIM(customer_id), '')::numeric::int,
    NULLIF(TRIM(country), ''),
    ROUND(quantity::numeric * price::numeric, 2),
    TRIM(invoice) LIKE 'C%',
    NOT (
        UPPER(TRIM(stock_code)) IN (
            'POST', 'DOT', 'M', 'C2', 'D', 'S', 'B',
            'BANK CHARGES', 'ADJUST', 'ADJUST2', 'AMAZONFEE',
            'CRUK', 'TEST001', 'TEST002'
        )
        OR UPPER(TRIM(stock_code)) LIKE 'GIFT_%'
    )
FROM bronze.online_retail_raw
WHERE invoice IS NOT NULL
  AND stock_code IS NOT NULL
  AND quantity IS NOT NULL
  AND invoice_date IS NOT NULL
  AND price IS NOT NULL;
-- Flag exact duplicate lines. The first occurrence stays unflagged.
UPDATE silver.transactions t
SET is_duplicate = TRUE
FROM (
    SELECT line_id,
           ROW_NUMBER() OVER (
               PARTITION BY invoice_no, stock_code, quantity, invoice_ts, unit_price, customer_id
               ORDER BY line_id
           ) AS rn
    FROM silver.transactions
) d
WHERE t.line_id = d.line_id AND d.rn > 1;
