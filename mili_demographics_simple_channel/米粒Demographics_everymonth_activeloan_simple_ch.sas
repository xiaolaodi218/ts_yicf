********************************************************************************************************************
*every_month_active_loan;

**渠道1;
data benzi.activeloan_every_m_chanel1;
set benzi.active_loan;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if 订单类型="新客户订单";
if 渠道标签=1;
run;
**渠道2;
data benzi.activeloan_every_m_chanel2;
set benzi.active_loan;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if 订单类型="新客户订单";
if 渠道标签=2;
run;
**渠道3;
data benzi.activeloan_every_m_chanel3;
set benzi.active_loan;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
if 订单类型="新客户订单";
if 渠道标签=3;
run;

***造一个关于放款月的宏变量到后面使用;
data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 3, 13, "same"); else dt = today() - 3;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

proc sort data=bjb.milipayment_report_demo(keep= 放款月份 loan_date cut_date where=(cut_date=&dt.))  out=month_list nodupkey;by 放款月份 ;run;
proc sort data=month_list;by loan_date;run;
data _null_;
set month_list end=last;     
call symput ("month_"||compress(_n_),compress(放款月份));        
if last then call symput("lcn",compress(_n_));
run;

***我们先拆分出每个月的表，然后再这个表的基础上循环20次，迭代变量；

**开始获取每个月demo_res_active_ 三个表;
%macro demo_0(use_database,i,type);
%do k=1 %to &lcn.;

data use_kfc;
set &use_database.;
if 放款月份=&&month_&k;
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

proc sql;
create table &type&&month_&k as
select a.*,b.count_N from var_name_left as a
left join demo_res as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=&type&&month_&k ;by id;run;

%end;
%mend;

%demo_0(use_database=benzi.activeloan_every_m_chanel1,i=21,type=demo_res_active_chanel1);

%demo_0(use_database=benzi.activeloan_every_m_chanel2,i=21,type=demo_res_active_chanel2);

%demo_0(use_database=benzi.activeloan_every_m_chanel3,i=21,type=demo_res_active_chanel3);

data benzi.activeloan_every_5_chanel1;
set benzi.activeloan_every_m_chanel1;
if od5=1;
run;

data benzi.activeloan_every_5_chanel2;
set benzi.activeloan_every_m_chanel2;
if od5=1;
run;

data benzi.activeloan_every_5_chanel3;
set benzi.activeloan_every_m_chanel3;
if od5=1;
run;

%macro demo_0(use_database,i,type);
%do k=1 %to &lcn.;

data use_kfd;
set &use_database;
if 放款月份 = &&month_&k;
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

proc sql;
create table &type&&month_&k as
select a.*,b.count_N from var_name_left as a
left join demo_res_ever15 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=&type&&month_&k ;by id;run;
%end;
%mend;

%demo_0(use_database=benzi.activeloan_every_5_chanel1,i=21,type=demo_res_ever15_chanel1);

%demo_0(use_database=benzi.activeloan_every_5_chanel2,i=21,type=demo_res_ever15_chanel2);

%demo_0(use_database=benzi.activeloan_every_5_chanel3,i=21,type=demo_res_ever15_chanel3);


**开始获取每个月的demo_res_90_all_的表;

data benzi.activeloan_every_15_chanel1;
set benzi.activeloan_every_m_chanel1;
if od15=1;
run;
data benzi.activeloan_every_15_chanel2;
set benzi.activeloan_every_m_chanel2;
if od15=1;
run;
data benzi.activeloan_every_15_chanel3;
set benzi.activeloan_every_m_chanel3;
if od15=1;
run;

%macro demo_0(use_database,i,type);
%do k=1 %to &lcn.;

data use_kfe;
set &use_database;
if 放款月份 = &&month_&k;
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
proc sql;
create table &type&&month_&k as
select a.*,b.count_N from var_name_left as a
left join demo_res_900 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=&type&&month_&k ;by id;run;
%end;
%mend;

%demo_0(use_database=benzi.activeloan_every_15_chanel1,i=21,type=demo_res_90_chanel1); 

%demo_0(use_database=benzi.activeloan_every_15_chanel2,i=21,type=demo_res_90_chanel2);

%demo_0(use_database=benzi.activeloan_every_15_chanel3,i=21,type=demo_res_90_chanel3);


**最后合并每个月的数据集;
**渠道1;
%macro demo_1();
%do k=2 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_chanel1&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_chanel1&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_chanel1&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_chanel1_&&month_&k;
merge demo_res_active_chanel1&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_chanel1_&&month_&k;by id;run;

/*x "F:\米粒Demographics\Monthly_Demographics(渠道1).xlsx";*/

filename DD DDE "EXCEL|[Monthly_Demographics(渠道1)_simple.xlsx]&&month_&k.!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel1_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_1();

**渠道2;
%macro demo_2();
%do k=2 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_chanel2&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_chanel2&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_chanel2&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_chanel2_&&month_&k;
merge demo_res_active_chanel2&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_chanel2_&&month_&k;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(渠道2)_simple.xlsx]&&month_&k.!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel2_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_2();

**渠道3;
%macro demo_3();
%do k=1 %to &lcn.;

data demo_res_ever15_2_&&month_&k; set Demo_res_ever15_chanel3&&month_&k; rename count_N=count_N_15;run;
data demo_res_90_2_&&month_&k; set Demo_res_90_chanel3&&month_&k; rename count_N=count_N_90;run;

proc sort data=demo_res_active_chanel3&&month_&k nodupkey;by id;run;
proc sort data=demo_res_ever15_2_&&month_&k nodupkey;by id;run;
proc sort data=demo_res_90_2_&&month_&k nodupkey;by id;run;

data demo_res_ods_chanel3_&&month_&k;
merge demo_res_active_chanel3&&month_&k(in=a) demo_res_ever15_2_&&month_&k(in=b) demo_res_90_2_&&month_&k(in=c);
by id;
if a;
run;
proc sort data=demo_res_ods_chanel3_&&month_&k;by id;run;

filename DD DDE "EXCEL|[Monthly_Demographics(渠道3)_simple.xlsx]&&month_&k.!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel3_&&month_&k;
file DD;
put count_N count_N_15 count_N_90;
run;

%end;
%mend;
%demo_3();
