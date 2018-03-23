****************************************************************************************************************
***NewBooking����
*nb_rate_�˹�;

***����1;
data benzi.ml_Demograph2_chanel1;
set bjb.ml_Demograph_simple;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
if ������ǩ=1;
if ��������="�¿ͻ�����";
if ��˴�����<=&dt.;
run;

***����2;
data benzi.ml_Demograph2_chanel2;
set bjb.ml_Demograph_simple;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
if ������ǩ=2;
if ��������="�¿ͻ�����";
if ��˴�����<=&dt.;
run;

***����3;
data benzi.ml_Demograph2_chanel3;
set bjb.ml_Demograph_simple;
if ������ in ("�˹�ͨ��","�˹��ܾ�");
if ������ǩ=3;
if ��������="�¿ͻ�����";
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

%demo_0(use_database=benzi.ml_Demograph2_chanel1,class_g=��˴����·�,i=21);
data demo_res_appr_ch1;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_ch1 as
select a.*,b.Rg201612,b.Rg201701,b.Rg201702,b.Rg201703,b.Rg201704,b.Rg201705,b.Rg201706,b.Rg201707,b.Rg201708,b.Rg201709,b.Rg201710 from var_name_left as a
left join demo_res_appr_ch1 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_ch1 ;by id;run;

%demo_0(use_database=benzi.ml_Demograph2_chanel2,class_g=��˴����·�,i=21);
data demo_res_appr_ch2;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_ch2 as
select a.*,b.Rg201612,b.Rg201701,b.Rg201702,b.Rg201703,b.Rg201704,b.Rg201705,b.Rg201706,b.Rg201707,b.Rg201708,b.Rg201709,b.Rg201710 from var_name_left as a
left join demo_res_appr_ch2 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_ch2 ;by id;run;

%demo_0(use_database=benzi.ml_Demograph2_chanel3,class_g=��˴����·�,i=21);
data demo_res_appr_ch3;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_ch3 as
select a.*,b.Rg201612,b.Rg201701,b.Rg201702,b.Rg201703,b.Rg201704,b.Rg201705,b.Rg201706,b.Rg201707,b.Rg201708,b.Rg201709,b.Rg201710 from var_name_left as a
left join demo_res_appr_ch3 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_ch3 ;by id;run;


*nb_rate_����1;
data benzi.ml_Demograph_ch1;
set bjb.ml_Demograph_simple;
*���Ӧ�ûᵼ�²�ͬʱ����demo��ͬͨ����;
if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;
if ������ǩ=1;
if ��������="�¿ͻ�����";
if ��˴�����<=&dt.;
run;

**nb_rate_����2;
data benzi.ml_Demograph_ch2;
set bjb.ml_Demograph_simple;
*���Ӧ�ûᵼ�²�ͬʱ����demo��ͬͨ����;
if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;
if ������ǩ=2;
if ��������="�¿ͻ�����";
if ��˴�����<=&dt.;
run;

**nb_rate_����3;
data benzi.ml_Demograph_ch3;
set bjb.ml_Demograph_simple;
*���Ӧ�ûᵼ�²�ͬʱ����demo��ͬͨ����;
if ������ in ("�˹�ͨ��","�˹��ܾ�","�˹�ȡ��","ϵͳ�ܾ�","ϵͳͨ��");
if ������ in ("�˹�ͨ��","ϵͳͨ��") then check_final_all=1;else check_final_all=0;
if ������ǩ=3;
if ��������="�¿ͻ�����";
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

%demo_0(use_database=benzi.ml_Demograph_ch1,class_g=��˴����·�,i=21);
data demo_res_appr_ch1;set demo_res;run;
proc sql;
create table demo_res_appr_2_ch1 as
select a.*,b.R201612,b.R201701,b.R201702,b.R201703,b.R201704,b.R201705,b.R201706,b.R201707,b.R201708,b.R201709,b.R201710 from var_name_left as a
left join demo_res_appr_ch1 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_ch1 ;by id;run;

%demo_0(use_database=benzi.ml_Demograph_ch2,class_g=��˴����·�,i=21);
data demo_res_appr_ch2;set demo_res;run;
proc sql;
create table demo_res_appr_2_ch2 as
select a.*,b.R201612,b.R201701,b.R201702,b.R201703,b.R201704,b.R201705,b.R201706,b.R201707,b.R201708,b.R201709,b.R201710 from var_name_left as a
left join demo_res_appr_ch2 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_ch2 ;by id;run;

%demo_0(use_database=benzi.ml_Demograph_ch3,class_g=��˴����·�,i=21);
data demo_res_appr_ch3;set demo_res;run;
proc sql;
create table demo_res_appr_2_ch3 as
select a.*,b.R201612,b.R201701,b.R201702,b.R201703,b.R201704,b.R201705,b.R201706,b.R201707,b.R201708,b.R201709,b.R201710 from var_name_left as a
left join demo_res_appr_ch3 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_ch3 ;by id;run;


**************************************************************************************************************;
***active_loan;

proc sql;
create table  benzi.active_loan as
select a.od_days,a.�ͻ���ǩ,a.�˻���ǩ,a.�ſ��·�,b.*  from bjb.milipayment_report_demo(where=(cut_date=&dt.)) as a
left join  bjb.ml_Demograph_simple as b on a.contract_no=b.apply_code;
quit;

