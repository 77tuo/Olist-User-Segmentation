#!/usr/bin/env python
# coding: utf-8

# In[19]:


import pandas as pd
from scipy.stats import chi2_contingency, ttest_ind

# 1. 读取数据
df = pd.read_csv('churn_p0_vs_active_high_value_comparison.csv')

# 2. 数据预览
print("=== 数据概览 ===")
print(f"总订单数: {len(df)}")
print(f"分组计数:\n{df['group_label'].value_counts()}")
print()

# 3. 数据处理：标记差评（score <= 2），空值视为非差评
df['review_score'] = pd.to_numeric(df['review_score'], errors='coerce')
df['is_low_score'] = df['review_score'].notna() & (df['review_score'] <= 2)

# 4. 构建2x2列联表
group_a_label = '短周期-流失-超高消费'
group_b_label = '短周期-活跃-超高消费'

a_data = df[df['group_label'] == group_a_label]
b_data = df[df['group_label'] == group_b_label]

a_low = a_data['is_low_score'].sum()
a_not_low = len(a_data) - a_low
b_low = b_data['is_low_score'].sum()
b_not_low = len(b_data) - b_low

observed = [[a_low, a_not_low],
            [b_low, b_not_low]]

print("=== 卡方检验（差评率差异） ===")
print(f"列联表（差评 / 非差评）:")
print(f"P0 目标流失: {a_low} / {a_not_low}")
print(f"活跃超高消费: {b_low} / {b_not_low}")
print(f"P0 目标流失差评率: {a_low/len(a_data)*100:.2f}%")
print(f"活跃超高消费差评率: {b_low/len(b_data)*100:.2f}%")

chi2, p_chi, dof, expected = chi2_contingency(observed)
print(f"卡方统计量: {chi2:.4f}")
print(f"p值: {p_chi:.6f}")
print(f"自由度: {dof}")
if p_chi < 0.05:
    print("结论：p值 < 0.05，差评率差异具有统计显著性。")
else:
    print("结论：p值 >= 0.05，差评率差异不具有统计显著性。")
print()

# 5. Welch t 检验（物流天数）
print("=== Welch t 检验（物流天数差异） ===")
a_delivery = a_data['delivery_days'].dropna()
b_delivery = b_data['delivery_days'].dropna()

print(f"P0 目标流失订单数: {len(a_delivery)}，平均物流: {a_delivery.mean():.2f} 天")
print(f"活跃超高消费订单数: {len(b_delivery)}，平均物流: {b_delivery.mean():.2f} 天")

t_stat, p_t = ttest_ind(a_delivery, b_delivery, equal_var=False)
print(f"t 统计量: {t_stat:.4f}")
print(f"p 值: {p_t:.6f}")
if p_t < 0.05:
    print("结论：p值 < 0.05，物流天数差异具有统计显著性。")
    if a_delivery.mean() > b_delivery.mean():
        print("P0 目标流失组的平均物流时间显著更长。")
    else:
        print("活跃组的平均物流时间显著更长。")
else:
    print("结论：p值 >= 0.05，物流天数差异不具有统计显著性。")


# In[ ]:




