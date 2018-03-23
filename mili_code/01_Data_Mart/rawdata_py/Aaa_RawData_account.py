# -*- coding: utf-8 -*-
"""
Created on Fri Jul 14 13:56:46 2017

@author: Administrator
"""

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

db_config = r"F:\BQS_ETL v0.2\cfg\account_config.json"
tmp_dir = r"D:\mili\Datamart\rawdata_csv_py\account"

cnx = dbconfig_importer.connect(db_config)

#counter=0
query_cursor = cnx.cursor()

def csv_account(acc_table):
    counter=0    
    query="SELECT * FROM account." + acc_table      
    
    query_cursor.execute(query)
    
    account_csv_file = tmp_dir + '\\'+ acc_table + ".csv"
    account_csvfile = codecs.open(account_csv_file,'w', 'utf-8')    
    acc_writer = csv.writer(account_csvfile)
        
    while True:
        rows = query_cursor.fetchone()
        desc = query_cursor.description
        header=[]
        for i in desc:
            header.append(i[0])
        
        if counter==0:
            acc_writer.writerow(header)
        if	not rows: break
        acc_writer.writerow(rows)
        counter += 1

csv_account("account_info")
csv_account("bill_main")
csv_account("repay_plan")

                   
query_cursor.close()
cnx.close()
#account_csvfile.close()

end = time.clock()
print('Running time: %s Seconds'%(end-start))



#==============================================================================
# #库和表
# query_cursor.execute('SHOW DATABASES')
# 
# print(query_cursor.fetchall())
# [('information_schema',), ('account',), ('approval',), ('cloudcall',), ('collection',), ('credit',), ('credit_data',), ('credit_lend',), ('crm',), ('css',), ('disconf',), ('fastfile',), ('file',), ('innodb',), ('insidedb',), ('mysql',), ('ods',), ('payment',), ('performance_schema',), ('product',), ('report',), ('resources',), ('shared',), ('sms',), ('tmp',), ('tslog',)]
# 
# query="SELECT * FROM account.account_info"
# 
# query_cursor.execute('SHOW TABLES')
# 
# print(query_cursor.fetchall())
# [('account_bank_info',), ('account_info',), ('account_info_snapshot',), ('account_info_snapshot_bak',), ('account_kft_apply',), ('base_fee',), ('bill_fee_dtl',), ('bill_fee_dtl_snapshot',), ('bill_fee_dtl_snapshot_bak',), ('bill_main',), ('bill_main_snapshot',), ('bill_main_snapshot_bak',), ('bill_main_xyd',), ('bill_notify',), ('bill_status_notify_dtl',), ('bill_status_notify_main',), ('branch_info',), ('claims_business_info',), ('company_account_pay_register',), ('company_batch_reduction_log',), ('early_repay_appoint_fee_dtl',), ('early_repay_appoint_main',), ('entrust_transfer_confirm',), ('error_amount_adjust',), ('excessive_pay_info',), ('fee_breaks_apply_dtl',), ('fee_breaks_apply_main',), ('fund_channel_change_info',), ('mq_msg_receive',), ('mq_wx_msg_receive',), ('offset_info',), ('overdue_fee',), ('overdue_fee_rebuilt_compare',), ('product_repay_priority',), ('realtime_draw',), ('repay_amt',), ('repay_apply',), ('repay_plan',), ('repay_plan_js',), ('repay_plan_xyd',), ('repayment_ynxt_dtl',), ('repayment_ynxt_dtl_detail',), ('repayment_ynxt_main',), ('system_batch_date',), ('trans_journal_dtl',), ('trans_journal_main',)]
#==============================================================================

