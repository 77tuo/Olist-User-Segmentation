-- ============================================================
-- 探索性数据分析
-- 数据集：Olist Brazilian E-Commerce
-- 分析口径：所有金额/订单指标仅基于 'delivered' 状态
-- ============================================================


-- ---------------------------------------------------------
-- 1. 商业总览
-- ---------------------------------------------------------
-- 1.1 总GMV、总订单数、总用户数、客单价
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_unique_customers,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';


-- ---------------------------------------------------------
-- 2. 时间维度
-- ---------------------------------------------------------
-- 2.1 按年-月统计GMV、订单数、客单价
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM olist_orders_dataset o
INNER JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY purchase_month
ORDER BY purchase_month;

-- 2.2 按一周内各天统计订单分布（看周规律）
SELECT
    DAYNAME(o.order_purchase_timestamp) AS weekday_name,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist_orders_dataset o
WHERE o.order_status = 'delivered'
GROUP BY weekday_name
ORDER BY FIELD(weekday_name, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');


-- ---------------------------------------------------------
-- 3. 空间维度
-- ---------------------------------------------------------
-- 3.1 按州统计GMV、订单数、客单价、用户数
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customer_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_gmv,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM olist_orders_dataset o
INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_gmv DESC;


-- ---------------------------------------------------------
-- 4. 订单流转
-- ---------------------------------------------------------
-- 4.1 订单状态分布
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_amount
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY order_status
ORDER BY order_count DESC;


-- ---------------------------------------------------------
-- 5. 品类维度
-- ---------------------------------------------------------
-- 5.1 按品类统计GMV、销量
SELECT
    dpc.category_name_cn AS category_cn,
    COUNT(DISTINCT oi.order_id) AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_gmv,
    COUNT(oi.product_id) AS product_sales_qty
FROM olist_order_items_dataset oi
INNER JOIN olist_products_dataset p ON oi.product_id = p.product_id
INNER JOIN dim_product_category dpc ON p.product_category_name = dpc.product_category_name
INNER JOIN olist_orders_dataset o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY dpc.category_name_cn
ORDER BY total_gmv DESC;


-- ---------------------------------------------------------
-- 6. 用户基底（为后续RFM分层探路）
-- ---------------------------------------------------------
-- 6.1 用户消费金额分段统计
SELECT
    CASE
        WHEN total_spent < 100 THEN 'a: 0-100'
        WHEN total_spent BETWEEN 100 AND 200 THEN 'b: 100-200'
        WHEN total_spent BETWEEN 200 AND 500 THEN 'c: 200-500'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'd: 500-1000'
        WHEN total_spent BETWEEN 1000 AND 5000 THEN 'e: 1000-5000'
        ELSE 'f: > 5000'
    END AS spend_bucket,
    COUNT(*) AS user_count
FROM (
    SELECT 
        c.customer_unique_id, 
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM olist_orders_dataset o
    INNER JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS user_spending
GROUP BY spend_bucket
ORDER BY MIN(total_spent);

-- 6.2 用户购买次数分段统计
SELECT
    CASE
        WHEN u.order_count = 1 THEN '1次'
        WHEN u.order_count = 2 THEN '2次'
        WHEN u.order_count BETWEEN 3 AND 5 THEN '3-5次'
        WHEN u.order_count BETWEEN 6 AND 10 THEN '6-10次'
        ELSE '10次以上'
    END AS frequency_bucket,
    COUNT(*) AS unique_customer_count
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_orders_dataset o
    INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) u
GROUP BY frequency_bucket
ORDER BY MIN(u.order_count);

-- 6.3 总用户数、复购用户数、复购率
SELECT
    COUNT(DISTINCT u.customer_unique_id) AS total_unique_customers,
    COUNT(DISTINCT CASE WHEN u.order_count >= 2 THEN u.customer_unique_id END) AS repeat_unique_customers,
    ROUND(COUNT(DISTINCT CASE WHEN u.order_count >= 2 THEN u.customer_unique_id END) * 100.0
          / COUNT(DISTINCT u.customer_unique_id), 2) AS repeat_purchase_rate
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_orders_dataset o
    INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) u;

-- 6.4 最近一次购买距固定日期的天数分布
SELECT
    CASE
        WHEN recency_days <= 30 THEN '30天内'
        WHEN recency_days BETWEEN 31 AND 90 THEN '31-90天'
        WHEN recency_days BETWEEN 91 AND 180 THEN '91-180天'
        WHEN recency_days BETWEEN 181 AND 365 THEN '181-365天'
        ELSE '365天以上'
    END AS recency_bucket,
    COUNT(*) AS user_count
