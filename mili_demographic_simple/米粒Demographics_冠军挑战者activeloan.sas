********************************************************************************************************************;

proc sql;
create table  bjb.active_loan as
select a.od_days,a.客户标签,a.账户标签,a.放款月份,b.*  from bjb.milipayment_report_demo(where=(cut_date=&dt.)) as a
left join  bjb.ml_Demograph as b on a.contract_no=b.apply_code;
quit;

**冠军;
data bjb.active_loan_activeloan_m_A;
set bjb.active_loan;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if loc_abmoduleflag = "A";
run;
**挑战者;
data bjb.active_loan_activeloan_m_B;
set bjb.active_loan;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if loc_abmoduleflag = "B";
run;

%macro demo_0(use_database,i);
%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set &use_database.;
format &var_name. $45.;
if strip(&var_name.)="" then &var_name.="z-Missing";
run;

proc tabulate data=use0 out=demo_res_&n.(drop=_TYPE_ _PAGE_ _TABLE_ );
class  &var_name. /missing;
var count;
table &var_name.
all,count*(N);
run;

data demo_&n.;
set demo_res_&n.;
format variable $45.;
format group $45.;
variable="&var_name.";
if &var_name.="" then group="小计";
else group=&var_name.;
drop  &var_name.;
run;

%if &n.=1 %then %do;
	data demo_res;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res;
	set demo_res demo_&n.;
	format variable $45.;
	run;
%end;
%end;
%mend;

%demo_0(use_database=bjb.active_loan_activeloan_m_A,i=116);
proc sql;
create table demo_res_active_A as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_A ;by id;run;

%demo_0(use_database=bjb.active_loan_activeloan_m_B,i=116);
proc sql;
create table demo_res_active_B as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_B ;by id;run;

**获取逾期5+天的;

data bjb.active_loan_activeloan_5_A;
set bjb.active_loan_activeloan_m_A;
if od5=1;
run;
data bjb.active_loan_activeloan_5_B;
set bjb.active_loan_activeloan_m_B;
if od5=1;
run;

%macro demo_0(use_database,i);
%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set &use_database.;
format &var_name. $45.;
if strip(&var_name.)="" then &var_name.="z-Missing";
run;

proc tabulate data=use0 out=demo_res_&n.(drop=_TYPE_ _PAGE_ _TABLE_ );
class  &var_name. /missing;
var count;
table &var_name. all,count*(N);
run;

data demo_&n.;
set demo_res_&n.;
format variable $45.;
format group $45.;
variable="&var_name.";
if &var_name.="" then group="小计";
else group=&var_name.;
drop  &var_name.;
run;

%if &n.=1 %then %do;
	data demo_res_ever15;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res_ever15;
	set demo_res_ever15 demo_&n.;
	format variable $45.;
	run;
%end;
%end;
%mend;

%demo_0(use_database=bjb.active_loan_activeloan_5_A,i=116);

proc sql;
create table demo_res_ever15_A as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_A ;by id;run;

%demo_0(use_database=bjb.active_loan_activeloan_5_B,i=116);
proc sql;
create table demo_res_ever15_B as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_B ;by id;run;

**获取逾期15+天的;

data bjb.active_loan_activeloan_15_A;
set bjb.active_loan_activeloan_m_A;
if od15=1;
run;
data bjb.active_loan_activeloan_15_B;
set bjb.active_loan_activeloan_m_B;
if od15=1;
run;


%macro demo_0(use_database,i);
%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set &use_database.;
format &var_name. $45.;
if strip(&var_name.)="" then &var_name.="z-Missing";
run;

proc tabulate data=use0 out=demo_res_&n.(drop=_TYPE_ _PAGE_ _TABLE_ );
class  &var_name. /missing;
var count;
table &var_name.
all,count*(N);
run;

data demo_&n.;
set demo_res_&n.;
format variable $45.;
format group $45.;
variable="&var_name.";
if &var_name.="" then group="小计";
else group=&var_name.;
drop  &var_name.;
run;

%if &n.=1 %then %do;
	data demo_res_900;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res_900;
	set demo_res_900 demo_&n.;
	format variable $45.;
	run;
%end;
%end;
%mend;

%demo_0(use_database=bjb.active_loan_activeloan_15_A,i=116);
proc sql;
create table demo_res_90_A as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_A ;by id;run;

%demo_0(use_database=bjb.active_loan_activeloan_15_B,i=116);
proc sql;
create table demo_res_90_B as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_B ;by id;run;

********************冠军;
/*x "F:\米粒Demographics\Monthly_Demographics(米粒_冠军).xlsx";*/

data demo_res_ever15_2_A;set demo_res_ever15_A;rename count_N=count_N_15;run;
data demo_res_90_2_A;set demo_res_90_A;rename count_N=count_N_90;run;

proc sort data=demo_res_active_A nodupkey;by id;run;
proc sort data=demo_res_ever15_2_A nodupkey;by id;run;
proc sort data=demo_res_90_2_A nodupkey;by id;run;
data demo_res_ods_A;
merge demo_res_active_A(in=a) demo_res_ever15_2_A(in=b) demo_res_90_2_A(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_A;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(米粒_冠军).xlsx]Active Loan!r5c3:r837c5';
data _null_;
set Work.demo_res_ods_A;
file DD;
put count_N count_N_15 count_N_90;
run;

*********************挑战者;
/*x "F:\米粒Demographics\Monthly_Demographics(米粒_挑战者).xlsx";*/

data demo_res_ever15_2_B;set demo_res_ever15_B;rename count_N=count_N_15;run;
data demo_res_90_2_B;set demo_res_90_B;rename count_N=count_N_90;run;

proc sort data=demo_res_active_B nodupkey;by id;run;
proc sort data=demo_res_ever15_2_B nodupkey;by id;run;
proc sort data=demo_res_90_2_B nodupkey;by id;run;

data demo_res_ods_B;
merge demo_res_active_B(in=a) demo_res_ever15_2_B(in=b) demo_res_90_2_B(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_B;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(米粒_挑战者).xlsx]Active Loan!r5c3:r837c5';
data _null_;
set Work.demo_res_ods_B;
file DD;
put count_N count_N_15 count_N_90;
run;
