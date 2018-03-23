*****************************************
	���붩�����еĹ���������
*****************************************;
option compress = yes validvarname = any;

libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";
libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";
libname dt "C:\Users\lenovo\Document\TS\Datamart\��������\���ڿͻ����е����й���";

***��Ҫ�鿴���й�������붩��;
/*data dt;*/
/*set dt.mili_yuqitest(keep = contract_no loan_date �������� CURR_RECEIVE_CAPITAL_AMT od_days ����������� BORROWER_TEL_ONE);*/
/*if od_days > 3 or ����������� > 4;*/
/*������������ = ����������� - 1;*/
/*�ſ����� = put(loan_date, yymmdd10.);*/
/*rename contract_no = apply_code CURR_RECEIVE_CAPITAL_AMT = ����� od_days = ��ǰ��������; */
/*drop ����������� loan_date;*/
/*run;*/
data dt;
set submart.mili_bill_main(keep = contract_no overdue_days bill_status CH_NAME where = (bill_status ^= "0001"));
	 if bill_status = "0002" and overdue_days > 5 then �������� = "��ǰ����5+"; 
else if overdue_days > 5 then �������� = "��������5+";
else �������� = "����";
rename contract_no = apply_code;
run;
proc sort data = dt nodupkey; by apply_code; run;


***BR���й���;
data br_rule;
set submart.BQSrule_br_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = br_rule; by apply_code; run;
data dt_br_rule;
merge dt(in = a) br_rule(in = b);
by apply_code;
if a;
run;

***ʧ�ŷ������й���;
data shixin_rule;
set submart.BQSrule_shixin_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = shixin_rule; by apply_code; run;
data dt_shixin_rule;
merge dt(in = a) shixin_rule(in = b);
by apply_code;
if a;
run;

***�����������й���;
data jbgz_rule;
set submart.BQSrule_jbgz_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = jbgz_rule; by apply_code; run;
data dt_jbgz_rule;
merge dt(in = a) jbgz_rule(in = b);
by apply_code;
if a;
run;

***JXL���й���;
data jxl_rule;
set submart.BQSrule_jxl_submart(keep = apply_code strategy_name rule_name_normal rule_decision);
run;
proc sort data = jxl_rule; by apply_code; run;
data dt_jxl_rule;
merge dt(in = a) jxl_rule(in = b);
by apply_code;
if a;
run;

***EYSQ���й���;
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

***TD���й���;
data td_rule;
set submart.Tdrule_submart(keep = apply_code rule_name rule_score);
rename rule_name = rule_name_normal rule_score = decision;
strategy_name = "ͬ��";
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


***TD����;
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


/****�����ע��ʱ����;*/
/*data reg_apply_intvl;*/
/*set submart.applyvar_submart(keep = apply_code �����ע���� �����ύʱ��);*/
/*format grp_�����ע�� $20.;*/
/*	 if 0 < �����ע���� < 5 then grp_�����ע�� = "0. < 5����";*/
/*else if 5 <= �����ע���� < 10 then grp_�����ע�� = "1. 5 - <10����";*/
/*else if 10 <= �����ע���� < 15 then grp_�����ע�� = "2. 10 - <15����";*/
/*else if 15 <= �����ע���� < 20 then grp_�����ע�� = "3. 15 - <20����";*/
/*else if 20 <= �����ע���� < 30 then grp_�����ע�� = "4. 20 - <30����";*/
/*else if 30 <= �����ע���� < 60 then grp_�����ע�� = "5. 30 - <60����";*/
/*else if �����ע���� >= 60 then grp_�����ע�� = "6. >60����";*/
/*run;*/
/*proc sort data = reg_apply_intvl nodupkey; by apply_code; run;*/
/*data dt.dt_time_intvl;*/
/*merge dt(in = a) reg_apply_intvl(in = b);*/
/*by apply_code;*/
/*if a;*/
/*run;*/
/**/
