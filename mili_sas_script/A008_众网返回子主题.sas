option compress = yes validvarname = any;

libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";

data zw_apply;
set dpraw.zw_apply;
众网处理日期 = put(datepart(date_created), yymmdd10.);
run;

data zw_apply;
set zw_apply;
format 众网返回结果 $20.;
if status = "AGREE" then 众网返回结果 = "通过";
if status = "DISAGREE" then 众网返回结果 = "拒绝";
if status = "SEND_FAIL" then 众网返回结果 = "推众网错误";
if status = "SEND_SUCCESS" then 众网返回结果 = "推众网成功";
if status = "INIT" then 众网返回结果 = "系统审核中";
run;

proc freq data=zw_apply noprint;
table 众网处理日期*众网返回结果/out=cac;
run;

data aaaaaaaa;
set zw_apply;
if status in ("SEND_FAIL","SEND_SUCCESS","INIT","INIT");
run;
