# -*- coding: utf-8 -*-
"""
Created on Tue Sep 26 10:55:47 2017

@author: Administrator
"""

import os
import sys
import pandas as pd
import numpy as np

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

sys.path.append(r"F:\moudle\lib")
import iv
#import model_evaluation_plot
#import model_helper
#import preprocess



dir_tmp = r"F:\moudle\prepare_collection\output"

df1 = pd.read_excel(r"F:\moudle\prepare_collection\data\collection_test_result.xlsx")
df2 = pd.read_csv(r"F:\moudle\prepare\data\repay.csv")
dict_data = pd.read_excel(r"F:\moudle\prepare_collection\data\dict_collection.xlsx")

train_data = np.array(dict_data)#np.ndarray()
x_list=train_data.tolist()#list
#列表转换为字典
new_dict = {}
new_dict = dict(x_list)

df1 = df1.rename(columns=new_dict, copy=False)


#==============================================================================
'''数据解析与缺失值处理'''
df1.shape
#df1.info()
#df1.describe().T
#msno.matrix(df1)  #查看缺失值的情况

a = df1.sum()==0
b = list(a[a==True].index)
df1 = df1.drop(b,axis = 1)   #抛弃了2个值为0或者为null的变量

check_null = df1.isnull().sum(axis=0).sort_values(ascending=False)/float(len(df1))
#print(check_null>0.2)  #查看缺失比例大于0.2的

#objectColumns = df1.select_dtypes(include=["object"]).columns
#df1[objectColumns].isnull().sum().sort_values(ascending=False)
#msno.matrix(df1[objectColumns]) #缺失值可视化
#msno.heatmap(df1[objectColumns])  #查看缺失值之间的相关性

df2 = df2.rename(columns={'BORROWER_TEL_ONE':'手机号'}, copy = False)

df12 = pd.merge(df1, df2, on = "手机号" , how = "left")

#一个电话号码会来借款多次，我们保留他最大的一次逾期天数
df12 = df12.sort_values(by=['apply_code'], ascending=[True]).drop_duplicates(['apply_code']) 
df12 = df12.sort_values(by=['手机号','曾经逾期天数'],ascending=[True,False]).drop_duplicates(['手机号'],keep = 'first')
 
df12 = df12.drop(['apply_code', 'CH_NAME', 'ID_NUMBER', '还款天数','REPAY_DATE', 
                  'CLEAR_DATE', 'BILL_STATUS', 'OVERDUE_DAYS', '账户标签', 'od_days', 
                  '放款月份', '订单类型', '渠道标签', '曾经逾期天数', '手机号',], axis = 1)
df=df12.dropna(axis = 0)


'''
特征工程(feature engineering)
'''

#目标变量可视化
fig, axs = plt.subplots(1,2,figsize=(8, 4))
sns.countplot(x = 'y', data = df, ax = axs[0])
axs[0].set_title('Frequency of each y')
df['y'].value_counts().plot(x=None, y=None, kind = 'pie', ax=axs[1], autopct='%1.2f%%')
axs[1].set_title('Percentage of each y')
plt.show()

#查看目标变量列的情况 ，#发现逾期客户占两者数量不平衡
#绝大多数常见的机器学习算法对于不平衡数据集都不能很好地工作
df.groupby('y').size()



##移除方差过小的的变量,抛弃了15个
from sklearn.feature_selection import VarianceThreshold

vt = VarianceThreshold(threshold=.08)
x_vt=vt.fit_transform(df)
vt.get_support()
vt_columns = df.columns[vt.get_support()]
df = df[vt_columns]


#查看正常客户和逾期客户之间的区别
xod = df.loc[df["y"] == 1] # update xod & xnonod with cleaned data
xnonod = df.loc[df["y"] == 0]
                  
correlationNonod = xnonod.loc[:, df.columns != 'y'].corr()
mask = np.zeros_like(correlationNonod)
indices = np.triu_indices_from(correlationNonod)
mask[indices] = True

grid_kws = {"width_ratios": (.9, .9, .05), "wspace": 0.2}
f, (ax1, ax2, cbar_ax) = plt.subplots(1, 3, gridspec_kw=grid_kws, \
                                     figsize = (18, 12))

