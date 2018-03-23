****************************************************************************************************************
***NewBooking开户
*nb_rate_人工;

data benzi.ml_Demograph2_all;
set bjb.ml_Demograph_simple;
*这个应该会导致不同时间做demo不同通过率;
if 申请结果 in ("人工通过","人工拒绝");
/*if 来源渠道 in ("appstore");*/
if 审核处理日<=&dt.;
run;

**得到复贷和新客户的数据集;
data benzi.ml_Demograph2_xz benzi.ml_Demograph2_fd;
set bjb.ml_Demograph_simple;
if 申请结果 in ("人工通过","人工拒绝");
if 复贷申请=1 then output benzi.ml_Demograph2_fd;
else if 订单类型="新客户订单" then output benzi.ml_Demograph2_xz;
if 审核处理日<=&dt.;
run;

/**得到冠军的数据集;*/
/*data benzi.ml_Demograph2_A;*/
/*set bjb.ml_Demograph_simple;*/
/*if 申请结果 in ("人工通过","人工拒绝");*/
/*if loc_abmoduleflag="A";*/
/*if 审核处理日<=&dt.;*/
/*run;*/
/**/
/**得到挑战者的数据集;*/
/*data benzi.ml_Demograph2_B;*/
/*set bjb.ml_Demograph_simple;*/
/*if 申请结果 in ("人工通过","人工拒绝");*/
/*if loc_abmoduleflag = "B";*/
/*if 申请提交日<=&dt.;*/
/*run;*/

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
if &var_name.="" then group="小计";
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

%demo_0(use_database=benzi.ml_Demograph2_all,class_g=审核处理月份,i=21);
data demo_res_appr_all;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_all as
select a.*,b.Rg201612,b.Rg201701,b.Rg201702,b.Rg201703,b.Rg201704,b.Rg201705,b.Rg201706,b.Rg201707,b.Rg201708,b.Rg201709,b.Rg201710 from var_name_left as a
left join demo_res_appr_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_all ;by id;run;

%demo_0(use_database=benzi.ml_Demograph2_xz,class_g=审核处理月份,i=21);
data demo_res_appr_xz;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_xz as
select a.*,b.Rg201612,b.Rg201701,b.Rg201702,b.Rg201703,b.Rg201704,b.Rg201705,b.Rg201706,b.Rg201707,b.Rg201708,b.Rg201709,b.Rg201710 from var_name_left as a
left join demo_res_appr_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_xz ;by id;run;

%demo_0(use_database=benzi.ml_Demograph2_fd,class_g=审核处理月份,i=21);
data demo_res_appr_fd;set demo_res;run;
proc sql;
create table demo_res_appr_2_rg_fd as
select a.*,b.Rg201612,b.Rg201701,b.Rg201702,b.Rg201703,b.Rg201704,b.Rg201705,b.Rg201706,b.Rg201707,b.Rg201708,b.Rg201709,b.Rg201710 from var_name_left as a
left join demo_res_appr_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_rg_fd ;by id;run;

/*%demo_0(use_database=benzi.ml_Demograph2_A,class_g=审核处理月份,i=20);*/
/*data demo_res_appr_A;set demo_res;run;*/
/*proc sql;*/
/*create table demo_res_appr_2_rg_A as*/
/*select a.*,b.Rg201706,b.Rg201707 from var_name_left as a*/
/*left join demo_res_appr_A as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_appr_2_rg_A ;by id;run;*/
/**/
/*%demo_0(use_database=benzi.ml_Demograph2_B,class_g=审核处理月份,i=20);*/
/*data demo_res_appr_B;set demo_res;run;*/
/*proc sql;*/
/*create table demo_res_appr_2_rg_B as*/
/*select a.*,b.Rg201706,b.Rg201707 from var_name_left as a*/
/*left join demo_res_appr_B as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_appr_2_rg_B ;by id;run;*/

*nb_rate_总的;
data benzi.ml_Demograph2_all;
set bjb.ml_Demograph_simple;
*这个应该会导致不同时间做demo不同通过率;
if 申请结果 in ("人工通过","人工拒绝","人工取消","系统拒绝","系统通过");
if 申请结果 in ("人工通过","系统通过") then check_final_all=1;else check_final_all=0;

