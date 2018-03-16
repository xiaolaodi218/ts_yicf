#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
# @Author: 
    
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

sys.path.append(r"F:\BQS_ETL v0.2\lib")
import dbconfig_importer
import json_parser

creditx_db_config = r"F:\BQS_ETL v0.2\cfg\creditx_database_config.json"
tmp_dir = r"F:\CreditX\tmp"
creditx_cnx = dbconfig_importer.connect(creditx_db_config) # for features

#sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

version = '0'

####################
# start_dt & end_dt
####################
if len(sys.argv) > 1:
    start_dt = datetime.datetime.strptime(sys.argv[1], '%Y-%m-%d')
else:
    start_dt = datetime.datetime(2017,6,28).replace(hour=0, minute=0, second=0, microsecond=0)
end_dt = datetime.datetime(2017,7,6).replace(hour=0, minute=0, second=0, microsecond=0)

print("start_dt: " + str(start_dt))
print("end_dt: " + str(end_dt))

###################
# truncate
###################


####################
# extract
####################
rows_counter = 0
query_cursor = creditx_cnx.cursor()

features_query = ("SELECT a.id, a.request_id, a.client_id, a.business_id, "
         "a.logstash_create_timestamp, a.data "
         "FROM dw_staging.logstash_staging a "
         "WHERE a.request_id in "
         "(select b.request_id from logstash_staging b where b.logstash_create_timestamp >= %s AND b.logstash_create_timestamp < %s  and b.client_id=90) "
         "AND a.client_id = 25 ;")

query_cursor.execute(features_query, (start_dt, end_dt)) 

creditx_csv_file = tmp_dir +'\\'+ "req_Creditx2017_6.28-7.6" + ".csv"
creditx_csvfile = codecs.open(creditx_csv_file,'w', 'utf-8')
creditx_writer = csv.writer(creditx_csvfile)

for (id, request_id, client_id, business_id, logstash_create_timestamp, data) in query_cursor:
    if data: 
        data = data.decode('utf-8')
        data_json = json.loads(data)
        params = json_parser.get(data_json, ['params'])
        result = json_parser.get(data_json, ['result'])

        col_list_params = [
            'apply_code',
            'request_id',
            'business_id',
        ]
        value_params = json_parser.get(params[0], col_list_params)
        apply_code = value_params[0]

        col_list_result = [
            'app_social_cnt',
            'app_type_cnt',
            'app_total_cnt',
            'app_loan_cnt',
            'app_disguise_cnt',
            'recent_device_available_capacity_rate',
            'contacts_size',
            'emgcy_in_contacts_rate',
            'last1m_callcnt_agg',
            'last3m_callcnt_agg',
            'last1m_callcnt_rate_in',
            'last1m_callcnt_void4cnt',
            'last3m_callcnt_void4cnt',
            'last1m_callcnt_agg_shrt',
            'last3m_callcnt_agg_shrt',
            'last1m_callcnt_agg_shrt_out',
            'last3m_callcnt_agg_shrt_out',
            'last1m_callcnt_agg_ctct',
            'last3m_callcnt_agg_ctct',
            'last1m_callcnt_with_emergency',
            'last3m_callcnt_with_emergency',
            'last1m_callcnt_homeplace',
            'last3m_callcnt_homeplace',
            'last1m_callplc_work',
            'last3m_callplc_work',
            'last1m_callplc_home',
            'last3m_callplc_home',
            'last1m_callplc_below_tier3cnt',
            'last3m_callplc_below_tier3cnt',
            'last1m_callcnt_agg_coll_in',
            'last3m_callcnt_agg_coll_in',
            'last1m_callcnt_agg_spc_in',
            'last3m_callcnt_agg_spc_in',
            'last1m_callplc_mostFreq',
            'last3m_callplc_mostFreq'
        ]
        value_result = json_parser.get(result[0], col_list_result)

        try:
            value_list =  [apply_code]+ value_result 
        except Exception:
            print(value_result)
            print(value_params)
            print(Exception)
            
        if rows_counter == 0:
            col_titles = ['apply_code']
            col_titles.extend(col_list_result)
            creditx_writer.writerow(tuple(['id']+col_titles ))
        creditx_writer.writerow(tuple( [id]+value_list ))
        rows_counter += 1

        #print(params)
        #print(result)
        #hitRules = json_parser.get(data_json, ['result.hitRules'])
        #if hitRules:
        #    hitRules = hitRules[0]
        #    hitRule_size = len(hitRules)
            
print(str(rows_counter) + " rows inserted into file.")

query_cursor.close()
creditx_cnx.close()
creditx_csvfile.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))

