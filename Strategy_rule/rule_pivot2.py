# -*- coding: utf-8 -*-
"""
Created on Sat Mar 25 16:08:16 2017

@author: DATA

"""
import time
start =time.clock()

import pandas as pd
from pandas.io.excel import ExcelWriter

filedir = r"F:\celueji\sas_csv"

writer = ExcelWriter(filedir + '\\' + 'RuleReport.xlsx')

def rule_pivot(filename1, filename2, applytype, eventname):
   
    filepath = filedir + '\\' + filename2 + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    df[u'rule_decision']=df[u'rule_decision'].astype("category")
    df[u'rule_decision'].cat.set_categories(["Reject", "Review", "Accept"],
                                        inplace=True)
    df[u'hit_rule_date']=df[u'规则命中日期']                          
    df[u'hit_rule_date']=df[u'hit_rule_date'].astype("category")
    df[u'hit_rule_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
                                     
    if filename2 == 'bqsrule_jbgz_submart':
        sheetname = applytype + u'基本规则'
        tn = [applytype + u'BQS基本规则策略规则命中量']                                    
    elif filename2 == 'bqsrule_fdzr_submart':
        sheetname = applytype + u'复贷准入'
        tn = [applytype + u'BQS复贷准入策略规则命中量']
    elif filename2 == 'bqsrule_fdjbgz_submart':
        sheetname = applytype + u'复贷基本规则'
        tn = [applytype + u'BQS复贷基本规则策略规则命中量']  
    elif filename2 == 'bqsrule_fsyys_submart':
        sheetname = applytype + u'FSYYS规则'
        tn = [applytype + u'BQSFSYYS策略规则命中量']
    elif filename2 == 'bqsrule_fsds_submart':
        sheetname = applytype + u'FSDS规则'
        tn = [applytype + u'BQSFSDS策略规则命中量']
    elif filename2 == 'bqsrule_glgz_submart':
        sheetname = applytype + u'关联规则'
        tn = [applytype + u'BQS关联规则策略规则命中量']                
    elif filename2 == 'bqsrule_mddh_submart':
        sheetname = applytype + u'通过规则'
        tn = [applytype + u'BQS通过策略规则命中量']
    elif filename2 == 'bqsrule_submart':
        sheetname = applytype + u'白骑士规则'
        tn = [applytype + u'BQS规则命中量']
    elif filename2 == 'tdrule_submart':
        sheetname = applytype + u'同盾规则'
        tn = [applytype + u'同盾规则命中量']
    else:
        sheetname = applytype + u'氪信规则'
        tn = [applytype + u'氪信规则命中量']         

    if filename1 == u'reloanbqs_submart':
        eventtype = 'RELOAN'
    elif filename1 == u'reloansimplebqs_submart':
        eventtype = 'RELOAN_SIMPLE'
        applytype = u'复贷客户订单'
    elif filename1 == u'reloantd_submart':
        eventtype = 'RELOAN'
    else:
        eventtype = 'LOAN'          

    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df[(df.event_name == eventname) &
                                    (df.event_type == eventtype) &
                                    (df[u'订单类型'] == applytype)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'规则命中月份'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df[(df.event_name == eventname) &
                                (df.event_type == eventtype) &
                                (df[u'订单类型'] == applytype) &
                                (df[u'规则命中月份'] == 201707)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'hit_rule_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,sheetname,header=False,index=False)
    table_month.to_excel(writer,sheetname,startrow=3)
    table_day.to_excel(writer,sheetname,startrow=2000)

    
    filepath1 = filedir + '\\' + filename1 + '.csv'
    df1 = pd.read_csv(filepath1,encoding='utf-8')
    df1[u'execut_date']=df1[u'execut日期']
    df1[u'execut_date']=df1[u'execut_date'].astype("category")
    df1[u'execut_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    df[u'规则命中日期'] =df[u'规则命中日期'].astype(str)
    table1_month = pd.pivot_table(df1[(df1.event_name == eventname) &
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut月份'],
                            aggfunc=len,
                            fill_value=0)
    table1_day = pd.pivot_table(df1[(df1.event_name == eventname) & 
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'execut月份'] == 201707) &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table1_month.to_excel(writer,sheetname,startrow=1,startcol=1)
    table1_day.to_excel(writer,sheetname,startrow=1998,startcol=1)
    
#贷款事件的规则
#total
rule_pivot('reloanbqs_submart', 'bqsrule_submart', u'复贷客户订单', 'custreloan')
rule_pivot('reloansimplebqs_submart', 'bqsrule_submart', u'复贷2客户订单', 'custreloan')
rule_pivot('loanbqs_submart', 'bqsrule_submart', u'新客户订单', 'loan')
#复贷
rule_pivot('reloanbqs_submart', 'bqsrule_fdzr_submart', u'复贷客户订单', 'custreloan')
rule_pivot('reloanbqs_submart', 'bqsrule_fdjbgz_submart', u'复贷客户订单', 'custreloan')
rule_pivot('reloanbqs_submart', 'bqsrule_fsyys_submart', u'复贷客户订单', 'custreloan')
rule_pivot('reloanbqs_submart', 'bqsrule_fsds_submart', u'复贷客户订单', 'custreloan')
rule_pivot('reloanbqs_submart', 'bqsrule_glgz_submart', u'复贷客户订单', 'custreloan')
rule_pivot('reloantd_submart', 'tdrule_submart', u'复贷客户订单', 'td')
#复贷2
rule_pivot('reloansimplebqs_submart', 'bqsrule_fdzr_submart', u'复贷2客户订单', 'custreloan')
rule_pivot('reloansimplebqs_submart', 'bqsrule_fdjbgz_submart', u'复贷2客户订单', 'custreloan')
rule_pivot('reloansimplebqs_submart', 'bqsrule_fsyys_submart', u'复贷2客户订单', 'custreloan')
rule_pivot('reloansimplebqs_submart', 'bqsrule_fsds_submart', u'复贷2客户订单', 'custreloan')
rule_pivot('reloansimplebqs_submart', 'bqsrule_glgz_submart', u'复贷2客户订单', 'custreloan')  
#新客户     
rule_pivot('loanbqs_submart', 'bqsrule_fsds_submart', u'新客户订单', 'loan')
rule_pivot('loanbqs_submart', 'bqsrule_glgz_submart', u'新客户订单', 'loan')
rule_pivot('loanbqs_submart', 'bqsrule_mddh_submart', u'新客户订单', 'loan')
rule_pivot('cx_anti_fraud', 'cxrule_submart', u'新客户订单', 'cx')
rule_pivot('loantd_submart', 'tdrule_submart', u'新客户订单', 'td')

writer.save() 

#==============================================================================
#==============================================================================
#贷款事件 JBGZ ,FSYYS ——冠军

import pandas as pd
from pandas.io.excel import ExcelWriter

filedir = r"F:\celueji\sas_csv"

writer = ExcelWriter(filedir + '\\' + 'RuleReport_a.xlsx')

def rule_pivot(filename1, filename2, applytype, eventname):
   
    filepath = filedir + '\\' + filename2 + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    df = df[df["loc_abmoduleflag"]=="A"]
    df[u'rule_decision']=df[u'rule_decision'].astype("category")
    df[u'rule_decision'].cat.set_categories(["Reject", "Review", "Accept"],
                                        inplace=True)
    df[u'hit_rule_date']=df[u'规则命中日期']                          
    df[u'hit_rule_date']=df[u'hit_rule_date'].astype("category")
    df[u'hit_rule_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    if filename2 == 'bqsrule_jbgz_submart':
        sheetname = applytype + u'基本规则_冠军(loan)'
        tn = [applytype + u'BQS基本规则策略规则_冠军命中量(贷款事件)']                                                          
    elif filename2 == 'bqsrule_fsyys_submart':
        sheetname = applytype + u'FSYYS规则_冠军(loan)'
        tn = [applytype + u'BQSFSYYS策略规则_冠军命中量(贷款事件)']
    
    if filename1 == u'reloanbqs_submart':
        eventtype = 'RELOAN'
    elif filename1 == u'reloansimplebqs_submart':
        eventtype = 'RELOAN_SIMPLE'
        applytype = u'复贷客户订单'
    elif filename1 == u'reloantd_submart':
        eventtype = 'RELOAN'
    else:
        eventtype = 'LOAN'          

    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df[(df.event_name == eventname) &
                                    (df.event_type == eventtype) &
                                    (df[u'订单类型'] == applytype)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'规则命中月份'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df[(df.event_name == eventname) &
                                (df.event_type == eventtype) &
                                (df[u'订单类型'] == applytype) &
                                (df[u'规则命中月份'] == 201707)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'hit_rule_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,sheetname,header=False,index=False)
    table_month.to_excel(writer,sheetname,startrow=3)
    table_day.to_excel(writer,sheetname,startrow=2000)
    
    filepath1 = filedir + '\\' + filename1 + '.csv'
    df1 = pd.read_csv(filepath1,encoding='utf-8')
    df1 = df1[df1["loc_abmoduleflag"]=="A"]
    df1[u'execut_date']=df1[u'execut日期']
    df1[u'execut_date']=df1[u'execut_date'].astype("category")
    df1[u'execut_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    table1_month = pd.pivot_table(df1[(df1.event_name == eventname) &
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut月份'],
                            aggfunc=len,
                            fill_value=0)
    table1_day = pd.pivot_table(df1[(df1.event_name == eventname) & 
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'execut月份'] == 201707) &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table1_month.to_excel(writer,sheetname,startrow=1,startcol=1)
    table1_day.to_excel(writer,sheetname,startrow=1998,startcol=1)

rule_pivot('loanbqs_submart', 'bqsrule_jbgz_submart', u'新客户订单', 'loan')    
rule_pivot('loanbqs_submart', 'bqsrule_fsyys_submart', u'新客户订单', 'loan')
writer.save() 

#==============================================================================
#贷款事件 JBGZ_B ,FSYYS_B —— 挑战者
import pandas as pd
from pandas.io.excel import ExcelWriter

filedir = r"F:\celueji\sas_csv"

writer = ExcelWriter(filedir + '\\' + 'RuleReport_b.xlsx')

def rule_pivot(filename1, filename2, applytype, eventname):
   
    filepath = filedir + '\\' + filename2 + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    #其实bqsrule_jbgz_b_submart和bqsrule_fsyys_b_submart这个文件只含B的数据
    df = df[df["loc_abmoduleflag"]=="B"]  
    df[u'rule_decision']=df[u'rule_decision'].astype("category")
    df[u'rule_decision'].cat.set_categories(["Reject", "Review", "Accept"],
                                        inplace=True)
    df[u'hit_rule_date']=df[u'规则命中日期']                          
    df[u'hit_rule_date']=df[u'hit_rule_date'].astype("category")
    df[u'hit_rule_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    
    if filename2 == 'bqsrule_jbgz_b_submart':
        sheetname = applytype + u'基本规则_挑战者(loan)'
        tn = [applytype + u'BQS基本规则策略规则命中量(贷款事件)']                                                              
    elif filename2 == 'bqsrule_fsyys_b_submart':
        sheetname = applytype + u'FSYYS_B规则(loan)'
        tn = [applytype + u'BQSFSYYS_B策略规则命中量(贷款事件)']

    if filename1 == u'reloanbqs_submart':
        eventtype = 'RELOAN'
    elif filename1 == u'reloansimplebqs_submart':
        eventtype = 'RELOAN_SIMPLE'
        applytype = u'复贷客户订单'
    elif filename1 == u'reloantd_submart':
        eventtype = 'RELOAN'
    else:
        eventtype = 'LOAN'          

    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df[(df.event_name == eventname) &
                                    (df.event_type == eventtype) &
                                    (df[u'订单类型'] == applytype)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'规则命中月份'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df[(df.event_name == eventname) &
                                (df.event_type == eventtype) &
                                (df[u'订单类型'] == applytype) &
                                (df[u'规则命中月份'] == 201707)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'hit_rule_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,sheetname,header=False,index=False)
    table_month.to_excel(writer,sheetname,startrow=3)
    table_day.to_excel(writer,sheetname,startrow=2000)
    
    filepath1 = filedir + '\\' + filename1 + '.csv'
    df1 = pd.read_csv(filepath1,encoding='utf-8')
    df1 = df1[df1["loc_abmoduleflag"]=="B"]
    df1[u'execut_date']=df1[u'execut日期']
    df1[u'execut_date']=df1[u'execut_date'].astype("category")
    df1[u'execut_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    table1_month = pd.pivot_table(df1[(df1.event_name == eventname) &
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut月份'],
                            aggfunc=len,
                            fill_value=0)
    table1_day = pd.pivot_table(df1[(df1.event_name == eventname) & 
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'execut月份'] == 201707) &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table1_month.to_excel(writer,sheetname,startrow=1,startcol=1)
    table1_day.to_excel(writer,sheetname,startrow=1998,startcol=1)

rule_pivot('loanbqs_submart', 'bqsrule_jbgz_b_submart', u'新客户订单', 'loan')        
rule_pivot('loanbqs_submart', 'bqsrule_fsyys_b_submart', u'新客户订单', 'loan')
writer.save() 


#==============================================================================
#决策事件
#==============================================================================
##基本规则
writer = ExcelWriter(filedir + '\\' + 'RuleReport1_a.xlsx')

def rule_pivot(filename1, filename2, applytype, eventname):
   
    filepath = filedir + '\\' + filename2 + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    df[u'rule_decision']=df[u'rule_decision'].astype("category")
    df[u'rule_decision'].cat.set_categories(["Reject", "Review", "Accept"],
                                        inplace=True)
    df[u'hit_rule_date']=df[u'规则命中日期']                          
    df[u'hit_rule_date']=df[u'hit_rule_date'].astype("category")
    df[u'hit_rule_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
                                                                      
    if filename2 == 'bqsrule_jbgz_submart':
        sheetname = applytype + u'基本规则(decision)'
        tn = [applytype + u'BQS基本规则策略规则命中量(决策事件)']      
      
    if filename1 == u'loanbqs_submart':
        eventtype = 'LOAN'          

    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df[(df.event_name == eventname) &
                                    (df.event_type == eventtype) &
                                    (df[u'订单类型'] == applytype)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'规则命中月份'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df[(df.event_name == eventname) &
                                (df.event_type == eventtype) &
                                (df[u'订单类型'] == applytype) &
                                (df[u'规则命中月份'] == 201707)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'hit_rule_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,sheetname,header=False,index=False)
    table_month.to_excel(writer,sheetname,startrow=3)
    table_day.to_excel(writer,sheetname,startrow=2000)

    
    filepath1 = filedir + '\\' + filename1 + '.csv'
    df1 = pd.read_csv(filepath1,encoding='utf-8')
    df1[u'execut_date']=df1[u'execut日期']
    df1[u'execut_date']=df1[u'execut_date'].astype("category")
    df1[u'execut_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    table1_month = pd.pivot_table(df1[(df1.event_name == eventname) &
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut月份'],
                            aggfunc=len,
                            fill_value=0)
    table1_day = pd.pivot_table(df1[(df1.event_name == eventname) & 
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'execut月份'] == 201707) &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table1_month.to_excel(writer,sheetname,startrow=1,startcol=1)
    table1_day.to_excel(writer,sheetname,startrow=1998,startcol=1)
    
#决策事件
rule_pivot('loanbqs_submart', 'bqsrule_jbgz_submart', u'新客户订单', 'custdecision')

writer.save() 

#==============================================================================
#决策事件
#FSYYS_挑战者
writer = ExcelWriter(filedir + '\\' + 'RuleReport1_b.xlsx')

def rule_pivot(filename1, filename2, applytype, eventname):
   
    filepath = filedir + '\\' + filename2 + '.csv'
    df = pd.read_csv(filepath,encoding='utf-8')
    df = df[df["loc_abmoduleflag"]=="B"]  
    df[u'rule_decision']=df[u'rule_decision'].astype("category")
    df[u'rule_decision'].cat.set_categories(["Reject", "Review", "Accept"],
                                        inplace=True)
    df[u'hit_rule_date']=df[u'规则命中日期']                          
    df[u'hit_rule_date']=df[u'hit_rule_date'].astype("category")
    df[u'hit_rule_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
                                                                      
    
    if filename2 == 'bqsrule_fsyys_b_submart':
        sheetname = applytype + u'FSYYS_B规则_挑战者(decision)'
        tn = [applytype + u'BQSFSYYS_B则命中量_挑战者(决策事件)']          
      

    if filename1 == u'reloanbqs_submart':
        eventtype = 'RELOAN'
    elif filename1 == u'reloansimplebqs_submart':
        eventtype = 'RELOAN_SIMPLE'
        applytype = u'复贷客户订单'
    elif filename1 == u'reloantd_submart':
        eventtype = 'RELOAN'
    else:
        eventtype = 'LOAN'          

    table_name = pd.DataFrame(tn)
    table_month = pd.pivot_table(df[(df.event_name == eventname) &
                                    (df.event_type == eventtype) &
                                    (df[u'订单类型'] == applytype)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'规则命中月份'],
                            aggfunc=len,
                            fill_value=0)
    table_day = pd.pivot_table(df[(df.event_name == eventname) &
                                (df.event_type == eventtype) &
                                (df[u'订单类型'] == applytype) &
                                (df[u'规则命中月份'] == 201707)],
                           index=['rule_decision', 'rule_name_normal'], 
                            values=['apply_code'], 
                            columns=[u'hit_rule_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table_name.to_excel(writer,sheetname,header=False,index=False)
    table_month.to_excel(writer,sheetname,startrow=3)
    table_day.to_excel(writer,sheetname,startrow=2000)

    
    filepath1 = filedir + '\\' + filename1 + '.csv'
    df1 = pd.read_csv(filepath1,encoding='utf-8')
    df1 = df1[df1["loc_abmoduleflag"]=="B"]  
    df1[u'execut_date']=df1[u'execut日期']
    df1[u'execut_date']=df1[u'execut_date'].astype("category")
    df1[u'execut_date'].cat.set_categories(["2017-07-0%s"%i for i in range(1,10)] 
                                        + ["2017-07-%s"%i for i in range(10,32)],
                                           inplace=True)
    table1_month = pd.pivot_table(df1[(df1.event_name == eventname) &
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut月份'],
                            aggfunc=len,
                            fill_value=0)
    table1_day = pd.pivot_table(df1[(df1.event_name == eventname) & 
                            (df1[u'execut状态'] == 'FINISHED') &
                            (df1[u'execut月份'] == 201707) &
                            (df1[u'订单类型'] == applytype) &
                            (df1[u'execut日期'] >= df[u'规则命中日期'].min())],
                            values=['apply_code'], 
                            columns=[u'execut_date'],
                            aggfunc=len,
                            fill_value=0)                                
    table1_month.to_excel(writer,sheetname,startrow=1,startcol=1)
    table1_day.to_excel(writer,sheetname,startrow=1998,startcol=1)
    
#决策事件
rule_pivot('loanbqs_submart', 'bqsrule_fsyys_b_submart', u'新客户订单', 'custdecision')

writer.save() 


end = time.clock()
print ('Running time: %s Seconds'%(end-start))

