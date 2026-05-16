-- ============================================================
-- 项目：Olist 用户分层与流失归因分析
-- 说明：本文件包含所有用于导出 CSV 的查询语句
-- ============================================================

-- 1. 品类销售汇总（category_sales_summary.csv）
-- 查询73个品类的销售额、销量、占比及所属周期
WITH
-- 品类周期分类规则（与视图 vw_user_segmentation_cycle_based 中的 order_cycle 一致）
category_cycle AS (
    SELECT
        product_category_name,
        CASE
            WHEN product_category_name IN (
                'cama_mesa_banho','moveis_decoracao','utilidades_domesticas',
                'informatica_acessorios','automotivo','ferramentas_jardim',
                'bebes','moveis_escritorio','pcs','eletroportateis','eletronicos',
                'consoles_games','construcao_ferramentas_construcao','casa_construcao',
                'eletrodomesticos','eletrodomesticos_2','agro_industria_e_comercio',
                'moveis_sala','casa_conforto','casa_conforto_2','telefonia_fixa',
                'climatizacao','audio','portateis_casa_forno_e_cafe',
                'moveis_cozinha_area_de_servico_jantar_e_jardim',
                'construcao_ferramentas_iluminacao','construcao_ferramentas_seguranca',
                'industria_comercio_e_negocios','construcao_ferramentas_jardim',
                'sinalizacao_e_seguranca','moveis_quarto','moveis_colchao_e_estofado',
                'tablets_impressao_imagem','cine_foto','portateis_cozinha_e_preparadores_de_alimentos',
                'la_cuisine','pc_gamer','telefonia','esporte_lazer','instrumentos_musicais',
                'construcao_ferramentas_ferramentas'
            ) THEN '长'
            WHEN product_category_name IN (
                'relogios_presentes','cool_stuff','perfumaria',
                'fashion_bolsas_e_acessorios','malas_acessorios',
                'papelaria','artes','artes_e_artesanato','artigos_de_natal',
                'artigos_de_festas','musica','cds_dvds_musicais','dvds_blu_ray',
                'livros_interesse_geral','livros_tecnicos','livros_importados',
                'brinquedos','fashion_calcados','fashion_roupa_masculina',
                'fashion_roupa_feminina','fashion_roupa_infanto_juvenil',
                'fashion_underwear_e_moda_praia','fashion_esporte','market_place',
                'seguros_e_servicos'
            ) THEN '中'
            WHEN product_category_name IN (
                'beleza_saude','alimentos','bebidas','alimentos_bebidas',
                'pet_shop','fraldas_higiene','flores'
            ) THEN '短'
            ELSE '中'
        END AS cycle
    FROM olist_products_dataset
    GROUP BY product_category_name
),
-- 按品类汇总已交付订单的销量和销售额
category_sales AS (
    SELECT
        pr.product_category_name,
        COUNT(DISTINCT oi.order_id) AS sales_quantity,
        SUM(oi.price) AS total_amount
    FROM olist_order_items_dataset oi
    JOIN olist_orders_dataset o ON oi.order_id = o.order_id
    JOIN olist_products_dataset pr ON oi.product_id = pr.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY pr.product_category_name
)
SELECT
    d.category_name_cn AS 中文名,
    cs.product_category_name AS 原文名,
    
    cs.sales_quantity AS 销量,
    ROUND(cs.total_amount, 2) AS 销售额,
    ROUND(cs.total_amount / SUM(cs.total_amount) OVER() * 100, 2) AS 销售额百分占比,
    cc.cycle AS 品类周期
FROM category_sales cs
JOIN category_cycle cc ON cs.product_category_name = cc.product_category_name
LEFT JOIN dim_product_category d ON cs.product_category_name = d.product_category_name
ORDER BY cs.total_amount DESC;




-- 2. 细分群体价值表（segment_32_value_table.csv）
-- 查询32个细分群体（短/中/长 × 活跃/沉默/流失 × 低/中/高/超高）的用户数、占比、金额等
WITH
totals AS (
    -- 全局总量：总用户数、总消费金额
    SELECT 
        COUNT(*) AS total_users,
        SUM(M_total) AS total_amount
    FROM vw_user_segmentation_cycle_based
),
grouped AS (
    -- 按品类周期、R状态、M层级聚合
    SELECT 
        last_order_cycle,
        R_segment,
        M_segment,
        COUNT(*) AS user_count,
        SUM(M_total) AS group_amount
    FROM vw_user_segmentation_cycle_based
    GROUP BY last_order_cycle, R_segment, M_segment
)
SELECT 
    g.last_order_cycle,
    g.R_segment,
    g.M_segment,
    g.user_count,
    ROUND(g.user_count / t.total_users * 100, 2) AS user_pct,         -- 用户占比(%)
    ROUND(g.group_amount, 2) AS group_amount,                         -- 消费总额
    ROUND(g.group_amount / t.total_amount * 100, 2) AS amount_pct,    -- 金额占比(%)
    -- 价值倍数 = 金额占比 / 用户占比（>1表示人均贡献高于整体均值）
    ROUND( (g.group_amount / t.total_amount) / (g.user_count / t.total_users), 2 ) AS value_multiple
FROM grouped g
CROSS JOIN totals t
ORDER BY 
    FIELD(g.last_order_cycle, '短', '中', '长'),
    FIELD(g.R_segment, '活跃', '沉默', '流失'),
    FIELD(g.M_segment, '低消费', '中消费', '高消费', '超高消费');
    



