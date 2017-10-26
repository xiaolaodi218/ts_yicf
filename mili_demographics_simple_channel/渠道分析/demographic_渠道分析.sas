data app_num;
set benzi.active_loan(keep = 
apply_code
申请结果
申请提交点
申请提交点_g
申请提交日期
申请提交月份
审核处理日期
审核处理月份
复贷申请
loc_appsl
loc_appsl_g
grp_cx_score
天启分区间
芝麻分区间
冰鉴分区间
月均消费金额区间
首次申请 
订单类型 
loc_abmoduleflag
来源渠道
渠道标签
放款月份
od_days
账户标签);
run;

data app_number;
set app_num;
format loc_appsl_num $20.;
if loc_appsl=0 then loc_appsl_num="1. 0个";
else if loc_appsl=1 then loc_appsl_num="2. 1个";
else if loc_appsl=2 then loc_appsl_num="3. 2个";
else if loc_appsl=3 then loc_appsl_num="4. 3个";
else if loc_appsl=4 then loc_appsl_num="5. 4个";
else if loc_appsl=5 then loc_appsl_num="6. 5个";
else if 5<loc_appsl<=10 then loc_appsl_num="7. 6-10个";
else if 10<loc_appsl<=15 then loc_appsl_num="8. 11-15个";
else if loc_appsl>15 then loc_appsl_num="9. 16个以上";
run;

data app_number;
set app_number;
if 放款月份^="201612";
if 放款月份^="201701";
if 放款月份^="201702";
if 放款月份^="201703";
run;


data app_number_loan;
set app_number;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
run;

proc freq data=app_number_loan noprint;
table 放款月份*loc_appsl_num/out=acc;
run;


data data app_number_loan5;
set app_number_loan;
if od5=1;
run;
proc freq data=app_number_loan5 noprint;
table 放款月份*loc_appsl_num/out=acc5;
run;


data data app_number_loan15;
set app_number_loan;
if od15=1;
run;
proc freq data=app_number_loan15 noprint;
table 放款月份*loc_appsl_num/out=acc15;
run;



***新客户;
data app_number_loan_xz;
set app_number_loan;
if 订单类型="新客户订单"; 
run;

proc freq data=app_number_loan_xz noprint;
table 放款月份*loc_appsl_num/out=acc_xz;
run;


data data app_number_loan5_xz;
set app_number_loan_xz;
if od5=1;
run;
proc freq data=app_number_loan5_xz noprint;
table 放款月份*loc_appsl_num/out=acc5_xz;
run;


data data app_number_loan15_xz;
set app_number_loan_xz;
if od15=1;
run;
proc freq data=app_number_loan15_xz noprint;
table 放款月份*loc_appsl_num/out=acc15_xz;
run;


*渠道1 ;
data app_number_loan_xz_ch1;
set app_number_loan_xz;
if 渠道标签=1; 
run;

proc freq data=app_number_loan_xz_ch1 noprint;
table 放款月份*loc_appsl_num/out=acc_xz_ch1;
run;


data data app_number_loan5_xz_ch1;
set app_number_loan_xz_ch1;
if od5=1;
run;
proc freq data=app_number_loan5_xz_ch1 noprint;
table 放款月份*loc_appsl_num/out=acc5_xz_ch1;
run;


data data app_number_loan15_xz_ch1;
set app_number_loan_xz_ch1;
if od15=1;
run;
proc freq data=app_number_loan15_xz_ch1 noprint;
table 放款月份*loc_appsl_num/out=acc15_xz_ch1;
run;

**不拆分放款月份;
data app_number_loan_xz_ch1;
set app_number_loan_xz;
if 渠道标签=1; 
run;

proc freq data=app_number_loan_xz_ch1 noprint;
table loc_appsl_num/out=acc_xz_ch1;
run;

data data app_number_loan5_xz_ch1;
set app_number_loan_xz_ch1;
if od5=1;
run;
proc freq data=app_number_loan5_xz_ch1 noprint;
table loc_appsl_num/out=acc5_xz_ch1;
run;


data data app_number_loan15_xz_ch1;
set app_number_loan_xz_ch1;
if od15=1;
run;
proc freq data=app_number_loan15_xz_ch1 noprint;
table loc_appsl_num/out=acc15_xz_ch1;
run;



*渠道2 ;
data app_number_loan_xz_ch2;
set app_number_loan_xz;
if 渠道标签=2; 
run;

proc freq data=app_number_loan_xz_ch2 noprint;
table 放款月份*loc_appsl_num/out=acc_xz_ch2;
run;

