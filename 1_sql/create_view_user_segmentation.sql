-- ============================================================
-- 增强视图：vw_user_segmentation_cycle_based
-- 说明：基于品类购买周期动态定义R活跃度，结合消费金额M分层
-- 新增字段：总订单数、首购日期、是否复购、首购品类周期
-- 参考日期：2018-10-17
-- 长周期（耐消品）：仅活跃(≤365天)与沉默(>365天)，不设流失
-- 中周期（半耐用）：活跃≤180，沉默181-365，流失>365
-- 短周期（快消品）：活跃≤90，沉默91-180，流失>180
-- 长周期（耐消品）：62.68%，中周期（半耐用）：21.50%，短周期（快消品）：15.82%
-- R活跃度分层基于最近订单的品类周期
-- ============================================================
CREATE OR REPLACE VIEW vw_user_segmentation_cycle_based AS

WITH 
-- 1. 固定分析参考日期
ref_date AS (
    SELECT '2018-10-17' AS analysis_date
),

-- 2. 已交付订单及其支付总金额（订单级）
delivered_orders AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_delivered_customer_date,
        SUM(p.payment_value) AS order_amount
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, o.customer_id, o.order_delivered_customer_date
),

-- 3. 每个订单的品类周期标签（取订单内所有商品的最长周期：长 > 中 > 短）
order_cycle AS (
    SELECT 
        oi.order_id,
        CASE 
            WHEN MAX(CASE WHEN pr.product_category_name IN (
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
                ) THEN 3 ELSE 0 END) = 3 THEN '长'
            
            WHEN MAX(CASE WHEN pr.product_category_name IN (
                    'relogios_presentes','cool_stuff','perfumaria',
                    'fashion_bolsas_e_acessorios','malas_acessorios',
                    'papelaria','artes','artes_e_artesanato','artigos_de_natal',
                    'artigos_de_festas','musica','cds_dvds_musicais','dvds_blu_ray',
                    'livros_interesse_geral','livros_tecnicos','livros_importados',
                    'brinquedos','fashion_calcados','fashion_roupa_masculina',
                    'fashion_roupa_feminina','fashion_roupa_infanto_juvenil',
                    'fashion_underwear_e_moda_praia','fashion_esporte','market_place',
                    'seguros_e_servicos'
                ) THEN 2 ELSE 0 END) = 2 THEN '中'
            
            WHEN MAX(CASE WHEN pr.product_category_name IN (
                    'beleza_saude','alimentos','bebidas','alimentos_bebidas',
                    'pet_shop','fraldas_higiene','flores'
                ) THEN 1 ELSE 0 END) = 1 THEN '短'
            
            ELSE '中'
        END AS cycle
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset pr ON oi.product_id = pr.product_id
    GROUP BY oi.order_id
),

-- 4. 每个客户的历史总消费M、最近一次购买信息、总订单数、首购日期
user_rfm AS (
    SELECT 
        c.customer_unique_id,
        SUM(do.order_amount) AS M_total,
        MAX(do.order_delivered_customer_date) AS last_order_date,
        COUNT(DISTINCT do.order_id) AS total_orders,
        MIN(do.order_delivered_customer_date) AS first_order_date
    FROM olist_order_customer_dataset c
    JOIN delivered_orders do ON c.customer_id = do.customer_id
    GROUP BY c.customer_unique_id
),

-- 5. 获取每个客户最近一次订单的周期标签
last_order_cycle AS (
    SELECT 
        u.customer_unique_id,
        oc.cycle AS last_order_cycle
    FROM user_rfm u
    JOIN delivered_orders do ON u.last_order_date = do.order_delivered_customer_date
                            AND u.customer_unique_id = (
                                SELECT c2.customer_unique_id 
                                FROM olist_order_customer_dataset c2 
                                WHERE c2.customer_id = do.customer_id
                            )
    JOIN order_cycle oc ON do.order_id = oc.order_id
    GROUP BY u.customer_unique_id, oc.cycle
),

