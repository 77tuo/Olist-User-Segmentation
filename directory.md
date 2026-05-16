olist-user-segmentation/

├── README.md                          # 项目总览、背景、技术栈、快速导航

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

├── 1_sql/

│   ├── README.md                      # 表结构图、执行顺序说明

│   ├── 0_create_database.sql           # 创建数据库

│   ├── 1_create_tables.sql             # 创建表结构

│   ├── 2_import_data.sql              # 导入数据至数据库

│   ├── 3_special_handling_olist_order_reviews_dataset.sql     # 处理评论表不规范数据

│   ├── 4_EDA.sql    # 探索性查询

│   ├── 5_create_view_user_segmentation.sql   # 核心用户分层模型视图

│   └── 6_export_queries.sql          # 所有导出 CSV 的查询

├── 2_csv/

│   ├── category_sales_summary.csv ← 73个品类销售汇总

│   ├── segment_32_value_table.csv ← 32个细分群体价值表

│   ├── M_threshold_summary.csv ← M阈值分位点验证

│   ├── segment_32_stats_with_std.csv ← 32个细分群体的均值和标准差

│   ├── churn_p0_vs_active_high_value_comparison.csv ← 短周期-流失-超高消费 vs 短周期-活跃-超高消费 评分情况与物流天数 订单级数据

│   ├── churn_p0_vs_active_high_value_review_coverage.csv ← 短周期-流失-超高消费 vs 短周期-活跃-超高消费 评论覆盖率 统计口径：每个订单至少一条评论

│   ├── statistical_test_results.csv ← 所有统计检验结果汇总

│   ├── churn_negative_reviews.csv ← 26条差评原文及翻译

│   ├── reviews_sample_with_summary.md ← 差评分类总结

│   ├── churn_user_values.csv ← 短周期-流失-超高消费 vs 其余流失人群 平均消费 用户级数据

│   ├── rfm_comparison.csv ← 新旧模型流失率对比

│   ├── ttest_p0_vs_other_churn_value.py ← 检验短周期-流失-超高消费 vs 其他流失用户消费金额差异（Welch t检验）

│   ├── attribution_p0_vs_active_churn_analysis.py ← 检验短周期-流失-超高消费 vs 短周期-活跃-超高消费用户 差评率 + 物流天数差异（卡方检验 + Welch t检验）

└── 3_powerbi/

│   ├── olist_user_segmentation.pbix            # 完整 Power BI 报告
