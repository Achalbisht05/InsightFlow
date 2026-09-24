/*
===============================================================================
 02 — Revenue Analysis
===============================================================================
*/

-- 2.1 Headline numbers: total revenue, total orders, average order value
SELECT
    ROUND(SUM(price + freight_value), 2) AS total_revenue,
    COUNT(DISTINCT order_id)             AS total_orders,
    ROUND(SUM(price + freight_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM fact_order_items;

-- 2.2 Monthly revenue trend (delivered orders only)
SELECT
    d.year_month,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue,
    COUNT(DISTINCT o.order_id)                 AS orders
FROM fact_order_items oi
JOIN dim_order o ON oi.order_id = o.order_id
JOIN dim_date  d ON o.order_purchase_date = d.date
WHERE o.order_status = 'delivered'
GROUP BY d.year_month
ORDER BY d.year_month;

-- 2.3 Revenue by customer state (top 10)
SELECT
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue,
    COUNT(DISTINCT o.order_id)                 AS orders
FROM fact_order_items oi
JOIN dim_order    o ON oi.order_id = o.order_id
JOIN dim_customer c ON o.customer_unique_id = c.customer_unique_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;

-- 2.4 Top 10 product categories by revenue
SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    COUNT(*)                AS items_sold
FROM fact_order_items oi
JOIN dim_product p ON oi.product_id = p.product_id
JOIN dim_order   o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY product_revenue DESC
LIMIT 10;

-- 2.5 Freight cost as a % of product price, by category (top 10 heaviest freight burden)
SELECT
    p.product_category_name,
    ROUND(SUM(oi.freight_value), 2)                              AS total_freight,
    ROUND(SUM(oi.price), 2)                                      AS total_price,
    ROUND(100.0 * SUM(oi.freight_value) / SUM(oi.price), 2)      AS freight_pct_of_price
FROM fact_order_items oi
JOIN dim_product p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING COUNT(*) > 30
ORDER BY freight_pct_of_price DESC
LIMIT 10;
