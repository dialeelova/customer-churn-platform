# Modeling Notes (Part 7)

## Evaluation design
Walk-forward: each monthly snapshot is scored by a model trained only on snapshots whose 90-day outcome was already known. 10 test snapshots, Dec 2010 to Sep 2011. No random splits.

## Results (mean over 10 test snapshots)

| Model | ROC-AUC | PR-AUC | Precision, top 10% | Brier |
|-------|---------|--------|--------------------|-------|
| Recency baseline | 0.674 | 0.680 | 0.755 | n/a |
| Logistic regression | 0.779 | 0.764 | 0.835 | 0.207 |
| XGBoost | 0.767 | 0.752 | 0.813 | 0.214 |
| XGBoost + snapshot month | 0.772 | 0.761 | 0.836 | 0.218 |

Base rate of churn in the test snapshots: 53.3%.

## Main findings
- Logistic regression is the best model. With 16 features the signal is mostly linear, so the simpler model wins.
- Every model beats the recency baseline in every test month.
- Ranking is reliable: the highest-risk decile churned at 81%, the lowest at 10%.
- Calibration depends on the season. Raw probabilities were 23 to 25 points too low for Dec 2010 and Jan 2011 and 3 to 8 points too high for Aug and Sep 2011. Do not use them as absolute churn rates.
- Survival and lifetime value (notebook 05): 27.4% of customers buy once and never return. The BG/NBD purchase forecast was within 1.5% of actual on a six-month holdout, but that window includes the Oct-Nov peak.

## Limitations
- One retailer, about two years of data, no marketing or support data.
- Seasonality: the training window does not contain a December, so the early test months are the hardest.
- Value estimates cover only customers with at least one repeat purchase, and spend is capped at its 99th percentile.
