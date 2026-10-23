"""Load the raw UCI Online Retail II workbook into bronze.online_retail_raw.

Everything is loaded as text, exactly as it appears in the file.
Cleaning and typing happen later, in the silver layer.
"""
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

RAW_FILE = Path("data/raw/online_retail_II.xlsx")
TARGET_SCHEMA = "bronze"
TARGET_TABLE = "online_retail_raw"

COLUMN_MAP = {
    "Invoice": "invoice",
    "StockCode": "stock_code",
    "Description": "description",
    "Quantity": "quantity",
    "InvoiceDate": "invoice_date",
    "Price": "price",
    "Customer ID": "customer_id",
    "Country": "country",
}


def get_engine():
    load_dotenv()
    url = URL.create(
        "postgresql+psycopg2",
        username=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        host=os.environ.get("PGHOST", "localhost"),
        port=int(os.environ.get("PGPORT", "5432")),
        database=os.environ["PGDATABASE"],
    )
    return create_engine(url)


def main():
    engine = get_engine()

    # Reruns start from an empty table, so rows are never duplicated.
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {TARGET_SCHEMA}.{TARGET_TABLE}"))

    workbook = pd.ExcelFile(RAW_FILE)
    print(f"Sheets found: {workbook.sheet_names}")

    for sheet in workbook.sheet_names:
        print(f"Reading sheet '{sheet}' (a few minutes)...")
        df = workbook.parse(sheet, dtype=str)
        df = df.rename(columns=COLUMN_MAP)
        df["source_file"] = f"{RAW_FILE.name}:{sheet}"
        df.to_sql(
            TARGET_TABLE,
            engine,
            schema=TARGET_SCHEMA,
            if_exists="append",
            index=False,
            chunksize=10000,
            method="multi",
        )
        print(f"Loaded {len(df):,} rows from '{sheet}'")

    print("Done.")


if __name__ == "__main__":
    main()