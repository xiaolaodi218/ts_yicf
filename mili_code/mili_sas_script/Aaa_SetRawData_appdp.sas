option compress = yes validvarname = any;
********************
策略原始数据
********************;
libname dp odbc datasrc=Prod_appdp;

libname dpraw "D:\mili\Datamart\rawdata\appdp";

/*限制时间为近7天*/
data _null_;
format dt yymmdd10.;
dt= today() - 3;
call symput("dt", dhms(dt,0,0,0));
run;

data _null_;
a = time();
call symput('start', a);
run;

data dpraw.apply_info;
set dp.apply_info(drop = interest ip_address ip_area os_type);
run;

data dpraw.approval_info;
set dp.approval_info(drop = handler_id handler_name remark priority);
run;

data dpraw.bqs_main_info;
set dp.bqs_main_info(drop = flow_no result_desc result_code);
run;

data dpraw.fushu_operator_raw_data;
set dp.fushu_operator_raw_data(drop =city first_record_time province provider last_record_time);
run;


libname dp odbc datasrc=Prod_appdp;

data dpraw.zmxy_pf_task;
set dp.zmxy_pf_task(drop = open_id remove_flag is_new);
run;

data dpraw.tian_qi_info;
set dp.tian_qi_info(drop = is_black is_hit_model);
run;

data dpraw.bing_jian_info;
set dp.bing_jian_info;
run;

data dpraw.zw_apply;
set dp.zw_apply(drop = customer_id remark shilupan_score risk_data_key status_source);
run;

/*data dpraw.invoke_record;*/
/*set dp.invoke_record(drop =gps_address ip_address id_card ip_area name tong_dun_token version  latitude longitude name);*/
/*run;*/

data invoke_record_temp;
set dp.invoke_record(drop =gps_address ip_address id_card ip_area name tong_dun_token version  latitude longitude name where = (last_updated >= &dt.));
run;
data invoke_record_all;
set invoke_record_temp dpraw.invoke_record;
run;
proc sort data = invoke_record_all nodupkey out = dpraw.invoke_record;by id;run;

/*data dpraw.strategy_execution;*/
/*set dp.strategy_execution(drop = version work_key );*/
/*run;*/
data strategy_execution_temp;
set dp.strategy_execution(drop = version work_key where = (last_updated >= &dt.));
run;
data strategy_execution_all;
set strategy_execution_temp  dpraw.strategy_execution;
run;
proc sort data = strategy_execution_all nodupkey out = dpraw.strategy_execution;by id;


/*data dpraw.bqs_strategy_result;*/
/*set dp.bqs_strategy_result(drop = strategy_id tips reject_value risk_type strategy_mode review_value where = (last_updated >= &dt.));*/
/*run;*/

data bqs_strategy_result_temp;
set dp.bqs_strategy_result(drop = strategy_id tips reject_value risk_type strategy_mode review_value where = (last_updated >= &dt.));
run;
data bqs_strategy_result_all;
set bqs_strategy_result_temp  dpraw.bqs_strategy_result;
run;
proc sort data = bqs_strategy_result_all nodupkey out = dpraw.bqs_strategy_result;by id;

/*data dpraw.bqs_hit_rule;*/
/*set dp.bqs_hit_rule;*/
/*run;*/

data bqs_hit_rule_temp;
set dp.bqs_hit_rule(where = (last_updated >= &dt.));
run;
data bqs_hit_rule_all;
set dpraw.bqs_hit_rule  bqs_hit_rule_temp;
run;
/*proc sort data = bqs_hit_rule_all nodupkey out = dpraw.bqs_hit_rule;by id;run;*/
/*排序*/
proc sort data = bqs_hit_rule_all out = bqs_hit_rule_a1;
by id;
run;
/*去重;*/
data dpraw.bqs_hit_rule; 
if _n_=1 then do;
  declare hash c();
  c.definekey("id");
  c.definedata("id");
  c.definedone();
end;
   set bqs_hit_rule_a1 end=done;  
   if c.find() ^= 0 then do;      
      c.add(); 
  output; 
   end;  
run; 

libname dp odbc datasrc=Prod_appdp;

data dpraw.td_risk_result;
set dp.td_risk_result(drop = device_info seq_id rule_detail_result_key spend_time reason_code geoip_info attribution);
run;

data dpraw.td_policy;
set dp.td_policy(drop = policy_uuid policy_mode);
run;

data dpraw.td_hit_rule;
set dp.td_hit_rule(drop = parent_uuid uuid);
run;

libname dp odbc datasrc=Prod_appdp;

data dpraw.creditx_score;
set dp.creditx_score(drop = probability os_type);
run;

data dpraw.creditx_anti_fraud;
set dp.creditx_anti_fraud(drop = return_code);
run;
/*libname dp odbc datasrc=Prod_appdp;*/
/**/
/*data dpraw.creditx_anti_fraud;*/
/*set dp.creditx_anti_fraud;*/
/*run;*/

/*data dpraw.ex_jxl_user_info_check;*/
/*set dp.ex_jxl_user_info_check;*/
/*run;*/

/*data dpraw.ex_jxl_basic;*/
/*set dp.ex_jxl_basic;*/
/*run;*/

/*data dpraw.jxl_data_summary;*/
/*set dp.jxl_data_summary;*/
/*run;*/

data _null_;
a = time();
b = a - &start.;
put b time.;
run;
