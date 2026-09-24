"""
etl.py — InsightFlow ETL pipeline

Extracts the raw Olist CSVs, applies the same cleaning and feature-engineering
logic used in notebooks/01_Raw_Data_Exploration.ipynb (data-quality fixes,
review metrics, star-schema design), and loads the result as the
dim_/fact_ CSVs used by the SQL reports and the Power BI dashboard.

This is the reusable, production version of the notebook's cleaning steps —
run this instead of re-executing the full exploratory notebook whenever the
raw data changes.

Usage:
    python etl/etl.py

Input:
    data/raw/olist_customers_dataset.csv
    data/raw/olist_orders_dataset.csv
    data/raw/olist_order_items_dataset.csv
    data/raw/olist_order_payments_dataset.csv
    data/raw/olist_order_reviews_dataset.csv
    data/raw/olist_products_dataset.csv
    data/raw/olist_sellers_dataset.csv
    data/raw/olist_geolocation_dataset.csv (loaded/validated, not exported)
    data/raw/product_category_name_translation.csv (loaded/validated, not exported)

Output (written to data/processed/):
    dim_customer.csv, dim_date.csv, dim_order.csv, dim_product.csv,
    dim_seller.csv, fact_order_items.csv, fact_payments.csv, fact_reviews.csv
"""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
PROCESSED_DIR = ROOT / "data" / "processed"

ORDER_DATE_COLUMNS = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]


def extract():
    """Load all raw Olist tables."""
    customers = pd.read_csv(RAW_DIR / "olist_customers_dataset.csv")
    orders = pd.read_csv(RAW_DIR / "olist_orders_dataset.csv")
    order_items = pd.read_csv(RAW_DIR / "olist_order_items_dataset.csv")
    payments = pd.read_csv(RAW_DIR / "olist_order_payments_dataset.csv")
    reviews = pd.read_csv(RAW_DIR / "olist_order_reviews_dataset.csv")
    products = pd.read_csv(RAW_DIR / "olist_products_dataset.csv")
    sellers = pd.read_csv(RAW_DIR / "olist_sellers_dataset.csv")
    return customers, orders, order_items, payments, reviews, products, sellers


def clean(customers, orders, order_items, payments, reviews, products, sellers):
    """Apply the same cleaning decisions made in Section 24 of the notebook."""
    customers_clean = customers.copy()
    orders_clean = orders.copy()
    order_items_clean = order_items.copy()
    payments_clean = payments.copy()
    reviews_clean = reviews.copy()
    products_clean = products.copy()
    sellers_clean = sellers.copy()

    # Products: missing category -> "Unknown" rather than dropping the rows
    # (these products are still sold and appear in order_items)
    products_clean["product_category_name"] = (
        products_clean["product_category_name"].fillna("Unknown")
    )

    # Orders: parse all date columns to real datetimes
    for col in ORDER_DATE_COLUMNS:
        orders_clean[col] = pd.to_datetime(orders_clean[col], errors="coerce")

    # Reviews: response time + comment features (kept as-is; duplicated
    # review_ids correspond to different orders, so no rows are dropped)
    reviews_clean["review_creation_date"] = pd.to_datetime(
        reviews_clean["review_creation_date"], errors="coerce"
    )
    reviews_clean["review_answer_timestamp"] = pd.to_datetime(
        reviews_clean["review_answer_timestamp"], errors="coerce"
    )
    reviews_clean["review_response_time"] = (
        reviews_clean["review_answer_timestamp"] - reviews_clean["review_creation_date"]
    )
    reviews_clean["response_time_hours"] = (
        reviews_clean["review_response_time"].dt.total_seconds() / 3600
    )

    bins = [0, 24, 48, 72, float("inf")]
    labels = ["< 24 hours", "24–48 hours", "48–72 hours", "72+ hours"]
    reviews_clean["response_time_group"] = pd.cut(
        reviews_clean["response_time_hours"], bins=bins, labels=labels, right=False
    )

    reviews_clean["review_category"] = pd.cut(
        reviews_clean["review_score"], bins=[0, 2, 3, 5], labels=["Negative", "Neutral", "Positive"]
    )

    reviews_clean["comment_length"] = (
        reviews_clean["review_comment_message"].fillna("").astype(str).str.len()
    )
    reviews_clean["comment_word_count"] = (
        reviews_clean["review_comment_message"].fillna("").astype(str).str.split().str.len()
    )
    reviews_clean["has_comment"] = (
        reviews_clean["review_comment_message"].notna()
        & reviews_clean["review_comment_message"].str.strip().ne("")
    )
    reviews_clean["has_title"] = (
        reviews_clean["review_comment_title"].notna()
        & reviews_clean["review_comment_title"].str.strip().ne("")
    )

    return customers_clean, orders_clean, order_items_clean, payments_clean, reviews_clean, products_clean, sellers_clean


