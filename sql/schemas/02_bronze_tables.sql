-- Bronze: raw UCI Online Retail II rows, all columns as text
CREATE TABLE IF NOT EXISTS bronze.online_retail_raw (
    invoice       TEXT,
    stock_code    TEXT,
    description   TEXT,
    quantity      TEXT,
    invoice_date  TEXT,
    price         TEXT,
    customer_id   TEXT,
    country       TEXT,
    source_file   TEXT,
    loaded_at     TIMESTAMPTZ DEFAULT now()
);
