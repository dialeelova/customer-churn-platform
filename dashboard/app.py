"""Customer risk dashboard. Reads gold.customer_risk_scores from PostgreSQL."""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

import pandas as pd
import streamlit as st

from src.db import query

st.set_page_config(page_title="Customer churn risk", layout="wide")

# Observed churn rate by risk decile from the walk-forward test (docs/modeling_notes.md,
# notebooks/07_campaign_value.ipynb). Decile 1 = highest risk.
OBSERVED_CHURN = {1: 0.84, 2: 0.80, 3: 0.75, 4: 0.69, 5: 0.62,
                  6: 0.56, 7: 0.47, 8: 0.36, 9: 0.24, 10: 0.08}


@st.cache_data(ttl=600)
def load_scores():
    df = query("""
        SELECT s.customer_id, s.country, s.risk_score, s.risk_rank, s.risk_decile,
               s.recency_days, s.orders_all, s.spend_all, c.spend_180d,
               c.avg_gap_days, c.cancel_invoices
        FROM gold.customer_risk_scores s
        JOIN gold.churn_scoring c USING (customer_key)
        ORDER BY s.risk_rank
    """)
    df["value_90d"] = df["spend_180d"] / 2
    df["observed_churn_rate"] = df["risk_decile"].map(OBSERVED_CHURN)
    df["revenue_at_risk"] = df["observed_churn_rate"] * df["value_90d"]
    return df


df = load_scores()

st.title("Customer churn risk")
st.caption(
    f"Active customers scored as of 10 Dec 2011. Rank customers by risk decile (1 = highest risk). "
    "The raw score is not a reliable churn probability: its calibration depends on the season, "
    "so use the observed churn rate by decile instead."
)

# Sidebar filters
st.sidebar.header("Filters")
deciles = st.sidebar.slider("Risk decile range (1 = highest risk)", 1, 10, (1, 3))
countries = st.sidebar.multiselect("Country", sorted(df["country"].dropna().unique()))
min_spend = st.sidebar.number_input("Minimum spend, last 180 days", min_value=0.0, value=0.0, step=100.0)

view = df[df["risk_decile"].between(*deciles) & (df["spend_180d"] >= min_spend)]
if countries:
    view = view[view["country"].isin(countries)]

# Headline numbers
c1, c2, c3, c4 = st.columns(4)
c1.metric("Active customers scored", f"{len(df):,}")
c2.metric("Customers in selection", f"{len(view):,}")
c3.metric("Expected churners in selection", f"{(view['observed_churn_rate']).sum():,.0f}")
c4.metric("Revenue at risk, 90 days", f"{view['revenue_at_risk'].sum():,.0f}")
st.caption("Revenue at risk = observed churn rate of the decile x half of spend over the last 180 days. "
           "Revenue, not profit. The spend proxy is a guess.")

tab_list, tab_charts, tab_lookup = st.tabs(["Contact list", "Risk overview", "Customer lookup"])

with tab_list:
    st.subheader("Customers in selection, highest risk first")
    cols = ["customer_id", "country", "risk_rank", "risk_decile", "observed_churn_rate",
            "recency_days", "orders_all", "spend_180d", "revenue_at_risk"]
    show = view[cols].rename(columns={"observed_churn_rate": "decile_churn_rate"})
    st.dataframe(show, width="stretch", hide_index=True)
    st.download_button("Download selection as CSV", show.to_csv(index=False).encode("utf-8"),
                       file_name="customers_to_contact.csv", mime="text/csv")

with tab_charts:
    left, right = st.columns(2)
    by_decile = df.groupby("risk_decile").agg(avg_spend_180d=("spend_180d", "mean"),
                                              revenue_at_risk=("revenue_at_risk", "sum"))
    left.subheader("Average spend per customer by risk decile")
    left.bar_chart(by_decile["avg_spend_180d"])
    left.caption("Spend over the last 180 days. The highest-risk customers tend to be low spenders.")
    right.subheader("Revenue at risk by decile")
    right.bar_chart(by_decile["revenue_at_risk"])
    right.caption("Revenue at risk is not highest in decile 1: low churn among big spenders still adds up. "
                  "Targeting by risk alone would miss much of the value.")
    st.subheader("Observed churn rate by decile (walk-forward test)")
    st.bar_chart(pd.Series(OBSERVED_CHURN, name="churn rate"))

with tab_lookup:
    cid = st.number_input("Customer ID", min_value=0, value=int(df["customer_id"].iloc[0]), step=1)
    row = df[df["customer_id"] == cid]
    if row.empty:
        st.info("No active customer with that ID at this snapshot.")
    else:
        r = row.iloc[0]
        a, b, c = st.columns(3)
        a.metric("Risk rank", f"{int(r['risk_rank']):,} of {len(df):,}")
        b.metric("Risk decile", int(r["risk_decile"]))
        c.metric("Decile churn rate", f"{r['observed_churn_rate']:.0%}")
        detail = row[["country", "recency_days", "orders_all", "spend_all", "spend_180d",
                      "avg_gap_days", "cancel_invoices"]].iloc[0]
        st.table(detail.astype(str).rename("value").to_frame())
