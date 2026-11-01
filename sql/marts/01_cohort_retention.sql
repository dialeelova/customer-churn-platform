-- Cohort retention: of the customers who first bought in month X,
-- what share bought again N months later?
-- Caveat: the Dec 2009 cohort includes customers who joined before the data starts.
CREATE OR REPLACE VIEW gold.vw_cohort_retention AS
WITH purchases AS (
    SELECT DISTINCT f.customer_key,
           DATE_TRUNC('month', d.full_date)::date AS purchase_month
    FROM gold.fact_sales f
    JOIN gold.dim_date d ON d.date_key = f.date_key
    WHERE NOT f.is_cancellation AND f.is_product_line
      AND f.quantity > 0 AND f.unit_price > 0
),
cohorts AS (
    SELECT customer_key, MIN(purchase_month) AS cohort_month
    FROM purchases GROUP BY customer_key
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohorts GROUP BY cohort_month
),
activity AS (
    SELECT c.cohort_month,
           (EXTRACT(YEAR FROM p.purchase_month) * 12 + EXTRACT(MONTH FROM p.purchase_month)
          - EXTRACT(YEAR FROM c.cohort_month) * 12 - EXTRACT(MONTH FROM c.cohort_month))::int AS month_number,
           COUNT(*) AS active_customers
    FROM purchases p
    JOIN cohorts c USING (customer_key)
    GROUP BY 1, 2
)
SELECT a.cohort_month, a.month_number, s.cohort_size, a.active_customers,
       ROUND(100.0 * a.active_customers / s.cohort_size, 1) AS retention_pct
FROM activity a
JOIN cohort_sizes s USING (cohort_month);