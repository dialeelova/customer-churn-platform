# Data

Raw data is not stored in Git.

1. Download online_retail_II.xlsx from https://archive.ics.uci.edu/dataset/502/online+retail+ii
2. Place it at data/raw/online_retail_II.xlsx
3. Copy .env.example to .env and set your PostgreSQL password
4. Run in order:
   - psql -U postgres -c "CREATE DATABASE churn_dw;"
   - psql -U postgres -d churn_dw -f each file in sql/schemas/ (01 to 05, in order)
   - py src/ingestion/load_bronze.py
   - psql -U postgres -d churn_dw -f sql/transformations/01_build_silver_transactions.sql
   - py src/ingestion/run_quality_checks.py
