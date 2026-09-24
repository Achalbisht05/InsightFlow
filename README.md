# 🛒 InsightFlow — E-Commerce Analytics & Data Engineering Platform

End-to-end analytics project on the **Brazilian E-Commerce Public Dataset by Olist**: raw data is cleaned and modeled into a star schema, explored with Python, queried with SQL, and visualized in an interactive Power BI dashboard.

## Project Architecture

```
Raw CSVs  →  Python (pandas) cleaning & EDA  →  Star schema (dim/fact tables)
                                                        │
                                        ┌───────────────┴───────────────┐
                                        ▼                               ▼
                              SQL analysis (sql_report/)      Power BI dashboard
```

## Repository Structure

```
InsightFlow/
├── data/
│   ├── raw/                     # original Olist CSVs
│   └── processed/               # cleaned dim_/fact_ tables (star schema)
├── notebooks/
│   └── 01_Raw_Data_Exploration.ipynb   # EDA, data quality checks, cleaning
├── sql_report/
│   ├── 01_schema.sql                   # star schema DDL
│   ├── 02_revenue_analysis.sql
│   ├── 03_delivery_performance.sql
│   ├── 04_customer_behavior.sql
│   ├── 05_payments.sql
│   ├── 06_reviews_and_sellers.sql
│   └── RESULTS_SUMMARY.md              # sample output of each query
├── scripts/
│   └── build_db.py              # loads processed CSVs into a local SQLite DB
├── dashboard/
│   └── InsightFlow.pbix         # Power BI dashboard
└── README.md
```

own.
## Dataset

The [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) covers ~100k orders placed between 2016–2018 across multiple marketplaces in Brazil, with data on orders, products, customers, sellers, payments, and reviews.

**Star schema:**
- `dim_customer`, `dim_product`, `dim_seller`, `dim_date` — dimension tables
- `dim_order` — order-grain table linking customers to orders
- `fact_order_items`, `fact_payments`, `fact_reviews` — transactional fact tables

## What each part of the project does

**1. Notebook (`notebook/`)** — Loads the raw Olist tables, profiles them (shape, nulls, duplicates, key uniqueness), cleans and joins them, and builds the resulting dimension/fact tables used by everything downstream.

**2. ETL (`etl/`)** — `etl.py` is the reusable, scripted version of the notebook's cleaning logic: it reads `data/raw` and rebuilds `data/processed` from scratch. `build_db.py` loads `data/processed` into a local SQLite database (`insightflow.db`) so the SQL reports can run against it.

**3. SQL Reports (`sql/`)** — A set of tested, standalone SQL queries answering concrete business questions directly against the star schema: revenue trends, delivery performance, customer repeat-purchase behavior, payment method mix, and review/seller quality. This layer demonstrates the same insights as the dashboard, but reproducible from raw SQL rather than a BI tool.

**4. Power BI Dashboard (`powerbi/InsightFlow.pbix`)** — Interactive dashboard built on the same star schema, for visual exploration and drill-down (revenue by state/time, delivery SLAs, review scores, top sellers/products).

## Key Insights

- **Total revenue:** R$ 15.8M across ~98.7k delivered orders (avg order value R$ 160.58)
- **On-time delivery rate:** 91.9%, averaging 12.6 days from purchase to delivery
- **Delivery speed drives satisfaction:** average review score is 4.29 for on-time orders vs. 2.57 for late ones
- **Low repeat-purchase rate:** only 3.1% of customers order more than once — a retention opportunity
- **Credit card dominates payments:** 76.8k transactions (avg 3.5 installments), well ahead of boleto and vouchers
- **Geographic concentration:** São Paulo alone drives ~36% of total revenue

See [`sql/RESULTS_SUMMARY.md`](sql/RESULTS_SUMMARY.md) for the full breakdown.

## Tech Stack

- **Python** (pandas, numpy, matplotlib, seaborn) — data cleaning & EDA
- **SQL** (SQLite) — business-question queries against the star schema
- **Power BI** — interactive dashboard and DAX measures

## How to Reproduce

```bash
# 1. Clone the repo
git clone https://github.com/Achalbisht05/InsightFlow.git
cd InsightFlow

# 2. Set up Python environment
pip install pandas numpy matplotlib seaborn jupyter

# 3. Run the EDA/cleaning notebook
jupyter notebook notebook/01_Raw_Data_Exploration.ipynb

# 4. Rebuild processed data and the SQLite database
python etl/etl.py
python etl/build_db.py

# 5. Run any SQL report, e.g.:
sqlite3 insightflow.db < sql/02_revenue_analysis.sql

# 6. Open powerbi/InsightFlow.pbix in Power BI Desktop
```

## Dashboard Preview

![InsightFlow Dashboard Overview](reports/overview.png)

[Download the full dashboard (PDF)](reports/InsightFlow_Dashboard.pdf)

The Power BI dashboard covers sales, orders, customers and products from Sep 2016 to Oct 2018.

> **Notes**
> - Dashboard totals (~16.01M sales, ~99K orders) include all order statuses. The SQL analysis (R$15.84M, 98,666 orders) counts delivered orders only, so the figures differ slightly by design.
> - Sales and orders drop to zero at the end of the period because the source data is incomplete for late 2018.

## Author

**Achal Bisht** — [GitHub](https://github.com/Achalbisht05)
