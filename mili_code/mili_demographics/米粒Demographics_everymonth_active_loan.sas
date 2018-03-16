********************************************************************************************************************
*every_month_active_loan;

**����;
data bjb.active_loan_every_m_all;
set bjb.active_loan;
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
data bjb.active_loan_every_m_xz bjb.active_loan_every_m_fd;
set bjb.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if �ͻ���ǩ=1 then output bjb.active_loan_every_m_xz;
else if �ͻ���ǩ^=1 then output bjb.active_loan_every_m_fd;
run;
**�ھ�;
data bjb.active_loan_every_m_A;
set bjb.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if loc_abmoduleflag = "A";
run;
**��ս��;
data bjb.active_loan_every_m_B;
set bjb.active_loan;
if �˻���ǩ not in ("δ�ſ�","������");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if loc_abmoduleflag = "B";
run;


***��һ�����ڷſ��µĺ����������ʹ��;
data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

proc sort data=bjb.milipayment_report_demo(keep= �ſ��·� loan_date cut_date where=(cut_date=&dt.))  out=month_list nodupkey;by �ſ��·� ;run;
proc sort data=month_list;by loan_date;run;
data _null_;
set month_list end=last;     
call symput ("month_"||compress(_n_),compress(�ſ��·�));        
if last then call symput("lcn",compress(_n_));
run;

***�����Ȳ�ֳ�ÿ���µı�Ȼ���������Ļ�����ѭ��122�Σ�����������

**��ʼ��ȡÿ����demo_res_active_ ������;
%macro demo_0(use_database,i,type);
%do k=1 %to &lcn.;

data use_kfc;
set &use_database.;
**��active_loan_activeloan_m_all���������·�;
if �ſ��·�=&&month_&k;
run;

%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
data use0;
set use_kfc;
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

proc sql;
create table &type&&month_&k as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=&type&&month_&k ;by id;run;

%end;
%mend;

%demo_0(use_database=bjb.active_loan_every_m_all,i=122,type=demo_res_active_all);

%demo_0(use_database=bjb.active_loan_every_m_fd,i=122,type=demo_res_active_fd);

%demo_0(use_database=bjb.active_loan_every_m_xz,i=122,type=demo_res_active_xz);

%demo_0(use_database=bjb.active_loan_every_m_A,i=122,type=demo_res_active_A);

%demo_0(use_database=bjb.active_loan_every_m_B,i=122,type=demo_res_active_B);

data bjb.active_loan_every_5_all;
set bjb.active_loan_every_m_all;
if od5=1;
run;

data bjb.active_loan_every_5_fd;
set bjb.active_loan_every_m_fd;
if od5=1;
run;

data bjb.active_loan_every_5_xz;
set bjb.active_loan_every_m_xz;
if od5=1;
run;

data bjb.active_loan_every_5_A;
set bjb.active_loan_every_m_A;
if od5=1;
run;

data bjb.active_loan_every_5_B;
set bjb.active_loan_every_m_B;
if od5=1;
run;


%macro demo_0(use_database,i,type);
%do k=1 %to &lcn.;

data use_kfd;
set &use_database;
if �ſ��·� = &&month_&k;
run;

%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set use_kfd;
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

proc sql;
create table &type&&month_&k as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=&type&&month_&k ;by id;run;
%end;
%mend;

%demo_0(use_database=bjb.active_loan_every_5_all,i=122,type=demo_res_ever15_all);

%demo_0(use_database=bjb.active_loan_every_5_fd,i=122,type=demo_res_ever15_fd);

%demo_0(use_database=bjb.active_loan_every_5_xz,i=122,type=demo_res_ever15_xz);

%demo_0(use_database=bjb.active_loan_every_5_A,i=122,type=demo_res_ever15_A);

%demo_0(use_database=bjb.active_loan_every_5_B,i=122,type=demo_res_ever15_B);

**��ʼ��ȡÿ���µ�demo_res_90_all_�ı�;

