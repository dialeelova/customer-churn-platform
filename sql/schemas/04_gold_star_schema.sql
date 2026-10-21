-- Gold: star schema for analytics and modeling
CREATE TABLE IF NOT EXISTS gold.dim_customer (
    customer_key         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id          INTEGER UNIQUE NOT NULL,
    country              TEXT,
    first_purchase_date  DATE
);

CREATE TABLE IF NOT EXISTS gold.dim_product (
    product_key  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_code   TEXT UNIQUE NOT NULL,
    description  TEXT
);

CREATE TABLE IF NOT EXISTS gold.dim_date (
    date_key      INTEGER PRIMARY KEY,   -- format YYYYMMDD
    full_date     DATE NOT NULL UNIQUE,
    year          SMALLINT NOT NULL,
    quarter       SMALLINT NOT NULL,
    month         SMALLINT NOT NULL,
    week_of_year  SMALLINT NOT NULL,
    day_of_week   SMALLINT NOT NULL,
    is_weekend    BOOLEAN  NOT NULL
);

CREATE TABLE IF NOT EXISTS gold.fact_sales (
    sales_key        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_no       TEXT    NOT NULL,
    date_key         INTEGER NOT NULL REFERENCES gold.dim_date (date_key),
    customer_key     INTEGER NOT NULL REFERENCES gold.dim_customer (customer_key),
    product_key      INTEGER NOT NULL REFERENCES gold.dim_product (product_key),
    quantity         INTEGER NOT NULL,
    unit_price       NUMERIC(12,2) NOT NULL,
    line_amount      NUMERIC(14,2) NOT NULL,
    is_cancellation  BOOLEAN NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_fact_customer ON gold.fact_sales (customer_key);
CREATE INDEX IF NOT EXISTS idx_fact_date ON gold.fact_sales (date_key);
