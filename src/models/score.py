"""Score active customers at the latest snapshot and save to gold.customer_risk_scores.

The model is the logistic regression trained on all labeled snapshots.
Use risk_rank and risk_decile for targeting. Raw scores are not reliable
absolute churn probabilities (calibration depends on the season).
"""
import pandas as pd

from src.db import get_engine, query
from src.models.churn_models import BASE_FEATURES, load_data, logistic_model


def main():
    train = load_data()
    model = logistic_model().fit(train[BASE_FEATURES], train["churned"])

    scoring = query("SELECT * FROM gold.churn_scoring")
    scoring["has_gap"] = (scoring["avg_gap_days"] >= 0).astype(int)
    scoring["avg_gap_days"] = scoring["avg_gap_days"].where(scoring["avg_gap_days"] >= 0)

    scoring["risk_score"] = model.predict_proba(scoring[BASE_FEATURES])[:, 1]
    scoring["risk_rank"] = scoring["risk_score"].rank(ascending=False, method="first").astype(int)
    scoring["risk_decile"] = pd.qcut(scoring["risk_rank"], 10, labels=range(1, 11)).astype(int)  # 1 = highest risk

    customers = query("SELECT customer_key, customer_id, country FROM gold.dim_customer")
    out = scoring.merge(customers, on="customer_key")[[
        "snapshot_date", "customer_key", "customer_id", "country",
        "risk_score", "risk_rank", "risk_decile",
        "recency_days", "orders_all", "spend_all",
    ]]
    out.to_sql("customer_risk_scores", get_engine(), schema="gold", if_exists="replace", index=False)

    print(f"Scored {len(out):,} active customers at {out['snapshot_date'].iloc[0]}")
    print(out.groupby("risk_decile")["risk_score"].mean().round(3).to_string())


if __name__ == "__main__":
    main()
