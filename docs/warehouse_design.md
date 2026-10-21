# Warehouse Design

## Layers

```mermaid
flowchart LR
    A[UCI Online Retail II<br/>Excel / CSV] --> B[bronze.online_retail_raw<br/>raw text, as loaded]
    B --> C[silver.transactions<br/>typed, cleaned, flagged]
    C --> D[gold star schema<br/>fact_sales + 3 dimensions]
    D --> E[Features, models, dashboard]
```

| Layer | Purpose | Rule |
|-------|---------|------|
| bronze | Raw copy of the source | All columns are text. Nothing is fixed or dropped. |
| silver | Clean, typed transactions | One row per invoice line. Problems are flagged, not hidden. |
| gold | Star schema for analytics and modeling | Built only from silver. Rows without a customer are excluded. |

## Star schema

```mermaid
erDiagram
    dim_customer ||--o{ fact_sales : places
    dim_product ||--o{ fact_sales : "is sold in"
    dim_date ||--o{ fact_sales : "occurs on"

    fact_sales {
        bigint sales_key PK
        text invoice_no
        int date_key FK
        int customer_key FK
        int product_key FK
        int quantity
        numeric unit_price
        numeric line_amount
        boolean is_cancellation
    }
    dim_customer {
        int customer_key PK
        int customer_id
        text country
        date first_purchase_date
    }
    dim_product {
        int product_key PK
        text stock_code
        text description
    }
    dim_date {
        int date_key PK
        date full_date
        int year
        int quarter
        int month
        int week_of_year
        int day_of_week
        boolean is_weekend
    }
```

**Grain of the fact table:** one row per invoice line.

## Design decisions

| Decision | Reason |
|----------|--------|
| Bronze columns are all TEXT | The raw load can never fail on a bad value. Cleaning happens in silver, where it is visible and testable. |
| Cancellations are kept, with a flag | They carry information about customer behavior and are used as a feature later. |
| Non-product lines (postage, fees) are flagged, not deleted | Revenue totals can include or exclude them on purpose. |
| Rows without a Customer ID stay in silver but not in gold | The churn model needs a customer to score. Revenue reports can still use silver. |
| Surrogate keys in gold | Keeps the fact table small and stable if source IDs change. |
| Indexes on customer and date | Churn features are computed per customer over time windows. |

## Files

SQL definitions are in `sql/schemas/`, numbered in the order they run.
