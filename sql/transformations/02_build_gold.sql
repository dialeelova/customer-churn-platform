-- Build the gold star schema from silver.
-- Rules:
--   * only rows with a Customer ID (the churn model needs a customer)
--   * exact duplicate lines are excluded (flagged in silver)
--   * cancellations and non-product lines are kept, with flags
-- Safe to rerun: all gold tables are emptied first.

TRUNCATE gold.fact_sales, gold.dim_customer, gold.dim_product, gold.dim_date
    RESTART IDENTITY;

-- Date dimension covering the whole data range
INSERT INTO gold.dim_date
    (date_key, full_date, year, quarter, month, week_of_year, day_of_week, is_weekend)
SELECT TO_CHAR(d, 'YYYYMMDD')::int,
       d::date,
       EXTRACT(YEAR FROM d),
       EXTRACT(QUARTER FROM d),
       EXTRACT(MONTH FROM d),
       EXTRACT(WEEK FROM d),
       EXTRACT(ISODOW FROM d),
       EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2009-12-01'::date, '2011-12-09'::date, interval '1 day') AS g(d);

-- Customer dimension: one row per customer.
-- Country comes from the most recent purchase (13 customers have several).
INSERT INTO gold.dim_customer (customer_id, country, first_purchase_date)
SELECT customer_id,
       (ARRAY_AGG(country ORDER BY invoice_ts DESC, line_id DESC))[1],
       (MIN(invoice_ts) FILTER (WHERE NOT is_cancellation))::date
FROM silver.transactions
WHERE customer_id IS NOT NULL AND NOT is_duplicate
GROUP BY customer_id;

-- Product dimension: one row per stock code, with its most common description
INSERT INTO gold.dim_product (stock_code, description)
SELECT stock_code,
       MODE() WITHIN GROUP (ORDER BY description)
FROM silver.transactions
WHERE customer_id IS NOT NULL AND NOT is_duplicate
GROUP BY stock_code;

-- Fact table: one row per invoice line
INSERT INTO gold.fact_sales
    (invoice_no, date_key, customer_key, product_key, quantity,
     unit_price, line_amount, is_cancellation, is_product_line)
SELECT t.invoice_no,
       TO_CHAR(t.invoice_ts, 'YYYYMMDD')::int,
       c.customer_key,
       p.product_key,
       t.quantity,
       t.unit_price,
       t.line_amount,
       t.is_cancellation,
       t.is_product_line
FROM silver.transactions t
JOIN gold.dim_customer c ON c.customer_id = t.customer_id
JOIN gold.dim_product  p ON p.stock_code  = t.stock_code
WHERE t.customer_id IS NOT NULL AND NOT t.is_duplicate;