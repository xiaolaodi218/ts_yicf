option compress = yes validvarname = any;
********************
策略原始数据
********************;
libname dp odbc datasrc=Prod_appdp;

libname dpraw "D:\mili\Datamart\rawdata\appdp";

data dpraw.invoke_record;
set dp.invoke_record;
run;

data dpraw.strategy_execution;
set dp.strategy_execution;
run;

data dpraw.bqs_main_info;
set dp.bqs_main_info;
run;

data dpraw.bqs_strategy_result;
set dp.bqs_strategy_result;
run;

data dpraw.bqs_hit_rule;
set dp.bqs_hit_rule;
run;

data dpraw.td_risk_result;
set dp.td_risk_result;
run;

data dpraw.td_policy;
set dp.td_policy;
run;

data dpraw.td_hit_rule;
set dp.td_hit_rule;
run;

data dpraw.apply_info;
set dp.apply_info;
run;

data dpraw.approval_info;
set dp.approval_info;
run;

data dpraw.ex_jxl_user_info_check;
set dp.ex_jxl_user_info_check;
run;

data dpraw.ex_jxl_basic;
set dp.ex_jxl_basic;
run;

data dpraw.jxl_data_summary;
set dp.jxl_data_summary;
run;

data dpraw.fushu_operator_raw_data;
set dp.fushu_operator_raw_data;
run;

data dpraw.creditx_anti_fraud;
set dp.creditx_anti_fraud;
run;

data dpraw.creditx_score;
set dp.creditx_score;
run;

data dpraw.zmxy_pf_task;
set dp.zmxy_pf_task;
run;
