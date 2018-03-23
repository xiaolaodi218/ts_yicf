# -*- coding: utf-8 -*-
"""
Created on Fri Jun 30 17:17:08 2017

@author: Administrator
"""

import csv
import pandas as pd
from pandas.io.excel import ExcelWriter

tmp_dir = r"D:\mili\Datamart\pyscript\submart"

bqs1 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2016_12.1-6.28.csv")
bqs2 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2017_6.28-7.12.csv")
bqs3 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2017_7.12-7.20.csv")
bqs4 = pd.read_csv(r"F:\BQS\tmp\req_bqsloan2017_7.20-8.1.csv")


bqsreq1 = pd.concat([bqs1,bqs2,bqs3,bqs4],axis = 0)

bqsreq = bqsreq1[["id","loc_addresscnt","loc_appsl","loc_ava_exp","loc_ava_limit","loc_callcount","loc_calledcount","loc_inpast1st_calledtime","loc_inpast1st_calltime",
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
creditx3 = pd.read_csv(r"F:\CreditX\tmp\req_Creditx2017_6.28-7.6.csv")
creditx4 = pd.read_csv(r"F:\CreditX\tmp\req_Creditx2017_7.6-7.20.csv")
creditx5 = pd.read_csv(r"F:\CreditX\tmp\req_Creditx2017_7.20-8.1.csv")

CreditX = pd.concat([creditx1,creditx2,creditx3,creditx4,creditx5],axis = 0)

writerfile = ExcelWriter(tmp_dir + '\\' + 'cxreq.xlsx')
CreditX.to_excel(writerfile,header=True,index=False)
writerfile.save()

#==============================================================================

import csv
import pandas as pd
 from pandas.io.excel import ExcelWriter

tmp_dir = r"D:\mili\Datamart\pyscript\submart"

tq1 = pd.read_csv(r"F:\TQ\tmp\tq_dec_temp6.19-7.20.csv")
tq2 = pd.read_csv(r"F:\TQ\tmp\tq_dec_temp7.20-8.1.csv")

tq = pd.concat([tq1,tq2],axis = 0)

writerfile = ExcelWriter(tmp_dir + '\\' + 'tqreq.xlsx')
tq.to_excel(writerfile,header=True,index=False)
writerfile.save()

