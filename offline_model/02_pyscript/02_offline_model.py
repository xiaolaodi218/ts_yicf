# -*- coding: utf-8 -*-
"""
Created on Wed Dec 20 18:03:29 2017

@author: yichengfan
"""

####瑞赛网络code
'''
信用风险评分卡开发第二章----信息值&woe
信用风险评分卡开发第三章----最优分箱&降低基数
信用风险评分卡开发第四章----从logistic回归模型到标准评分卡
信用风险评分卡开发第五章----评分卡生成'''

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.font_manager import FontProperties  
# plt.style.use('ggplot')  #风格设置近似R这种的ggplot库
import seaborn as sns
sns.set_style('whitegrid')
import missingno as msno

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

df = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\orig_data_6.csv')
df.columns = df.columns.str.lower()  #列名变为小写
df = df.rename(columns = {'target':'y'}, copy = False)
df.groupby('y').size()
'''
y
0    3760
1     529
dtype: int64
11.8%
odds = 7.12
'''

#基于业务的原因删除省份等地域有关影响;汽车个数房产个数工作变动次数现在的申请表已经没有了
#is_has_insurance_policy只是针对E保通,故删除;
df1 = df.drop(['apply_code','进件时间', '是否有房','是否有车'], axis = 1)

#排序
df1 = df1[['申请产品', '申请城市', '住房性质', '教育程度', '婚姻状况', '性别',
           '单位性质', '是否本地','财产信息', '薪资发放方式','职级',
           '申请贷款金额', '贷款申请期限', '子女个数', '工作年限','年龄', 
           '月收入', '月其他收入','社保公积基数','score','group_level', 'risk_level',
           '贷款月还', '信用卡月还', '准贷记卡月还', '其他负债','简版汇总负债总计',
           '信用卡使用率','征信负债率','计算年收入', '计算负债率1', '计算负债率2','y']]

#同值化检查
df2, feature_primaryvalue_ratio = step01_feature_engine.select_primaryvalue_ratio(df1,ratiolimit = 0.95)
#查看缺失值情况
null_ratio = step01_feature_engine.select_null_ratio(df2)
df3 = df2.fillna(0)

#打印字符型变量
step01_feature_engine.check_feature_binary(df3)

#观察各个离散值的分布情况
step01_feature_engine.watch_obj(df3)


#==============================================================================
##绘图看出离群值
#var = list(df3.columns)
#for i in var:
#    step06_draw_plot.Outliers(df[[i]])


##处理下离群值；只能用眼睛看了；
'''
子女个数 有1个40这样的离群值
申请贷款金额 5000000 ;
'''
dfa = df3.replace({'子女个数':40}, int(df3.子女个数.mode()))
dfb = dfa.replace({'申请贷款金额':5000000}, int(500000))
dfc = dfb.replace({'申请贷款金额':5000000}, int(500000))
dfd = dfc.replace({'信用卡使用率':13900}, int(13.9))
dfe = dfd.replace({'信用卡使用率':2320}, int(2.32))
df4 = dfe
#==============================================================================

#绘图
#objectColumns = df1.select_dtypes(include=["object"]).columns
#var = df3[objectColumns].columns
var = ['申请产品', '申请城市', '住房性质', '教育程度', '婚姻状况', '性别','职级', '单位性质',
       '是否本地','财产信息', '薪资发放方式','子女个数','贷款申请期限','group_level', 'risk_level',]
for i in var:
    step06_draw_plot.drawBar(df4[i])
    
    
v_feat = ['申请贷款金额', '工作年限', '年龄', '月收入', '月其他收入','社保公积基数','score',
       '贷款月还', '信用卡月还', '准贷记卡月还', '其他负债','简版汇总负债总计','征信负债率',
       '信用卡使用率','计算年收入', '计算负债率1', '计算负债率2']
for i in v_feat:
    step06_draw_plot.drawHistogram(df4[i])
   
    
