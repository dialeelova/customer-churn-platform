# Data Notes

**Source:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii), transactions from a UK online gift retailer, roughly December 2009 to December 2011 (exact range confirmed in Part 3).

**Columns:** Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country

## Known limitations (to verify in Part 3)
- Many customers are wholesalers, so behavior differs from ordinary shoppers.
- Some rows have no Customer ID. The share will be measured.
- Cancellations appear as invoices starting with C and negative quantities.
- Non-product stock codes (postage, fees, adjustments) are mixed in.
- Only about two years of history, so seasonality is seen at most twice.
- No marketing, demographic or support data, so causes of churn cannot be modeled.
- One retailer only, so findings may not transfer elsewhere.
## Verified in Part 3

| Item | Result |
|------|--------|
| Rows loaded | 1,067,371 (525,461 + 541,910 across two sheets) |
| Date range | 2009-12-01 to 2011-12-09 |
| Rows without Customer ID | 243,007 (22.8%). Kept in silver, excluded from gold. |
| Cancellation lines | 19,494 |
| Non-product lines (postage, fees, vouchers) | 5,911, flagged with is_product_line = FALSE |
| Exact duplicate lines | 34,337 (3.2%), flagged with is_duplicate = TRUE, not deleted |
| Non-positive quantity, not a cancellation | 3,457 rows, all without a customer (stock write-offs) |
| Non-positive price | 6,207 rows, 6,136 without a customer, the other 71 have a price of exactly 0 |
| Customers with more than one country | 13. Part 4 uses the country of the most recent purchase. |
| Cancellations with positive quantity | 1 (tracked as a warning) |

## Verified in Part 4

| Item | Result |
|------|--------|
| Gold customers / products / fact rows | 5,942 / 4,646 / 797,883 |
| Gold revenue (net of cancellations) | 16,289,439.42, matches silver exactly |
| Sheet overlap | The two Excel sheets share 22,523 rows (1 to 9 Dec 2010). The duplicate flag removes them, so gold counts them once. |
| Customers with no purchase, only cancellations | 61, excluded from churn modeling |
| Month-1 retention | about 15 to 25% for most monthly cohorts |
| Revenue concentration | Champions are 25% of customers and about 69% of RFM revenue |
| Dec 2009 cohort | Inflated, because it includes customers who joined before the data starts |

## Verified in Part 6

| Item | Result |
|------|--------|
| Feature table | gold.churn_features: 47,933 rows, 16 monthly snapshots (Jun 2010 to Sep 2011), 5,212 customers |
| Overall churn rate | 50.9%, varying from 38.0% to 62.3% by snapshot, matching the validated definition |
| Leakage tests | 9 checks in sql/quality/features_checks.sql, including an independent recount of purchase history and an independent recheck of every label |
| Bug found and fixed | avg_order_value divided spend by all invoices instead of real purchase days. Fixed by dividing by purchase days. |
