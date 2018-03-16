#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
# @Author: DATA

import time
start =time.clock()

import mysql.connector
import re
import datetime
import json
import os
import sys
import csv
import codecs
import pandas as pd

sys.path.append(r"F:\BQS_ETL v0.2\lib")
import dbconfig_importer
import json_parser

db_config = r"F:\BQS_ETL v0.2\cfg\database_config.json"
tmp_dir = r"F:\TQ\tq_change"

cnx = dbconfig_importer.connect(db_config)

#sys.stdout = os.fdopen(sys.stdout.fileno(), w, 0)

####################
# start_dt & end_dt
####################
#==============================================================================
# if len(sys.argv) > 1:
#     start_dt = datetime.datetime.strptime(sys.argv[1], '%Y-%m-%d')
# else:
#     start_dt = datetime.datetime(2017,7,28).replace(hour=0, minute=0, second=0, microsecond=0)
# end_dt = datetime.datetime(2017,7,31).replace(hour=0, minute=0, second=0, microsecond=0)
# 
# print("start_dt: ", str(start_dt))
# print("end_dt: ", str(end_dt))
# #==============================================================================

today = datetime.date.today()
yesterday = today - datetime.timedelta(days=1)

start_dt = yesterday.strftime('%Y-%m-%d') + " 00:00:00"
end_dt = today.strftime('%Y-%m-%d') + " 00:00:00"

###################
# truncate
###################

rows_counter = 0

query_cursor = cnx.cursor()

query = ("SELECT a.id, a.req_json "
		 "FROM ex_data_query_log a "
		 "WHERE a.date_created >= %s " 
		 "AND a.date_created < %s "
#		 "AND a.id = 640689 "
		 "AND a.ext1 = 'BQS';")

# in the req_json, result.eventType: blacklist, faceRecognition, loan, sendDynamic, verify

query_cursor.execute(query, (start_dt, end_dt))

req_csv_file = tmp_dir + '\\'+'abmoduleflag_req' + ".csv"
req_csvfile = codecs.open(req_csv_file,'a+', 'utf-8')

req_writer = csv.writer(req_csvfile)
 
for (id, req_data) in query_cursor:
    req_data = req_data.decode('utf-8')
    req_data_json = json.loads(req_data)
    
    if req_data_json['eventType'] != 'loan':
        continue
    
    col_list = ['loc_abmoduleflag']

    header=['id']+col_list
    value_result = json_parser.get(req_data_json, col_list)
    if value_list:
        value_list = [id] +value_result
                 
    #if rows_counter == 0:       
        #req_writer.writerow(header)        
    req_writer.writerow(value_list)   
    rows_counter += 1
          
print(str(rows_counter) + " rows inserted into file.")

query_cursor.close()
cnx.close()
req_csvfile.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))


#==============================================================================
# tq1 = pd.read_csv(r"F:\TQ\tq_change\abmoduleflag_req6.20-7.28.csv")
# tq2 = pd.read_csv(r"F:\TQ\tq_change\abmoduleflag_req7.28-7.31.csv")
# 
# tq = pd.concat([tq1,tq2],axis = 0)
# 
# csvfile = tmp_dir + '\\'+ "abmoduleflag_req.csv"
# tq.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')
# 
#==============================================================================
