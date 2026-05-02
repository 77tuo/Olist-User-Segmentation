
-- 1. 禁用外键检查
SET FOREIGN_KEY_CHECKS = 0;

-- 2. 删除旧表
DROP TABLE IF EXISTS olist_order_reviews_dataset;

-- 3. 创建新表：注意，日期字段暂时设为 VARCHAR，用来先接数据
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date VARCHAR(50),      -- 先用字符串接收
    review_answer_timestamp VARCHAR(50),   -- 先用字符串接收
    PRIMARY KEY (order_id, review_id),
        -- 定义外键
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id)
);

-- 4. 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- 导入数据

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_dataset.csv'
IGNORE        -- 这里忽略错误行
INTO TABLE olist_order_reviews_dataset
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



-- 第一步：新建一个临时表，结构完全正确
CREATE TABLE temp_reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (order_id, review_id)
);

-- 第二步：从旧表把数据搬过来，顺便转换时间格式
-- 这里会自动过滤掉无法转换成时间的错误数据
INSERT INTO temp_reviews
SELECT 
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    -- 尝试转换时间，如果格式不对就设为 NULL
    STR_TO_DATE(review_creation_date, '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(review_answer_timestamp, '%Y-%m-%d %H:%i:%s')
FROM olist_order_reviews_dataset
WHERE 
    -- 简单过滤一下，确保时间字段看起来像时间
    review_creation_date LIKE '20%';

-- 第三步：删除旧表
DROP TABLE olist_order_reviews_dataset;

-- 第四步：把临时表改名为正式表
RENAME TABLE temp_reviews TO olist_order_reviews_dataset;

-- 第五步：验证一下数据量（应该为99222）
SELECT COUNT(*) FROM olist_order_reviews_dataset;

-- 查看特定条数据，了解数据全貌，检查时间格式是否正确
SELECT * FROM olist_order_reviews_dataset LIMIT 800;