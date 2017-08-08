# -*- coding: utf-8 -*-
"""
Created on Fri Jun 30 13:16:42 2017

@author: Administrator
"""

#==============================================================================
# 	策略入参子主题

##贷款事件
from datetime import datetime
from dateutil.parser import parse
import pandas as pd
import csv

tem = r"D:\mili\Datamart\rawdata_csv_py\applend"
ten = r"D:\mili\Datamart\rawdata_csv_py\appdp"
tmp_dir = r"D:\mili\Datamart\pyscript\submart"

main_log_id = pd.read_csv(ten + "\\" + "bqs_main_info.csv")

main_log_id = main_log_id[["data_query_log_id",'date_created', 'last_updated']]

main_log_id["date_created"] = main_log_id["date_created"].apply(lambda x:x[:10])
main_log_id["last_updated"] = main_log_id["last_updated"].apply(lambda x:x[:10])

#==============================================================================
# #时间变量
# main_log_id['created_day'] = main_log_id['date_created'].apply(lambda x:x[:2]+" "+x[2:5]+" "+x[5:])
# main_log_id['date_created'] = main_log_id['created_day'].apply(lambda x:parse(x))
# 
# main_log_id['updated_day'] = main_log_id['updated_day'].apply(lambda x:x[:2]+" "+x[2:5]+" "+x[5:])
# main_log_id['last_updated'] = main_log_id['updated_day'].apply(lambda x:parse(x))
# 
#==============================================================================
main_log_id = main_log_id.drop_duplicates(['data_query_log_id'],keep = 'first')

###贷款事件策略入参;
bqs1 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2016_12.1-6.28.csv")
bqs2 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2017_6.28-7.12.csv")
bqs3 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2017_7.12-7.20.csv")
bqs4 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2017_7.20-8.1.csv")
bqsreq = pd.concat([bqs1,bqs2,bqs3,bqs4],axis = 0)

bqs = bqsreq[["id","loc_addresscnt","loc_appsl","loc_ava_exp","loc_ava_limit","loc_callcount","loc_calledcount",
                       "loc_inpast1st_calledtime","loc_inpast1st_calltime","loc_inpast2nd_calledtime","loc_inpast2nd_calltime",
                       "loc_inpast3rd_calledtime","loc_inpast3rd_calltime","loc_limit","loc_phonenum","loc_register_date", 
						  "loc_status","loc_txlsl","loc_txlfm","loc_unusnalflag","loc_yysisidentify","loc_tel_po_rank",
                       "loc_tel_fm_rank","loc_tel_zn_rank","loc_tel_qs_rank", "loc_tel_tx_rank","loc_tel_ts_rank",
                       "loc_tel_py_rank","loc_tel_qt_rank","loc_tel_xd_rank","loc_tel_jm_rank","loc_tel_xdjm_rank",
                       "loc_6mmaxcnt_silent","loc_3mmaxcnt_silent","loc_1mmaxcnt_silent","loc_6mcnt_silent",
                        "loc_3mcnt_silent","loc_1mcnt_silent","loc_zmscore","loc_CreditxScore"]]

bqs = bqs.rename(columns={"id":"data_query_log_id"},copy=False)

bqs = bqs.drop_duplicates(['data_query_log_id'],keep = 'first')

loanevent_in = pd.merge(main_log_id,bqs,on= "data_query_log_id",how = "left")

loanevent_in['date_created'] = loanevent_in['date_created'].astype('str')
loanevent_in['month'] = loanevent_in['date_created'].apply(lambda x:x[:7])
loanevent_in.groupby('month')["loc_zmscore"].count()
loanevent_in.groupby('month')["loc_CreditxScore"].count()







#==============================================================================

import csv
import pandas as pd
from pandas.io.excel import ExcelWriter

tmp_dir = r"D:\mili\Datamart\pyscript\submart"

bqs = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2016_12.1-6.28.csv")

bqsreq = bqs[["id","loc_addresscnt","loc_appsl","loc_ava_exp","loc_ava_limit","loc_callcount","loc_calledcount","loc_inpast1st_calledtime","loc_inpast1st_calltime",
						 "loc_inpast2nd_calledtime","loc_inpast2nd_calltime","loc_inpast3rd_calledtime","loc_inpast3rd_calltime","loc_limit","loc_phonenum","loc_register_date", 
						 "loc_status","loc_txlsl","loc_txlfm","loc_unusnalflag","loc_yysisidentify","loc_tel_po_rank","loc_tel_fm_rank","loc_tel_zn_rank","loc_tel_qs_rank",
  			  			 "loc_tel_tx_rank","loc_tel_ts_rank","loc_tel_py_rank","loc_tel_qt_rank","loc_tel_xd_rank","loc_tel_jm_rank","loc_tel_xdjm_rank","loc_6mmaxcnt_silent",
						 "loc_3mmaxcnt_silent","loc_1mmaxcnt_silent","loc_6mcnt_silent","loc_3mcnt_silent","loc_1mcnt_silent","loc_zmscore","loc_CreditxScore"]]

#csvfile = tmp_dir + '\\'+ "bqsreq.csv"
#bqsreq.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

writerfile = ExcelWriter(tmp_dir + '\\' + 'bqsreq.xlsx')
bqsreq.to_excel(writerfile,header=True,index=False)
writerfile.save()

#==============================================================================

import csv
import pandas as pd
from pandas.io.excel import ExcelWriter

tmp_dir = r"D:\mili\Datamart\pyscript\submart"

creditx1 = pd.read_csv(r"F:\CreditX\tmp\req_Creditx2016_12.1-2017_5.11.csv")
creditx2 = pd.read_csv(r"F:\CreditX\tmp\req_Creditx2017_5.11-6.28.csv")

CreditX = pd.concat([creditx1,creditx2],axis = 0)

#csvfile = tmp_dir + '\\'+ "cxreq.csv"
#cxreq.to_csv(csvfile,sep=',',index=False ,encoding = 'utf-8')

writerfile = ExcelWriter(tmp_dir + '\\' + 'cxreq.xlsx')
CreditX.to_excel(writerfile,header=True,index=False)
writerfile.save()







