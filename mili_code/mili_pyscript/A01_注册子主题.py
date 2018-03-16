# -*- coding: utf-8 -*-
"""
Created on Wed Jun 14 14:34:56 2017

@author: Administrator
"""

#==============================================================================
# 注册子主题
#==============================================================================

import pandas as pd
import csv

##注册时间、来源渠道
tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

df=pd.read_csv(tem+"\\"+ "user.csv")


df = df.drop(["ID",
"HAND_PASSWORD",
"CREATED_USER_ID",
"CREATED_USER_NAME", 
"UPDATED_USER_ID",
"UPDATED_USER_NAME", 
"VERSION", 
"REMARK"], axis=1)

df['用户注册月份'] = df['CREATED_TIME'].apply(lambda x:x[:7])
df['用户注册日期'] = df['CREATED_TIME'].apply(lambda x:x[:10])
df['用户注册时间段'] = df['CREATED_TIME'].apply(lambda x:x[11:13])
df['用户更新日期'] = df['UPDATED_TIME'].apply(lambda x:x[:10])

col_mapping={"CREATED_TIME":"用户注册时间", "UPDATED_TIME":"用户更新时间", "SOURCE_CHANNEL" : "来源渠道"}
df = df.rename(columns=col_mapping,copy=False)

##注册透视表数据源
register_submart = df[["USER_CODE","来源渠道", "用户注册月份", "用户注册日期", "用户注册时间段"]]
register_submart.columns = register_submart.columns.str.lower()

csvfile = tmp_dir + '\\'+ "register_submart.csv"
register_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

