*********************************************
	复贷2提交借款申请后BQS人脸识别事件子主题
*********************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***人脸识别事件;
data face;
set submart.reloansimpleBQS_submart(where = (event_name = "faceRecognition") 
							 keep = apply_code event_name execution_id execut状态 execut结果 execut日期 execut月份);
run;
proc sort data = face nodupkey; by execution_id; run;

data bqs_main_info;
set dpRaw.bqs_main_info;
rename id = main_info_id final_decision = strategySet_decision final_score = strategySet_score;
drop date_created last_updated data_query_log_id flow_no result_code result_desc;
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table faceSet_result as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, b.main_info_id
from face as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

***人脸比对策略;
data face_strategy;
set dpRaw.bqs_strategy_result(where = (strategy_name = "人脸比对策略"));
rename id = strategy_result_id;
drop date_created last_updated reject_value review_value risk_type strategy_id strategy_mode tips;
run;
proc sort data = face_strategy nodupkey; by main_info_id descending strategy_result_id; run;
proc sort data = face_strategy nodupkey; by main_info_id; run;

proc sql;
create table face as
select a.apply_code, a.execut状态, a.execut日期, a.execut月份, a.main_info_id, b.strategy_result_id, b.strategy_decision as 人脸比对策略结果
from faceSet_result as a left join 
face_strategy as b on a.main_info_id = b.main_info_id
;
quit;

proc sort data = face nodupkey; by main_info_id; run;
data submart.reloansimpleBQS_face_submart;
set face;
if execut状态 = "FINISHED" and 人脸比对策略结果 = "" then 人脸比对策略结果 = "Accept";
run;