def prob_density(data, v_feat):
    font = FontProperties(fname=r"c:\windows\fonts\simsun.ttc", size=10)  
       
    plt.figure(figsize=(16,20*4))
    gs = gridspec.GridSpec(20, 1)
    for i, cn in enumerate(data[v_feat]):
        ax = plt.subplot(gs[i])
        sns.distplot(data[cn][data["y"] == 1], bins=50)
        sns.distplot(data[cn][data["y"] == 0], bins=100)
        ax.set_xlabel('')
        ax.set_title('histogram of feature: ' + str(cn), fontproperties=font)

#for i in v_feat:
#    prob_density(df4,v_feat)
              

#计算每个分类变量的逾期率情况，看情况合并

str_value = step01_feature_engine.str_ratio(df4,var)

        
'''
0.1134789557805008
0.09
0.1896551724137931
'''


# 构建mapping，对有序变量进行转换
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
    "是否本地": {"本地":0,"外地":1},
    "group_level": {"A":0,"B":1,"C":2,"D":3,"E":4},
    "risk_level": {"低":0,"中":1,"高":2}}

df5 = df4.replace(mapping_dict1) #变量映射

df5.贷款申请期限 = df5.贷款申请期限.map({36:0,24:1,18:1,12:1,6:1})
df5.子女个数 = df5.子女个数.map({0:0,1:1,2:2,3:2,4:2,5:2})

df5[['申请产品','教育程度','申请城市','婚姻状况','性别','住房性质','薪资发放方式','单位性质',
     '财产信息','是否本地','group_level','risk_level','贷款申请期限','子女个数']].head() #查看效果

df6 = df5.rename(columns = {
        "申请产品":"apply_product_g", "申请城市":"apply_city_g", "申请贷款金额":"desired_loan_amt_g",
        "贷款申请期限":"desired_loan_lift_g", "住房性质":"housing_nature_g", "教育程度":"education_g",
        "婚姻状况":"married_g","性别":"sex_g", "单位性质":"company_nature_g","是否本地":"local_nolocal_g",
        "财产信息":"asset_g", "薪资发放方式":"salary_grant_type_g","职级":"job_level_g",
        "子女个数":"child_counts_g","工作年限":"work_years","年龄":"age", "月收入":"month_salary",
        "月其他收入":"month_other_income_g", "社保公积基数":"social_fund_basenum",
        "贷款月还":"loan_month_return_amt", "信用卡月还":"credit_month_return_amt", 
        "准贷记卡月还":"semicard_month_return_amt", "其他负债":"other_debet", 
        "简版汇总负债总计":"debet_all", "征信负债率":"external_debat_ratio",
        "信用卡使用率":"credit_use_ratio","计算年收入":"cal_yearly_income", 
        "计算负债率1":"cal_debat_ratio1", "计算负债率2":"cal_debat_ratio2",
        "准贷记卡月还":"debit_card_return"}, copy = False)
    
    
#打印字符型变量
step01_feature_engine.check_feature_binary(df6)

#查看缺失值情况
df6.isnull().sum(axis=0).sort_values(ascending=False)

#df5 = df4.fillna(0)
#df5.isnull().sum(axis=0).sort_values(ascending=False)



#IV保留大于0.02的变量
new_data,iv_value = step01_feature_engine.filter_iv(df6, group=10)
iv_value.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\second\iv_value_refresh6.xls")
'''
小于0.02的变量有(无预测能力): 6
['age', 'job_level_g', 'cal_debat_ratio1', 'desired_loan_lift_g',
 'credit_month_return_amt', 'month_salary', 'child_counts_g']
'''

##皮尔森系数删除多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(new_data)

df8 = new_data.drop(['score','risk_level','month_other_income_g','loan_month_return_amt', 'debet_all'], axis = 1)
pearson_coef = step02_modle_plot.plot_pearson(df8)

csvfile = r"F:\TS\offline_model\01_Dataset\02_Interim\middle_data\middle_data7.csv"
df8.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')




new_data3 = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\middle_data\middle_data7.csv",encoding = 'utf-8')










'''end'''
#==============================================================================

