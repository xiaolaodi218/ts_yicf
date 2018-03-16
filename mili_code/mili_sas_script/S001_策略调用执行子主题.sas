*********************************
	���Ե���ִ��������
*********************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

*---------------------------------------------------------------------------------------------*
***���Ե���;
data invoke_record;
set dpRaw.invoke_record;
run;
/*token�����ڹ����豸��Ϣ�ģ�һ����app�򿪵�ʱ�����ɣ�Ȼ���ں����¼��ж���ͬһ��token����Ϊ���Ի�����Щ�¼�����û�ϴ�phone_no������ͨ��token����*/
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
	 if index(gps_address, "�½�ά���������") then GPSʡ�� = "�½�ά���������";
else if index(gps_address, "����׳��������") then GPSʡ�� = "����׳��������";
else if index(gps_address, "���ɹ�������") then GPSʡ�� = "���ɹ�������"; 
else if index(gps_address, "����������") then GPSʡ�� = "����������"; 
else if index(gps_address, "���Ļ���������") then GPSʡ�� = "���Ļ���������"; 
else if index(gps_address, "�����ر�������") then GPSʡ�� = "�����ر�������"; 
else GPSʡ�� = ksubstr(gps_address, 1, 3);

invoke���� = put(datepart(last_updated), yymmdd10.);
invoke�·� = put(datepart(last_updated), yymmn6.);

rename id = invoke_record_id status = invoke״̬;
drop bai_qi_shi_token phone date_created last_updated gps_address;
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



***����ִ��;
data strategy_execution;
set dpRaw.strategy_execution;

execut���� = put(datepart(last_updated), yymmdd10.);
execut�·� = put(datepart(last_updated), yymmn6.);

rename id = execution_id name = event_name decision = execut��� status = execut״̬;
drop date_created last_updated;
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


***�ύ���������ܵ�BQS���;
proc sql;
create table loan_bqs_result as
select a.*, b.*
from loan_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;
/*BQS�����Լ����*/
/*data submart.loanBQS_blk_submart submart.loanBQS_loan_submart submart.loanBQS_face_submart submart.loanBQS_invi_submart submart.loanBQS_acq_submart;*/
/*set loan_bqs_result;*/
/*	 if event_name = "blacklist" then output submart.loanBQS_blk_submart;*/
/*else if event_name = "loan" then output submart.loanBQS_loan_submart;*/
/*else if event_name = "faceRecognition" then output submart.loanBQS_face_submart;*/
/*else if event_name = "invitation" then output submart.loanBQS_invi_submart;*/
/*else if event_name = "acquire" then output submart.loanBQS_acq_submart;*/
/*run;*/

data bqs_engine_result_1;
set loan_bqs_result(keep = invoke_record_id execut��� event_name);
	 if execut��� = "REJECT" then executrisk = 3;
else if execut��� = "REVIEW" then executrisk = 2;
else if execut��� = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut���;
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
	 if risk = 3 then ������ = "REJECT";
else if risk = 2 then ������ = "REVIEW";
else if risk = 1 then ������ = "ACCEPT";
if invoke״̬ = "ERROR" then ������ = "ERROR";
	 if risk_blkloan = 3 then ���������¼���� = "REJECT";
else if risk_blkloan = 2 then ���������¼���� = "REVIEW";
else if risk_blkloan = 1 then ���������¼���� = "ACCEPT";
if invoke״̬ = "ERROR" then ���������¼���� = "ERROR";
drop risk event_type phone_no type risk_blkloan;
run;

***�ύ���������ܵ�TD���;
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
������ = execut���;
drop event_type phone_no type;
run;


***�ύ���������ܵ�CREDITX���;
proc sql;
create table loan_creditx_result as
select a.*, b.*
from loan_invoke as a left join 
creditx_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;
/*��ŷ���թ�����ֽ��*/
data submart.loanCX_fraud_submart submart.loanCX_score_submart;
set loan_creditx_result;
	 if event_name = "anti_fraud" then output submart.loanCX_fraud_submart;
else output submart.loanCX_score_submart;
run;

data creditx_engine_result_1;
set loan_creditx_result(keep = invoke_record_id execut���);
	 if execut��� = "REJECT" then executrisk = 3;
else if execut��� = "REVIEW" then executrisk = 2;
else if execut��� = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut���;
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
	 if risk = 3 then ������ = "REJECT";
else if risk = 2 then ������ = "REVIEW";
else if risk = 1 then ������ = "ACCEPT";
if invoke״̬ = "ERROR" then ������ = "ERROR";
drop risk event_type phone_no type;
run;

*---------------------��������Ƶ�L001_���������ǩ������--------------------------------*
***���붩����������ǩ�����Ƿ񸴴�;
/*data apply_flag;*/
/*set submart.apply_submart(keep = apply_code ��������);*/
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
*---------------------����������Ƶ�L001_���������ǩ������--------------------------------*


***�ύ���������ܵ�ϵͳ���Խ��;
data bqs_engine;
set submart.loanBQS_submart(keep = invoke_record_id apply_code invoke״̬ GPSʡ�� invoke���� invoke�·� ������ os_type);
rename ������ = BQS������;
run;
data td_engine;
set submart.loanTD_submart(keep = invoke_record_id ������ os_type);
rename ������ = TD������;
run;
data creditx_engine;
set submart.loanCX_submart(keep = invoke_record_id ������ os_type);
rename ������ = CREDITX������;
run;
proc sort data = bqs_engine nodupkey; by invoke_record_id; run;
proc sort data = td_engine nodupkey; by invoke_record_id; run;
proc sort data = creditx_engine nodupkey; by invoke_record_id; run;
data submart.loan_submart;
merge bqs_engine(in = a) td_engine(in = b) creditx_engine(in = c);
by invoke_record_id;
if a;
	 if BQS������ = "REJECT" or TD������ = "REJECT" or CREDITX������ = "REJECT" then ϵͳ���߽�� = "REJECT";
