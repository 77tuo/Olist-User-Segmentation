olist-user-segmentation/

├── README.md                          # 项目总览、背景、技术栈、快速导航

│

├── 0_data/

│   ├── README.md                      # 数据来源、清洗说明、免责声明
│   ├── olist_orders_dataset.csv       # 原始数据（8个表）
│   ├── olist_order_items_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_customers_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_geolocation_dataset.zip  # 地理数据过大，压缩上传
│   ├── EDA_and_dataset_clean.py           # 简单探索数据并清洗聚合地理数据脚本
│   └── olist_geolocation_cleaned.csv        # 清洗后的地理数据
│
├── 1_sql/
│   ├── README.md                      # 表结构图、执行顺序说明
│   ├── 0_create_database.sql           # 创建数据库
│   ├── 1_create_tables.sql             # 创建表结构
│   ├── 2_import_data.sql              # 导入数据至数据库
│   ├── 3_special_handling_olist_order_reviews_dataset.sql     # 处理评论表不规范数据
│   ├── 4_EDA.sql    # 探索性查询
│   ├── 5_create_view_user_segmentation.sql   # 核心用户分层模型视图
│   └── 6_export_queries.sql          # 所有导出 CSV 的查询
│
├── 2_csv/
│   ├── M_threshold_summary.csv
│   ├── category_sales_summary.csv
│   ├── segment_32_value_table.csv
│   
│   ├── segment_32_stats_with_std.csv
│   ├── rfm_comparison.csv
│   ├── churn_p0_vs_active_high_value_comparison.csv
│   ├── review_coverage_p0_vs_active_high_value.csv
│   ├── churn_negative_reviews.csv
│   ├── reviews_sample_with_summary.md
│   ├── statistical_test_results.csv
│   ├── ttest_p0_vs_other_churn_value.py        # 消费金额差异检验
│   └── attribution_p0_vs_active_churn_analysis.py  # 归因双检验
│
└── 3_powerbi/
    └── olist_user_segmentation.pbix            # 完整 Power BI 报告
