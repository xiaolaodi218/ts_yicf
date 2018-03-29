# -*- coding: utf-8 -*-
"""
Created on Tue Jan  2 11:56:38 2018

@author: Administrator
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

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

df = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\orig_data_5.csv')
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

#基于业务的原因删除 保险，微众银行，消费金融的数据,变量由223变为184个
df1 = df.drop(['apply_code','webank_query_in1m','webank_query_in3m',
 'webank_query_in6m','webank_query_in12m','webank_query_in24m','webank_loquery_in1m', 'webank_loquery_in3m', 
 'webank_loquery_in6m','webank_loquery_in12m','webank_loquery_in24m', 'webank_manaquery_in1m', 'webank_manaquery_in3m',
 'webank_manaquery_in6m','webank_manaquery_in12m', 'webank_manaquery_in24m',
 'consumerfinance_query_in1m','consumerfinance_query_in3m','consumerfinance_query_in6m',
 'consumerfinance_query_in12m','consumerfinance_query_in24m','consumerfinance_loquery_in1m',
 'consumerfinance_loquery_in3m','consumerfinance_loquery_in6m','consumerfinance_loquery_in12m',
 'consumerfinance_loquery_in24m','consumerfinance_manaquery_in1m','consumerfinance_manaquery_in3m',
 'consumerfinance_manaquery_in6m','consumerfinance_manaquery_in12m','consumerfinance_manaquery_in24m',
 'webank_query_in1m','webank_query_in3m','webank_query_in6m','webank_query_in12m','webank_query_in24m',
 'webank_loquery_in1m','webank_loquery_in3m','webank_loquery_in6m','webank_loquery_in12m','webank_loquery_in24m',
 'webank_manaquery_in1m','webank_manaquery_in3m','webank_manaquery_in6m','webank_manaquery_in12m','webank_manaquery_in24m',
 'insurquery_in1m','insurquery_in3m','insurquery_in6m','insurquery_in12m','insurquery_in24m',
 'com_insurquery_max_in3m','insurquery_com_num','webank_loan_num'], axis = 1)

##将y标签移到最后一列
last = df1['y']
df1.drop(labels=['y'], axis=1,inplace = True)
df1.insert(183, 'y', last)


#同值化检查，变量由184变为170个
df2, feature_primaryvalue_ratio = step01_feature_engine.select_primaryvalue_ratio(df1,ratiolimit = 0.90)
#查看缺失值情况
df3,null_ratio = step01_feature_engine.select_null_ratio(df2)
    
      
#查看缺失值情况
#step01_feature_engine.fill_null_data(df3)
df3.isnull().sum(axis=0).sort_values(ascending=False)
null_ratio = step01_feature_engine.select_null_ratio(df3)

df4 = df3.fillna(0)
df4.isnull().sum(axis=0).sort_values(ascending=False)

#==============================================================================
# #绘图
# var = list(df4.columns)
# for i in var:
#     step06_draw_plot.drawHistogram(df4[i])
#==============================================================================

#IV保留大于0.02的变量，170个变量保留126个
new_data,iv_value = step01_feature_engine.filter_iv(df4, group=10)

#对数据按照IV大小顺序进行排序，以便于使用fillter_pearson删除相关性较高里面IV值低的数据
list_value = iv_value[iv_value.ori_IV >= 0.02].var_name
iv_sort_columns = list(list_value.drop_duplicates())
df5 = new_data[iv_sort_columns]

iv_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\lycredit\iv_value_lycredit_group10.xls")

##皮尔森系数绘图，观察多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(df5)

#多变量分析，保留相关性低于阈值0.6的变量
#对产生的相关系数矩阵进行比较，并删除IV比较小的变量
per_col = step02_modle_plot.fillter_pearson(pearson_coef, threshold = 0.60)
print ('保留了变量有:',len(per_col))
print (per_col)   #126个变量,保留21个
df6 = new_data[['selfquery_cardquery_in3m', 'card_cardquery_rate', 'mean_cardline',
       'normal_card_num', 'selfquery_in3m_min_interval', 'max_loanline',
       'sum_carloan_line', 'near_newopen_carloan', 'can_card_rate',
       'far_open_loan', 'near_open_loan', 'inac_card_rate', 'od_card_rate',
       'min_cardline', 'clear_loan_num', 'min_cardline_f',
       'near_open_percosloan', 'bus_loan_num', 'manaquery_in6m_f',
       'com_insurquery_max', 'inac_card_num','y']]  

pearson_coef = step02_modle_plot.plot_pearson(df6)  #再次观察共线情况
per_new_data,iv_new_value = step01_feature_engine.filter_iv(df6, group=5)
iv_new_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\lycredit\iv_value_lycredit4.xls")

df6 = df6.reset_index()

#导入个人基本信息,customer_info
cus_base_data = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\middle_data\middle_data2.csv",encoding = 'utf-8')

cus_base =  cus_base_data[['age', 'education_g', 'married_g', 'sex_g', 'housing_nature_g',
                           'work_years', 
                           'company_nature_g','local_nolocal_g','child_count','monthly_salary',
                           'monthly_other_income','credit_use_ratio','desired_loan_amount', 'score','y']]
cus_base_index = cus_base.reset_index()

#共36个变量
data_all = pd.merge(cus_base_index, df6, how = 'left', on = 'index')
data_all = data_all.drop(['index', 'y_x'], axis = 1)
data_all = data_all.rename(columns = {'y_y':'y'}, copy = False)
data_all.groupby('y').size()
'''
0    1987
1     251
'''



#IV保留大于0.02的变量，170个变量保留126个
new_data_all,iv_value_all = step01_feature_engine.filter_iv(data_all, group=10)

#对数据按照IV大小顺序进行排序，以便于使用fillter_pearson删除相关性较高里面IV值低的数据
iv_value_all = iv_value_all[iv_value_all.ori_IV >= 0.02].var_name
iv_sort_columns = list(iv_value_all.drop_duplicates())
df_data = new_data_all[iv_sort_columns]

##删除相关性高的变量
pearson_coef = step02_modle_plot.plot_pearson(df_data)
per_col_all = step02_modle_plot.fillter_pearson(pearson_coef, threshold = 0.60)

print ('保留了变量有:',len(per_col_all))
print (per_col_all)   #126个变量里面80个共线,36个变量不共线,保留36个
df_data_last = new_data_all[['selfquery_cardquery_in3m', 'score', 'card_cardquery_rate',
       'housing_nature_g', 'local_nolocal_g', 'mean_cardline',
       'normal_card_num', 'selfquery_in3m_min_interval', 'max_loanline',
       'sum_carloan_line', 'monthly_other_income', 'near_newopen_carloan',
       'company_nature_g', 'can_card_rate', 'credit_use_ratio',
       'far_open_loan', 'desired_loan_amount', 'near_open_loan',
       'inac_card_rate', 'age', 'od_card_rate', 'monthly_salary',
       'min_cardline', 'clear_loan_num', 'education_g', 'min_cardline_f',
       'near_open_percosloan', 'sex_g', 'bus_loan_num', 'manaquery_in6m_f',
       'com_insurquery_max', 'inac_card_num', 'child_count','y']]  



X, y = step01_feature_engine.x_y_data(df_data_last)
##逻辑回归对共线性敏感，判断下VIF
##当VIF大于5或10时，代表模型存在严重的共线性问题
#所有自变量的VIF均低于10，说明自变量之间并不存在多重共线性的隐患。
#==============================================================================
# from statsmodels.stats.outliers_influence import variance_inflation_factor as vif
#vif_data = pd.DataFrame([])
#vif_data["VIF_Factor"] = [vif(X.values, i) for i in range(X.shape[1])]
#vif_data["features"] = X.columns
#==============================================================================
vif_data = step01_feature_engine.judge_vif(X) #两个变量VIF>10,共线

data_all_last = df_data_last.drop(["age"], axis = 1)


csvfile = r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv"
data_all_last.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')


#最终的数据,无多重共线以及IV值相对比较高的变量
data_loan = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv",encoding = 'utf-8')
data_loan = data_loan.fillna(0)


#==============================================================================
# #无多重共线的变量
# all_new_data,iv_all_value = step01_feature_engine.filter_iv(data_loan, group=5)
# iv_all_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\all\iv_value_all.xls")
# 
# #woe_sample.mono_bin(data_loan.y, data_loan.can_card_num)
# 
# ##利用卡方来进行最优分箱，但是需要花时间去手动调整分箱结果
# one_woe = pd.DataFrame([])
# new_col = list(data_loan.columns)
# new_col.remove('married_g')
# new_col.remove('open_card_num_in24m')
# new_col.remove('y')
# 
# for var in new_col:
#     new_woe = new_iv.ChiMerge(data_loan, var, 'y')
#     one_woe = one_woe.append(new_woe)
#     
# csvfile = r"F:\TS\offline_model\01_Dataset\04_Output\chi_iv\chi_iv_all.csv"
# one_woe.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
#==============================================================================
    

    
########################################################################
#经过等距分箱,卡方最优分箱,R语言中sanning包最优分箱,比较三者结果,进行手动分箱，最终IV>0.02有45个变量
loan_best_banning = data_loan[[
       'selfquery_cardquery_in3m', 'score', 'card_cardquery_rate',
       'housing_nature_g', 'local_nolocal_g', 'mean_cardline',
       'normal_card_num', 'selfquery_in3m_min_interval', 'max_loanline',
       'sum_carloan_line', 'monthly_other_income', 'near_newopen_carloan',
       'company_nature_g', 'can_card_rate', 'credit_use_ratio',
       'far_open_loan', 'desired_loan_amount', 'near_open_loan',
       'inac_card_rate', 'od_card_rate', 'monthly_salary', 'min_cardline',
       'clear_loan_num', 'education_g', 'min_cardline_f',
       'near_open_percosloan', 'sex_g', 'bus_loan_num', 'manaquery_in6m_f',
       'com_insurquery_max', 'inac_card_num', 'child_count',"y"]]


pearson_coef = step02_modle_plot.plot_pearson(loan_best_banning)


#未做one-hot编码
##构造X，y变量
X, y = step01_feature_engine.x_y_data(loan_best_banning)


## 获取每个变量的显著性p值，p值越大则越不显著。
import statsmodels.api as sm
LR = sm.Logit(X, y).fit()
summary = LR.summary()
pvals = LR.pvalues
pvals = pvals.to_dict()


##特征缩放，标准化

Col = ["selfquery_loquery_in6m",
"selfquery_cardquery_in3m",
"selfquery_in3m_min_interval",
"normal_card_num",
"housing_nature_g",
"near_house_loan",
"company_nature_g",
"can_card_rate",
"mean_cardline",
"sum_carloan_line",
"near_newopen_carloan",
"ave_percosloan_line"]

from sklearn.preprocessing import StandardScaler # 导入模块
sc = StandardScaler()
X[Col] = sc.fit_transform(X[Col])


##处理样本不平衡；当样本过少的时候建议采用这个方法
X, y = step01_feature_engine.smote_data(X, y)

model = step03_built_modle.baseline_model(X, y)
'''
confusion_matrix 
 [[1283  704]
 [ 675 1312]]
accuracy_score 0.652994464016
precision_score 0.650793650794
recall_score 0.660291897333
ROC_AUC is 0.710277346284
K-S score 0.311021640664
'''

#生成训练集测试集
X_train, X_test, y_train, y_test = step03_built_modle.train_test_split_data(X, y)

#网格搜索最优参数
best_parameters = step03_built_modle.model_optimizing(X_train,y_train)

#利用最优参数建模
model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=best_parameters)

##学习曲线


###截距和回归系数
formula = step03_built_modle.get_lr_formula(model, X)

woe = pd.read_excel(r"F:\TS\offline_model\02_DataProcess\03_best_IV\02_read_woe.xlsx")
print(len(woe.var_name.drop_duplicates()))
woe = woe[woe.ori_IV >= 0.0603]




##评分卡
scorecard = step03_built_modle.make_scorecard(formula, woe)

csvfile = r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\03scorecard_best_bin.csv"
scorecard.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

scorecard = pd.read_csv(r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\03scorecard_best_bin.csv")
inf = float("inf")
scorecard = scorecard.fillna(inf)


##再造一次X，y
X_last, y_last = step01_feature_engine.x_y_data(loan_best_banning)

feature_score = step03_built_modle.feature_score(scorecard, X_last, y_last) 
feature_score.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\feature_score1.xlsx")


##将iv中分组的group回填到 原始的样本中
  
new_col = list(X_last.columns)
bin_res_data=pd.DataFrame()
for var in new_col:
    bin_res = step03_built_modle.applyBinMap(X_last, woe, var)
    bin_res_data = pd.concat([bin_res_data,bin_res], axis = 1)



#生成编码对应的字典        
dict_code = step03_built_modle.change_dict_code(scorecard)


#生成分数
score_data = bin_res_data.replace(dict_code)
score_data.to_excel(r"F:\TS\offline_model\02_DataProcess\05_result_score\result_score1.xlsx")






#==============================================================================
#==============================================================================
'''
按照woe中group回填的编码来进行训练模型
'''

#最终的数据,无多重共线以及IV值相对比较高的变量
data_loan = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv",encoding = 'utf-8')

#经过等距分箱,卡方最优分箱,R语言中sanning包最优分箱,比较三者结果,进行手动分箱，最终IV>0.02有45个变量
loan_best_banning = data_loan[[
"selfquery_cardquery_in3m",
"local_nolocal_g",
"score",
##"selfquery_in3m_min_interval", #不具有单调性
#"normal_card_num", 
"housing_nature_g",
"company_nature_g",
##"can_card_rate",
#"mean_cardline",
"sum_carloan_line",
"near_newopen_carloan",
#"max_loanline", #上次评分卡结果太差
"far_open_loan",
#"monthly_other_income", #上次评分卡结果太差
"desired_loan_amount",
"education_g",
"near_open_percosloan",
"card_cardquery_rate",
"sex_g",
"y"]]

#观察变量相关性
pearson_coef = step02_modle_plot.plot_pearson(loan_best_banning)

#导入WOE
#woe = pd.read_excel(r"F:\TS\offline_model\02_DataProcess\03_best_IV\02_read_woe_01.xlsx")
woe = pd.read_excel(r"F:\TS\offline_model\02_DataProcess\03_best_IV\03_read_woe_03.xlsx")
print(len(woe.var_name.drop_duplicates()))
woe = woe[woe.ori_IV >= 0.0335]


X, y = step01_feature_engine.x_y_data(loan_best_banning)

##将iv中分组的group回填到 原始的样本中
  
new_col = list(X.columns)
bin_res_data=pd.DataFrame()
for var in new_col:
    bin_res = step03_built_modle.applyBinMap(X, woe, var)
    bin_res_data = pd.concat([bin_res_data,bin_res], axis = 1)
    

#未做one-hot编码
##构造X，y变量
#X, y = step01_feature_engine.x_y_data(bin_res_data)
X = bin_res_data
y = loan_best_banning['y']

##特征缩放

Col = ["selfquery_cardquery_in3m",		
"selfquery_cardquery_in3m",
"selfquery_in3m_min_interval", #不具有单调性
"housing_nature_g",
"company_nature_g",
"sum_carloan_line",
"near_newopen_carloan",
"far_open_loan",
"desired_loan_amount",
"education_g",
"near_open_percosloan",
"card_cardquery_rate",
]

from sklearn.preprocessing import MinMaxScaler

ms = MinMaxScaler()
#区间缩放，返回值为缩放到[0, 1]区间的数据
X[Col] = ms.fit_transform(X[Col])


## 获取每个变量的显著性p值，p值越大则越不显著。数据确保目标列介于0到1之间（如逻辑回归所需）
import statsmodels.api as sm

LR = sm.Logit(X, y).fit()
summary = LR.summary()
pvals = LR.pvalues
pvals = pvals.to_dict()



#==============================================================================
# from sklearn.preprocessing import StandardScaler # 导入模块
# sc = StandardScaler()
# X[Col] = sc.fit_transform(X[Col])
#==============================================================================


##处理样本不平衡；当样本过少的时候建议采用这个方法
X, y = step01_feature_engine.smote_data(X, y)

model = step03_built_modle.baseline_model(X, y)
'''
confusion_matrix 
 [[1250  737]
 [ 562 1425]]
accuracy_score 0.673125314545
precision_score 0.659111933395
recall_score 0.717161550075
ROC_AUC is 0.719034443561
K-S score 0.361780614906
'''

#生成训练集测试集
X_train, X_test, y_train, y_test = step03_built_modle.train_test_split_data(X, y)
model = step03_built_modle.baseline_model(X_train, y_train)
'''
confusion_matrix 
 [[1005  581]
 [ 445 1148]]
accuracy_score 0.677256999056
precision_score 0.663967611336
recall_score 0.720652856246
ROC_AUC is 0.721041536546
K-S score 0.361780614906
'''

#网格搜索最优参数
#best_parameters = step03_built_modle.model_optimizing(X_train,y_train)

#利用最优参数建模
model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=best_parameters)

model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=None)

##学习曲线


###截距和回归系数
formula = step03_built_modle.get_lr_formula(model, X)



##生成各变量的评分卡
scorecard = step03_built_modle.make_scorecard(formula, woe)

csvfile = r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\03scorecard_best_bin_woe6.csv"
scorecard.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

scorecard = pd.read_csv(r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\03scorecard_best_bin_woe6.csv")


#生成编码对应的字典        
dict_code = step03_built_modle.change_dict_code(scorecard)

##再造一次X，y
X_last, y_last = step01_feature_engine.x_y_data(loan_best_banning)

##将iv中分组的group回填到 原始的样本中
  
new_col = list(X_last.columns)
X_bin_data=pd.DataFrame()
for var in new_col:
    bin_res = step03_built_modle.applyBinMap(X_last, woe, var)
    X_bin_data = pd.concat([X_bin_data,bin_res], axis = 1)

#生成分数
score_data = X_bin_data.replace(dict_code)
score_data["score_sum"] = score_data.sum(axis = 1)
score_data = score_data.reset_index()

y_label = pd.DataFrame(y_last)
y_label = y_label.reset_index()

scorcarde_data = pd.merge(score_data, y_label,how = 'left', on = 'index')
scorcarde_data = scorcarde_data.drop(['index'], axis = 1)

iv_score_sum = step01_feature_engine.filter_iv(scorcarde_data, group=10)
iv_score_sum[1].to_excel(r"F:\TS\offline_model\02_DataProcess\05_result_score\model_result6.xlsx")

#画个图看下分数的分布情况
step06_draw_plot.drawHistogram(scorcarde_data['score_sum'])

#KS值>0.2就可认为模型有比较好的预测准确性











'''向后淘汰法'''

logit_instance, logit_model, logit_result, logit_result_0 = step03_statsmodels.logistic_reg(X, y, stepwise="BS")
desc, params, evaluate, quality = step03_statsmodels.logit_output(logit_instance, logit_model, logit_result, logit_result_0)
'''向前选择法
效果 目前来说 向后淘汰优于向前选择'''
logit_instance, logit_model, logit_result, logit_result_0 = step03_statsmodels.logistic_reg(X, y, stepwise="FS")
desc, params, evaluate, quality = step03_statsmodels.logit_output(logit_instance, logit_model, logit_result, logit_result_0)


import statsmodels.api as sm
X_test = sm.add_constant(X[params.index.drop("const")])

step04_moudle_evaluate.plot_roc_curve(logit_result.predict(X_test),y)
ks_results, ks_ax=step04_moudle_evaluate.ks_stats(logit_result.predict(X_test), y, k=10)
