#!/usr/bin/env python
# coding: utf-8

# In[ ]:


# 查找8个表中缺失数据的字段

import os
import pandas as pd

# 配置
DATA_DIR = "."  # 数据文件所在目录，根据实际情况修改
OUTPUT_FILE = "missing_values_report.csv"  # 可选：输出汇总文件

# 表名与文件名映射（可根据实际文件名调整）
tables = {
    "olist_geolocation_dataset": "olist_geolocation_dataset.csv",
    "olist_sellers_dataset": "olist_sellers_dataset.csv",
    "olist_customers_dataset": "olist_customers_dataset.csv",
    "olist_orders_dataset": "olist_orders_dataset.csv",
    "olist_products_dataset": "olist_products_dataset.csv",
    "olist_order_items_dataset": "olist_order_items_dataset.csv",
    "olist_order_payments_dataset": "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset": "olist_order_reviews_dataset.csv"
}

def analyze_missing(df, table_name):
    """统计DataFrame每列的缺失情况"""
    missing_count = df.isnull().sum()
    missing_pct = (missing_count / len(df)) * 100
    result = pd.DataFrame({
        "table": table_name,
        "column": missing_count.index,
        "missing_count": missing_count.values,
        "missing_pct": missing_pct.values
    })
    return result

def main():
    all_results = []
    
    for table_name, file_name in tables.items():
        file_path = os.path.join(DATA_DIR, file_name)
        if not os.path.exists(file_path):
            print(f"警告: 文件 {file_path} 不存在，跳过")
            continue
        
        print(f"正在处理 {table_name} ...")
        try:
            df = pd.read_csv(file_path, encoding='utf-8')  # 若编码问题可调整为 'latin1'
            res = analyze_missing(df, table_name)
            all_results.append(res)
        except Exception as e:
            print(f"读取 {file_path} 失败: {e}")
            continue
    
    if not all_results:
        print("没有成功处理任何文件")
        return
    
    # 合并所有结果
    final_report = pd.concat(all_results, ignore_index=True)
    
    # 打印摘要
    print("\n=== 缺失值统计报告 ===")
    for table_name in tables.keys():
        table_data = final_report[final_report["table"] == table_name]
        if table_data.empty:
            continue
        print(f"\n表: {table_name}")
        for _, row in table_data.iterrows():
            print(f"  {row['column']}: 缺失 {row['missing_count']} 行 ({row['missing_pct']:.2f}%)")
    '''
    # 可选：保存到文件
    final_report.to_csv(OUTPUT_FILE, index=False, encoding='utf-8-sig')
    print(f"\n汇总报告已保存至 {OUTPUT_FILE}")
    '''

if __name__ == "__main__":
    main()


# In[ ]:


# 计算地理位置表中邮编和经纬度都相同的多余数据量
import pandas as pd

# 读取 CSV 文件
df = pd.read_csv("olist_geolocation_dataset.csv")

# 按三个字段分组，计算每组行数
grouped = df.groupby(["geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"]).size()

# 多余数量 = 每组行数 - 1，总和即为多余总行数
duplicate_count = (grouped - 1).sum()

print(f"多余的数据行数（重复组中除第一条外）为: {duplicate_count}")


# In[ ]:


#  统计 olist_order_reviews_dataset.csv 中 review_id 字段完全相同的记录
import pandas as pd

# 读取 CSV 文件（请根据实际路径修改）
df = pd.read_csv("olist_order_reviews_dataset.csv")

# 统计所有重复的行数（包括第二次及之后出现的所有重复记录）
# 使用 duplicated() 标记重复行（keep=False 标记所有重复行，keep='first' 只标记除第一条外的重复行）
# 若只要除第一条外的重复行数量，设置 keep='first'
duplicate_count = df["review_id"].duplicated(keep=False).sum()
print(f"完全重复的 review_id 总行数（包括所有出现多次的行）: {duplicate_count}")


# In[ ]:


#  统计 olist_order_reviews_dataset.csv 中 order_id 字段完全相同的记录
import pandas as pd

# 读取 CSV 文件（请根据实际路径修改）
df = pd.read_csv("olist_order_reviews_dataset.csv")

# 统计所有重复的行数（包括第二次及之后出现的所有重复记录）
# 使用 duplicated() 标记重复行（keep=False 标记所有重复行，keep='first' 只标记除第一条外的重复行）
# 若只要除第一条外的重复行数量，设置 keep='first'
duplicate_count = df["order_id"].duplicated(keep=False).sum()
print(f"完全重复的 order_id 总行数（包括所有出现多次的行）: {duplicate_count}")


# In[ ]:


# 检索olist_order_reviews_dataset表中的review_id字段和order_id字段都完全相同的条数
import pandas as pd

