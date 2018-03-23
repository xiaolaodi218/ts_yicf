*****************************************
	申请订单命中的规则子主题
*****************************************;
option compress = yes validvarname = any;

libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";
libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";
libname dt "C:\Users\lenovo\Document\TS\Datamart\米粒白条\逾期客户命中的所有规则";

***需要查看命中规则的申请订单;
/*data dt;*/
/*set dt.mili_yuqitest(keep = contract_no loan_date 还款天数 CURR_RECEIVE_CAPITAL_AMT od_days 最大逾期天数 BORROWER_TEL_ONE);*/
/*if od_days > 3 or 最大逾期天数 > 4;*/
/*曾经逾期天数 = 最大逾期天数 - 1;*/
/*放款日期 = put(loan_date, yymmdd10.);*/
/*rename contract_no = apply_code CURR_RECEIVE_CAPITAL_AMT = 借款金额 od_days = 当前逾期天数; */
/*drop 最大逾期天数 loan_date;*/
/*run;*/
data dt;
set submart.mili_bill_main(keep = contract_no overdue_days bill_status CH_NAME where = (bill_status ^= "0001"));
	 if bill_status = "0002" and overdue_days > 5 then 逾期类型 = "当前逾期5+"; 
else if overdue_days > 5 then 逾期类型 = "曾经逾期5+";
else 逾期类型 = "其他";
rename contract_no = apply_code;
run;
proc sort data = dt nodupkey; by apply_code; run;


***BR命中规则;
data br_rule;
set submart.BQSrule_br_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = br_rule; by apply_code; run;
data dt_br_rule;
merge dt(in = a) br_rule(in = b);
by apply_code;
if a;
run;

***失信风险命中规则;
data shixin_rule;
set submart.BQSrule_shixin_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = shixin_rule; by apply_code; run;
data dt_shixin_rule;
merge dt(in = a) shixin_rule(in = b);
by apply_code;
if a;
run;

***基本规则命中规则;
data jbgz_rule;
set submart.BQSrule_jbgz_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = jbgz_rule; by apply_code; run;
data dt_jbgz_rule;
merge dt(in = a) jbgz_rule(in = b);
by apply_code;
if a;
run;

***JXL命中规则;
data jxl_rule;
set submart.BQSrule_jxl_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = jxl_rule; by apply_code; run;
data dt_jxl_rule;
merge dt(in = a) jxl_rule(in = b);
by apply_code;
if a;
run;

***EYSQ命中规则;
data eysq_rule;
set submart.loanloan_eysq_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = eysq_rule; by apply_code; run;
data dt_eysq_rule;
merge dt(in = a) eysq_rule(in = b);
by apply_code;
if a;
run;

data dt_bqs_rule;
set dt_br_rule dt_shixin_rule dt_jbgz_rule dt_jxl_rule dt_eysq_rule;
run;

***TD命中规则;
data td_rule;
set submart.Tdrule_submart(keep = apply_code rule_name rule_score);
rename rule_name = rule_name_normal rule_score = decision;
strategy_name = "同盾";
run;
proc sort data = td_rule; by apply_code; run;

data dt_td_rule;
merge dt(in = a) td_rule(in = b);
by apply_code;
if a;
run;


data dt_rule;
set dt_bqs_rule dt_td_rule;
run;
proc sort data = dt_rule; by apply_code strategy_name; run;

data dt.dt_rule;
set dt_rule;
run;


***TD分数;
data td_id_1;
set submart.loantd_submart(keep = execution_id apply_code);
run;
proc sort data = td_id_1; by apply_code; run;
data td_id_1;
merge dt(in = a) td_id_1(in = b);
by apply_code;
if a & b;
run;

data td_id_score;
set dpraw.td_risk_result(keep = id execution_id final_score);
rename id = risk_result_id;
run;
proc sql;
create table td_score as
select a.*, b.final_score
from td_id_1 as a
left join td_id_score as b
on a.execution_id = b.execution_id
;
quit;

data dt.td_score;
set td_score;
run;


/****申请距注册时间间隔;*/
/*data reg_apply_intvl;*/
/*set submart.applyvar_submart(keep = apply_code 申请距注册间隔 申请提交时点);*/
/*format grp_申请距注册 $20.;*/
/*	 if 0 < 申请距注册间隔 < 5 then grp_申请距注册 = "0. < 5分钟";*/
/*else if 5 <= 申请距注册间隔 < 10 then grp_申请距注册 = "1. 5 - <10分钟";*/
/*else if 10 <= 申请距注册间隔 < 15 then grp_申请距注册 = "2. 10 - <15分钟";*/
/*else if 15 <= 申请距注册间隔 < 20 then grp_申请距注册 = "3. 15 - <20分钟";*/
/*else if 20 <= 申请距注册间隔 < 30 then grp_申请距注册 = "4. 20 - <30分钟";*/
/*else if 30 <= 申请距注册间隔 < 60 then grp_申请距注册 = "5. 30 - <60分钟";*/
/*else if 申请距注册间隔 >= 60 then grp_申请距注册 = "6. >60分钟";*/
/*run;*/
/*proc sort data = reg_apply_intvl nodupkey; by apply_code; run;*/
/*data dt.dt_time_intvl;*/
/*merge dt(in = a) reg_apply_intvl(in = b);*/
/*by apply_code;*/
/*if a;*/
/*run;*/
/**/
