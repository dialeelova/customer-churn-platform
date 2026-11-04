# Churn Definition

The retailer has no subscriptions, so customers never formally cancel. Here, churn means inactivity.

## Definition (provisional values)
- **Snapshot date T:** a date at which we pretend to make predictions. Only data before T may be used.
- **Active customer:** made at least one purchase in the 180 days before T. Only active customers are scored.
- **Churned (label 1):** an active customer with no purchase in the 90 days after T.
- **Retained (label 0):** an active customer with a purchase in the 90 days after T.

The 180-day and 90-day values are starting points. We will test them in Part 5.

## What counts as a purchase
- Invoices with positive quantity and positive price, linked to a Customer ID
- Cancellations (invoice numbers starting with C) are not purchases. They are kept as a feature.
- Rows without a Customer ID cannot be linked to a customer, so they are left out of the churn model but kept in revenue totals.

## Why a fixed horizon
It is simple to explain and easy to keep free of leakage. A cycle-based alternative (inactive for more than twice the customer's usual gap) will be compared in Part 5.

## Leakage rules
- Features use only data from before T.
- Validation is by time: train on earlier snapshots, test on later ones. No random splits.
- The last usable snapshot is 90 days before the end of the data, because later ones have no complete outcome.

## Known weaknesses
Customers with long natural gaps, such as seasonal buyers or wholesalers, may be labeled as churned and then come back.
## Decision (Part 5)

Kept the 180-day lookback and 90-day horizon.

- The median gap between orders is 32 days, and 81% of observed gaps are under 90 days. Gaps are only observed for customers who returned, so the true share under 90 days is somewhat lower.
- Sensitivity (see notebooks/02_churn_definition.ipynb): a 60-day horizon gives roughly 47 to 71% churn, a 120-day horizon roughly 34 to 56%, and a 365-day lookback roughly 51 to 67%. All follow the same seasonal shape.
- Seasonality: with the chosen definition, churn ranges from 38% (Sep 2010 snapshot) to 62% (Jan 2011 snapshot), because the 90-day window lands in either the Oct-Nov peak or the post-holiday lull.

Consequences for modeling:
- Use monthly snapshots, not one snapshot date.
- Include snapshot month as a feature.
- Evaluate ranking metrics within each snapshot, because base rates differ between snapshots.
