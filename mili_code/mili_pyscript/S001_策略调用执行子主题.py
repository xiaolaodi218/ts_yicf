# -*- coding: utf-8 -*-
"""
Created on Tue Jun 20 16:43:33 2017

@author: Administrator
"""

#==============================================================================
# ##策略调用执行子主题
#==============================================================================

import pandas as pd
from pandas import DataFrame
import csv
import re

tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

invoke_record1 = pd.read_csv(ten+"\\"+ "invoke_record.csv")
strategy_execution = pd.read_csv(ten +"\\"+"strategy_execution.csv") 

##策略调用

##token是用于关联设备信息的，一般是app打开的时候生成，然后在后续事件中都用同一个token，因为测试环境有些事件调用没上传phone_no，所以通过token来补

token_phone = invoke_record1[['phone_no','bai_qi_shi_token']]
token_phone = token_phone.rename(columns={"phone_no":"phone"},copy=False)
token_phone["phone"] = token_phone["phone"].astype(str)
token_phone = token_phone[(token_phone["phone"].isnull() != 1)]
#筛选bai_qi_shi_token这个字段下面的value字符串长度大于20的
token_phone = token_phone[token_phone['bai_qi_shi_token'].str.len() >20]
token_phone = token_phone.drop_duplicates(['bai_qi_shi_token'],keep = 'first')
#这个也可以使用        
#token_phone = token_phone.sort_values(by=['bai_qi_shi_token'],ascending=True).drop_duplicates(['bai_qi_shi_token']) 

invoke_record1 = pd.merge(invoke_record1,token_phone,on='bai_qi_shi_token',how = 'left')

#invoke_record1['gps_address'] = invoke_record1['gps_address'].astype(str)
#invoke_record1['GPS省份'] = invoke_record1['gps_address'].apply(lambda x:x[:3])

a = invoke_record1[invoke_record1["gps_address"].isnull() != 1]
b = invoke_record1[invoke_record1["gps_address"].isnull() == 1]

c = pd.DataFrame((re.split('区|省|市',x)[0]+re.split('(区|省|市)',x)[1] for x in a.gps_address ),index = a.index,columns = ['gps_address'])

invoke_record1 = pd.merge(c,b,on = "apply_code",how = "left")
#==============================================================================
# 	 if index(gps_address, "新疆维吾尔自治区") then GPS省份 = "新疆维吾尔自治区";
# else if index(gps_address, "广西壮族自治区") then GPS省份 = "广西壮族自治区";
# else if index(gps_address, "内蒙古自治区") then GPS省份 = "内蒙古自治区"; 
# else if index(gps_address, "西藏自治区") then GPS省份 = "西藏自治区"; 
# else if index(gps_address, "宁夏回族自治区") then GPS省份 = "宁夏回族自治区"; 
# else if index(gps_address, "澳门特别行政区") then GPS省份 = "澳门特别行政区"; 
# else GPS省份 = ksubstr(gps_address, 1, 3);
#==============================================================================

invoke_record1['invoke日期'] = invoke_record1['last_updated'].apply(lambda x:x[:10])
invoke_record1['invoke月份'] = invoke_record1['last_updated'].apply(lambda x:x[:7])

col_mapping = {"id":"invoke_record_id","status":"invoke状态"}
invoke_record1 = invoke_record1.rename(columns=col_mapping, copy=False)                  

invoke_record = invoke_record1.drop(["bai_qi_shi_token",
                                      "id_card",
                                      "ip_address",
                                      "ip_area", 
                                      "latitude",
                                      "longitude", 
                                      "name", 
                                      "tong_dun_token",
                                      #phone ,
                                      "date_created",
                                      "last_updated", 
                                      "gps_address"],axis = 1)

