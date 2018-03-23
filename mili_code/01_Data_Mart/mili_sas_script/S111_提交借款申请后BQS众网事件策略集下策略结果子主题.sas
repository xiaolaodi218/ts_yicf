*****************************************
	提交借款申请后BQS众网事件子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname submart "D:\mili\Datamart\data";*/

***众网事件;
data loan_zw;
set submart.loanBQS_submart(where = (event_name = "custzhongwang") 
							 keep = apply_code event_name execution_id execut状态 execut结果 execut日期 execut月份 os_type);
run;
proc sort data = loan_zw nodupkey; by execution_id; run;

data bqs_main_info;
set dpRaw.bqs_main_info;
rename id = main_info_id final_decision = strategySet_decision final_score = strategySet_score;
/*drop date_created last_updated data_query_log_id flow_no result_code result_desc;*/
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table loanSet_result_zw as
select a.apply_code, a.event_name, a.execut结果, a.execut状态, a.execut日期, a.execut月份, a.os_type, b.main_info_id
from loan_zw as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***众网基本规则策略;
data jbgz_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "基本规则策略_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table jbgz_zw as
select a.apply_code, a.execut状态, a.execut结果,a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略_ZW结果
from loanSet_result_zw as a left join 
jbgz_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***众网FSYYS策略_ZW;
data fsyys_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsyys_zw as
select a.apply_code, a.execut状态, a.execut结果, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_ZW结果
from loanSet_result_zw as a left join 
fsyys_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***失信风险策略_ZW;
data sxfx_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "失信风险策略_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = sxfx_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = sxfx_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table sxfx_zw as
select a.apply_code, a.execut状态, a.execut结果, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 失信风险策略_ZW结果
from loanSet_result_zw as a left join 
sxfx_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***BR策略_ZW;
data br_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "BR策略_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = br_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = br_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table br_zw as
select a.apply_code, a.execut状态, a.execut结果, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as BR策略_ZW结果
from loanSet_result_zw as a left join 
br_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;


***恶意申请策略_ZW;
data eysq_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "恶意申请策略_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = eysq_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = eysq_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table eysq_zw as
select a.apply_code, a.execut状态, a.execut结果, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 恶意申请策略_ZW结果
from loanSet_result_zw as a left join 
eysq_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***关联规则策略_ZW;
data glgz_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "关联规则策略_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = glgz_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = glgz_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table glgz_zw as
select a.apply_code, a.event_name, a.execut状态, a.execut结果, a.execut日期, a.execut月份, a.execut结果, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 关联规则策略_ZW结果
from loanSet_result_zw as a left join 
glgz_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;


proc sort data = jbgz_zw nodupkey; by main_info_id; run;
proc sort data = fsyys_zw nodupkey; by main_info_id; run;
proc sort data = sxfx_zw nodupkey; by main_info_id; run;
proc sort data = br_zw nodupkey; by main_info_id; run;
proc sort data = eysq_zw nodupkey; by main_info_id; run;
proc sort data = glgz_zw nodupkey; by main_info_id; run;


data submart.loanBQS_zw_submart;
merge jbgz_zw(in = a) fsyys_zw(in = b) sxfx_zw(in = c) br_zw(in = d) eysq_zw(in = e) glgz_zw(in = f);
by main_info_id;
if a;

if execut状态 = "FINISHED" and 基本规则策略_ZW结果 = "" then 基本规则策略_ZW结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_ZW结果 = "" then FSYYS策略_ZW结果 = "Accept";
if execut状态 = "FINISHED" and 失信风险策略_ZW结果 = "" then 失信风险策略_ZW结果 = "Accept";
if execut状态 = "FINISHED" and BR策略_ZW结果 = "" then BR策略_ZW结果 = "Accept";
if execut状态 = "FINISHED" and 恶意申请策略_ZW结果 = "" then 恶意申请策略_ZW结果 = "Accept";
if execut状态 = "FINISHED" and 关联规则策略_ZW结果 = "" then 关联规则策略_ZW结果 = "Accept";

run;
