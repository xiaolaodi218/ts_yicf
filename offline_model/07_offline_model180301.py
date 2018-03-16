# -*- coding: utf-8 -*-
"""
Created on Tue March 02 11:56:38 2018

@author: Yichengfan
"""

#======================================== 导入模块======================================
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

#======================================== 导入数据======================================
#259个变量
df = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\orig_data_develop.csv')
df.columns = df.columns.str.lower()  #列名变为小写
df = df.rename(columns = {'target':'y'}, copy = False)
df.groupby('y').size()
'''
y
0    2867
1     527
dtype: int64
15.5%
odds = 7.12
'''

#基于业务的原因删除 保险，微众银行，消费金融，贷后管理，小额贷款
#车贷，经营性贷款，房贷，个人消费贷款(覆盖率太低)的数据,变量由259变为167个
df1 = df.drop(['apply_code','放款月份','进件时间','是否有车','是否有房',
'贷款月还','信用卡月还','准贷记卡月还',
 'webank_query_in1m','webank_query_in3m','webank_query_in6m','webank_query_in12m','webank_query_in24m',
 'webank_loquery_in1m', 'webank_loquery_in3m', 'webank_loquery_in6m','webank_loquery_in12m',
 'webank_loquery_in24m', 'webank_manaquery_in1m', 'webank_manaquery_in3m',
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
 'com_insurquery_max_in3m','insurquery_com_num','webank_loan_num',
"manaquery_in12m","manaquery_in12m_def","manaquery_in12m_f","manaquery_in1m","manaquery_in1m_def",
"manaquery_in1m_f","manaquery_in24m","manaquery_in24m_def","manaquery_in24m_f","manaquery_in3m",
"manaquery_in3m_def","manaquery_in3m_f","manaquery_in6m","manaquery_in6m_def","manaquery_in6m_f",
"pettyloan_query_in1m","pettyloan_manaquery_in1m","pettyloan_query_in3m","pettyloan_manaquery_in3m",
"pettyloan_query_in6m","pettyloan_manaquery_in6m","pettyloan_query_in12m",
"pettyloan_manaquery_in12m","pettyloan_query_in24m","pettyloan_loquery_in24m","pettyloan_manaquery_in24m",
"card_num_fo","consumloan_num","otherloan_num","max_carloan_line","min_carloan_line",
"ave_carloan_line","sum_carloan_line","max_manloan_line","min_manloan_line","ave_manloan_line",
"sum_manloan_line","near_newopen_manloan","max_houseloan_line","min_houseloan_line","ave_houseloan_line",
"sum_houseloan_line","max_percosloan_line","min_percosloan_line","ave_percosloan_line","sum_percosloan_line",
], axis = 1)

#======================================== 同值化，缺失值检验======================================

#同值化检查，变量由167变为158个
df2, feature_primaryvalue_ratio = step01_feature_engine.select_primaryvalue_ratio(df1,ratiolimit = 0.90)

#查看缺失值情况
df3,null_ratio = step01_feature_engine.select_null_ratio(df2)
    
      
#查看缺失值情况
step01_feature_engine.fill_null_data(df2)
#df2.isnull().sum(axis=0).sort_values(ascending=False)
#null_ratio = step01_feature_engine.select_null_ratio(df2)

df4 = df3.fillna(0)
df4.isnull().sum(axis=0).sort_values(ascending=False)

#==============================================================================
# #绘图
# var = list(df4.columns)
# for i in var:
#     step06_draw_plot.drawHistogram(df4[i])
#==============================================================================

