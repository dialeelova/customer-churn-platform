"""Database helper for notebooks and scripts."""
import os
from decimal import Decimal

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

load_dotenv()


def get_engine():
    url = URL.create(
        "postgresql+psycopg2",
        username=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        host=os.environ.get("PGHOST", "localhost"),
        port=int(os.environ.get("PGPORT", "5432")),
        database=os.environ["PGDATABASE"],
    )
    return create_engine(url)


def query(sql, params=None):
    """Run a SQL query and return a DataFrame. Decimal columns become floats."""
    with get_engine().connect() as conn:
        df = pd.read_sql(text(sql), conn, params=params)
    for col in df.columns:
        if df[col].dtype == object and df[col].map(lambda v: isinstance(v, Decimal)).any():
            df[col] = df[col].astype(float)
    return df
