"""API tests. They need the database and models/churn_logreg.joblib."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

from api.main import app

client = TestClient(app)

FEATURES = {
    "orders_all": 2, "orders_30d": 0, "orders_90d": 0, "orders_180d": 2,
    "recency_days": 162, "tenure_days": 163, "avg_gap_days": 1.0,
    "recency_to_gap_ratio": 162.0, "spend_180d": 100.97, "spend_all": 100.97,
    "avg_order_value": 50.49, "distinct_products": 3, "cancel_invoices": 1,
    "cancelled_value": 0, "is_uk": 1,
}


def test_health():
    body = client.get("/health").json()
    assert body["status"] == "ok" and body["model_file"] is True


def test_score_known_customer():
    r = client.get("/score/16498")
    assert r.status_code == 200
    assert r.json()["risk_rank"] == 1


def test_score_unknown_customer_returns_404():
    assert client.get("/score/1").status_code == 404


def test_predict_returns_probability():
    r = client.post("/predict", json=FEATURES)
    assert r.status_code == 200
    assert 0.0 <= r.json()["risk_score"] <= 1.0


def test_predict_rejects_recency_above_180():
    assert client.post("/predict", json={**FEATURES, "recency_days": 300}).status_code == 422


def test_predict_handles_missing_gap():
    body = {k: v for k, v in FEATURES.items() if k not in ("avg_gap_days", "recency_to_gap_ratio")}
    assert client.post("/predict", json=body).status_code == 200