cmap = sns.diverging_palette(220, 8, as_cmap=True)
ax1 =sns.heatmap(correlationNonod, ax = ax1, vmin = -1, vmax = 1, \
    cmap = cmap, square = False, linewidths = 0.5, mask = mask, cbar = False)
ax1.set_xticklabels(ax1.get_xticklabels(), size = 8); 
ax1.set_yticklabels(ax1.get_yticklabels(), size = 8); 
ax1.set_title('Normal', size = 15)


correlationod = xod.loc[:, df.columns != 'y'].corr()
ax2 = sns.heatmap(correlationod, vmin = -1, vmax = 1, cmap = cmap, \
             ax = ax2, square = False, linewidths = 0.5, yticklabels = False, \
             cbar_ax = cbar_ax, mask = mask, cbar_kws={'orientation': 'vertical', \
             'ticks': [-1, -0.5, 0, 0.5, 1]})
ax2.set_xticklabels(ax2.get_xticklabels(), size = 10); 
ax2.set_title('Overdue', size = 15);

cbar_ax.set_yticklabels(cbar_ax.get_yticklabels(), size = 8);

##变量V20，V21，V30，V31与目标变量相关性太弱，剔除
col = ['V20','V21','V30','V31']
df_new = df.drop(col, axis=1)

##给出每个变量的频率关系图
#==============================================================================
# v_feat = df_new.columns
# plt.figure(figsize=(16,28*4))
# gs = gridspec.GridSpec(28,1)
# for i,cn in enumerate(df_new[v_feat]):
#     ax = plt.subplot(gs[i])
#     sns.distplot(df_new[cn][df_new['y']==1], bins=50)
#     sns.distplot(df_new[cn][df_new['y']==0], bins=100)
#     ax.set_xlabel('')
#     ax.set_title('histogram of feature:' + str(cn))
#==============================================================================

'''
标准化
'''
from sklearn.preprocessing import StandardScaler
sc = StandardScaler()
feature = list(df_new.columns)
feature.remove('y')
df_ml = df_new
df_ml[feature] = sc.fit_transform(df_ml[feature])
df_ml.head()

'''构建X特征变量和Y目标变量'''
feature_new = list(df_ml.columns)
feature_new.remove('y')
y = df_ml['y']
x = df_ml[feature_new]

'''特征选择'''
### Wrapper -- 递归特征消除
from sklearn.feature_selection import RFE
from sklearn.linear_model import LogisticRegression
# 建立逻辑回归分类器
model = LogisticRegression()
# 建立递归特征消除筛选器
rfe = RFE(model, 20) #通过递归选择特征，选择20个特征
rfe = rfe.fit(x, y)
# 打印筛选结果
print(rfe.support_)
print(rfe.ranking_) #ranking 为 1代表被选中，其他则未被代表未被选中

col_filter = x.columns[rfe.support_]
df_ml_new = df_ml[col_filter]
#筛选30个与目标变量相关性最强的特征

### Filter -- 过滤方法
'''
我们在第一次降维的基础上，通过皮尔森相关性图谱找出冗余特征并将其剔除；
同时，可以通过相关性图谱进一步引导我们选择特征的方向。
<0.4显著弱相关，0.4-0.75中等相关，大于0.75强相关
'''
colormap = plt.cm.viridis
plt.figure(figsize=(16,16))
plt.title('Person Correlation of Feature', y = 1.05, size = 12)
sns.heatmap(df_ml_new[col_filter].corr(), linewidths=0.1, vmax=1.0, 
            square=True,cmap = colormap,linecolor='white',annot=True)
col_filter = list(df_ml_new.columns)

#删掉一些冗余特征
col = ['V23','V36','V14','V37','V2']
df_ml_loan = df_ml_new.drop(col, axis=1)
col_filter_new = list(df_ml_loan.columns)
#col_filter_new.remove('y')

'''
通过特征重要性排序来挖掘哪些变量是比较重要的，降低学习难度，最终达到优化模型计算的目的
'''
names = df_ml_loan[col_filter_new].columns
from sklearn.ensemble import RandomForestClassifier

