# -*- coding: utf-8 -*-
"""
Created on Wed Jan 31 10:21:36 2018

@author: Yichengfan

###线下201707催收分评估
"""
import numpy as np
import pandas as pd
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


path1 = r'F:\TS\external_data_test\电话邦\通善_测试结果\催收分_测试结果_1579.csv'
path2 = r'F:\TS\external_data_test\电话邦\通善_测试结果\线下提取通话详单订单号.csv'
path3 = r'F:\TS\external_data_test\电话邦\通善_测试结果\data\target_g.csv'
path4 = r'F:\TS\external_data_test\电话邦\通善_测试结果\催收分字典.csv'

f1= open(path1, encoding="utf-8")
df1= pd.read_csv(f1)

f2= open(path2, encoding="utf-8")
df2= pd.read_csv(f2)

f3= open(path3, encoding="utf-8")
df3= pd.read_csv(f3)

f4= open(path4, encoding="utf-8")
df4= pd.read_csv(f4)


#将催收分数据变量进行编码
train_data = np.array(df4)#np.ndarray()
x_list=train_data.tolist()#list
#列表转换为字典
dict_data = {}
dict_data = dict(x_list)

df1 = df1.rename(columns = dict_data, copy = False)


df1 = df1.rename(columns = {'uid':'tel_phone'}, copy = False)
df1 = df1.drop(['sid'], axis = 1)

#拼接线下提取通话详单订单号和target_g
df23 = pd.merge(df2, df3, how = 'left', on = 'apply_code')


df123 = pd.merge(df1, df23, how = 'left', on = 'tel_phone')
df123 = df123.drop(['apply_code','tel_phone'], axis = 1)
df123.y.isnull().sum()
df123.groupby('y').size()

lf = df123[(df123['y'] == 0)|(df123['y'] == 1)]
lf.y.isnull().sum()
lf.groupby('y').size()
'''
y
0.0    1381
1.0     104
7.5%
'''

a = step01_feature_engine.fill_null_data(lf)
#==============================================================================
#绘图
objectColumns = lf.select_dtypes(include=["object"]).columns
var = lf[objectColumns].columns
for i in var:
    step06_draw_plot.drawBar(lf[i])


objectColumns = lf.select_dtypes(include=["float"]).columns
var = lf[objectColumns].columns
for i in var:
    step06_draw_plot.drawHistogram(lf[i])

#同值化检查
lf2, feature_primaryvalue_ratio = step01_feature_engine.select_primaryvalue_ratio(lf,ratiolimit = 0.931)

#打印字符型变量
step01_feature_engine.check_feature_binary(lf2)

#观察各个离散值的分布情况
step01_feature_engine.watch_obj(lf2)


# 构建mapping，对有序变量进行转换
mapping_dict1 = {
    "var1": {"无":0, "近151-180天":1, "近121-150天":1, "近91-120天":1, "近61-90天":1,
             "近31-60天":2,"近16-30天":3, "近8-15天":3, "近6-7天":4, "近4-5天":4, "近3天":5},
    "var2": {"无":0, "180天前":1,"近151-180天":2, "近121-150天":2, "近91-120天":2, "近61-90天":2,
             "近31-60天":3,"近16-30天":4, "近8-15天":4, "近6-7天":5, "近4-5天":5, "近3天":6},
    "var14":{"无":0, "180天前":1,"近151-180天":2, "近121-150天":2, "近91-120天":2, "近61-90天":2,
             "近31-60天":3,"近16-30天":4, "近8-15天":4, "近6-7天":5, "近4-5天":5, "近3天":6},
    "var15": {"无":0, "180天前":1,"近151-180天":2, "近121-150天":2, "近91-120天":2, "近61-90天":2,
             "近31-60天":3,"近16-30天":4, "近8-15天":4, "近6-7天":5, "近4-5天":5, "近3天":6}}

lf3 = lf2.replace(mapping_dict1) #变量映射

var = [ "var1", "var2", "var14","var15"]
str_value = step01_feature_engine.str_ratio(lf3,var)


#IV保留大于0.02的变量，170个变量保留126个
new_data,iv_value = step01_feature_engine.filter_iv(lf3, group=10)

#对数据按照IV大小顺序进行排序，以便于使用fillter_pearson删除相关性较高里面IV值低的数据
list_value = iv_value[iv_value.ori_IV >= 0.02].var_name
iv_sort_columns = list(list_value.drop_duplicates())
lf4 = new_data[iv_sort_columns]

iv_value.to_excel(r"F:\TS\external_data_test\电话邦\通善_测试结果\output\iv_value.xls")

##皮尔森系数绘图，观察多重共线的变量
pearson_coef = step02_modle_plot.plot_pearson(lf4)

#多变量分析，保留相关性低于阈值0.6的变量
#对产生的相关系数矩阵进行比较，并删除IV比较小的变量
per_col = step02_modle_plot.fillter_pearson(pearson_coef, threshold = 0.60)
print ('保留了变量有:',len(per_col))
print (per_col)   #136个变量,保留37个
lf5 = new_data[['var8', 'var94', 'var17', 'var7', 'var13', 'var139', 'var78', 'var53',
               'var121', 'var97', 'var147', 'var113', 'var59', 'var57', 'var27',
               'var114', 'var26', 'var144', 'var154', 'var2', 'var141', 'var136',
               'var65', 'var135', 'var123', 'var107', 'var108', 'var122', 'var40',
               'var118', 'var133', 'var89', 'var19', 'var14', 'var134', 'var145',
               'var156','y']]  

pearson_coef = step02_modle_plot.plot_pearson(lf5)  #再次观察共线情况

lf5.to_csv(r"C:\Users\Administrator\Desktop\data.csv")

data,iv_value = step01_feature_engine.filter_iv(lf5, group=5)

iv_value.to_excel(r"F:\TS\external_data_test\电话邦\通善_测试结果\output\iv_value_2.xls")



X, y = step01_feature_engine.x_y_data(data)

vif_data = step01_feature_engine.judge_vif(X) #两个变量VIF>10,共线


X, y = step01_feature_engine.smote_data(X, y)

model = step03_built_modle.baseline_model(X, y)




