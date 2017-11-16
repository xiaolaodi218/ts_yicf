*********************************
	策略调用执行子主题
*********************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

*---------------------------------------------------------------------------------------------*
***策略调用;
data invoke_record;
set dpRaw.invoke_record;
run;
/*token是用于关联设备信息的，一般是app打开的时候生成，然后在后续事件中都用同一个token，因为测试环境有些事件调用没上传phone_no，所以通过token来补*/
proc sort data = invoke_record(where = (phone_no ^="" and length(bai_qi_shi_token) > 20)) out = token_phone(keep = bai_qi_shi_token phone_no rename=(phone_no = phone)) nodupkey; 
by bai_qi_shi_token; 
run;
proc sort data = invoke_record;
by bai_qi_shi_token; 
run;
data invoke_record;
merge invoke_record(in = a) token_phone(in = b);
by bai_qi_shi_token;
if phone_no = "" then phone_no = phone;
	 if index(gps_address, "新疆维吾尔自治区") then GPS省份 = "新疆维吾尔自治区";
else if index(gps_address, "广西壮族自治区") then GPS省份 = "广西壮族自治区";
else if index(gps_address, "内蒙古自治区") then GPS省份 = "内蒙古自治区"; 
else if index(gps_address, "西藏自治区") then GPS省份 = "西藏自治区"; 
else if index(gps_address, "宁夏回族自治区") then GPS省份 = "宁夏回族自治区"; 
else if index(gps_address, "澳门特别行政区") then GPS省份 = "澳门特别行政区"; 
else GPS省份 = ksubstr(gps_address, 1, 3);

invoke日期 = put(datepart(last_updated), yymmdd10.);
invoke月份 = put(datepart(last_updated), yymmn6.);

rename id = invoke_record_id status = invoke状态;
drop bai_qi_shi_token id_card ip_address ip_area latitude longitude name tong_dun_token phone date_created last_updated gps_address;
run;

data submart.invoke_record;
set invoke_record;
run;

data loan_invoke hold_invoke dynamic_invoke pay_invoke reloan_invoke reloan_simple_invoke zhongrong_invoke;
set submart.invoke_record;
	 if event_type in ("LOAN","ZHONGRONG_LOAN") then output loan_invoke;
else if event_type = "HOLD" then output hold_invoke;
else if event_type = "SEND_DYNAMIC" then output dynamic_invoke;
else if event_type = "MINI_AMOUNT_PAY" then output pay_invoke;
else if event_type = "RELOAN" then output reloan_invoke;
else if event_type = "RELOAN_SIMPLE" then output reloan_simple_invoke;

run;



***策略执行;
data strategy_execution;
set dpRaw.strategy_execution;

execut日期 = put(datepart(last_updated), yymmdd10.);
execut月份 = put(datepart(last_updated), yymmn6.);

rename id = execution_id name = event_name decision = execut结果 status = execut状态;
drop date_created last_updated version;
run;

data submart.strategy_execution;
set strategy_execution;
run;

data bqs_execution td_execution creditx_execution;
set submart.strategy_execution;
	 if type = "BQS" then output bqs_execution;
else if type = "TD" then output td_execution;
else if type = "CREDITX" then output creditx_execution;
run;
*---------------------------------------------------------------------------------------------*


***提交借款申请后跑的BQS结果;
proc sql;
create table loan_bqs_result as
select a.*, b.*
from loan_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;
/*BQS各策略集结果*/
/*data submart.loanBQS_blk_submart submart.loanBQS_loan_submart submart.loanBQS_face_submart submart.loanBQS_invi_submart submart.loanBQS_acq_submart;*/
/*set loan_bqs_result;*/
/*	 if event_name = "blacklist" then output submart.loanBQS_blk_submart;*/
/*else if event_name = "loan" then output submart.loanBQS_loan_submart;*/
/*else if event_name = "faceRecognition" then output submart.loanBQS_face_submart;*/
/*else if event_name = "invitation" then output submart.loanBQS_invi_submart;*/
/*else if event_name = "acquire" then output submart.loanBQS_acq_submart;*/
/*run;*/

data bqs_engine_result_1;
set loan_bqs_result(keep = invoke_record_id execut结果 event_name);
	 if execut结果 = "REJECT" then executrisk = 3;