##one-hot虚拟编码
n_columns = ['company_nature_g','housing_nature_g','sex_g','local_nolocal_g','education_g']
dummy_company = pd.get_dummies(new_data2['company_nature_g'], prefix= 'company_nature_g')
dummy_house = pd.get_dummies(new_data2['housing_nature_g'], prefix= 'housing_nature_g')
dummy_sex = pd.get_dummies(new_data2['sex_g'], prefix= 'sex_g')
dummy_local = pd.get_dummies(new_data2['local_nolocal_g'], prefix= 'local_nolocal_g')
dummy_educate = pd.get_dummies(new_data2['education_g'], prefix= 'education_g')

dummy_df = pd.concat([new_data2,dummy_company, dummy_house, dummy_sex, dummy_local, dummy_educate], axis=1)
df7 = dummy_df.drop(n_columns, axis=1)

#列名排序
df7 = df7[['age', 'work_years', 'local_res_years', 'monthly_expense',
       'yearly_income', 'monthly_salary', 'credit_amt_all', 'credit_use_ratio',
       'desired_loan_amount', 'score', 'self_query_03_month_frequency',
       'self_query_24_month_frequency', 'loan__query_24_month_frequency',
       'card_apply_03_month_frequency', 'card_60_pastdue_frequency',
       'max_cardline', 'selfquery_cardquery_in6m', 'cardquery_card_num_dvalue',
       'y', 'company_nature_g_0', 'company_nature_g_1', 'company_nature_g_2',
       'company_nature_g_3', 'company_nature_g_4', 'company_nature_g_5',
       'housing_nature_g_0.0', 'housing_nature_g_1.0', 'housing_nature_g_2.0',
       'housing_nature_g_3.0', 'housing_nature_g_4.0', 'sex_g_0', 'sex_g_1',
       'local_nolocal_g_0', 'local_nolocal_g_1', 'education_g_0',
       'education_g_1', 'education_g_2', 'education_g_3','y']]

##皮尔森系数删除多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(df7)


##构造X，y变量
X, y = step01_feature_engine.x_y_data(new_data3)
X, y = step01_feature_engine.x_y_data(df7)

##特征缩放，标准化
X = step01_feature_engine.standard_scaler(X)

##方法一：递归消除算法
#X, y = step01_feature_engine.wrapper_data(X, y,n_features_to_select = 15)

##方法二: 随机逻辑回归
scoretable,X_picked = step01_feature_engine.rdlg_variables(X, y, threshold=0.15)

#==============================================================================

###取IV最大的十几个变量
#new_data
#==============================================================================
# last_data = df7[['selfquery_cardquery_in6m','score','credit_amt_all','yearly_income', 
#                  'self_query_03_month_frequency','card_60_pastdue_frequency', 'max_cardline',
#                  'local_res_years', 'local_nolocal_g_0','local_nolocal_g_1',
#                   'housing_nature_g_0.0', 'housing_nature_g_1.0', 'housing_nature_g_2.0',
#                   'housing_nature_g_3.0', 'housing_nature_g_4.0', 'company_nature_g_0', 
#                   'company_nature_g_1','company_nature_g_2','company_nature_g_3', 
#                   'company_nature_g_4', 'company_nature_g_5','y']]
#                        #'card_apply_03_month_frequency', 'cardquery_card_num_dvalue'
#==============================================================================
new_data3 = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\middle_data\new_data3.csv",encoding = 'utf-8')
#last_data = df7
last_data = new_data3 #IV分了5类，未做one-hot编码
##构造X，y变量
X, y = step01_feature_engine.x_y_data(last_data)


##特征缩放，标准化
#X = step01_feature_engine.standard_scaler(X)
#==============================================================================
# Col = ['age', 'work_years', 'local_res_years', 'monthly_expense',
#        'yearly_income', 'monthly_salary', 'credit_amt_all', 'credit_use_ratio',
#        'desired_loan_amount', 'self_query_03_month_frequency',
#        'self_query_24_month_frequency', 'loan__query_24_month_frequency',
#        'card_apply_03_month_frequency', 'card_60_pastdue_frequency',
#        'max_cardline', 'selfquery_cardquery_in6m', 'cardquery_card_num_dvalue']
#==============================================================================

