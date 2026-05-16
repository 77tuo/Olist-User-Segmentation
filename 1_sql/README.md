数据表结构：
（该图中的客户信息表命名为olist_order_customer_dataset，下载的数据csv表中命名为olist_customers_dataset.csv,实际为同一数据表）
<img width="1002" height="672" alt="olist数据表结构" src="https://github.com/user-attachments/assets/795a507a-5ef3-4c78-bd2f-c112fdffd776" />
另外新建一个产品品类中英文对照翻译表dim_product_category，通过product_category_name字段与产品表olist_products_dataset相连。

本文件夹的sql执行需要按照前缀数字的顺序来执行(从0开始)