data bjb.active_loan_every_15_all;
set bjb.active_loan_every_m_all;
if od15=1;
run;
data bjb.active_loan_every_15_fd;
set bjb.active_loan_every_m_fd;
if od15=1;
run;
data bjb.active_loan_every_15_xz;
set bjb.active_loan_every_m_xz;
if od15=1;
run;
data bjb.active_loan_every_15_A;
set bjb.active_loan_every_m_A;
if od15=1;
run;
data bjb.active_loan_every_15_B;
set bjb.active_loan_every_m_B;
if od15=1;
run;

%macro demo_0(use_database,i,type);
%do k=1 %to &lcn.;

data use_kfe;
set &use_database;
if �ſ��·� = &&month_&k;
run;

%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set use_kfe;
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
proc sql;
create table &type&&month_&k as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=&type&&month_&k ;by id;run;
%end;
%mend;

%demo_0(use_database=bjb.active_loan_every_15_all,i=122,type=demo_res_90_all); 

%demo_0(use_database=bjb.active_loan_activeloan_15_fd,i=122,type=demo_res_90_fd);

%demo_0(use_database=bjb.active_loan_activeloan_15_xz,i=122,type=demo_res_90_xz);

%demo_0(use_database=bjb.active_loan_activeloan_15_A,i=122,type=demo_res_90_A);

%demo_0(use_database=bjb.active_loan_activeloan_15_B,i=122,type=demo_res_90_B);



**���ϲ�ÿ���µ����ݼ�;
**����;
%macro demo_1();
%do k=1 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_all&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_all&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_all&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_all_&&month_&k;
merge demo_res_active_all&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_all_&&month_&k;by id;run;

/*x "F:\����Demographics\Monthly_Demographics(����_total).xlsx";*/

filename DD DDE "EXCEL|[Monthly_Demographics(����_total).xlsx]&&month_&k.!r5c3:r1000c5";
data _null_;
set Work.demo_res_ods_all_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_1();

**fd;
%macro demo_2();
%do k=1 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_fd&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_fd&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_fd&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_fd_&&month_&k;
merge demo_res_active_fd&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_fd_&&month_&k;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(����_����).xlsx]&&month_&k.!r5c3:r1000c5";
data _null_;
set Work.demo_res_ods_fd_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_2();

**xz;
%macro demo_3();
%do k=1 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_xz&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_xz&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_xz&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_xz_&&month_&k;
merge demo_res_active_xz&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_xz_&&month_&k;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(����_�¿ͻ�).xlsx]&&month_&k.!r5c3:r1000c5";
data _null_;
set Work.demo_res_ods_xz_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_3();

**�ھ�;
%macro demo_4();
%do k=7 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_A&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_B&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_A&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_A_&&month_&k;
merge demo_res_active_A&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_A_&&month_&k;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(����_�ھ�).xlsx]&&month_&k.!r5c3:r1000c5";
data _null_;
set Work.demo_res_ods_A_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_4();

**��ս��;
%macro demo_5();
%do k=7 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_B&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_B&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_B&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_B_&&month_&k;
merge demo_res_active_B&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_B_&&month_&k;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(����_��ս��).xlsx]&&month_&k.!r5c3:r1000c5";
data _null_;
set Work.demo_res_ods_B_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_5();


/*����sheet201612*/
/*data demo_res_ever15_2_201612;set Demo_res_ever15_all_201612;rename count_N=count_N_15;run;*/
/*data demo_res_90_2_201612;set Demo_res_90_all_201612;rename count_N=count_N_90;run;*/
/**/
/*proc sort data=demo_res_active_201612 nodupkey;by id;run;*/
/*proc sort data=demo_res_ever15_2_201612 nodupkey;by id;run;*/
/*proc sort data=demo_res_90_2_201612 nodupkey;by id;run;*/
/**/
/*data demo_res_ods_201612;*/
/*merge demo_res_active_all(in=a) demo_res_ever15_2_all(in=b) demo_res_90_2_all(in=c);*/
/*by id;*/
/*if a;*/
/*run;*/
/*proc sort data=demo_res_ods_all_201612;by id;run;*/
