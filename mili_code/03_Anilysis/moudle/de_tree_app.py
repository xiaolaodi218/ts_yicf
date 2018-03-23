# -*- coding: utf-8 -*-
"""
Created on Thu Oct 19 10:32:36 2017

@author: Administrator
"""

import itertools
import numpy as np  
import scipy as sp  
import pandas as pd
import matplotlib.pyplot as plt
from sklearn import tree  
from sklearn import metrics
from sklearn.metrics import confusion_matrix
from sklearn.tree import DecisionTreeClassifier  
from sklearn.metrics import precision_recall_curve  
from sklearn.metrics import classification_report  
from sklearn.model_selection import train_test_split  
from sklearn.pipeline import Pipeline  
from sklearn.grid_search import GridSearchCV  
from sklearn.metrics import accuracy_score,precision_score,recall_score


  
  
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
                 "SEX_NAME":"sex_name_g"},copy = False)

my_dict1 = {"2000以下":0, "2000-2999":1, "3000-4999":2, "5000-7999":3,"8000-11999":4,"12000及以上":5}
my_dict2 = {"初中及以下":0, "高中或中专":1, "大专":2, "本科":3,"硕士及以上":4}
my_dict3 = {"男":0, "女":1}

df3.loc_month_salay = df3.loc_month_salay.map(my_dict1)
df3.degree_name_g = df3.degree_name_g.map(my_dict2)
df3.sex_name_g = df3.sex_name_g.map(my_dict3)

df4 = df3[(df3.y == 0)|(df3.y == 1)] 

df5 = df4.drop([
'apply_code',
'CH_NAME',                    
'ID_NUMBER',                   
'ACCOUNT_STATUS',
'BORROWER_TEL_ONE',          
'还款天数',                        
'客户标签',                        
'REPAY_DATE' ,                 
'CLEAR_DATE',                
'BILL_STATUS',                 
'OVERDUE_DAYS',                
'cut_date',                    
'账户标签',                        
'od_days',                     
'放款月份',                        
'首次申请',                        
'订单类型',                        
'来源渠道',                        
'渠道标签',                        
'曾经逾期天数'], axis = 1)

#x = df2.drop(['y'], axis = 1)
#df5.isnull().sum()/len(df3)
df6 = df5.fillna(df5.median())

data = df6.drop(['loc_tel_fm_rank', 'loc_tel_po_rank', 
              'loc_tel_qs_rank',
#              'loc_appsl'
              ], axis = 1)

y = data.pop('y')
x = data

#y = df4[['y']]  #Some programmers use capitalized variables for 2-dimensional arrays and lower-case for 1-dimensional arrays.
#y = df4['y']


''''' 拆分训练数据与测试数据 '''  
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = 0.2)  

###最简单的且没有优化的概率分类器模型可以达到 72% 的精度 
treeClassifier = DecisionTreeClassifier()
treeClassifier.fit(x_train, y_train)
treeClassifier.score(x_test, y_test)
y_pred = treeClassifier.predict(x_test)
cfm = confusion_matrix(y_test, y_pred, labels=[0, 1])
plt.figure(figsize=(10,6))
plot_confusion_matrix(cfm, classes=["<=607", ">607"], normalize=True)

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


pipeline = Pipeline([('clf',DecisionTreeClassifier())])   
  
parameters = {  
#'clf__criterion':('entropy', 'gini'),     #“分裂条件”（criterion）
#'clf__max_depth': (2, 3, 4),              #“最大树深度”（max_depth）
#'clf__min_samples_leaf': (10, 15, 20)     #“叶节点最小样本数”（min_samples_leaf）
'clf__max_features':(None, 9, 6),
'clf__max_depth':(None, 4, 6),
'clf__min_samples_split': (2, 4, 8),
'clf__min_samples_leaf': (10, 15, 20)
}  
   
grid_search = GridSearchCV(pipeline, parameters, cv=5, n_jobs=4
 #                          n_jobs=-1,verbose=1, scoring='f1'
                           )  
grid_search.fit(x_train, y_train)  
print ('最佳效果：%0.3f' %grid_search.best_score_)  
print ('模型精度: %0.3f'%grid_search.score(x_test, y_test))
print ('最优参数')  
best_parameters = grid_search.best_best_parameters = grid_search.best_estimator_.get_params()  
for param_name in sorted(parameters.keys()):  
    print('\t%s: %r' % (param_name, best_parameters[param_name]))  
predictions = grid_search.predict(x_test)  
print (classification_report(y_test, predictions))  

