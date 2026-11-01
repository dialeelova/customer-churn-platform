-- Data quality checks for the gold star schema
-- Checks marked error must return 0.

SELECT 'fact_row_count_matches_silver' AS check_name, 'error' AS severity,
       ABS((SELECT count(*) FROM gold.fact_sales)
         - (SELECT count(*) FROM silver.transactions
            WHERE customer_id IS NOT NULL AND NOT is_duplicate)) AS violations
UNION ALL
SELECT 'revenue_matches_silver', 'error',
       ABS(ROUND((SELECT sum(line_amount) FROM gold.fact_sales)
               - (SELECT sum(line_amount) FROM silver.transactions
                  WHERE customer_id IS NOT NULL AND NOT is_duplicate), 2))::bigint
UNION ALL
SELECT 'fact_rows_with_missing_dimension', 'error', count(*)
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c USING (customer_key)
LEFT JOIN gold.dim_product p USING (product_key)
LEFT JOIN gold.dim_date d USING (date_key)
WHERE c.customer_key IS NULL OR p.product_key IS NULL OR d.date_key IS NULL
UNION ALL
SELECT 'duplicate_customer_ids', 'error', count(*)
FROM (SELECT customer_id FROM gold.dim_customer
      GROUP BY customer_id HAVING count(*) > 1) x
UNION ALL
SELECT 'duplicate_stock_codes', 'error', count(*)
FROM (SELECT stock_code FROM gold.dim_product
      GROUP BY stock_code HAVING count(*) > 1) x
UNION ALL
SELECT 'customers_without_purchase_date', 'warn', count(*)
FROM gold.dim_customer WHERE first_purchase_date IS NULL
ORDER BY severity, check_name;