loan_invoke = invoke_record[invoke_record["event_type"] == "LOAN"]
hold_invoke = invoke_record[invoke_record["event_type"] == "HOLD"]
dynamic_invoke = invoke_record[invoke_record["event_type"] == "SEND_DYNAMIC"]
pay_invoke = invoke_record[invoke_record["event_type"] == "MINI_AMOUNT_PAY"]
reloan_invoke = invoke_record[invoke_record["event_type"] == "RELOAN"]
reloan_simple_invoke = invoke_record[invoke_record["event_type"] == "RELOAN_SIMPLE"]

approval = pd.concat([loan_invoke,hold_invoke,dynamic_invoke,pay_invoke,reloan_invoke,reloan_simple_invoke],axis=0)

#==============================================================================
###策略执行

strategy_execution['execut日期'] = strategy_execution['last_updated'].apply(lambda x:x[:10])
strategy_execution['execut月份'] = strategy_execution['last_updated'].apply(lambda x:x[:7])

col_mapping = {"id":"execution_id","name":"event_name","decision":"execut结果","status":"execut状态"}
strategy_execution = strategy_execution.rename(columns=col_mapping,copy=False)

strategy_execution = strategy_execution.drop(["date_created","last_updated","version"],axis=1)

bqs_execution = strategy_execution[strategy_execution["type"]=="BQS"]
td_execution = strategy_execution[strategy_execution["type"]=="TD"]
creditx_execution = strategy_execution[strategy_execution["type"]=="CREDITX"]

#==============================================================================
###提交借款申请后跑的BQS结果
loan_bqs_result = pd.merge(loan_invoke,bqs_execution,on="invoke_record_id",how = "left")
loan_bqs_result["execution_id"] = loan_bqs_result["execution_id"].astype(str)
loan_bqs_result = loan_bqs_result[(loan_bqs_result["execution_id"] != "NaN")]


bqs_engine_result_1 = loan_bqs_result[["invoke_record_id", "execut结果","event_name"]]

bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="REJECT"),"executrisk"] = "3"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="REVIEW"),"executrisk"] = "2"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="ACCEPT"),"executrisk"] = "1"
bqs_engine_result_1 = bqs_engine_result_1.fillna({"executrisk":"0"})
bqs_engine_result_1 = bqs_engine_result_1.drop(["execut结果"],axis = 1)

bqs_engine_result_2 = bqs_engine_result_1[["invoke_record_id", "executrisk"]]                        
bqs_engine_result_2 = bqs_engine_result_2.groupby('invoke_record_id')['executrisk'].agg({'risk':max})
bqs_engine_result_2["invoke_record_id"] = bqs_engine_result_2.index

bqs_engine_result_3 = bqs_engine_result_1[(bqs_engine_result_1["event_name"]=="blacklist") | (bqs_engine_result_1["event_name"]=="loan")]
bqs_engine_result_3 = bqs_engine_result_3.groupby('invoke_record_id')['executrisk'].agg({'risk_blkloan':max})
bqs_engine_result_3["invoke_record_id"] = bqs_engine_result_3.index

loan_bqs_result = loan_bqs_result.drop_duplicates(['invoke_record_id'],keep = 'first')
bqs_engine_result_2 = bqs_engine_result_2.drop_duplicates(['invoke_record_id'],keep = 'first')
bqs_engine_result_3 = bqs_engine_result_3.drop_duplicates(['invoke_record_id'],keep = 'first')

a = pd.merge(loan_bqs_result,bqs_engine_result_2,on = "invoke_record_id",how = "left")
loanBQS_submart = pd.merge(a,bqs_engine_result_3, on = "invoke_record_id",how = "left")

loanBQS_submart.loc[(loanBQS_submart['risk']=="3"),"引擎结果"] = "REJECT"
loanBQS_submart.loc[(loanBQS_submart['risk']=="2"),"引擎结果"] = "REVIEW"
loanBQS_submart.loc[(loanBQS_submart['risk']=="1"),"引擎结果"] = "ACCEPT"
loanBQS_submart.loc[(loanBQS_submart['invoke状态']=="ERROR"),"引擎结果"] = "ERROR"