mapping_dict1 = {
    "申请产品": {"U贷通":0, "E网通":1, "E保通":1, "E微贷":1, "E房通":1, "E社通":1,"E保通-自雇":1},
    "教育程度": {"硕士及其以上":0, "大学本科":0, "专科":1, "高中":2, "中专":2, "初中":2, "小学":2,"未知":2},
    "申请城市":{"上海":0, "厦门":0, "成都":0,"南京":0,"重庆":0, "海口":1,"乌鲁木齐":1,"杭州":1,"惠州":1,"昆明":1,
               "福州":1,"广州":1,"合肥":1, "南宁":1,"银川":1,"邵阳":1, "深圳":1,"江门":1,"盐城":1,"红河":1,
               "武汉":1, "佛山":1,"南通":1, "郑州":1,},
    "婚姻状况": {"已婚":0, "离异":1,"丧偶":1,"未婚":1},
    "性别": {"男":0, "女":1},
    "住房性质": {"无按揭购房":0, "公积金按揭购房":1,"商业按揭房":1,"自建房":1, "亲属住房":1, 
                "租用":2, "公司宿舍":2, "其他":2},
    "薪资发放方式": {"打卡":0, "银行代发":0, "均有":1, "现金":2, "其他":2},
    "职级": {"高级管理人员":0, "中级管理人员":0, "法人":0, "一般管理人员":1, "一般正式员工":1,
            "派遣员工":2,"负责人":2,"退休人员":2,"非正式员工":2},
    "单位性质": {"机关事业单位":0, "私营企业":1,"国有股份":1, "民营企业":1, "合资企业":1,"外资企业":1, "个体":1,"社会团体":1},
    "财产信息": {"有房无车":0,"有房有车":0,"有车无房":0,"无车无房":1},
    "是否本地": {"本地":1,"外地":0},
    "group_level": {"A":0,"B":1,"C":2,"D":3,"E":4},
    "risk_level": {"低":0,"中":1,"高":2}}

df5 = df4.replace(mapping_dict1) #变量映射

##df5.贷款申请期限 = df5.贷款申请期限.map({36:0,24:1,18:1,12:1,6:1})
df5.子女个数 = df5.子女个数.map({0:0,1:1,2:2,3:2,4:2,5:2})

df5[['申请产品','教育程度','申请城市','婚姻状况','性别','住房性质','薪资发放方式','单位性质',
     '财产信息','是否本地','group_level','risk_level','子女个数']].head() #查看效果

df6 = df5.rename(columns = {
        "申请产品":"apply_product_g", "申请城市":"apply_city_g", "申请贷款金额":"desired_loan_amt_g",
         "住房性质":"housing_nature_g", "教育程度":"education_g",
        "婚姻状况":"married_g","性别":"sex_g", "单位性质":"company_nature_g","是否本地":"local_nolocal_g",
        "财产信息":"asset_g", "薪资发放方式":"salary_grant_type_g","职级":"job_level_g",
        "子女个数":"child_counts_g","工作年限":"work_years","年龄":"age", "月收入":"month_salary",
        "月其他收入":"month_other_income_g", "社保公积基数":"social_fund_basenum",
        "其他负债":"other_debet", "简版汇总负债总计":"debet_all", "征信负债率":"external_debat_ratio",
        "信用卡使用率":"credit_use_ratio","计算年收入":"cal_yearly_income", 
        "计算负债率1":"cal_debat_ratio1", "计算负债率2":"cal_debat_ratio2",}, copy = False)


##将y标签移到最后一列
last = df1['y']
df6.drop(labels=['y'], axis=1,inplace = True)
df6.insert(157, 'y', last)

#======================================== 变量筛选，IV值和相关系数======================================

#IV保留大于0.02的变量，158个变量保留111个
new_data,iv_value = step01_feature_engine.filter_iv(df6, group=10)

#对数据按照IV大小顺序进行排序，以便于使用fillter_pearson删除相关性较高里面IV值低的数据
list_value = iv_value[iv_value.ori_IV >= 0.02].var_name
iv_sort_columns = list(list_value.drop_duplicates())
df7 = new_data[iv_sort_columns]

iv_value.to_excel(r"F:\TS\offline_model\output\iv_value_group01.xls")

##皮尔森系数绘图，观察多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(df7)

#多变量分析，保留相关性低于阈值0.6的变量
#对产生的相关系数矩阵进行比较，并删除IV比较小的变量
per_col = step02_modle_plot.fillter_pearson(pearson_coef, threshold = 0.60)
print ('保留了变量有:',len(per_col))
print (per_col)   #135个变量,保留35个
df8 = df6[[          
       'selfquery_cardquery_in6m', 'group_level',
       'housing_nature_g','selfquery6_in3m', 'selfquery_in3m_min_interval',
       'selfquery_loquery_cardquery_in1m', 'pettyloan_loquery_in6m',
       'local_nolocal_g', 'social_fund_basenum', 'desired_loan_amt_g',
       'asset_g', 'mean_cardline', 'loquery_in24m_def', 'month_other_income_g',
       'apply_city_g', 'max_loanline', 'near_open_loan', 'salary_grant_type_g',
       'credit_use_ratio', 'card_cardquery_rate', 'sex_g', 'min_cardline',
       'com_cardquery_max_in3m', 'card_num', 'company_nature_g',
       'near_newopen_carloan', 'com_loquery_max_in3m', 'work_years',
       'near_open_percosloan', 'min_cardline_f', 'normal_card_num',
       'other_debet', 'clear_loan_num', 'married_g', 'cal_debat_ratio2','y']]  

pearson_coef = step02_modle_plot.plot_pearson(df8)  #再次观察共线情况
per_new_data,iv_new_value = step01_feature_engine.filter_iv(df8, group=10)
iv_new_value.to_excel(r"F:\TS\offline_model\output\iv_value_group02.xls")


csvfile = r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv"
df8.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

data_all = pd.read_csv(csvfile, encoding = 'utf-8')
#删除最优分箱时候表现差的变量,保留的变量有：
data_all_best = data_all[[
'selfquery_cardquery_in6m', 'group_level',
       'housing_nature_g','selfquery6_in3m', 'selfquery_in3m_min_interval',
       'selfquery_loquery_cardquery_in1m', 'pettyloan_loquery_in6m',
       'local_nolocal_g', 'social_fund_basenum', 'desired_loan_amt_g',
       'asset_g', 'mean_cardline', 'loquery_in24m_def', 'month_other_income_g',
       'apply_city_g', 'max_loanline', 'near_open_loan', 'salary_grant_type_g',
       'credit_use_ratio', 'card_cardquery_rate', 'sex_g', 'min_cardline',
       'com_cardquery_max_in3m', 'card_num', 'company_nature_g',
       'near_newopen_carloan', 'com_loquery_max_in3m', 'work_years',
       'near_open_percosloan', 'min_cardline_f', 'normal_card_num',
       'other_debet', 'clear_loan_num', 'married_g', 'cal_debat_ratio2','y']]




##利用卡方来进行最优分箱，但是需要花时间去手动调整分箱结果
#==============================================================================
#==============================================================================
# #基于卡方的最优分箱
# one_woe = pd.DataFrame([])
# new_col = list(df8.columns)
# new_col.remove('near_open_percosloan')
# new_col.remove('y')
#  
# for var in new_col:
#     new_woe = new_iv.ChiMerge(df8, var, 'y')
#     one_woe = one_woe.append(new_woe)
#     print(var)
# #     
#csvfile = r"F:\TS\offline_model\02_DataProcess\03_best_IV\IV_output_refresh\chi1_iv_all02_refresh.csv"
#one_woe.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
#==============================================================================

#基于step02_bining的最优分箱
#==============================================================================
# X, y = step01_feature_engine.x_y_data(df8)
# new_col = ['work_years','social_fund_basenum','cal_yearly_income','external_debat_ratio',
#             'selfquery_cardquery_in6m','selfquery_loquery_in3m', 'card_num_fo',
#            'selfquery_loquery_cardquery_in1m', 'selfquery_in3m_min_interval',
#            'max_loanline', 'manaquery_in24m_def', 'near_open_loan',
#            'pettyloan_loquery_in6m',
#            'cardquery_in6m_max',
#            'selfquery6_in1m',
#            'cardquery_in3m', 'max_percosloan_line',]
# woe_bin_data=pd.DataFrame()
# for var in new_col:
#     woe_bin = step02_bining.binContVar(X[var], y, method=4)
#     woe_bin['var_name'] =var    
#     woe_bin_data = woe_bin_data.append(woe_bin)
#     print(var)
# 
# csvfile = r"F:\TS\offline_model\02_DataProcess\03_best_IV\IV_output_refresh\chi2_iv_all02_refresh.csv"
# woe_bin_data.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
#==============================================================================


