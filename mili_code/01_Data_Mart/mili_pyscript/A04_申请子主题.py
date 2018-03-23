# -*- coding: utf-8 -*-
"""
Created on Thu Jun 15 16:39:26 2017

@author: Administrator
"""

#==============================================================================
# 申请子主题
#==============================================================================

import pandas as pd
from pandas import DataFrame
import csv

##申请审批状态
tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

df=pd.read_csv(ten +"\\"+ "apply_info.csv")
handle_code=pd.read_csv(ten +"\\"+ "approval_info.csv")
loan_info=pd.read_csv(tem +"\\"+ "loan_info.csv")
source_channel=pd.read_csv(tmp_dir +"\\"+ "register_submart.csv")

apply_status=df[["apply_code", 
"status" ,
"last_updated", 
"user_code",
"os_type", 
"ip_area",
"date_created", 
"apply_date" ,
"loan_amt",
"period", 
"service_amt", 
"desired_product"]]

apply_status['申请结果'] = apply_status['status']
apply_status.申请结果 = apply_status.申请结果.map({
                                                "HUMAN_REFUSE":"人工拒绝",
                                                "SYS_REFUSE":"系统拒绝",
                                                "HUMAN_AGREE":"人工通过",
                                                "SYS_APPROVING":"系统审核中",
                                                "REVIEWING":"人工复核",
                                                "HUMAN_CANCEL":"人工取消",
                                                "SYS_AGREE":"系统通过",
                                                "SYS_CANCEL":"系统取消"})	
	
col_mapping={"apply_date":"申请开始时间","date_created":"申请提交时间"}
apply_status = apply_status.rename(columns=col_mapping,copy=False)

apply_status = apply_status.sort_values(by=['last_updated'],ascending=True)
apply_status = apply_status.sort_values(by=['apply_code'],ascending=False)

#==============================================================================
##审批下码
handle_code = handle_code[["apply_code","handle_code","last_updated"]]
##前期策略结果为通过和人工审核的都需进入人工复核，所以有两条审批记录，还有些异常的重复数据，先保留最新的
handle_code = handle_code.sort_values(by=['last_updated','apply_code'],ascending=[True,False]).drop_duplicates(['apply_code']) 

#==============================================================================
##来源渠道
source_channel = source_channel[["USER_CODE","来源渠道"]]
source_channel.columns = source_channel.columns.str.lower()

#==============================================================================
##放款
loan_info1 = loan_info[["apply_code","loan_date","status"]]
loan_info1['loan_date'] = loan_info1['loan_date'].astype(str)
loan_info1['loan_date'] = loan_info1['loan_date'].apply(lambda x:x[:10])
loan_info2 = loan_info1.rename(columns={"status":"放款状态","loan_date":"放款日期"},copy=False)
loan_info3 = loan_info2.sort_values(by=['apply_code'],ascending=False)

##申请-审批-放款
a=pd.merge(handle_code,loan_info3,on='apply_code',how='left')
apply_status=apply_status.combine_first(a) 

apply_status1 = apply_status.sort_values(by=['user_code','last_updated'],ascending=[True,True])

#对客户打标签,区分首次申请和最新申请
apply_status1.loc[(apply_status1.drop_duplicates(['user_code'],keep = 'first').index),"首次申请"] = "1"
apply_status1.loc[(apply_status1.drop_duplicates(['user_code'],keep = 'last').index),"最新申请"] = "1"
apply_status2 = apply_status1.fillna({"首次申请":"2"})
            
#==============================================================================

##首次放款日期
first_loan_date = loan_info[["apply_code","id_card_no","loan_date","customer_apply_time","customer_name","status"]]
first_loan_date = first_loan_date[first_loan_date["status"] == 304]
first_loan_date = first_loan_date.rename(columns={"loan_date":"first_loan_date"},copy=False)
first_loan_date = first_loan_date.drop(["status"],axis=1)
first_loan_date = first_loan_date.sort_values(by=['id_card_no','first_loan_date'],ascending=[True,True])
first_loan_date = first_loan_date.sort_values(by=['id_card_no'],ascending=[True])

