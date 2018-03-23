# -*- coding: utf-8 -*-
"""
Created on Thu Jun  8 15:22:59 2017

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
tmp_dir = r"D:\mili\Datamart\rawdata_csv_py\applend"

cnx = dbconfig_importer.connect(db_config)

query_cursor = cnx.cursor()

def csv_applend(lend_table):
    counter = 0
    query="SELECT * FROM applend." + lend_table
        
    query_cursor.execute(query)
    
    applend_csv_file = tmp_dir + '\\'+ lend_table + ".csv"    
    applend_csvfile = codecs.open(applend_csv_file,'w', 'utf-8')
    lend_writer = csv.writer(applend_csvfile)
        
    while True:
        rows = query_cursor.fetchone()
        desc = query_cursor.description
        header=[]
        for i in desc:
            header.append(i[0])
        
        if counter==0:
            lend_writer.writerow(header)
        if	not rows: break
        lend_writer.writerow(rows)
        counter += 1

csv_applend("user")
#csv_applend("user_base_info")
#csv_applend("circular")
csv_applend("loan_info")
#csv_applend("user_verification_info")
#==============================================================================
# csv_applend("id_verification")
# csv_applend("operator_verification")
# csv_applend("user_relation")
# csv_applend("user_relation_his")
#==============================================================================
                   
query_cursor.close()
cnx.close()
#applend_csvfile.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))




#==============================================================================
# 第二种取数的方法
import time
start =time.clock()

import mysql.connector
import os
import sys
import re
import csv
import pandas as pd

sys.path.append(r"F:\BQS_ETL v0.2\lib")
import dbconfig_importer

db_config = r"F:\BQS_ETL v0.2\cfg\database_config.json"
tmp_dir = r"D:\mili\Datamart\rawdata_csv_py\applend"

cnx = dbconfig_importer.connect(db_config)

query_cursor = cnx.cursor()

def csv_applend(lend_table):
    query="SELECT * FROM applend." + lend_table
      
    df = pd.read_sql(query,cnx)
    applend_csv_file = tmp_dir + '\\'+ lend_table + ".csv"    
    
    df.to_csv(applend_csv_file,encoding = "utf-8" ,index = False)
    table = ["user","loan_info"]
   
#==============================================================================
#     table = [
#             "user",
#             "user_base_info",
#             "circular",
#             "loan_info",
#             "user_verification_info",
#             "id_verification",
#             "operator_verification",
#             "user_relation",
#             "user_relation_his"]
#==============================================================================
    
for lend_table in table:
    csv_applend(lend_table)
                 
query_cursor.close()
cnx.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))