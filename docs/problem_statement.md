# Problem Statement

## Business question
Which customers are about to stop buying, how much revenue is at risk, and which customers should the business contact first?

## Who uses this
A retention team at an online retailer with a limited campaign budget. They can contact only a fraction of customers each month, so the ranking of customers matters more than a yes/no label.

## What the project delivers
1. A PostgreSQL warehouse with cleaned, documented data
2. A churn risk score for every active customer
3. An estimate of each customer's future value
4. Revenue at risk and a prioritized contact list
5. A dashboard and an API to explore and serve the results

## Success metrics
**Model metrics**
- PR-AUC (main metric, because churners are a minority)
- Recall among the 10% highest-risk customers
- Brier score (are the probabilities trustworthy?)

**Baseline to beat:** a simple rule where risk rises with days since the last purchase.

**Business metric:** expected revenue saved versus campaign cost, with every assumption stated. Predictions alone do not prove a campaign works, so no causal claims are made without an experiment.

## Out of scope
Real-time streaming, proving campaign effects causally, and any personal customer data.