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
0    2392
1     342
dtype: int64
12.5%
odds_ratio
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
#df3,null_ratio = step01_feature_engine.select_null_ratio(df2)
    
      
#查看缺失值情况
#step01_feature_engine.fill_null_data(df3)
df2.isnull().sum(axis=0).sort_values(ascending=False)
null_ratio = step01_feature_engine.select_null_ratio(df2)

#df4 = df3.fillna(0)
#df4.isnull().sum(axis=0).sort_values(ascending=False)

#==============================================================================
# #绘图
# var = list(df4.columns)
# for i in var:
#     step06_draw_plot.drawHistogram(df4[i])
#==============================================================================

#IV保留大于0.02的变量，170个变量保留126个
new_data,iv_value = step01_feature_engine.filter_iv(df2, group=10)

#对数据按照IV大小顺序进行排序，以便于使用fillter_pearson删除相关性较高里面IV值低的数据
list_value = iv_value[iv_value.ori_IV >= 0.02].var_name
iv_sort_columns = list(list_value.drop_duplicates())
df3 = new_data[iv_sort_columns]

iv_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\01_refresh\iv_value_refresh01.xls")

##皮尔森系数绘图，观察多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(df3)

#多变量分析，保留相关性低于阈值0.6的变量
#对产生的相关系数矩阵进行比较，并删除IV比较小的变量
per_col = step02_modle_plot.fillter_pearson(pearson_coef, threshold = 0.60)
print ('保留了变量有:',len(per_col))
print (per_col)   #126个变量,保留33个
df4 = new_data[['selfquery_cardquery_in6m','selfquery_loquery_in3m', 'card_num_fo',
       'selfquery_loquery_cardquery_in1m', 'selfquery_in3m_min_interval',
       'max_cardline', 'max_loanline', 'manaquery_in24m_def',
       'unclear_monthpay', 'min_cardline', 'near_open_loan',
       'max_carloan_line', 'min_cardline_f', 'near_newopen_carloan',
       'pettyloan_loquery_in6m', 'cardquery_in24m', 'near_house_loan',
       'inac_card_rate', 'card_cardquery_rate', 'cardquery_in6m_max',
       'selfquery5_in12m', 'card_num', 'selfquery6_in1m', 'manaquery_in1m_def',
       'can_card_num', 'cardquery_in3m', 'manaquery_in24m_f', 'clear_loan_num',
       'near_open_percosloan', 'inac_card_num', 'max_percosloan_line',
       'loan_num','y']]  

pearson_coef = step02_modle_plot.plot_pearson(df4)  #再次观察共线情况
#per_new_data,iv_new_value = step01_feature_engine.filter_iv(df6, group=5)
#iv_new_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\lycredit\iv_value_lycredit4.xls")

df5 = df4.reset_index()

#导入个人基本信息,customer_info
cus_base_data = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\middle_data\middle_data6.csv",encoding = 'utf-8')

cus_base_index = cus_base_data.reset_index()

#共36个变量
data_all = pd.merge(cus_base_index, df5, how = 'left', on = 'index')
data_all = data_all.drop(['index', 'y_x'], axis = 1)
data_all = data_all.rename(columns = {'y_y':'y'}, copy = False)
data_all.groupby('y').size()
'''
0    2392
1     342
'''

##等距分箱
new_data_all,iv_value_all = step01_feature_engine.filter_iv(data_all, group=10)
iv_value_all.to_csv(r"F:\TS\offline_model\01_Dataset\04_Output\01_refresh\iv_value_all.csv")

csvfile = r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv"
data_all.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

data_all = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv")


##利用卡方来进行最优分箱，但是需要花时间去手动调整分箱结果
#==============================================================================
#基于卡方的最优分箱
# one_woe = pd.DataFrame([])
# new_col = list(data_all.columns)
# new_col.remove('near_open_percosloan')
# new_col.remove('y')
# 
# for var in new_col:
#     new_woe = new_iv.ChiMerge(data_all, var, 'y')
#     one_woe = one_woe.append(new_woe)
#     print(var)
#     
# csvfile = r"F:\TS\offline_model\01_Dataset\04_Output\chi_iv\chi_iv_all.csv"
# one_woe.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

