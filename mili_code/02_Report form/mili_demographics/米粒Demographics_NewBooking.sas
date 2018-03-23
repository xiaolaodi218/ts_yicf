****************************************************************************************************************
***NewBooking����
*nb_rate_�˹�;

data bjb.ml_Demograph2_all;
set bjb.ml_Demograph;
*���Ӧ�ûᵼ�²�ͬʱ����demo��ͬͨ����;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
/*if ��Դ���� in ("appstore");*/
if ��˴�����<=&dt.;
run;

**�õ��������¿ͻ������ݼ�;
data bjb.ml_Demograph2_xz bjb.ml_Demograph2_fd;
set bjb.ml_Demograph;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
if ��������=1 then output bjb.ml_Demograph2_fd;
else if ��������^=1 then output bjb.ml_Demograph2_xz;
if ��˴�����<=&dt.;
run;

*�õ��ھ������ݼ�;
data bjb.ml_Demograph2_A;
set bjb.ml_Demograph;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
if loc_abmoduleflag="A";
if ��˴�����<=&dt.;
run;

*�õ���ս�ߵ����ݼ�;
data bjb.ml_Demograph2_B;
set bjb.ml_Demograph;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
if loc_abmoduleflag = "B";
if �����ύ��<=&dt.;
run;

%macro demo_0(use_database,class_g,i);
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
class &class_g. &var_name. /missing;
var check_final;
table &var_name.
all,&class_g.*check_final*(sum N);
run;

data demo_res_&n.;
set demo_res_&n.;
approval_rate=check_final_Sum/check_final_N;
run;
 
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=Rg;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var approval_rate;
run;

data demo_&n.;
set demo_&n.;
format Group $45.;
format variable $45.;
variable="&var_name.";
if &var_name.="" then group="С��";
else group=&var_name.;
drop _NAME_ &var_name.;
run;

%if &n=1 %then %do;
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

%demo_0(use_database=bjb.ml_Demograph2_all,class_g=��˴����·�,i=122);
data demo_res_appr_all;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_all as
select a.*,b.Rg201707 from var_name_left as a
left join demo_res_appr_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_all ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_xz,class_g=��˴����·�,i=122);
data demo_res_appr_xz;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_xz as
select a.*,b.Rg201707 from var_name_left as a
left join demo_res_appr_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_xz ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_fd,class_g=��˴����·�,i=122);
data demo_res_appr_fd;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_fd as
select a.*,b.Rg201707 from var_name_left as a
left join demo_res_appr_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_fd ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_A,class_g=��˴����·�,i=122);
data demo_res_appr_A;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_A as
select a.*,b.Rg201707 from var_name_left as a
left join demo_res_appr_A as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_A ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_B,class_g=��˴����·�,i=122);
data demo_res_appr_B;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_B as
select a.*,b.Rg201707 from var_name_left as a
left join demo_res_appr_B as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_B ;by id;run;

*nb_rate_�ܵ�;
data bjb.ml_Demograph2_all;
set bjb.ml_Demograph;
*���Ӧ�ûᵼ�²�ͬʱ����demo��ͬͨ����;
if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;

/*if ��Դ���� in ("appstore");*/
if ��˴�����<=&dt.;
run;

**nb_rate_�¿ͻ��͸����ͻ�;
data bjb.ml_Demograph2_xz bjb.ml_Demograph2_fd;
set bjb.ml_Demograph;

if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;
if ��������=1 then output bjb.ml_Demograph2_fd;
else if ��������^=1 then output bjb.ml_Demograph2_xz;
if ��˴�����<=&dt.;
run;

**nb_rate_�ھ�;
data bjb.ml_Demograph2_A;
set bjb.ml_Demograph;
if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;
if loc_abmoduleflag="A";
if ��˴�����<=&dt.;
run;

**nb_rate_��ս��;
data bjb.ml_Demograph2_B;
set bjb.ml_Demograph;
if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;
if loc_abmoduleflag="B";
if ��˴�����<=&dt.;
run;

