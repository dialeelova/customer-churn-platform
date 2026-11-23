"""Churn risk API.

Run:  uvicorn api.main:app --reload
Docs: http://localhost:8000/docs
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text

from src.db import get_engine

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "churn_logreg.joblib"
NOTE = ("Use the score to rank customers. It is not a reliable churn probability: "
        "calibration depends on the season.")

app = FastAPI(title="Customer churn risk API", version="0.1.0")
_artifact = None


def get_artifact():
    global _artifact
    if _artifact is None:
        if not MODEL_PATH.exists():
            raise HTTPException(503, "Model file not found. Run: py -m src.models.train_final")
        _artifact = joblib.load(MODEL_PATH)
    return _artifact


class CustomerFeatures(BaseModel):
    orders_all: int = Field(ge=1, description="Purchase days before the snapshot")
    orders_30d: int = Field(ge=0)
    orders_90d: int = Field(ge=0)
    orders_180d: int = Field(ge=1)
    recency_days: int = Field(ge=1, le=180, description="Days since last purchase")
    tenure_days: int = Field(ge=1)
    avg_gap_days: float | None = Field(default=None, ge=0,
                                       description="Average days between purchases; omit if only one purchase day")
    recency_to_gap_ratio: float | None = Field(default=None, ge=0)
    spend_180d: float = Field(ge=0)
    spend_all: float = Field(ge=0)
    avg_order_value: float = Field(ge=0)
    distinct_products: int = Field(ge=0)
    cancel_invoices: int = Field(ge=0)
    cancelled_value: float = Field(ge=0)
    is_uk: int = Field(ge=0, le=1)


@app.get("/health")
def health():
    try:
        with get_engine().connect() as conn:
            conn.execute(text("SELECT 1"))
        db = "ok"
    except Exception:
        db = "unreachable"
    return {"status": "ok", "database": db, "model_file": MODEL_PATH.exists()}


@app.get("/score/{customer_id}")
def score(customer_id: int):
    with get_engine().connect() as conn:
        row = conn.execute(
            text("SELECT customer_id, snapshot_date, risk_score, risk_rank, risk_decile "
                 "FROM gold.customer_risk_scores WHERE customer_id = :cid"),
            {"cid": customer_id},
        ).mappings().first()
    if row is None:
        raise HTTPException(404, "No active customer with that ID at the scoring snapshot")
    return {**dict(row), "snapshot_date": str(row["snapshot_date"]), "note": NOTE}


@app.post("/predict")
def predict(features: CustomerFeatures):
    art = get_artifact()
    data = features.model_dump()
    data["has_gap"] = 0 if data["avg_gap_days"] is None else 1
    frame = pd.DataFrame([data])[art["features"]]
    risk = float(art["model"].predict_proba(frame)[0, 1])
    return {"risk_score": round(risk, 4),
            "model_trained_through_snapshot": art["last_snapshot"],
            "note": NOTE}
