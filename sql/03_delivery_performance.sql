/*
===============================================================================
 03 — Delivery Performance
===============================================================================
*/

-- 3.1 Overall on-time delivery rate and average delivery time (days)
SELECT
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date
                            THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_pct,
    ROUND(AVG(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)), 2) AS avg_delivery_days
FROM dim_order
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;

-- 3.2 Average delivery time by customer state (slowest 10)
SELECT
    c.customer_state,
    ROUND(AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)), 2) AS avg_delivery_days,
    COUNT(*) AS orders
FROM dim_order o
JOIN dim_customer c ON o.customer_unique_id = c.customer_unique_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC
LIMIT 10;

-- 3.3 Monthly late-delivery rate trend
SELECT
    d.year_month,
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
    ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_pct
FROM dim_order o
JOIN dim_date d ON o.order_purchase_date = d.date
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY d.year_month
ORDER BY d.year_month;

-- 3.4 Time-to-approval vs. time-to-ship vs. time-to-deliver (funnel breakdown, in days)
SELECT
    ROUND(AVG(julianday(order_approved_at) - julianday(order_purchase_timestamp)), 2)              AS avg_days_to_approve,
    ROUND(AVG(julianday(order_delivered_carrier_date) - julianday(order_approved_at)), 2)           AS avg_days_to_ship,
    ROUND(AVG(julianday(order_delivered_customer_date) - julianday(order_delivered_carrier_date)), 2) AS avg_days_in_transit
FROM dim_order
WHERE order_status = 'delivered'
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;