#==============================================================================
# Col =  ['selfquery_cardquery_in6m', 'score', 'credit_amt_all', 'yearly_income',
#        'self_query_03_month_frequency', 'card_60_pastdue_frequency',
#        'max_cardline', 'local_res_years']
#==============================================================================

Col = ['education_g', 'housing_nature_g', 'company_nature_g',
      'local_res_years', 'yearly_income', 'monthly_salary',
       'credit_amt_all', 'desired_loan_amount', 'max_cardline', 
       'self_query_03_month_frequency', 'self_query_24_month_frequency',
       'card_apply_03_month_frequency', 'card_60_pastdue_frequency',
       'selfquery_cardquery_in6m','cardquery_card_num_dvalue']

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

#woe = pd.read_excel(r"F:\TS\offline_model\01_Dataset\04_Output\second\iv_value3.xls")
one_woe = pd.DataFrame([])
new_col = list(df4.columns)

for var in new_col:
    new_woe = new_iv.ChiMerge(df4, var, 'y')
    all_woe = pd.concat([one_woe],axis=0)
#all_woe = all_woe.sort_values(by=['ori_IV','variable','max'],ascending=[False,True,True])
all_woe = all_woe[['variable', 'interval', 'flag_0', 'flag_1', 'N', 'bad_rate', 'y1_total',
       'y0_total', 'y1_percent', 'y0_percent', 'WOE', 'y0/y1', 'total_percent',
       'MIV', 'ori_IV']]

woe1 = new_iv.ChiMerge(df4, 'age', 'y')
woe2 = new_iv.ChiMerge(df4, 'education_g', 'y')
woe4 = new_iv.ChiMerge(df4, 'housing_nature_g', 'y')
woe5 = new_iv.ChiMerge(df4, 'work_years', 'y')
woe6 = new_iv.ChiMerge(df4, 'work_years', 'y')
woe7 = new_iv.ChiMerge(df4, 'company_nature_g', 'y')
woe8 = new_iv.ChiMerge(df4, 'debit_card_return', 'y')
woe9 = new_iv.ChiMerge(df4, 'yearly_income', 'y')
woe10 = new_iv.ChiMerge(df4, 'monthly_salary', 'y')
woe11 = new_iv.ChiMerge(df4, 'monthly_other_income', 'y')
woe12 = new_iv.ChiMerge(df4, 'credit_amt_all', 'y')
woe13 = new_iv.ChiMerge(df4, 'debt_all', 'y')
woe14 = new_iv.ChiMerge(df4, 'desired_loan_amount', 'y')
woe16 = new_iv.ChiMerge(df4, 'loan_month_return_new', 'y')
woe17 = new_iv.ChiMerge(df4, 'score', 'y')
woe18 = new_iv.ChiMerge(df4, 'selfquery_cardquery_in6m', 'y')
woe19 = new_iv.ChiMerge(df4, 'cardquery_card_num_dvalue', 'y')
woe20 = new_iv.ChiMerge(df4, 'max_cardline', 'y')

woe_n = pd.concat([woe1,woe2,woe4,woe5,woe6,woe7,woe8,woe9,woe10,woe11,woe12,woe13,woe14,woe16,woe17,woe18,woe19,woe20],axis=0)
woe_n.to_csv(r"F:\TS\offline_model\01_Dataset\04_Output\woe_r\woe_new_chi.csv",sep=',',index=False ,encoding = 'utf-8')



##评分卡
scorecard = step03_built_modle.make_scorecard(formula, woe)

csvfile = r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\scorecard1.csv"
scorecard.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
scorecard = pd.read_csv(r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\scorecard1.csv")

##再造一次X，y
X_last, y_last = step01_feature_engine.x_y_data(last_data)

X_last


feature_score = step03_built_modle.feature_score(scorecard, X_last, y_last) 
feature_score.to_excel(r"F:\TS\offline_model\01_Dataset\04_Output\scorecard\feature_score1.xlsx")







