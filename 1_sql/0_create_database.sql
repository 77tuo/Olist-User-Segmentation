CREATE DATABASE IF NOT EXISTS olist;
USE olist;

-- DROP DATABASE IF EXISTS olist;

-- 展示csv文件可安全导入的数据路径，将这里显示的路径粘贴到import_data.sql中指向的路径
SHOW VARIABLES LIKE 'secure_file_priv';

