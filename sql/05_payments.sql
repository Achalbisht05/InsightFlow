/*
===============================================================================
 05 — Payments Analysis
===============================================================================
*/

-- 5.1 Payment method mix: transactions, total value, average installments
SELECT
    payment_type,
    COUNT(*)                        AS transactions,
    ROUND(SUM(payment_value), 2)    AS total_value,
    ROUND(AVG(payment_installments), 2) AS avg_installments
FROM fact_payments
GROUP BY payment_type
ORDER BY total_value DESC;

-- 5.2 Installment distribution for credit card payments
SELECT
    payment_installments,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value), 2) AS total_value
FROM fact_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;

-- 5.3 Average order value by number of installments chosen (does financing = bigger baskets?)
SELECT
    CASE
        WHEN payment_installments = 1 THEN '1 (upfront)'
        WHEN payment_installments BETWEEN 2 AND 4 THEN '2-4'
        WHEN payment_installments BETWEEN 5 AND 8 THEN '5-8'
        ELSE '9+'
    END AS installment_bucket,
    COUNT(*) AS transactions,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM fact_payments
WHERE payment_type = 'credit_card'
GROUP BY installment_bucket
ORDER BY MIN(payment_installments);