#基于step02_bining的最优分箱
X, y = step01_feature_engine.x_y_data(data_all)
new_col = ['work_years','social_fund_basenum','cal_yearly_income','external_debat_ratio',
           'cal_debat_ratio1', 'selfquery_cardquery_in6m',
           'selfquery_loquery_in3m', 'card_num_fo',
           'selfquery_loquery_cardquery_in1m', 'selfquery_in3m_min_interval',
           'max_cardline', 'max_loanline', 'manaquery_in24m_def', 'near_open_loan',
           'max_carloan_line', 'near_newopen_carloan', 'pettyloan_loquery_in6m',
           'cardquery_in24m', 'near_house_loan', 'cardquery_in6m_max',
           'selfquery5_in12m', 'card_num', 'selfquery6_in1m', 'can_card_num',
           'cardquery_in3m', 'manaquery_in24m_f', 'max_percosloan_line',]
woe_bin_data=pd.DataFrame()
for var in new_col:
    woe_bin = step02_bining.binContVar(X[var], y, method=4)
    woe_bin['var_name'] =var    
    woe_bin_data = woe_bin_data.append(woe_bin)
    print(var)

#==============================================================================

#经过等距分箱,卡方最优分箱,R语言中sanning包最优分箱,比较三者结果,进行手动分箱，最终IV>0.02有38个变量
df_data_last = data_all.drop(['salary_grant_type_g','education_g','manaquery_in1m_def',
                              'other_debet','credit_use_ratio','min_cardline','clear_loan_num',
                              'min_cardline_f','inac_card_rate','card_cardquery_rate',
                              'near_open_percosloan','inac_card_num','loan_num',
                              'unclear_monthpay','can_card_num'], axis = 1)

pearson_coef = step02_modle_plot.plot_pearson(df_data_last)
#变量里面已经没有多重共线的


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

#data_all_last = df_data_last.drop(["age"], axis = 1)


csvfile = r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv"
df_data_last.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')


#最终的数据,无多重共线以及IV值相对比较高的变量
data_loan = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv",encoding = 'utf-8')
#data_loan = data_loan.fillna(0)
    
########################################################################
'''
按照woe中group回填的编码来进行训练模型
'''

#本次选取28个比较高的变量进入模型
loan_best_banning = data_loan[[
                            #"group_level",
                            "selfquery_cardquery_in6m",
                            "housing_nature_g",
                            "selfquery_loquery_in3m",
                            #"local_nolocal_g",
                            "social_fund_basenum",
                            "selfquery_in3m_min_interval",
                            "card_num_fo", #变量不好解释
                            #"asset_g",
                            #"selfquery_loquery_cardquery_in1m",
                            "work_years",
                            #"external_debat_ratio",
                            "desired_loan_amt_g",
                            "apply_city_g",
                            "max_loanline",
                            "max_cardline",
                            "cal_debat_ratio2",
                            #"pettyloan_loquery_in6m",
                            #"selfquery6_in1m",                         
                            "near_open_loan",
                            "company_nature_g",
                            #"apply_product_g",
                            "sex_g",
                            #"cardquery_in6m_max",
                            "selfquery5_in12m",
                            "cal_yearly_income",
                            "card_num",
                            "married_g",
                            "cardquery_in3m", 
                            "cardquery_in24m",
                            "max_percosloan_line",#个人消费贷缺失多
                            "cal_debat_ratio1",
                            "y"]]
print(loan_best_banning.shape[1]-1)
#观察变量相关性
pearson_coef = step02_modle_plot.plot_pearson(loan_best_banning)


#未做one-hot编码
##构造X，y变量
X_new, y_new = step01_feature_engine.x_y_data(loan_best_banning)


## 获取每个变量的显著性p值，p值越大则越不显著。
#==============================================================================
# import statsmodels.api as sm
# LR = sm.Logit(X, y).fit()
# summary = LR.summary()
# pvals = LR.pvalues
# pvals = pvals.to_dict()
#==============================================================================


#导入WOE
#woe = pd.read_excel(r"F:\TS\offline_model\02_DataProcess\03_best_IV\02_read_woe_01.xlsx")
woe = pd.read_excel(r"F:\TS\offline_model\02_DataProcess\03_best_IV\06_read_woe_refresh_Jan_02.xlsx")
print(len(woe.var_name.drop_duplicates()))
woe = woe[woe.ori_IV >= 0.05]
print(len(woe.var_name.drop_duplicates()))


#==============================================================================
# ##将iv中分组的group回填到 原始的样本中
#   
# new_col = list(X.columns)
# bin_res_data=pd.DataFrame()
# for var in new_col:
#     bin_res = step03_built_modle.applyBinMap(X, woe, var)
#     bin_res_data = pd.concat([bin_res_data,bin_res], axis = 1)
#==============================================================================