#======================================== 开始建模，28个变量======================================


csvfile = r"F:\TS\offline_model\01_Dataset\02_Interim\all_data\data_loan.csv"
#data_all_best.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')


#最终的数据,无多重共线以及IV值相对比较高的变量
data_loan = pd.read_csv(csvfile, encoding = 'utf-8')
#data_loan = data_loan.fillna(0)
    
pearson_coef = step02_modle_plot.plot_pearson(data_loan)

#本次选取19个比较高的变量进入模型;由于vif几个比较高，
#而且模型的最终的结果也是表现了有的变量多重共线严重，so删除了几个变量
loan_best_banning = data_loan[[
       'selfquery_cardquery_in6m', 
       'group_level',
       'housing_nature_g',
       #'selfquery6_in3m', 
       'selfquery_in3m_min_interval',
       'selfquery_loquery_cardquery_in1m',
       #'pettyloan_loquery_in6m',
    #   'local_nolocal_g', 
       'desired_loan_amt_g',
       'asset_g', 
       #'loquery_in24m_def',
       #'month_other_income_g',
       'apply_city_g',
       'social_fund_basenum', 
       'mean_cardline', 
       'sex_g',  
       'company_nature_g',       
       #'near_open_loan',
       'salary_grant_type_g',
       'max_loanline', 
       #'credit_use_ratio', 
       #'card_cardquery_rate', 
       #'min_cardline',
       #'com_cardquery_max_in3m',
       #'card_num', 
       #'near_newopen_carloan', 
       #'com_loquery_max_in3m', 
     #  'work_years',
       #'near_open_percosloan',
       #'min_cardline_f', 
       #'normal_card_num',
       #'other_debet', 
       #'clear_loan_num',
       'married_g', 
       #'cal_debat_ratio2',                           
       "y"]]
print(loan_best_banning.shape[1]-1)
#观察变量相关性

X, y = step01_feature_engine.x_y_data(loan_best_banning)

##逻辑回归对共线性敏感，判断下VIF
##当VIF大于5或10时，代表模型存在严重的共线性问题
#所有自变量的VIF均低于10，说明自变量之间并不存在多重共线性的隐患。
vif_data = step01_feature_engine.judge_vif(X) #3个变量VIF>5,共线

pearson_coef = step02_modle_plot.plot_pearson(loan_best_banning)


#导入WOE
#woe = pd.read_excel(r"F:\TS\offline_model\02_DataProcess\03_best_IV\02_read_woe_01.xlsx")
woe = pd.read_excel(r"F:\TS\offline_model\output\02_best_iv\02_best_iv.xlsx")
print(len(woe.var_name.drop_duplicates()))

X, y = step01_feature_engine.x_y_data(loan_best_banning)

##将iv中分组的WOE回填到原始的样本中 
new_col = list(X.columns)
bin_res_data=pd.DataFrame()
for var in new_col:
    bin_res = step03_built_modle.applyBinMap(X, woe, var)
    bin_res_data = pd.concat([bin_res_data,bin_res], axis = 1)
    

#未做one-hot编码
X = bin_res_data
y = loan_best_banning['y']


vif_data = step01_feature_engine.judge_vif(X) 

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
best_parameters = step03_built_modle.model_optimizing(X_train,y_train)

#利用最优参数建模
model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=best_parameters)

#利用默认参数建模
model = step03_built_modle.make_model(X_train,y_train,X_test, y_test,best_parameters=None)



##学习曲线


###截距和回归系数
formula = step03_built_modle.get_lr_formula(model, X)



