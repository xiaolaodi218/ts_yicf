*****************************************
	BQS��������������
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

/*Hash����*/
%macro InitVariableInDataset(dataset,withoutvar, withoutvar2='');

	%local dsid i nvar vname vtype rc strN strC;
	%let strN = %str(=.;);
	%let strC = %str(='';);
	%let dsid = %sysfunc(open(&dataset));
	%if &dsid %then
		%do;
			%let nvar = %sysfunc(attrn(&dsid,NVARS));
%*			%put &nvar;
		   	%do i = 1 %to &nvar;
		      %let vname = %sysfunc(varname(&dsid,&i));
			  %if %UPCASE(&vname) ^= %UPCASE(&withoutvar) 
				and %UPCASE(&vname) ^= %UPCASE(&withoutvar2) %then %do;
			      %let vtype = %sysfunc(vartype(&dsid,&i));
	%*			  	%put _%sysfunc(compress(&vtype))_;
				  %if %sysfunc(compress(&vtype)) = N %then %do;
&vname &strN; 
				  %end; %else %do;
&vname &strC;
				  %end;

			  %end;
		   	%end;

			%let rc = %sysfunc(close(&dsid));
		%end;
	%else %put %sysfunc(sysmsg());

%mend;

data rule_map;
set submart.rule_map;
run;

data bqs_hit_rule;
set dpRaw.bqs_hit_rule;
rename decision = rule_decision score = rule_score;
���������·� = put(datepart(last_updated), yymmn6.);
������������ = put(datepart(last_updated), yymmdd10.);
rule_code = substr(rule_name, 1, 7);
drop last_updated;
run;

data invoke_record;
set submart.invoke_record;
keep invoke_record_id event_type os_type apply_code;
run;

***���붩����������ǩ�����Ƿ񸴴�;
data apply_flag;
set submart.apply_submart(keep = apply_code ��������);
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

proc sort data = invoke_record; by apply_code; run;
data invoke_record;
merge invoke_record(in = a) apply_flag(in = b);
by apply_code;
if a;
run;

data strategy_execution;
set submart.strategy_execution;
keep execution_id invoke_record_id event_name;
run;

proc sql;
create table invoke_execution as
select a.*, b.execution_id, b.event_name
from invoke_record as a left join 
strategy_execution as b on a.invoke_record_id = b.invoke_record_id
where execution_id ^= .
;
quit;

data bqs_main_info;
set dpRaw.bqs_main_info(keep = id execution_id);
rename id = main_info_id;
run;
proc sort data = bqs_main_info nodupkey; by execution_id descending main_info_id; run;
proc sort data = bqs_main_info nodupkey; by execution_id; run;

proc sql;
create table invoke_exec as
select a.event_type, a.event_name, a.os_type, a.��������, a.apply_code, b.main_info_id
from invoke_execution as a left join 
bqs_main_info as b on a.execution_id = b.execution_id
;
quit;

data bqs_strategy;
set dpRaw.bqs_strategy_result(keep = id strategy_name main_info_id);
run;

proc sql;
create table bqs_strategy_result as
select a.*, b.event_type, b.event_name, b.os_type, b.��������, b.apply_code
from bqs_strategy as a
left join invoke_exec as b on a.main_info_id = b.main_info_id
;
quit;

%macro hit_rule(scode, sname);

data &scode._rule;
set bqs_strategy_result(where = (strategy_name = &sname.));
rename id = strategy_result_id;
run;
proc sort data = &scode._rule nodupkey; by strategy_result_id; run;

data &scode._hit_rule;
if _n_=1 then do;
	if 0 then set &scode._rule;
	declare hash map (dataset:"&scode._rule");
	map.definekey("strategy_result_id");
	map.definedata(All:"yes");
	map.definedone();
end;

set bqs_hit_rule;
	rt=map.find(key:strategy_result_id);
	if rt=0 then do; end;
	else do; delete; end;
drop rt;
run;

data &scode._submart;
if _n_=1 then do;
	if 0 then set rule_map;
	declare hash map (dataset:"rule_map");
	map.definekey("rule_code");
	map.definedata(All:"yes");
	map.definedone();
end;

set &scode._hit_rule;
	rt=map.find(key:rule_code);
	if rt=0 then do; end;
	else do; %InitVariableInDataset(rule_map,rule_code); end;
drop rt;
run;

data submart.BQSrule_&scode._submart;
set &scode._submart;
if length(rule_name) > klength(rule_name) then rule_name_normal = rule_name;
run;
%mend;
%hit_rule(jbgz,"�����������");
%hit_rule(jxl,"JXL����");
%hit_rule(llkz,"�������Ʋ���");
%hit_rule(eysq,"�����������");
%hit_rule(ycsq,"�쳣�������");
%hit_rule(fsyys,"FSYYS����");
%hit_rule(fsds,"FSDS����");
%hit_rule(shixin,"ʧ�ŷ��ղ���");
%hit_rule(br,"BR����");
%hit_rule(gk,"�ܿ���������");
%hit_rule(face,"�����ȶԲ���");
%hit_rule(ivs,"IVS����");
%hit_rule(glgz,"�����������");
%hit_rule(fdjbgz,"���������������");
%hit_rule(fdzr,"����׼�����");
%hit_rule(mddh,"ͨ������");