%macro demo_0(use_database,class_g,i);
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
class &class_g. &var_name. /missing;
var check_final_all;
table &var_name.
all,&class_g.*check_final_all*(sum N);
run;

data demo_res_&n.;
set demo_res_&n.;
approval_rate=check_final_all_Sum/check_final_all_N;
run;
 
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=R;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var approval_rate;
run;

data demo_&n.;
set demo_&n.;
format Group $45.;
format variable $45.;
variable="&var_name.";
if &var_name.="" then group="С��";
else group=&var_name.;
drop _NAME_ &var_name.;
run;

%if &n=1 %then %do;
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

%demo_0(use_database=bjb.ml_Demograph2_all,class_g=��˴����·�,i=122);
data demo_res_appr_all;set demo_res;run;
proc sql;
create table demo_res_appr_2_all as
select a.*,b.R201707 from var_name_left as a
left join demo_res_appr_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_all ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_xz,class_g=��˴����·�,i=122);
data demo_res_appr_xz;set demo_res;run;
proc sql;
create table demo_res_appr_2_xz as
select a.*,b.R201707 from var_name_left as a
left join demo_res_appr_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_xz ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_fd,class_g=��˴����·�,i=122);
data demo_res_appr_fd;set demo_res;run;
proc sql;
create table demo_res_appr_2_fd as
select a.*,b.R201707 from var_name_left as a
left join demo_res_appr_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_fd ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_A,class_g=��˴����·�,i=122);
data demo_res_appr_A;set demo_res;run;
proc sql;
create table demo_res_appr_2_A as
select a.*,b.R201707 from var_name_left as a
left join demo_res_appr_A as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_A ;by id;run;

%demo_0(use_database=bjb.ml_Demograph2_B,class_g=��˴����·�,i=122);
data demo_res_appr_B;set demo_res;run;
proc sql;
create table demo_res_appr_2_B as
select a.*,b.R201707 from var_name_left as a
left join demo_res_appr_B as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_B ;by id;run;

proc sql;
create table  bjb.active_loan as
select a.od_days,a.�ͻ���ǩ,a.�˻���ǩ,a.�ſ��·�,b.*  from bjb.milipayment_report_demo(where=(cut_date=&dt.)) as a
left join  bjb.ml_Demograph as b on a.contract_no=b.apply_code;
quit;
*nb_loan;
*δ�ſ�������cut_date=&dt.�Ѿ�ȷ���˷ſ����ݵĽ�ֹ������;
data bjb.active_loan_nb_all;
set bjb.active_loan;
if �˻���ǩ^="δ�ſ�";
/*if ��Դ���� in ("qihu360","vivo","yingyongbao");*/
count=1;
run;
**�¿ͻ��͸���;
data bjb.active_loan_nb_xz bjb.active_loan_nb_fd ;
set bjb.active_loan;
if �˻���ǩ^="δ�ſ�";
count=1;
if �ͻ���ǩ=1 then output bjb.active_loan_nb_xz;
else if �ͻ���ǩ^=1 then output bjb.active_loan_nb_fd;
run;
**�ھ�;
data bjb.active_loan_nb_A;
set bjb.active_loan;
if �˻���ǩ^="δ�ſ�";
count=1;
if loc_abmoduleflag="A";
run;
**��ս��;
data bjb.active_loan_nb_B;
set bjb.active_loan;
if �˻���ǩ^="δ�ſ�";
count=1;
if loc_abmoduleflag="B";
run;


%macro demo_0(use_database,class_g,i);
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
class &class_g. &var_name. /missing;
var count;
table &var_name.
all,&class_g.*count*(N);
run;
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=L;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var count_N;
run;

data demo_&n.;
set demo_&n.;
format Group $45.;
format variable $45.;
variable="&var_name.";
if &var_name.="" then group="С��";
else group=&var_name.;
drop _NAME_ &var_name.;
run;

%if &n=1 %then %do;
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

%demo_0(use_database=bjb.active_loan_nb_all,class_g=�ſ��·�,i=122);
data demo_res_loan_all;set demo_res;run;
proc sql;
create table demo_res_loan_2_all as
select a.*,b.L201707 from var_name_left as a
left join demo_res_loan_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_all ;by id;run;