else if execut结果 = "REVIEW" then executrisk = 2;
else if execut结果 = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut结果;
run;
proc sql;
create table bqs_engine_result_2 as
select invoke_record_id, max(executrisk) as risk
from bqs_engine_result_1
group by invoke_record_id
;
quit;
proc sql;
create table bqs_engine_result_3 as
select invoke_record_id, max(executrisk) as risk_blkloan
from bqs_engine_result_1
where event_name in ("blacklist", "loan")
group by invoke_record_id
;
quit;

proc sort data = loan_bqs_result; by invoke_record_id; run;
proc sort data = bqs_engine_result_2 nodupkey; by invoke_record_id; run;
proc sort data = bqs_engine_result_3 nodupkey; by invoke_record_id; run;
data submart.loanBQS_submart;
merge loan_bqs_result(in = a) bqs_engine_result_2(in = b) bqs_engine_result_3(in = c);
by invoke_record_id;
if a;
	 if risk = 3 then 引擎结果 = "REJECT";
else if risk = 2 then 引擎结果 = "REVIEW";
else if risk = 1 then 引擎结果 = "ACCEPT";
if invoke状态 = "ERROR" then 引擎结果 = "ERROR";
	 if risk_blkloan = 3 then 名单贷款事件结果 = "REJECT";
else if risk_blkloan = 2 then 名单贷款事件结果 = "REVIEW";
else if risk_blkloan = 1 then 名单贷款事件结果 = "ACCEPT";
if invoke状态 = "ERROR" then 名单贷款事件结果 = "ERROR";
drop risk event_type phone_no type risk_blkloan;
run;




/****BQS下众网的结果;*/
/*proc sql;*/
/*create table loan_bqszw_result as*/
/*select a.*, b.**/
/*from zhongrong_invoke as a left join */
/*bqs_execution as b on a.invoke_record_id = b.invoke_record_id*/
/*where execution_id ^= .*/
/*;*/
/*quit;*/
/*/*BQS各策略集结果*/*/
/*/*data submart.loanBQS_blk_submart submart.loanBQS_loan_submart submart.loanBQS_face_submart submart.loanBQS_invi_submart submart.loanBQS_acq_submart;*/*/
/*/*set loan_bqs_result;*/*/
/*/*	 if event_name = "blacklist" then output submart.loanBQS_blk_submart;*/*/
/*/*else if event_name = "loan" then output submart.loanBQS_loan_submart;*/*/
/*/*else if event_name = "faceRecognition" then output submart.loanBQS_face_submart;*/*/
/*/*else if event_name = "invitation" then output submart.loanBQS_invi_submart;*/*/
/*/*else if event_name = "acquire" then output submart.loanBQS_acq_submart;*/*/
/*/*run;*/*/
/**/
/*data bqszw_engine_result_1;*/
/*set loan_bqszw_result(keep = invoke_record_id execut结果 event_name);*/
/*	 if execut结果 = "REJECT" then executrisk = 3;*/
/*else if execut结果 = "REVIEW" then executrisk = 2;*/
/*else if execut结果 = "ACCEPT" then executrisk = 1;*/
/*else executrisk = 0;*/
/*drop execut结果;*/
/*run;*/
/*proc sql;*/
/*create table bqs_engine_result_2 as*/
/*select invoke_record_id, max(executrisk) as risk*/
/*from bqs_engine_result_1*/
/*group by invoke_record_id*/
/*;*/
/*quit;*/
/*proc sql;*/
/*create table bqs_engine_result_3 as*/
/*select invoke_record_id, max(executrisk) as risk_blkloan*/
/*from bqs_engine_result_1*/
/*where event_name in ("blacklist", "loan")*/
/*group by invoke_record_id*/
/*;*/
/*quit;*/
/**/
/*proc sort data = loan_bqs_result; by invoke_record_id; run;*/
/*proc sort data = bqs_engine_result_2 nodupkey; by invoke_record_id; run;*/
/*proc sort data = bqs_engine_result_3 nodupkey; by invoke_record_id; run;*/
/*data submart.loanBQS_submart;*/
/*merge loan_bqs_result(in = a) bqs_engine_result_2(in = b) bqs_engine_result_3(in = c);*/
/*by invoke_record_id;*/
/*if a;*/
/*	 if risk = 3 then 引擎结果 = "REJECT";*/
/*else if risk = 2 then 引擎结果 = "REVIEW";*/
/*else if risk = 1 then 引擎结果 = "ACCEPT";*/
/*if invoke状态 = "ERROR" then 引擎结果 = "ERROR";*/
/*	 if risk_blkloan = 3 then 名单贷款事件结果 = "REJECT";*/
/*else if risk_blkloan = 2 then 名单贷款事件结果 = "REVIEW";*/
/*else if risk_blkloan = 1 then 名单贷款事件结果 = "ACCEPT";*/
/*if invoke状态 = "ERROR" then 名单贷款事件结果 = "ERROR";*/
/*drop risk event_type phone_no type risk_blkloan;*/
/*run;*/
/**/
/**/
/**/
/**/
/**/
/**/






