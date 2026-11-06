-- Leakage and sanity checks for gold.churn_features
-- All checks must return 0.

SELECT 'unique_snapshot_customer' AS check_name, 'error' AS severity, count(*) AS violations
FROM (SELECT snapshot_date, customer_key FROM gold.churn_features
      GROUP BY 1, 2 HAVING count(*) > 1) x
UNION ALL
SELECT 'no_missing_labels', 'error', count(*)
FROM gold.churn_features WHERE churned IS NULL
UNION ALL
SELECT 'recency_is_at_least_one_day', 'error', count(*)
FROM gold.churn_features WHERE recency_days < 1
UNION ALL
SELECT 'recency_within_lookback', 'error', count(*)
FROM gold.churn_features WHERE recency_days > 180
UNION ALL
SELECT 'order_counts_are_nested', 'error', count(*)
FROM gold.churn_features
WHERE NOT (orders_30d <= orders_90d AND orders_90d <= orders_180d
           AND orders_180d <= orders_all AND orders_180d >= 1)
UNION ALL
SELECT 'tenure_at_least_recency', 'error', count(*)
FROM gold.churn_features WHERE tenure_days < recency_days
UNION ALL
SELECT 'spend_180d_not_above_total', 'error', count(*)
FROM gold.churn_features WHERE spend_180d > spend_all + 0.01
UNION ALL
-- Leakage test: recount purchase days using only dates before the snapshot
SELECT 'orders_all_matches_independent_count', 'error', count(*)
FROM gold.churn_features f
WHERE f.orders_all <> (SELECT count(*) FROM gold.vw_customer_orders o
                       WHERE o.customer_key = f.customer_key
                         AND o.order_date < f.snapshot_date)
UNION ALL
-- Label test: recheck the 90-day outcome independently
SELECT 'label_matches_independent_check', 'error', count(*)
FROM gold.churn_features f
WHERE (f.churned = 1) <> (NOT EXISTS (
          SELECT 1 FROM gold.vw_customer_orders o
          WHERE o.customer_key = f.customer_key
            AND o.order_date >= f.snapshot_date
            AND o.order_date <  f.snapshot_date + 90))
ORDER BY severity, check_name;