else if BQS������ = "REVIEW" or TD������ = "REVIEW" or CREDITX������ = "REVIEW" then ϵͳ���߽�� = "REVIEW";
else if BQS������ = "ACCEPT" and TD������ = "ACCEPT" and (CREDITX������ = "ACCEPT" or CREDITX������ = "") then ϵͳ���߽�� = "ACCEPT";
if invoke״̬ = "ERROR" then ϵͳ���߽�� = "ERROR";
run;

/*data loan_result;*/
/*set loan_bqs_result(keep = invoke_record_id execut��� event_name) */
/*	loan_td_result(keep = invoke_record_id execut��� event_name) */
/*	loan_creditx_result(keep = invoke_record_id execut��� event_name);*/
/*	 if execut��� = "REJECT" then executrisk = 3;*/
/*else if execut��� = "REVIEW" then executrisk = 2;*/
/*else if execut��� = "ACCEPT" then executrisk = 1;*/
/*else executrisk = 0;*/
/*drop execut���;*/
/*run;*/
/****����Խ��;*/
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
/*	 if risk = 3 then ����Խ�� = "REJECT";*/
/*else if risk = 2 then ����Խ�� = "REVIEW";*/
/*else if risk = 1 then ����Խ�� = "ACCEPT";*/
/*drop risk;*/
/*run;*/
/****�����Խ��;*/
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
/*	 if risk = 3 then �����Խ�� = "REJECT";*/
/*else if risk = 2 then �����Խ�� = "REVIEW";*/
/*else if risk = 1 then �����Խ�� = "ACCEPT";*/
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

***���ٴ��ύ���������ܵ�ϵͳ���Խ��;
proc sql;
create table pay_bqs_result as
select a.*, b.*
from pay_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data pay_bqs_engine_result_1;
set pay_bqs_result(keep = invoke_record_id execut���);
	 if execut��� = "REJECT" then executrisk = 3;
else if execut��� = "REVIEW" then executrisk = 2;
else if execut��� = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut���;
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
	 if risk = 3 then ������ = "REJECT";
else if risk = 2 then ������ = "REVIEW";
else if risk = 1 then ������ = "ACCEPT";
if invoke״̬ = "ERROR" then ������ = "ERROR";
drop risk event_type phone_no type;
run;
*--------------------------------------------------------------------------------*

*********************************
RELOAN����BQS��TD;
*********************************;
***�����ύ���������ܵ�BQS���;
proc sql;
create table reloan_bqs_result as
select a.*, b.*
from reloan_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data bqs_engine_result_1;
set reloan_bqs_result(keep = invoke_record_id execut��� event_name);
	 if execut��� = "REJECT" then executrisk = 3;
else if execut��� = "REVIEW" then executrisk = 2;
else if execut��� = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut���;
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
	 if risk = 3 then ������ = "REJECT";
else if risk = 2 then ������ = "REVIEW";
else if risk = 1 then ������ = "ACCEPT";
if invoke״̬ = "ERROR" then ������ = "ERROR";
drop risk event_type phone_no type;
run;

***�����ύ���������ܵ�TD���;
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
������ = execut���;
drop event_type phone_no type;
run;


data bqs_engine;
set submart.reloanBQS_submart(keep = invoke_record_id apply_code invoke״̬ GPSʡ�� invoke���� invoke�·� ������ os_type);
rename ������ = BQS������;
run;
data td_engine;
set submart.reloanTD_submart(keep = invoke_record_id ������ os_type);
rename ������ = TD������;
run;
proc sort data = bqs_engine nodupkey; by invoke_record_id; run;
proc sort data = td_engine nodupkey; by invoke_record_id; run;
data submart.reloan_submart;
merge bqs_engine(in = a) td_engine(in = b);
by invoke_record_id;
if a;
	 if BQS������ = "REJECT" or TD������ = "REJECT" then ϵͳ���߽�� = "REJECT";
else if BQS������ = "REVIEW" or TD������ = "REVIEW" then ϵͳ���߽�� = "REVIEW";
else if BQS������ = "ACCEPT" and TD������ = "ACCEPT" then ϵͳ���߽�� = "ACCEPT";
if invoke״̬ = "ERROR" then ϵͳ���߽�� = "ERROR";
run;

*--------------------------------------------------------------------------------*
*********************************
RELOAN_SIMPLE����TD;
*********************************;

/****�����ύ���������ܵ�TD���;*/
proc sql;
create table reloan_simple_td_result as
select a.*, b.*
from reloan_simple_invoke as a left join 
td_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data submart.reloansimpleTD_submart;
set reloan_simple_td_result;
������ = execut���;
drop event_type phone_no type;
run;


*--------------------------------------------------------------------------------*
*********************************
RELOAN_SIMPLE����BQS;
*********************************;
***����2�ύ���������ܵ�BQS���;
proc sql;
create table reloan_simple_bqs_result as
select a.*, b.*
from reloan_simple_invoke as a left join 
bqs_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data bqs_engine_result_1;
set reloan_simple_bqs_result(keep = invoke_record_id execut��� event_name);
	 if execut��� = "REJECT" then executrisk = 3;
else if execut��� = "REVIEW" then executrisk = 2;
else if execut��� = "ACCEPT" then executrisk = 1;
else executrisk = 0;
drop execut���;
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
	 if risk = 3 then ������ = "REJECT";
else if risk = 2 then ������ = "REVIEW";
else if risk = 1 then ������ = "ACCEPT";
if invoke״̬ = "ERROR" then ������ = "ERROR";
drop risk event_type phone_no type;
run;