-- 3. M阈值分位点验证（M_threshold_summary.csv）
-- 查询四个M层级的用户数、占比、金额、占比、价值倍数
-- 按M维度汇总，防止辛普森悖论
SELECT
    M_segment,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) / MAX(t.total_users) * 100, 2) AS user_pct,
    ROUND(SUM(M_total), 2) AS total_amount,
    ROUND(SUM(M_total) / MAX(t.total_amount) * 100, 2) AS amount_pct,
    ROUND(
        (SUM(M_total) / MAX(t.total_amount)) / (COUNT(*) / MAX(t.total_users)), 
        2
    ) AS value_multiple
FROM vw_user_segmentation_cycle_based
CROSS JOIN (
    SELECT COUNT(*) AS total_users, SUM(M_total) AS total_amount
    FROM vw_user_segmentation_cycle_based
) t
GROUP BY M_segment
ORDER BY FIELD(M_segment, '低消费', '中消费', '高消费', '超高消费');




-- 4. 细分群体标准差（segment_32_stats_with_std.csv）
-- 查询32个细分群体的用户数、平均消费、标准差
SELECT 
    last_order_cycle,
    R_segment,
    M_segment,
    COUNT(*) AS user_count,
    ROUND(AVG(M_total), 2) AS avg_M,
    ROUND(STDDEV(M_total), 2) AS std_M
FROM vw_user_segmentation_cycle_based
GROUP BY last_order_cycle, R_segment, M_segment
ORDER BY 
    FIELD(last_order_cycle, '短', '中', '长'),
    FIELD(R_segment, '活跃', '沉默', '流失'),
    FIELD(M_segment, '低消费', '中消费', '高消费', '超高消费');




-- 5. 新旧模型流失率对比（rfm_comparison.csv）
-- 查询不同口径下的流失用户占比
WITH 
total_users AS (
    SELECT COUNT(*) AS total FROM vw_user_segmentation_cycle_based
)
-- 口径1：固定阈值（365天），所有用户，距今>365天即流失
SELECT 
    '固定阈值(365天)' AS model,
    COUNT(*) AS churn_users,
    ROUND(COUNT(*) / MAX(t.total) * 100, 2) AS churn_pct
FROM vw_user_segmentation_cycle_based
CROSS JOIN total_users t
WHERE DATEDIFF(ref_date, last_order_date) > 365

UNION ALL

-- 口径2：品类周期旧版（长周期也设流失，阈值为540天）
SELECT 
    '品类周期旧版(长周期流失阈值540天)' AS model,
    COUNT(*) AS churn_users,
    ROUND(COUNT(*) / MAX(t.total) * 100, 2) AS churn_pct
FROM vw_user_segmentation_cycle_based
CROSS JOIN total_users t
WHERE R_segment = '流失'  -- 短和中周期正常流失
   OR (last_order_cycle = '长' AND DATEDIFF(ref_date, last_order_date) > 540)  -- 旧版长周期流失定义

UNION ALL

-- 口径3：品类周期最终版（长周期不设流失，>365天仅标记为沉默）
SELECT 
    '品类周期最终版(长周期不设流失)' AS model,
    COUNT(*) AS churn_users,
    ROUND(COUNT(*) / MAX(t.total) * 100, 2) AS churn_pct
FROM vw_user_segmentation_cycle_based
CROSS JOIN total_users t
WHERE R_segment = '流失';  -- 当前视图仅短、中周期有流失标签




-- 6. P0 vs 活跃高价值 订单级数据（churn_p0_vs_active_high_value_comparison.csv）
-- 导出物流天数和评分，用于统计检验
SELECT 
    CASE 
        WHEN v.R_segment = '流失' THEN '短周期-流失-超高消费'
        WHEN v.R_segment = '活跃' THEN '短周期-活跃-超高消费'
    END AS group_label,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
    r.review_score
FROM vw_user_segmentation_cycle_based v
JOIN olist_order_customer_dataset c ON v.customer_unique_id = c.customer_unique_id
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id 
    AND o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_purchase_timestamp IS NOT NULL
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE v.last_order_cycle = '短'
  AND v.M_segment = '超高消费'
  AND v.R_segment IN ('流失', '活跃')
ORDER BY group_label;




-- 7. 评论覆盖率（review_coverage_p0_vs_active_high_value.csv）
-- 查询两组的评论覆盖率
-- 查询短周期-流失-超高消费 vs 短周期-活跃-超高消费 的评论覆盖率
SELECT 
    CASE 
        WHEN v.R_segment = '流失' THEN '短周期-流失-超高消费'
        WHEN v.R_segment = '活跃' THEN '短周期-活跃-超高消费'
    END AS group_label,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN r.review_id IS NOT NULL THEN o.order_id END) AS reviewed_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN r.review_id IS NOT NULL THEN o.order_id END) 
        / COUNT(DISTINCT o.order_id) * 100, 
        2
    ) AS review_coverage_pct
FROM vw_user_segmentation_cycle_based v
JOIN olist_order_customer_dataset c ON v.customer_unique_id = c.customer_unique_id
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id AND o.order_status = 'delivered'
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE v.last_order_cycle = '短'
  AND v.R_segment IN ('流失', '活跃')
  AND v.M_segment = '超高消费'
GROUP BY group_label;




-- 8. 差评原文导出（churn_negative_reviews.csv）
-- 导出P0目标用户的差评原文
-- 统计口径为评分为1或2分且评论内容不为空
SELECT r.review_score, r.review_comment_message
FROM vw_user_segmentation_cycle_based v
JOIN olist_order_customer_dataset c ON v.customer_unique_id = c.customer_unique_id
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id AND o.order_status = 'delivered'
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE v.last_order_cycle = '短'
  AND v.R_segment = '流失'
  AND v.M_segment = '超高消费'
  AND r.review_score <= 2
  AND r.review_comment_message IS NOT NULL AND r.review_comment_message != '';