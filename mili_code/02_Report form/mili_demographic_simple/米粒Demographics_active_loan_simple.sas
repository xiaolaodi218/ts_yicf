********************************************************************************************************************
*active_loan;
data benzi.active_loan_activeloan_m_all;
set benzi.active_loan;
/*if �����ύ��_g="1.1-5��" ;*/

/*if �����̨="7.11������" or �����ύ��_g="1.1-5��";*/
/*if DEGREE_NAME_g^="5.���м�����";*/

/*if ��Դ���� in ("qihu360","vivo","yingyongbao");*/

if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
run;
**���� �¿ͻ�;
data benzi.active_loan_activeloan_m_xz benzi.active_loan_activeloan_m_fd;
set benzi.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if ��������="�¿ͻ�����" then output benzi.active_loan_activeloan_m_xz;
else if �ͻ���ǩ^=1 then output benzi.active_loan_activeloan_m_fd;
run;
**�ھ�;
/*data benzi.active_loan_activeloan_m_A;*/
/*set benzi.active_loan;*/
/*if �˻���ǩ not in ("δ�ſ�","������");*/
/*if apply_code^="";*/
/*count=1;*/
/*if od_days>5 then od5=1;else od5=0;*/
/*if od_days>15 then od15=1;else od15=0;*/
/*if loc_abmoduleflag = "A";*/
/*run;*/
/***��ս��;*/
/*data benzi.active_loan_activeloan_m_B;*/
/*set benzi.active_loan;*/
/*if �˻���ǩ not in ("δ�ſ�","������");*/
/*if apply_code^="";*/
/*count=1;*/
/*if od_days>5 then od5=1;else od5=0;*/
/*if od_days>15 then od15=1;else od15=0;*/
/*if loc_abmoduleflag = "B";*/
/*run;*/

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
%demo_0(use_database=benzi.active_loan_activeloan_m_all,i=21);
proc sql;
create table demo_res_active_all as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_all ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_m_fd,i=21);
proc sql;
create table demo_res_active_fd as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_fd ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_m_xz,i=21);
proc sql;
create table demo_res_active_xz as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_active_xz ;by id;run;

/*%demo_0(use_database=benzi.active_loan_activeloan_m_A,i=21);*/
/*proc sql;*/
/*create table demo_res_active_A as*/
/*select a.*,b.count_N from var_name_left as a*/
/*left join demo_res as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_active_A ;by id;run;*/
/**/
/*%demo_0(use_database=benzi.active_loan_activeloan_m_B,i=20);*/
/*proc sql;*/
/*create table demo_res_active_B as*/
/*select a.*,b.count_N from var_name_left as a*/
/*left join demo_res as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_active_B ;by id;run;*/

**��ȡ����5+���;
data benzi.active_loan_activeloan_5_all;
set benzi.active_loan_activeloan_m_all;
if od5=1;
run;
data benzi.active_loan_activeloan_5_xz;
set benzi.active_loan_activeloan_m_xz;
if od5=1;
run;
data benzi.active_loan_activeloan_5_fd;
set benzi.active_loan_activeloan_m_fd;
if od5=1;
run;
/*data benzi.active_loan_activeloan_5_A;*/
/*set benzi.active_loan_activeloan_m_A;*/
/*if od5=1;*/
/*run;*/
/*data benzi.active_loan_activeloan_5_B;*/
/*set benzi.active_loan_activeloan_m_B;*/
/*if od5=1;*/
/*run;*/


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

%demo_0(use_database=benzi.active_loan_activeloan_5_all,i=21);
proc sql;
create table demo_res_ever15_all as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_all ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_5_xz,i=21);
proc sql;
create table demo_res_ever15_xz as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_xz ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_5_fd,i=21);
proc sql;
create table demo_res_ever15_fd as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ever15_fd ;by id;run;

/*%demo_0(use_database=benzi.active_loan_activeloan_5_A,i=21);*/
/*proc sql;*/
/*create table demo_res_ever15_A as*/
/*select a.*,b.count_N from var_name_left as a*/
/*left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_ever15_A ;by id;run;*/
/**/
/*%demo_0(use_database=benzi.active_loan_activeloan_5_B,i=21);*/
/*proc sql;*/
/*create table demo_res_ever15_B as*/
/*select a.*,b.count_N from var_name_left as a*/
/*left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_ever15_B ;by id;run;*/

**��ȡ����15+���;
data benzi.active_loan_activeloan_15_all;
set benzi.active_loan_activeloan_m_all;
if od15=1;
run;
data benzi.active_loan_activeloan_15_xz;
set benzi.active_loan_activeloan_m_xz;
if od15=1;
run;
data benzi.active_loan_activeloan_15_fd;
set benzi.active_loan_activeloan_m_fd;
if od15=1;
run;
/*data benzi.active_loan_activeloan_15_A;*/
/*set benzi.active_loan_activeloan_m_A;*/
/*if od15=1;*/
/*run;*/
/*data benzi.active_loan_activeloan_15_B;*/
/*set benzi.active_loan_activeloan_m_B;*/
/*if od15=1;*/
/*run;*/


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

%demo_0(use_database=benzi.active_loan_activeloan_15_all,i=21); 

proc sql;
create table demo_res_90_all as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_all ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_15_xz,i=21);
proc sql;
create table demo_res_90_xz as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_xz ;by id;run;

%demo_0(use_database=benzi.active_loan_activeloan_15_fd,i=21);
proc sql;
create table demo_res_90_fd as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_90_fd ;by id;run;