data data app_number_loan5_xz_ch2;
set app_number_loan_xz_ch2;
if od5=1;
run;
proc freq data=app_number_loan5_xz_ch2 noprint;
table 放款月份*loc_appsl_num/out=acc5_xz_ch2;
run;

data data app_number_loan15_xz_ch2;
set app_number_loan_xz_ch2;
if od15=1;
run;
proc freq data=app_number_loan15_xz_ch2 noprint;
table 放款月份*loc_appsl_num/out=acc15_xz_ch2;
run;

**不按照放款月份拆分;
data app_number_loan_xz_ch2;
set app_number_loan_xz;
if 渠道标签=2; 
run;

proc freq data=app_number_loan_xz_ch2 noprint;
table loc_appsl_num/out=acc_xz_ch2;
run;

data data app_number_loan5_xz_ch2;
set app_number_loan_xz_ch2;
if od5=1;
run;
proc freq data=app_number_loan5_xz_ch2 noprint;
table loc_appsl_num/out=acc5_xz_ch2;
run;

data data app_number_loan15_xz_ch2;
set app_number_loan_xz_ch2;
if od15=1;
run;
proc freq data=app_number_loan15_xz_ch2 noprint;
table loc_appsl_num/out=acc15_xz_ch2;
run;

*渠道3 ;
data app_number_loan_xz_ch3;
set app_number_loan_xz;
if 渠道标签=3; 
run;

proc freq data=app_number_loan_xz_ch3 noprint;
table 放款月份*loc_appsl_num/out=acc_xz_ch3;
run;


data data app_number_loan5_xz_ch3;
set app_number_loan_xz_ch3;
if od5=1;
run;
proc freq data=app_number_loan5_xz_ch3 noprint;
table 放款月份*loc_appsl_num/out=acc5_xz_ch3;
run;


data data app_number_loan15_xz_ch3;
set app_number_loan_xz_ch3;
if od15=1;
run;
proc freq data=app_number_loan15_xz_ch3 noprint;
table 放款月份*loc_appsl_num/out=acc15_xz_ch3;
run;


***不按照放款月份拆分;
data app_number_loan_xz_ch3;
set app_number_loan_xz;
if 渠道标签=3; 
run;
proc freq data=app_number_loan_xz_ch3 noprint;
table loc_appsl_num/out=acc_xz_ch3;
run;
data data app_number_loan5_xz_ch3;
set app_number_loan_xz_ch3;
if od5=1;
run;
proc freq data=app_number_loan5_xz_ch3 noprint;
table loc_appsl_num/out=acc5_xz_ch3;
run;
data data app_number_loan15_xz_ch3;
set app_number_loan_xz_ch3;
if od15=1;
run;
proc freq data=app_number_loan15_xz_ch3 noprint;
table loc_appsl_num/out=acc15_xz_ch3;
run;
















********************************************************************************************************************;

option compress = yes validvarname = any;
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";
libname bjb "F:\米粒Demographics\data";
libname benzi "F:\米粒demographics_simple_channel\data";
libname repayFin "F:\米粒逾期日报表\data";

data active_loan222;
set benzi.active_loan;
if 审核处理日期>"2017-08-18";
run;

*active_loan;
***渠道1;
data benzi.active_loan_activeloan_m_chanel1;
set active_loan222;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
**筛选新客户;
if 订单类型="新客户订单";
**下面这个标签会筛选出拒绝客户订单和极速贷订单;/*if 客户标签=1;*/
if 渠道标签=1;
run;

**渠道2;
data benzi.active_loan_activeloan_m_chanel2;
set active_loan222;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
**筛选新客户;
if 订单类型="新客户订单";
if 渠道标签=2;
run;

**渠道3;
data benzi.active_loan_activeloan_m_chanel3;
set active_loan222;
if 账户标签 not in ("未放款","待还款");
if apply_code^="";
count=1;
if od_days>5 then od5=1;else od5=0;
if od_days>15 then od15=1;else od15=0;
**筛选新客户;
if 订单类型="新客户订单";
if 渠道标签=3;
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


**获取逾期5+天的;
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


**获取逾期15+天的;
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

/*链接active ever15+ ever90+*/

******************渠道1;
/*x "F:\米粒Demographics\Monthly_Demographics(米粒_total).xlsx";*/

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

filename DD DDE "EXCEL|[Monthly_Demographics(渠道123)_simple.xlsx]Active Loan1!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel1;
file DD;
put count_N count_N_15 count_N_90;
run;


