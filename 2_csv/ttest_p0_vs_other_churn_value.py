#!/usr/bin/env python
# coding: utf-8

# In[7]:


import pandas as pd
from scipy import stats

# 1. 读取数据
df = pd.read_csv('churn_user_values.csv')

# 2. 数据清洗
df['M_total'] = pd.to_numeric(df['M_total'], errors='coerce')
df.dropna(subset=['M_total'], inplace=True)

# 分组
# 均为短周期
# A_目标组为短周期-流失-超高消费人群
group_a = df[df['group_label'] == 'A_目标组']['M_total']
group_b = df[df['group_label'] == 'B_对照组']['M_total']

# 3. 统计描述
print("=== 描述性统计 ===")
print(f"A组（目标组）样本量: {len(group_a)}")
print(f"A组平均消费: ¥{group_a.mean():.2f}")
print(f"A组标准差: ¥{group_a.std():.2f}")
print()
print(f"B组（其他流失用户）样本量: {len(group_b)}")
print(f"B组平均消费: ¥{group_b.mean():.2f}")
print(f"B组标准差: ¥{group_b.std():.2f}")

# 4. Welch's t检验（不假设方差齐性）
t_stat, p_value = stats.ttest_ind(group_a, group_b, equal_var=False, alternative='two-sided')

# 5. 输出结果
print(f"\n=== Welch t-test 结果 ===")
print(f"t 统计量 = {t_stat:.4f}")
print(f"p 值 = {p_value:.6e}")  # 科学计数法，p极小也能显示

alpha = 0.05
if p_value < alpha:
    print(f"\n结论：p值远小于显著性水平{alpha}，拒绝原假设。")
    print("两组之间的消费金额差异在统计学上极显著。")
else:
    print(f"\n结论：p值大于等于{alpha}，不能拒绝原假设。差异不显著。")

from scipy.stats import mannwhitneyu

# 补充：Mann-Whitney U检验（不假设正态性）
u_stat, p_value_mw = mannwhitneyu(group_a, group_b, alternative='two-sided')

print(f"=== Mann-Whitney U 检验 (非参数) ===")
print(f"U 统计量 = {u_stat:.2f}")
print(f"p 值 = {p_value_mw:.6e}")

if p_value_mw < 0.05:
    print("结论：在非参数检验下，差异依然极显著。")

