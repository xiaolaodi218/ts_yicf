# -*- coding: utf-8 -*-
"""
Created on Thu Jun  8 09:29:44 2017

@author: Administrator
"""
   
import time
start =time.clock()

import mysql.connector
import os
import sys
import re
import csv
import codecs

sys.path.append(r"F:\BQS_ETL v0.2\lib")
import dbconfig_importer

db_config = r"F:\BQS_ETL v0.2\cfg\database_config.json"
tmp_dir = r"D:\mili\Datamart\rawdata_csv_py\account"

cnx = dbconfig_importer.connect(db_config)

#counter=0
query_cursor = cnx.cursor()

#==============================================================================
# cur.execute("SELECT * FROM appdp.apply_info")
# rows = query_cursor.fetchall()
# #获取连接对象的描述信息
# desc = query_cursor.description
# print ('cur.description:',desc)
# #打印表头，就是字段名字
# print ("%s %2s %3s %7s" % (desc[0][0], desc[1][0],desc[2][0],desc[3][0]))
# 
# #获取所有数据库
# query_cursor.execute('SHOW DATABASES')
# print(query_cursor.fetchall())
# #获取dome数据库中所有表
# query_cursor.execute('SHOW TABLES')
# print(query_cursor.fetchall())
#==============================================================================


def csv_appdp(dp_table):
    counter=0    
    query="SELECT * FROM appdp." + dp_table      
    
    query_cursor.execute(query)
    
    appdp_csv_file = tmp_dir + '\\'+ dp_table + ".csv"
    appdp_csvfile = codecs.open(appdp_csv_file,'w', 'utf-8')    
    dp_writer = csv.writer(appdp_csvfile)
        
    while True:
        rows = query_cursor.fetchone()
        desc = query_cursor.description
        header=[]
        for i in desc:
            header.append(i[0])
        
        if counter==0:
            dp_writer.writerow(header)
        if	not rows: break
        dp_writer.writerow(rows)
        counter += 1

csv_appdp("apply_info")
csv_appdp("approval_info")
csv_appdp("bqs_hit_rule")
csv_appdp("bqs_main_info")
csv_appdp("bqs_strategy_result")
csv_appdp("creditx_anti_fraud")
csv_appdp("creditx_score")
csv_appdp("fushu_operator_raw_data")
csv_appdp("invoke_record")
csv_appdp("strategy_execution")
csv_appdp("td_hit_rule")
csv_appdp("td_policy")
csv_appdp("td_risk_result")
csv_appdp("zmxy_pf_task")
#==============================================================================
# csv_appdp("ex_jxl_basic")
# csv_appdp("ex_jxl_user_info_check")
# csv_appdp("jxl_data_summary")
#==============================================================================
                   
query_cursor.close()
cnx.close()
#appdp_csvfile.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))