loanBQS_submart.loc[(loanBQS_submart['risk_blkloan']=="3"),"名单贷款事件结果"] = "REJECT"
loanBQS_submart.loc[(loanBQS_submart['risk_blkloan']=="2"),"名单贷款事件结果"] = "REVIEW"
loanBQS_submart.loc[(loanBQS_submart['risk_blkloan']=="1"),"名单贷款事件结果"] = "ACCEPT"
loanBQS_submart.loc[(loanBQS_submart['invoke状态']=="ERROR"),"名单贷款事件结果"] = "ERROR"
                     
loanBQS_submart = loanBQS_submart.drop(["risk", "event_type", "phone_no", "type", "risk_blkloan"],axis = 1)

#==============================================================================
###提交借款申请后跑的TD结果
loan_td_result = pd.merge(loan_invoke,td_execution,on="invoke_record_id",how = "left")
loan_td_result["execution_id"] = loan_td_result["execution_id"].astype(str)
loan_td_result = loan_td_result[(loan_td_result["execution_id"] != "NaN")]

loan_td_result["引擎结果"] = loan_td_result["execut结果"]
loanTD_submart = loan_td_result.drop(["event_type","phone_no","type"],axis = 1)

#==============================================================================
##提交借款申请后跑的CREDITX结果
loan_creditx_result = pd.merge(loan_invoke,creditx_execution,on="invoke_record_id",how = "left")
loan_creditx_result["execution_id"] = loan_creditx_result["execution_id"].astype(str)
loan_creditx_result = loan_creditx_result[(loan_creditx_result["execution_id"] != "NaN")]

#==============================================================================
##氪信反欺诈和评分结果
loanCX_fraud_submart = loan_creditx_result[loan_creditx_result["event_name"]=="anti_fraud"]
loanCX_score_submart = loan_creditx_result[loan_creditx_result["event_name"]!="anti_fraud"]
                                         
creditx_engine_result_1 = loan_creditx_result[["invoke_record_id","execut结果"]]

creditx_engine_result_1.loc[(creditx_engine_result_1['execut结果']=="REJECT"),"executrisk"] = "3"
creditx_engine_result_1.loc[(creditx_engine_result_1['execut结果']=="REVIEW"),"executrisk"] = "2"
creditx_engine_result_1.loc[(creditx_engine_result_1['execut结果']=="ACCEPT"),"executrisk"] = "1"
creditx_engine_result_1 = creditx_engine_result_1.fillna({"executrisk":"0"})

creditx_engine_result_2 = creditx_engine_result_1.groupby('invoke_record_id')['executrisk'].agg({'risk':max})
creditx_engine_result_2["invoke_record_id"] = creditx_engine_result_2.index

loan_creditx_result = loan_creditx_result.drop_duplicates(['invoke_record_id'],keep = 'first')
creditx_engine_result_2 = creditx_engine_result_2.drop_duplicates(['invoke_record_id'],keep = 'first')

loanCX_submart = pd.merge(loan_creditx_result, creditx_engine_result_2,on = "invoke_record_id", how = "left" )
loanCX_submart.loc[(loanCX_submart['risk']=="3"),"引擎结果"] = "REJECT"
loanCX_submart.loc[(loanCX_submart['risk']=="2"),"引擎结果"] = "REVIEW"
loanCX_submart.loc[(loanCX_submart['risk']=="1"),"引擎结果"] = "ACCEPT"
loanCX_submart.loc[(loanCX_submart['invoke状态']=="ERROR"),"引擎结果"] = "ERROR"
loanCX_submart = loanCX_submart.drop(["risk", "event_type", "phone_no", "type"],axis = 1)

#==============================================================================
###提交借款申请后跑的系统策略结果

bqs_engine = loanBQS_submart[["invoke_record_id", "apply_code", "invoke状态", "GPS省份", "invoke日期", "invoke月份", "引擎结果", "os_type"]]
bqs_engine = bqs_engine.rename(columns={"引擎结果":"BQS引擎结果"},copy=False)