/*if 来源渠道 in ("appstore");*/
if 审核处理日<=&dt.;
run;

**nb_rate_新客户和复贷客户;
data benzi.ml_Demograph2_xz benzi.ml_Demograph2_fd;
set bjb.ml_Demograph_simple;

if 申请结果 in ("人工通过","人工拒绝","人工取消","系统拒绝","系统通过");
if 申请结果 in ("人工通过","系统通过") then check_final_all=1;else check_final_all=0;
if 复贷申请=1 then output benzi.ml_Demograph2_fd;
else if 订单类型="新客户订单" then output benzi.ml_Demograph2_xz;
if 审核处理日<=&dt.;
run;

/***nb_rate_冠军;*/
/*data benzi.ml_Demograph2_A;*/
/*set bjb.ml_Demograph_simple;*/
/*if 申请结果 in ("人工通过","人工拒绝","人工取消","系统拒绝","系统通过");*/
/*if 申请结果 in ("人工通过","系统通过") then check_final_all=1;else check_final_all=0;*/
/*if loc_abmoduleflag="A";*/
/*if 审核处理日<=&dt.;*/
/*run;*/
/**/
/***nb_rate_挑战者;*/
/*data benzi.ml_Demograph2_B;*/
/*set bjb.ml_Demograph_simple;*/
/*if 申请结果 in ("人工通过","人工拒绝","人工取消","系统拒绝","系统通过");*/
/*if 申请结果 in ("人工通过","系统通过") then check_final_all=1;else check_final_all=0;*/
/*if loc_abmoduleflag="B";*/
/*if 审核处理日<=&dt.;*/
/*run;*/

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
if &var_name.="" then group="小计";
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

%demo_0(use_database=benzi.ml_Demograph2_all,class_g=审核处理月份,i=21);
data demo_res_appr_all;set demo_res;run;
proc sql;
create table demo_res_appr_2_all as
select a.*,b.R201612,b.R201701,b.R201702,b.R201703,b.R201704,b.R201705,b.R201706,b.R201707,b.R201708,b.R201709,b.R201710 from var_name_left as a
left join demo_res_appr_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_all ;by id;run;

%demo_0(use_database=benzi.ml_Demograph2_xz,class_g=审核处理月份,i=21);
data demo_res_appr_xz;set demo_res;run;
proc sql;
create table demo_res_appr_2_xz as
select a.*,b.R201612,b.R201701,b.R201702,b.R201703,b.R201704,b.R201705,b.R201706,b.R201707,b.R201708,b.R201709,b.R201710 from var_name_left as a
left join demo_res_appr_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_xz ;by id;run;

%demo_0(use_database=benzi.ml_Demograph2_fd,class_g=审核处理月份,i=21);
data demo_res_appr_fd;set demo_res;run;
proc sql;
create table demo_res_appr_2_fd as
select a.*,b.R201612,b.R201701,b.R201702,b.R201703,b.R201704,b.R201705,b.R201706,b.R201707,b.R201708,b.R201709,b.R201710 from var_name_left as a
left join demo_res_appr_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_appr_2_fd ;by id;run;

/*%demo_0(use_database=benzi.ml_Demograph2_A,class_g=审核处理月份,i=21);*/
/*data demo_res_appr_A;set demo_res;run;*/
/*proc sql;*/
/*create table demo_res_appr_2_A as*/
/*select a.*,b.R201706,b.R201707 from var_name_left as a*/
/*left join demo_res_appr_A as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_appr_2_A ;by id;run;*/
/**/
/*%demo_0(use_database=benzi.ml_Demograph2_B,class_g=审核处理月份,i=21);*/
/*data demo_res_appr_B;set demo_res;run;*/
/*proc sql;*/
/*create table demo_res_appr_2_B as*/
/*select a.*,b.R201706,b.R201707 from var_name_left as a*/
/*left join demo_res_appr_B as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_appr_2_B ;by id;run;*/

proc sql;
create table  benzi.active_loan as
select a.od_days,a.客户标签,a.账户标签,a.放款月份,b.*  from bjb.milipayment_report_demo(where=(cut_date=&dt.)) as a
left join  bjb.ml_Demograph_simple as b on a.contract_no=b.apply_code;
quit;

