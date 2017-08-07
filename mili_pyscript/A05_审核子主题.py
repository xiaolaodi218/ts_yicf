# -*- coding: utf-8 -*-
"""
Created on Mon Jun 19 18:13:27 2017

@author: Administrator
"""

#==============================================================================
# 		审核子主题
#==============================================================================

import pandas as pd
from pandas import DataFrame
import csv

##申请审批状态
tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

approval_info = pd.read_csv(ten +"\\"+ "approval_info.csv")
circular = pd.read_csv(tem +"\\"+ "circular.csv")
refuse_map = pd.read_csv(tmp_dir +"\\"+"refuse_map.csv")

##处理日期格式和长度
approval_info['handle_time'] = approval_info['handle_time'].astype(str)
approval_info['date_created'] = approval_info['date_created'].astype(str)

approval_info['审核处理月份'] = approval_info['handle_time'].apply(lambda x:x[:7])
approval_info['审核处理日期'] = approval_info['handle_time'].apply(lambda x:x[:10])
approval_info['审核开始月份'] = approval_info['date_created'].apply(lambda x:x[:7])
approval_info['审核开始日期'] = approval_info['date_created'].apply(lambda x:x[:10])

col_mapping={"date_created":"审核开始时间",
            "last_updated":"审核更新时间",
            "handle_time":"审核处理时间",
            "remark":"审核备注"}
approval_info = approval_info.rename(columns=col_mapping,copy=False)
approval_info = approval_info.drop(['id','handler_id'],axis=1)

##系统拒绝
sys_refuse = approval_info[(approval_info["handle_status"] == "COMPLETE") & 
                           (approval_info["handle_type"] == "SYSTEM") &
                           (approval_info["handle_result"] == "REJECT")]
##系统通过
sys_agree = approval_info[(approval_info["handle_status"] == "COMPLETE") & 
                          (approval_info["handle_type"] == "SYSTEM") &
                          (approval_info["handle_result"] == "ACCEPT")]
##人工通过
human_agree = approval_info[(approval_info["handle_status"] == "COMPLETE") & 
                            (approval_info["handle_type"] == "HUMAN") & 
                            (approval_info["handle_result"] == "ACCEPT")]
##人工拒绝
human_refuse = approval_info[(approval_info["handle_status"] == "COMPLETE") &
                             (approval_info["handle_type"] == "HUMAN") & 
                             (approval_info["handle_result"] == "REJECT")]

##系统审核中
sys_init = approval_info[(approval_info["handle_status"] == "INIT") & 
                         (approval_info["handle_type"] == "SYSTEM")]
##人工审核中
human_init = approval_info[(approval_info["handle_status"] == "INIT") &
                           (approval_info["handle_type"] == "HUMAN")]
##人工取消
human_cancel = approval_info[(approval_info["handle_status"] == "COMPLETE") & 
                             (approval_info["handle_type"] == "HUMAN") & 
                             (approval_info["handle_result"] == "CANCEL")]
##系统取消
sys_cancel = approval_info[(approval_info["handle_status"] == "COMPLETE") &
                           (approval_info["handle_type"] == "SYSTEM") &
                           (approval_info["handle_result"] == "CANCEL")]

approval = pd.concat([sys_refuse,sys_refuse,human_agree,human_refuse,sys_init,human_init,human_cancel,sys_cancel],axis=0)

col_mapping={"refuse_code":"handle_code"}
refuse_map = refuse_map.rename(columns=col_mapping,copy=False)
approval = pd.merge (approval,refuse_map, on ="handle_code",how = "left")

##有一些异常的单子如PL148202792530602600007429，同时有系统和人工拒绝的结果
approval = approval.sort_values(by=['apply_code','审核更新时间'],ascending=[True,True])
approval = approval.sort_values(by=['apply_code'],ascending=False)

approval.loc[(approval['handle_type']=="SYSTEM") & (approval['handle_result'] == "REJECT"),"审批结果"] = "系统拒绝"
approval.loc[(approval['handle_type']=="SYSTEM") & (approval['handle_result'] == "ACCEPT"),"审批结果"] = "系统通过"
approval.loc[(approval['handle_type']=="SYSTEM") & (approval['handle_result'] == "CANCEL"),"审批结果"] = "系统取消"
##银策略筛选出来人工通过的订单
approval.loc[(approval['handle_type']=="HUMAN") & (approval['handle_result'] == "REJECT") & (approval["handle_code"] == ""),"审批结果"] = "人工通过"
approval.loc[(approval['handle_type']=="HUMAN") & (approval['handle_result'] == "REJECT"),"审批结果"] = "人工拒绝"
approval.loc[(approval['handle_type']=="HUMAN") & (approval['handle_result'] == "ACCEPT"),"审批结果"] = "人工通过"
approval.loc[(approval['handle_type']=="HUMAN") & (approval['handle_result'] == "CANCEL"),"审批结果"] = "人工取消"           
approval.loc[(approval['handle_type']=="SYSTEM") & (approval['handle_result'] == "NaN"),"审批结果"] = "系统审核中"
approval.loc[(approval['handle_type']=="HUMAN") & (approval['handle_result'] == "NaN"),"审批结果"] = "人工复核中"
                        
approval_submart = approval.drop(["审核开始时间","审核更新时间","审核处理时间","审核备注"],axis=1)

##银策略筛出来被人工通过的客户*/
circular = circular[["NAME","USER_CODE","CREATED_TIME"]]
silver_pass_user = circular[circular["NAME"] =="马上拿钱"]

##银策略筛出来被人工通过的订单
#==============================================================================
# silver_pass_apply = approval_info[(approval_info['handle_type']=="HUMAN") & 
#                                   (approval_info['handle_result']=="REJECT") &
#                                   (approval_info['handle_code']=="")]
#==============================================================================

csvfile1 = tmp_dir + '\\'+ "approval_submart.csv"
csvfile2 = tmp_dir + '\\'+ "silver_pass_user.csv"

approval_submart.to_csv(csvfile1,sep=',',index=False ,encoding = 'utf-8')
silver_pass_user.to_csv(csvfile2,sep=',',index=False ,encoding = 'utf-8')