#==============================================================================
#计算

''''' 使用信息熵作为划分标准，对决策树进行训练 ''' 
#clf = tree.DecisionTreeClassifier(criterion='entropy',max_depth =3,min_samples_leaf = 20) 
clf = DecisionTreeClassifier(criterion=best_parameters['clf__criterion'],
                             max_depth =best_parameters['clf__max_depth'], 
                             max_features =best_parameters['clf__max_features'],
                             min_samples_leaf =best_parameters['clf__min_samples_leaf'],
                             min_samples_split =best_parameters['clf__min_samples_split']
                             )  

"""
max_depth:树的最大深度
"""
clf.fit(x_train, y_train)  
#clf.fit(x, y)  
  
''''' 把决策树结构写入文件 '''      
dot_data = tree.export_graphviz(clf, out_file=r"F:\ML\decisiontree\output\best_tree1.dot", 
                         feature_names=x.columns,
                         #class_names=y.columns,                            
                         filled=True, rounded=True,  special_characters=True)  
   
   
''''' 系数反映每个特征的影响力。越大表示该特征在分类中起到的作用越大 '''  
print("每个特征的影响力",clf.feature_importances_)  
importances = clf.feature_importances_
indices = np.argsort(importances)
cols = list(x.columns)
cols = [cols[x] for x in indices]
plt.figure(figsize=(10,6))
plt.title('Feature Importances')
plt.barh(range(len(indices)), importances[indices], color='b', align='center')
plt.yticks(range(len(indices)), cols)
plt.xlabel('Relative Importance')



'''预测结果'''
predict_target=clf.predict(x_test)
'''预测结果与真实结果比对'''
print('预测结果/真实结果:',sum(predict_target==y_test)/len(y_test))

'''输出准确率 召回率 
F值 : 如果综合考虑查准率与查全率，可以得到新的评价指标F1测试值，也称为综合分类率'''
print(classification_report(y_test,predict_target))

###########
#混淆矩阵

def plot_confusion_matrix(cm, classes, normalize=False):
    """
    This function prints and plots the confusion matrix.
    Normalization can be applied by setting `normalize=True`.
    """
    cmap = plt.cm.Blues
    title = "Confusion Matrix"
    if normalize:
        cm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
        cm = np.around(cm, decimals=3)

    plt.imshow(cm, interpolation='nearest', cmap=cmap)
    plt.title(title)
    plt.colorbar()
    tick_marks = np.arange(len(classes))
    plt.xticks(tick_marks, classes, rotation=45)
    plt.yticks(tick_marks, classes)

    thresh = cm.max() / 2.
    for i, j in itertools.product(range(cm.shape[0]), range(cm.shape[1])):
        plt.text(j, i, cm[i, j],
                 horizontalalignment="center",
                 color="white" if cm[i, j] > thresh else "black")

    plt.tight_layout()
    plt.ylabel('Actual label')
    plt.xlabel('Predicted label')


cfm = confusion_matrix(y_test, predict_target, labels=[0, 1])
plt.figure(figsize=(10,6))
plot_confusion_matrix(cfm, classes=["<=602", ">602"], normalize=True)

##类别（<=602）的精度为 96.7%，少数类别（>602）的精度只有 9.7%。
#==============================================================================


######
'''
x.columns
Out[46]: 
Index(['loc_month_salay', 'loc_appsl', 'loc_ava_exp', 'loc_zmscore',
       'loc_txlsl', 'loc_3mcnt_silent', 'loc_3mmaxcnt_silent',
       'loc_1mcnt_silent', 'loc_1mmaxcnt_silent', 'loc_tqscore',
       'loc_apply_submit_time', 'loc_network_age'],
      dtype='object')
[ 0.          0.1190951   0.          0.43966183  0.03667006  0.14102803
  0.12984247  0.          0.          0.10665989  0.          0.02704262]

我们发现有几个特征是没有特征影响力的，我们可以删去然后再做一遍拟合
loc_month_salay
'''


#############################################################
'''learning curves'''

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from sklearn.learning_curve import learning_curve

msyh = matplotlib.font_manager.FontProperties(fname='C:\Windows\Fonts\MSYHBD.TTF')

# 用sklearn的learning_curve得到training_score和cv_score，使用matplotlib画出learning curve
def plot_learning_curve(estimator, x, y, ylim=None, cv=None, n_jobs=1, 
                        train_sizes=np.linspace(.05, 1., 20), verbose=0, plot=True):
    """
    画出data在某模型上的learning curve.
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