##将iv中分组的WOE回填到原始的样本中
def applyBinMap(X_data, bin_map, var):
    x = X_data[var]
    bin_map = bin_map[bin_map['var_name'] == var]
    bin_res = np.array([0] * x.shape[-1], dtype=float)
    
    for i in bin_map.index:
        upper = bin_map['max'][i]
        lower = bin_map['min'][i]
        if lower == upper:
            x1 = x[np.where(x >= lower)[0]]
        else:
            x1 = x[np.where((x >= lower) & (x < upper))[0]]  #会去筛选矩阵里面符合条件的值
        mask = np.in1d(x, x1)    #用于测试一个数组中的值在另一个数组中的成员资格,返回布尔型数组
        bin_res[mask] = bin_map['WOE'][i]   #将Ture的数据替换掉
    
    bin_res = pd.Series(bin_res, index=x.index)
    bin_res.name = x.name
    
    return bin_res


  
new_col = list(X_new.columns)
bin_res_data=pd.DataFrame()
for var in new_col:
    bin_res = applyBinMap(X_new, woe, var)
    bin_res_data = pd.concat([bin_res_data,bin_res], axis = 1)
    

#未做one-hot编码
##构造X，y变量
#X, y = step01_feature_engine.x_y_data(bin_res_data)
X = bin_res_data
y = loan_best_banning['y']


vif_data = step01_feature_engine.judge_vif(X) #两个变量VIF>10,共线

##特征缩放

#==============================================================================
# Col = ['group_level', 'selfquery_cardquery_in6m', 'selfquery_in3m_min_interval',
#        'work_years','cal_debat_ratio2']
# 
# from sklearn.preprocessing import MinMaxScaler
# 
# ms = MinMaxScaler()
# #区间缩放，返回值为缩放到[0, 1]区间的数据
# X[Col] = ms.fit_transform(X[Col])
# 
# 
# ## 获取每个变量的显著性p值，p值越大则越不显著。数据确保目标列介于0到1之间（如逻辑回归所需）
# import statsmodels.api as sm
# 
# LR = sm.Logit(X, y).fit()
# summary = LR.summary()
# pvals = LR.pvalues
# pvals = pvals.to_dict()
# 
#==============================================================================


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
 [[1531  861]
 [ 764 1628]]
accuracy_score 0.668147373922
precision_score 0.663346613546
recall_score 0.691588785047
ROC_AUC is 0.728932086353
K-S score 0.354737526648'''


'''or: '''   

model = log_model_test(X,y)
    


#生成训练集测试集
X_train, X_test, y_train, y_test = step03_built_modle.train_test_split_data(X, y)
model = step03_built_modle.baseline_model(X_train, y_train)
'''
confusion_matrix 
 [[1212  689]
 [ 611 1315]]
accuracy_score 0.660308335511
precision_score 0.65618762475
recall_score 0.682762201454
ROC_AUC is 0.707323931275

K-S score 0.32472770794
'''

#网格搜索最优参数
#best_parameters = step03_built_modle.model_optimizing(X_train,y_train)

#利用最优参数建模
#model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=best_parameters)

#利用默认参数建模
model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=None)



##学习曲线


###截距和回归系数
formula = step03_built_modle.get_lr_formula(model, X)



##生成各变量的评分卡
scorecard = step03_built_modle.make_scorecard(formula, woe)

csvfile = r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\06scorecard_best_bin_Jan.csv"
scorecard.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

scorecard = pd.read_csv(r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\06scorecard_best_bin_Jan.csv")


#生成编码对应的字典        
dict_code = step03_built_modle.change_dict_code(scorecard)

#==============================================================================
# ##再造一次X，y
# X_last, y_last = step01_feature_engine.x_y_data(loan_best_banning)
# 
# 
# ##将iv中分组的group回填到 原始的样本中
#   
# new_col = list(X_last.columns)
# X_bin_data=pd.DataFrame()
# for var in new_col:
#     bin_res = step03_built_modle.applyBinMap(X_last, woe, var)
#     X_bin_data = pd.concat([X_bin_data,bin_res], axis = 1)
#==============================================================================

#生成分数
score_data = bin_res_data.replace(dict_code)
score_data["score_sum"] = score_data.sum(axis = 1)

#拼接y值
scorcarde_data = pd.concat([score_data, loan_best_banning['y']], axis =1)

iv_score_sum = step01_feature_engine.filter_iv(scorcarde_data, group=10)
iv_score_sum[1].to_excel(r"F:\TS\offline_model\02_DataProcess\05_result_score\model_result6_Jan.xlsx")
score_group = iv_score_sum[1]

#画个图看下分数的分布情况
step06_draw_plot.drawHistogram(scorcarde_data['score_sum'])
v_feat = ['score_sum']
step02_modle_plot.prob_density(scorcarde_data, v_feat)

'''评分卡'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
#plt.subplot2grid((2,3),(1,0), colspan=2)
scorcarde_data.score_sum[scorcarde_data.y == 0].plot(kind='kde')   
scorcarde_data.score_sum[scorcarde_data.y == 1].plot(kind='kde')
plt.xlabel(u"score_sum")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of score_sum")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

