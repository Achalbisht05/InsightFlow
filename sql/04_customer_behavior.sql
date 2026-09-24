/*
===============================================================================
 04 — Customer Behavior
===============================================================================
*/

-- 4.1 Repeat customer rate
SELECT
    COUNT(*)                                                       AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)               AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_pct
FROM (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS order_count
    FROM dim_order
    GROUP BY customer_unique_id
);

-- 4.2 Top 10 customers by lifetime spend
SELECT
    o.customer_unique_id,
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spent,
    COUNT(DISTINCT o.order_id)                 AS orders
FROM fact_order_items oi
JOIN dim_order    o ON oi.order_id = o.order_id
JOIN dim_customer c ON o.customer_unique_id = c.customer_unique_id
GROUP BY o.customer_unique_id, c.customer_state
ORDER BY total_spent DESC
LIMIT 10;

-- 4.3 Customer count and share by state
SELECT
    customer_state,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dim_customer), 2) AS pct_of_customers
FROM dim_customer
GROUP BY customer_state
ORDER BY customers DESC
LIMIT 10;

-- 4.4 Order volume by day of week (are weekends slower?)
SELECT
    d.day_name,
    d.is_weekend,
    COUNT(DISTINCT o.order_id) AS orders
FROM dim_order o
JOIN dim_date d ON o.order_purchase_date = d.date
GROUP BY d.day_name, d.is_weekend
ORDER BY orders DESC;
