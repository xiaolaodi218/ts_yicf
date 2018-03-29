# -*- coding: utf-8 -*-
"""
Created on Fri Mar 16 16:57:53 2018

@author: Administrator
"""

import pandas as pd

sys.path.append(r"F:\TS\offline_model\lib")
import step01_feature_engine
import step02_modle_plot
import step03_built_modle


path = r'F:\TS\external_data_test\tq_data.xlsx'  
df= pd.read_excel(path)  

df.groupby('y').size()
'''
y
0    2656
1     359
dtype: int64
'''

iv_score_sum = step01_feature_engine.filter_iv(df, group=10)
tq_score_group = iv_score_sum[1]

'''
                        var_name    ori_IV
group_num                                 
0.0                  fraud_level  0.558952
0.0        tianqi_score_loan_dt1  0.548399
0.0        tianqi_score_loan_dt2  0.496616
0.0                     is_black  0.486085
0.0        credit_score_loan_dt2  0.060653
0.0        credit_score_loan_dt1  0.049207
'''

tq_score_group.to_excel(r"F:\TS\external_data_test\tq_score_group_10.xlsx")
