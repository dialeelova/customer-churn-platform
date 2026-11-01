-- RFM segments as of the last day in the data (2011-12-09).
-- Recency = days since last purchase, Frequency = number of invoices, Monetary = total spend.
-- Scores 1-5 use quintiles (5 = best).
CREATE OR REPLACE VIEW gold.vw_rfm AS
WITH base AS (
    SELECT c.customer_id,
           MAX(d.full_date)             AS last_purchase,
           COUNT(DISTINCT f.invoice_no) AS frequency,
           SUM(f.line_amount)           AS monetary
    FROM gold.fact_sales f
    JOIN gold.dim_customer c ON c.customer_key = f.customer_key
    JOIN gold.dim_date d ON d.date_key = f.date_key
    WHERE NOT f.is_cancellation AND f.is_product_line
      AND f.quantity > 0 AND f.unit_price > 0
    GROUP BY c.customer_id
),
scored AS (
    SELECT *,
           (DATE '2011-12-09' - last_purchase) AS recency_days,
           NTILE(5) OVER (ORDER BY DATE '2011-12-09' - last_purchase DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency) AS f_score,
           NTILE(5) OVER (ORDER BY monetary)  AS m_score
    FROM base
)
SELECT *,
       CASE
           WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
           WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
           WHEN r_score >= 4 AND f_score <= 2 THEN 'New or promising'
           WHEN r_score <= 2 AND f_score >= 4 THEN 'At risk'
           WHEN r_score <= 2 THEN 'Lost'
           ELSE 'Needs attention'
       END AS segment
FROM scored;