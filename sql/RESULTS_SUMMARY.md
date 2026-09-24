# SQL Report — Sample Results

These are actual outputs from running the queries in this folder against the
InsightFlow star schema (loaded from the cleaned `dim_`/`fact_` CSVs). Numbers
will match your Power BI dashboard since both read from the same data.

## Revenue
| Metric | Value |
|---|---|
| Total revenue | R$ 15,843,553.24 |
| Total orders | 98,666 |
| Average order value | R$ 160.58 |

**Top 3 states by revenue:** SP (R$ 5.77M), RJ (R$ 2.05M), MG (R$ 1.82M)

**Top 3 categories by revenue:** beleza_saude (R$ 1.23M), relogios_presentes (R$ 1.17M), cama_mesa_banho (R$ 1.02M)

## Delivery
| Metric | Value |
|---|---|
| On-time delivery rate | 91.89% |
| Average delivery time | 12.56 days |

**Slowest states to deliver to:** RR (29.4 days), AP (27.2 days), AM (26.4 days)

## Customers
| Metric | Value |
|---|---|
| Total unique customers | 96,096 |
| Repeat customers | 2,997 (3.12%) |

## Payments
| Payment type | Transactions | Total value | Avg installments |
|---|---|---|---|
| credit_card | 76,795 | R$ 12,542,084.19 | 3.51 |
| boleto | 19,784 | R$ 2,869,361.27 | 1.00 |
| voucher | 5,775 | R$ 379,436.87 | 1.00 |

## Reviews
| Score | Reviews | % |
|---|---|---|
| 5 | 57,328 | 57.78% |
| 4 | 19,142 | 19.29% |
| 3 | 8,179 | 8.24% |

**Key insight:** average review score is **4.29** for on-time deliveries vs. **2.57** for late ones — delivery speed is the single biggest driver of customer satisfaction in this dataset.

## Top seller
Seller `4869f7a5...` (SP) leads with R$ 229,472.63 in revenue across 1,132 orders and a 4.12 average review score.

---
*Regenerate these numbers anytime with `python scripts/build_db.py` (loads the CSVs into `insightflow.db`) followed by any query in this folder.*
