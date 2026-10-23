-- Data quality checks for silver.transactions
-- Each row returns the check name, its severity and the number of violating rows.
-- Checks marked error must return 0. Checks marked warn are reported only.

SELECT 'silver_row_count_matches_bronze' AS check_name, 'error' AS severity,
       ABS((SELECT count(*) FROM silver.transactions)
         - (SELECT count(*) FROM bronze.online_retail_raw)) AS violations
UNION ALL
SELECT 'dates_within_expected_range', 'error', count(*)
FROM silver.transactions
WHERE invoice_ts < '2009-12-01' OR invoice_ts >= '2011-12-10'
UNION ALL
SELECT 'line_amount_equals_qty_times_price', 'error', count(*)
FROM silver.transactions
WHERE line_amount <> ROUND(quantity * unit_price, 2)
UNION ALL
SELECT 'cancellation_flag_matches_invoice_prefix', 'error', count(*)
FROM silver.transactions
WHERE is_cancellation <> (invoice_no LIKE 'C%')
UNION ALL
SELECT 'customer_ids_are_positive', 'error', count(*)
FROM silver.transactions
WHERE customer_id <= 0
UNION ALL
SELECT 'invoices_with_multiple_customers', 'warn', count(*)
FROM (SELECT invoice_no FROM silver.transactions
      WHERE customer_id IS NOT NULL
      GROUP BY invoice_no
      HAVING count(DISTINCT customer_id) > 1) x
UNION ALL
SELECT 'customers_with_multiple_countries', 'warn', count(*)
FROM (SELECT customer_id FROM silver.transactions
      WHERE customer_id IS NOT NULL
      GROUP BY customer_id
      HAVING count(DISTINCT country) > 1) y
UNION ALL
SELECT 'customer_rows_with_negative_price', 'warn', count(*)
FROM silver.transactions
WHERE customer_id IS NOT NULL AND unit_price < 0
UNION ALL
SELECT 'customer_noncancel_rows_with_nonpositive_qty', 'warn', count(*)
FROM silver.transactions
WHERE customer_id IS NOT NULL AND NOT is_cancellation AND quantity <= 0
UNION ALL
SELECT 'cancellations_with_positive_qty', 'warn', count(*)
FROM silver.transactions
WHERE is_cancellation AND quantity > 0
ORDER BY severity, check_name;