***提交借款申请后跑的TD结果;
proc sql;
create table loan_td_result as
select a.*, b.*
from loan_invoke as a left join 
td_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data submart.loanTD_submart;
set loan_td_result;
引擎结果 = execut结果;
drop event_type phone_no type;
run;


***提交借款申请后跑的CREDITX结果;
proc sql;
create table loan_creditx_result as
select a.*, b.*
from loan_invoke as a left join 
creditx_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;
/*氪信反欺诈和评分结果*/
data submart.loanCX_fraud_submart submart.loanCX_score_submart;
set loan_creditx_result;
	 if event_name = "anti_fraud" then output submart.loanCX_fraud_submart;
else output submart.loanCX_score_submart;
run;

data creditx_engine_result_1;
set loan_creditx_result(keep = invoke_record_id execut结果);
	 if execut结果 = "REJECT" then executrisk = 3;
else if execut结果 = "REVIEW" then executrisk = 2;
else if execut结果 = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut结果;
run;
proc sql;
create table creditx_engine_result_2 as
select invoke_record_id, max(executrisk) as risk
from creditx_engine_result_1
group by invoke_record_id
;
quit;

proc sort data = loan_creditx_result; by invoke_record_id; run;
proc sort data = creditx_engine_result_2 nodupkey; by invoke_record_id; run;
data submart.loanCX_submart;
merge loan_creditx_result(in = a) creditx_engine_result_2(in = b);
by invoke_record_id;
if a;
	 if risk = 3 then 引擎结果 = "REJECT";
else if risk = 2 then 引擎结果 = "REVIEW";
else if risk = 1 then 引擎结果 = "ACCEPT";
if invoke状态 = "ERROR" then 引擎结果 = "ERROR";
drop risk event_type phone_no type;
run;

*---------------------下面代码移到L001_给订单打标签子主题--------------------------------*
***申请订单的其他标签，如是否复贷;
/*data apply_flag;*/
/*set submart.apply_submart(keep = apply_code 复贷申请);*/
/*run;*/
/*proc sort data = apply_flag nodupkey; by apply_code; run;*/
/**/
/*proc sort data = submart.loanBQS_submart out = loanBQS_submart; by apply_code; run;*/
/*data submart.loanBQS_submart;*/
/*merge loanBQS_submart(in = a) apply_flag(in = b);*/
/*by apply_code;*/
/*if a;*/
/*run;*/
/**/
/*proc sort data = submart.loanTD_submart out = loanTD_submart; by apply_code; run;*/
/*data submart.loanTD_submart;*/
/*merge loanTD_submart(in = a) apply_flag(in = b);*/
/*by apply_code;*/
/*if a;*/
/*run;*/
/**/
/*proc sort data = submart.loanCX_submart out = loanCX_submart; by apply_code; run;*/
/*data submart.loanCX_submart;*/
/*merge loanCX_submart(in = a) apply_flag(in = b);*/
/*by apply_code;*/
/*if a;*/
/*run;*/
*---------------------上面面代码移到L001_给订单打标签子主题--------------------------------*


***提交借款申请后跑的系统策略结果;
data bqs_engine;
set submart.loanBQS_submart(keep = invoke_record_id apply_code invoke状态 GPS省份 invoke日期 invoke月份 引擎结果 os_type);
rename 引擎结果 = BQS引擎结果;
run;
data td_engine;
set submart.loanTD_submart(keep = invoke_record_id 引擎结果 os_type);
rename 引擎结果 = TD引擎结果;
run;
data creditx_engine;
set submart.loanCX_submart(keep = invoke_record_id 引擎结果 os_type);
rename 引擎结果 = CREDITX引擎结果;
run;
proc sort data = bqs_engine nodupkey; by invoke_record_id; run;
proc sort data = td_engine nodupkey; by invoke_record_id; run;
proc sort data = creditx_engine nodupkey; by invoke_record_id; run;
data submart.loan_submart;
merge bqs_engine(in = a) td_engine(in = b) creditx_engine(in = c);
by invoke_record_id;
if a;
	 if BQS引擎结果 = "REJECT" or TD引擎结果 = "REJECT" or CREDITX引擎结果 = "REJECT" then 系统决策结果 = "REJECT";
