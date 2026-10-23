"""Run the silver data-quality checks and print PASS, WARN or FAIL per check.

Exits with code 1 if any error-level check has violations,
so a CI pipeline can fail on bad data later.
"""
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import text

from load_bronze import get_engine

CHECKS_FILE = Path("sql/quality/silver_checks.sql")


def main():
    engine = get_engine()
    with engine.connect() as conn:
        results = pd.read_sql(text(CHECKS_FILE.read_text()), conn)

    failed = False
    for row in results.itertuples():
        violations = int(row.violations)
        if violations == 0:
            status = "PASS"
        elif row.severity == "error":
            status = "FAIL"
            failed = True
        else:
            status = "WARN"
        print(f"{status:5} {row.check_name:48} {violations:>10,}")

    print("\nResult:", "FAILED" if failed else "no error-level failures")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()