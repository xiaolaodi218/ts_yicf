********************************************
	BQS�����������ߵ����Խ����Ӱ��������
********************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "C:\Users\lenovo\Document\TS\Datamart\applend\rawdata";*/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

*----------------------------���Լ�������ԭ���-----------------------------------------------------------------*
***�ύ����������Լ�ԭ���;
data strategySet_result;
set submart.loanstrategySet_submart;
keep apply_code invoke״̬ invoke���� invoke�·� execut���_blk execut���_loan execut���_invitation execut���_faceRecognition execut���_td
	execut���_cxfraud execut���_cxscore ����Խ�� �����Խ��;
run;
***�ύ�������������ȶ��¼��²���ԭ���;
data blk_result;
set submart.loanBQS_blk_submart;
run;
***�ύ������������¼��²���ԭ���;
data loan_result;
set submart.loanBQS_loan_submart;
run;
***�ύ�������������¼��²���ԭ���;
data invi_result;
set submart.loanBQS_invi_submart;
run;

*---------------------------�����ȶ��¼������������-------------------------------------------------------------*
***�ύ�������󵥱ȶ��¼���BR�����������;
data br_rule;
set submart.BQSrule_br_submart(where = (event_type = "LOAN") keep = main_info_id event_type rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***�ύ�������󵥱ȶ��¼���ʧ�ŷ��չ����������;
data shixin_rule;
set submart.BQSrule_shixin_submart(where = (event_type = "LOAN") keep = main_info_id event_type rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***�ύ�������󵥱ȶ��¼��¹ܿع����������;
data gk_rule;
set submart.BQSrule_gk_submart(where = (event_type = "LOAN") keep = main_info_id event_type rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
*---------------------------------�����ȶ��¼��������--------------------------------------------------------*
***BR������ߵ���;
data br_rule_adj;
set br_rule;
/*if rule_code = "BRMD004" then rule_risk = 2;*/
/*if rule_code = "BRMD008" then rule_risk = 2;*/
/*if rule_code = "BRMD012" then rule_risk = 2;*/
/*if rule_code = "BRMD016" then rule_risk = 2;*/
run;
***ʧ�ŷ��չ�����ߵ���;
data shixin_rule_adj;
set shixin_rule;
run;
***�ܿع�����ߵ���;
data gk_rule_adj;
set gk_rule;
run;
*----------------------------------�����ȶ��¼������������-------------------------------------------------*
***BR������ߵ�����BR���Խ��;
proc sql;
create table br_adj as
select main_info_id, max(rule_risk) as br_risk_adj
from br_rule_adj
group by main_info_id
;
quit;
data br_adj;
set br_adj;
	 if br_risk_adj = 3 then br_result_adj = "Reject";
else if br_risk_adj = 2 then br_result_adj = "Review";
else br_result_adj = "Accept";
drop br_risk_adj;
run;
***ʧ�Ź�����ߵ�����ʧ�Ų��Խ��;
proc sql;
create table shixin_adj as
select main_info_id, max(rule_risk) as shixin_risk_adj
from shixin_rule_adj
group by main_info_id
;
quit;
data shixin_adj;
set shixin_adj;
	 if shixin_risk_adj = 3 then shixin_result_adj = "Reject";
else if shixin_risk_adj = 2 then shixin_result_adj = "Review";
else shixin_result_adj = "Accept";
drop shixin_risk_adj;
run;
***�ܿع�����ߵ�����ܿع�����Խ��;
proc sql;
create table gk_adj as
select main_info_id, max(rule_risk) as gk_risk_adj
from gk_rule_adj
group by main_info_id
;
quit;
data gk_adj;
set gk_adj;
	 if gk_risk_adj = 3 then gk_result_adj = "Reject";
else if gk_risk_adj = 2 then gk_result_adj = "Review";
else gk_result_adj = "Accept";
drop gk_risk_adj;
run;

***��������������ȶ��¼����;
proc sort data = blk_result nodupkey; by main_info_id; run;
proc sort data = br_adj nodupkey; by main_info_id; run;
proc sort data = shixin_adj nodupkey; by main_info_id; run;
proc sort data = gk_adj nodupkey; by main_info_id; run;
data blk_adj;
merge blk_result(in = a) br_adj(in = b) shixin_adj(in = c) gk_adj(in = d);
by main_info_id;
if a;
	 if br_result_adj = "Reject" or shixin_result_adj = "Reject" or gk_result_adj = "Reject" then blk_adj = "REJECT";
else if br_result_adj = "Review" or shixin_result_adj = "Review" or gk_result_adj = "Review" then blk_adj = "REVIEW";
else blk_adj = "ACCEPT";
run;

data submart.blk_adj;
set blk_adj;
run;


*----------------------------�����¼������������----------------------------------------------------------------------------*
***�ύ����������������������;
data jbgz_rule;
set submart.BQSrule_jbgz_submart(where = (event_type = "LOAN" and event_name = "loan") 
								  keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***�ύ��������JXL�����������;
data jxl_rule;
set submart.BQSrule_jxl_submart(where = (event_type = "LOAN" and event_name = "loan") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***�ύ��������FSYYS�����������;
data fsyys_rule;
set submart.BQSrule_fsyys_submart(where = (event_type = "LOAN" and event_name = "loan") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
*----------------------------------�����¼��������---------------------------------------------------------*
***����������ߵ���;
data jbgz_rule_adj;
set jbgz_rule;
if rule_code = "JBAA015" then rule_risk = 1;
run;
***JXL������ߵ���;
data jxl_rule_adj;
set jxl_rule;
/*if rule_code = "JXL0025" then rule_risk = 2;*/
/*if rule_code = "JXL0026" then rule_risk = 2;*/
/*if rule_code = "JXL0008" then rule_risk = 2;*/
/*if rule_code = "JXL0014" then rule_risk = 2;*/
/*if rule_code = "JXL0015" then rule_risk = 2;*/
/*if rule_code = "JXL0016" then rule_risk = 2;*/
/*if rule_code = "JXL0017" then rule_risk = 2;*/
/*if rule_code = "JXL0019" then rule_risk = 3;*/
/*if rule_code = "JXL0006" then rule_risk = 3;*/
/*if rule_code = "JXL0012" then rule_risk = 3;*/
/*if rule_code = "JXL0008" then rule_risk = 3;*/
/*if rule_code = "JXL0020" then rule_risk = 3;*/
/*if rule_code = "JXL0005" then rule_risk = 3;*/
/*if rule_code = "JXL0017" then rule_risk = 2;*/

run;
***FSYYS������ߵ���;
data fsyys_rule_adj;
set fsyys_rule;
/*if rule_code = "FSSJ025" then rule_risk = 1;*/
/*if rule_code = "FSSJ027" then rule_risk = 1;*/
run;
*------------------------------�����¼������������------------------------------------------*
***����������ߵ��������������Խ��;
proc sql;
create table jbgz_adj as
select main_info_id, max(rule_risk) as jbgz_risk_adj
from jbgz_rule_adj
group by main_info_id
;
quit;
data jbgz_adj;
set jbgz_adj;
	 if jbgz_risk_adj = 3 then jbgz_result_adj = "Reject";
else if jbgz_risk_adj = 2 then jbgz_result_adj = "Review";
else jbgz_result_adj = "Accept";
drop jbgz_risk_adj;
run;
***JXL������ߵ�����JXL������Խ��;
proc sql;
create table jxl_adj as
select main_info_id, max(rule_risk) as jxl_risk_adj
from jxl_rule_adj
group by main_info_id
;
quit;
data jxl_adj;
set jxl_adj;
	 if jxl_risk_adj = 3 then jxl_result_adj = "Reject";
else if jxl_risk_adj = 2 then jxl_result_adj = "Review";
else jxl_result_adj = "Accept";
drop jxl_risk_adj;
run;
***FSYYS������ߵ�����FSYYS������Խ��;
proc sql;
create table fsyys_adj as
select main_info_id, max(rule_risk) as fsyys_risk_adj
from fsyys_rule_adj
group by main_info_id
;
quit;
data fsyys_adj;
set fsyys_adj;
	 if fsyys_risk_adj = 3 then fsyys_result_adj = "Reject";
else if fsyys_risk_adj = 2 then fsyys_result_adj = "Review";
else fsyys_result_adj = "Accept";
drop fsyys_risk_adj;
run;

***�������������¼����;
proc sort data = loan_result nodupkey; by main_info_id; run;
proc sort data = jbgz_adj nodupkey; by main_info_id; run;
proc sort data = jxl_adj nodupkey; by main_info_id; run;
proc sort data = fsyys_adj nodupkey; by main_info_id; run;
data loan_adj;
merge loan_result(in = a) jbgz_adj(in = b) jxl_adj(in = c) fsyys_adj(in = d);
by main_info_id;
if a;
	 if jbgz_result_adj = "Reject" or jxl_result_adj = "Reject" or fsyys_result_adj = "Reject" or FSDS���Խ�� = "Reject" or �������Ʋ��Խ�� = "Reject" or ����������Խ�� = "Reject" or �쳣������Խ�� = "Reject" then loan_adj = "REJECT";
else if jbgz_result_adj = "Review" or jxl_result_adj = "Review" or fsyys_result_adj = "Review" or FSDS���Խ�� = "Review" or �������Ʋ��Խ�� = "Review" or ����������Խ�� = "Review" or �쳣������Խ�� = "Review" then loan_adj = "REVIEW";
else loan_adj = "ACCEPT";
run;

data submart.loan_adj;
set loan_adj;
run;


*----------------------------�����¼������������----------------------------------------------------------------------------*
***�ύ����������������������;
data jbgz_rule;
set submart.BQSrule_jbgz_submart(where = (event_type = "LOAN" and event_name = "invitation") 
								  keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***�ύ��������JXL�����������;
data jxl_rule;
set submart.BQSrule_jxl_submart(where = (event_type = "LOAN" and event_name = "invitation") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***�ύ��������FSYYS�����������;
data fsyys_rule;
set submart.BQSrule_fsyys_submart(where = (event_type = "LOAN" and event_name = "invitation") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
*----------------------------------�����¼��������---------------------------------------------------------*
***����������ߵ���;
data jbgz_rule_adj;
set jbgz_rule;
if rule_code = "JBAA015" then rule_risk = 1;
run;
***JXL������ߵ���;
data jxl_rule_adj;
set jxl_rule;
/*if rule_code = "JXL0025" then rule_risk = 2;*/
/*if rule_code = "JXL0026" then rule_risk = 2;*/
/*if rule_code = "JXL0008" then rule_risk = 2;*/
/*if rule_code = "JXL0014" then rule_risk = 2;*/
/*if rule_code = "JXL0015" then rule_risk = 2;*/
/*if rule_code = "JXL0016" then rule_risk = 2;*/
/*if rule_code = "JXL0017" then rule_risk = 2;*/
/*if rule_code = "JXL0019" then rule_risk = 3;*/
/*if rule_code = "JXL0006" then rule_risk = 3;*/
/*if rule_code = "JXL0012" then rule_risk = 3;*/
/*if rule_code = "JXL0008" then rule_risk = 3;*/
/*if rule_code = "JXL0020" then rule_risk = 3;*/
/*if rule_code = "JXL0005" then rule_risk = 3;*/
/*if rule_code = "JXL0017" then rule_risk = 2;*/

run;
***FSYYS������ߵ���;
data fsyys_rule_adj;
set fsyys_rule;
if rule_code = "FSSJ025" then rule_risk = 1;
if rule_code = "FSSJ027" then rule_risk = 1;
run;
*------------------------------�����¼������������------------------------------------------*
***����������ߵ��������������Խ��;
proc sql;
create table jbgz_adj as
select main_info_id, max(rule_risk) as jbgz_risk_adj
from jbgz_rule_adj
group by main_info_id
;
quit;
data jbgz_adj;
set jbgz_adj;
	 if jbgz_risk_adj = 3 then jbgz_result_adj = "Reject";
else if jbgz_risk_adj = 2 then jbgz_result_adj = "Review";
else jbgz_result_adj = "Accept";
drop jbgz_risk_adj;
run;
***JXL������ߵ�����JXL������Խ��;
proc sql;
create table jxl_adj as
select main_info_id, max(rule_risk) as jxl_risk_adj
from jxl_rule_adj
group by main_info_id
;
quit;
data jxl_adj;
set jxl_adj;
	 if jxl_risk_adj = 3 then jxl_result_adj = "Reject";
else if jxl_risk_adj = 2 then jxl_result_adj = "Review";
else jxl_result_adj = "Accept";
drop jxl_risk_adj;
run;
***FSYYS������ߵ�����FSYYS������Խ��;
proc sql;
create table fsyys_adj as
select main_info_id, max(rule_risk) as fsyys_risk_adj
from fsyys_rule_adj
group by main_info_id
;
quit;
data fsyys_adj;
set fsyys_adj;
	 if fsyys_risk_adj = 3 then fsyys_result_adj = "Reject";
else if fsyys_risk_adj = 2 then fsyys_result_adj = "Review";
else fsyys_result_adj = "Accept";
drop fsyys_risk_adj;
run;

***��������������¼����;
proc sort data = invi_result nodupkey; by main_info_id; run;
proc sort data = jbgz_adj nodupkey; by main_info_id; run;
proc sort data = jxl_adj nodupkey; by main_info_id; run;
proc sort data = fsyys_adj nodupkey; by main_info_id; run;
data invi_adj;
merge invi_result(in = a) jbgz_adj(in = b) jxl_adj(in = c) fsyys_adj(in = d);
by main_info_id;
if a;
	 if jbgz_result_adj = "Reject" or jxl_result_adj = "Reject" or fsyys_result_adj = "Reject" or FSDS���Խ�� = "Reject" or �������Ʋ��Խ�� = "Reject" or ����������Խ�� = "Reject" or �쳣������Խ�� = "Reject" then invi_adj = "REJECT";
else if jbgz_result_adj = "Review" or jxl_result_adj = "Review" or fsyys_result_adj = "Review" or FSDS���Խ�� = "Review" or �������Ʋ��Խ�� = "Review" or ����������Խ�� = "Review" or �쳣������Խ�� = "Review" then invi_adj = "REVIEW";
else invi_adj = "ACCEPT";
run;

data submart.invi_adj;
set invi_adj;
run;

*------------------------------���������ϵͳ���߽��-----------------------------------------------;
proc sort data = strategySet_result nodupkey; by apply_code; run;
proc sort data = blk_adj(keep = apply_code blk_adj) nodupkey; by apply_code; run;
proc sort data = loan_adj(keep = apply_code loan_adj) nodupkey; by apply_code; run;
proc sort data = invi_adj(keep = apply_code invi_adj) nodupkey; by apply_code; run;
data submart.bqsengine_adj;
merge strategySet_result(in = a) blk_adj(in = b) loan_adj(in = c) invi_adj(in = d);
by apply_code;
if a;
	 if blk_adj = "REJECT" or loan_adj = "REJECT" or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" 
		 or execut���_cxfraud = "REJECT" or execut���_cxscore = "REJECT" then ����Խ��_adj = "REJECT";
else if blk_adj = "REVIEW" or loan_adj = "REVIEW" or execut���_td = "REVIEW" or execut���_faceRecognition = "REVIEW" 
		 or execut���_cxfraud = "REVIEW" or execut���_cxscore = "REVIEW" then ����Խ��_adj = "REVIEW";
else ����Խ��_adj = "ACCEPT";
	 if blk_adj = "REJECT" or invi_adj = "REJECT" or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" 
		 or execut���_cxfraud = "REJECT" or execut���_cxscore = "REJECT" then �����Խ��_adj = "REJECT";
else if blk_adj = "REVIEW" or invi_adj = "REVIEW" or execut���_td = "REVIEW" or execut���_faceRecognition = "REVIEW" 
		 or execut���_cxfraud = "REVIEW" or execut���_cxscore = "REVIEW" then �����Խ��_adj = "REVIEW";
else �����Խ��_adj = "ACCEPT";
if invoke״̬ = "ERROR" then do; ����Խ��_adj = "ERROR"; �����Խ��_adj = "ERROR"; end;
/*drop blk_adj loan_adj;*/
run;
