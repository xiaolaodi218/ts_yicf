*****************************************
	仅命中某些规则的申请订单子主题
*****************************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";

proc sort data = submart.id_submart out = id_submart(keep = apply_code phone_no) nodupkey; by apply_code; run;

***申请订单结果;
data apply_result;
set submart.apply_submart(keep = apply_code user_code 申请结果 申请提交日期 申请提交月份);
run;
proc sort data = apply_result nodupkey; by apply_code; run;

***审批结果;
data approval_result;
set submart.approval_submart(keep = apply_code 审批结果 审核开始月份 审核开始日期 订单类型);
run;
proc sort data = approval_result nodupkey; by apply_code; run;

data apply_appr_result;
merge apply_result(in = a) approval_result(in = b);
by apply_code;
if a;
run;


data bqsrule_submart;
set SUBMART.BQSRULE_JBGZ_SUBMART
	SUBMART.BQSRULE_FDZR_SUBMART
	SUBMART.BQSRULE_FDJBGZ_SUBMART
	SUBMART.BQSRULE_FSYYS_SUBMART
	SUBMART.BQSRULE_FSDS_SUBMART
	SUBMART.BQSRULE_GLGZ_SUBMART
;
run;
data refuse_rule;
set bqsrule_submart(where = (event_type = "LOAN" and event_name = "loan" and rule_decision = "Reject"));
keep rule_code apply_code;
run;

/*仅命中rule_code_list中一条拒绝规则*/
%let rule_code_list = FSSJ004 FSSJ024 FSSJ025 FSSJ027 JBAB007 JBAA044 JBAA015;
%macro refuse_only_one(rcl);
%let i = 1;
%do %until (%scan(&rcl., &i.)=);

%let rc = %scan(&rcl., &i.);
proc sql;
create table &rc. as 
select apply_code,
		sum(case when rule_code = "&rc." then 0 else 1 end) as other_refuse_cnt
from refuse_rule
group by apply_code
;
quit;
data &rc.;
set &rc.(where = (other_refuse_cnt = 0));
&rc. = 1;
drop other_refuse_cnt;
run;
%if &i. = 1 %then %do;
data refuse_only_one;
set apply_appr_result;
run;
%end;	
proc sort data = refuse_only_one nodupkey; by apply_code; run;
proc sort data = &rc. nodupkey; by apply_code; run;
data refuse_only_one;
merge refuse_only_one(in = a) &rc.(in = b);
by apply_code;
if a;
run;
	
%let i = %eval(&i. + 1);
%end;
%mend;
%refuse_only_one(&rule_code_list.);
data submart.refuse_only_one;
set refuse_only_one;
total = 1;
run;


/*仅命中rule_code_list2中的拒绝规则的订单，other_refuse_cnt>0*/
%let rule_code_list2 = ("JBAA044", "JBAA015");
proc sql;
create table rule_code_list2 as
select apply_code,
	sum(case when rule_code in &rule_code_list2. then 0 else 1 end) as other_refuse_cnt
from refuse_rule
group by apply_code
;
quit;
data rule_code_list2;
set rule_code_list2(where = (other_refuse_cnt = 0));
refuse_only = 1;
drop other_refuse_cnt;
run;

proc sort data = apply_appr_result nodupkey; by apply_code; run;
proc sort data = rule_code_list2 nodupkey; by apply_code; run;
data submart.refuse_only;
merge apply_appr_result(in = a) rule_code_list2(in = b);
by apply_code;
if a;
total = 1;
run;
