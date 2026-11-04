-- One row per customer per day with at least one real purchase.
-- Real purchase = not a cancellation, a product line, positive quantity and price.
-- Stored as a materialized view with an index, because churn queries look
-- up each customer's orders many times.
-- After rebuilding gold, refresh it: REFRESH MATERIALIZED VIEW gold.vw_customer_orders;
DROP VIEW IF EXISTS gold.vw_customer_orders;
DROP MATERIALIZED VIEW IF EXISTS gold.vw_customer_orders;

CREATE MATERIALIZED VIEW gold.vw_customer_orders AS
SELECT DISTINCT f.customer_key, d.full_date AS order_date
FROM gold.fact_sales f
JOIN gold.dim_date d ON d.date_key = f.date_key
WHERE NOT f.is_cancellation AND f.is_product_line
  AND f.quantity > 0 AND f.unit_price > 0;

CREATE INDEX idx_customer_orders ON gold.vw_customer_orders (customer_key, order_date);
ANALYZE gold.vw_customer_orders;
