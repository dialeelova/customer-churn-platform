"""Walk-forward evaluation of churn models on gold.churn_features.

To score the snapshot of month T, a model is trained only on snapshots whose
90-day outcome was already known on T (snapshot_date + 90 days <= T).
There are no random splits.
"""
import numpy as np
import pandas as pd
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, brier_score_loss, roc_auc_score
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import FunctionTransformer, StandardScaler
from xgboost import XGBClassifier

from src.db import query

HORIZON_DAYS = 90
MIN_TRAIN_SNAPSHOTS = 4

BASE_FEATURES = [
    "orders_all", "orders_30d", "orders_90d", "orders_180d",
    "recency_days", "tenure_days", "avg_gap_days", "recency_to_gap_ratio",
    "spend_180d", "spend_all", "avg_order_value", "distinct_products",
    "cancel_invoices", "cancelled_value", "is_uk", "has_gap",
]


def load_data():
    df = query("SELECT * FROM gold.churn_features ORDER BY snapshot_date, customer_key")
    df["snapshot_date"] = pd.to_datetime(df["snapshot_date"])
    # SQL used -1 for "no purchase gap yet": make it a real missing value plus an indicator
    df["has_gap"] = (df["avg_gap_days"] >= 0).astype(int)
    df["avg_gap_days"] = df["avg_gap_days"].where(df["avg_gap_days"] >= 0)
    return df


def signed_log(x):
    return np.sign(x) * np.log1p(np.abs(x))


def logistic_model():
    return make_pipeline(
        SimpleImputer(strategy="median"),
        FunctionTransformer(signed_log),
        StandardScaler(),
        LogisticRegression(max_iter=1000),
    )


def xgboost_model():
    return XGBClassifier(
        n_estimators=300, max_depth=4, learning_rate=0.05,
        subsample=0.8, colsample_bytree=0.8,
        eval_metric="logloss", n_jobs=2, random_state=42,
    )


# (name, features, builder). The baseline has no model: higher recency = higher risk.
MODELS = [
    ("recency baseline", None, None),
    ("logistic regression", BASE_FEATURES, logistic_model),
    ("xgboost", BASE_FEATURES, xgboost_model),
    ("xgboost + month", BASE_FEATURES + ["snapshot_month"], xgboost_model),
]


def top_decile(y, score, frac=0.10):
    """Recall and precision among the highest-risk 10% of customers."""
    k = max(1, int(round(len(y) * frac)))
    top = np.argsort(-score)[:k]
    caught = y[top].sum()
    return caught / y.sum(), caught / k


def walk_forward(df):
    results, predictions = [], []
    for test_date in sorted(df["snapshot_date"].unique()):
        test_date = pd.Timestamp(test_date)
        train = df[df["snapshot_date"] <= test_date - pd.Timedelta(days=HORIZON_DAYS)]
        if train["snapshot_date"].nunique() < MIN_TRAIN_SNAPSHOTS:
            continue
        test = df[df["snapshot_date"] == test_date]
        y = test["churned"].to_numpy()

        for name, features, build in MODELS:
            if build is None:
                score = test["recency_days"].to_numpy(dtype=float)
                brier = np.nan
            else:
                model = build()
                model.fit(train[features], train["churned"])
                score = model.predict_proba(test[features])[:, 1]
                brier = brier_score_loss(y, score)

            recall10, precision10 = top_decile(y, score)
            results.append({
                "snapshot_date": test_date, "model": name, "n": len(y),
                "base_rate": y.mean(),
                "pr_auc": average_precision_score(y, score),
                "roc_auc": roc_auc_score(y, score),
                "recall_top10": recall10, "precision_top10": precision10,
                "brier": brier,
            })
            predictions.append(pd.DataFrame({
                "snapshot_date": test_date, "customer_key": test["customer_key"].to_numpy(),
                "model": name, "score": score, "churned": y,
            }))
    return pd.DataFrame(results), pd.concat(predictions, ignore_index=True)


def summarize(results):
    summary = results.groupby("model").agg(
        pr_auc=("pr_auc", "mean"),
        roc_auc=("roc_auc", "mean"),
        precision_top10=("precision_top10", "mean"),
        recall_top10=("recall_top10", "mean"),
        brier=("brier", "mean"),
        base_rate=("base_rate", "mean"),
    )
    summary["lift_top10"] = summary["precision_top10"] / summary["base_rate"]
    return summary.reindex([m[0] for m in MODELS]).round(3)


if __name__ == "__main__":
    data = load_data()
    print(f"{len(data):,} rows, {data['snapshot_date'].nunique()} snapshots")
    results, _ = walk_forward(data)
    print(f"Test snapshots: {results['snapshot_date'].nunique()}\n")
    print(summarize(results).to_string())
    print("\nROC-AUC by test snapshot:")
    print(results.pivot(index="snapshot_date", columns="model", values="roc_auc").round(3).to_string())