##生成各变量的评分卡
scorecard = step03_built_modle.make_scorecard(formula, woe)

csvfile = r"F:\TS\offline_model\output\03_scorecard\scorecard_0101.csv"
scorecard.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

scorecard = pd.read_csv(csvfile)

def change_dict_code(scorecard):
    '''
    构造WOE和score对应的一个字典,类似下面
    {score:{2: -1.17, 1: 20.04,0: 75.46}, }
    '''
    dict_code={}
    for i in scorecard.var_name.drop_duplicates():
        temp=scorecard[scorecard["var_name"]==i].set_index("WOE").T.to_dict("records")
        dict_code[i]=temp[6]
    return dict_code

#生成编码对应的字典        
#dict_code = step03_built_modle.change_dict_code(scorecard)
dict_code = change_dict_code(scorecard)
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
score_group = iv_score_sum[1]
score_group.to_excel(r"F:\TS\offline_model\output\04_model_result\model_result0101.xlsx")


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





#========================================对验证集进行数据清洗===============================

dv = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\orig_data_validate.csv')
dv.columns = dv.columns.str.lower()  #列名变为小写
dv = dv.rename(columns = {'target':'y'}, copy = False)
dv.groupby('y').size()
'''
y
0    1680
1     138
dtype: int64
7.6%
odds =12.2
'''
      
dv1 = dv.fillna(0)
dv1.isnull().sum(axis=0).sort_values(ascending=False)

mapping_dict1 = {
    "申请产品": {"U贷通":0, "E网通":1, "E保通":1, "E微贷":1, "E房通":1, "E社通":1,"E保通-自雇":1},
    "教育程度": {"硕士及其以上":0, "大学本科":0, "专科":1, "高中":2, "中专":2, "初中":2, "小学":2,"未知":2},
    "申请城市":{"上海":0, "厦门":0, "成都":0,"南京":0,"重庆":0, "海口":1,"乌鲁木齐":1,"杭州":1,"惠州":1,"昆明":1,
               "福州":1,"广州":1,"合肥":1, "南宁":1,"银川":1,"邵阳":1, "深圳":1,"江门":1,"盐城":1,"红河":1,
               "武汉":1, "佛山":1,"南通":1, "郑州":1, "北京":1},
    "婚姻状况": {"已婚":0, "离异":1,"丧偶":1,"未婚":1},
    "性别": {"男":0, "女":1},
    "住房性质": {"无按揭购房":0, "公积金按揭购房":1,"商业按揭房":1,"自建房":1, "亲属住房":1, 
                "租用":2, "公司宿舍":2, "其他":2},
    "薪资发放方式": {"打卡":0, "银行代发":0, "均有":1, "现金":2, "其他":2},
    "职级": {"高级管理人员":0, "中级管理人员":0, "法人":0, "一般管理人员":1, "一般正式员工":1,
            "派遣员工":2,"负责人":2,"退休人员":2,"非正式员工":2},
    "单位性质": {"机关事业单位":0, "私营企业":1,"国有股份":1, "民营企业":1, "合资企业":1,"外资企业":1, "个体":1,"社会团体":1},
    "财产信息": {"有房无车":0,"有房有车":0,"有车无房":0,"无车无房":1},
    "是否本地": {"本地":0,"外地":1},
    "group_level": {"A":0,"B":1,"C":2,"D":3,"E":4},
    "risk_level": {"低":0,"中":1,"高":2}}

dv2 = dv1.replace(mapping_dict1) #变量映射

##df5.贷款申请期限 = df5.贷款申请期限.map({36:0,24:1,18:1,12:1,6:1})
dv2.子女个数 = dv2.子女个数.map({0:0,1:1,2:2,3:2,4:2,5:2})

dv2[['申请产品','教育程度','申请城市','婚姻状况','性别','住房性质','薪资发放方式','单位性质',
     '财产信息','是否本地','group_level','risk_level','子女个数']].head() #查看效果

