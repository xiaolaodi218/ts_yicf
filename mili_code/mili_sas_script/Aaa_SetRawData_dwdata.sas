option compress = yes validvarname = any;

libname dwdata odbc datasrc = dwdata;
libname dwRaw "D:\mili\Datamart\rawdata\dwdata";

data dwRaw.creditx_hit_rule;
set dwdata.risk_creditx_resp;
run;
data dwRaw.risk_bqs_req;
set dwdata.risk_bqs_req;
run;