**********************渠道2;
/*x "F:\米粒Demographics\Monthly_Demographics(米粒_新客户).xlsx";*/

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

filename DD DDE "EXCEL|[Monthly_Demographics(渠道123)_simple.xlsx]Active Loan2!r5c3:r400c5";
data _null_;
set Work.demo_res_ods_chanel2;
file DD;
put count_N count_N_15 count_N_90;
run;

*********************渠道3;
/*x "F:\米粒Demographics\Monthly_Demographics(米粒_复贷).xlsx";*/

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

filename DD DDE 'EXCEL|[Monthly_Demographics(渠道123)_simple.xlsx]Active Loan3!r5c3:r400c5';
data _null_;
set Work.demo_res_ods_chanel3;
file DD;
put count_N count_N_15 count_N_90;
run;










*************************************************************************************************************************
***TTD;

data ml_Demograph_simple_ch123;
set bjb.ml_Demograph_simple;
if 审核处理日期>"2017-08-18";
run;

***渠道1;
data benzi.ml_Demograph1_chanel1;
set ml_Demograph_simple_ch123;
if 申请提交日<=&dt.;
if 订单类型="新客户订单";
if 渠道标签=1;
run;
**渠道2;
data  benzi.ml_Demograph1_chanel2;
set ml_Demograph_simple_ch123;
if 申请提交日<=&dt.;
if 订单类型="新客户订单";
if 渠道标签=2;
run;
*渠道3;
data  benzi.ml_Demograph1_chanel3; 
set ml_Demograph_simple_ch123;
if 申请提交日<=&dt.;
if 订单类型="新客户订单";
if 渠道标签=3;
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
var input_complete;
table &var_name.
all,&class_g.*input_complete*(N);
run;
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=a_;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var input_complete_N;
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

**demo_res_ttd_chanel1_auto;
%demo_0(use_database=benzi.ml_Demograph1_chanel1,class_g=申请提交月份,i=21);
data demo_res_ttd_chanel1;set demo_res;run;
proc sql;
create table demo_res_ttd_chanel1_auto as
select a.*,b.a_201708,b.a_201709,b.a_201710 from var_name_left as a
left join demo_res_ttd_chanel1 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_chanel1_auto ;by id;run;

filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD1!r5c3:r400c3';
data _null_;
set Work.demo_res_ttd_chanel1_auto;
file DD;
put a_201708;
run;
filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD1!r5c5:r400c5';
data _null_;
set Work.demo_res_ttd_chanel1_auto;
file DD;
put a_201709;
run;
filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD1!r5c7:r400c7';
data _null_;
set Work.demo_res_ttd_chanel1_auto;
file DD;
put a_201710;
run;

**demo_res_ttd_chanel2_auto;
%demo_0(use_database=benzi.ml_Demograph1_chanel2,class_g=申请提交月份,i=21);
data demo_res_ttd_chanel2;set demo_res;run;
proc sql;
create table demo_res_ttd_chanel2_auto as
select a.*,b.a_201708,b.a_201709,b.a_201710 from var_name_left as a
left join demo_res_ttd_chanel2 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_chanel2_auto ;by id;run;

filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD2!r5c3:r400c3';
data _null_;
set Work.demo_res_ttd_chanel2_auto;
file DD;
put a_201708;
run;
filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD2!r5c5:r400c5';
data _null_;
set Work.demo_res_ttd_chanel2_auto;
file DD;
put a_201709;
run;
filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD2!r5c7:r400c7';
data _null_;
set Work.demo_res_ttd_chanel2_auto;
file DD;
put a_201710;
run;

**demo_res_ttd_chanel3_auto;
%demo_0(use_database=benzi.ml_Demograph1_chanel3,class_g=申请提交月份,i=21);
data demo_res_ttd_chanel3;set demo_res;run;
proc sql;
create table demo_res_ttd_chanel3_auto as
select a.* ,b.a_201708,b.a_201709,b.a_201710 from var_name_left as a
left join demo_res_ttd_chanel3 as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_chanel3_auto ;by id;run;

filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD3!r5c3:r400c3';
data _null_;
set Work.demo_res_ttd_chanel3_auto;
file DD;
put a_201708;
run;
filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD3!r5c5:r400c5';
data _null_;
set Work.demo_res_ttd_chanel3_auto;
file DD;
put a_201709;
run;filename DD DDE 'EXCEL|[Demographics(渠道123).xlsx]TTD3!r5c7:r400c7';
data _null_;
set Work.demo_res_ttd_chanel3_auto;
file DD;
put a_201710;
run;