data benzi.active_loan;
set benzi.active_loan;
if apply_code ^= "";
run;
*nb_loan;
*未放款和上面的cut_date=&dt.已经确定了放款数据的截止日期了;
data benzi.active_loan_nb_all;
set benzi.active_loan;
if 账户标签^="未放款";
/*if 来源渠道 in ("qihu360","vivo","yingyongbao");*/
count=1;
run;
**新客户和复贷;
data benzi.active_loan_nb_xz benzi.active_loan_nb_fd ;
set benzi.active_loan;
if 账户标签^="未放款";
count=1;
if 订单类型="新客户订单" then output benzi.active_loan_nb_xz;
else if 客户标签^=1 then output benzi.active_loan_nb_fd;
run;
**冠军;
/*data benzi.active_loan_nb_A;*/
/*set benzi.active_loan;*/
/*if 账户标签^="未放款";*/
/*count=1;*/
/*if loc_abmoduleflag="A";*/
/*run;*/
/***挑战者;*/
/*data benzi.active_loan_nb_B;*/
/*set benzi.active_loan;*/
/*if 账户标签^="未放款";*/
/*count=1;*/
/*if loc_abmoduleflag="B";*/
/*run;*/


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
if &var_name.="" then group="小计";
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

%demo_0(use_database=benzi.active_loan_nb_all,class_g=放款月份,i=21);
data demo_res_loan_all;set demo_res;run;
proc sql;
create table demo_res_loan_2_all as
select a.*,b.L201612,b.L201701,b.L201702,b.L201703,b.L201704,b.L201705,b.L201706,b.L201707,b.L201708,b.L201709,b.L201710 from var_name_left as a
left join demo_res_loan_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_all ;by id;run;

%demo_0(use_database=benzi.active_loan_nb_xz,class_g=放款月份,i=21);
data demo_res_loan_xz;set demo_res;run;
proc sql;
create table demo_res_loan_2_xz as
select a.*,b.L201612,b.L201701,b.L201702,b.L201703,b.L201704,b.L201705,b.L201706,b.L201707,b.L201708,b.L201709,b.L201710 from var_name_left as a
left join demo_res_loan_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_xz ;by id;run;

%demo_0(use_database=benzi.active_loan_nb_fd,class_g=放款月份,i=21);
data demo_res_loan_fd;set demo_res;run;
proc sql;
create table demo_res_loan_2_fd as
select a.*,b.L201612,b.L201701,b.L201702,b.L201703,b.L201704,b.L201705,b.L201706,b.L201707,b.L201708,b.L201709,b.L201710 from var_name_left as a
left join demo_res_loan_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_loan_2_fd ;by id;run;

/*%demo_0(use_database=benzi.active_loan_nb_A,class_g=放款月份,i=20);*/
/*data demo_res_loan_A;set demo_res;run;*/
/*proc sql;*/
/*create table demo_res_loan_2_A as*/
/*select a.*,b.L201706,b.L201707 from var_name_left as a*/
/*left join demo_res_loan_A as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_loan_2_A ;by id;run;*/
/**/
/*%demo_0(use_database=benzi.active_loan_nb_B,class_g=放款月份,i=20);*/
/*data demo_res_loan_B;set demo_res;run;*/
/*proc sql;*/
/*create table demo_res_loan_2_B as*/
/*select a.*,b.L201706,b.L201707 from var_name_left as a*/
/*left join demo_res_loan_B as b on a.group=b.group and a.variable=b.variable;*/
/*quit;*/
/*proc sort data=demo_res_loan_2_B ;by id;run;*/


*****这里需要修改;
*可能会出现这几个表的维度不同，5月17的时候出现了，导致数量对不上;

