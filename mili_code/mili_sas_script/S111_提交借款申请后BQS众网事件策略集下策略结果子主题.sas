*****************************************
	�ύ��������BQS�����¼�������
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname submart "D:\mili\Datamart\data";*/

***�����¼�;
data loan_zw;
set submart.loanBQS_submart(where = (event_name = "custzhongwang") 
							 keep = apply_code event_name execution_id execut״̬ execut��� execut���� execut�·� os_type);
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
select a.apply_code, a.event_name, a.execut���, a.execut״̬, a.execut����, a.execut�·�, a.os_type, b.main_info_id
from loan_zw as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***���������������;
data jbgz_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�����������_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = jbgz_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table jbgz_zw as
select a.apply_code, a.execut״̬, a.execut���,a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as �����������_ZW���
from loanSet_result_zw as a left join 
jbgz_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***����FSYYS����_ZW;
data fsyys_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS����_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = fsyys_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsyys_zw as
select a.apply_code, a.execut״̬, a.execut���, a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS����_ZW���
from loanSet_result_zw as a left join 
fsyys_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***ʧ�ŷ��ղ���_ZW;
data sxfx_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "ʧ�ŷ��ղ���_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = sxfx_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = sxfx_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table sxfx_zw as
select a.apply_code, a.execut״̬, a.execut���, a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as ʧ�ŷ��ղ���_ZW���
from loanSet_result_zw as a left join 
sxfx_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***BR����_ZW;
data br_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "BR����_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = br_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = br_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table br_zw as
select a.apply_code, a.execut״̬, a.execut���, a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as BR����_ZW���
from loanSet_result_zw as a left join 
br_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;


***�����������_ZW;
data eysq_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�����������_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = eysq_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = eysq_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table eysq_zw as
select a.apply_code, a.execut״̬, a.execut���, a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as �����������_ZW���
from loanSet_result_zw as a left join 
eysq_zw_strategy as b on a.main_info_id = b.main_info_id;
quit;

***�����������_ZW;
data glgz_zw_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�����������_ZW"));
rename id = strategy_result_id;
/*drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;*/
run;
proc sort data = glgz_zw_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = glgz_zw_strategy nodupkey; by main_info_id; run;

proc sql;
create table glgz_zw as
select a.apply_code, a.event_name, a.execut״̬, a.execut���, a.execut����, a.execut�·�, a.execut���, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as �����������_ZW���
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

if execut״̬ = "FINISHED" and �����������_ZW��� = "" then �����������_ZW��� = "Accept";
if execut״̬ = "FINISHED" and FSYYS����_ZW��� = "" then FSYYS����_ZW��� = "Accept";
if execut״̬ = "FINISHED" and ʧ�ŷ��ղ���_ZW��� = "" then ʧ�ŷ��ղ���_ZW��� = "Accept";
if execut״̬ = "FINISHED" and BR����_ZW��� = "" then BR����_ZW��� = "Accept";
if execut״̬ = "FINISHED" and �����������_ZW��� = "" then �����������_ZW��� = "Accept";
if execut״̬ = "FINISHED" and �����������_ZW��� = "" then �����������_ZW��� = "Accept";

run;