#KS值>0.2就可认为模型有比较好的预测准确性





















##建议先使用逐步法(P值限制为0.05，而不是0.01)
'''向前选择法(逐步法)'''
'''提高了选择最佳预测变量的能力，但是几乎不考虑一些低显著性的变量，
而且降低了处理速度，因为每一步都要考虑每一个变量的加入与删除'''
logit_instance, logit_model, logit_result, logit_result_0 = step03_statsmodels.logistic_reg(X, y, stepwise="FS")
desc, params, evaluate, quality = step03_statsmodels.logit_output(logit_instance, 
                                                                  logit_model, logit_result, logit_result_0)


'''向后淘汰法,不能使用过采样'''
'''从全部的备选变量中依次删除“最不显著”的变量，会保留一些低显著性的变量，
这些变量独立预测的能力不高，但是与其他变量结合会提升模型整体的预测能力'''
logit_instance, logit_model, logit_result, logit_result_0 = step03_statsmodels.logistic_reg(X, y, stepwise="BS")
desc, params, evaluate, quality = step03_statsmodels.logit_output(logit_instance,
                                                                  logit_model, logit_result, logit_result_0)



import statsmodels.api as sm
X_test = sm.add_constant(X[params.index.drop("const")])

step04_moudle_evaluate.plot_roc_curve(logit_result.predict(X_test),y)
ks_results, ks_ax=step04_moudle_evaluate.ks_stats(logit_result.predict(X_test), y, k=20)
















#逻辑回归
from sklearn.linear_model import LogisticRegression
lr = LogisticRegression()
lr.fit(X_train,y_train)
#preds 就是一个得分是用来画ROC曲线，从而计算GINI
preds=lr.predict_proba(X_test)
prob = pd.DataFrame(lr.predict_proba(X_test),columns=['B','G'])
preds = prob['G']

#SVM 模型
from sklearn.svm import SVC
svc = SVC(kernel = 'rbf',class_weight='balanced',probability = True)
svc.fit(X_train,y_train)
#preds 就是一个得分是用来画ROC曲线，从而计算GINI
prob = pd.DataFrame(svc.predict_proba(X_test),columns=['B','G'])
preds = prob['G']

#RadomForest
from sklearn.ensemble import RandomForestClassifier
rf = RandomForestClassifier(n_estimators = 100 ,min_samples_split = 60, \
                            max_depth = 3,max_features = 4,class_weight= 'balanced')
rf.fit(X_train, y_train)#进行模型的训练
#preds 就是一个得分是用来画ROC曲线，从而计算GINI
prob = pd.DataFrame(rf.predict_proba(X_test),columns=['B','G'])
preds = prob['G']


#GBDT
from sklearn.ensemble import GradientBoostingClassifier
gbdt = GradientBoostingClassifier(max_depth=2,max_features=12,n_estimators=100,\
                                  loss = 'exponential',learning_rate = 0.1 ,min_samples_leaf = 50)
gbdt.fit(X_train,y_train)
#preds 就是一个得分是用来画ROC曲线，从而计算GINI
prob = pd.DataFrame(gbdt.predict_proba(X_test),columns=['B','G'])
preds = prob['G']

#建立MLPClassifier(神经网络)
from sklearn.neural_network import MLPClassifier
mlp = MLPClassifier(hidden_layer_sizes = (15,12), activation = 'relu', max_iter = 100)
mlp.fit(X_train , y_train)
#preds 就是一个得分是用来画ROC曲线，从而计算GINI
prob =pd.DataFrame(mlp.predict_proba(X_test),columns=['B','G'])
preds = prob['G']

#模型评估
from sklearn.metrics import roc_auc_score
auc = roc_auc_score(y_test, preds)
GINI = (auc-0.5)*2
#precision  recall  f1-score
from sklearn.metrics import classification_report
step02_modle_plot.model_evaluation_plot(model, X, y, ksgroup=20)      
    