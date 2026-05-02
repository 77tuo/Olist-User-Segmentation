-- 在导入数据前，先用pandas扫描8个表，有缺失值的字段需要转换成NULL，需要额外处理


-- 导入olist_orders_dataset表
-- 暂时关闭外键检查（防止因父表数据缺失导致导入失败）
SET FOREIGN_KEY_CHECKS = 0;

-- 清空原表（如果需要重新导入，非必需）
-- TRUNCATE TABLE olist_orders_dataset;

-- 执行导入命令
-- 特别注意，这里路径是create_database.sql中的语句中指向的路径，并且需要把csv数据挂载在其路径上
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id, 
    customer_id, 
    order_status, 
    @var_purchase_timestamp,  -- 使用变量接收原始CSV数据，
    @var_approved_at,         -- 虽然这个表只有三个缺失值，
    @var_delivered_carrier,   -- 但是时间类型建议使用变量处理
    @var_delivered_customer,
    @var_estimated_delivery
)
SET 
    order_purchase_timestamp = STR_TO_DATE(@var_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
    order_approved_at = NULLIF(@var_approved_at, ''), -- 将空字符串转为NULL
    order_delivered_carrier_date = NULLIF(@var_delivered_carrier, ''),
    order_delivered_customer_date = NULLIF(@var_delivered_customer, ''),
    order_estimated_delivery_date = NULLIF(@var_estimated_delivery, '');

-- 导入完成后恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;


-- 以上为导入一个表作为实验，接下来导入其他表


-- ==========================================
-- 1. 导入地理位置表
-- 报告显示无缺失，简单处理
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_geolocation_cleaned.csv'
IGNORE   
INTO TABLE olist_geolocation_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
	@var_zip_prefix,  -- 使用变量接收，防止 01046 变成 1046
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SET 
    geolocation_zip_code_prefix = @var_zip_prefix; -- 直接赋值字符串

SET FOREIGN_KEY_CHECKS = 1;


-- ==========================================
-- 2. 导入产品信息表
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_id,
    @var_category,
    @var_name_lenght,      -- CSV文件头拼写错误
    @var_desc_lenght,      -- CSV文件头拼写错误
    @var_photos_qty,
    @var_weight,
    @var_length,
    @var_height,
    @var_width
)
SET 
    product_category_name = NULLIF(@var_category, ''),
    product_name_length = NULLIF(@var_name_lenght, ''),
    product_description_length = NULLIF(@var_desc_lenght, ''),
    product_photos_qty = NULLIF(@var_photos_qty, ''),
    product_weight_g = NULLIF(@var_weight, ''),
    product_length_cm = NULLIF(@var_length, ''),
    product_height_cm = NULLIF(@var_height, ''),
    product_width_cm = NULLIF(@var_width, '');

SET FOREIGN_KEY_CHECKS = 1;


-- ==========================================
-- 3. 导入卖家信息表
-- 报告显示无缺失，简单处理
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
);

SET FOREIGN_KEY_CHECKS = 1;


-- ==========================================
-- 4. 导入客户信息表
-- 报告显示无缺失，简单处理
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE olist_order_customer_dataset 
-- 这里下载的csv名称是olist_customers_dataset，
-- 但是在kaggle网页的数据表关系图中是olist_order_customer_dataset，
-- 由于前面表设计时也是如此，故这里是olist_order_customer_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
);

SET FOREIGN_KEY_CHECKS = 1;

/* olist_orders_dataset前面已经导入，这里先注释掉
-- ==========================================
-- 5. 导入订单信息表
-- 必须使用 NULLIF 处理空日期
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id, 
    customer_id, 
    order_status, 
    @var_purchase_timestamp,
    @var_approved_at,
    @var_delivered_carrier,
    @var_delivered_customer,
    @var_estimated_delivery
)
SET 
    order_purchase_timestamp = STR_TO_DATE(@var_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
    order_approved_at = NULLIF(STR_TO_DATE(@var_approved_at, '%Y-%m-%d %H:%i:%s'), ''),
    order_delivered_carrier_date = NULLIF(STR_TO_DATE(@var_delivered_carrier, '%Y-%m-%d %H:%i:%s'), ''),
    order_delivered_customer_date = NULLIF(STR_TO_DATE(@var_delivered_customer, '%Y-%m-%d %H:%i:%s'), ''),
    order_estimated_delivery_date = NULLIF(STR_TO_DATE(@var_estimated_delivery, '%Y-%m-%d %H:%i:%s'), '');

SET FOREIGN_KEY_CHECKS = 1;

*/
-- ==========================================
-- 6. 导入订单支付表
-- 报告显示无缺失，简单处理
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
);

SET FOREIGN_KEY_CHECKS = 1;


-- ==========================================
-- 7. 导入订单商品项表
-- 报告显示无缺失，简单处理
-- ==========================================
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    @var_shipping_limit_date,
    price,
    freight_value
)
SET 
    shipping_limit_date = STR_TO_DATE(@var_shipping_limit_date, '%Y-%m-%d %H:%i:%s');

SET FOREIGN_KEY_CHECKS = 1;


-- ==========================================
-- 8. 导入订单评论表
-- 由于评论中存在特殊数据，无法直接导入到MySQL中（会报错），所以另开一个文件单独处理。
-- 即为special_handling__olist_order_reviews_dataset.sql
-- ==========================================