data benzi.active_loan;
set benzi.active_loan;
if apply_code ^= "";
run;

***;
*nb_loan����1;
*δ�ſ�������cut_date=&dt.�Ѿ�ȷ���˷ſ����ݵĽ�ֹ������;
data benzi.active_loan_nb_chanel1;
set benzi.active_loan;
if �˻���ǩ^="δ�ſ�";
if ������ǩ=1;
if ��������="�¿ͻ�����";
count=1;
run;
**nb_loan����2;
data benzi.active_loan_nb_chanel2;
set benzi.active_loan;
if �˻���ǩ^="δ�ſ�";
if ������ǩ=2;
if ��������="�¿ͻ�����";
count=1;
run;
**nb_loan����3;
data benzi.active_loan_nb_chanel3;
set benzi.active_loan;
if �˻���ǩ^="δ�ſ�";
if ������ǩ=3;
if ��������="�¿ͻ�����";
count=1;
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

%demo_0(use_database=benzi.active_loan_nb_chanel1,class_g=�ſ��·�,i=21);
data demo_res_loan_ch1;set demo_res;run;
proc sql;
create table demo_res_loan_2_ch1 as
select a.*,b.L201612,b.L201701,b.L201702,b.L201703,b.L201704,b.L201705,b.L201706,b.L201707,b.L201708,b.L201709,b.L201710 from var_name_left as a
left join demo_res_loan_ch1 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_ch1 ;by id;run;

%demo_0(use_database=benzi.active_loan_nb_chanel2,class_g=�ſ��·�,i=21);
data demo_res_loan_ch2;set demo_res;run;
proc sql;
create table demo_res_loan_2_ch2 as
select a.*,b.L201612,b.L201701,b.L201702,b.L201703,b.L201704,b.L201705,b.L201706,b.L201707,b.L201708,b.L201709,b.L201710 from var_name_left as a
left join demo_res_loan_ch2 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_ch2 ;by id;run;

%demo_0(use_database=benzi.active_loan_nb_chanel3,class_g=�ſ��·�,i=21);
data demo_res_loan_ch3;set demo_res;run;
proc sql;
create table demo_res_loan_2_ch3 as
select a.*,b.L201612,b.L201701,b.L201702,b.L201703,b.L201704,b.L201705,b.L201706,b.L201707,b.L201708,b.L201709,b.L201710 from var_name_left as a
left join demo_res_loan_ch3 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_ch3 ;by id;run;


*****������Ҫ�޸�;
*���ܻ�����⼸�����ά�Ȳ�ͬ��5��17��ʱ������ˣ����������Բ���;

**demo_res_NB_ch1_auto;

data demo_res_NB_ch1_auto;
merge demo_res_loan_2_ch1(in=a) demo_res_appr_2_ch1(in=b) demo_res_appr_2_rg_ch1(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_ch1_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����1)_simple.xlsx]NewBooking!r5c3:r400c35';
data _null_;
set Work.demo_res_NB_ch1_auto;
file DD;
put L201612 R201612 Rg201612 L201701 R201701 Rg201701 L201702 R201702 Rg201702 L201703 R201703 Rg201703 
L201704 R201704 Rg201704 L201705 R201705 Rg201705 L201706 R201706 Rg201706 L201707 R201707 Rg201707 
L201708 R201708 Rg201708 L201709 R201709 Rg201709 L201710 R201710 Rg201710;
run;


**demo_res_NB_ch2_auto;
data demo_res_NB_ch2_auto;
merge demo_res_loan_2_ch2(in=a) demo_res_appr_2_ch2(in=b) demo_res_appr_2_rg_ch2(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_ch2_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����2)_simple.xlsx]NewBooking!r5c3:r400c35';
data _null_;
set Work.demo_res_NB_ch2_auto;
file DD;
put L201612 R201612 Rg201612 L201701 R201701 Rg201701 L201702 R201702 Rg201702 L201703 R201703 Rg201703 
L201704 R201704 Rg201704 L201705 R201705 Rg201705 L201706 R201706 Rg201706 L201707 R201707 Rg201707 
L201708 R201708 Rg201708 L201709 R201709 Rg201709 L201710 R201710 Rg201710;
run;

**demo_res_NB_ch3_auto;
data demo_res_NB_ch3_auto;
merge demo_res_loan_2_ch3(in=a) demo_res_appr_2_ch3(in=b) demo_res_appr_2_rg_ch3(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_ch3_auto;by id;run;
filename DD DDE 'EXCEL|[Monthly_Demographics(����3)_simple.xlsx]NewBooking!r5c3:r400c35';
data _null_;
set Work.demo_res_NB_ch3_auto;
file DD;
put L201612 R201612 Rg201612 L201701 R201701 Rg201701 L201702 R201702 Rg201702 L201703 R201703 Rg201703 
L201704 R201704 Rg201704 L201705 R201705 Rg201705 L201706 R201706 Rg201706 L201707 R201707 Rg201707 
L201708 R201708 Rg201708 L201709 R201709 Rg201709 L201710 R201710 Rg201710;
run;

