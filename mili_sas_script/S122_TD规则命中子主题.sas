*****************************************
	TD规则命中子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/


***提交借款申请后调用的策略;
data invoke_record;
set submart.invoke_record(where = (event_type in ("LOAN", "RELOAN")));
keep invoke_record_id event_type os_type apply_code;
run;

***申请订单的其他标签，如是否复贷;
data apply_flag;
set submart.apply_submart(keep = apply_code 复贷申请);
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

proc sort data = invoke_record; by apply_code; run;
data invoke_record;
merge invoke_record(in = a) apply_flag(in = b);
by apply_code;
if a;
run;

data strategy_execution;
set submart.strategy_execution;
keep execution_id invoke_record_id;
run;

proc sql;
create table invoke_execution as
select a.*, b.execution_id
from invoke_record as a left join 
strategy_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data td_risk_result;
set dpRaw.td_risk_result(keep = id execution_id policy_set_name);
rename id = risk_result_id;
run;
proc sort data = td_risk_result nodupkey; by execution_id descending risk_result_id; run;
proc sort data = td_risk_result nodupkey; by execution_id; run;

proc sql;
create table invoke_exec as
select a.event_type, a.os_type, a.apply_code, a.复贷申请, b.risk_result_id, b.policy_set_name
from invoke_execution as a left join 
td_risk_result as b on a.execution_id = b.execution_id
;
quit;

data td_policy;
set dpRaw.td_policy(keep = id risk_result_id);
rename id = policy_id;
run;

proc sql;
create table td_policy_result as
select a.*, b.*
from td_policy as a
left join invoke_exec as b on a.risk_result_id = b.risk_result_id
;
quit;

data td_hit_rule;
set dpraw.td_hit_rule;
规则命中月份 = put(datepart(last_updated), yymmn6.);
规则命中日期 = put(datepart(last_updated), yymmdd10.);
rename decision = rule_decision name = rule_name score = rule_score;
drop id date_created last_updated parent_uuid uuid;
run;

proc sql;
create table submart.tdrule_submart as
select a.*, b.*
from td_policy_result as a left join
td_hit_rule as b on a.policy_id = b.policy_id
;
quit;