clf = RandomForestClassifier(n_estimators=10, random_state=123) #构建分类随机森林分类器
clf.fit(x[col_filter_new], y) #对自变量和因变量进行拟合
names, clf.feature_importances_
for feature in zip(names, clf.feature_importances_):
    print(feature)

plt.style.use('fivethirtyeight')
plt.rcParams['figure.figsize'] = (12,6)

###feature importances 可视化
importances = clf.feature_importances_
feat_names = names
indices = np.argsort(importances)[::-1]
fig = plt.figure(figsize=(12,4))
plt.title('Feature importances by RandomTreeClassifier')
plt.bar(range(len(indices)), importances[indices],color='lightblue',align='center')
plt.step(range(len(indices)), np.cumsum(importances[indices]),where='mid',label='Cumulative')    
plt.xticks(range(len(indices)),feat_names[indices],rotation='vertical',fontsize=10)
plt.xlim([-1,len(indices)])
plt.show()

'''模型训练'''
"""处理样本不平衡"""
#正常客户与预期客户的比例数据差别较大，会对学习模型造成影响。
##'''构建X特征变量和Y目标变量'''
y = df_ml['y']
x = df_ml[col_filter_new]

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


'''计算iv值'''
iv_value, iv_detail = iv.cal_iv(df_ml_loan, group=10)
iv_value.to_excel(r"F:\moudle\prepare_collection\output\iv_value.xls")
iv_detail.to_excel(r"F:\moudle\prepare_collection\output\iv_detail.xls")









'''构建分类器进行训练'''
'''baseline modle'''
from sklearn.linear_model import LogisticRegression
clf1 = LogisticRegression()
clf1.fit(x, y)

predicted1 = clf1.predict(x)


from sklearn.metrics import accuracy_score
from sklearn.metrics import roc_curve, auc
print("Test set accuracy score: {:.5f}".format(accuracy_score(predicted1,y,)))
##Test set accuracy score: 0.62648

#混淆矩阵
def plot_confusion_matrix(cm, classes,
                          title='Confusion matrix',
                          cmap=plt.cm.Blues):
    """
    This function prints and plots the confusion matrix.
    """
    plt.imshow(cm, interpolation='nearest', cmap=cmap)
    plt.title(title)
    plt.colorbar()
    tick_marks = np.arange(len(classes))
    plt.xticks(tick_marks, classes, rotation=0)
    plt.yticks(tick_marks, classes)

    thresh = cm.max() / 2.
    for i, j in itertools.product(range(cm.shape[0]), range(cm.shape[1])):
        plt.text(j, i, cm[i, j],
                 horizontalalignment="center",
                 color="white" if cm[i, j] > thresh else "black")

    plt.tight_layout()
    plt.ylabel('True label')
    plt.xlabel('Predicted label')
    
##################################################################################

# Compute confusion matrix
cnf_matrix = confusion_matrix(y, predicted1)  # 生成混淆矩阵
np.set_printoptions(precision=2)

print("Recall metric in the testing dataset: ", cnf_matrix[1,1]/(cnf_matrix[1,0]+cnf_matrix[1,1]))

# Plot non-normalized confusion matrix
class_names = [0,1]
plt.figure()
plot_confusion_matrix(cnf_matrix, classes=class_names, title='Confusion matrix')
plt.show()


y_pred1_prob = clf1.predict_proba(x)[:, 1]  # 阈值默认值为0.5

fpr, tpr, thresholds = roc_curve(y,y_pred1_prob)
roc_auc = auc(fpr,tpr)

# 绘制 ROC曲线
plt.title('Receiver Operating Characteristic')
plt.plot(fpr, tpr, 'b',label='AUC = %0.5f'% roc_auc)
plt.legend(loc='lower right')
plt.plot([0,1],[0,1],'r--')
plt.xlim([-0.1,1.0])
plt.ylim([-0.1,1.01])
plt.ylabel('True Positive Rate')
plt.xlabel('False Positive Rate')
plt.show()


