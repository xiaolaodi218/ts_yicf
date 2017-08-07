********************************************
	BQS引擎里规则决策调整对结果的影响子主题
********************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "C:\Users\lenovo\Document\TS\Datamart\applend\rawdata";*/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

*----------------------------策略集、策略原结果-----------------------------------------------------------------*
***提交借款申请后策略集原结果;
data strategySet_result;
set submart.loanstrategySet_submart;
keep apply_code invoke状态 invoke日期 invoke月份 execut结果_blk execut结果_loan execut结果_invitation execut结果_faceRecognition execut结果_td
	execut结果_cxfraud execut结果_cxscore 金策略结果 银策略结果;
run;
***提交借款申请后名单比对事件下策略原结果;
data blk_result;
set submart.loanBQS_blk_submart;
run;
***提交借款申请后贷款事件下策略原结果;
data loan_result;
set submart.loanBQS_loan_submart;
run;
***提交借款申请后邀请事件下策略原结果;
data invi_result;
set submart.loanBQS_invi_submart;
run;

*---------------------------名单比对事件规则命中情况-------------------------------------------------------------*
***提交借款申请后单比对事件下BR规则命中情况;
data br_rule;
set submart.BQSrule_br_submart(where = (event_type = "LOAN") keep = main_info_id event_type rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***提交借款申请后单比对事件下失信风险规则命中情况;
data shixin_rule;
set submart.BQSrule_shixin_submart(where = (event_type = "LOAN") keep = main_info_id event_type rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***提交借款申请后单比对事件下管控规则命中情况;
data gk_rule;
set submart.BQSrule_gk_submart(where = (event_type = "LOAN") keep = main_info_id event_type rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
*---------------------------------名单比对事件规则调整--------------------------------------------------------*
***BR规则决策调整;
data br_rule_adj;
set br_rule;
/*if rule_code = "BRMD004" then rule_risk = 2;*/
/*if rule_code = "BRMD008" then rule_risk = 2;*/
/*if rule_code = "BRMD012" then rule_risk = 2;*/
/*if rule_code = "BRMD016" then rule_risk = 2;*/
run;
***失信风险规则决策调整;
data shixin_rule_adj;
set shixin_rule;
run;
***管控规则决策调整;
data gk_rule_adj;
set gk_rule;
run;
*----------------------------------名单比对事件规则调整后结果-------------------------------------------------*
***BR规则决策调整后BR策略结果;
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
***失信规则决策调整后失信策略结果;
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
***管控规则决策调整后管控规则策略结果;
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

***规则调整后名单比对事件结果;
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


*----------------------------贷款事件规则命中情况----------------------------------------------------------------------------*
***提交借款申请后基本规则命中情况;
data jbgz_rule;
set submart.BQSrule_jbgz_submart(where = (event_type = "LOAN" and event_name = "loan") 
								  keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***提交借款申请后JXL规则命中情况;
data jxl_rule;
set submart.BQSrule_jxl_submart(where = (event_type = "LOAN" and event_name = "loan") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***提交借款申请后FSYYS规则命中情况;
data fsyys_rule;
set submart.BQSrule_fsyys_submart(where = (event_type = "LOAN" and event_name = "loan") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
*----------------------------------贷款事件规则调整---------------------------------------------------------*
***基本规则决策调整;
data jbgz_rule_adj;
set jbgz_rule;
if rule_code = "JBAA015" then rule_risk = 1;
run;
***JXL规则决策调整;
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
***FSYYS规则决策调整;
data fsyys_rule_adj;
set fsyys_rule;
/*if rule_code = "FSSJ025" then rule_risk = 1;*/
/*if rule_code = "FSSJ027" then rule_risk = 1;*/
run;
*------------------------------贷款事件规则调整后结果------------------------------------------*
***基本规则决策调整后基本规则策略结果;
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
***JXL规则决策调整后JXL规则策略结果;
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
***FSYYS规则决策调整后FSYYS规则策略结果;
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

***规则调整后贷款事件结果;
proc sort data = loan_result nodupkey; by main_info_id; run;
proc sort data = jbgz_adj nodupkey; by main_info_id; run;
proc sort data = jxl_adj nodupkey; by main_info_id; run;
proc sort data = fsyys_adj nodupkey; by main_info_id; run;
data loan_adj;
merge loan_result(in = a) jbgz_adj(in = b) jxl_adj(in = c) fsyys_adj(in = d);
by main_info_id;
if a;
	 if jbgz_result_adj = "Reject" or jxl_result_adj = "Reject" or fsyys_result_adj = "Reject" or FSDS策略结果 = "Reject" or 流量控制策略结果 = "Reject" or 恶意申请策略结果 = "Reject" or 异常申请策略结果 = "Reject" then loan_adj = "REJECT";
else if jbgz_result_adj = "Review" or jxl_result_adj = "Review" or fsyys_result_adj = "Review" or FSDS策略结果 = "Review" or 流量控制策略结果 = "Review" or 恶意申请策略结果 = "Review" or 异常申请策略结果 = "Review" then loan_adj = "REVIEW";
else loan_adj = "ACCEPT";
run;

data submart.loan_adj;
set loan_adj;
run;


*----------------------------邀请事件规则命中情况----------------------------------------------------------------------------*
***提交借款申请后基本规则命中情况;
data jbgz_rule;
set submart.BQSrule_jbgz_submart(where = (event_type = "LOAN" and event_name = "invitation") 
								  keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***提交借款申请后JXL规则命中情况;
data jxl_rule;
set submart.BQSrule_jxl_submart(where = (event_type = "LOAN" and event_name = "invitation") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
***提交借款申请后FSYYS规则命中情况;
data fsyys_rule;
set submart.BQSrule_fsyys_submart(where = (event_type = "LOAN" and event_name = "invitation") 
								 keep = main_info_id event_type event_name rule_code rule_decision);
	 if rule_decision = "Reject" then rule_risk = 3;
else if rule_decision = "Review" then rule_risk = 2;
else if rule_decision = "Accept" then rule_risk = 1;
else rule_risk = 0;
run;
*----------------------------------邀请事件规则调整---------------------------------------------------------*
***基本规则决策调整;
data jbgz_rule_adj;
set jbgz_rule;
if rule_code = "JBAA015" then rule_risk = 1;
run;
***JXL规则决策调整;
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
***FSYYS规则决策调整;
data fsyys_rule_adj;
set fsyys_rule;
if rule_code = "FSSJ025" then rule_risk = 1;
if rule_code = "FSSJ027" then rule_risk = 1;
run;
*------------------------------邀请事件规则调整后结果------------------------------------------*
***基本规则决策调整后基本规则策略结果;
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
***JXL规则决策调整后JXL规则策略结果;
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
***FSYYS规则决策调整后FSYYS规则策略结果;
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

***规则调整后邀请事件结果;
proc sort data = invi_result nodupkey; by main_info_id; run;
proc sort data = jbgz_adj nodupkey; by main_info_id; run;
proc sort data = jxl_adj nodupkey; by main_info_id; run;
proc sort data = fsyys_adj nodupkey; by main_info_id; run;
data invi_adj;
merge invi_result(in = a) jbgz_adj(in = b) jxl_adj(in = c) fsyys_adj(in = d);
by main_info_id;
if a;
	 if jbgz_result_adj = "Reject" or jxl_result_adj = "Reject" or fsyys_result_adj = "Reject" or FSDS策略结果 = "Reject" or 流量控制策略结果 = "Reject" or 恶意申请策略结果 = "Reject" or 异常申请策略结果 = "Reject" then invi_adj = "REJECT";
else if jbgz_result_adj = "Review" or jxl_result_adj = "Review" or fsyys_result_adj = "Review" or FSDS策略结果 = "Review" or 流量控制策略结果 = "Review" or 恶意申请策略结果 = "Review" or 异常申请策略结果 = "Review" then invi_adj = "REVIEW";
else invi_adj = "ACCEPT";
run;

data submart.invi_adj;
set invi_adj;
run;

*------------------------------规则调整后系统决策结果-----------------------------------------------;
proc sort data = strategySet_result nodupkey; by apply_code; run;
proc sort data = blk_adj(keep = apply_code blk_adj) nodupkey; by apply_code; run;
proc sort data = loan_adj(keep = apply_code loan_adj) nodupkey; by apply_code; run;
proc sort data = invi_adj(keep = apply_code invi_adj) nodupkey; by apply_code; run;
data submart.bqsengine_adj;
merge strategySet_result(in = a) blk_adj(in = b) loan_adj(in = c) invi_adj(in = d);
by apply_code;
if a;
	 if blk_adj = "REJECT" or loan_adj = "REJECT" or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" 
		 or execut结果_cxfraud = "REJECT" or execut结果_cxscore = "REJECT" then 金策略结果_adj = "REJECT";
else if blk_adj = "REVIEW" or loan_adj = "REVIEW" or execut结果_td = "REVIEW" or execut结果_faceRecognition = "REVIEW" 
		 or execut结果_cxfraud = "REVIEW" or execut结果_cxscore = "REVIEW" then 金策略结果_adj = "REVIEW";
else 金策略结果_adj = "ACCEPT";
	 if blk_adj = "REJECT" or invi_adj = "REJECT" or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" 
		 or execut结果_cxfraud = "REJECT" or execut结果_cxscore = "REJECT" then 银策略结果_adj = "REJECT";
else if blk_adj = "REVIEW" or invi_adj = "REVIEW" or execut结果_td = "REVIEW" or execut结果_faceRecognition = "REVIEW" 
		 or execut结果_cxfraud = "REVIEW" or execut结果_cxscore = "REVIEW" then 银策略结果_adj = "REVIEW";
else 银策略结果_adj = "ACCEPT";
if invoke状态 = "ERROR" then do; 金策略结果_adj = "ERROR"; 银策略结果_adj = "ERROR"; end;
/*drop blk_adj loan_adj;*/
run;
