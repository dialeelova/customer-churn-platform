-- Features for scoring: same logic as 01_build_features.sql, one snapshot date, no label.
-- The snapshot is the day after the last order in the data.
-- Every feature uses only rows dated before the snapshot.

DROP TABLE IF EXISTS gold.churn_scoring;

CREATE TABLE gold.churn_scoring AS
WITH snap AS (
    SELECT DATE '2011-12-10' AS snapshot_date
),
active AS (
    SELECT DISTINCT s.snapshot_date, o.customer_key
    FROM snap s
    JOIN gold.vw_customer_orders o
      ON o.order_date >= s.snapshot_date - 180
     AND o.order_date <  s.snapshot_date
),
history AS (
    SELECT a.snapshot_date, a.customer_key,
           COUNT(*)                                                      AS orders_all,
           COUNT(*) FILTER (WHERE o.order_date >= a.snapshot_date - 30)  AS orders_30d,
           COUNT(*) FILTER (WHERE o.order_date >= a.snapshot_date - 90)  AS orders_90d,
           COUNT(*) FILTER (WHERE o.order_date >= a.snapshot_date - 180) AS orders_180d,
           a.snapshot_date - MAX(o.order_date)                           AS recency_days,
           a.snapshot_date - MIN(o.order_date)                           AS tenure_days
    FROM active a
    JOIN gold.vw_customer_orders o
      ON o.customer_key = a.customer_key AND o.order_date < a.snapshot_date
    GROUP BY a.snapshot_date, a.customer_key
),
gaps AS (
    SELECT a.snapshot_date, a.customer_key, AVG(x.gap) AS avg_gap_days
    FROM active a
    JOIN (
        SELECT customer_key, order_date,
               order_date - LAG(order_date) OVER (PARTITION BY customer_key ORDER BY order_date) AS gap
        FROM gold.vw_customer_orders
    ) x ON x.customer_key = a.customer_key AND x.order_date < a.snapshot_date
    WHERE x.gap IS NOT NULL
    GROUP BY a.snapshot_date, a.customer_key
),
spend AS (
    SELECT a.snapshot_date, a.customer_key,
           SUM(f.line_amount) FILTER (WHERE NOT f.is_cancellation AND f.is_product_line
                                      AND f.quantity > 0 AND f.unit_price > 0
                                      AND d.full_date >= a.snapshot_date - 180) AS spend_180d,
           SUM(f.line_amount) FILTER (WHERE NOT f.is_cancellation AND f.is_product_line
                                      AND f.quantity > 0 AND f.unit_price > 0) AS spend_all,
           COUNT(DISTINCT f.product_key) FILTER (WHERE NOT f.is_cancellation AND f.is_product_line
                                                 AND f.quantity > 0 AND f.unit_price > 0) AS distinct_products,
           COUNT(DISTINCT f.invoice_no) FILTER (WHERE f.is_cancellation) AS cancel_invoices,
           SUM(-f.line_amount) FILTER (WHERE f.is_cancellation AND f.is_product_line) AS cancelled_value
    FROM active a
    JOIN gold.fact_sales f ON f.customer_key = a.customer_key
    JOIN gold.dim_date d   ON d.date_key = f.date_key AND d.full_date < a.snapshot_date
    GROUP BY a.snapshot_date, a.customer_key
)
SELECT h.snapshot_date,
       h.customer_key,
       EXTRACT(MONTH FROM h.snapshot_date)::int          AS snapshot_month,
       h.orders_all, h.orders_30d, h.orders_90d, h.orders_180d,
       h.recency_days, h.tenure_days,
       COALESCE(g.avg_gap_days, -1)                      AS avg_gap_days,
       ROUND(h.recency_days / NULLIF(g.avg_gap_days, 0), 2) AS recency_to_gap_ratio,
       COALESCE(s.spend_180d, 0)                         AS spend_180d,
       COALESCE(s.spend_all, 0)                          AS spend_all,
       ROUND(COALESCE(s.spend_all, 0) / NULLIF(h.orders_all, 0), 2) AS avg_order_value,
       COALESCE(s.distinct_products, 0)                  AS distinct_products,
       COALESCE(s.cancel_invoices, 0)                    AS cancel_invoices,
       COALESCE(s.cancelled_value, 0)                    AS cancelled_value,
       (c.country = 'United Kingdom')::int              AS is_uk
FROM history h
LEFT JOIN gaps g   USING (snapshot_date, customer_key)
LEFT JOIN spend s  USING (snapshot_date, customer_key)
JOIN gold.dim_customer c ON c.customer_key = h.customer_key;

CREATE INDEX idx_churn_scoring ON gold.churn_scoring (customer_key);
ANALYZE gold.churn_scoring;