-- 9. 导入商品品类中英文对照表的数据
-- 这里手动输入数据导入
-- 批量插入数据 (使用电商常用中文)
-- 中间发现原翻译表没有覆盖所有品类，所以以下数据添加了原翻译表没有的翻译品类
INSERT INTO dim_product_category (product_category_name, category_name_en, category_name_cn) VALUES
('beleza_saude', 'health_beauty', '健康美容'),
('informatica_acessorios', 'computers_accessories', '电脑配件'),
('automotivo', 'auto', '汽车用品'),
('cama_mesa_banho', 'bed_bath_table', '床品浴巾桌布'),
('moveis_decoracao', 'furniture_decor', '家具装饰'),
('esporte_lazer', 'sports_leisure', '运动休闲'),
('perfumaria', 'perfumery', '香水香氛'),
('utilidades_domesticas', 'housewares', '居家日用品'),
('telefonia', 'telephony', '手机通讯'),
('relogios_presentes', 'watches_gifts', '钟表礼品'),
('alimentos_bebidas', 'food_drink', '食品饮料'),
('bebes', 'baby', '母婴用品'),
('papelaria', 'stationery', '文具'),
('tablets_impressao_imagem', 'tablets_printing_image', '平板及打印设备'),
('brinquedos', 'toys', '玩具'),
('telefonia_fixa', 'fixed_telephony', '固定电话'),
('ferramentas_jardim', 'garden_tools', '园艺工具'),
('fashion_bolsas_e_acessorios', 'fashion_bags_accessories', '时尚箱包配饰'),
('eletroportateis', 'small_appliances', '小家电'),
('consoles_games', 'consoles_games', '游戏机及游戏'),
('audio', 'audio', '音频设备'),
('fashion_calcados', 'fashion_shoes', '时尚鞋履'),
('cool_stuff', 'cool_stuff', '潮流酷玩'),
('malas_acessorios', 'luggage_accessories', '箱包配饰'),
('climatizacao', 'air_conditioning', '温控设备'),
('construcao_ferramentas_construcao', 'construction_tools_construction', '建筑施工工具'),
('moveis_cozinha_area_de_servico_jantar_e_jardim', 'kitchen_dining_laundry_garden_furniture', '厨餐及庭院家具'),
('construcao_ferramentas_jardim', 'costruction_tools_garden', '园艺施工工具'),
('fashion_roupa_masculina', 'fashion_male_clothing', '男装'),
('pet_shop', 'pet_shop', '宠物用品'),
('moveis_escritorio', 'office_furniture', '办公家具'),
('market_place', 'market_place', '第三方集市'),
('eletronicos', 'electronics', '电子产品'),
('eletrodomesticos', 'home_appliances', '大家电'),
('artigos_de_festas', 'party_supplies', '派对用品'),
('casa_conforto', 'home_confort', '家居舒适用品'),
('construcao_ferramentas_ferramentas', 'costruction_tools_tools', '手工工具'),
('agro_industria_e_comercio', 'agro_industry_and_commerce', '农工商业用品'),
('moveis_colchao_e_estofado', 'furniture_mattress_and_upholstery', '床垫与软装家具'),
('livros_tecnicos', 'books_technical', '技术书籍'),
('casa_construcao', 'home_construction', '家装建材'),
('instrumentos_musicais', 'musical_instruments', '乐器'),
('moveis_sala', 'furniture_living_room', '客厅家具'),
('construcao_ferramentas_iluminacao', 'construction_tools_lights', '工程照明灯具'),
('industria_comercio_e_negocios', 'industry_commerce_and_business', '工商业用品'),
('alimentos', 'food', '食品'),
('artes', 'art', '艺术用品'),
('moveis_quarto', 'furniture_bedroom', '卧室家具'),
('livros_interesse_geral', 'books_general_interest', '综合类书籍'),
('construcao_ferramentas_seguranca', 'construction_tools_safety', '安全防护工具'),
('fashion_underwear_e_moda_praia', 'fashion_underwear_beach', '内衣泳装'),
('fashion_esporte', 'fashion_sport', '运动服饰'),
('sinalizacao_e_seguranca', 'signaling_and_security', '安防与信号设备'),
('pcs', 'computers', '电脑'),
('artigos_de_natal', 'christmas_supplies', '圣诞用品'),
('fashion_roupa_feminina', 'fashio_female_clothing', '女装'),
('eletrodomesticos_2', 'home_appliances_2', '大家电_2'),
('livros_importados', 'books_imported', '进口书籍'),
('bebidas', 'drinks', '饮品'),
('cine_foto', 'cine_photo', '影音摄影'),
('la_cuisine', 'la_cuisine', '厨房用具'),
('musica', 'music', '音乐制品'),
('casa_conforto_2', 'home_confort_2', '家居舒适用品_2'),
('portateis_casa_forno_e_cafe', 'small_appliances_home_oven_and_coffee', '烤箱及咖啡小家电'),
('cds_dvds_musicais', 'cds_dvds_musicals', '音乐CD/DVD'),
('dvds_blu_ray', 'dvds_blu_ray', '蓝光DVD'),
('flores', 'flowers', '鲜花'),
('artes_e_artesanato', 'arts_and_craftmanship', '手工艺品'),
('fraldas_higiene', 'diapers_and_hygiene', '纸尿裤及卫生用品'),
('fashion_roupa_infanto_juvenil', 'fashion_childrens_clothes', '童装'),
('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_appliances_and_food_preparers', '便携式厨房和食品加工设备'),
('pc_gamer', 'PC Gaming', '电竞设备'),
('seguros_e_servicos', 'security_and_services', '安全与服务');