-- 6. 获取每个客户首购订单的品类周期标签
first_order_cycle AS (
    SELECT 
        u.customer_unique_id,
        oc.cycle AS first_order_cycle
    FROM user_rfm u
    JOIN delivered_orders do ON u.first_order_date = do.order_delivered_customer_date
                            AND u.customer_unique_id = (
                                SELECT c2.customer_unique_id 
                                FROM olist_order_customer_dataset c2 
                                WHERE c2.customer_id = do.customer_id
                            )
    JOIN order_cycle oc ON do.order_id = oc.order_id
    GROUP BY u.customer_unique_id, oc.cycle
)

-- 7. 最终输出：所有分层标签及新增描述字段
SELECT 
    u.customer_unique_id,
    u.M_total,
    u.last_order_date,
    u.first_order_date,
    u.total_orders,
    CASE WHEN u.total_orders >= 2 THEN '是' ELSE '否' END AS is_repeat,
    DATEDIFF(rd.analysis_date, u.last_order_date) AS days_since_last,
    DATEDIFF(rd.analysis_date, u.first_order_date) AS days_since_first,
    
    loc.last_order_cycle,
    foc.first_order_cycle,
    
    rd.analysis_date AS ref_date,

    -- R活跃度分层（基于最近订单的品类周期）
    CASE 
        WHEN loc.last_order_cycle = '短' THEN
            CASE 
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 90  THEN '活跃'
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 180 THEN '沉默'
                ELSE '流失'
            END
        WHEN loc.last_order_cycle = '中' THEN
            CASE 
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 180 THEN '活跃'
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 365 THEN '沉默'
                ELSE '流失'
            END
        WHEN loc.last_order_cycle = '长' THEN
            CASE 
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 365 THEN '活跃'
                ELSE '沉默'
            END
        ELSE '流失'
    END AS R_segment,

    -- M价值分层（阈值 100, 200, 500）
    CASE 
        WHEN u.M_total <= 100 THEN '低消费'
        WHEN u.M_total <= 200 THEN '中消费'
        WHEN u.M_total <= 500 THEN '高消费'
        ELSE '超高消费'
    END AS M_segment,

    -- 综合分层标签
    CONCAT(
        CASE 
            WHEN loc.last_order_cycle = '短' THEN
                CASE 
                    WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 90  THEN '活跃'
                    WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 180 THEN '沉默'
                    ELSE '流失'
                END
            WHEN loc.last_order_cycle = '中' THEN
                CASE 
                    WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 180 THEN '活跃'
                    WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 365 THEN '沉默'
                    ELSE '流失'
                END
            WHEN loc.last_order_cycle = '长' THEN
                CASE 
                    WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 365 THEN '活跃'
                    ELSE '沉默'
                END
            ELSE '流失'
        END,
        '-',
        CASE 
            WHEN u.M_total <= 100 THEN '低消费'
            WHEN u.M_total <= 200 THEN '中消费'
            WHEN u.M_total <= 500 THEN '高消费'
            ELSE '超高消费'
        END
    ) AS combined_segment,
    
    -- R_score (长周期无流失，只有1和2)
    CASE 
        WHEN loc.last_order_cycle = '短' THEN
            CASE 
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 90  THEN 1
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 180 THEN 2
                ELSE 3
            END
        WHEN loc.last_order_cycle = '中' THEN
            CASE 
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 180 THEN 1
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 365 THEN 2
                ELSE 3
            END
        WHEN loc.last_order_cycle = '长' THEN
            CASE 
                WHEN DATEDIFF(rd.analysis_date, u.last_order_date) <= 365 THEN 1
                ELSE 2
            END
        ELSE 3
    END AS R_score,

    -- M_score
    CASE 
        WHEN u.M_total <= 100 THEN 1
        WHEN u.M_total <= 200 THEN 2
        WHEN u.M_total <= 500 THEN 3
        ELSE 4
    END AS M_score

FROM user_rfm u
JOIN last_order_cycle loc ON u.customer_unique_id = loc.customer_unique_id
JOIN first_order_cycle foc ON u.customer_unique_id = foc.customer_unique_id
CROSS JOIN ref_date rd;

