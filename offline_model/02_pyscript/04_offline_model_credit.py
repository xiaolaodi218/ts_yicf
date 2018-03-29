# -*- coding: utf-8 -*-
"""
Created on Fri Dec 29 10:42:19 2017

@author: Administrator
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

#忽略弹出的warnings
import warnings
warnings.filterwarnings("ignore")

import sys
sys.path.append(r"F:\model\lib")
import iv
import model_evaluation_plot
import model_helper
import preprocess

sys.path.append(r"F:\ML\lib")
import step01_woe_iv
import step02_bining
import step03_statsmodels
import step04_moudle_evaluate
import step05_make_score
import step06_draw_plot

sys.path.append(r"F:\TS\offline_model\lib")
import step01_feature_engine
import step02_modle_plot
import step03_built_modle
import new_iv

df = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\orig_data_3.csv')
#df.columns = df.columns.str.lower()  #列名变为小写
df = df.rename(columns = {'target':'y'}, copy = False)
df.groupby('y').size()
'''
y
0    1987
1     251
dtype: int64
11.2%
'''

#基于业务的原因删除省份等地域有关影响;汽车个数房产个数工作变动次数现在的申请表已经没有了
#is_has_insurance_policy只是针对E保通,故删除;
df1 = df.drop(['apply_code','REPORT_NUMBER', 'REAL_NAME','征信获取时间','ID_CARD'], axis = 1)

#排序
df1 = df1[['selfquery_in3m',
 'selfquery_in1m',
 'selfquery_in6m',
 'selfquery_in12m',
 'selfquery_in24m',
 'loan_query_in1m',
 'loan_query_in3m',
 'loan_query_in6m',
 'loan_query_in12m',
 'loan_query_in24m',
 'query_in3m_1',
 'query_in1m',
 'query_in12m',
 'query_in6m',
 'query_in24m',
 'card_query_in1m',
 'card_query_in3m',
 'card_query_in6m',
 'card_query_in12m',
 'card_query_in24m',
 'selfquery_in3m_min_interval',
 'selfquery_in3m_max_interval',
 'selfquery5_in1m',
 'selfquery5_in3m',
 'selfquery5_inl3m',
 'selfquery5_in6m',
 'selfquery5_in12m',
 'selfquery5_in24m',
 'selfquery6_in1m',
 'selfquery6_in3m',
 'selfquery6_in6m',
 'selfquery6_inl3m',
 'selfquery6_in12m',
 'selfquery6_in24m',
 'lo_query_in1m',
 'lo_query_in3m',
 'lo_query_in6m',
 'lo_query_in12m',
 'lo_query_in24m',
 'lo_query_in1m_f',
 'lo_query_in3m_f',
 'lo_query_in6m_f',
 'lo_query_in12m_f',
 'lo_query_in24m_f',
 'lo_query_in1m_de_f',
 'lo_query_in3m_de_f',
 'lo_query_in6m_de_f',
 'lo_query_in12m_de_f',
 'lo_query_in24m_de_f',
 'mana_loan_in1m',
 'mana_loan_in3m',
 'mana_loan_in6m',
 'mana_loan_in12m',
 'mana_loan_in24m',
 'mana_loan_in1m_f',
 'mana_loan_in3m_f',
 'mana_loan_in6m_f',
 'mana_loan_in12m_f',
 'mana_loan_in24m_f',
 'mana_loan_in1m_de_f',
 'mana_loan_in3m_de_f',
 'mana_loan_in6m_de_f',
 'mana_loan_in12m_de_f',
 'mana_loan_in24m_de_f',
 'cardqurry_com_num',
 'insurqurry_com_num',
 'num_pettyloan',
 'loqurry_com_num',
 'credit_card_num_cn',
 'credit_card_num_fo',
 'use_credit_card_numb',
 'can_card_num',
 'can_card_rate',
 'inac_card_num',
 'inac_card_rate',
 'bad_card_num',
 'bad_card_rate',
 'normal_card_num',
 'pres_overdue_num',
 'pres_overdue_card_rate',
 'his_overdue_card_rate',
 'his_overdue_card_num',
 'near_2y_card_num',
 'max_card_line',
 'mean_card_line',
 'min_card_line',
 'var_card_line',
 'max_card_line_bf',
 'min_card_line_bf',
 'mean_card_line_bf',
 'var_card_line_bf',
 'loan_num',
 'credit_card_number_l60',
 'credit_card_number_m90',
 'credit_card_number_m90_rate',
 'credit_card_number_l60_rate',
 'consumer_finance_loan_num',
 'high_consum_loan_num',
 'clear_loan_num_6m',
 'clear_loan_num_12m',
 'clear_loan_num_24m',
 'consum_loan_num',
 'unclear_loan_num',
 'clear_loan_num',
 'petty_loan_num',
 'bus_loan_num',
 'loan_num_in24m',
 '银行结清贷款',
 'other_loan_num',
 '四大行贷款',
 'webank_loan',
 '银行贷款',
 'near_loan_time',
 'far_loan_time',
 'max_loanline',
 '银行消金',
 '银行小额',
 '无银行有消费贷',
 '银行微众',
 'new_loan_in12m',
 'due_cos_loan_balance_in12m',
 'max_car_loan_line',
 'ave_car_loan_line',
 'near_car_loan',
 'min_car_loan_line',
 '个人汽车贷款数',
 'max_man_loan_line',
 'ave_man_loan_line',
 'near_man_loan',
 'min_man_loan_line',
 '个人经营数',
 'max_percos_loan_line',
 'ave_percos_loan_line',
 'near_percos_loan',
 'min_percos_loan_line',
 '个人消费',
 'unclear_loan_amount',
 'umclear_month_pay',
 '发放贷款数',
 'consumerfinance_query_in1m',
 'consumerfinance_query_in3m',
 'consumerfinance_query_in6m',
 'consumerfinance_query_in12m',
 'consumerfinance_query_in24m',
 'consumerfinance_loquery_in1m',
 'consumerfinance_loquery_in3m',
 'consumerfinance_loquery_in6m',
 'consumerfinance_loquery_in12m',
 'consumerfinance_loquery_in24m',
 'consumerfinance_manaquery_in1m',
 'consumerfinance_manaquery_in3m',
 'consumerfinance_manaquery_in6m',
 'consumerfinance_manaquery_in12m',
 'consumerfinance_manaquery_in24m',
 'pettyloan_query_in1m',
 'pettyloan_query_in3m',
 'pettyloan_query_in6m',
 'pettyloan_query_in12m',
 'pettyloan_query_in24m',
 'pettyloan_loquery_in1m_1',
 'pettyloan_loquery_in3m_1',
 'pettyloan_loquery_in6m_1',
 'pettyloan_loquery_in12m_1',
 'pettyloan_loquery_in24m_1',
 'pettyloan_manaquery_in1m',
 'pettyloan_manaquery_in3m',
 'pettyloan_manaquery_in6m',
 'pettyloan_manaquery_in12m',
 'pettyloan_manaquery_in24m',
 'card_query_in1m_max',
 'card_query_in3m_max',
 'card_query_in6m_max',
 'card_query_in12m_max',
 'card_query_in24m_max',
 '发放信用卡数',
 'com_loqurry_num',
 'com_locard_num',
 'same_com_insur_qurry_num',
 'same_com_lo_qurry_num_3m',
 'same_com_lo_card_num_3m',
 'same_com_insur_qurry_num_3m',
 'self_loan_dv_in1m',
 'self_loan_dv_in3m',
 'self_loan_dv_in6m',
 'self_loan_dv_in12m',
 'self_loan_dv_in24m',
 'self_card_query_in6m',
 'self_card_query_in3m',
 'self_card_query_in1m',
 'self_card_query_in12m',
 'self_card_query_in24m',
 'self_loan_query_in6m',
 'self_loan_query_in3m',
 'self_loan_query_in1m',
 'self_loan_query_in12m',
 'self_loan_query_in24m',
 'self_loan_query_de_f_in6m',
 'self_loan_query_de_f_in3m',
 'self_loan_query_de_f_in1m',
 'self_loan_query_de_f_in12m',
 'self_loan_query_de_f_in24m',
 'self_loan_card_query_in6m',
 'self_loan_card_query_in3m',
 'self_loan_card_query_in1m',
 'self_loan_card_query_in12m',
 'self_loan_card_query_in24m','y']]

#同值化检查
df2, feature_primaryvalue_ratio = step01_feature_engine.select_primaryvalue_ratio(df1,ratiolimit = 0.95)
#查看缺失值情况
df3,null_ratio = step01_feature_engine.select_null_ratio(df2)
    
    
var = list(df2.columns)
for i in var:
    step06_draw_plot.drawHistogram(df[i])
    
#查看缺失值情况
#step01_feature_engine.fill_null_data(df3)
df3.isnull().sum(axis=0).sort_values(ascending=False)
null_ratio = step01_feature_engine.select_null_ratio(df3)

df4 = df3.fillna(0)
df4.isnull().sum(axis=0).sort_values(ascending=False)


#IV保留大于0.02的变量
new_data,iv_value = step01_feature_engine.filter_iv(df4, group=5)
iv_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\credit\iv_value_credit.xls")

##皮尔森系数删除多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(new_data)

df5 = new_data.drop(['selfquery_in12m','card_query_in12m','query_in3m_1','selfquery6_in12m',
                     'use_credit_card_numb','selfquery6_in24m','self_loan_query_de_f_in24m',
                     'self_loan_dv_in12m','mana_loan_in12m_de_f','query_in12m', 'mana_loan_in24m',
                     'lo_query_in12m','lo_query_in6m','lo_query_in6m_de_f','self_loan_card_query_in12m',
                     'lo_query_in24m_de_f','mana_loan_in1m','query_in1m','query_in6m',
                     'mana_loan_in3m','mana_loan_in12m','self_loan_query_de_f_in1m',
                     'self_loan_query_in3m','self_loan_query_in6m','normal_card_num',
                     'self_loan_card_query_in12m','self_loan_card_query_in6m','lo_query_in12m_de_f',
                     'selfquery_in24m','self_loan_query_de_f_in12m','max_card_line',
                     'self_card_query_in24m','selfquery6_in6m','selfquery6_in3m',
                     'self_card_query_in1m','self_loan_card_query_in3m','card_query_in3m',
                     'self_loan_query_in1m','max_loanline','card_query_in1m_max',
                     'self_card_query_in12m','self_loan_query_de_f_in6m','loan_num_in24m',
                     'self_loan_query_de_f_in3m','mana_loan_in1m_de_f','selfquery6_inl3m',
                     'card_query_in6m','selfquery_in6m','self_loan_dv_in3m',
                     'mana_loan_in24m_de_f','self_card_query_in3m'], axis = 1)
pearson_coef = step02_modle_plot.plot_pearson(df5)
df6,iv_new_value = step01_feature_engine.filter_iv(df5, group=5)

iv_new_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\credit\iv_new_value3.xls")
    







