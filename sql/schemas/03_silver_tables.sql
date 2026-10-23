-- Silver: cleaned transactions with proper data types
CREATE TABLE IF NOT EXISTS silver.transactions (
    line_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_no       TEXT        NOT NULL,
    stock_code       TEXT        NOT NULL,
    description      TEXT,
    quantity         INTEGER     NOT NULL,
    invoice_ts       TIMESTAMP   NOT NULL,
    unit_price       NUMERIC(12,4) NOT NULL,
    customer_id      INTEGER,            -- NULL when the source row has no customer
    country          TEXT,
    line_amount      NUMERIC(14,2) NOT NULL,  -- quantity * unit_price
    is_cancellation  BOOLEAN     NOT NULL,   -- invoice number starts with C
    is_product_line  BOOLEAN     NOT NULL    -- FALSE for postage, fees, adjustments
);

CREATE INDEX IF NOT EXISTS idx_silver_tx_customer ON silver.transactions (customer_id);
CREATE INDEX IF NOT EXISTS idx_silver_tx_ts ON silver.transactions (invoice_ts);
