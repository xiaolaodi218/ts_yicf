/********************************************************************************************/
/* 中融微盟科技有限公司需要的数据																				*/
/* 2018-01-12, 新建, Yichengfan  						   								    */


/*2018/3/19,重新给出数据，Yichengfan	*/
/********************************************************************************************/

/*先确定时间维度和数据量大小；再确定取哪些变量*/
option compress = yes validvarname = any;

libname ly_data "\\ly\Datamart\中间表\daily";

libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname daily "D:\mili\offline\daily";
libname cre "D:\mili\offline\centre_data\daily";

libname credit "D:\mili\offline\offlinedata\credit";
libname approval "D:\mili\offline\offlinedata\approval";

libname test "F:\TS\external_data_test\data";


/*好坏的定义*/ 
option compress = yes validvarname = any;
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname orig "F:\TS\offline_model\01_Dataset\01_original";

%let month = '201803';

data target1;
set repayFin.payment(where = (month = &month. and mob > 8)
			keep = 产品小类 apply_code 营业部 产品大类 od_days od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if '20JUN2017'd=>LOAN_DATE >= '01MAY2017'd;	    ***取2017年5月份开始的放款***;
if 产品大类 = "续贷" then delete;	***剔除续贷产品***;	
if not kindex(产品小类 ,"米粒");     ***剔除米粒产品***;	
run;

proc sort data = target1 nodupkey; by apply_code descending mob; run;
proc sort data = target1 nodupkey; by apply_code;run;

data target2;
set target1;
/*if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;*/
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***还款表现期，跟真实的还款期数有一定区别***;

************************************
Bad   —— 在前12个还款期出现曾经逾期30天以上
Good  —— 还款表现期大于5（提前结清的是大于5，正常在还的是大于7）且 当前未逾期 且 曾经逾期天数小于8（门店端催回）
Indet —— 其他
************************************;
format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;

data target3;
set target2(keep = apply_code od_days_ever mob 放款月份 target_label target);
if target^=2;
run;

data target4;
set target3(firstobs=1 obs=1000);
run;


/*取一下基本信息*/
data customer_info;
merge cre.customer_info(in = a) approval.apply_info(in = b) ;
by apply_code;
if a;
run;

data customer_info_2;
set customer_info(keep = 
/*ID_CARD_NO  PHONE1*/
apply_code  进件时间 approve_产品 BRANCH_NAME
DESIRED_LOAN_LIFE  DESIRED_LOAN_AMOUNT  CHILD_COUNT age 教育程度 性别 婚姻状况  
居住省 居住市 居住区 户籍省 户籍市 户籍区 住房性质 
户口性质 单位名称 职位 COMP_ADDRESS CURRENT_INDUSTRY WORK_YEARS 入职时间 工作省 工作市 工作区 
单位性质  房产性质  贷款月还 信用卡月还 社保基数 公积金基数 
IS_HAS_CAR  IS_HAS_HOURSE    
准贷记卡月还 核实收入 核实代发工资 其他负债 YEARLY_INCOME MONTHLY_SALARY MONTHLY_OTHER_INCOME 薪资发放方式
);
/*根据指定字符定位截取字符串,将营业部保留为城市名*/
format 申请城市$50.;
	 if index(BRANCH_NAME, "呼和浩特市第一营业部") then 申请城市 = "呼和浩特";
else if index(BRANCH_NAME, "乌鲁木齐市第一营业部") then 申请城市 = "乌鲁木齐";
else 申请城市=substr(BRANCH_NAME,1, 4);

/*申请贷款期数*/;
if DESIRED_LOAN_LIFE=341  then 贷款申请期限=6;
else if DESIRED_LOAN_LIFE=342 then 贷款申请期限=12;
else if DESIRED_LOAN_LIFE=343 then 贷款申请期限=18;
else if DESIRED_LOAN_LIFE=344 then 贷款申请期限=24;
else if DESIRED_LOAN_LIFE=345 then 贷款申请期限=36;
else if 贷款申请期限=0;

rename 
approve_产品 = 申请产品      age = 年龄   COMP_ADDRESS = 公司地址   CURRENT_INDUSTRY = 所属行业
DESIRED_LOAN_AMOUNT = 申请贷款金额  WORK_YEARS = 工作年限
CHILD_COUNT = 子女个数  IS_HAS_CAR = 是否有车   IS_HAS_HOURSE = 是否有房
YEARLY_INCOME = 年收入  MONTHLY_SALARY = 月收入  MONTHLY_OTHER_INCOME = 月其他收入
;

drop BRANCH_NAME DESIRED_LOAN_LIFE;

run;


data test_ex;
merge target4(in = a) customer_info_2(in = b) ;
by apply_code;
if a;
/*drop  ;*/
run;


/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\user_baseinfo.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= test_ex*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/

PROC EXPORT DATA=test_ex
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="user_baseinfo"; 
RUN;



/*征信数据*/

data test_applycode;
set test_ex(keep = apply_code);
run;

proc sort data=test_applycode nodupkey; by apply_code; run;

proc sort data=credit.Credit_report nodupkey out = crt; by apply_code; run;

/*pboc_credit*/
data pboc_credit;
merge crt(in = a)  test_applycode(in = b);
by apply_code;
if b;
run;

proc sort data=pboc_credit nodupkey; by apply_code; run;

data pboc_credit;
set pboc_credit;
if apply_code ^= "";
run;



/*pboc_base*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_info_base ; by REPORT_NUMBER; run;

data pboc_base;
merge  pboc_credit(in = a)  credit.Credit_info_base(in = b);
by REPORT_NUMBER;
if a;
drop ID ID_CARD ID_NUMBER; 
run;

/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\pboc_base.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_base*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_base
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_base"; 
RUN;



/*pboc_detail*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
data Credit_detail;
set credit.Credit_detail(drop =CREDIT_LINE_AMT_CNY	USEDCREDIT_LINE_AMT_CNY
LOAN_PERIOD	MONTHLY_PAYMENT	CREDIT_BALANCE	OVERDRAFT_BALANCE );
run;
proc sort data=Credit_detail ; by REPORT_NUMBER; run;

data pboc_detail;
merge  pboc_credit(in = a)  Credit_detail(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD;
run;

data pboc_detail;
set pboc_detail;
if apply_code ^= "";
run;

/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\pboc_detail.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_detail*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_detail
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_detail"; 
RUN;

/*pboc_query*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_query_record out = cqrd ; by REPORT_NUMBER; run;

data pboc_query;
merge pboc_credit(in = a)  cqrd(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD QUERY_OPERATOR;
run;


data pboc_query;
set pboc_query;
if apply_code ^= "";
run;


/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\pboc_query.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_query*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_query
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_query"; 
RUN;



/***哈希函数,拼接大数据集;*/
/**/
/*%macro InitVariableInDataset(dataset,withoutvar, withoutvar2='');*/
/**/
/*	%local dsid i nvar vname vtype rc strN strC;*/
/*	%let strN = %str(=.;);*/
/*	%let strC = %str(='';);*/
/*	%let dsid = %sysfunc(open(&dataset));*/
/*	%if &dsid %then*/
/*		%do;*/
/*			%let nvar = %sysfunc(attrn(&dsid,NVARS));*/
/*%*			%put &nvar;*/
/*		   	%do i = 1 %to &nvar;*/
/*		      %let vname = %sysfunc(varname(&dsid,&i));*/
/*			  %if %UPCASE(&vname) ^= %UPCASE(&withoutvar) */
/*				and %UPCASE(&vname) ^= %UPCASE(&withoutvar2) %then %do;*/
/*			      %let vtype = %sysfunc(vartype(&dsid,&i));*/
/*	%*			  	%put _%sysfunc(compress(&vtype))_;*/
/*				  %if %sysfunc(compress(&vtype)) = N %then %do;*/
/*&vname &strN; */
/*				  %end; %else %do;*/
/*&vname &strC;*/
/*				  %end;*/
/**/
/*			  %end;*/
/*		   	%end;*/
/**/
/*			%let rc = %sysfunc(close(&dsid));*/
/*		%end;*/
/*	%else %put %sysfunc(sysmsg());*/
/**/
/*%mend;*/
/**/
/*proc sort data=pboc_credit ; by REPORT_NUMBER; run;*/
/*proc sort data=credit.Credit_query_record out=cqrd; by REPORT_NUMBER; run;*/
/**/
/*data ass;*/
/*	if _n_ = 0 then set pboc_credit;*/
/*	if _n_ = 1 then do;*/
/*		declare hash share(dataset:'pboc_credit');*/
/*					 share.definekey('report_number');*/
/*					 share.definedata(all:'yes');*/
/*					 share.definedone();*/
/*	call missing (of _all_);*/
/*	end;*/
/*	set cqrd;*/
/*	if share.find() = 0 then do; end;*/
/*	else do; %InitVariableInDataset(pboc_credit,report_number); end;*/
/*run;*/
/**/
/**/
/**/





option compress=yes validvarname=any;
libname appRaw odbc  datasrc=approval_nf;
libname brlist "D:\mili\offline\br_blacklist";

data brlist.early_warning_info;
set appraw.early_warning_info;
run;
/*黑名单数据*/
proc sql;
create table br_blacklist as 
SELECT * FROM  brlist.early_warning_info WHERE SOURCE = 'blackList'; quit;
/*调出百融数据*/
data br_blacklist1;
set br_blacklist;
if LEVEL ="BRB";
run;

proc sort data = br_blacklist1 out = br_blacklist2 nodupkey;by apply_no;run;

data br_blacklist3;
set br_blacklist2(keep=APPLY_NO  VALUE_  CONTENT);
rename apply_no = apply_code;
run;

data external_br_blacklist;
merge test_applycode(in = a) br_blacklist3(in = b);
by apply_code;
if a;
run;

filename export "F:\TS\external_data_test\中融微盟\second_test\output\external_br_blacklist.csv" encoding='utf-8';
PROC EXPORT DATA= external_br_blacklist
			 outfile = export
			 dbms = csv replace;
RUN;






*************************************************************************************************;
*需要credit_score里面的风险评级数据;

proc import datafile="F:\TS\external_data_test\中融微盟\数据和测试结果\test_data result.xlsx"
out=lable dbms=excel replace;
SHEET="Data";
scantext=no;
getnames=yes;
run;

data zhongrongwm;
merge lable(in = a) approval.credit_score(in = b);
by apply_code;
if a;
keep apply_code decile 是否通过 score group_Level risk_level;
run;



























/*2018/3/21,重新给出数据，Yichengfan,本次还要给出300条的自动拒绝的客户的数据	*/
/********************************************************************************************/

/*先确定时间维度和数据量大小；再确定取哪些变量*/
option compress = yes validvarname = any;

libname ly_data "\\ly\Datamart\中间表\daily";

libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname daily "D:\mili\offline\daily";
libname cre "D:\mili\offline\centre_data\daily";

libname credit "D:\mili\offline\offlinedata\credit";
libname approval "D:\mili\offline\offlinedata\approval";

libname test "F:\TS\external_data_test\data";


************************************
自动拒绝客户  100
审批拒绝      100
签约拒绝      100
************************************;


*offline
/*自动拒绝的客户  100个*/;
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(1,1,2018);
dt_end=mdy(1,10,2018);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***取2017年12月11日份开始的放款***;
if auto_reject_time <= &dt_end.;	***取2017年12月31日份结束的放款***;
run;

data auto_reject_bad1;
set auto_reject_bad(firstobs=1 obs=100);
run;

*offline
/*人工(审批)拒绝的客户  100个*/;

data approval_reject;
set daily.daily_acquisition(keep =APPLY_CODE 拒绝 批核日期 进件日期  );
if  拒绝 = 1;
if '03JAN2018'd=>进件日期 >= '01JAN2018'd;	    ***取2018年1月份开始的放款***;
run;

data approval_reject1;
set approval_reject(firstobs=1 obs=100);
run;


*offline
/*人工(签约)拒绝的客户  100个*/;
data sign_reject;
set daily.approval_refuse_his(keep =APPLY_CODE 批核月份 批核日期 放款状态 refuse_type );
if  refuse_type = "拒绝";
if 批核月份 = "201801";	    ***取2018年1月份开始的放款***;
run;

data sign_reject1;
set sign_reject(firstobs=1 obs=100);
run;

/*拼接这些拒绝的数据*/
data refuse_customer;
set auto_reject_bad1  approval_reject1  sign_reject1;
run;


/*取一下客户基本信息*/
data customer_info;
merge cre.customer_info(in = a) approval.apply_info(in = b) ;
by apply_code;
if a;
run;

data customer_info_2;
set customer_info(keep = 
/*ID_CARD_NO  PHONE1*/
apply_code  进件时间 approve_产品 BRANCH_NAME
DESIRED_LOAN_LIFE  DESIRED_LOAN_AMOUNT  CHILD_COUNT age 教育程度 性别 婚姻状况  
居住省 居住市 居住区 户籍省 户籍市 户籍区 住房性质 
户口性质 单位名称 职位 COMP_ADDRESS CURRENT_INDUSTRY WORK_YEARS 入职时间 工作省 工作市 工作区 
单位性质  房产性质  贷款月还 信用卡月还 社保基数 公积金基数 
IS_HAS_CAR  IS_HAS_HOURSE    
准贷记卡月还 核实收入 核实代发工资 其他负债 YEARLY_INCOME MONTHLY_SALARY MONTHLY_OTHER_INCOME 薪资发放方式
);
/*根据指定字符定位截取字符串,将营业部保留为城市名*/
format 申请城市$50.;
	 if index(BRANCH_NAME, "呼和浩特市第一营业部") then 申请城市 = "呼和浩特";
else if index(BRANCH_NAME, "乌鲁木齐市第一营业部") then 申请城市 = "乌鲁木齐";
else 申请城市=substr(BRANCH_NAME,1, 4);

/*申请贷款期数*/;
if DESIRED_LOAN_LIFE=341  then 贷款申请期限=6;
else if DESIRED_LOAN_LIFE=342 then 贷款申请期限=12;
else if DESIRED_LOAN_LIFE=343 then 贷款申请期限=18;
else if DESIRED_LOAN_LIFE=344 then 贷款申请期限=24;
else if DESIRED_LOAN_LIFE=345 then 贷款申请期限=36;
else if 贷款申请期限=0;

rename 
approve_产品 = 申请产品      age = 年龄   COMP_ADDRESS = 公司地址   CURRENT_INDUSTRY = 所属行业
DESIRED_LOAN_AMOUNT = 申请贷款金额  WORK_YEARS = 工作年限
CHILD_COUNT = 子女个数  IS_HAS_CAR = 是否有车   IS_HAS_HOURSE = 是否有房
YEARLY_INCOME = 年收入  MONTHLY_SALARY = 月收入  MONTHLY_OTHER_INCOME = 月其他收入
;

drop BRANCH_NAME DESIRED_LOAN_LIFE;

run;

proc sort data = refuse_customer nodupkey ; by apply_code;run;
proc sort data = customer_info_2 nodupkey ; by apply_code;run;

data test_ex;
merge refuse_customer(in = a) customer_info_2(in = b) ;
by apply_code;
if a;
run;


/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\user_baseinfo_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= test_ex*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/

PROC EXPORT DATA=test_ex
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test_300(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="user_baseinfo_300"; 
RUN;



/*征信数据*/

data test_applycode;
set test_ex(keep = apply_code);
run;

proc sort data=test_applycode nodupkey; by apply_code; run;

proc sort data=credit.Credit_report nodupkey out = crt; by apply_code; run;

/*pboc_credit*/
data pboc_credit;
merge crt(in = a)  test_applycode(in = b);
by apply_code;
if b;
run;

proc sort data=pboc_credit nodupkey; by apply_code; run;

data pboc_credit;
set pboc_credit;
if apply_code ^= "";
run;



/*pboc_base*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_info_base ; by REPORT_NUMBER; run;

data pboc_base;
merge  pboc_credit(in = a)  credit.Credit_info_base(in = b);
by REPORT_NUMBER;
if a;
drop ID ID_CARD ID_NUMBER; 
run;

/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\pboc_base_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_base*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_base
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test_300(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_base_300"; 
RUN;



/*pboc_detail*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
data Credit_detail;
set credit.Credit_detail(drop =CREDIT_LINE_AMT_CNY	USEDCREDIT_LINE_AMT_CNY
LOAN_PERIOD	MONTHLY_PAYMENT	CREDIT_BALANCE	OVERDRAFT_BALANCE );
run;
proc sort data=Credit_detail ; by REPORT_NUMBER; run;

data pboc_detail;
merge  pboc_credit(in = a)  Credit_detail(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD;
run;

data pboc_detail;
set pboc_detail;
if apply_code ^= "";
run;

/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\pboc_detail_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_detail*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_detail
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test_300(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_detail_300"; 
RUN;



/*pboc_query*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_query_record out = cqrd ; by REPORT_NUMBER; run;

data pboc_query;
merge pboc_credit(in = a)  cqrd(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD QUERY_OPERATOR;
run;


data pboc_query;
set pboc_query;
if apply_code ^= "";
run;


/*filename export "F:\TS\external_data_test\中融微盟\second_test\output\pboc_query_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_query*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_query
OUTFILE= "F:\TS\external_data_test\中融微盟\second_test\output\zhongrong_test_300(有Y值).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_query_300"; 
RUN;
