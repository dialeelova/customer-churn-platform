-- Churn rate per monthly snapshot date for one churn definition.
--   :lookback = days of history used to call a customer active
--   :horizon  = days after the snapshot with no purchase = churned
-- Only snapshots with a full lookback window and a fully observed horizon are used.
WITH snapshots AS (
    SELECT g::date AS snapshot_date
    FROM generate_series(DATE '2009-12-01', DATE '2011-12-01', interval '1 month') AS g
    WHERE g::date >= DATE '2009-12-01' + :lookback
      AND g::date + :horizon <= DATE '2011-12-09'
),
active AS (
    SELECT DISTINCT s.snapshot_date, o.customer_key
    FROM snapshots s
    JOIN gold.vw_customer_orders o
      ON o.order_date >= s.snapshot_date - :lookback
     AND o.order_date <  s.snapshot_date
),
labeled AS (
    SELECT a.snapshot_date, a.customer_key,
           NOT EXISTS (
               SELECT 1 FROM gold.vw_customer_orders o2
               WHERE o2.customer_key = a.customer_key
                 AND o2.order_date >= a.snapshot_date
                 AND o2.order_date <  a.snapshot_date + :horizon
           ) AS churned
    FROM active a
)
SELECT snapshot_date,
       COUNT(*) AS active_customers,
       COUNT(*) FILTER (WHERE churned) AS churned_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE churned) / COUNT(*), 1) AS churn_rate_pct
FROM labeled
GROUP BY 1
ORDER BY 1;