else if BQS引擎结果 = "REVIEW" or TD引擎结果 = "REVIEW" or CREDITX引擎结果 = "REVIEW" then 系统决策结果 = "REVIEW";
else if BQS引擎结果 = "ACCEPT" and TD引擎结果 = "ACCEPT" and (CREDITX引擎结果 = "ACCEPT" or CREDITX引擎结果 = "") then 系统决策结果 = "ACCEPT";
if invoke状态 = "ERROR" then 系统决策结果 = "ERROR";
run;

/*data loan_result;*/
/*set loan_bqs_result(keep = invoke_record_id execut结果 event_name) */
/*	loan_td_result(keep = invoke_record_id execut结果 event_name) */
/*	loan_creditx_result(keep = invoke_record_id execut结果 event_name);*/
/*	 if execut结果 = "REJECT" then executrisk = 3;*/
/*else if execut结果 = "REVIEW" then executrisk = 2;*/
/*else if execut结果 = "ACCEPT" then executrisk = 1;*/
/*else executrisk = 0;*/
/*drop execut结果;*/
/*run;*/
/****金策略结果;*/
/*proc sql;*/
/*create table gold_result as*/
/*select invoke_record_id, max(executrisk) as risk*/
/*from loan_result*/
/*where event_name ^= "invitation"*/
/*group by invoke_record_id*/
/*;*/
/*quit;*/
/*data gold_result;*/
/*set gold_result;*/
/*	 if risk = 3 then 金策略结果 = "REJECT";*/
/*else if risk = 2 then 金策略结果 = "REVIEW";*/
/*else if risk = 1 then 金策略结果 = "ACCEPT";*/
/*drop risk;*/
/*run;*/
/****银策略结果;*/
/*proc sql;*/
/*create table silver_result as*/
/*select invoke_record_id, max(executrisk) as risk*/
/*from loan_result*/
/*where event_name ^= "loan"*/
/*group by invoke_record_id*/
/*;*/
/*quit;*/
/*data silver_result;*/
/*set silver_result;*/
/*	 if risk = 3 then 银策略结果 = "REJECT";*/
/*else if risk = 2 then 银策略结果 = "REVIEW";*/
/*else if risk = 1 then 银策略结果 = "ACCEPT";*/
/*drop risk;*/
/*run;*/
/*proc sort data = gold_result nodupkey; by invoke_record_id; run;*/
/*proc sort data = silver_result nodupkey; by invoke_record_id; run;*/
/*proc sort data = submart.loan_submart out = loan_submart nodupkey; by invoke_record_id; run;*/
/*data submart.loan_submart;*/
/*merge loan_submart(in = a) gold_result(in = b) silver_result(in = c);*/
/*by invoke_record_id;*/
/*if a;*/
/*run;*/

***极速贷提交借款申请后跑的系统策略结果;
proc sql;
create table pay_bqs_result as
select a.*, b.*
from pay_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data pay_bqs_engine_result_1;
set pay_bqs_result(keep = invoke_record_id execut结果);
	 if execut结果 = "REJECT" then executrisk = 3;
else if execut结果 = "REVIEW" then executrisk = 2;
else if execut结果 = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut结果;
run;
proc sql;
create table pay_bqs_engine_result_2 as
select invoke_record_id, max(executrisk) as risk
from pay_bqs_engine_result_1
group by invoke_record_id
;
quit;

proc sort data = pay_bqs_result; by invoke_record_id; run;
proc sort data = pay_bqs_engine_result_2 nodupkey; by invoke_record_id; run;
data submart.payBQS_submart;
merge pay_bqs_result(in = a) pay_bqs_engine_result_2(in = b);
by invoke_record_id;
if a;
	 if risk = 3 then 引擎结果 = "REJECT";