/*%demo_0(use_database=benzi.active_loan_activeloan_15_A,i=21);*/
/*proc sql;*/
/*create table demo_res_90_A as*/
/*select a.*,b.count_N from var_name_left as a*/
/*left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_90_A ;by id;run;*/
/**/
/*%demo_0(use_database=benzi.active_loan_activeloan_15_B,i=21);*/
/*proc sql;*/
/*create table demo_res_90_B as*/
/*select a.*,b.count_N from var_name_left as a*/
/*left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_90_B ;by id;run;*/

/*proc export data=demo_res_90*/
/*outfile="F:\WORK\Report\Demographics\output\&work_Day.\demo_res_ever_90_&work_Day..csv"*/
/*dbms=csv*/
/*replace;*/
/*delimiter=',';*/
/*run;*/

/*����active ever15+ ever90+*/

******************����;
/*x "F:\����Demographics\Monthly_Demographics(����_total).xlsx";*/

data demo_res_ever15_2_all;set demo_res_ever15_all;rename count_N=count_N_15;run;
data demo_res_90_2_all;set demo_res_90_all;rename count_N=count_N_90;run;
proc sort data=demo_res_active_all nodupkey;by id;run;
proc sort data=demo_res_ever15_2_all nodupkey;by id;run;
proc sort data=demo_res_90_2_all nodupkey;by id;run;
data demo_res_ods_all;
merge demo_res_active_all(in=a) demo_res_ever15_2_all(in=b) demo_res_90_2_all(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_all;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_total)_simple.xlsx]Active Loan!r5c3:r400c5';
data _null_;
set Work.demo_res_ods_all;
file DD;
put count_N count_N_15 count_N_90;
run;


**********************�¿ͻ�;
/*x "F:\����Demographics\Monthly_Demographics(����_�¿ͻ�).xlsx";*/

data demo_res_ever15_2_xz;set demo_res_ever15_xz;rename count_N=count_N_15;run;
data demo_res_90_2_xz;set demo_res_90_xz;rename count_N=count_N_90;run;
proc sort data=demo_res_active_xz nodupkey;by id;run;
proc sort data=demo_res_ever15_2_xz nodupkey;by id;run;
proc sort data=demo_res_90_2_xz nodupkey;by id;run;
data demo_res_ods_xz;
merge demo_res_active_xz(in=a) demo_res_ever15_2_xz(in=b) demo_res_90_2_xz(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_xz;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_�¿ͻ�)_simple.xlsx]Active Loan!r5c3:r400c5';
data _null_;
set Work.demo_res_ods_xz;
file DD;
put count_N count_N_15 count_N_90;
run;

*********************����;
/*x "F:\����Demographics\Monthly_Demographics(����_����).xlsx";*/

data demo_res_ever15_2_fd;set demo_res_ever15_fd;rename count_N=count_N_15;run;
data demo_res_90_2_fd;set demo_res_90_fd;rename count_N=count_N_90;run;
proc sort data=demo_res_active_fd nodupkey;by id;run;
proc sort data=demo_res_ever15_2_fd nodupkey;by id;run;
proc sort data=demo_res_90_2_fd nodupkey;by id;run;
data demo_res_ods_fd;
merge demo_res_active_fd(in=a) demo_res_ever15_2_fd(in=b) demo_res_90_2_fd(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_fd;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_����)_simple.xlsx]Active Loan!r5c3:r400c5';
data _null_;
set Work.demo_res_ods_fd;
file DD;
put count_N count_N_15 count_N_90;
run;



/*********************�ھ�;*/
/*/*x "F:\����Demographics\Monthly_Demographics(����_�ھ�).xlsx";*/*/
/**/
/*data demo_res_ever15_2_A;set demo_res_ever15_A;rename count_N=count_N_15;run;*/
/*data demo_res_90_2_A;set demo_res_90_A;rename count_N=count_N_90;run;*/
/*proc sort data=demo_res_active_A nodupkey;by id;run;*/
/*proc sort data=demo_res_ever15_2_A nodupkey;by id;run;*/
/*proc sort data=demo_res_90_2_A nodupkey;by id;run;*/
/*data demo_res_ods_A;*/
/*merge demo_res_active_A(in=a) demo_res_ever15_2_A(in=b) demo_res_90_2_A(in=c);*/
/*by id;*/
/*if a;*/
/*run;*/
/*proc sort data=demo_res_ods_A;by id;run;*/
/**/
/*filename DD DDE 'EXCEL|[Monthly_Demographics(����_�ھ�)_simple.xlsx]Active Loan!r5c3:r400c5';*/
/*data _null_;*/
/*set Work.demo_res_ods_A;*/
/*file DD;*/
/*put count_N count_N_15 count_N_90;*/
/*run;*/
/**/
/**********************��ս��;*/
/*/*x "F:\����Demographics\Monthly_Demographics(����_��ս��).xlsx";*/*/
/**/
/*data demo_res_ever15_2_B;set demo_res_ever15_B;rename count_N=count_N_15;run;*/
/*data demo_res_90_2_B;set demo_res_90_B;rename count_N=count_N_90;run;*/
/*proc sort data=demo_res_active_B nodupkey;by id;run;*/
/*proc sort data=demo_res_ever15_2_B nodupkey;by id;run;*/
/*proc sort data=demo_res_90_2_B nodupkey;by id;run;*/
/*data demo_res_ods_B;*/
/*merge demo_res_active_B(in=a) demo_res_ever15_2_B(in=b) demo_res_90_2_B(in=c);*/
/*by id;*/
/*if a;*/
/*run;*/
/*proc sort data=demo_res_ods_B;by id;run;*/
/**/
/*filename DD DDE 'EXCEL|[Monthly_Demographics(����_��ս��)_simple.xlsx]Active Loan!r5c3:r400c5';*/
/*data _null_;*/
/*set Work.demo_res_ods_B;*/
/*file DD;*/
/*put count_N count_N_15 count_N_90;*/
/*run;*/
