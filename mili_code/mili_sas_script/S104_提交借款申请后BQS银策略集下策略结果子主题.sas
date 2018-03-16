**********************************************
	�ύ��������BQS�����Լ��²��Խ��������
**********************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***�����Լ�;
data loan;
set submart.loanBQS_submart(where = (event_name = "invitation") 
							 keep = apply_code event_name execution_id execut״̬ execut��� execut���� execut�·� os_type);
run;
proc sort data = loan nodupkey; by execution_id; run;

data bqs_main_info;
set dpRaw.bqs_main_info;
rename id = main_info_id final_decision = strategySet_decision final_score = strategySet_score;
drop date_created last_updated data_query_log_id flow_no result_code result_desc;
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table loanSet_result as
select a.apply_code, a.execut״̬, a.execut����, a.execut�·�, a.os_type, b.main_info_id
from loan as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***�����������;
data jbgz_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�����������"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = jbgz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jbgz_strategy nodupkey; by main_info_id; run;

proc sql;
create table jbgz as
select a.apply_code, a.execut״̬, a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as ����������Խ��
from loanSet_result as a left join 
jbgz_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***JXL����;
data jxl_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "JXL����"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = jxl_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = jxl_strategy nodupkey; by main_info_id; run;

proc sql;
create table jxl as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as JXL���Խ��
from loanSet_result as a left join 
jxl_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***�������Ʋ���;
data llkz_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�������Ʋ���"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = llkz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = llkz_strategy nodupkey; by main_info_id; run;

proc sql;
create table llkz as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as �������Ʋ��Խ��
from loanSet_result as a left join 
llkz_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***�����������;
data eysq_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�����������"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = eysq_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = eysq_strategy nodupkey; by main_info_id; run;

proc sql;
create table eysq as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as ����������Խ��
from loanSet_result as a left join 
eysq_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***�쳣�������;
data ycsq_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�쳣�������"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = ycsq_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = ycsq_strategy nodupkey; by main_info_id; run;

proc sql;
create table ycsq as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as �쳣������Խ��
from loanSet_result as a left join 
ycsq_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***FSYYS����;
data fsyys_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSYYS����"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = fsyys_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsyys_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsyys as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSYYS���Խ��
from loanSet_result as a left join 
fsyys_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***FSDS����;
data fsds_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "FSDS����"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = fsds_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = fsds_strategy nodupkey; by main_info_id; run;

proc sql;
create table fsds as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as FSDS���Խ��
from loanSet_result as a left join 
fsds_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***�����������;
data glgz_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�����������"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = glgz_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = glgz_strategy nodupkey; by main_info_id; run;

proc sql;
create table glgz as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as ����������Խ��
from loanSet_result as a left join 
glgz_strategy as b on a.main_info_id = b.main_info_id
;
quit;

proc sort data = jbgz nodupkey; by main_info_id; run;
proc sort data = jxl nodupkey; by main_info_id; run;
proc sort data = llkz nodupkey; by main_info_id; run;
proc sort data = eysq nodupkey; by main_info_id; run;
proc sort data = ycsq nodupkey; by main_info_id; run;
proc sort data = fsyys nodupkey; by main_info_id; run;
proc sort data = fsds nodupkey; by main_info_id; run;
proc sort data = glgz nodupkey; by main_info_id; run;

data submart.loanBQS_invi_submart;
merge jbgz(in = a) jxl(in = b) llkz(in = c) eysq(in = d) ycsq(in = e) fsyys(in = f) fsds(in = g) glgz(in = h);
by main_info_id;
if a;
if execut״̬ = "FINISHED" and ����������Խ�� = "" then ����������Խ�� = "Accept";
if execut״̬ = "FINISHED" and JXL���Խ�� = "" then JXL���Խ�� = "Accept";
if execut״̬ = "FINISHED" and �������Ʋ��Խ�� = "" then �������Ʋ��Խ�� = "Accept";
if execut״̬ = "FINISHED" and ����������Խ�� = "" then ����������Խ�� = "Accept";
if execut״̬ = "FINISHED" and �쳣������Խ�� = "" then �쳣������Խ�� = "Accept";
if execut״̬ = "FINISHED" and FSYYS���Խ�� = "" then FSYYS���Խ�� = "Accept";
if execut״̬ = "FINISHED" and FSDS���Խ�� = "" then FSDS���Խ�� = "Accept";
if execut״̬ = "FINISHED" and ����������Խ�� = "" then ����������Խ�� = "Accept";

run;
