*****************************************
	提交借款申请后BQS决策事件子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***决策事件;
data loan;
set submart.loanBQS_submart(where = (event_name = "custdecision") 
							 keep = apply_code event_name execution_id execut状态 execut结果 execut日期 execut月份 os_type);
run;
proc sort data = loan nodupkey; by execution_id; run;

data bqs_main_info;
set dpRaw.bqs_main_info;
rename id = main_info_id final_decision = strategySet_decision final_score = strategySet_score;
/*drop date_created last_updated data_query_log_id flow_no result_code result_desc;*/
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table loanSet_result as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, b.main_info_id
from loan as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***基本规则策略;
data jbgz_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "基本规则策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy nodupkey; by main_info_id; run;

proc sql;
create table jbgz as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略结果
from loanSet_result as a left join 
jbgz_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略;
data fsyys_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_挑战者"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsyys as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_挑战者结果
from loanSet_result as a left join 
fsyys_strategy as b on a.main_info_id = b.main_info_id
;
quit;


proc sort data = jbgz nodupkey; by main_info_id; run;
proc sort data = fsyys nodupkey; by main_info_id; run;

data submart.loanBQS_decision_submart;
merge jbgz(in = a) fsyys(in = f);
by main_info_id;
if a;
if execut状态 = "FINISHED" and 基本规则策略结果 = "" then 基本规则策略结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_挑战者结果 = "" then FSYYS策略_挑战者结果 = "Accept";

run;
