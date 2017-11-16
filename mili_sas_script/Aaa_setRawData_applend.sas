/*proc import datafile = "C:\Users\lenovo\Document\TS\08产品\线上\03风控策略\03策略配置\规则编码.xls" out = a.rule_map dbms = excel replace;*/
/*getnames = yes;*/
/*run;*/
/*proc import datafile = "C:\Users\lenovo\Document\TS\Datamart\appdp\线上人工审批拒绝原因及取消原因.xls" out = a.refuse_map dbms = excel replace;*/
/*getnames = yes;*/
/*sheet = "Sheet3";*/
/*run;*/
/*libname a "C:\Users\lenovo\Document\TS\Datamart\appdp\findata";*/


option compress = yes validvarname = any;
********************
app数据
********************;
/*libname lend odbc datasrc=mili_applend;*/
libname lend odbc datasrc=Prod_applend;

libname lendRaw "D:\mili\Datamart\rawdata\applend";

/*proc copy in = lend out = lendRaw; run;*/

data lendRaw.user;
set lend.user;
run;

data lendRaw.loan_info;
set lend.loan_info;
run;




data lendRaw.user_base_info;
set lend.user_base_info;
run;

data lendRaw.id_verification;
set lend.id_verification;
run;

data lendRaw.user_relation_his;
set lend.user_relation_his;
run;

data lendRaw.user_relation;
set lend.user_relation;
run;

libname lend odbc datasrc=Prod_applend;

data lendRaw.operator_verification;
set lend.operator_verification;
run;

data lendRaw.user_verification_info;
set lend.user_verification_info;
run;

data lendRaw.circular;
set lend.circular;
run;
