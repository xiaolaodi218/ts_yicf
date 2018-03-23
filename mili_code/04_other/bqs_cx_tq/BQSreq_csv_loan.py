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

sys.path.append(r"F:\BQS_ETL v0.2\lib")
import dbconfig_importer
import json_parser

db_config = r"F:\BQS_ETL v0.2\cfg\database_config.json"
tmp_dir = r"F:\BQS\tmp"

cnx = dbconfig_importer.connect(db_config)

#sys.stdout = os.fdopen(sys.stdout.fileno(), w, 0)

####################
# start_dt & end_dt
####################
if len(sys.argv) > 1:
    start_dt = datetime.datetime.strptime(sys.argv[1], '%Y-%m-%d')
else:
    start_dt = datetime.datetime(2017,6,28).replace(hour=0, minute=0, second=0, microsecond=0)
end_dt = datetime.datetime(2017,7,6).replace(hour=0, minute=0, second=0, microsecond=0)

print("start_dt: ", str(start_dt))
print("end_dt: ", str(end_dt))

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

req_csv_file = tmp_dir + '\\'+'req_bqsloan2017_6.28-7.6' + ".csv"
req_csvfile = codecs.open(req_csv_file,'w', 'utf-8')

req_writer = csv.writer(req_csvfile)
 
for (id, req_data) in query_cursor:
    req_data = req_data.decode('utf-8')
    req_data_json = json.loads(req_data)
    
    if req_data_json['eventType'] != 'loan':
        continue
    
    col_list = [        
'loc_1mcnt_silent',
'loc_1mmaxcnt_silent',
'loc_3mcnt_silent',
'loc_3mmaxcnt_silent',
'loc_6mcnt_silent',
'loc_6mmaxcnt_silent',
'loc_6mon_amount_percent',
'loc_6mon_amount_total',
'loc_6mon_amount_xuni',
'loc_abmoduleflag',
'loc_addresscnt',
'loc_amount_cp',
'loc_amount_tx',
'loc_amount_xd',
'loc_amount_xn',
'loc_appsl',
'loc_ava_exp',
'loc_ava_limit',
'loc_badcredit',
'loc_bank_contact',
'loc_callcount',
'loc_calledcount',
'loc_cell_used_time',
'loc_contacts_class1_blk_cnt',
'loc_contacts_class2_blk_cnt',
'loc_contacts_router_ratio',
'loc_count_cp',
'loc_count_tx',
'loc_count_xd',
'loc_count_xn',
'loc_court_call_much',
'loc_credit_contact',
'loc_CreditxScore',
'loc_fm_contact_cnt_l1m',
'loc_fm_contact_cnt_l3m',
'loc_fm_contact_time_l1m',
'loc_fm_contact_time_l3m',
'loc_forge',
'loc_gaming',
'loc_id_with_other_names_cnt',
'loc_id_with_other_phones_cnt',
'loc_idcard_match_ebus',
'loc_idcard_match_tel',
'loc_inpast1st_calledtime',
'loc_inpast1st_calltime',
'loc_inpast2nd_calledtime',
'loc_inpast2nd_calltime',
'loc_inpast3rd_calledtime',
'loc_inpast3rd_calltime',
'loc_inpast4th_calledtime',
'loc_inpast4th_calltime',
'loc_inpast5th_calledtime',
'loc_inpast5th_calltime',
'loc_inter_call_few',
'loc_ivs_score',
'loc_jxl_cell_financial',
'loc_jxl_id_court',
'loc_jxl_id_financial',
'loc_latest_com_time',
'loc_lawyer_call_much',
'loc_limit',
'loc_loan_contact',
'loc_location_match_idcard',
'loc_macao_call_much',
'loc_mobile_match_add',
'loc_mobile_match_ebus',
'loc_mobiletype',
'loc_mz',
'loc_name_match_ebus',
'loc_name_match_tel',
'loc_night_activity',
'loc_night_freq',
'loc_no_call',
'loc_phone_gray_score',
'loc_phone_with_other_id_cnt',
'loc_phone_with_other_names_cnt',
'loc_phonenum',
'loc_po_contact_cnt_l1m',
'loc_po_contact_cnt_l1w',
'loc_po_contact_cnt_l3m',
'loc_po_contact_date_latest',
'loc_po_contact_time_l1m',
'loc_po_contact_time_l3m',
'loc_register_date',
'loc_register_org_cnt',
'loc_regtime',
'loc_reliability_cell_failure',
'loc_searched_org_cnt',
'loc_status',
'loc_subtime',
'loc_tel_fm_rank',
'loc_tel_jm_rank',
'loc_tel_po_rank',
'loc_tel_py_rank',
'loc_tel_qs_rank',
'loc_tel_qt_rank',
'loc_tel_ts_rank',
'loc_tel_tx_rank',
'loc_tel_xd_rank',
'loc_tel_xdjm_rank',
'loc_tel_zn_rank',
'loc_txlfm',
'loc_txlfm_flag',
'loc_txlsl',
'loc_unusnalflag',
'loc_yysisidentify',
'loc_zmscore',
#'loc_abmoduleflag'
]

    header=['id']+col_list
    value_result = json_parser.get(req_data_json, col_list)
    value_list = [id] + value_result
                 
    if rows_counter == 0:       
        req_writer.writerow(header)        
    req_writer.writerow(value_list)   
    rows_counter += 1
          
print(str(rows_counter) + " rows inserted into file.")

query_cursor.close()
cnx.close()
req_csvfile.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))
