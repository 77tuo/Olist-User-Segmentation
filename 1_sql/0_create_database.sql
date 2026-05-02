CREATE DATABASE IF NOT EXISTS olist;
USE olist;

-- DROP DATABASE IF EXISTS olist;

-- 展示csv文件可安全导入的数据路径，将这里显示的路径粘贴到import_data.sql中指向的路径
-- 特别注意，你需要将数据挂载到以下代码展示的路径中，并修改import_data.sql中的指向路径（注意地理信息表要导入清洗后的cleaned版本而不是原始csv）
SHOW VARIABLES LIKE 'secure_file_priv';