def build_dim_date(orders_clean):
    """Build a continuous date dimension spanning the full order date range."""
    all_dates = pd.concat([orders_clean[c] for c in ORDER_DATE_COLUMNS]).dropna()
    date_range = pd.date_range(all_dates.min().normalize(), all_dates.max().normalize(), freq="D")

    dim_date = pd.DataFrame({"date": date_range})
    dim_date["year"] = dim_date["date"].dt.year
    dim_date["quarter"] = "Q" + dim_date["date"].dt.quarter.astype(str)
    dim_date["month_number"] = dim_date["date"].dt.month
    dim_date["month_name"] = dim_date["date"].dt.strftime("%B")
    dim_date["month_short"] = dim_date["date"].dt.strftime("%b")
    dim_date["year_month"] = dim_date["date"].dt.strftime("%Y-%m")
    dim_date["week_number"] = dim_date["date"].dt.isocalendar().week
    dim_date["day"] = dim_date["date"].dt.day
    dim_date["day_name"] = dim_date["date"].dt.strftime("%A")
    dim_date["day_of_week"] = dim_date["date"].dt.dayofweek + 1  # 1 = Monday
    dim_date["is_weekend"] = dim_date["day_of_week"].isin([6, 7])
    dim_date["month_year_sort"] = dim_date["year"] * 100 + dim_date["month_number"]
    dim_date["date"] = dim_date["date"].dt.strftime("%Y-%m-%d")
    return dim_date


def transform_load(customers_clean, orders_clean, order_items_clean, payments_clean,
                    reviews_clean, products_clean, sellers_clean):
    """Build the star schema (Section 25/26 of the notebook) and write CSVs."""

    # customer_id (order-grain) -> customer_unique_id (person-grain) mapping
    id_map = customers_clean.set_index("customer_id")["customer_unique_id"]

    dim_customer = (
        customers_clean[["customer_unique_id", "customer_city", "customer_state"]]
        .drop_duplicates("customer_unique_id")
        .reset_index(drop=True)
    )

    dim_product = (
        products_clean[[
            "product_id", "product_category_name", "product_name_lenght",
            "product_description_lenght", "product_photos_qty",
            "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm",
        ]]
        .drop_duplicates("product_id")
        .reset_index(drop=True)
    )

    dim_seller = (
        sellers_clean[["seller_id", "seller_city", "seller_state"]]
        .drop_duplicates("seller_id")
        .reset_index(drop=True)
    )

    dim_order = orders_clean.copy()
    dim_order["customer_unique_id"] = dim_order["customer_id"].map(id_map)
    dim_order["order_purchase_date"] = dim_order["order_purchase_timestamp"].dt.normalize().dt.strftime("%Y-%m-%d")
    dim_order = dim_order[[
        "order_id", "customer_id", "order_status", "order_purchase_timestamp",
        "order_approved_at", "order_delivered_carrier_date", "order_delivered_customer_date",
        "order_estimated_delivery_date", "customer_unique_id", "order_purchase_date",
    ]]

    dim_date = build_dim_date(orders_clean)

    fact_order_items = order_items_clean[[
        "order_id", "order_item_id", "product_id", "seller_id", "shipping_limit_date", "price", "freight_value",
    ]].copy()

    fact_payments = payments_clean[[
        "order_id", "payment_sequential", "payment_type", "payment_installments", "payment_value",
    ]].copy()

    fact_reviews = reviews_clean[[
        "review_id", "order_id", "review_score", "review_creation_date", "review_answer_timestamp",
        "review_response_time", "response_time_hours", "response_time_group", "review_category",
        "comment_length", "comment_word_count", "has_comment", "has_title",
    ]].copy()

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    outputs = {
        "dim_customer.csv": dim_customer,
        "dim_date.csv": dim_date,
        "dim_order.csv": dim_order,
        "dim_product.csv": dim_product,
        "dim_seller.csv": dim_seller,
        "fact_order_items.csv": fact_order_items,
        "fact_payments.csv": fact_payments,
        "fact_reviews.csv": fact_reviews,
    }
    for filename, df in outputs.items():
        out_path = PROCESSED_DIR / filename
        df.to_csv(out_path, index=False)
        print(f"Wrote {filename:<22} {df.shape[0]:>7} rows -> {out_path}")


def main():
    print("EXTRACT: reading raw Olist CSVs...")
    raw_tables = extract()

    print("\nTRANSFORM: cleaning + feature engineering...")
    cleaned_tables = clean(*raw_tables)

    print("\nLOAD: building star schema and writing processed CSVs...")
    transform_load(*cleaned_tables)

    print("\nETL complete.")


if __name__ == "__main__":
    main()