'''模型评估与优化'''
'''
我们的模型训练和测试都在同一个数据集上进行，这会产生2个问题：
1、很可能导致学习器把训练样本学得“太好”，把训练样本自身的特点当做所有潜在样本都会具有的一般性质。
2、模型在同一个数据集上进行训练和测试，使得测试集的样本属性提前泄露给模型。
以上2个问题都会导致模型的泛化能力下降，这种现象我们称之为“过拟合”（overfitting）。
'''
from sklearn.model_selection import GridSearchCV
from sklearn.cross_validation import train_test_split 

X_train, X_test, y_train, y_test = train_test_split(x, y, test_size = 0.3, random_state = 0) # random_state = 0 每次切分的数据都一样
# 构建参数组合
param_grid = {'C': [0.01,0.1, 1, 10, 100, 1000,],
                            'penalty': [ 'l1', 'l2']}
# 确定模型LogisticRegression，和参数组合param_grid ，cv指定5折
grid_search = GridSearchCV(LogisticRegression(),  param_grid, cv=10) 
grid_search.fit(X_train, y_train) # 使用训练集学习算法


results = pd.DataFrame(grid_search.cv_results_)   #性能结果评估
best = np.argmax(results.mean_test_score.values)
print("Best parameters: {}".format(grid_search.best_params_))
print("Best cross-validation score: {:.5f}".format(grid_search.best_score_))


#scores = np.array(results.mean_test_score).reshape(2, 6)
#sns.heatmap(scores, ylabel='penalty', yticklabels=param_grid['penalty'],
#                      xlabel='C', xticklabels=param_grid['C'], cmap="viridis")


y_pred = grid_search.predict(X_test)
print("Test set accuracy score: {:.5f}".format(accuracy_score(y_test, y_pred,)))
print(classification_report(y_test, y_pred))


'''对混淆矩阵可视化。'''
# Compute confusion matrix
cnf_matrix = confusion_matrix(y_test, y_pred)  # 生成混淆矩阵
np.set_printoptions(precision=2)

print("Recall metric in the testing dataset: ", cnf_matrix[1,1]/(cnf_matrix[1,0]+cnf_matrix[1,1]))

# Plot non-normalized confusion matrix
class_names = [0,1]
plt.figure()
plot_confusion_matrix(cnf_matrix, classes=class_names, title='Confusion matrix')
plt.show()


'''
模型评估
解决不同的问题，通常需要不同的指标来度量模型的性能。
例如我们希望用算法来预测癌症是否是恶性的，假设100个病人中有5个病人的癌症是恶性，
对于医生来说，尽可能提高模型的查全率（recall）比提高查准率（precision）更为重要，
因为站在病人的角度，发生漏发现癌症为恶性比发生误判为癌症是恶性更为严重。
'''
y_pred_proba = grid_search.predict_proba(X_test)  #predict_prob 获得一个概率值

thresholds = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]  # 设定不同阈值

plt.figure(figsize=(15,10))

j = 1
for i in thresholds:
    y_test_predictions_high_recall = y_pred_proba[:,1] > i#预测出来的概率值是否大于阈值 
    
    plt.subplot(3,3,j)
    j += 1
    
    # Compute confusion matrix
    cnf_matrix = confusion_matrix(y_test, y_test_predictions_high_recall)
    np.set_printoptions(precision=2)

    print("Recall metric in the testing dataset: ", cnf_matrix[1,1]/(cnf_matrix[1,0]+cnf_matrix[1,1]))

    # Plot non-normalized confusion matrix
    class_names = [0,1]
    plot_confusion_matrix(cnf_matrix, classes=class_names)


'''可视化'''
from itertools import cycle

thresholds = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]
colors = cycle(['navy', 'turquoise', 'darkorange', 'cornflowerblue', 'teal', 'red', 'yellow', 'green', 'blue','black'])

plt.figure(figsize=(12,7))

