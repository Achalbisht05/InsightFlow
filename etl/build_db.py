"""
build_db.py — Load the cleaned InsightFlow dim_/fact_ CSVs into a local
SQLite database so the queries in sql_report/ can be run and verified.

Usage:
    python scripts/build_db.py

Output:
    insightflow.db (created in the project root)
"""
import sqlite3
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data" / "processed"
DB_PATH = ROOT / "insightflow.db"

TABLES = {
    "dim_customer": "dim_customer.csv",
    "dim_date": "dim_date.csv",
    "dim_order": "dim_order.csv",
    "dim_product": "dim_product.csv",
    "dim_seller": "dim_seller.csv",
    "fact_order_items": "fact_order_items.csv",
    "fact_payments": "fact_payments.csv",
    "fact_reviews": "fact_reviews.csv",
}


def main():
    conn = sqlite3.connect(DB_PATH)
    for table, filename in TABLES.items():
        csv_path = DATA_DIR / filename
        df = pd.read_csv(csv_path)
        df.to_sql(table, conn, if_exists="replace", index=False)
        print(f"Loaded {table:<20} {df.shape[0]:>7} rows  <- {csv_path}")
    conn.close()
    print(f"\nDone. Database written to: {DB_PATH}")


if __name__ == "__main__":
    main()
