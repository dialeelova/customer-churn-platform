# Business Impact (Part 8)

## Question
If a retention team can contact 10% of active customers (347 of 3,471 at 10 Dec 2011), who should it contact, and what could that be worth?

## Method
- Customers are ranked by the logistic regression trained on all labeled snapshots.
- Churn rate by risk decile comes from the walk-forward test (30,814 predictions over 10 snapshots), because raw model scores are not calibrated.
- A churner's value is approximated by their spend over the last 180 days, halved (a 90-day proxy).
- Three strategies are compared: random, top 10% by risk, and top 10% by expected loss (risk score times value).

## Results

| Strategy | Expected churners | Revenue at risk (90 days) |
|----------|-------------------|---------------------------|
| Random 10% | 187 | 72,700 |
| Top 10% by risk | 290 | 29,600 |
| Top 10% by expected loss | 183 | 271,200 |

- Observed churn by decile ranges from 84% (highest risk) to 8% (lowest), and runs 5 to 6 points higher in the December and January snapshots.
- Ranking by risk alone finds the most churners but mostly low-value ones. Ranking by expected loss finds fewer churners but about 3.7 times the revenue at risk of a random group.
- Break-even cost per contact at a 10% save rate: about 78 for the expected-loss strategy and about 21 for a random group. A campaign costing less than the break-even pays for itself in revenue terms.

## Assumptions and limits
- The value proxy is a guess. Churners cannot be observed spending, so true losses may be lower.
- Revenue is not profit.
- The campaign effect is unknown. Scenarios of 5, 10 and 20% saved are shown in the notebook, and a real value needs a randomized holdout test.
- The expected-loss ranking multiplies an uncalibrated risk score by a value proxy, so the ranking is plausible but unproven.
- The snapshot is 10 December, in the post-holiday lull, where predictions were weakest in Part 7.
