# -*- coding: utf-8 -*-
"""
Created on Tue Dec  5 13:55:00 2017

@author: yichengfan
"""

import numpy as np
import pandas as pd

import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
plt.style.use('ggplot')  #风格设置接近R中的ggplot
import seaborn as sns    #数据可视化模块
sns.set_style('whitegrid')
%matplotlib inline
import missingno as msno

from sklearn.feature_selection import VarianceThreshold
from sklearn.linear_model import RandomizedLogisticRegression   #随机逻辑回归,用于 稳定性选择
from sklearn.pipeline import Pipeline  #参数集在新数据集（比如测试集）上的重复使用。管道机制实现了对全部步骤的流式化封装和管理
from sklearn.grid_search import GridSearchCV  

from sklearn.metrics import confusion_matrix
from sklearn.metrics import precision_recall_curve  
from sklearn.metrics import classification_report  
from sklearn.model_selection import train_test_split  
from sklearn.metrics import accuracy_score,precision_score,recall_score

#忽略弹出的warnings
import warnings
warnings.filterwarnings("ignore")

import sys
sys.path.append(r"F:\model\lib")
import iv
import model_evaluation_plot
import model_helper
import preprocess


df = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\baseline_model_data.csv')
df.columns = df.columns.str.lower()  #列名变为小写df2 = df2.rename(columns={'BORROWER_TEL_ONE':'手机号'}, copy = False)
df = df.rename(columns = {'target':'y'}, copy = False)
df.groupby('y').size()
'''
target
0    1987
1     251
dtype: int64
'''

'''对于缺失值的处理，一般来说先判定缺失的数据是否有意义。
从确实信息可以发现，本次数据集缺失值较多的属性对我们模型预测意义不大
统计每列属性缺失值的数量,删除缺失值过高的比例的函数'''
def null_ratio(data, ratiolimit = 0.3):
    #删除缺失值过高的比例的函数
    df_null = data.isnull().sum(axis=0).sort_values(ascending=False)/float(len(data))
    null_ratio = pd.DataFrame(df_null)
    null_ratio = null_ratio.reset_index() #重置索引
    null_ratio = null_ratio.rename(columns = {'index':'Col', 0:'value_retio'}, copy = False)    
    df_nullre = null_ratio[null_ratio.value_retio < ratiolimit] #删掉缺失值>0.4的数据   
    refesh_data = data[list(df_nullre['Col'])] 
    return refesh_data,null_ratio

df1, null_ratio = null_ratio(df)



'''变量同值性观察;删除维度占比过大值过高的比例的函数'''
def primaryvalue_ratio(data, ratiolimit = 0.90):
    #按照命中率进行筛选      
    #首先计算每个变量的命中率,这个命中率是指 维度中占比最大的值的占比       
    recordcount = data.shape[0]
    x = []
    #循环每一个列，并取出出现频率最大的那个值;index[0]是取列名,iloc[0]是取列名对应的值
    for col in data.columns:
        primaryvalue = data[col].value_counts().index[0]
        ratio = float(data[col].value_counts().iloc[0])/recordcount
        x.append([ratio,primaryvalue])       
    feature_primaryvalue_ratio = pd.DataFrame(x,index = data.columns)
    feature_primaryvalue_ratio.columns = ['primaryvalue_ratio','primaryvalue']
        
    needcol = feature_primaryvalue_ratio[feature_primaryvalue_ratio['primaryvalue_ratio']<ratiolimit]
    needcol = needcol.reset_index()
    select_data = data[list(needcol['index'])]
    return select_data, feature_primaryvalue_ratio   

df2, feature_primaryvalue_ratio = primaryvalue_ratio(df1)


##找到object的特征
object_columns_df =df2.select_dtypes(include=["object"]) #筛选数据类型为object的变量
print(object_columns_df.iloc[0])


#缺失值可视化
df2.select_dtypes(include=[np.number]).isnull().sum().sort_values(ascending=False)
numColumns = df2.select_dtypes(include=[np.number]).columns
msno.matrix(df2[numColumns]) #缺失值可视化
#df2 = df2.dropna(axis = 0)

##填充缺失值
from sklearn.preprocessing import Imputer
imr = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)  # 针对axis=0 列来处理,填充众数
imr = imr.fit(df2[numColumns])
df2[numColumns] = imr.transform(df2[numColumns])



##移除方差过小的的变量,抛弃了0个(参数threshold为方差的阈值),需要输入的数据无缺失值
##假设我们有一个有布尔特征的数据集，然后我们想去掉那些超过90%的样本都是0（或者1）的特征
from sklearn.feature_selection import VarianceThreshold

vt = VarianceThreshold(threshold = .9 * (1 - .9))
x_vt=vt.fit_transform(df2)
vt.get_support()
vt_columns = df2.columns[vt.get_support()]
df3 = df2[vt_columns]


iv_value, iv_detail = iv.cal_iv(df3, group=10)
#iv_value.to_excel(r"F:\TS\offline_model\output\iv_value.xls")
#iv_detail.to_excel(r"F:\TS\offline_model\output\iv_detail.xls")
##利用IV值，先删除掉IV值<0.02的特征
list_value = iv_value[iv_value.ori_IV <= 0.02].var_name
new_list = list(set(list_value))
print(new_list)
#new_list.sort(key = list_value.index)

drop_list = new_list
df4 = df3.drop(drop_list, axis = 1)


#==============================================================================


#构建X特征变量和Y目标变量
x_feature = list(df4.columns)
x_feature.remove('y')
x_val = df4[x_feature]
y_val = df4['y']
len(x_feature) # 查看初始特征集合的数量



####wrapper递归消除算法
from sklearn.feature_selection import RFE
from sklearn.linear_model import LogisticRegression
model = LogisticRegression()  # 建立逻辑回归分类器
# 建立递归特征消除筛选器
rfe = RFE(model, 15) #通过递归选择特征，选择40个特征
rfe = rfe.fit(x_val, y_val)
# 打印筛选结果
print(rfe.support_)
print(rfe.ranking_) #ranking 为 1代表被选中，其他则未被代表未被选中a

col_filter = x_val.columns[rfe.support_] #通过布尔值筛选首次降维后的变量
col_filter # 查看通过递归特征消除法筛选的变量

x_val = x_val[col_filter]



'''
我们在第一次降维的基础上，通过皮尔森相关性图谱找出冗余特征并将其剔除；
同时，可以通过相关性图谱进一步引导我们选择特征的方向。
<0.4显著弱相关，0.4-0.75中等相关，大于0.75强相关
'''
colormap = plt.cm.viridis
plt.figure(figsize=(14,14))
plt.title('Person Correlation of Feature', y = 1.05, size = 12)
sns.heatmap(x_val.corr(), linewidths=0.1, vmax=1.0, 
            square=True,cmap = colormap,linecolor='white',annot=True)
col_filter = list(x_val.columns)

#删掉一些冗余特征
col = ['card_used_amt_sum_new']
x_val_new = x_val.drop(col, axis=1)
col_filter_new = list(x_val_new.columns)

colormap = plt.cm.viridis
plt.figure(figsize=(10,10))
plt.title('Person Correlation of Feature', y = 1.05, size = 12)
sns.heatmap(x_val_new.corr(), linewidths=0.1, vmax=1.0, 
            square=True,cmap = colormap,linecolor='white',annot=True)
col_new = list(x_val_new.columns)

#==============================================================================
# ###皮尔森图谱,删除共线的特征
# colormap = plt.cm.viridis
# plt.figure(figsize=(50,50))
# plt.title('Pearson Correlation of Features', y=1.05, size=15)
# sns.heatmap(df4.corr(),linewidths=0.1,vmax=1.0, square=True, cmap=colormap, linecolor='white', annot=True)
# col_filter = x_val.columns
# 
# drop_col = ['mana_loan_in24m', 
#             'mana_loan_in12m',
#             'mana_loan_in6m',
#             'mana_loan_in3m',
#             'lo_query_in24m_de_f',
#             'lo_query_in12m_de_f',
#             'lo_query_in24m',
#             'lo_query_in12m',
#             'lo_query_in6m',
#             'selfquery6_in6m',
#             'selfquery6_in24m',
#             'selfquery6_in12m',
#             'selfquery6_in3m',
#             'selfquery5_in24m',
#             'selfquery5_in12m',
#             'selfquery5_in3m',
#             'selfquery_in6m', 
#             'selfquery_in1m',
#             'use_credit_card_numb',
#             'credit_card_num_fo',
#             'normal_card_num',
#             'mana_loan_in24m_de_f',
#             'mana_loan_in12m_de_f',
#             'mana_loan_in6m_de_f',
#             'mana_loan_in3m_de_f',
#             'mana_loan_in1m_de_f',
#             'mana_loan_in24m_f',
#             'selfquery_in3m_min_interval',
#             'self_card_query_in24m',
#             'self_card_query_in12m',
#             'self_card_query_in6m',
#             'self_card_query_in3m',
#             'self_card_query_in1m',
#             'card_query_in24m',
#             'card_query_in12m',
#             'card_query_in3m',
#             'card_query_in3m_max',
#             'card_query_in6m_max',
#             'cardqurry_com_num',
#             'card_query_in1m_max',
#             'query_in24m',
#             'query_in12m',
#             'query_in6m',
#             'loan_query_in24m',
#             'loan_query_in12m',
#             'loan_query_in6m',
#             'selfquery_in24m',
#             'selfquery_in12m',
#             'pettyloan_loquery_in12m_1',
#             'pettyloan_loquery_in6m_1',
#             'pettyloan_loquery_in3m_1',
#             'pettyloan_query_in12m',
#             'pettyloan_query_in6m',
#             'pettyloan_query_in3m',
#             'self_loan_card_query_in1m',
#             'self_loan_card_query_in3m',
#             'self_loan_card_query_in6m',
#             'self_loan_card_query_in12m',
#             'self_loan_query_de_f_in24m',
#             'self_loan_query_de_f_in12m',
#             'self_loan_query_de_f_in6m',
#             'self_loan_query_de_f_in3m',
#             'self_loan_query_de_f_in1m',
#             'self_loan_query_in24m',
#             'self_loan_query_in12m',
#             'self_loan_query_in6m',
#             'self_loan_query_in3m',
#             'self_loan_query_in1m',
#             'self_loan_dv_in12m',
#             'self_loan_dv_in3m',
#             'same_com_lo_card_num_3m',
#             'same_com_insur_qurry_num',
#             'consumerfinance_loquery_in6m',
#             'consumerfinance_query_in24m',
#             'consumerfinance_query_in6m',
#             'loan_num',
#             'clear_loan_num',
#             'clear_loan_num_24m',
#             'umclear_month_pay',
#             'unclear_loan_num',
#             'unclear_loan_amount',
#             'loan_num_in24m',
#             'max_card_line',
#             'max_card_line_bf',
#             'max_car_loan_line',
#             'min_car_loan_line',
#             'max_percos_loan_line',
#             '个人汽车贷款数']
# col_new = col_filter.drop(drop_col) #剔除冗余特征
# 
# #目前为止，特征子集包含的变量从130个降维至42个。
# 
# colormap = plt.cm.viridis
# plt.figure(figsize=(18,18))
# plt.title('Pearson Correlation of Features', y=1.05, size=15)
# sns.heatmap(df4[col_new].corr(),linewidths=0.1,vmax=1.0, square=True, cmap=colormap, linecolor='white', annot=True)
# 
# 
# ###随机森林计算特征的重要性
# names = df4[col_new].columns
# from sklearn.ensemble import RandomForestClassifier
# clf=RandomForestClassifier(n_estimators=10,random_state=123)#构建分类随机森林分类器
# clf.fit(x_val[col_new], y_val) #对自变量和因变量进行拟合
# names, clf.feature_importances_
# for feature in zip(names, clf.feature_importances_):
#     print(feature)
# 
# plt.style.use('fivethirtyeight')
# plt.rcParams['figure.figsize'] = (12,6)
# 
# ## feature importances 可视化##
# importances = clf.feature_importances_
# feat_names = names
# indices = np.argsort(importances)[::-1]
# fig = plt.figure(figsize=(16,4))
# plt.title("Feature importances by RandomTreeClassifier")
# plt.bar(range(len(indices)), importances[indices], color='lightblue',  align="center")
# plt.step(range(len(indices)), np.cumsum(importances[indices]), where='mid', label='Cumulative')
# plt.xticks(range(len(indices)), feat_names[indices], rotation='vertical',fontsize=14)
# plt.xlim([-1, len(indices)])
# plt.show()
#==============================================================================

##计算IV值
#==============================================================================
# df4 = df3.drop(['credit_use_ratio'], axis = 1)
# Ser = df4.信用卡使用率.map(lambda x :x/100)
# df4 = df4.drop(['信用卡使用率'], axis = 1)
# df4.insert(7, '信用卡使用率', Ser) 
#==============================================================================

#==============================================================================
# df3 = df3[['mana_loan_in1m', 'selfquery6_inl3m', 'num_pettyloan', 'education_g',
#        'loan_query_in1m', 'nonlocal_g', 'same_com_insur_qurry_num',
#        'self_card_query_in1m', 'same_com_lo_card_num_3m','same_com_lo_qurry_num_3m', 
#        'unclear_loan_num', 'loan_num','target']]
#==============================================================================


###################################################################################


#####one-hot编码
df5 = df4[col_new]
#n_columns = ["work_years_g", "local_rescondition_g","education_g","work_years_g","local_res_years_g"] 
#dummy_df = pd.get_dummies(df4[n_columns])# 用get_dummies进行one hot编码
#df5 = pd.concat([df4, dummy_df], axis=1) #当axis = 1的时候，concat就是行对齐，然后将不同列名称的两张表合并


####标准化
from sklearn.preprocessing import StandardScaler # 导入模块
sc =StandardScaler() # 初始化缩放器
df5[col_new] =sc.fit_transform(df5[col_new]) #对数据进行标准化
df5.head() #查看经标准化后的数据


X = df5[col_new]
y = df4["y"]

n_sample = y.shape[0]
n_pos_sample = y[y == 0].shape[0]
n_neg_sample = y[y == 1].shape[0]
print('样本个数：{}; 正样本占{:.2%}; 负样本占{:.2%}'.format(n_sample,
                                                   n_pos_sample / n_sample,
                                                   n_neg_sample / n_sample))
print('特征维数：', X.shape[1])

from imblearn.over_sampling import SMOTE # 导入SMOTE算法模块
# 处理不平衡数据
sm = SMOTE(random_state=42)    # 处理过采样的方法
X, y = sm.fit_sample(X, y)
print('通过SMOTE方法平衡正负样本后')
n_sample = y.shape[0]
n_pos_sample = y[y == 0].shape[0]
n_neg_sample = y[y == 1].shape[0]
print('样本个数：{}; 正样本占{:.2%}; 负样本占{:.2%}'.format(n_sample,
                                                   n_pos_sample / n_sample,
                                                   n_neg_sample / n_sample))

#构建分类器进行训练
#初始化分类器。

from sklearn.linear_model import LogisticRegression
clf = LogisticRegression() # 构建逻辑回归分类器
clf.fit(X, y)

predicted1 = clf.predict(X) # 通过分类器产生预测结果
#查看预则结果的准确率。 0.62406

from sklearn.metrics import accuracy_score
print("Test set accuracy score: {:.5f}".format(accuracy_score(predicted1, y,)))
'''Test set accuracy score: 0.62406'''

#借助混淆矩阵进一步比较。
from sklearn.metrics import confusion_matrix
m = confusion_matrix(y, predicted1) 
m
'''
array([[1185,  802],
       [ 692, 1295]], dtype=int64)
'''

##上面是混淆矩阵对分类器产生不同类型的正误数量的统计。为了更加直观，我们对混淆矩阵进行可视化。

plt.figure(figsize=(5,3))
sns.heatmap(m) # 混淆矩阵可视化

'''
热图颜色越浅代表数量越多，从上图可以看出真阳性的数量最多，而假阳性的数量最少。
根据混淆矩阵，我们可以分别计算precision、recall、f1-score的值，
这里我们采用sklearn.metrics子模块classification_report快速查看混淆矩阵precision、recall、f1-score的计算值。
'''

from sklearn.metrics import classification_report
print(classification_report(y, predicted1))
'''
             precision    recall  f1-score   support

        0.0       0.63      0.60      0.61      1987
        1.0       0.62      0.65      0.63      1987

avg / total       0.62      0.62      0.62      3974
'''

from sklearn.metrics import roc_auc_score
roc_auc1 = roc_auc_score(y, predicted1)
print("Area under the ROC curve : %f" % roc_auc1)
'''Area under the ROC curve : 0.624056'''
'''
以上只是一个baseline模型，接下来我们继续优化模型。

7 模型评估与优化
在上一个步骤中，我们的模型训练和测试都在同一个数据集上进行，这会产生2个问题：

1、很可能导致学习器把训练样本学得“太好”，把训练样本自身的特点当做所有潜在样本都会具有的一般性质。
2、模型在同一个数据集上进行训练和测试，使得测试集的样本属性提前泄露给模型。

以上2个问题都会导致模型的泛化能力下降，这种现象我们称之为“过拟合”（overfitting）。
因此，我们需要将数据集划分为测试集和训练集，让模型在训练集上学习，在测试集上测试模型的判别能力。

通常来说，将数据集划分为训练集和测试集有3种处理方法：
1、留出法（hold-out），2、交叉验证法（cross-validation），3、自助法（bootstrapping）

本次项目我们采用交叉验证法划分数据集，将数据划分为3部分：
训练集（training set）、验证集（validation set）和测试集（test set）。
让模型在训练集进行学习，在验证集上进行参数调优，最后使用测试集数据评估模型的性能。


模型调优我们采用网格搜索调优参数（grid search），通过构建参数候选集合，
然后网格搜索会穷举各种参数组合，根据设定评定的评分机制找到最好的那一组设置。

结合cross-validation和grid search，具体操作我们采用scikit learn模块model_selection中的GridSearchCV方法。
'''

from sklearn.model_selection import GridSearchCV
from sklearn.cross_validation import train_test_split 

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.3, random_state = 0) # random_state = 0 每次切分的数据都一样
# 构建参数组合
param_grid = {'penalty': [ 'l1', 'l2'],
              'max_iter':[10,30,50,80,100,120,150,180],
              'C': [0.001, 0.01,0.1, 1, 10, 100, 1000,],}

grid_search = GridSearchCV(LogisticRegression(),  param_grid, cv=10) # 确定模型LogisticRegression，和参数组合param_grid ，cv指定5折
grid_search.fit(X_train, y_train) # 使用训练集学习算法

results = pd.DataFrame(grid_search.cv_results_) 
best = np.argmax(results.mean_test_score.values)


#模型性能评估
best_parameters = grid_search.best_params_
print("Best parameters: {}".format(grid_search.best_params_))
print("Best cross-validation score: {:.5f}".format(grid_search.best_score_))
'''Best parameters: {'C': 10, 'penalty': 'l1'}
Best cross-validation score: 0.61129
'''

results# 查看分析报告

scores = np.array(results.mean_test_score).reshape(2, 6)
sns.heatmap(scores, ylabel='penalty', yticklabels=param_grid['penalty'],
                    xlabel='C', xticklabels=param_grid['C'], cmap="viridis")
'''
上图模型在不同参数组合下跑出的分数热力图，我们可以从热力图明显看出，l2比l1的表现普遍要好，当C小于1时，模型表现较差。
同时，我可以利用热力图来寻找参数调优的方向，进一步选择更优的参数。而实际操作中，模型调参是一个反复迭代的过程。
'''

print("Best estimator:\n{}".format(grid_search.best_estimator_))#grid_search.best_estimator_ 返回模型以及他的所有参数（包含最优参数）
'''
Best estimator:
LogisticRegression(C=1000, class_weight=None, dual=False, fit_intercept=True,
          intercept_scaling=1, max_iter=30, multi_class='ovr', n_jobs=1,
          penalty='l1', random_state=None, solver='liblinear', tol=0.0001,
          verbose=0, warm_start=False)
'''
#现在，我们使用经过训练和调优的模型在测试集上测试。

y_pred = grid_search.predict(X_test)
print("Test set accuracy score: {:.5f}".format(accuracy_score(y_test, y_pred,)))
'''Test set accuracy score: 0.61358'''
print(classification_report(y_test, y_pred))
'''print(classification_report(y_test, y_pred))
             precision    recall  f1-score   support

        0.0       0.62      0.59      0.60       594
        1.0       0.61      0.64      0.62       599

avg / total       0.61      0.61      0.61      1193'''
m2 = confusion_matrix(y_test, y_pred) 
plt.figure(figsize=(5,3))
sns.heatmap(m2) # 混淆矩阵可视化

roc_auc2 = roc_auc_score(y_test, y_pred)
print("Area under the ROC curve : %f" % roc_auc2)
'''Area under the ROC curve : 0.613464'''


model_optimizing(X_train,y_train)
quick_make_model()


def model_optimizing(X_train,y_train):
    pipline = Pipeline([('lr',LogisticRegression())
            ])
    parameters = {
      'lr__penalty': ('l1','l2'),'lr__C': (0.001,0.01,0.1,1.0,10,100,1000),
      'lr__max_iter':(10,30,50,80,100,120,150,180),
      }
    """
    网格搜索为自动化调参的常见技术之一，grid_search包提供了自动化调参的工具，包括GridSearchCV类
    #GridSearchCV 是自动调参，只要把参数输进去，就能给出最优化的结果和参数数据
    #sklearn模块的GridSearchCV模块，能够在指定的范围内自动搜索具有不同超参数的不同模型组合，有效解放注意力。
    """
    grid_search = GridSearchCV(pipline,parameters,n_jobs=4,scoring='recall',cv=10)
    """
    cv :交叉验证参数，默认None，使用三折交叉验证。指定fold数量，默认为3，也可以是yield训练/测试数据的生成器。
    n_jobs: 并行数，int：个数,-1：跟CPU核数一致, 1:默认值。
    """
    grid_search.fit(X_train, y_train) 
    print('Best score: %0.3f' % grid_search.best_score_)
    print('Best parameters set:')
    best_parameters = grid_search.best_estimator_.get_params()
    for param_name in sorted(parameters.keys()):
        print('\t%s: %r' % (param_name, best_parameters[param_name]))    
    return best_parameters



def quick_make_model(model="LR",best_parameters=None):
    #快速建模方法
    '''#best_params 就是之前取得的最优化参数结果'''
    model = LogisticRegression(C = best_parameters['lr__C'],
                               max_iter =  best_parameters['lr__max_iter'],
                               penalty = best_parameters['lr__penalty'])
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    print("Test set accuracy score: {:.5f}".format(accuracy_score(y_test, y_pred,)))
    print(classification_report(y_test, y_pred))
    
    return model
        

def get_lr_formula(model,X):
    '''返回回归系数和截距'''
    intercept = pd.DataFrame(model.intercept_) #截距
    coef = model.coef_.T   #模型(回归)系数(相关系数)
    coef = pd.DataFrame(coef)   
    formula = pd.concat([intercept,coef])
    index = ['Intercept']
    index = index + list(X.columns)
    formula.index = index
    formula.reset_index(inplace=True)
    formula.columns = [u'参数',u'估计值']
    return formula



Model_Evaluation_Plot(model,X_test,y_test) #绘图，混淆矩阵，KS曲线，AUC



import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.metrics import roc_curve,auc
from sklearn.metrics import confusion_matrix
from sklearn.metrics import accuracy_score,precision_score,recall_score
from scipy import stats

def __tool_sas_rank1(tmp_frame,group):
    '''
    这个按照 sas 公式实现rank分组功能，公式为
    floor(rank*k/(n+1))
    '''
    lenth = len(tmp_frame)
    tmp_frame['rank'] = tmp_frame.ix[:,1].rank(method='min')
    tmp_frame['group_num'] = tmp_frame.apply(lambda row : np.floor(row['rank']*group/(lenth+1)), axis=1)    


def Model_Evaluation_Plot(model,X,y,ksgroup=20):
    
    #plot Confusion Matrix 混淆矩阵
    y_pred = model.predict(X)
    cm = confusion_matrix(y, y_pred, labels=[0, 1])
    plt.figure(figsize=(10,6))
    fig, ax = plt.subplots()
    plt.matshow(cm, cmap=plt.cm.Blues, alpha=0.3)
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(x=j, y=i, s=cm[i, j], va='center', ha='center')

    plt.title('Confusion matrix')
    plt.ylabel('True label')
    plt.xlabel('Predicted label')
    plt.show()
    print("accuracy_score %s"%(str(accuracy_score(y,y_pred))))
    print("precision_score %s"%(str(precision_score(y,y_pred))))
    print("recall_score %s"%(str(recall_score(y,y_pred))))


    #plot ROC curve
    predictions_prob_forest = model.predict(X)
    false_positive_rate,recall,threshold = roc_curve(y,predictions_prob_forest[:,1])
    roc_auc = auc(false_positive_rate,recall)
    plt.title('ROC curve')  
    plt.ylabel('True Positive rate')
    plt.xlabel('False Positive rate')        
    print("ROC_AUC is %s"%roc_auc)
    plt.plot(false_positive_rate,recall)
    plt.plot([0, 1], [0, 1], 'r--')
    plt.show()

       
    #plot KS
    predictions_prob = pd.DataFrame(model.predict(X))
    predictions_prob['y'] = y.get_values()
    __tool_sas_rank1(predictions_prob,ksgroup)                
    closPred1 = predictions_prob.groupby('group_num')[1].agg({'minPred1':min,'maxPred1':max})
    colsy = predictions_prob.groupby('group_num')['y'].agg({'bad':sum,'N':len})
    colsy['good'] = colsy['N']-colsy['bad']
    colscumy = colsy.cumsum(0) 
    colscumy = colscumy.rename(columns={'bad':'cum1','N': 'cumN','good':'cum0'}) 
    colscumy['cum1Percent'] = colscumy['cum1']/colscumy['cum1'].max()
    colscumy['cum0Percent'] = colscumy['cum0']/colscumy['cum0'].max() 
    colscumy['cumDiff'] = abs(colscumy['cum1Percent']-colscumy['cum0Percent'])
    ks_file = pd.concat([closPred1,colsy,colscumy],axis=1)
    ks_file['group'] = ks_file.index
    x = np.arange(1,ks_file.shape[0]+1)
    
    plt.plot(x,ks_file['cum0Percent'], label='cum0Percent',marker='o')
    plt.plot(x,ks_file['cum1Percent'], label='cum1Percent',marker='o')
    plt.plot(x,ks_file['cumDiff'], label='cumDiff',marker='o')
    plt.legend()
    plt.title('KS')
    plt.legend(loc='upper left')
    datadotxy=tuple(zip((x+0.2),ks_file['cumDiff']))
    for dotxy in datadotxy:
        plt.annotate(str(round(dotxy[1],2)),xy=dotxy)
        plt.xlabel(u"group", fontproperties='SimHei')
    #plt.savefig("F:\moudle\modle\\KS.png",dpi=2000)
    plt.show()

    p = pd.DataFrame(model.predict_proba(X),index = X.index)
    p['y'] = y
    proba_y0 = np.array(p[p['y']==0][1])
    proba_y1 = np.array(p[p['y']==1][1])
    ks = stats.ks_2samp(proba_y0,proba_y1)[0]   
    print("K-S score %s"%str(ks))





#########################################################
"""
(二)数据预处理
"""
#########################################################
df = pd.read_csv(r'F:\TS\offline_model\01_Dataset\02_Interim\baseline_model_data.csv')
df.columns = df.columns.str.lower()  #列名变为小写df2 = df2.rename(columns={'BORROWER_TEL_ONE':'手机号'}, copy = False)
df = df.rename(columns = {'target':'y'}, copy = False)
colx = list(df.columns)
colx.remove('y')
dfX = df[colx]
dfY = df['y']
rm = preprocess.Preprocess(dfX,dfY)           #调用preprocess这个包。先调用类,然后再根据需要调用函数

rm.undigital_filler()                         #函数undigital_filler对于非数字的值转化为数字
p_ratio = rm.primaryvalue_ratio()             #函数primaryvalue_ratio()查看数据主要值的占比
rm.primaryvalue_ratio(discover=False,ratiolimit=0.95)    #只选取单一值小于95%的数据，如果主要的数据占比大于95%，数据没有什么意义
data = rm.selected_data                       #只保留了小于0.95的值，列和行,变量会减少(本次抛弃了15个变量)
#data.to_excel(r"F:\moudle\prepare_collection\output\data1.xls")
x = rm.find_nan_infinite()                    #查看数据里面有没有坏数据缺失数据
data.fillna(0,inplace=True)                  #对缺失数据进行填充

#########################################################
"""
(二)特征选择
"""
#########################################################

#==============================================================================
mh = model_helper.ModelHelper(df4) #建模工具,调用model_helper这个包


X_train,X_test,y_train,y_test = mh.train_test_split(recut=True,random_state=100)   #切分数据
mh.standard_scaler()                               #维度标准化
var_import = mh.pick_variables()                   #利用顶层特征选择算法，特征选择,得分(分数在0-100%)
var_importance = var_import[var_import['var_score']>0.1]  #不同的子集上建立模型，然后汇总最终确定特征得分，挑出阈值>0.05的重要特征
var_importance.reset_index(inplace=True)                
picked = list(var_importance['index'])             #得到了13个变量
picked.append("y")
mh.pick_variables_bylist(picked)       ##按照这个13个变量得到数据集

picked_parms = mh.model_optimizing()               ##使用LR ,简单建模看效果
mh.quick_make_model()  
step2_data = mh.picked_data


