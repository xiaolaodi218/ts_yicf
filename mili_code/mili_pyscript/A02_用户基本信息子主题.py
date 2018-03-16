# -*- coding: utf-8 -*-
"""
Created on Wed Jun 14 17:31:58 2017

@author: Administrator
"""

#==============================================================================
#用户基本信息子主题
#==============================================================================

import pandas as pd
from pandas import DataFrame
import csv

##用户基本信息
tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

df=pd.read_csv(tem+"\\"+ "user_base_info.csv")

df = df.drop(["ID", 
"REMARK",
"CREATED_USER_ID", 
"CREATED_USER_NAME", 
"CREATED_TIME" ,
"UPDATED_USER_ID" ,
"UPDATED_USER_NAME", 
"UPDATED_TIME", 
"VERSION"], axis=1)

df.SEX = df.SEX.map({0: '女', 1: '男'})
df.columns = df.columns.str.lower()

   
csvfile = tmp_dir + '\\'+ "user_base_info.csv"
df.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')



#==============================================================================
# 计算总服务费
#==============================================================================
#==============================================================================
# import pandas as pd
# from pandas import DataFrame
# import csv
# 
# ##申请审批状态
# tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
# ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
# tmp_dir = r"D:\mili\Datamart\pyscript\submart"
# 
# df=pd.read_csv(tem +"\\"+ "loan_info.csv")
# 
# df=df[["apply_code","contract_amount", "loan_amt", "period" ,"service_amt", "loan_date", "status"]]
# 
# df=df[df["status"]==304]
# #按照索引删除
# index=list(df[df["loan_date"]=='2017-06-16'].index)
# df.drop(index,axis=0)
# df = df.drop_duplicates(['apply_code']) 
# 
# 
# loan_amt_sum=df['contract_amount'].sum()
# service_amt_sum=df['service_amt'].sum()
# rate=service_amt_sum/loan_amt_sum
#==============================================================================

