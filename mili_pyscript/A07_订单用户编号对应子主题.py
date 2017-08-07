# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 18:16:48 2017

@author: Administrator

"""
#==============================================================================
# 订单号与手机号身份证号等对应子主题
#==============================================================================

import pandas as pd
from pandas import DataFrame
import csv

tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

apply_user_code = pd.read_csv(ten +"\\"+ "apply_info.csv")
user_phone_no = pd.read_csv(tem +"\\"+ "user.csv")
user_id_no = pd.read_csv(tem +"\\"+ "user_base_info.csv")

apply_user_code = apply_user_code[["apply_code","user_code"]]

##用户编号对应手机号;
user_phone_no = user_phone_no[["USER_CODE","PHONE_NO"]]
user_phone_no.columns = user_phone_no.columns.str.lower()

##用户编号对应姓名身份证号;
user_id_no = user_id_no[["USER_CODE","USER_NAME","ID_CARD"]]
user_id_no.columns = user_id_no.columns.str.lower()

a=pd.merge(user_phone_no,user_id_no,on='user_code',how='left')
id_submart=apply_user_code.combine_first(a) 

csvfile = tmp_dir + '\\'+ "id_submart.csv"
id_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