j = 1
for i,color in zip(thresholds,colors):
    y_test_predictions_prob = y_pred_proba[:,1] > i #预测出来的概率值是否大于阈值  

    precision, recall, thresholds = precision_recall_curve(y_test, y_test_predictions_prob)
    area = auc(recall, precision)
    
    # Plot Precision-Recall curve
    plt.plot(recall, precision, color=color,
                 label='Threshold: %s, AUC=%0.5f' %(i , area))
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.ylim([0.0, 1.05])
    plt.xlim([0.0, 1.0])
    plt.title('Precision-Recall Curve')
    plt.legend(loc="lower left")










#########################################################
"""
(二)数据预处理
"""
#########################################################

rm = preprocess.Preprocess(dfX,dfY)           #调用preprocess这个包。先调用类,然后再根据需要调用函数

rm.undigital_filler()                         #函数undigital_filler对于非数字的值转化为数字
p_ratio = rm.primaryvalue_ratio()             #函数primaryvalue_ratio()查看数据主要值的占比
rm.primaryvalue_ratio(discover=False,ratiolimit=0.9999)    #只选取单一值小于98%的数据，如果主要的数据占比大于98%，数据没有什么意义
data = rm.selected_data                       #只保留了小于0.98的值，列和行,变量会减少(本次抛弃了15个变量)
#data.to_excel(r"F:\moudle\prepare_collection\output\data1.xls")
#x = rm.find_nan_infinite()                    #查看数据里面有没有坏数据缺失数据
#data.fillna(0,inplace=True)                  #对缺失数据进行填充

#########################################################
"""
(二)特征选择
"""
#########################################################

#==============================================================================
mh = model_helper.ModelHelper(data) #建模工具,调用model_helper这个包


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


#############################
"""
(三) iv值
"""
#############################

##计算iv统计变量
iv_value, iv_detail = iv.cal_iv(step2_data,group=10)
iv_value.to_excel(r"F:\moudle\prepare_collection\output\iv_backup.xls")
iv_detail.to_excel(r"F:\moudle\prepare_collection\output\iv_detail_step2.xls")
iv_value.to_excel(r"F:\moudle\prepare_collection\output\new_iv\iv_group.xls")

# ##调整iv分组
group = pd.read_excel(r"F:\moudle\prepare_collection\output\new_iv\iv_group.xls")
new_iv = iv.group_manual_regulation(group,iv_detail)
new_iv.to_excel(r"F:\moudle\prepare_collection\output\new_iv\iv_newgroup.xls")


###回填WOE
iv_value = pd.read_excel(r"F:\moudle\prepare_collection\output\iv_backup.xls")
group = pd.read_excel(r"F:\moudle\prepare_collection\output\new_iv\iv_newgroup.xls")
step4_data = step2_data[iv_value['var_name'].unique()]   #只需要选中的变量
step4_data = pd.concat((step4_data,step2_data.ix[:,-1]),axis=1)  #将y填上                     
woe_data = iv.filling_woe(group,step4_data)   #按照上面给出的变量返回x和y
woe_data.to_csv(r"F:\moudle\prepare_collection\output\new_iv\setp4_data.csv",sep=',',encoding = 'utf-8')


#############################
"""
(四) 建模
"""
#############################


###为评分卡建模
woe_data = pd.read_csv(r"F:\moudle\prepare_collection\output\new_iv\setp4_data.csv")
woe_data.index.names = ['key']
woe_data.set_index("key",inplace=True)


mt = model_helper.ModelHelper(woe_data)   ##建模工具
X_train,X_test,y_train,y_test = mt.train_test_split(recut=True,random_state=100)   #切分数据
mt.standard_scaler() 
                                      #维度标准化
picked_parms = mt.model_optimizing()                       ##使用LR
model = mt.quick_make_model(best_params=picked_parms)

model = mt.quick_make_model()
X = mt.X_train
formular = mt.get_lr_formula(model,X)
formular.to_excel(r"F:\moudle\modle\modlemodel_pinan.xlsx")


##生成评分卡
woe = pd.read_excel(r"F:\moudle\prepare_collection\output\new_iv\iv_newgroup.xls")
formular = pd.read_excel(r"F:\moudle\modle\modlemodel_pinan.xlsx")
scorecard = iv.make_scorecard(formular,woe)
scorecard.to_excel(r"F:\moudle\modle\scorecard.xlsx")