td_engine = loanTD_submart[["invoke_record_id","引擎结果", "os_type"]]
td_engine = td_engine.rename(columns={"引擎结果":"TD引擎结果"},copy = False)

creditx_engine = loanCX_submart[["invoke_record_id", "引擎结果", "os_type"]]
creditx_engine = creditx_engine.rename(columns={"引擎结果":"CREDITX引擎结果"},copy = False)

bqs_engine = bqs_engine.drop_duplicates(['invoke_record_id'],keep = 'first')
td_engine = td_engine.drop_duplicates(['invoke_record_id'],keep = 'first')
creditx_engine = creditx_engine.drop_duplicates(['invoke_record_id'],keep = 'first')

a = pd.merge(bqs_engine, td_engine,on = "invoke_record_id", how = "left" )
loan_submart = pd.merge(a, creditx_engine,on = "invoke_record_id", how = "left" )

loan_submart.loc[((loan_submart['BQS引擎结果']=="REJECT") | (loan_submart['TD引擎结果']=="REJECT") | (loan_submart['CREDITX引擎结果']=="REJECT")),"系统决策结果"] = "REJECT"
loan_submart.loc[((loan_submart['BQS引擎结果']=="REVIEW") | (loan_submart['TD引擎结果']=="REVIEW") | (loan_submart['CREDITX引擎结果']=="REVIEW")),"系统决策结果"] = "REVIEW"
loan_submart.loc[((loan_submart['BQS引擎结果']=="ACCEPT") & (loan_submart['TD引擎结果']=="ACCEPT") & ((loan_submart['CREDITX引擎结果']=="ACCEPT") | (loan_submart['CREDITX引擎结果']==""))),"系统决策结果"] = "REJECT"
loan_submart.loc[(loan_submart['invoke状态']=="ERROR"),"系统决策结果"] = "ERROR"

                 
csvfile = tmp_dir + '\\'+ "invoke_record.csv"
csvfile = tmp_dir + '\\'+ "strategy_execution.csv"
csvfile = tmp_dir + '\\'+ "loanBQS_submart.csv"
csvfile = tmp_dir + '\\'+ "loanTD_submart.csv"
csvfile = tmp_dir + '\\'+ "loanCX_submart.csv"
csvfile = tmp_dir + '\\'+ "loan_submart.csv"

invoke_record.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
strategy_execution.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
loanBQS_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
loanTD_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
loanCX_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
loan_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

#==============================================================================
###极速贷提交借款申请后跑的系统策略结果

pay_bqs_result =pd.merge(pay_invoke,bqs_execution,on="invoke_record_id",how="left")
pay_bqs_result["invoke_record_id"] = pay_bqs_result["invoke_record_id"].astype(str)
pay_bqs_result = pay_bqs_result[(pay_bqs_result["invoke_record_id"] != "NaN")]

pay_bqs_engine_result_1 = pay_bqs_result[["invoke_record_id", "execut结果"]]
pay_bqs_engine_result_1.loc[(pay_bqs_engine_result_1['execut结果']=="REJECT"),"executrisk"] = "3"
pay_bqs_engine_result_1.loc[(pay_bqs_engine_result_1['execut结果']=="REVIEW"),"executrisk"] = "2"
pay_bqs_engine_result_1.loc[(pay_bqs_engine_result_1['execut结果']=="ACCEPT"),"executrisk"] = "1"
pay_bqs_engine_result_1.loc[(pay_bqs_engine_result_1['execut结果']=="NaN"),"executrisk"] = "0"
pay_bqs_engine_result_1 = pay_bqs_engine_result_1.drop(["execut结果"],axis =1)

pay_bqs_engine_result_2 = pay_bqs_engine_result_1.groupby('invoke_record_id')['executrisk'].agg({'risk':max})

pay_bqs_result = pay_bqs_result.drop_duplicates(['invoke_record_id'],keep = 'first')
pay_bqs_engine_result_2 = pay_bqs_engine_result_2.drop_duplicates(['invoke_record_id'],keep = 'first')


