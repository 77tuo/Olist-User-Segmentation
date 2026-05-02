-- 按顺序创建表，否则被引用表未创建时会报错


CREATE TABLE IF NOT EXISTS olist_geolocation_dataset (
    geolocation_zip_code_prefix VARCHAR(10) PRIMARY KEY, -- 邮编前缀
    geolocation_lat DECIMAL(15,13),              -- 纬度
    geolocation_lng DECIMAL(15,13),              -- 经度
    geolocation_city VARCHAR(50),               -- 城市
    geolocation_state VARCHAR(2)                -- 州
    
);


CREATE TABLE IF NOT EXISTS olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY,          -- 卖家ID（主键）
    seller_zip_code_prefix VARCHAR(10),         -- 卖家邮编前缀
    seller_city VARCHAR(50),                    -- 卖家城市
    seller_state VARCHAR(2),                  -- 卖家州
        
	-- 添加外键约束
    CONSTRAINT fk_seller_geolocation 
    FOREIGN KEY (seller_zip_code_prefix) 
    REFERENCES olist_geolocation_dataset(geolocation_zip_code_prefix)
    
);


CREATE TABLE IF NOT EXISTS olist_order_customer_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,        -- 客户ID（主键）
    customer_unique_id VARCHAR(50),             -- 客户唯一ID
    customer_zip_code_prefix VARCHAR(10),       -- 客户邮编前缀
    customer_city VARCHAR(50),                  -- 客户城市
    customer_state VARCHAR(2),                 -- 客户州
    INDEX idx_customer_unique_id (customer_unique_id),
    
        -- 添加外键约束
    CONSTRAINT fk_customer_geolocation 
    FOREIGN KEY (customer_zip_code_prefix) 
    REFERENCES olist_geolocation_dataset(geolocation_zip_code_prefix)
    
);


CREATE TABLE IF NOT EXISTS olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,           -- 订单ID（主键）
    customer_id VARCHAR(50),                    -- 客户ID（外键，关联订单客户表）
    order_status VARCHAR(30),                   -- 订单状态
    order_purchase_timestamp DATETIME,          -- 订单购买时间
    order_approved_at DATETIME,                 -- 订单批准时间
    order_delivered_carrier_date DATETIME,      -- 订单交付给物流时间
    order_delivered_customer_date DATETIME,     -- 订单交付给客户时间
    order_estimated_delivery_date DATETIME,     -- 预估交付时间
    FOREIGN KEY (customer_id) REFERENCES olist_order_customer_dataset(customer_id),
    -- 1. 复合索引：支持按购买时间范围查询，且支持查询特定状态的订单
    INDEX idx_purchase_time_status (order_purchase_timestamp, order_status),
    -- 2. 单独索引：支持物流准时率分析（筛选某个时间点之前送达的订单）
    INDEX idx_delivery_date (order_delivered_customer_date)
    
);


CREATE TABLE IF NOT EXISTS olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,         -- 产品ID（主键）
    product_category_name VARCHAR(50),          -- 产品类别名称
    product_name_length INT,                   -- 产品名称长度
    product_description_length INT,             -- 产品描述长度
    product_photos_qty INT,                    -- 产品图片数量
    product_weight_g INT,                      -- 产品重量（克）
    product_length_cm INT,                     -- 产品长度（厘米）
    product_height_cm INT,                     -- 产品高度（厘米）
    product_width_cm INT,                       -- 产品宽度（厘米）
    INDEX idx_product_category (product_category_name)
);


CREATE TABLE IF NOT EXISTS olist_order_items_dataset (
    order_id VARCHAR(50),                      -- 订单ID（外键，关联订单表）
    order_item_id INT,                         -- 订单商品ID（联合主键）
    product_id VARCHAR(50),                    -- 产品ID（外键，关联产品表）
    seller_id VARCHAR(50),                     -- 卖家ID（外键，关联卖家表）
    shipping_limit_date DATETIME,               -- 发货限制时间
    price DECIMAL(10,2),                       -- 商品价格
    freight_value DECIMAL(10,2),               -- 运费
    PRIMARY KEY (order_id, order_item_id),       -- 联合主键
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id),
    FOREIGN KEY (product_id) REFERENCES olist_products_dataset(product_id),
    FOREIGN KEY (seller_id) REFERENCES olist_sellers_dataset(seller_id),
	INDEX idx_item_product (product_id),
    INDEX idx_item_seller (seller_id)
);


CREATE TABLE IF NOT EXISTS olist_order_payments_dataset (
    order_id VARCHAR(50),                      -- 订单ID（外键，关联订单表）
    payment_sequential INT,                    -- 支付序列（联合主键）
    payment_type VARCHAR(30),                   -- 支付类型
    payment_installments INT,                   -- 分期数
    payment_value DECIMAL(12,2),                -- 支付金额
    PRIMARY KEY (order_id, payment_sequential),  -- 联合主键
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id)
);

-- 评论表中有不符合规范的数据，需要将其特殊处理。
-- 处理详情查看special_handling__olist_order_reviews_dataset.sql
CREATE TABLE IF NOT EXISTS olist_order_reviews_dataset (
    review_id VARCHAR(50) NOT NULL,            -- 评论ID (联合主键)
    order_id VARCHAR(50) NOT NULL,             -- 订单ID（联合主键，外键，关联订单表）
    review_score INT,                          -- 评论评分
    review_comment_title VARCHAR(255),         -- 评论标题
    review_comment_message TEXT,               -- 评论内容
    review_creation_date DATETIME,             -- 评论创建时间
    review_answer_timestamp DATETIME,          -- 评论回复时间
    
	-- 定义联合主键
    PRIMARY KEY (order_id, review_id),
    -- 定义外键
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id)
);


-- 商品品类的中英文对照表
CREATE TABLE dim_product_category (
    product_category_name VARCHAR(100) PRIMARY KEY COMMENT '原葡萄牙语品类名(主键)',
    category_name_en VARCHAR(100) COMMENT '英文品类名',
    category_name_cn VARCHAR(50) COMMENT '中文品类名'
) COMMENT '商品品类中文对照表';
