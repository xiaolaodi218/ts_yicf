# -*- coding: utf-8 -*-
"""
Created on Wed Dec 27 12:47:37 2017

@author: Administrator
"""
import rpy2.robjects as robjects    #这个命令是导入 r对象

# R 语言测试脚本
r_script = '''
x <- c(1,2,3,4)
y <- x*x
plt <- plot(x,y)            # 画散点图
dev.off()                   # 关闭设备
'''                  
robjects.r.source('plot_demo.r')
  
df = pd.read_csv(r"F:\TS\offline_model\01_Dataset\02_Interim\middle_data\middle_data2.csv",encoding = 'utf-8')

r_script = '''
library(randomForest) # 导入随机森林包
## use data set iris
data = iris # 使用鸢尾花数据集
table(data$Species)
## create a randomForest model to classfy the iris species
# 创建随机森林模型给鸢尾花分类
iris.rf <- randomForest(Species~., data = data, importance=T, proximity=T)
print('--------here is the random model-------')
print(iris.rf)
print('--------here is the names of model-----')
print(names(iris.rf))
confusion = iris.rf$confusion
print(confusion)
'''
robjects.r(r_script)


import rpy2.robjects as robjects
pi = robjects.r('pi')
pi[0]

rscript = '''
df = iris
m = lm(Sepal_Length~Sepal_Width, data = df)
'''
pymodel = robjects.r(rscript)