else if risk = 2 then 引擎结果 = "REVIEW";
else if risk = 1 then 引擎结果 = "ACCEPT";
if invoke状态 = "ERROR" then 引擎结果 = "ERROR";
drop risk event_type phone_no type;
run;
*--------------------------------------------------------------------------------*

*********************************
RELOAN会跑BQS和TD;
*********************************;
***复贷提交借款申请后跑的BQS结果;
proc sql;
create table reloan_bqs_result as
select a.*, b.*
from reloan_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data bqs_engine_result_1;
set reloan_bqs_result(keep = invoke_record_id execut结果 event_name);
	 if execut结果 = "REJECT" then executrisk = 3;
else if execut结果 = "REVIEW" then executrisk = 2;
else if execut结果 = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut结果;
run;
proc sql;
create table bqs_engine_result_2 as
select invoke_record_id, max(executrisk) as risk
from bqs_engine_result_1
group by invoke_record_id
;
quit;

proc sort data = reloan_bqs_result; by invoke_record_id; run;
proc sort data = bqs_engine_result_2 nodupkey; by invoke_record_id; run;
data submart.reloanBQS_submart;
merge reloan_bqs_result(in = a) bqs_engine_result_2(in = b);
by invoke_record_id;
if a;
	 if risk = 3 then 引擎结果 = "REJECT";
else if risk = 2 then 引擎结果 = "REVIEW";
else if risk = 1 then 引擎结果 = "ACCEPT";
if invoke状态 = "ERROR" then 引擎结果 = "ERROR";
drop risk event_type phone_no type;
run;

***复贷提交借款申请后跑的TD结果;
proc sql;
create table reloan_td_result as
select a.*, b.*
from reloan_invoke as a left join 
td_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data submart.reloanTD_submart;
set reloan_td_result;
引擎结果 = execut结果;
drop event_type phone_no type;
run;


data bqs_engine;
set submart.reloanBQS_submart(keep = invoke_record_id apply_code invoke状态 GPS省份 invoke日期 invoke月份 引擎结果 os_type);
rename 引擎结果 = BQS引擎结果;
run;
data td_engine;
set submart.reloanTD_submart(keep = invoke_record_id 引擎结果 os_type);
rename 引擎结果 = TD引擎结果;
run;
proc sort data = bqs_engine nodupkey; by invoke_record_id; run;
proc sort data = td_engine nodupkey; by invoke_record_id; run;
data submart.reloan_submart;
merge bqs_engine(in = a) td_engine(in = b);
by invoke_record_id;
if a;
	 if BQS引擎结果 = "REJECT" or TD引擎结果 = "REJECT" then 系统决策结果 = "REJECT";
else if BQS引擎结果 = "REVIEW" or TD引擎结果 = "REVIEW" then 系统决策结果 = "REVIEW";
else if BQS引擎结果 = "ACCEPT" and TD引擎结果 = "ACCEPT" then 系统决策结果 = "ACCEPT";
if invoke状态 = "ERROR" then 系统决策结果 = "ERROR";
run;

*--------------------------------------------------------------------------------*
*********************************
RELOAN_SIMPLE会跑BQS;
*********************************;
***复贷2提交借款申请后跑的BQS结果;
proc sql;
create table reloan_simple_bqs_result as
select a.*, b.*
from reloan_simple_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data bqs_engine_result_1;
set reloan_simple_bqs_result(keep = invoke_record_id execut结果 event_name);
	 if execut结果 = "REJECT" then executrisk = 3;
else if execut结果 = "REVIEW" then executrisk = 2;
else if execut结果 = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut结果;
run;
proc sql;
create table bqs_engine_result_2 as
select invoke_record_id, max(executrisk) as risk
from bqs_engine_result_1
group by invoke_record_id
;
quit;

proc sort data = reloan_simple_bqs_result; by invoke_record_id; run;
proc sort data = bqs_engine_result_2 nodupkey; by invoke_record_id; run;
data submart.reloansimpleBQS_submart;
merge reloan_simple_bqs_result(in = a) bqs_engine_result_2(in = b);
by invoke_record_id;
if a;
	 if risk = 3 then 引擎结果 = "REJECT";
else if risk = 2 then 引擎结果 = "REVIEW";
else if risk = 1 then 引擎结果 = "ACCEPT";
if invoke状态 = "ERROR" then 引擎结果 = "ERROR";
drop risk event_type phone_no type;
run;
