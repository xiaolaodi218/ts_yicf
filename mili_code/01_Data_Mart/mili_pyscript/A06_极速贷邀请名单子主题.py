# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 18:15:12 2017

@author: Administrator
"""
##极速贷邀请名单子主题

import pandas as pd
from pandas import DataFrame
import csv

tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

jsdinvite_submart=pd.read_csv(tem +"\\"+ "circular.csv")

jsdinvite_submart = jsdinvite_submart.drop(["ID","URI_PATH","REMARK","DEADLINE","STATUS","UPDATED_TIME","TYPE"], axis=1)
jsdinvite_submart = jsdinvite_submart[jsdinvite_submart["NAME"] =="马上拿钱"]
jsdinvite_submart['极速贷邀请月份'] = jsdinvite_submart['CREATED_TIME'].apply(lambda x:x[:7])
jsdinvite_submart['极速贷邀请日期'] = jsdinvite_submart['CREATED_TIME'].apply(lambda x:x[:10])
jsdinvite_submart = jsdinvite_submart.rename(columns={"CREATED_TIME":"极速贷邀请时间"},copy=False)
jsdinvite_submart = jsdinvite_submart.drop(["NAME"], axis=1)

csvfile = tmp_dir + '\\'+ "jsdinvite_submart.csv"
jsdinvite_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