##拼上user_code;
apply_user_code = df[["apply_code","user_code"]]
apply_user_code = apply_user_code.sort_values(by=['apply_code'],ascending=[True])
first_loan_date = first_loan_date.sort_values(by=['apply_code'],ascending=[True])
first_loan_date = pd.merge(first_loan_date,apply_user_code,on = "apply_code",how = "left")
first_loan_date = first_loan_date.drop(["apply_code" ,"customer_apply_time" ,"id_card_no"],axis=1)

apply_status_3 = pd.merge(apply_status2,first_loan_date,on="user_code",how = "left")
apply_status_3.loc[(apply_status_3["申请开始时间"] > apply_status_3["first_loan_date"]),"复贷申请"] = "1"

#==============================================================================

##为数据打上首次申请提交时间和最近申请提交时间
apply_sum = apply_status.groupby('user_code')['申请提交时间'].agg({'首次申请提交时间':min,'最新申请提交时间':max})
apply_sum["user_code"] = apply_sum.index  ##将索引变成列名
                       
a = pd.merge(apply_status_3,apply_sum,on="user_code",how = "left")
apply_submart = pd.merge(a,source_channel,on="user_code",how = "left")

apply_submart['申请提交月份'] = apply_submart['申请提交时间'].apply(lambda x:x[:7])
apply_submart['申请提交日期'] = apply_submart['申请提交时间'].apply(lambda x:x[:10])
apply_submart['首次申请提交月份'] = apply_submart['首次申请提交时间'].apply(lambda x:x[:7])
apply_submart['首次申请提交日期'] = apply_submart['首次申请提交时间'].apply(lambda x:x[:10])
apply_submart['最新申请提交日期'] = apply_submart['最新申请提交时间'].apply(lambda x:x[:10])

apply_submart1 = apply_submart.drop(apply_submart[(apply_submart["customer_name"] == "沙振华") | (apply_submart["customer_name"] == "沈正喆")].index,axis=0)

apply_submart1.loc[(apply_submart1['申请结果']=="人工通过") & (apply_submart1['申请结果'] == "系统通过"),"申请通过"] = "1"
apply_submart1.loc[(apply_submart1['申请结果']=="系统拒绝") & (apply_submart1['申请结果'] == "人工拒绝"),"申请拒绝"] = "1"

apply_submart1['放款日期'] = apply_submart1['放款日期'].astype(str)
apply_submart1['放款月份'] = apply_submart1['放款日期'].apply(lambda x:x[:7])
##2017年12月25号之前拒绝后再申请的标记为无效申请
apply_submart1.loc[((apply_submart1['申请提交时间']>"2016-12-25") | (apply_submart1['最新申请'] == "1") | (apply_submart1["放款日期"] != "")),"有效申请"] = "1"
  
apply_submart = apply_submart1.drop(["申请提交时间",
                                   "last_updated",
                                   "申请开始时间",
                                   "ip_area",
                                   "first_loan_date",
                                   "首次申请提交时间",
                                   "最新申请提交时间",
                                   "首次申请提交日期",
                                   "最新申请提交日期",
                                   "status",
                                   "os_type",
                                   "service_amt"],axis=1)

apply_submart.loc[(apply_submart['首次申请']=="1"),"订单类型"] = "新客户订单"
apply_submart.loc[(apply_submart['复贷申请']=="1"),"订单类型"] = "复贷客户订单"
apply_submart.loc[(apply_submart['desired_product']=="MPD10"),"订单类型"] = "极速贷订单"
apply_submart.loc[((apply_submart['首次申请']!="1") | (apply_submart['复贷申请']!="1") | (apply_submart['desired_product']!="MPD10")),"订单类型"] = "拒绝客户订单"
##或者使用下面这个方法
#apply_submart = apply_submart.fillna({"订单类型":"拒绝客户订单"})

loan_times = apply_submart[["apply_code","user_code","放款状态"]]
loan_times = loan_times [loan_times["放款状态"] == 304]

#打标签，区分首次放款客户
loan_times.loc[(loan_times.drop_duplicates(['user_code'],keep = 'first').index),"首次放款"] = "1"
loan_times = loan_times.fillna({"首次放款":"2"})
loan_times = loan_times.drop(["user_code","放款状态"],axis = 1)
apply_submart = pd.merge(apply_submart,loan_times,on = "apply_code",how = "left") 


csvfile1 = tmp_dir + '\\'+ "apply_submart.csv"
apply_submart.to_csv(csvfile1,sep=',',index=False ,encoding = 'utf-8')