dv3 = dv2.rename(columns = {
        "申请产品":"apply_product_g", "申请城市":"apply_city_g", "申请贷款金额":"desired_loan_amt_g",
         "住房性质":"housing_nature_g", "教育程度":"education_g",
        "婚姻状况":"married_g","性别":"sex_g", "单位性质":"company_nature_g","是否本地":"local_nolocal_g",
        "财产信息":"asset_g", "薪资发放方式":"salary_grant_type_g","职级":"job_level_g",
        "子女个数":"child_counts_g","工作年限":"work_years","年龄":"age", "月收入":"month_salary",
        "月其他收入":"month_other_income_g", "社保公积基数":"social_fund_basenum",
        "其他负债":"other_debet", "简版汇总负债总计":"debet_all", "征信负债率":"external_debat_ratio",
        "信用卡使用率":"credit_use_ratio","计算年收入":"cal_yearly_income", 
        "计算负债率1":"cal_debat_ratio1", "计算负债率2":"cal_debat_ratio2",}, copy = False)

dv4 =  dv3[['selfquery_cardquery_in6m', 
           'group_level',
           'housing_nature_g',
           'selfquery_in3m_min_interval',
           'selfquery_loquery_cardquery_in1m',
           'local_nolocal_g', 
           'desired_loan_amt_g',
           'asset_g', 
           'apply_city_g',
           'social_fund_basenum', 
           'mean_cardline', 
           'sex_g',  
           'company_nature_g',       
           'salary_grant_type_g',
           'max_loanline', 
           'work_years',
           'married_g', 
            "y"]]


#========================================对验证集进行打分===============================

csvfile = r"F:\TS\offline_model\output\05_valid_data\valid_data.csv"
#dv4.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

valid_data = pd.read_csv(csvfile)
valid_data = valid_data[[
       'selfquery_cardquery_in6m', 
       'group_level',
       'housing_nature_g',
       'selfquery_in3m_min_interval',
       'selfquery_loquery_cardquery_in1m',
    #   'local_nolocal_g', 
       'desired_loan_amt_g',
       'asset_g', 
       'apply_city_g',
       'social_fund_basenum', 
       'mean_cardline', 
       'sex_g',  
       'company_nature_g',       
       'salary_grant_type_g',
       'max_loanline', 
     #  'work_years',
       'married_g', 
       "y"]]

step01_feature_engine.watch_obj(valid_data)


X_valid, y_valid = step01_feature_engine.x_y_data(valid_data)

##将scoreacrd中分组的score回填到 原始的样本中
#针对X_train  
new_col = list(X_valid.columns)
valid_score=pd.DataFrame()
for var in new_col:
    bin_res = step03_built_modle.applymap_score(X_valid, scorecard, var)
    valid_score = pd.concat([valid_score,bin_res], axis = 1)

#生成分数
valid_score["score_sum"] = valid_score.sum(axis = 1)

#拼接y值
valid_score_data = pd.concat([valid_score, valid_data['y']], axis =1)

iv_score_sum = step01_feature_engine.filter_iv(valid_score_data, group=10)
valid_score_group = iv_score_sum[1]
valid_score_group.to_excel(r"F:\TS\Lending_Club\04_output\09_valid_data\valid_model_result_spi_10.xlsx")


##使用卡方来分箱
one_woe = pd.DataFrame([])
new_col = ['score_sum','selfquery_cardquery_in6m','group_level','housing_nature_g']
new_col.remove('y')
  
for var in new_col:
    new_woe = new_iv.ChiMerge(valid_score_data, var, 'y')
    one_woe = one_woe.append(new_woe)
    print(var)


##计算SPI

dd1 = valid_score.drop(['score_sum'], axis = 1)
new_col = list(dd1.columns)
valid_spi=pd.DataFrame()
for var in new_col:
    lsvc = pd.value_counts(dd1[var]).reset_index()
    ls = lsvc.sort_values(by = ['index'], ascending=False)
    valid_spi = pd.concat([valid_spi,ls], axis = 1)
valid_spi.to_excel(r"F:\TS\offline_model\output\06_spi\spi_01.xlsx")