%demo_0(use_database=bjb.active_loan_nb_xz,class_g=�ſ��·�,i=122);
data demo_res_loan_xz;set demo_res;run;
proc sql;
create table demo_res_loan_2_xz as
select a.*,b.L201707 from var_name_left as a
left join demo_res_loan_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_xz ;by id;run;

%demo_0(use_database=bjb.active_loan_nb_fd,class_g=�ſ��·�,i=122);
data demo_res_loan_fd;set demo_res;run;
proc sql;
create table demo_res_loan_2_fd as
select a.*,b.L201707 from var_name_left as a
left join demo_res_loan_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_fd ;by id;run;

%demo_0(use_database=bjb.active_loan_nb_A,class_g=�ſ��·�,i=122);
data demo_res_loan_A;set demo_res;run;
proc sql;
create table demo_res_loan_2_A as
select a.*,b.L201707 from var_name_left as a
left join demo_res_loan_A as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_A ;by id;run;

%demo_0(use_database=bjb.active_loan_nb_B,class_g=�ſ��·�,i=122);
data demo_res_loan_B;set demo_res;run;
proc sql;
create table demo_res_loan_2_B as
select a.*,b.L201707 from var_name_left as a
left join demo_res_loan_B as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_B ;by id;run;


*****������Ҫ�޸�;
*���ܻ�����⼸�����ά�Ȳ�ͬ��5��17��ʱ������ˣ����������Բ���;

/*x "F:\����Demographics\Monthly_Demographics(����_total).xlsx";*/
**demo_res_NB_all_auto;
data demo_res_NB_all_auto;
merge demo_res_loan_2_all(in=a) demo_res_appr_2_all(in=b) demo_res_appr_2_rg_all(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_all_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����_total).xlsx]NewBooking!r5c27:r1000c29';
data _null_;
set Work.demo_res_NB_all_auto;
file DD;
put L201707 R201707 Rg201707;
run;


/*x "F:\����Demographics\Monthly_Demographics(����_�¿ͻ�).xlsx";*/
**demo_res_NB_xz_auto;
data demo_res_NB_xz_auto;
merge demo_res_loan_2_xz(in=a) demo_res_appr_2_xz(in=b) demo_res_appr_2_rg_xz(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_xz_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����_�¿ͻ�).xlsx]NewBooking!r5c27:r1000c29';
data _null_;
set Work.demo_res_NB_xz_auto;
file DD;
put L201707 R201707 Rg201707;
run;


/*x "F:\����Demographics\Monthly_Demographics(����_����).xlsx";*/
**demo_res_NB_fd_auto;
data demo_res_NB_fd_auto;
merge demo_res_loan_2_fd(in=a) demo_res_appr_2_fd(in=b) demo_res_appr_2_rg_fd(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_fd_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����_����).xlsx]NewBooking!r5c27:r1000c29';
data _null_;
set Work.demo_res_NB_fd_auto;
file DD;
put L201707 R201707 Rg201707;
run;

/*x "F:\����Demographics\Monthly_Demographics(����_�ھ�).xlsx";*/
**demo_res_NB_A_auto;
data demo_res_NB_A_auto;
merge demo_res_loan_2_A(in=a) demo_res_appr_2_A(in=b) demo_res_appr_2_rg_A(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_A_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����_�ھ�).xlsx]NewBooking!r5c6:r1000c8';
data _null_;
set Work.demo_res_NB_A_auto;
file DD;
put L201707 R201707 Rg201707;
run;

/*x "F:\����Demographics\Monthly_Demographics(����_��ս��).xlsx";*/
**demo_res_NB_B_auto;
data demo_res_NB_B_auto;
merge demo_res_loan_2_B(in=a) demo_res_appr_2_B(in=b) demo_res_appr_2_rg_B(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_B_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����_��ս��).xlsx]NewBooking!r5c6:r1000c8';
data _null_;
set Work.demo_res_NB_B_auto;
file DD;
put L201707 R201707 Rg201707;
run;
