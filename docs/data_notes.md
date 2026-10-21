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