payBQS_submart = pd.merge(pay_bqs_result,pay_bqs_engine_result_2,on = "invoke_record_id", how = "left" )
payBQS_submart.loc[(payBQS_submart['risk']=="3"),"引擎结果"] = "REJECT"
payBQS_submart.loc[(payBQS_submart['risk']=="2"),"引擎结果"] = "REVIEW"
payBQS_submart.loc[(payBQS_submart['risk']=="1"),"引擎结果"] = "ACCEPT"
payBQS_submart.loc[(payBQS_submart['invoke状态']=="ERROR"),"引擎结果"] = "ERROR"

payBQS_submart = payBQS_submart.drop(["risk","event_type", "phone_no", "type"],axis=1)

#==============================================================================


#==============================================================================
#RELOAN会跑BQS和TD;
#==============================================================================

##复贷提交借款申请后跑的BQS结果
reloan_bqs_result =pd.merge(reloan_invoke,bqs_execution,on="invoke_record_id",how="left")
reloan_bqs_result["invoke_record_id"] = reloan_bqs_result["invoke_record_id"].astype(str)
reloan_bqs_result = reloan_bqs_result[(pay_bqs_result["invoke_record_id"] != "NaN")]

bqs_engine_result_1 = reloan_bqs_result[["invoke_record_id", "execut结果","event_name"]]
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="REJECT"),"executrisk"] = "3"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="REVIEW"),"executrisk"] = "2"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="ACCEPT"),"executrisk"] = "1"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="NaN"),"executrisk"] = "0"
bqs_engine_result_1 = bqs_engine_result_1.drop(["execut结果"],axis =1)

bqs_engine_result_2 = bqs_engine_result_2.groupby('invoke_record_id')['executrisk'].agg({'risk':max})

reloan_bqs_result = pay_bqs_result.drop_duplicates(['invoke_record_id'],keep = 'first')
bqs_engine_result_2 = pay_bqs_engine_result_2.drop_duplicates(['invoke_record_id'],keep = 'first')


reloanBQS_submart = pd.merge(reloan_bqs_result,bqs_engine_result_2,on = "invoke_record_id", how = "left" )
reloanBQS_submart.loc[(reloanBQS_submart['risk']=="3"),"引擎结果"] = "REJECT"
reloanBQS_submart.loc[(reloanBQS_submart['risk']=="2"),"引擎结果"] = "REVIEW"
reloanBQS_submart.loc[(reloanBQS_submart['risk']=="1"),"引擎结果"] = "ACCEPT"
reloanBQS_submart.loc[(reloanBQS_submart['invoke状态']=="ERROR"),"引擎结果"] = "ERROR"

reloanBQS_submart = payBQS_submart.drop(["risk","event_type", "phone_no", "type"],axis=1)

#==============================================================================
###复贷提交借款申请后跑的TD结果;
reloan_td_result =pd.merge(reloan_invoke,td_execution,on="invoke_record_id",how="left")
reloan_td_result["invoke_record_id"] = reloan_td_result["invoke_record_id"].astype(str)
reloan_td_result = reloan_td_result[(reloan_td_result["invoke_record_id"].isnull() != 1)]

reloanTD_submart = reloanTD_submart.drop["event_type","phone_no type"]
reloanTD_submart['引擎结果'] = reloanTD_submart['execut结果']

bqs_engine = reloanBQS_submart[["invoke_record_id","apply_code invoke状态","GPS省份","invoke日期","invoke月","引擎结果","os_type"]]
bqs_engine = bqs_engine.rename(columns={"引擎结果":"BQS引擎结果"},copy = False)

td_engine = reloanTD_submart[["invoke_record_id","引擎结果","os_type"]]
td_engine = td_engine.rename(columns={"引擎结果":"TD引擎结果"},copy = False)

