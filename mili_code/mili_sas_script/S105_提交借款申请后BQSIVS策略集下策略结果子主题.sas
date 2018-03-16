*****************************************
	�ύ��������BQS�յ��¼�������
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***�յ��¼�;
data ivs;
set submart.loanBQS_submart(where = (event_name = "acquire") 
							 keep = apply_code event_name execution_id execut״̬ execut��� execut���� execut�·�);
run;
proc sort data = ivs nodupkey; by execution_id; run;

data bqs_main_info;
set dpRaw.bqs_main_info;
rename id = main_info_id final_decision = strategySet_decision final_score = strategySet_score;
drop date_created last_updated data_query_log_id flow_no result_code result_desc;
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table ivsSet_result as
select a.apply_code, a.execut״̬, a.execut����, a.execut�·�, b.main_info_id
from ivs as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***�����ȶԲ���;
data ivs_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "IVS����"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = ivs_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = ivs_strategy nodupkey; by main_info_id; run;

proc sql;
create table ivs as
select a.apply_code, a.execut״̬, a.execut����, a.execut�·�, a.main_info_id, b.strategy_result_id, b.strategy_decision as IVS���Խ��
from ivsSet_result as a left join 
ivs_strategy as b on a.main_info_id = b.main_info_id
;
quit;

proc sort data = ivs nodupkey; by main_info_id; run;
data submart.loanBQS_ivs_submart;
set ivs;
if execut״̬ = "FINISHED" and IVS���Խ�� = "" then IVS���Խ�� = "Accept";
run;