%hit_rule(fsyys_B,"FSYYS����_��ս��");
%hit_rule(fsyys_BASE,"FSYYS����_BASE");
%hit_rule(fsyys_AAA,"FSYYS����_AAA");
%hit_rule(fsyys_BBB,"FSYYS����_BBB");
%hit_rule(fsyys_CCC,"FSYYS����_CCC");

%hit_rule(jbgz_B,"�����������_��ս��");
%hit_rule(jbgz_BASE,"�����������_BASE");
%hit_rule(jbgz_AAA,"�����������_AAA");
%hit_rule(jbgz_BBB,"�����������_BBB");

**��������;
%hit_rule(jbgz_zw,"�����������_ZW");
%hit_rule(fsyys_zw,"FSYYS����_ZW");
%hit_rule(sxfx_zw,"ʧ�ŷ��ղ���_ZW");
%hit_rule(br_zw,"BR����_ZW");
%hit_rule(eysq_zw,"�����������_ZW");
%hit_rule(glgz_zw,"�����������_ZW");

 
 
 
/****��������;*/
/*data jbgz_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "�����������"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = jbgz_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table jbgz_hit_rule as*/
/*select a.*, b.**/
/*from jbgz_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_jbgz_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set jbgz_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_jbgz_submart;*/
/*set loanloan_jbgz_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****JXL����;*/
/*data jxl_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "JXL����"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = jxl_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table jxl_hit_rule as*/
/*select a.*, b.**/
/*from jxl_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_jxl_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set jxl_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_jxl_submart;*/
/*set loanloan_jxl_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/****�������ƹ���;*/
/*data llkz_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "�������Ʋ���"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = llkz_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table llkz_hit_rule as*/
/*select a.*, b.**/
/*from llkz_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_llkz_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set llkz_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_llkz_submart;*/
/*set loanloan_llkz_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/****�����������;*/
/*data eysq_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "�����������"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = eysq_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table eysq_hit_rule as*/
/*select a.*, b.**/
/*from eysq_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_eysq_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set eysq_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_eysq_submart;*/
/*set loanloan_eysq_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****�쳣�������;*/
/*data ycsq_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "�쳣�������"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = ycsq_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table ycsq_hit_rule as*/
/*select a.*, b.**/
/*from ycsq_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_ycsq_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set ycsq_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_ycsq_submart;*/
/*set loanloan_ycsq_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****FSYYS���Թ���;*/
/*data fsyys_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "FSYYS����"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = fsyys_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table fsyys_hit_rule as*/
/*select a.*, b.**/
/*from fsyys_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_fsyys_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set fsyys_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_fsyys_submart;*/
/*set loanloan_fsyys_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****FSDS���Թ���;*/
/*data fsds_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "FSDS����"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = fsds_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table fsds_hit_rule as*/
/*select a.*, b.**/
/*from fsds_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanloan_fsds_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set fsds_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_fsds_submart;*/
/*set loanloan_fsds_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****ʧ�ŷ��չ���;*/
/*data shixin_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "ʧ�ŷ��ղ���"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = shixin_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table shixin_hit_rule as*/
/*select a.*, b.**/
/*from shixin_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanblk_shixin_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set shixin_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_shixin_submart;*/
/*set loanblk_shixin_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/****BR����;*/
/*data br_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "BR����"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = br_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table br_hit_rule as*/
/*select a.*, b.**/
/*from br_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanblk_br_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set br_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_br_submart;*/
/*set loanblk_br_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/****�ܿع���;*/
/*data gk_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "�ܿ���������"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = gk_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table gk_hit_rule as*/
/*select a.*, b.**/
/*from gk_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanblk_gk_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set gk_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_gk_submart;*/
/*set loanblk_gk_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****�����ȶԹ���;*/
/*data face_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "�����ȶԲ���"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = face_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table face_hit_rule as*/
/*select a.*, b.**/
/*from face_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanface_face_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set face_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_face_submart;*/
/*set loanface_face_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/
/**/
/**/
/****IVS����;*/
/*data ivs_rule;*/
/*set bqs_strategy_result(where = (strategy_name = "IVS����"));*/
/*rename id = strategy_result_id;*/
/*run;*/
/*proc sort data = ivs_rule nodupkey; by strategy_result_id; run;*/
/**/
/*proc sql;*/
/*create table ivs_hit_rule as*/
/*select a.*, b.**/
/*from ivs_rule as a left join */
/*bqs_hit_rule as b on a.strategy_result_id = b.strategy_result_id*/
/*;*/
/*quit;*/
/**/
/*data loanivs_ivs_submart;*/
/*if _n_=1 then do;*/
/*	if 0 then set rule_map;*/
/*	declare hash map (dataset:"rule_map");*/
/*	map.definekey("rule_code");*/
/*	map.definedata(All:"yes");*/
/*	map.definedone();*/
/*end;*/
/**/
/*set ivs_hit_rule;*/
/*	rt=map.find(key:rule_code);*/
/*	if rt=0 then do; end;*/
/*	else do; %InitVariableInDataset(rule_map,rule_code); end;*/
/*drop rt;*/
/*run;*/
/**/
/*data submart.BQSrule_ivs_submart;*/
/*set loanivs_ivs_submart;*/
/*if rule_name_normal = "" then rule_name_normal = rule_name;*/
/*run;*/