bqs_engine = bqs_engine.drop_duplicates(['invoke_record_id'],keep = 'first')
td_engine = td_engine.drop_duplicates(['invoke_record_id'],keep = 'first')

reloan_submart =pd.merge(bqs_engine,td_engine,on = "invoke_record_id",how = "left")

reloan_submart.loc[((reloan_submart['BQS引擎结果']=="REJECT") | (loan_submart['TD引擎结果']=="REJECT")),"系统决策结果"] = "REJECT"
reloan_submart.loc[((reloan_submart['BQS引擎结果']=="REVIEW") | (loan_submart['TD引擎结果']=="REVIEW")),"系统决策结果"] = "REVIEW"
reloan_submart.loc[((reloan_submart['BQS引擎结果']=="ACCEPT") & (loan_submart['TD引擎结果']=="ACCEPT")),"系统决策结果"] = "REJECT"
reloan_submart.loc[(reloan_submart['invoke状态']=="ERROR"),"系统决策结果"] = "ERROR"


#==============================================================================
#RELOAN_SIMPLE会跑BQS;
#==============================================================================
###复贷2提交借款申请后跑的BQS结果;

reloan_simple_bqs_result =pd.merge(reloan_simple_invoke,bqs_execution,on="invoke_record_id",how="left")
reloan_simple_bqs_result["invoke_record_id"] = reloan_simple_bqs_result["invoke_record_id"].astype(str)
reloan_simple_bqs_result = reloan_simple_bqs_result[(reloan_simple_bqs_result["invoke_record_id"] != "NaN")]

bqs_engine_result_1 = reloan_simple_bqs_result[["invoke_record_id", "execut结果","event_name"]]
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="REJECT"),"executrisk"] = "3"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="REVIEW"),"executrisk"] = "2"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="ACCEPT"),"executrisk"] = "1"
bqs_engine_result_1.loc[(bqs_engine_result_1['execut结果']=="NaN"),"executrisk"] = "0"
bqs_engine_result_1 = bqs_engine_result_1.drop(["execut结果"],axis =1)

bqs_engine_result_2 = bqs_engine_result_2.groupby('invoke_record_id')['executrisk'].agg({'risk':max})

reloan_simple_bqs_result = reloan_simple_bqs_result.drop_duplicates(['invoke_record_id'],keep = 'first')
bqs_engine_result_2 = bqs_engine_result_2.drop_duplicates(['invoke_record_id'],keep = 'first')

reloansimpleBQS_submart = pd.merge(reloan_simple_bqs_result,bqs_engine_result_2,on = "invoke_record_id", how = "left" )
reloansimpleBQS_submart.loc[(reloansimpleBQS_submart['risk']=="3"),"引擎结果"] = "REJECT"
reloansimpleBQS_submart.loc[(reloansimpleBQS_submart['risk']=="2"),"引擎结果"] = "REVIEW"
reloansimpleBQS_submart.loc[(reloansimpleBQS_submart['risk']=="1"),"引擎结果"] = "ACCEPT"
reloansimpleBQS_submart.loc[(reloansimpleBQS_submart['invoke状态']=="ERROR"),"引擎结果"] = "ERROR"

reloansimpleBQS_submart = reloansimpleBQS_submart.drop(["risk","event_type", "phone_no", "type"],axis=1)




csvfile = tmp_dir + '\\'+ "invoke_record.csv"
invoke_record.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "strategy_execution.csv"
strategy_execution.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "loanBQS_submart.csv"
loanBQS_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "loanTD_submart.csv"
loanTD_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "loanCX_fraud_submart.csv"
loanCX_fraud_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "loanCX_score_submart.csv"
loanCX_score_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "loanCX_submart.csv"
loanCX_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "loan_submart.csv"
loan_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "payBQS_submart.csv"
payBQS_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "reloanTD_submart.csv"
reloanBQS_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "reloanTD_submart.csv"
reloanTD_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

csvfile = tmp_dir + '\\'+ "reloansimpleBQS_submart.csv"
reloansimpleBQS_submart.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')



