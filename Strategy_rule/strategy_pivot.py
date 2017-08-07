# -*- coding: utf-8 -*-
"""
Created on Sat Mar 25 16:08:16 2017

@author: lenovo
"""
import time
start =time.clock()

import pandas as pd
from pandas.io.excel import ExcelWriter

filedir = r"F:\celueji\sas_csv"

writer = ExcelWriter(filedir + '\\' + 'StrategyReport.xlsx')


#策略漏斗
#==============================================================================
# 
def strategy_funnel_pivot(filename, stcol):
    filepath = filedir + '\\' + filename + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    df[u'漏斗节点']=df[u'漏斗节点'].astype("category")
    if filename == 'reloanfunnel_submart':
        tn = [u'RELOAN策略漏斗']
        df[u'漏斗节点'].cat.set_categories(
            [u'1.申请', u'2.BQS拒绝', u'3.BQSTD拒绝', u'4.BQSTD人脸拒绝'],
                inplace=True)
    elif filename == 'reloansimplefunnel_submart':
        tn = [u'RELOAN_SIMPLE策略漏斗']
        df[u'漏斗节点'].cat.set_categories(
            [u'1.申请', u'2.BQS拒绝', u'3.BQS人脸拒绝'],
                inplace=True)
    elif filename == 'loanfunnel_submart':
        tn = [u'LOAN漏斗']
        df[u'漏斗节点'].cat.set_categories(
            [u'1.申请', u'2.BQS贷拒', u'3.BQS贷CX拒', u'4.BQS贷CX决拒',
             u'5.BQS贷CX决TD拒',u'6.BQS贷CX决TD脸拒'],
        inplace=True)                    
 
    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df[df[u'invoke状态'] == 'FINISHED'],
                           index=[u'invoke月份'], 
                            values=['apply_code'], 
                            columns=[u'漏斗节点'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df[(df[u'invoke状态'] == 'FINISHED') &
                                    (df[u'invoke月份'] == 201707)],
                           index=[u'invoke日期'], 
                            values=['apply_code'], 
                            columns=[u'漏斗节点'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,u'Strategy﻿策略漏斗',header=False,
                        index=False,startcol=stcol)
    table_month.to_excel(writer,u'Strategy﻿策略漏斗',startrow=2,startcol=stcol)
    table_day.to_excel(writer,u'Strategy﻿策略漏斗',startrow=20,startcol=stcol)
strategy_funnel_pivot('reloanfunnel_submart', 0)
strategy_funnel_pivot('reloansimplefunnel_submart', 7)
strategy_funnel_pivot('loanfunnel_submart', 13)

#==============================================================================
#冠军_A策略漏斗
def strategy_funnel_pivot(filename, stcol):
    filepath = filedir + '\\' + filename + '.csv'
    df1 = pd.read_csv(filepath,encoding='utf-8')
    df1 = df1[df1["loc_abmoduleflag"]=="A"]
    df1 = df1[df1["订单类型"]=="新客户订单"]
    df1[u'漏斗节点']=df1[u'漏斗节点'].astype("category")     
    tn = [u'冠军_A策略漏斗']
    df1[u'漏斗节点'].cat.set_categories(
    [u'1.申请', u'2.BQS贷拒', u'3.BQS贷CX拒', u'4.BQS贷CX决拒',
     u'5.BQS贷CX决TD拒',u'6.BQS贷CX决TD脸拒'],inplace=True)                       
 
    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df1[df1[u'invoke状态'] == 'FINISHED'],
                           index=[u'invoke月份'], 
                            values=['apply_code'], 
                            columns=[u'漏斗节点'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df1[(df1[u'invoke状态'] == 'FINISHED') &
                                    (df1[u'invoke月份'] == 201707)],
                           index=[u'invoke日期'], 
                            values=['apply_code'], 
                            columns=[u'漏斗节点'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,u'Strategy﻿策略漏斗',header=False,
                        index=False,startcol=stcol)
    table_month.to_excel(writer,u'Strategy﻿策略漏斗',startrow=2,startcol=stcol)
    table_day.to_excel(writer,u'Strategy﻿策略漏斗',startrow=20,startcol=stcol)
strategy_funnel_pivot('loanfunnel_submart', 22)

#==============================================================================
#挑战者_B策略漏斗
def strategy_funnel_pivot(filename, stcol):
    filepath = filedir + '\\' + filename + '.csv'
    df2 = pd.read_csv(filepath,encoding='utf-8')    
    df2[u'漏斗节点']=df2[u'漏斗节点'].astype("category")
    df2 = df2[df2["loc_abmoduleflag"]=="B"]
    df2 = df2[df2["订单类型"]=="新客户订单"]      
    tn = [u'挑战者_B策略漏斗']
    df2[u'漏斗节点'].cat.set_categories(
      [u'1.申请', u'2.BQS贷拒', u'3.BQS贷CX拒', u'4.BQS贷CX决拒',
       u'5.BQS贷CX决TD拒',u'6.BQS贷CX决TD脸拒'],inplace=True)                   
 
    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df2[df2[u'invoke状态'] == 'FINISHED'],
                           index=[u'invoke月份'], 
                            values=['apply_code'], 
                            columns=[u'漏斗节点'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df2[(df2[u'invoke状态'] == 'FINISHED') &
                                    (df2[u'invoke月份'] == 201707)],
                           index=[u'invoke日期'], 
                            values=['apply_code'], 
                            columns=[u'漏斗节点'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,u'Strategy﻿策略漏斗',header=False,
                        index=False,startcol=stcol)
    table_month.to_excel(writer,u'Strategy﻿策略漏斗',startrow=2,startcol=stcol)
    table_day.to_excel(writer,u'Strategy﻿策略漏斗',startrow=20,startcol=stcol)
strategy_funnel_pivot('loanfunnel_submart', 31)
#==============================================================================

#事件结果
def strategy_pivot(filename, sheetname, eventname, applytype):
    filepath = filedir + '\\' + filename + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    df[u'execut状态']=df[u'execut状态'].astype("category")
    df[u'execut状态'].cat.set_categories(["ABANDON", "WAITING", "ERROR", "FINISHED"],
                                        inplace=True)
    df[u'execut结果']=df[u'execut结果'].astype("category")
    df[u'execut结果'].cat.set_categories(["REJECT", "REVIEW", "ACCEPT"],
                                        inplace=True)
    stcol = 0    
    for e in eventname:
        if e == 'custreloan':
            tn1 = [applytype + u'BQS复贷事件执行状态']
            tn2 = [applytype + u'BQS复贷事件执行结果']
        elif e == 'faceRecognition':
            tn1 = [applytype + u'BQS人脸识别事件执行状态']
            tn2 = [applytype + u'BQS人脸识别事件执行结果']
        elif e == 'custdecision':
            tn1 = [applytype + u'BQS决策事件执行状态']
            tn2 = [applytype + u'BQS决策事件执行结果']    
        elif e == 'acquire':
            tn1 = [applytype + u'BQS收单事件执行状态']
            tn2 = [applytype + u'BQS收单事件执行结果']
        elif e == 'blacklist':
            tn1 = [applytype + u'BQS名单比对事件执行状态']
            tn2 = [applytype + u'BQS名单比对事件执行结果']
        elif e == 'loan':
            tn1 = [applytype + u'BQS贷款事件执行状态']
            tn2 = [applytype + u'BQS贷款事件执行结果']            
        elif e == 'invitation':
            tn1 = [applytype + u'BQS邀请事件执行状态']
            tn2 = [applytype + u'BQS邀请事件执行结果']
        elif e == 'anti_fraud':
            tn1 = [applytype + u'CX反欺诈事件执行状态']
            tn2 = [applytype + u'CX反欺诈事件执行结果']                        
        else:
            tn1 = [applytype + u'TD事件执行状态']
            tn2 = [applytype + u'TD事件执行结果']

        table_name = pd.DataFrame(tn1)
        table_month = pd.pivot_table(df[(df.event_name == e) &
                                        (df[u'订单类型'] == applytype)],
                               index=[u'execut月份'], 
                                values=['apply_code'], 
                                columns=[u'execut状态'],
                                aggfunc=len,
                                fill_value=0,
                                margins=True)
        table_day = pd.pivot_table(df[(df.event_name == e) &
                                    (df[u'订单类型'] == applytype) &
                                    (df[u'execut月份'] == 201707)],
                               index=[u'execut日期'], 
                                values=['apply_code'], 
                                columns=[u'execut状态'],
                                aggfunc=len,
                                fill_value=0,
                                margins=True)                                
        table_name.to_excel(writer,sheetname,header=False,
                            index=False,startcol=stcol)
        table_month.to_excel(writer,sheetname,startrow=2,startcol=stcol)
        table_day.to_excel(writer,sheetname,startrow=20,startcol=stcol)
        stcol = stcol + 10
        
        table_name = pd.DataFrame(tn2)
        table_month = pd.pivot_table(df[(df.event_name == e) & 
                                    (df[u'订单类型'] == applytype) &
                                    (df[u'execut状态'] == 'FINISHED')],
                               index=[u'execut月份'], 
                                values=['apply_code'], 
                                columns=[u'execut结果'],
                                aggfunc=len,
                                fill_value=0,
                                margins=True)
        table_day = pd.pivot_table(df[(df.event_name == e) & 
                                    (df[u'订单类型'] == applytype) &
                                    (df[u'execut状态'] == 'FINISHED') &
                                    (df[u'execut月份'] == 201707)],
                               index=[u'execut日期'], 
                                values=['apply_code'], 
                                columns=[u'execut结果'],
                                aggfunc=len,
                                fill_value=0,
                                margins=True)                                
        table_name.to_excel(writer,sheetname,header=False,
                            index=False,startcol=stcol)
        table_month.to_excel(writer,sheetname,startrow=2,startcol=stcol)
        table_day.to_excel(writer,sheetname,startrow=20,startcol=stcol)     
        stcol = stcol + 10                    
        
strategy_pivot('reloanbqs_submart', u'RELOAN_BQS策略集',
               ['custreloan', 'faceRecognition'], u'复贷客户订单')
strategy_pivot('reloantd_submart', u'RELOAN_TD策略集',
               ['td'], u'复贷客户订单')               
strategy_pivot('reloansimplebqs_submart', u'RELOAN_SIMPLE_BQS策略集',
               ['custreloan', 'faceRecognition'], u'复贷客户订单')               
strategy_pivot('loanbqs_submart', u'LOAN_BQS策略集',
            ['acquire', 'blacklist', 'custdecision','loan','faceRecognition'],u'新客户订单')
strategy_pivot('loantd_submart', u'LOAN_TD策略集', ['td'], u'新客户订单')
strategy_pivot('loancx_submart', u'LOAN_CX策略集',['anti_fraud'], u'新客户订单')
        
writer.save() 

end = time.clock()
print('Running time: %s Seconds'%(end-start))