/*x "F:\米粒Demographics\Monthly_Demographics(米粒_total).xlsx";*/
**demo_res_NB_all_auto;
data demo_res_NB_all_auto;
merge demo_res_loan_2_all(in=a) demo_res_appr_2_all(in=b) demo_res_appr_2_rg_all(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_all_auto;by id;run;
filename DD DDE "EXCEL|[Monthly_Demographics(米粒_total)_simple.xlsx]NewBooking!r5c33:r400c35";
data _null_;
set Work.demo_res_NB_all_auto;
file DD;
/*put L201612 R201612 Rg201612 L201701 R201701 Rg201701 L201702 R201702 Rg201702 L201703 R201703 Rg201703 L201704 R201704 Rg201704 */
/*L201705 R201705 Rg201705 L201706 R201706 Rg201706 L201707 R201707 Rg201707 L201708 R201708 Rg201708 L201709 R201709 Rg201709 L201710 R201710 Rg201710;*/
put L201710 R201710 Rg201710;
run;


/*x "F:\米粒Demographics\Monthly_Demographics(米粒_新客户).xlsx";*/
**demo_res_NB_xz_auto;
data demo_res_NB_xz_auto;
merge demo_res_loan_2_xz(in=a) demo_res_appr_2_xz(in=b) demo_res_appr_2_rg_xz(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_xz_auto;by id;run;
filename DD DDE "EXCEL|[Monthly_Demographics(米粒_新客户)_simple.xlsx]NewBooking!r5c33:r400c35";
data _null_;
set Work.demo_res_NB_xz_auto;
file DD;
/*put L201612 R201612 Rg201612 L201701 R201701 Rg201701 L201702 R201702 Rg201702 L201703 R201703 Rg201703 L201704 R201704 Rg201704 */
/*L201705 R201705 Rg201705 L201706 R201706 Rg201706 L201707 R201707 Rg201707 L201708 R201708 Rg201708 L201709 R201709 Rg201709 L201710 R201710 Rg201710;*/
put L201710 R201710 Rg201710;
run;


/*x "F:\米粒Demographics\Monthly_Demographics(米粒_复贷).xlsx";*/
**demo_res_NB_fd_auto;
data demo_res_NB_fd_auto;
merge demo_res_loan_2_fd(in=a) demo_res_appr_2_fd(in=b) demo_res_appr_2_rg_fd(in=c);
by id;
if b;
run;
proc sort data=demo_res_NB_fd_auto;by id;run;
filename DD DDE "EXCEL|[Monthly_Demographics(米粒_复贷)_simple.xlsx]NewBooking!r5c33:r400c35";
data _null_;
set Work.demo_res_NB_fd_auto;
file DD;
/*put L201612 R201612 Rg201612 L201701 R201701 Rg201701 L201702 R201702 Rg201702 L201703 R201703 Rg201703 L201704 R201704 */
/*Rg201704 L201705 R201705 Rg201705 L201706 R201706 Rg201706 L201707 R201707 Rg201707 L201708 R201708 Rg201708 L201709 R201709 Rg201709 L201710 R201710 Rg201710;*/
put L201710 R201710 Rg201710;
run;

/*/*x "F:\米粒Demographics\Monthly_Demographics(米粒_冠军).xlsx";*/*/
/***demo_res_NB_A_auto;*/
/*data demo_res_NB_A_auto;*/
/*merge demo_res_loan_2_A(in=a) demo_res_appr_2_A(in=b) demo_res_appr_2_rg_A(in=c);*/
/*by id;*/
/*if b;*/
/*run;*/
/*proc sort data=demo_res_NB_A_auto;by id;run;*/
/*filename DD DDE 'EXCEL|[Monthly_Demographics(米粒_冠军)_simple.xlsx]NewBooking!r5c3:r400c8';*/
/*data _null_;*/
/*set Work.demo_res_NB_A_auto;*/
/*file DD;*/
/*put L201706 R201706 Rg201706 L201707 R201707 Rg201707;*/
/*run;*/
/**/
/*/*x "F:\米粒Demographics\Monthly_Demographics(米粒_挑战者).xlsx";*/*/
/***demo_res_NB_B_auto;*/
/*data demo_res_NB_B_auto;*/
/*merge demo_res_loan_2_B(in=a) demo_res_appr_2_B(in=b) demo_res_appr_2_rg_B(in=c);*/
/*by id;*/
/*if b;*/
/*run;*/
/*proc sort data=demo_res_NB_B_auto;by id;run;*/
/*filename DD DDE 'EXCEL|[Monthly_Demographics(米粒_挑战者)_simple.xlsx]NewBooking!r5c3:r400c8';*/
/*data _null_;*/
/*set Work.demo_res_NB_B_auto;*/
/*file DD;*/
/*put L201706 R201706 Rg201706 L201707 R201707 Rg201707;*/
/*run;*/
