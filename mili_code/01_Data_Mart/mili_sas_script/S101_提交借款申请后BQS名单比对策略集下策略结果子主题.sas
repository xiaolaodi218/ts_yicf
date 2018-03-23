*****************************************
	�ύ��������BQS�����ȶ��¼�������
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***�����ȶ��¼�;
data blk;
set submart.loanBQS_submart(where = (event_name = "blacklist") 
							 keep = apply_code event_name execution_id execut״̬ execut��� execut���� execut�·� os_type);
run;
proc sort data = blk nodupkey; by execution_id; run;

data bqs_main_info;
set dpRaw.bqs_main_info;
rename id = main_info_id final_decision = strategySet_decision final_score = strategySet_score;
drop date_created last_updated data_query_log_id flow_no result_code result_desc;
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table blkSet_result as
select a.apply_code, a.execut״̬, a.execut����, a.execut�·�, a.os_type, b.main_info_id
from blk as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***ʧ�ŷ��ղ���;
data bqs_shixin_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "ʧ�ŷ��ղ���"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = bqs_shixin_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = bqs_shixin_strategy nodupkey; by main_info_id; run;

/*proc sql;*/
/*create table bqs_shixin as*/
/*select a.*, b.**/
/*from blkSet_result as a left join */
/*bqs_shixin_strategy as b on a.main_info_id = b.main_info_id*/
/*;*/
/*quit;*/

proc sql;
create table bqs_shixin as
select a.apply_code, a.execut״̬, a.execut����, a.execut�·�, a.os_type, a.main_info_id, b.strategy_result_id, b.strategy_decision as ʧ�ŷ��ղ��Խ��
from blkSet_result as a left join 
bqs_shixin_strategy as b on a.main_info_id = b.main_info_id
;
quit;


***BR����;
data br_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "BR����"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = br_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = br_strategy nodupkey; by main_info_id; run;

/*proc sql;*/
/*create table br as*/
/*select a.*, b.**/
/*from blkSet_result as a left join */
/*br_strategy as b on a.main_info_id = b.main_info_id*/
/*;*/
/*quit;*/

proc sql;
create table br as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as BR���Խ��
from blkSet_result as a left join 
br_strategy as b on a.main_info_id = b.main_info_id
;
quit;

***�ܿ���������;
data gk_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "�ܿ���������"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = gk_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = gk_strategy nodupkey; by main_info_id; run;

/*proc sql;*/
/*create table gk as*/
/*select a.*, b.**/
/*from blkSet_result as a left join */
/*gk_strategy as b on a.main_info_id = b.main_info_id*/
/*;*/
/*quit;*/

proc sql;
create table gk as
select a.main_info_id, b.strategy_result_id, b.strategy_decision as �ܿ��������Խ��
from blkSet_result as a left join 
gk_strategy as b on a.main_info_id = b.main_info_id
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
from blkSet_result as a left join 
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
from blkSet_result as a left join 
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
from blkSet_result as a left join 
ycsq_strategy as b on a.main_info_id = b.main_info_id
;
quit;


proc sort data = bqs_shixin nodupkey; by main_info_id; run;
proc sort data = br nodupkey; by main_info_id; run;
proc sort data = gk nodupkey; by main_info_id; run;
data submart.loanBQS_blk_submart;
merge bqs_shixin(in = a) br(in = b) gk(in = c) llkz(in = d) eysq(in = e) ycsq(in = f);
by main_info_id;
if a;
if execut״̬ = "FINISHED" and ʧ�ŷ��ղ��Խ�� = "" then ʧ�ŷ��ղ��Խ�� = "Accept";
if execut״̬ = "FINISHED" and BR���Խ�� = "" then BR���Խ�� = "Accept";
if execut״̬ = "FINISHED" and �ܿ��������Խ�� = "" then �ܿ��������Խ�� = "Accept";
if execut״̬ = "FINISHED" and �������Ʋ��Խ�� = "" then �������Ʋ��Խ�� = "Accept";
if execut״̬ = "FINISHED" and ����������Խ�� = "" then ����������Խ�� = "Accept";
if execut״̬ = "FINISHED" and �쳣������Խ�� = "" then �쳣������Խ�� = "Accept";
run;
