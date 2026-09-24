/*
===============================================================================
 06 — Reviews & Seller Performance
===============================================================================
*/

-- 6.1 Review score distribution
SELECT
    review_score,
    COUNT(*) AS reviews,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_reviews), 2) AS pct
FROM fact_reviews
GROUP BY review_score
ORDER BY review_score DESC;

-- 6.2 Average review score: on-time vs. late deliveries
SELECT
    CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
         THEN 'On time' ELSE 'Late' END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(*) AS orders
FROM fact_reviews r
JOIN dim_order o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- 6.3 Does leaving a written comment correlate with a lower score?
SELECT
    has_comment,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(*) AS reviews
FROM fact_reviews
GROUP BY has_comment;

-- 6.4 Top 10 sellers by revenue, with order volume and average review score
SELECT
    s.seller_id,
    s.seller_state,
    ROUND(SUM(oi.price), 2)      AS revenue,
    COUNT(DISTINCT oi.order_id)  AS orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM fact_order_items oi
JOIN dim_seller s          ON oi.seller_id = s.seller_id
LEFT JOIN fact_reviews r   ON oi.order_id = r.order_id
GROUP BY s.seller_id, s.seller_state
ORDER BY revenue DESC
LIMIT 10;

-- 6.5 Response time buckets vs. average review score (does a fast reply help?)
SELECT
    response_time_group,
    ROUND(AVG(review_score), 2) AS avg_review_score,
    COUNT(*) AS reviews
FROM fact_reviews
WHERE response_time_group IS NOT NULL
GROUP BY response_time_group
ORDER BY avg_review_score DESC;
