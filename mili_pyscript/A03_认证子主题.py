# -*- coding: utf-8 -*-
"""
Created on Thu Jun 15 10:10:23 2017

@author: Administrator
"""

#==============================================================================
#认证子主题——逻辑二
#==============================================================================

import pandas as pd
from pandas import DataFrame
import csv

##来源渠道
tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

source_channel=pd.read_csv(tmp_dir+"\\"+ "register_submart.csv")
df=pd.read_csv(tem+"\\"+ "user_verification_info.csv")

source_channel=source_channel[["USER_CODE", "来源渠道"]]

df=df[["USER_CODE", "VERIFY_TYPE", "UPDATED_TIME"]]
df['认证月份'] = df['UPDATED_TIME'].apply(lambda x:x[:7])
df['认证日期'] = df['UPDATED_TIME'].apply(lambda x:x[:10])
df = df.drop(["UPDATED_TIME"],axis=1)

#==============================================================================
##完成运营商认证时间
operatorverify=df[df["VERIFY_TYPE"]==3]
col_mapping={"认证日期":"运营商认证日期","认证月份":"运营商认证月份"}
operverify_verify = operatorverify.rename(columns=col_mapping,copy=False)
operverify_submart = pd.merge(operator_verify,source_channel,on="USER_CODE",how="left")
operverify_submart = operverify_submart.drop(["VERIFY_TYPE"],axis=1)
operverify_submart = operverify_submart.drop_duplicates(['USER_CODE']) 
operverify_submart = operverify_submart.sort_values(by=['USER_CODE'],ascending=True)

#==============================================================================
##完成淘宝商认证时间
taobaoverify=df[df["VERIFY_TYPE"]==5]
col_mapping={"认证日期":"淘宝认证日期","认证月份":"淘宝认证月份"}
taobaoverify = taobaoverify.rename(columns=col_mapping,copy=False)
taobaoverify = taobaoverify.drop(["VERIFY_TYPE"],axis=1)
taobao_verify = pd.merge(taobaoverify,source_channel,on="USER_CODE",how="left")
tbverify_submart = tbverify_submart.drop_duplicates(['USER_CODE']) 
tbverify_submart = tbverify_submart.sort_values(by=['USER_CODE'])
 
#==============================================================================
##完成京东认证时间
jingdongverify=df[df["VERIFY_TYPE"]==6]
col_mapping={"认证日期":"京东认证日期","认证月份":"京东认证月份"}
jingdongverify = jingdongverify.rename(columns=col_mapping,copy=False)
jingdongverify = jingdongverify.drop(["VERIFY_TYPE"],axis=1)
jingdong_verify = pd.merge(jingdongverify,source_channel,on="USER_CODE")
jingdong_submart = jingdong_submart.drop_duplicates(['USER_CODE']) 
jingdong_submart = jingdong_submart.sort_values(by=['USER_CODE'])

#==============================================================================
##完成电商认证时间
ebusiverify_verify = pd.merge(tb,jd,on="USER_CODE",how="left")
ebusiverify_submart = pd.merge(ebusiverify_verify,source_channel,on="USER_CODE",how="left")
ebusiverify_submart = ebusiverify_submart.drop_duplicates(['USER_CODE']) 
ebusiverify_submart = ebusiverify_submart.sort_values(by=['USER_CODE'])

operverify_submart.columns = operverify_submart.columns.str.lower()
tbverify_submart.columns = tbverify_submart.columns.str.lower()
jingdong_submart.columns = jingdong_submart.columns.str.lower()
ebusiverify_submart.columns = ebusiverify_submart.columns.str.lower()


csvfile1 = tmp_dir + '\\'+ "operverify_submart.csv"
csvfile2 = tmp_dir + '\\'+ "tbverify_submart.csv"
csvfile3 = tmp_dir + '\\'+ "jingdong_submart.csv"
csvfile4 = tmp_dir + '\\'+ "ebusiverify_submart.csv"

operverify_submart.to_csv(csvfile1,sep=',',index=False ,encoding = 'utf-8')
tbverify_submart.to_csv(csvfile2,sep=',',index=False ,encoding = 'utf-8')
jingdong_submart.to_csv(csvfile3,sep=',',index=False ,encoding = 'utf-8')
ebusiverify_submart.to_csv(csvfile4,sep=',',index=False ,encoding = 'utf-8')

