#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
# @Author: 

import time
start =time.clock()
    
import mysql.connector
import re
import json
import os
import sys
import csv
import codecs

sys.path.append(r"F:\BQS_ETL v0.2\lib")
import dbconfig_importer
import json_parser

db_config = r"F:\BQS_ETL v0.2\cfg\database_config.json"
tmp_dir = r"D:\mili\Datamart\rawdata_csv_py\dwdata"

cnx = dbconfig_importer.connect(db_config)

#sys.stdout = os.fdopen(sys.stdout.fileno(), w, 0)

###################
# truncate
###################

query_cursor = cnx.cursor()

query = ("SELECT a.id, a.apply_code, a.return_code, a.hit_rules "
		 "FROM creditx_anti_fraud a ")

# in the req_json, result.eventType: blacklist, faceRecognition, loan, sendDynamic, verify

rows_counter = 0
query_cursor.execute(query)

dw_csv_file = tmp_dir + '\\'+ "risk_creditx_resp.csv"
dw_csvfile = codecs.open(dw_csv_file,'w', 'utf-8')
dw_writer = csv.writer(dw_csvfile)
  
for (id, apply_code, return_code, resp_data) in query_cursor:
#	resp_data = resp_data.decode('utf-8')
    resp_data_json = json.loads(resp_data)
    hitRules_size = len(resp_data_json)

#	here to initiate the target col list
#	col_list = [src_id, ext1, op_type, status]
#	for x in req_data_json.keys():
#		col_list.append(x)

    #if hitRules_size > 0:
    #print(hitRules_size)
    for i in range(0,hitRules_size):
#	1/2 Here to define what cols needed
        col_list = ['ruleID',
                    'riskDesc',
					   'riskLevel',
#					   'ruleDetail',
					   'ruleType']
                    
        value_list = json_parser.get(resp_data_json[i], col_list)
        value_list = [apply_code] + value_list
					
        if rows_counter==0:
            dw_writer.writerow(tuple(['apply_code']+col_list ))
        dw_writer.writerow(tuple(value_list))
        rows_counter += 1

dw_csvfile.close()
query_cursor.close()
cnx.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))