# 读取 CSV 文件（请根据实际路径修改）
df = pd.read_csv("olist_order_reviews_dataset.csv")

# 选取需要检查的两列
cols = ['review_id', 'order_id']
df_sub = df[cols]

# 统计所有重复的行数（包括第一次出现，即所有出现次数大于1的行）
duplicate_all = df_sub.duplicated(keep=False).sum()
print(f"两列组合完全重复的行数（所有出现多次的行）: {duplicate_all}")


# In[ ]:


# 检索olist_order_reviews_dataset表中的review_id字段和order_id字段这两个字段是否有为空的行
import pandas as pd

df = pd.read_csv("olist_order_reviews_dataset.csv", usecols=['review_id', 'order_id'])

# 检查空值
print(df.isnull().sum())


# In[ ]:


# 先去除异常经纬度的数据（不在巴西境内）
# 将olist_geolocation_dataset表中一个邮编对应多个地址的情况重新输出一张表使其一个邮编对应一个聚合地址
# 聚合地址采取同一邮编下的所有地址的平均值（不去除重复）
# 如果遇到州和城市不相同，取众数
# 同时要注意邮编的前导0不要丢失(不要将其识别成INT)

import pandas as pd

# 1. 读取数据
file_path = 'olist_geolocation_dataset.csv'

# 使用 dtype 参数，强制将邮编列作为字符串读取，防止前导0丢失
try:
    df = pd.read_csv(file_path, dtype={'geolocation_zip_code_prefix': str})
except FileNotFoundError:
    print(f"错误：未找到文件 {file_path}，请检查路径。")
    exit()

print(f"原始数据行数: {len(df)}")

# 2. 剔除经纬度异常值
print("\n正在剔除经纬度异常数据...")
# 设定巴西的大致经纬度范围
LAT_MIN = -33.75   # 最南端（大约南纬33.75度）
LAT_MAX = 5.27     # 最北端（大约北纬5.27度）
LNG_MIN = -73.99   # 最西端（大约西经73.99度）
LNG_MAX = -34.79   # 最东端（大约西经34.79度）

# 筛选在范围内的数据
df_filtered = df[
    (df['geolocation_lat'] >= LAT_MIN) & 
    (df['geolocation_lat'] <= LAT_MAX) & 
    (df['geolocation_lng'] >= LNG_MIN) & 
    (df['geolocation_lng'] <= LNG_MAX)
]

removed_count = len(df) - len(df_filtered)
print(f"剔除了 {removed_count} 行异常数据（显示在巴西境外的坐标）。")
print(f"剩余有效数据行数: {len(df_filtered)}")

# 3. 数据一致性检查 (在过滤后的数据上进行)
print("\n正在进行一致性检查...")

def check_consistency(df, group_col, check_col):
    # 按邮编分组，计算每个组内 check_col 的唯一值数量
    nunique_values = df.groupby(group_col)[check_col].nunique()
    
    # 筛选出唯一值大于1的邮编（即存在冲突的邮编）
    inconsistent_zips = nunique_values[nunique_values > 1]
    
    if not inconsistent_zips.empty:
        print(f"\n[警告] 发现 {len(inconsistent_zips)} 个邮编存在不同的 {check_col} 值！详情如下（展示前10个）：")
        
        for zip_code in inconsistent_zips.index[:10]:
            unique_vals = df[df[group_col] == zip_code][check_col].unique()
            print(f"  邮编 {zip_code}: 存在值 {list(unique_vals)}")
            
        return False
    else:
        print(f"检查通过：所有相同邮编的 {check_col} 均相同。")
        return True

# 检查城市和州
city_consistent = check_consistency(df_filtered, 'geolocation_zip_code_prefix', 'geolocation_city')
state_consistent = check_consistency(df_filtered, 'geolocation_zip_code_prefix', 'geolocation_state')

# 4. 数据聚合
print("\n开始聚合数据（经纬度取平均，城市/州取众数）...")

# 定义聚合逻辑
agg_logic = {
    'geolocation_lat': 'mean',
    'geolocation_lng': 'mean',
    'geolocation_city': lambda x: x.mode()[0] if not x.mode().empty else x.iloc[0],
    'geolocation_state': lambda x: x.mode()[0] if not x.mode().empty else x.iloc[0]
}

# 执行分组聚合 (使用过滤后的 df_filtered)
df_cleaned = df_filtered.groupby('geolocation_zip_code_prefix').agg(agg_logic).reset_index()

# 5. 保存结果
output_file = 'olist_geolocation_cleaned.csv'

df_cleaned.to_csv(output_file, index=False)

print(f"\n处理完成！")
print(f"最终聚合后行数: {len(df_cleaned)}")
print(f"结果已保存至: {output_file}")

# 打印前几行预览
print("\n清洗后数据预览：")
print(df_cleaned.head())


# In[ ]:




