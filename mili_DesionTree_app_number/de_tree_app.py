# -*- coding: utf-8 -*-
"""
Created on Thu Oct 19 10:32:36 2017

@author: Administrator
"""

import sys
import itertools
import numpy as np  
import scipy as sp  
import pandas as pd
import matplotlib.pyplot as plt
from sklearn import tree  
from sklearn import metrics
from sklearn.tree import DecisionTreeClassifier  
from sklearn.metrics import confusion_matrix
from sklearn.metrics import precision_recall_curve  
from sklearn.metrics import classification_report  
from sklearn.model_selection import train_test_split  
#from sklearn.pipeline import Pipeline  
from sklearn.grid_search import GridSearchCV  
from sklearn.metrics import accuracy_score,precision_score,recall_score

sys.path.append(r"F:\ML\lib")
import draw_plot
import plot_confusion_matrix

import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
plt.style.use('ggplot')  #风格设置接近R中的ggplot
import seaborn as sns #数据可视化模块
sns.set_style('whitegrid')
%matplotlib inline
import missingno as msno

#忽略弹出的warnings
import warnings
warnings.filterwarnings("ignore")


''''' 数据读入 '''  
df1 = pd.read_csv(r'F:\ML\decisiontree\data\app_loan_xz0.csv')
df2 = pd.read_csv(r'F:\moudle\prepare\data\repay.csv')


#df2 = df2.sort_values(by=['apply_code'], ascending=[True]).drop_duplicates(['apply_code']) 
#一个电话号码会来借款多次，我们保留他最大的一次逾期天数##新客户不存在多次借款
#df2 = df2.sort_values(by=['ID_NUMBER','曾经逾期天数'],ascending=[True,False]).drop_duplicates(['ID_NUMBER'],keep = 'first') 
df12 = pd.merge(df1, df2, on = "apply_code" , how = "left")

df3 = df12.rename(columns = {"网龄月份":"loc_network_age","od3":"y",
                 "申请提交点":"loc_apply_submit_time",
                 "MONTH_SALARY_NAME":"loc_month_salay",
                 "DEGREE_NAME":"degree_name_g",
                 "SEX_NAME":"sex_name_g",
                 "渠道标签":"channel"
                 },copy = False)

my_dict1 = {"2000以下":1, "2000-2999":2, "3000-4999":3, "5000-7999":4,"8000-11999":5,"12000及以上":6}
my_dict2 = {"初中及以下":1, "高中或中专":2, "大专":3, "本科":4,"硕士及以上":5}
my_dict3 = {"男":0, "女":1}

df3.loc_month_salay = df3.loc_month_salay.map(my_dict1)
df3.degree_name_g = df3.degree_name_g.map(my_dict2)
df3.sex_name_g = df3.sex_name_g.map(my_dict3)

df4 = df3[(df3.y == 0)|(df3.y == 1)] 

df5 = df4.drop([
'apply_code',
'CH_NAME',                    
'ID_NUMBER',                   
'还款天数',                        
'REPAY_DATE' ,                 
'CLEAR_DATE',                
'BILL_STATUS',                 
'OVERDUE_DAYS',                
'账户标签',                        
'od_days',                     
'放款月份',                        
'订单类型',                        
'曾经逾期天数',
'target_label'], axis = 1)

#x = df2.drop(['y'], axis = 1)
#msno.matrix(df5)  #查看缺失值的情况
df5.isnull().sum()/len(df5)
df5.shape
df5.info()
df5.describe().T

df6 = df5.fillna(df5.median())

'''loc_tel_fm_rank', 'loc_tel_po_rank', 'loc_tel_qs_rank数据缺失比例过大'''
'''loc_ava_exp缺失值占到15%-25%'''
'''degree_name_g', 'sex_name_g业务指标不能准备预测，删掉'''
data = df6.drop(['loc_tel_fm_rank', 'loc_tel_po_rank', 
              'loc_tel_qs_rank',
              'loc_appsl',
#              'degree_name_g', 'sex_name_g'
              ], axis = 1)

#data = data[(data["channel"] ==2)|(data["channel"] ==3)]
data = data[(data["channel"] ==2)]

data.groupby('channel').size()
data.groupby('y').size()

#==============================================================================
# csvfile = r"F:\ML\decisiontree\output\data.csv"
# data.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
#==============================================================================


#y = df4[['y']]  #Some programmers use capitalized variables for 2-dimensional arrays and lower-case for 1-dimensional arrays.
#y = df4['y']



''''' 绘图，初步分析 '''  

'''芝麻分'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
#plt.subplot2grid((2,3),(1,0), colspan=2)
data.loc_zmscore[data.y == 0].plot(kind='kde')   
data.loc_zmscore[data.y == 1].plot(kind='kde')
plt.xlabel(u"loc_zmsocre")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of zm_score")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

'''天启分'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
#plt.subplot2grid((2,3),(1,0), colspan=2)
data.loc_tqscore[data.y == 0].plot(kind='kde')   
data.loc_tqscore[data.y == 1].plot(kind='kde')
plt.xlabel(u"loc_tqsocre")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of tq_score")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

'''联系人'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
data.loc_txlsl[data.y == 0].plot(kind='kde')   
data.loc_txlsl[data.y == 1].plot(kind='kde')
plt.xlabel(u"loc_txlsl")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of txlsl")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

'''近一个月最大静默时长'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
data.loc_1mmaxcnt_silent[data.y == 0].plot(kind='kde')   
data.loc_1mmaxcnt_silent[data.y == 1].plot(kind='kde')
plt.xlabel(u"loc_1mmaxcnt_silent")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of 1mmaxcnt_silent")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

'''近三个月最大静默时长'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
data.loc_3mmaxcnt_silent[data.y == 0].plot(kind='kde')   
data.loc_3mmaxcnt_silent[data.y == 1].plot(kind='kde')
plt.xlabel(u"loc_3mmaxcnt_silent")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of 3mmaxcnt_silent")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

'''月收入区间'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
data.loc_month_salay[data.y == 0].plot(kind='kde')   
data.loc_month_salay[data.y == 1].plot(kind='kde')
plt.xlabel(u"loc_month_salay")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of loc_month_salay")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.

'''渠道'''
fig = plt.figure()
fig.set(alpha=0.2)  # 设定图表颜色alpha参数
data.channel[data.y == 0].plot(kind='kde')   
data.channel[data.y == 1].plot(kind='kde')
plt.xlabel(u"channel")# plots an axis lable
plt.ylabel(u"density") 
plt.title(u"Distribution of channel")
plt.legend((u'good', u'bad'),loc='best') # sets our legend for our graph.


'''特征的重要性排序'''
col = list(data.columns)
col_new = col.remove('y')
y = data['y']
x = data[col]

colX = data.columns

'''
['degree_name_g',  X0
 'sex_name_g',X1
 'loc_month_salay',X2
 'loc_ava_exp',X3
 'loc_zmscore',X4
 'loc_txlsl',X5
 'loc_3mcnt_silent',X6
 'loc_3mmaxcnt_silent',X7
 'loc_1mcnt_silent',X8
 'loc_1mmaxcnt_silent',X9
 'loc_tqscore',X10
 'loc_apply_submit_time',X11
 'loc_network_age',X12
 'channel'X13]
'''

'''模型训练'''
"""处理样本不平衡"""
'''
SMOET的基本原理是：采样最邻近算法，计算出每个少数类样本的K个近邻，
从K个近邻中随机挑选N个样本进行随机线性插值，构造新的少数样本，
同时将新样本与原数据合成，产生新的训练集。
'''
#正常客户与预期客户的比例数据差别较大，会对学习模型造成影响。
##'''构建X特征变量和Y目标变量'''

n_sample = y.shape[0]
n_pos_sample = y[y==0].shape[0]
n_neg_sample = y[y==1].shape[0]
print('样本个数:{};正样本占比{:.2%};负样本占比{:.2%}'.format(n_sample, 
                               n_pos_sample/n_sample,n_neg_sample/n_sample))
print('特征维数:', x.shape[1])


from imblearn.over_sampling import SMOTE
sm = SMOTE(random_state = 42)
x, y = sm.fit_sample(x, y)
print('通过SMOTE算法平衡正负样本比例后')
n_sample = y.shape[0]
n_pos_sample = y[y==0].shape[0]
n_neg_sample = y[y==1].shape[0]
print('样本个数:{};正样本占比{:.2%};负样本占比{:.2%}'.format(n_sample, 
                               n_pos_sample/n_sample,n_neg_sample/n_sample))



from sklearn.ensemble import RandomForestClassifier

clf = RandomForestClassifier(n_estimators=10, random_state=123) #构建分类随机森林分类器
clf.fit(x, y) #对自变量和因变量进行拟合
#x.columns, 
clf.feature_importances_
for feature in zip(
#        x.columns, 
        clf.feature_importances_):
    print(feature)

plt.style.use('fivethirtyeight')
plt.rcParams['figure.figsize'] = (12,6)

###feature importances 可视化
importances = clf.feature_importances_
#feat_names = x.columns
indices = np.argsort(importances)[::-1]
fig = plt.figure(figsize=(12,4))
plt.title('Feature importances by RandomTreeClassifier')
plt.bar(range(len(indices)), importances[indices],color='lightblue',align='center')
plt.step(range(len(indices)), np.cumsum(importances[indices]),where='mid',label='Cumulative')    
plt.xticks(range(len(indices)),colX[indices],rotation='vertical',fontsize=10)
plt.xlim([-1,len(indices)])
plt.show()


'''''构建分类器进行训练'''
'''baseline modle'''  

###未进行剪枝操作；最简单的且没有优化的分类器模型
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = 0.2)  

treeClassifier = DecisionTreeClassifier(class_weight = 'balanced')
treeClassifier.fit(x_train, y_train)
treeClassifier.score(x_train, y_train)
y_pred = treeClassifier.predict(x_test)
print("Test set accuracy score: {:.5f}".format(accuracy_score(y_pred, y_test,)))
#Test set accuracy score: 0.89044
cfm = confusion_matrix(y_test, y_pred, labels=[0, 1])
'''array([[334,  86],
          [ 83, 355]], dtype=int64)'''


plt.figure(figsize=(10,6))
fig, ax = plt.subplots()
ax.matshow(cfm, cmap=plt.cm.Blues, alpha=0.3)
for i in range(cfm.shape[0]):
    for j in range(cfm.shape[1]):
        ax.text(x=j, y=i, s=cfm[i, j], va='center', ha='center')
plt.xlabel('predicted label')
plt.ylabel('true label')
plt.show()



"""
剪枝：

如果是使用sklearn库的决策树生成的话，剪枝方法有限，仅仅只能改变其中参数来进行剪枝。
DecisionTreeClassifier(class_weight=None, criterion='gini', max_depth=7,
            max_features=None, max_leaf_nodes=None,
            min_impurity_split=1e-07, min_samples_leaf=10,
            min_samples_split=20, min_weight_fraction_leaf=0.0,
            presort=False, random_state=None, splitter='best')

criterion: ”gini” or “entropy”(default=”gini”)是计算属性的gini(基尼不纯度)还是entropy(信息增益)，来选择最合适的节点。
splitter: ”best” or “random”(default=”best”)随机选择属性还是选择不纯度最大的属性，建议用默认。
max_features: 选择最适属性时划分的特征不能超过此值。
当为整数时，即最大特征数；当为小数时，训练集特征数*小数；
if “auto”, then max_features=sqrt(n_features).
If “sqrt”, thenmax_features=sqrt(n_features).
If “log2”, thenmax_features=log2(n_features).
If None, then max_features=n_features.
max_depth: (default=None)设置树的最大深度，默认为None，这样建树时，会使每一个叶节点只有一个类别，或是达到min_samples_split。
min_samples_split:根据属性划分节点时，每个划分最少的样本数。
min_samples_leaf:叶子节点最少的样本数。
max_leaf_nodes: (default=None)叶子树的最大样本数。
min_weight_fraction_leaf: (default=0) 叶子节点所需要的最小权值
"""

from sklearn.model_selection import GridSearchCV
parameters = {#'max_features':(None, 9, 6),
              'max_depth':(2, 3, 4),                       #“最大树深度”（max_depth）
              'min_samples_leaf':(3,5,10,15,20,25,30,35),    #“叶节点最小样本数”（min_samples_leaf）
              'min_samples_split':(3,5,10,15,20,25,30,35),
              #'class_weight':('balanced',None)
}                         #区分一个内部节点需要的最少的样本数

clf1 = GridSearchCV(treeClassifier, parameters, cv=5)
clf1.fit(x_train, y_train)
#clf.best_score_, clf.score(x_test, y_test), clf.best_params_
best_parameters = clf1.best_params_
results = pd.DataFrame(clf1.cv_results_)   #性能结果评估

print ('最佳效果：%0.3f' %clf1.best_score_)  
print ('模型精度: %0.3f'%clf1.score(x_test, y_test))
print ('最优参数:', clf1.best_params_)  

'''
最佳效果：0.802
模型精度: 0.775
最优参数: {'max_depth': 4, 'min_samples_leaf': 15, 'min_samples_split': 10}
'''

predictions = clf1.predict(x_test)  
print (classification_report(y_test, predictions))  

'''
             precision    recall  f1-score   support

        0.0       0.70      0.93      0.80       411
        1.0       0.91      0.63      0.75       447

avg / total       0.81      0.78      0.77       858'''

##混淆矩阵
cfm1 = confusion_matrix(y_test, predictions, labels=[0, 1])
plt.figure(figsize=(10,6))
fig, ax = plt.subplots()
ax.matshow(cfm1, cmap=plt.cm.Blues, alpha=0.3)
for i in range(cfm1.shape[0]):
    for j in range(cfm1.shape[1]):
        ax.text(x=j, y=i, s=cfm1[i, j], va='center', ha='center')
plt.xlabel('predicted label')
plt.ylabel('true label')
plt.show()

'''array([[383,  28],
       [165, 282]], dtype=int64)'''
#==============================================================================
#计算

''''' 使用信息熵作为划分标准，对决策树进行训练 ''' 
#clf = tree.DecisionTreeClassifier(criterion='entropy',max_depth =3,min_samples_leaf = 20) 
clf = DecisionTreeClassifier(
                             max_depth =best_parameters['max_depth'], 
                             min_samples_leaf =best_parameters['min_samples_leaf'],
                             min_samples_split =best_parameters['min_samples_split'],
                             #class_weight = 'balanced'
#                             class_weight = best_parameters['class_weight']
                             )  

"""
max_depth:树的最大深度
"""
clf.fit(x_train, y_train)  
clf.fit(x, y)  

  
''''' 把决策树结构写入文件 '''      
dot_data = tree.export_graphviz(clf, out_file=r"F:\ML\decisiontree\output\best_tree_last2323.dot", 
                         #feature_names=x.columns,
                         #class_names=y.columns,                            
                         filled=True, rounded=True,  special_characters=True)  

 
   
''''' 系数反映每个特征的影响力。越大表示该特征在分类中起到的作用越大 '''  
print("每个特征的影响力",clf.feature_importances_)  
importances = clf.feature_importances_
indices = np.argsort(importances)
#cols = list(x.columns)
cols = [colX[x] for x in indices]
plt.figure(figsize=(8,4))
plt.title('Feature Importances')
plt.barh(range(len(indices)), importances[indices], color='b', align='center')
plt.yticks(range(len(indices)), cols)
plt.xlabel('Relative Importance')



'''预测结果'''
predict_target=clf.predict(x_test)
'''预测结果与真实结果比对'''
print('预测结果/真实结果:',sum(predict_target==y_test)/len(y_test))

clf3 = confusion_matrix(y_test, predict_target, labels=[0, 1])

'''输出准确率 召回率 
F值 : 如果综合考虑查准率与查全率，可以得到新的评价指标F1测试值，也称为综合分类率'''
print(classification_report(y_test,predict_target))

'''             
             precision    recall  f1-score   support

        0.0       0.70      0.94      0.81       411
        1.0       0.93      0.64      0.75       447

avg / total       0.82      0.78      0.78       858 '''

###########
#混淆矩阵


#==============================================================================




#############################################################
'''learning curves'''

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from sklearn.learning_curve import learning_curve

msyh = matplotlib.font_manager.FontProperties(fname='C:\Windows\Fonts\MSYHBD.TTF')

# 用sklearn的learning_curve得到training_score和cv_score，使用matplotlib画出learning curve
def plot_learning_curve(estimator, x, y, ylim=None, cv=None, n_jobs=1, 
                        train_sizes=np.linspace(.05, 1., 16), verbose=0, plot=True):
    """
    画出data在某模型上的learning curve.如果两者得分有很大的差距，意味着可能过度拟合训练数据了
    参数解释
    ----------
    estimator : 你用的分类器。
    title : 表格的标题。
    X : 输入的feature，numpy类型
    y : 输入的target vector
    ylim : tuple格式的(ymin, ymax), 设定图像中纵坐标的最低点和最高点
    cv : 做cross-validation的时候，数据分成的份数，其中一份作为cv集，其余n-1份作为training(默认为3份)
    n_jobs : 并行的的任务数(默认1)
    """
    train_sizes, train_scores, test_scores = learning_curve(
        estimator, x, y, cv=cv, n_jobs=n_jobs, train_sizes=train_sizes, verbose=verbose)

    train_scores_mean = np.mean(train_scores, axis=1)
    train_scores_std = np.std(train_scores, axis=1)
    test_scores_mean = np.mean(test_scores, axis=1)
    test_scores_std = np.std(test_scores, axis=1)

    if plot:
        plt.figure()
        plt.title(u"学习曲线", fontproperties=msyh)
        if ylim is not None:
            plt.ylim(*ylim)
        plt.xlabel(u"训练样本数", fontproperties=msyh)
        plt.ylabel(u"得分", fontproperties=msyh)
        plt.gca().invert_yaxis()
        plt.grid()

        plt.fill_between(train_sizes, train_scores_mean - train_scores_std, train_scores_mean + train_scores_std, 
                         alpha=0.1, color="b")
        plt.fill_between(train_sizes, test_scores_mean - test_scores_std, test_scores_mean + test_scores_std, 
                         alpha=0.1, color="r")
        plt.plot(train_sizes, train_scores_mean, 'o-', color="b", label=u"训练集上得分")
        plt.plot(train_sizes, test_scores_mean, 'o-', color="r", label=u"交叉验证集上得分")

        plt.legend(loc="best", prop=msyh)

        plt.draw()
        plt.show()
        plt.gca().invert_yaxis()

    midpoint = ((train_scores_mean[-1] + train_scores_std[-1]) + (test_scores_mean[-1] - test_scores_std[-1])) / 2
    diff = (train_scores_mean[-1] + train_scores_std[-1]) - (test_scores_mean[-1] - test_scores_std[-1])
    return midpoint, diff

plot_learning_curve(clf, x, y)


['degree_name_g',  X0
 'sex_name_g',X1
 'loc_month_salay',X2
 'loc_ava_exp',X3
 'loc_zmscore',X4
 'loc_txlsl',X5
 'loc_3mcnt_silent',X6
 'loc_3mmaxcnt_silent',X7
 'loc_1mcnt_silent',X8
 'loc_1mmaxcnt_silent',X9
 'loc_tqscore',X10
 'loc_apply_submit_time',X11
 'loc_network_age',X12
 'channel'X13]

my_dict1 = {"2000以下":1, "2000-2999":2, "3000-4999":3, "5000-7999":4,"8000-11999":5,"12000及以上":6}
my_dict2 = {"初中及以下":1, "高中或中专":2, "大专":3, "本科":4,"硕士及以上":5}
my_dict3 = {"男":0, "女":1}



##对通过率和坏账率的检验
data1 = data[(data["channel"] ==1)]
data2 = data[(data["channel"] ==2)]
data3 = data[(data["channel"] ==3)]
data23 = data[(data["channel"] ==2)|(data["channel"] ==3)]

da1 = data1[(data1["loc_month_salay"] >=3)&(data1["loc_1mmaxcnt_silent"] <=2)&(data1['loc_tqscore']>534)]
da1.shape[0]/data1.shape[0] = 14.6%
da1.y.sum()/da1.shape[0] = 2.8%   (本身的逾期率是9%)

#==============================================================================
# dr1 = data1[(data1["loc_month_salay"] >=4)&(data1["loc_1mmaxcnt_silent"] >2)&(data1['loc_txlsl']>103)]
# dr1.shape[0]/data1.shape[0] = 0.6%
# dr1.y.sum()/da1.shape[0]
#==============================================================================

da3 = data3[(data3["degree_name_g"] >2)&(data3["loc_zmscore"] >570)]
da3.shape[0]/data3.shape[0] = 35%
da3.y.sum()/da3.shape[0] = 9% (本身的逾期率是16%)
 
da23 = data23[(data23["loc_1mmaxcnt_silent"] ==0)&(data23["loc_zmscore"] >570)&(data23["loc_ava_exp"] >96)]
da23.shape[0]/data23.shape[0] = 37%
da23.y.sum()/da23.shape[0] = 9.2% (本身的逾期率是15.6%)


