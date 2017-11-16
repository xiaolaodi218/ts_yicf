*****************************************
	提交借款申请后BQS贷款事件子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***贷款事件;
data loan;
set submart.loanBQS_submart(where = (event_name = "loan") 
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
set dpRaw.bqs_strategy_result(where = (strategy_name="基本规则策略" or strategy_name="基本规则策略_挑战者" or 
strategy_name="基本规则策略_BASE" or strategy_name="基本规则策略_AAA" or strategy_name="基本规则策略_BBB"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy nodupkey; by main_info_id; run;

proc sql;
create table jbgz as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略结果
from loanSet_result as a left join 
jbgz_strategy as b on a.main_info_id = b.main_info_id;
quit;

***基本规则策略_挑战者;
data jbgz_strategy_b;
set dpRaw.bqs_strategy_result(where = (strategy_name = "基本规则策略_挑战者"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_strategy_b nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy_b nodupkey; by main_info_id; run;

proc sql;
create table jbgz_B as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略_挑战者结果
from loanSet_result as a left join 
jbgz_strategy_b as b on a.main_info_id = b.main_info_id;
quit;


***基本规则BASE;
data jbgz_strategy_base;
set dpRaw.bqs_strategy_result(where = (strategy_name = "基本规则策略_BASE"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_strategy_base nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy_base nodupkey; by main_info_id; run;

proc sql;
create table jbgz_base as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略_BASE结果
from loanSet_result as a left join 
jbgz_strategy_base as b on a.main_info_id = b.main_info_id;
quit;

***基本规则策略_AAA;
data jbgz_strategy_AAA;
set dpRaw.bqs_strategy_result(where = (strategy_name = "基本规则策略_AAA"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_strategy_AAA nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy_AAA nodupkey; by main_info_id; run;

proc sql;
create table jbgz_AAA as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略_AAA结果
from loanSet_result as a left join 
jbgz_strategy_AAA as b on a.main_info_id = b.main_info_id;
quit;
***基本规则策略_BBB;
data jbgz_strategy_BBB;
set dpRaw.bqs_strategy_result(where = (strategy_name = "基本规则策略_BBB"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_strategy_BBB nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy_BBB nodupkey; by main_info_id; run;

proc sql;
create table jbgz_BBB as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as 基本规则策略_BBB结果
from loanSet_result as a left join 
jbgz_strategy_BBB as b on a.main_info_id = b.main_info_id;
quit;


***JXL策略;
data jxl_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "JXL策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jxl_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jxl_strategy nodupkey; by main_info_id; run;

proc sql;
create table jxl as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as JXL策略结果
from loanSet_result as a left join 
jxl_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***流量控制策略;
data llkz_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "流量控制策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = llkz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = llkz_strategy nodupkey; by main_info_id; run;

proc sql;
create table llkz as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as 流量控制策略结果
from loanSet_result as a left join 
llkz_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***恶意申请策略;
data eysq_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "恶意申请策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = eysq_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = eysq_strategy nodupkey; by main_info_id; run;

proc sql;
create table eysq as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as 恶意申请策略结果
from loanSet_result as a left join 
eysq_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***异常申请策略;
data ycsq_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "异常申请策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = ycsq_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = ycsq_strategy nodupkey; by main_info_id; run;

proc sql;
create table ycsq as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as 异常申请策略结果
from loanSet_result as a left join 
ycsq_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略;
data fsyys_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略" or strategy_name = "FSYYS策略_挑战者" or strategy_name = "FSYYS策略_AAA" 
or strategy_name = "FSYYS策略_BBB" or strategy_name = "FSYYS策略_CCC"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsyys as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略结果
from loanSet_result as a left join 
fsyys_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略_挑战者;
data fsyys_strategy_B;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_挑战者"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy_B nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy_B nodupkey; by main_info_id; run;

proc sql;
create table fsyys_B as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_挑战者结果
from loanSet_result as a left join 
fsyys_strategy_B as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略_BASE;
data fsyys_strategy_BASE;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_BASE"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy_BASE nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy_BASE nodupkey; by main_info_id; run;

proc sql;
create table fsyys_BASE as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_BASE结果
from loanSet_result as a left join 
fsyys_strategy_BASE as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略_AAA;
data fsyys_strategy_AAA;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_AAA"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy_AAA nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy_AAA nodupkey; by main_info_id; run;

proc sql;
create table fsyys_AAA as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_AAA结果
from loanSet_result as a left join 
fsyys_strategy_AAA as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略_BBB;
data fsyys_strategy_BBB;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_BBB"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy_BBB nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy_BBB nodupkey; by main_info_id; run;

proc sql;
create table fsyys_BBB as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_BBB结果
from loanSet_result as a left join 
fsyys_strategy_BBB as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS策略_CCC;
data fsyys_strategy_CCC;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS策略_CCC"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_strategy_CCC nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy_CCC nodupkey; by main_info_id; run;

proc sql;
create table fsyys_CCC as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS策略_CCC结果
from loanSet_result as a left join 
fsyys_strategy_CCC as b on a.main_info_id = b.main_info_id
;
quit;

***FSDS策略;
data fsds_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSDS策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsds_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsds_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsds as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSDS策略结果
from loanSet_result as a left join 
fsds_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***关联规则策略;
data glgz_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "关联规则策略"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = glgz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = glgz_strategy nodupkey; by main_info_id; run;

proc sql;
create table glgz as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as 关联规则策略结果
from loanSet_result as a left join 
glgz_strategy as b on a.main_info_id = b.main_info_id
;
quit;

proc sort data = jbgz nodupkey; by main_info_id; run;
proc sort data = jbgz_B nodupkey; by main_info_id; run;
proc sort data = jbgz_BASE nodupkey; by main_info_id; run;
proc sort data = jbgz_AAA nodupkey; by main_info_id; run;
proc sort data = jbgz_BBB nodupkey; by main_info_id; run;

proc sort data = jxl nodupkey; by main_info_id; run;
proc sort data = llkz nodupkey; by main_info_id; run;
proc sort data = eysq nodupkey; by main_info_id; run;
proc sort data = ycsq nodupkey; by main_info_id; run;
proc sort data = fsyys nodupkey; by main_info_id; run;
proc sort data = fsyys_B nodupkey; by main_info_id; run;
proc sort data = jbgz_BASE nodupkey; by main_info_id; run;
proc sort data = fsyys_AAA nodupkey; by main_info_id; run;
proc sort data = fsyys_BBB nodupkey; by main_info_id; run;
proc sort data = fsyys_CCC nodupkey; by main_info_id; run;

proc sort data = fsds nodupkey; by main_info_id; run;
proc sort data = glgz nodupkey; by main_info_id; run;

data submart.loanBQS_loan_submart;
merge jbgz(in = a) jxl(in = b) llkz(in = c) eysq(in = d) ycsq(in = e) fsyys(in = f) fsds(in = g) glgz(in = h) fsyys_B(in = i) jbgz_B(in = j) 
jbgz_BASE(in = k) jbgz_AAA(in = l) jbgz_BBB(in = m) fsyys_BASE(in= n) fsyys_AAA(in = o) fsyys_BBB(in = p) fsyys_CCC(in = q);
by main_info_id;
if a;
if execut状态 = "FINISHED" and 基本规则策略结果 = "" then 基本规则策略结果 = "Accept";
if execut状态 = "FINISHED" and 基本规则策略_挑战者结果 = "" then 基本规则策略_挑战者结果 = "Accept";
if execut状态 = "FINISHED" and 基本规则策略_BASE结果 = "" then 基本规则策略_BASE结果 = "Accept";
if execut状态 = "FINISHED" and 基本规则策略_AAA结果 = "" then 基本规则策略_AAA结果 = "Accept";
if execut状态 = "FINISHED" and 基本规则策略_BBB结果 = "" then 基本规则策略_BBB结果 = "Accept";

if execut状态 = "FINISHED" and JXL策略结果 = "" then JXL策略结果 = "Accept";
if execut状态 = "FINISHED" and 流量控制策略结果 = "" then 流量控制策略结果 = "Accept";
if execut状态 = "FINISHED" and 恶意申请策略结果 = "" then 恶意申请策略结果 = "Accept";
if execut状态 = "FINISHED" and 异常申请策略结果 = "" then 异常申请策略结果 = "Accept";

if execut状态 = "FINISHED" and FSYYS策略结果 = "" then FSYYS策略结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_挑战者结果 = "" then FSYYS策略_挑战者结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_BASE结果 = "" then FSYYS策略_BASE结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_AAA结果 = "" then FSYYS策略_AAA结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_BBB结果 = "" then FSYYS策略_BBB结果 = "Accept";
if execut状态 = "FINISHED" and FSYYS策略_CCC结果 = "" then FSYYS策略_CCC结果 = "Accept";

if execut状态 = "FINISHED" and FSDS策略结果 = "" then FSDS策略结果 = "Accept";
if execut状态 = "FINISHED" and 关联规则策略结果 = "" then 关联规则策略结果 = "Accept";*/;

run;