FROM (
    SELECT 
        c.customer_unique_id,
        DATEDIFF('2018-10-17', MAX(o.order_purchase_timestamp)) AS recency_days
    FROM olist_orders_dataset o
    INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS user_recency
GROUP BY recency_bucket
ORDER BY MIN(recency_days);



-- ---------------------------------------------------------
-- 7. 复购人群品类分布
-- ---------------------------------------------------------
-- 7.1 复购人群（购买>=2次）的品类GMV与销量分布
WITH repeat_buyers AS (
    SELECT c.customer_unique_id
    FROM olist_orders_dataset o
    INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) >= 2
)
SELECT
    dpc.category_name_cn,
    COUNT(DISTINCT oi.order_id) AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_gmv,
    COUNT(oi.product_id) AS product_quantity
FROM olist_order_items_dataset oi
INNER JOIN olist_orders_dataset o ON oi.order_id = o.order_id
INNER JOIN olist_order_customer_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_products_dataset p ON oi.product_id = p.product_id
INNER JOIN dim_product_category dpc ON p.product_category_name = dpc.product_category_name
WHERE o.order_status = 'delivered'
  AND c.customer_unique_id IN (SELECT customer_unique_id FROM repeat_buyers)
GROUP BY dpc.category_name_cn
ORDER BY total_gmv DESC;


-- ---------------------------------------------------------
-- 8. 其他
-- ---------------------------------------------------------
-- 查看消费金额各层级人数及金额情况

WITH ordered AS (
    SELECT 
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue) AS row_num,
        COUNT(*) OVER () AS total_cnt
    FROM user_order_agg
),
percentile_values AS (
    SELECT 
        MAX(CASE WHEN row_num = ROUND(0.99 * total_cnt) THEN total_revenue END) AS p99,
        MAX(CASE WHEN row_num = ROUND(0.95 * total_cnt) THEN total_revenue END) AS p95,
        MAX(CASE WHEN row_num = ROUND(0.90 * total_cnt) THEN total_revenue END) AS p90,
        MAX(CASE WHEN row_num = ROUND(0.80 * total_cnt) THEN total_revenue END) AS p80,
        MAX(CASE WHEN row_num = ROUND(0.70 * total_cnt) THEN total_revenue END) AS p70,
        MAX(CASE WHEN row_num = ROUND(0.60 * total_cnt) THEN total_revenue END) AS p60,
        MAX(CASE WHEN row_num = ROUND(0.50 * total_cnt) THEN total_revenue END) AS p50,
        MAX(CASE WHEN row_num = ROUND(0.40 * total_cnt) THEN total_revenue END) AS p40,
        MAX(CASE WHEN row_num = ROUND(0.30 * total_cnt) THEN total_revenue END) AS p30,
        MAX(CASE WHEN row_num = ROUND(0.20 * total_cnt) THEN total_revenue END) AS p20,
        MAX(CASE WHEN row_num = ROUND(0.10 * total_cnt) THEN total_revenue END) AS p10,
        MAX(CASE WHEN row_num = ROUND(0.05 * total_cnt) THEN total_revenue END) AS p5
    FROM ordered
)
SELECT '99%' AS percentile, p99 AS threshold, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p99) AS user_count FROM percentile_values
UNION ALL
SELECT '95%', p95, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p95) FROM percentile_values
UNION ALL
SELECT '90%', p90, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p90) FROM percentile_values
UNION ALL
SELECT '80%', p80, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p80) FROM percentile_values
UNION ALL
SELECT '70%', p70, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p70) FROM percentile_values
UNION ALL
SELECT '60%', p60, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p60) FROM percentile_values
UNION ALL
SELECT '50%', p50, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p50) FROM percentile_values
UNION ALL
SELECT '40%', p40, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p40) FROM percentile_values
UNION ALL
SELECT '30%', p30, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p30) FROM percentile_values
UNION ALL
SELECT '20%', p20, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p20) FROM percentile_values
UNION ALL
SELECT '10%', p10, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p10) FROM percentile_values
UNION ALL
SELECT '5%', p5, (SELECT COUNT(*) FROM user_order_agg WHERE total_revenue >= p5) FROM percentile_values;