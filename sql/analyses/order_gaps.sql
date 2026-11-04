-- Days between consecutive purchase days, per customer
SELECT customer_key, gap_days
FROM (
    SELECT customer_key,
           order_date - LAG(order_date) OVER (PARTITION BY customer_key ORDER BY order_date) AS gap_days
    FROM gold.vw_customer_orders
) x
WHERE gap_days IS NOT NULL;
