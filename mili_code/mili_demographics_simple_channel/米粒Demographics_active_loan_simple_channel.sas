********************************************************************************************************************;

*active_loan;
***����1;
data benzi.active_loan_activeloan_m_chanel1;
set benzi.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
**ɸѡ�¿ͻ�;
if ��������="�¿ͻ�����";
**���������ǩ��ɸѡ���ܾ��ͻ������ͼ��ٴ�����;/*if �ͻ���ǩ=1;*/
if ������ǩ=1;
run;

**����2;
data benzi.active_loan_activeloan_m_chanel2;
set benzi.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
**ɸѡ�¿ͻ�;
if ��������="�¿ͻ�����";
if ������ǩ=2;
run;

**����3;
data benzi.active_loan_activeloan_m_chanel3;
set benzi.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
**ɸѡ�¿ͻ�;
if ��������="�¿ͻ�����";
if ������ǩ=3;
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
if &var_name.="" then group="С��";
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
%demo_0(use_database=benzi.active_loan_activeloan_m_chanel1,i=21);
proc sql;
create table demo_res_active_chanel1 as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_chanel1 ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_m_chanel2,i=21);
proc sql;
create table demo_res_active_chanel2 as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_chanel2 ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_m_chanel3,i=21);
proc sql;
create table demo_res_active_chanel3 as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_chanel3;by id;run;


**��ȡ����5+���;
data benzi.active_loan_activeloan_5_chanel1;
set benzi.active_loan_activeloan_m_chanel1;
if od5=1;
run;
data benzi.active_loan_activeloan_5_chanel2;
set benzi.active_loan_activeloan_m_chanel2;
if od5=1;
run;
data benzi.active_loan_activeloan_5_chanel3;
set benzi.active_loan_activeloan_m_chanel3;
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
if &var_name.="" then group="С��";
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

%demo_0(use_database=benzi.active_loan_activeloan_5_chanel1,i=21);
proc sql;
create table demo_res_ever15_chanel1 as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_chanel1 ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_5_chanel2,i=21);
proc sql;
create table demo_res_ever15_chanel2 as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_chanel2 ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_5_chanel3,i=21);
proc sql;
create table demo_res_ever15_chanel3 as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_chanel3 ;by id;run;


**��ȡ����15+���;
data benzi.activeloan_activeloan_15_chanel1;
set benzi.active_loan_activeloan_m_chanel1;
if od15=1;
run;
data benzi.activeloan_activeloan_15_chanel2;
set benzi.active_loan_activeloan_m_chanel2;
if od15=1;
run;
data benzi.activeloan_activeloan_15_chanel3;
set benzi.active_loan_activeloan_m_chanel3;
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
if &var_name.="" then group="С��";
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

%demo_0(use_database=benzi.activeloan_activeloan_15_chanel1,i=21); 
proc sql;
create table demo_res_90_chanel1 as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_chanel1 ;by id;run;

%demo_0(use_database=benzi.activeloan_activeloan_15_chanel2,i=21);
proc sql;
create table demo_res_90_chanel2 as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_chanel2 ;by id;run;

%demo_0(use_database=benzi.activeloan_activeloan_15_chanel3,i=21);
proc sql;
create table demo_res_90_chanel3 as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_chanel3 ;by id;run;

/*proc export data=demo_res_90*/
/*outfile="F:\WORK\Report\Demographics\output\&work_Day.\demo_res_ever_90_&work_Day..csv"*/
/*dbms=csv*/
/*replace;*/
/*delimiter=',';*/
/*run;*/

/*����active ever15+ ever90+*/

******************����1;
/*x "F:\����Demographics\Monthly_Demographics(����_total).xlsx";*/

data demo_res_ever15_2_chanel1;set demo_res_ever15_chanel1;rename count_N=count_N_15;run;
data demo_res_90_2_chanel1;set demo_res_90_chanel1;rename count_N=count_N_90;run;
proc sort data=demo_res_active_chanel1 nodupkey;by id;run;
proc sort data=demo_res_ever15_2_chanel1 nodupkey;by id;run;
proc sort data=demo_res_90_2_chanel1 nodupkey;by id;run;
data demo_res_ods_chanel1;
merge demo_res_active_chanel1(in=a) demo_res_ever15_2_chanel1(in=b) demo_res_90_2_chanel1(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_chanel1;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(����1)_simple.xlsx]Active Loan!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel1;
file DD;
put count_N count_N_15 count_N_90;
run;


**********************����2;
/*x "F:\����Demographics\Monthly_Demographics(����_�¿ͻ�).xlsx";*/

data demo_res_ever15_2_chanel2;set demo_res_ever15_chanel2;rename count_N=count_N_15;run;
data demo_res_90_2_chanel2;set demo_res_90_chanel2;rename count_N=count_N_90;run;
proc sort data=demo_res_active_chanel2 nodupkey;by id;run;
proc sort data=demo_res_ever15_2_chanel2 nodupkey;by id;run;
proc sort data=demo_res_90_2_chanel2 nodupkey;by id;run;
data demo_res_ods_chanel2;
merge demo_res_active_chanel2(in=a) demo_res_ever15_2_chanel2(in=b) demo_res_90_2_chanel2(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_chanel2;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(����2)_simple.xlsx]Active Loan!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel2;
file DD;
put count_N count_N_15 count_N_90;
run;

*********************����3;
/*x "F:\����Demographics\Monthly_Demographics(����_����).xlsx";*/

data demo_res_ever15_2_chanel3;set demo_res_ever15_chanel3;rename count_N=count_N_15;run;
data demo_res_90_2_chanel3;set demo_res_90_chanel3;rename count_N=count_N_90;run;
proc sort data=demo_res_active_chanel3 nodupkey;by id;run;
proc sort data=demo_res_ever15_2_chanel3 nodupkey;by id;run;
proc sort data=demo_res_90_2_chanel3 nodupkey;by id;run;
data demo_res_ods_chanel3;
merge demo_res_active_chanel3(in=a) demo_res_ever15_2_chanel3(in=b) demo_res_90_2_chanel3(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_chanel3;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����3)_simple.xlsx]Active Loan!r5c3:r400c5';
data _null_;
set Work.demo_res_ods_chanel3;
file DD;
put count_N count_N_15 count_N_90;
run;
