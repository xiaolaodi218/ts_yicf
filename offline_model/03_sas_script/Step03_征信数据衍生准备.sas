option compress=yes validvarname=any;
option missing = 0;

libname approval "D:\mili\offline\offlinedata\approval";
libname centre "D:\mili\offline\centre_data\daily";
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname cred "D:\mili\offline\offlinedata\credit";
libname output "F:\TS\offline_model\database\data";
/*---output libname---*/
libname orig "F:\TS\offline_model\01_Dataset\01_original";


/*---------------------------------------------------------------------------*/
*查询原由：	
    query	    查询
	cardquery	信用卡审批
	loquery	    贷款审批
	selfquery	本人查询
	selfquery5	本人查询(互联网个人信用信息服务平台)
	selfquery6	本人查询（临柜）
	insurquery	保前审查
	manaquery	贷后管理

时间：	
    in1m	近1个月
	in3m	近3个月
	in6m	近6个月
	in12m	近12个月
	in24m	近24月

机构：	
    f	            四大行
	def	            除四大行以外
	com	            公司
	prettyloan	    小额贷款
	webank	        微众银行
	consumerfinance	消费金融

计数项：	
    num				数量
	max				最大值
	min				最小值
	interval		时间间隔
	rate			比值;
/*---------------------------------------------------------------------------*/


/*报告日期 近似等于查询日期*/
/*proc sort data=cred.credit_derived_data out =credit_derived_data nodupkey; by report_number; run; */
proc sort data=cred.credit_query_record out=credit_query_record; by report_number; run; /*查询明细加上报告日期*/
proc sort data=cred.credit_info_base out=credit_info_base nodupkey; by report_number; run;
proc sort data=cred.credit_detail out = credit_detail;by report_number ;run;


data credit_query_record_info;
merge credit_query_record(in=a) credit_info_base(in=b);
by report_number;
if a;
*定义"特征"的时间;
if query_date >= intnx("month", report_date, -1, "same") then in1month = 1; else in1month = 0;  /*近1个月*/
if query_date >= intnx("month", report_date, -3, "same") then in3month = 1; else in3month = 0;  /*近2个月*/
if query_date >= intnx("month", report_date, -6, "same") then in6month = 1; else in6month = 0;  /*近6个月*/
if query_date >= intnx("month", report_date, -12, "same") then in12month = 1; else in12month = 0; /*近12个月*/
if query_date >= intnx("month", report_date, -24, "same") then in24month = 1; else in24month = 0; /*近24个月*/

run;

*********************************************************************
    REASON_1(1,"贷款审批"),
    REASON_2(2,"信用卡审批"),
    REASON_3(3,"担保资格审查"),
    REASON_4(4,"贷后管理"),
    REASON_5(5,"本人查询（临柜）"),
    REASON_6(6,"本人查询(互联网个人信用信息服务平台)"),
    REASON_7(7,"特约商户实名审查"),
    REASON_8(8,"保前审查"),
    REASON_9(9,"客户准入资格审查"),
    REASON_10(10,"保后管理"),

*********************************************************************;

/*近3月查询次数1:系统逻辑;*/
/*data query_in3m_1;*/
/*set crRaw.credit_derived_data(keep = REPORT_NUMBER LOAN_GUARANTEE_QUERY_03_MONTH_FR SELF_QUERY_03_MONTH_FREQUENCY_SA);*/
/*近3个月查询次数 = LOAN_GUARANTEE_QUERY_03_MONTH_FR + SELF_QUERY_03_MONTH_FREQUENCY_SA;*/
/*run;*/
/*近3月查询次数1:同一天内的本人查询算作一次；同一机构1个月内重复查询，仅算一次贷款查询次数;*/


/*本人查询（临柜）;本人查询(互联网个人信用信息服务平台)*/
data self_query;
set credit_query_record_info(where = (QUERY_REASON in ("5", "6")));
run;
proc sort data = self_query nodupkey; by report_number query_date; run;

proc sql;
create table self_query_in3m as
select report_number,
	   sum(in3month) as selfquery_in3m,
	   sum(in1month) as selfquery_in1m,
	   sum(in6month) as selfquery_in6m,
	   sum(in12month) as selfquery_in12m,
	   sum(in24month) as selfquery_in24m

from self_query
group by report_number
;
quit;

/*征信查询记录*/
data credit_query;
set credit_query_record_info;
length 查询机构 $50;
if index(QUERY_ORG, "/") then 查询机构 = scan(QUERY_ORG, 1, "/"); else 查询机构 = QUERY_ORG;
run;
proc sort data = credit_query; by report_number 查询机构 descending query_date; run;

data credit_query_organ;
set credit_query;
by report_number 查询机构;
format query_dt yymmdd10.;
retain query_dt;
	 if first.查询机构 then query_dt = query_date;   /*以第一次第一家机构的查询时间为准*/
else if intck("day", query_date, query_dt) <= 30 then del = 1; /*intck函数计算两个日期间隔小于30，标记为1*/
else query_dt = query_date;
run;

/*贷款审批;担保资格审查;保前审查*/
data query_safe_guarantee_183;
set credit_query_organ(where = (QUERY_REASON in ("1", "8", "3")));
run;

proc sql;
create table loan_query_in3m as
select report_number,
		sum(in1month) as loan_query_in1m,
		sum(in3month) as loan_query_in3m,
		sum(in6month) as loan_query_in6m,
		sum(in12month) as loan_query_in12m,
		sum(in24month) as loan_query_in24m
from query_safe_guarantee_183
where del ^= 1
group by report_number
;
quit;

proc sort data = cred.credit_report out = credit_report nodupkey; by report_number; run;
proc sort data = self_query_in3m nodupkey; by report_number; run;
proc sort data = loan_query_in3m nodupkey; by report_number; run;

data query_in3m1;
merge credit_report(in = a) self_query_in3m(in = e) loan_query_in3m(in = f);
by report_number;
if a;
query_in3m_1 = sum(selfquery_in3m,loan_query_in3m,0);
query_in1m = sum(selfquery_in1m,loan_query_in1m,0);
query_in12m = sum(selfquery_in12m,loan_query_in12m,0);
query_in6m = sum(selfquery_in6m,loan_query_in6m,0);
query_in24m = sum(selfquery_in24m,loan_query_in24m,0);

format 征信获取时间 yymmdd10.;

征信获取时间 = datepart(created_time);
drop created_time ;
run;


/*本人查询*/

/*REASON_5(5,"本人查询（临柜）"),*/
/*data self_query;*/
/*set credit_query_record(where = (QUERY_REASON in ("5", "6")));*/
/*run;*/
/*proc sort data = self_query nodupkey; by report_number query_date; run;*/

proc sql;
create table self_query_in3m_5 as
select report_number,
		sum(in1month) as selfquery5_in1m,
		sum(in3month) as selfquery5_in3m,
		sum(sum(in6month),-sum(in3month)) as selfquery5_inl3m,
		sum(in6month) as selfquery5_in6m,
		sum(in12month) as selfquery5_in12m,
		sum(in24month) as selfquery5_in24m
from self_query(where=(QUERY_REASON="5"))
group by report_number;
quit;
proc sql;
create table self_query_in3m_6 as
select report_number,
		sum(in1month) as selfquery6_in1m,
		sum(in3month) as selfquery6_in3m,

		sum(in6month) as selfquery6_in6m,
		sum(sum(in6month),-sum(in3month)) as selfquery6_inl3m,

		sum(in12month) as selfquery6_in12m,
		sum(in24month) as selfquery6_in24m
from self_query(where=(QUERY_REASON="6"))
group by report_number;
quit;
/*本人查询的日期*/
/*data self_query_weekday;*/
/*set self_query;*/
/*by report_number;*/
/*if first.report_number then do;week = weekday(query_date);end;*/
/*else do;delete;end;*/
/*if  in1month = 1 then max_time = 1;*/
/*else if in3month =1 then max_time =2;*/
/*else if in6month =1 then max_time =3;*/
/*else if in12month =1 then max_time =4;*/
/*else if in24month =1 then max_time =5;*/
/*else  max_time=0;*/
/*run;*/

/*最近三个月本人查询最短时间间隔多少天(interval)*/
data self_query_interval;
set self_query(where=(in3month=1));
by report_number;
retain interval time;

if first.report_number then do;interval=. ;time = query_date;end;
else do; interval = intck("day",time,query_date);time=query_date;end;

drop time;
run;

/*最近三个月本人查询最短时间间隔*/
proc sql;
create table  self_query_in3m_interval as 
select report_number,
min(interval) as selfquery_in3m_min_interval,
max(interval) as selfquery_in3m_max_interval 
from self_query_interval 
group by report_number;
quit;

data self_query_in3m;
merge self_query_in3m_interval self_query_in3m_5 self_query_in3m_6;
by report_number;
run;


/**/
/*proc sql;*/
/*create table loan_query_in3m as*/
/*select report_number,*/
/*		sum(in1month) as loan_query_in1m,*/
/*		sum(in3month) as loan_query_in3m,*/
/*		sum(in6month) as loan_query_in6m,*/
/*		sum(in12month) as loan_query_in12m,*/
/*		sum(in24month) as loan_query_in24m*/
/*from query_safe_guarantee where del ^= 1 and QUERY_REASON="1"*/
/*group by report_number*/
/*;*/
/*quit;*/

/*银行类型*/
data test;
set credit_query_organ(where = (QUERY_REASON in ("1")));
format 查询机构大类 $10.;
if kindex(查询机构,"农村信用") or kindex(查询机构,"信用联社") or kindex(查询机构,"农村商业银行") or kindex(查询机构,"农村合作银行") then  do;查询机构="农村合作银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"包商银行") then do; 查询机构="包商银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"徽商银行") then do; 查询机构="徽商银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"村镇银行") then do; 查询机构="村镇银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"渤海银行") then do; 查询机构="渤海银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"北京银行") then do; 查询机构="北京银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"成都银行") then do; 查询机构="成都银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"长沙银行")  or kindex(查询机构,"长沙市商业银行") then do; 查询机构="长沙银行" ;查询机构大类="银行"; 查询机构小类="地方银行";end ;
if kindex(查询机构,"东莞银行") then do; 查询机构="东莞银行" ;查询机构大类="银行"; 查询机构小类="地方银行";end ;
if kindex(查询机构,"福建海峡银行") then do; 查询机构="福建海峡银行" ;查询机构大类="银行";查询机构大类="银行"; 查询机构小类="地方银行";end ;
if kindex(查询机构,"富滇银行") then do; 查询机构="富滇银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"广东南粤") then do; 查询机构="广东南粤银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"广东华兴银行") then do; 查询机构="广东华兴银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"广发银行") then do; 查询机构="广发银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"广州银行") then do; 查询机构="广州银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"哈尔滨银行") then do; 查询机构="哈尔滨银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"汉口银行") then do; 查询机构="汉口银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"杭州银行") then do; 查询机构="杭州银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"恒丰银行") then do; 查询机构="恒丰银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"华夏银行") then do; 查询机构="华夏银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"江苏长江商业银行") then do; 查询机构="江苏长江商业银行" ;查询机构大类="银行";查询机构小类="地方银行";end ;
if kindex(查询机构,"中信银行") then do; 查询机构="中信银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"中国邮政储蓄银行") then do; 查询机构="中国邮政储蓄银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"中国银行") then do; 查询机构="中国银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"中国农业银行") then do; 查询机构="中国农业银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"中国民生银行") then do; 查询机构="中国民生银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"中国建设银行") then do; 查询机构="中国建设银行" ;查询机构大类="银行";查询机构小类="国有银行";end ;
if kindex(查询机构,"中国光大银行") then do; 查询机构="中国光大银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"中国工商银行") then do; 查询机构="中国工商银行" ;查询机构大类="银行";end ;
if kindex(查询机构,"浙商银行") then do; 查询机构="浙商银行" ;查询机构大类="银行";end ;
/*if kindex(查询机构,"银行") then 查询机构大类="银行"; */
if kindex(查询机构,"小额贷款") then 查询机构大类="小额贷款"; 
if kindex(查询机构,"担保") then 查询机构大类="担保"; 
if kindex(查询机构,"消费金融") then 查询机构大类="消费金融"; 
if kindex(查询机构,"汽车金融") then 查询机构大类="汽车金融"; 
if kindex(查询机构,"保险") then 查询机构大类="保险"; 
if kindex(查询机构,"信托") then 查询机构大类="信托"; 
if kindex(查询机构,"财务") then 查询机构大类="财务有限公司"; 
if kindex(查询机构,"花旗") then 查询机构大类="银行"; 
if kindex(查询机构,"微众") then 查询机构大类="微众银行"; 

if kindex(查询机构,"住房公积金") then 查询机构大类="住房公积金"; 
if kindex(查询机构,"中和农信项目管理有限公司") or kindex(查询机构,"江苏小贷信息管理中心") then 查询机构大类="信贷"; 
if 查询机构大类="" then 查询机构大类="其他" ; 
/*农村信用合作联社*/
run;

/*机构分布*/
proc freq data = test;
table 查询机构;
run;
/*proc freq data=test noprint;*/
/*table 查询机构/out=cac;*/
/*run;*/

/*微众银行*/
data webank ;
set credit_query_organ(where=(kindex(查询机构,"微众")));
run;

proc sql;
create table webank_query1 as 
             select report_number,
			 sum(in1month) as webank_query_in1m,
			 sum(in3month) as webank_query_in3m,
			 sum(in6month) as webank_query_in6m,
			 sum(in12month) as webank_query_in12m,
			 sum(in24month) as webank_query_in24m

from webank 
group by report_number;
quit;
proc sql;
create table webank_query_qc as 
             select report_number,
			 sum(in1month) as webank_query_qc_in1m,
			 sum(in3month) as webank_query_qc_in3m,
			 sum(in6month) as webank_query_qc_in6m,
			 sum(in12month) as webank_query_qc_in12m,
			 sum(in24month) as webank_query_qc_in24m

from webank(where=(del ^= 1)) 
group by report_number;
quit;
proc sql;
create table webank_query_1 as 
             select report_number,
			 sum(in1month) as webank_loquery_in1m,
			 sum(in3month) as webank_loquery_in3m,
			 sum(in6month) as webank_loquery_in6m,
			 sum(in12month) as webank_loquery_in12m,
			 sum(in24month) as webank_loquery_in24m

from webank(where=(QUERY_REASON ="1")) 
group by report_number;
quit;
proc sql;
create table webank_query_4 as 
             select report_number,
			 sum(in1month) as webank_manaquery_in1m,
			 sum(in3month) as webank_manaquery_in3m,
			 sum(in6month) as webank_manaquery_in6m,
			 sum(in12month) as webank_manaquery_in12m,
			 sum(in24month) as webank_manaquery_in24m

from webank(where=(QUERY_REASON ="4")) 
group by report_number;
quit;
data webank_query;
merge webank_query1  webank_query_1 webank_query_4 webank_query_qc;
by report_number;
run;


/*消费金融*/
data consumer_finance ;
set credit_query_organ(where=(kindex(查询机构,"消费金融")));
run;

proc sql;
create table consumer_finance_query1 as select report_number,
		sum(in1month) as consumerfinance_query_in1m,           /*近1个月消费金融机构查询次数*/
		sum(in3month) as consumerfinance_query_in3m,
		sum(in6month) as consumerfinance_query_in6m,
		sum(in12month) as consumerfinance_query_in12m,
		sum(in24month) as consumerfinance_query_in24m

from consumer_finance group by report_number;quit;

proc sql;
create table consumer_finance_query_1 as select report_number,
		sum(in1month) as consumerfinance_loquery_in1m,        /*近1个月消费金融机构贷款审批查询次数*/
		sum(in3month) as consumerfinance_loquery_in3m,  
		sum(in6month) as consumerfinance_loquery_in6m,
		sum(in12month) as consumerfinance_loquery_in12m,
		sum(in24month) as consumerfinance_loquery_in24m

from consumer_finance(where=(QUERY_REASON ="1")) group by report_number;quit;

proc sql;
create table consumer_finance_query_4 as select report_number,
		sum(in1month) as consumerfinance_manaquery_in1m,          /*近1个月消费金融机构贷后管理查询次数*/
		sum(in3month) as consumerfinance_manaquery_in3m,
		sum(in6month) as consumerfinance_manaquery_in6m,
		sum(in12month) as consumerfinance_manaquery_in12m,
		sum(in24month) as consumerfinance_manaquery_in24m

from consumer_finance(where=(QUERY_REASON ="4")) group by report_number;quit;

data consumer_finance_query;
merge consumer_finance_query1  consumer_finance_query_1 consumer_finance_query_4;
by report_number;
run;


/*小额贷款*/
data petty_loan ;
set credit_query_organ(where=(kindex(查询机构,"小额贷款")));
run;

proc sql;
create table petty_loan_query1 as select report_number,
		sum(in1month) as pettyloan_query_in1m,
		sum(in3month) as pettyloan_query_in3m,
		sum(in6month) as pettyloan_query_in6m,
		sum(in12month) as pettyloan_query_in12m,
		sum(in24month) as pettyloan_query_in24m

from petty_loan group by report_number;quit;

proc sql;
create table petty_loan_query_1 as select report_number,
		sum(in1month) as pettyloan_loquery_in1m_1,
		sum(in3month) as pettyloan_loquery_in3m_1,
		sum(in6month) as pettyloan_loquery_in6m_1,
		sum(in12month) as pettyloan_loquery_in12m_1,
		sum(in24month) as pettyloan_loquery_in24m_1

from petty_loan(where=(QUERY_REASON ="1")) group by report_number;quit;

proc sql;
create table petty_loan_query_4 as select report_number,
		sum(in1month) as pettyloan_manaquery_in1m,
		sum(in3month) as pettyloan_manaquery_in3m,
		sum(in6month) as pettyloan_manaquery_in6m,
		sum(in12month) as pettyloan_manaquery_in12m,
		sum(in24month) as pettyloan_manaquery_in24m

from petty_loan(where=(QUERY_REASON ="4")) group by report_number;quit;

data petty_loan_query;
merge petty_loan_query1  petty_loan_query_1 petty_loan_query_4;
by report_number;
run;


/*保前审查、贷款、信用卡审批机构数*/
proc sort data = credit_query_organ  out = loan_query_com nodupkey;by report_number 查询机构 QUERY_REASON;run;
proc sql;
create table card_qurry_com_num as 
select report_number,count(查询机构) as cardqurry_com_num 
from loan_query_com(where=(QUERY_REASON ="2")) 
group by report_number;
quit;
proc sql;
create table insur_qurry_com_num as 
select report_number,count(查询机构) as insurqurry_com_num
from loan_query_com(where=(QUERY_REASON ="8")) 
group by report_number;
quit;
proc sql;
create table lo_qurry_com_num as 
select report_number,count(查询机构) as loqurry_com_num
from loan_query_com(where=(QUERY_REASON ="1")) 
group by report_number;quit;
proc sql;
create table num_petty_loan as 
select report_number,count(查询机构) as num_pettyloan 
from loan_query_com(where=(QUERY_REASON ="1" and kindex(查询机构,"小额贷款"))) 
group by report_number;quit;

data num_com;
merge card_qurry_com_num insur_qurry_com_num num_petty_loan lo_qurry_com_num;
by report_number;
run;

/*同一家机构的查询*/
proc sql;
create table com_same_loan  as 
select report_number,查询机构,QUERY_REASON,count(查询机构) as com_querry_num
from credit_query_organ 
group by report_number,查询机构,QUERY_REASON;
quit;
/*转置问题*/
proc transpose data = com_same_loan(where=(QUERY_REASON in ("1","2","8"))) out = com_same_loan1 prefix=D;
id QUERY_REASON;
var com_querry_num;
by  report_number 查询机构;
run;
/*查询机构贷款审批次数最大值*/
proc sql;
create table com_same_loan2 as 
		select  report_number,
		max(D1) as com_loqurry_num,
		max(D2) as com_locard_num,
		max(D8) as same_com_insur_qurry_num 
from com_same_loan1
group by report_number;
quit;


/*近三个月*/
proc sql;
create table com_same_loan_in3m  as 
			 select report_number,
			 查询机构,
			 QUERY_REASON,
			 count(查询机构) as com_querry_num
from credit_query_organ(where=(in3month=1)) 
group by report_number,查询机构,QUERY_REASON;
quit;

/*查询机构贷款审批次数最大值*/
proc transpose data = com_same_loan_in3m(where=(QUERY_REASON in ("1","2","8"))) out = com_same_loan1_in3m prefix=D;
id QUERY_REASON;
var com_querry_num;
by  report_number 查询机构;
run;
/*查询机构贷款审批次数最大值*/
proc sql;
create table com_same_loan2_in3m as 
			 select  report_number,
			 max(D1) as same_com_lo_qurry_num_3m ,
			 max(D2) as same_com_lo_card_num_3m ,
			 max(D8) as same_com_insur_qurry_num_3m 
from com_same_loan1_in3m
group by report_number;
quit;

data com_same_loan_num;
merge  com_same_loan2 com_same_loan2_in3m ;
by report_number;
run;


/*信用卡审批次数*/
data card_qurry;
set credit_query_organ(where = (QUERY_REASON ="2"));
run;
proc sql;
create table card_query_in3m as
select report_number,
		sum(in1month) as card_query_in1m,
		sum(in3month) as card_query_in3m,
		sum(in6month) as card_query_in6m,
		sum(in12month) as card_query_in12m,
		sum(in24month) as card_query_in24m
from card_qurry(where=(del^=1))
group by report_number;
quit;
proc sql;
create table card_query_in3m_max_1 as
select report_number,查询机构,
		sum(in1month) as card_query_in1m,
		sum(in3month) as card_query_in3m,
		sum(in6month) as card_query_in6m,
		sum(in12month) as card_query_in12m,
		sum(in24month) as card_query_in24m
from card_qurry
group by report_number,查询机构;
quit;
proc sql;
create table card_query_in3m_max as
select report_number,
		max(card_query_in1m) as card_query_in1m_max,
		max(card_query_in3m) as card_query_in3m_max,
		max(card_query_in6m) as card_query_in6m_max,
		max(card_query_in12m) as card_query_in12m_max,
		max(card_query_in24m) as card_query_in24m_max
from card_query_in3m_max_1
group by report_number;
quit;

/*贷后管理*/
data management_loan;
set credit_query_organ(where = (QUERY_REASON ="4"));
run;
proc sql;
create table mana_loan_in3m as
select report_number,
		sum(in1month) as mana_loan_in1m,
		sum(in3month) as mana_loan_in3m,
		sum(in6month) as mana_loan_in6m,
		sum(in12month) as mana_loan_in12m,
		sum(in24month) as mana_loan_in24m
from management_loan
group by report_number;
quit;

proc sql;
create table mana_loan_f as
select report_number,
		sum(in1month) as mana_loan_in1m_f,
		sum(in3month) as mana_loan_in3m_f,
		sum(in6month) as mana_loan_in6m_f,
		sum(in12month) as mana_loan_in12m_f,
		sum(in24month) as mana_loan_in24m_f
from management_loan(where=(index(查询机构,"中国银行") or index(查询机构,"中国工商银行") 
or index(查询机构,"中国农业银行")  or index(查询机构,"中国建设银行")))
group by report_number;
quit;

proc sort data = mana_loan_in3m;by report_number;run;
proc sort data = mana_loan_f;by report_number;run;

data mana_loan_in3m;
merge mana_loan_in3m mana_loan_f;
by report_number;
mana_loan_in1m_de_f = sum(mana_loan_in1m, -mana_loan_in1m_f);
mana_loan_in3m_de_f = sum(mana_loan_in3m, -mana_loan_in3m_f);
mana_loan_in6m_de_f = sum(mana_loan_in6m, -mana_loan_in6m_f);
mana_loan_in12m_de_f = sum(mana_loan_in12m, -mana_loan_in12m_f);
mana_loan_in24m_de_f = sum(mana_loan_in24m, -mana_loan_in24m_f);

run;


/*保险审批次数*/
data insur_qurry;
set credit_query_organ(where = (QUERY_REASON in("8")));
run;

proc sql;
create table insur_query_in3m as
select report_number,
		sum(in1month) as insur_query_in1m,
		sum(in3month) as insur_query_in3m,
		sum(in6month) as insur_query_in6m,
		sum(in12month) as insur_query_in12m,
		sum(in24month) as insur_query_in24m

from insur_qurry
group by report_number;
quit;

/*贷款审批次数*/
data lo_qurry;
set credit_query_organ(where = (QUERY_REASON ="1"));
run;

proc sql;
create table lo_query_in3m as
select report_number,
		sum(in1month) as lo_query_in1m,
		sum(in3month) as lo_query_in3m,
		sum(in6month) as lo_query_in6m,
		sum(in12month) as lo_query_in12m,
		sum(in24month) as lo_query_in24m
from lo_qurry(where=(del^=1))
group by report_number;
quit;

proc sql;
create table lo_query_f as
select report_number,
		sum(in1month) as lo_query_in1m_f,
		sum(in3month) as lo_query_in3m_f,
		sum(in6month) as lo_query_in6m_f,
		sum(in12month) as lo_query_in12m_f,
		sum(in24month) as lo_query_in24m_f
from lo_qurry( where=((del^=1) and (index(查询机构,"中国银行")  or index(查询机构,"中国工商银行") 
or index(查询机构,"中国农业银行") or index(查询机构,"中国建设银行"))))
group by report_number;
quit;
proc sort data = lo_query_in3m;by report_number;run;
proc sort data = lo_query_f;by report_number;run;

data lo_query_in3m;
merge lo_query_in3m lo_query_f;
by report_number;
lo_query_in1m_de_f = sum(lo_query_in1m,-lo_query_in1m_f);
lo_query_in3m_de_f = sum(lo_query_in3m,-lo_query_in3m_f);
lo_query_in6m_de_f = sum(lo_query_in6m,-lo_query_in6m_f);
lo_query_in12m_de_f = sum(lo_query_in12m,-lo_query_in12m_f);
lo_query_in24m_de_f = sum(lo_query_in24m,-lo_query_in24m_f);

run;


/*/*最近3月查询次数2: 贷款审批、保前审查、担保资格审查、本人查询*/*/
/*proc sql;*/
/*create table query_in3m_2 as*/
/*select report_number,*/
/*		sum(in3month) as query_in3m_2*/
/*from credit_query_record*/
/*where QUERY_REASON in ("1", "8", "3", "5", "6")*/
/*group by report_number*/
/*;*/
/*quit;*/
/**/
/*/*最近3月查询次数3: 贷款审批、保前审查、担保资格审查、本人查询、信用卡审批*/*/
/*proc sql;*/
/*create table query_in3m_3 as*/
/*select report_number,*/
/*		sum(in3month) as query_in3m_3*/
/*from credit_query_record*/
/*where QUERY_REASON in ("1", "8", "3", "5", "6", "2")*/
/*group by report_number*/
/*;*/
/*quit;

data record;
merge credit_info_base  credit_detail;
by report_number;
run;

/*信用卡情况*/
data test2;
set record;
if BUSI_TYPE="CREDIT_CARD" and CURRENCY_TYPE = "人民币"  then 国内信用卡=1;
else  if BUSI_TYPE="CREDIT_CARD" and CURRENCY_TYPE ^= "人民币"  then 国外信用卡=1;
if 国内信用卡 then 国内信用卡额度=CREDIT_LINE_AMT;
if 国内信用卡 and ACCT_STATUS in( "11","17")    then 正在使用中的信用卡=1;
else if 国内信用卡 and ACCT_STATUS="14" then 销户信用卡=1;
else if 国内信用卡 and ACCT_STATUS="15" then 呆账信用卡=1;
else if 国内信用卡 and ACCT_STATUS="16" then 未激活信用卡=1;

if 国内信用卡 and ACCT_STATUS="11" then 正常使用中的信用卡=1;
else if  国内信用卡 and ACCT_STATUS="17" then 目前逾期的信用卡=1;

if 正在使用中的信用卡 and PASTDUE_BY60_CNT>0 then 逾期小于90天的正在使用中的信用卡=1;
if 正在使用中的信用卡 and PASTDUE_M3_BY60_CNT>0 then 逾期大于90天的正在使用中的信用卡=1;
if  PASTDUE_BY60_CNT>0 then 逾期小于90天的信用卡=1;
if  PASTDUE_M3_BY60_CNT>0 then 逾期大于90天的信用卡=1;

if intck ("year",DATE_OPENED,REPORT_DATE)<=2 and 国内信用卡 then 近两年开户信用卡=1;
时间差别=intck ("year",DATE_OPENED,REPORT_DATE);

if kindex(ORG_NAME,"中国银行") or index(ORG_NAME,"中国工商银行") 
or index(ORG_NAME,"中国农业银行")  or index(ORG_NAME,"中国建设银行") then 四大行额度=CREDIT_LINE_AMT;

run;

proc sql;
create table card_info  as 
select report_number,
sum(国内信用卡) as credit_card_num_cn,
sum(国外信用卡) as credit_card_num_fo,
sum(正在使用中的信用卡)as use_credit_card_numb,
sum(销户信用卡) as can_card_num,
sum(销户信用卡)/count(*)as can_card_rate, 
sum(未激活信用卡) as inac_card_num,
sum(未激活信用卡)/count(*) as inac_card_rate ,
sum(呆账信用卡) as bad_card_num,
sum(呆账信用卡)/sum(国内信用卡) as bad_card_rate,
sum(正常使用中的信用卡) as normal_card_num,
sum(目前逾期的信用卡) as pres_overdue_num,
sum(目前逾期的信用卡)/sum(正在使用中的信用卡) as pres_overdue_card_rate,
count(逾期小于90天的信用卡)/sum(国内信用卡) as his_overdue_card_rate, 
count(逾期小于90天的信用卡) as his_overdue_card_num ,
sum(近两年开户信用卡) as near_2y_card_num,
max(国内信用卡额度) as max_card_line,
mean(国内信用卡额度) as mean_card_line,
min(国内信用卡额度)as min_card_line,
var(国内信用卡额度)as var_card_line,
max(四大行额度) as max_card_line_bf,
min(四大行额度) as min_card_line_bf,
mean(四大行额度) as mean_card_line_bf,
var(四大行额度) as var_card_line_bf

from test2(where=(BUSI_TYPE="CREDIT_CARD")) 
group by report_number;
quit;

/*贷款情况*/
/*时间 金额 机构 贷款原因 贷款状态*/
data test3;
set record(where=(BUSI_TYPE="LOAN" ));
if ACCT_STATUS="3" and intck ("month",DATE_OPENED,REPORT_DATE)<=6  then 近半年结清贷款=1;
if ACCT_STATUS="3" and intck ("month",DATE_OPENED,REPORT_DATE)<=12  then 近一年结清贷款=1;
if ACCT_STATUS="3" and intck ("month",DATE_OPENED,REPORT_DATE)<=24  then 近两年结清贷款=1;
if intck ("month",DATE_OPENED,REPORT_DATE)<=24  then 近两年批贷=1;

if ACCT_STATUS="3"   then 结清贷款=1;
if ACCT_STATUS="1" then 未结清贷款=1;
if ACCT_STATUS="3" and CREDIT_LINE_AMT>1000  then 万元以上结清=1;
time = intck ("month",DATE_OPENED,REPORT_DATE);
end_time = intck("month",REPORT_DATE,DATE_CLOSED);
if kindex(ORG_NAME,"消费金融") then 消费金融贷款=1;
if 消费金融贷款 and ACCT_STATUS="3" and CREDIT_LINE_AMT>10000 then  未结清消费金融贷款=1;
if 近两年批贷=1 and kindex(ORG_NAME,"小额贷款") then 小额贷款=1;
if 近两年结清贷款=1 and kindex(ORG_NAME,"银行") then 银行结清贷款=1;
if 近两年批贷=1 and kindex(ORG_NAME,"微众") then 微众银行=1;
if 近两年批贷=1 and kindex(ORG_NAME,"银行") then 银行贷款=1;

if 近两年批贷=1 and kindex(ORG_NAME,"中国银行") or 
                   index(ORG_NAME,"中国工商银行") or 
                   index(ORG_NAME,"中国农业银行")  or 
                   index(ORG_NAME,"中国建设银行") then 四大行贷款=1;
if 近两年批贷=1 and kindex(SUB_BUSI_TYPE,"个人消费") then 个人消费贷款=1;
if 近两年批贷=1 and kindex(SUB_BUSI_TYPE,"个人经营") then 个人经营贷款=1;
if 近两年批贷=1 and kindex(SUB_BUSI_TYPE,"其他") then 其他贷款=1;
if 近两年批贷=1 and kindex(SUB_BUSI_TYPE,"个人汽车贷款") or 
                    kindex(SUB_BUSI_TYPE,"个人住房") or 
                    kindex(SUB_BUSI_TYPE,"个人商用房") or 
                    kindex(SUB_BUSI_TYPE,"个人助学贷款") then 个人高消费贷款=1;
run;

/*贷款情况*/
/*-------------------------------------------贷款机构分类-------------------------------------*/
data loan_org;
set record(where=(BUSI_TYPE="LOAN" ));
if intck ("month",DATE_OPENED,REPORT_DATE)<=24 and ACCT_STATUS="1";

format 查询机构大类 $10.;
if kindex(ORG_NAME,"农村信用") or  kindex(ORG_NAME,"信用联社") or 
								   kindex(ORG_NAME,"农村商业银行") or 
                                   kindex(ORG_NAME,"农村合作银行") then  do;查询机构="农村合作银行" ;查询机构大类="农村信用";end ;

if kindex(ORG_NAME,"城市信用") then 查询机构大类="城市信用"; 
if kindex(ORG_NAME,"银行") then 查询机构大类="银行"; 
if kindex(ORG_NAME,"小额贷款") then 查询机构大类="小额贷款"; 
if kindex(ORG_NAME,"担保") then 查询机构大类="担保"; 
if kindex(ORG_NAME,"消费金融") then 查询机构大类="消费金融"; 
if kindex(ORG_NAME,"汽车金融") then 查询机构大类="汽车金融"; 
if kindex(ORG_NAME,"保险") then 查询机构大类="保险"; 
if kindex(ORG_NAME,"信托") then 查询机构大类="信托"; 
if kindex(ORG_NAME,"财务") then 查询机构大类="财务有限公司"; 
if kindex(ORG_NAME,"花旗") then 查询机构大类="银行"; 
if kindex(ORG_NAME,"微众") then 查询机构大类="微众银行"; 

if kindex(ORG_NAME,"住房公积金") then 查询机构大类="住房公积金"; 
if kindex(ORG_NAME,"中和农信项目管理有限公司") or kindex(查询机构,"江苏小贷信息管理中心") then 查询机构大类="信贷"; 
if kindex(ORG_NAME,"自立服务") then 查询机构大类="小额贷款"; 
if kindex(ORG_NAME,"中心联社") then 查询机构大类="中心联社"; 

if 查询机构大类="" then 查询机构大类="其他" ; 

run;

proc sql;
create table test4  as select report_number ,查询机构大类,count(*) as 贷款次数 from loan_org group by report_number,查询机构大类;
quit;

proc transpose data = test4 out =aaa(drop=_NAME_);
var 贷款次数;
ID 查询机构大类;
by report_number ;
run;
data aaa1;
set aaa;
run;


/*==================================================end=========================================================*/

proc sql;
create table loan_info_per as 
select report_number,

count(*) as loan_num ,
count(PASTDUE_BY60_CNT) as credit_card_number_l60,
count(PASTDUE_M3_BY60_CNT) as credit_card_number_m90,
count(PASTDUE_M3_BY60_CNT)/count(*)as credit_card_number_m90_rate,
count(PASTDUE_BY60_CNT)/count(*) as credit_card_number_l60_rate,

sum(消费金融贷款) as consumer_finance_loan_num ,
sum(个人高消费贷款) as high_consum_loan_num,
sum(近半年结清贷款) as clear_loan_num_6m ,
sum(近一年结清贷款) as clear_loan_num_12m, 
sum(近两年结清贷款)as clear_loan_num_24m,
sum(个人消费贷款) as consum_loan_num,
sum(未结清贷款) as unclear_loan_num,
sum(结清贷款) as clear_loan_num,
sum(小额贷款) as petty_loan_num,
sum(个人经营贷款) as bus_loan_num,
sum(近两年批贷) as loan_num_in24m,
sum(银行结清贷款) as 银行结清贷款,
sum(其他贷款)as  other_loan_num,
sum(四大行贷款) as 四大行贷款,
sum(微众银行) as webank_loan,
sum(银行贷款) as 银行贷款,

min(time) as near_loan_time,
max(time) as far_loan_time,
max(CREDIT_LINE_AMT) as max_loanline

from  test3 
group by report_number ;
quit;

data loan_info1;
set loan_info_per;
if 银行贷款 <1  and consumer_finance_loan_num >=1  then 银行消金 =2 ;
else if 银行贷款 <1  and consumer_finance_loan_num <1  then 银行消金 =0 ;
else if 银行贷款 >0  and consumer_finance_loan_num <1  then 银行消金 =1 ;
else if 银行贷款 >0  and consumer_finance_loan_num >=1  then 银行消金 =3 ;

if 银行贷款 <1  and petty_loan_num >=1  then 银行小额 =2 ;
else if 银行贷款 <1  and petty_loan_num <1  then 银行消金 =0 ;
else if 银行贷款 >0  and petty_loan_num <1  then 银行消金 =1 ;
else if 银行贷款 >0  and petty_loan_num >=1  then 银行消金 =3 ;

if 银行贷款 <1  and  sum(consumer_finance_loan_num,petty_loan_num)  >=1  then 无银行有消费贷 =2 ;
else if 银行贷款 <1  and sum(consumer_finance_loan_num,petty_loan_num) <1  then 银行消金 =0 ;
else if 银行贷款 >0  and sum(consumer_finance_loan_num,petty_loan_num) <1  then 银行消金 =1 ;
else if 银行贷款 >0  and sum(consumer_finance_loan_num,petty_loan_num) >=1  then 银行消金 =3 ;

if sum(银行贷款,webank_loan) <1   then 银行微众 =0 ;else 银行微众=1 ;

run;


proc sql;
create table loan_info1_1 as 
select report_number, sum(CREDIT_LINE_AMT) as new_loan_in12m
from  test3(where=(time<=12)) 
group by report_number ;
quit;

proc sql;
create table loan_info1_2 as 
select report_number, sum(LOAN_BALANCE) as due_cos_loan_balance_in12m
from  test3(where=(end_time<=12)) 
group by report_number ;
quit;

proc sql;
create table loan_info1_3 as 
select report_number, sum(LOAN_BALANCE) as unclear_loan_amount,
sum(MONTHLY_PAYMENT) as umclear_month_pay
from  test3(where=(未结清贷款=1)) 
group by report_number ;
quit;

proc sql;
create table loan_info2 as 
select report_number,max(CREDIT_LINE_AMT) as max_car_loan_line,
mean(CREDIT_LINE_AMT) as ave_car_loan_line, 
min(time) as near_car_loan  ,
min(CREDIT_LINE_AMT) as min_car_loan_line,
sum(CREDIT_LINE_AMT)  as 个人汽车贷款数
from  test3(where=(kindex(SUB_BUSI_TYPE,"个人汽车贷款") and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;
proc sql;
create table loan_info3 as 
select report_number,max(CREDIT_LINE_AMT) as max_man_loan_line,
mean(CREDIT_LINE_AMT) as ave_man_loan_line
, min(time) as near_man_loan  ,
min(CREDIT_LINE_AMT) as min_man_loan_line,
sum(CREDIT_LINE_AMT)  as 个人经营数
from test3(where=(kindex(SUB_BUSI_TYPE,"个人经营") and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;
proc sql;
create table loan_info4 as 
select report_number,max(CREDIT_LINE_AMT) as max_house_loan_line,
mean(CREDIT_LINE_AMT) as ave_house_loan_line,
min(time) as near_house_loan ,
min(CREDIT_LINE_AMT) as min_house_loan_line,
sum(CREDIT_LINE_AMT)  as 个人住房
from test3(where=((kindex(SUB_BUSI_TYPE,"个人住房")or kindex(SUB_BUSI_TYPE,"个人商用房")) and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;
proc sql;
create table loan_info4 as 
select report_number,
max(CREDIT_LINE_AMT) as max_percos_loan_line,
mean(CREDIT_LINE_AMT) as ave_percos_loan_line,
min(time) as near_percos_loan ,
min(CREDIT_LINE_AMT) as min_percos_loan_line,
sum(CREDIT_LINE_AMT)  as 个人消费
from  test3(where=((kindex(SUB_BUSI_TYPE,"个人消费")) and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;

data loan_info;
merge loan_info1 loan_info1_1 loan_info1_2 loan_info2 loan_info3 loan_info4 loan_info1_3;
by report_number;
run;



/*计算查询后未放款的机构数数量*/
data org_loan;
set record(where=(BUSI_TYPE="LOAN"  ));
if intck ("year",DATE_OPENED,REPORT_DATE)<=2;
/*if kindex(ORG_NAME,"");*/
run;
/*proc sort data = xiaojin_loan nodupkey ;by report_number ORG_NAME;run;*/

proc sql ;
create table not_loan_query_1 as 
select a.*,b.* from lo_qurry as a inner join org_loan as b  on a.report_number = b.report_number and a.查询机构=b.ORG_NAME and a.query_dt < b.DATE_OPENED;
quit;
proc sort data = not_loan_query_1 nodupkey;by report_number 查询机构 ;run;
proc sql ;
create table loan_query_2 as 
select report_number,count(*) as 发放贷款数 from not_loan_query_1 group by report_number ;
quit;
/*未发放信用卡*/
data org_card;
set record(where=(BUSI_TYPE="CREDIT_CARD"));
if intck ("year",DATE_OPENED,REPORT_DATE)<=2;
/*if kindex(ORG_NAME,"");*/
run;
/*proc sort data = xiaojin_loan nodupkey ;by report_number ORG_NAME;run;*/


proc sql ;
create table not_card_query_1 as 
select a.*,b.* from card_qurry as a inner join org_card as b  on a.report_number = b.report_number and a.查询机构=b.ORG_NAME and a.query_dt < b.DATE_OPENED;
quit;
proc sort data = not_card_query_1 nodupkey;by report_number 查询机构 ;run;
proc sql ;
create table card_query_2 as 
select report_number,count(*) as 发放信用卡数 from not_card_query_1 
group by report_number ;
quit;


proc sort data = self_query_in3m nodupkey; by report_number; run;
proc sort data = loan_query_in3m nodupkey; by report_number; run;
proc sort data = card_query_in3m nodupkey; by report_number; run;
proc sort data = insur_query_in3m nodupkey; by report_number; run;
proc sort data = lo_query_in3m nodupkey; by report_number; run;
proc sort data = mana_loan_in3m nodupkey; by report_number; run;
proc sort data = num_com nodupkey; by report_number; run;

proc sort data = cred.credit_derived_data out =credit_derived_data(keep = REPORT_NUMBER ID_CARD)  nodupkey; by report_number; run;


/*--------------------所有数据-------------------------*/
data credit_all_data;
merge query_in3m1(in = a)
credit_derived_data(in = b) 
card_query_in3m(in = c) 
/*insur_query_in3m(in = d) */
self_query_in3m(in = e) 
lo_query_in3m(in = f) 
mana_loan_in3m(in = g)  
num_com(in = h)   
card_info(in = i)   
loan_info(in = j)   
loan_query_2(in = k)  
/*webank_query(in = l)  */
consumer_finance_query(in = m)  
petty_loan_query(in = n)  
card_query_in3m_max(in = o)  
card_query_2(in = p) 
com_same_loan_num(in = q)  
; 
by report_number ;
if a;

self_loan_dv_in1m=sum( selfquery_in1m,-lo_query_in1m,0);
self_loan_dv_in3m=sum( selfquery_in3m,-lo_query_in3m,0);
self_loan_dv_in6m=sum( selfquery_in6m,-lo_query_in6m,0);
self_loan_dv_in12m=sum( selfquery_in12m,-lo_query_in12m,0);
self_loan_dv_in24m=sum( selfquery_in24m,-lo_query_in24m,0);
self_card_query_in6m=sum(selfquery_in6m,card_query_in6m,0);
self_card_query_in3m=sum(selfquery_in3m,card_query_in3m,0);
self_card_query_in1m=sum(selfquery_in1m,card_query_in1m,0);
self_card_query_in12m=sum(selfquery_in12m,card_query_in12m,0);
self_card_query_in24m=sum(selfquery_in24m,card_query_in24m,0);
self_loan_query_in6m=sum(selfquery_in6m,lo_query_in6m,0);
self_loan_query_in3m=sum(selfquery_in3m,lo_query_in3m,0);
self_loan_query_in1m=sum(selfquery_in1m,lo_query_in1m,0);
self_loan_query_in12m=sum(selfquery_in12m,lo_query_in12m,0);
self_loan_query_in24m=sum(selfquery_in24m,lo_query_in24m,0);
self_loan_query_de_f_in6m=sum(selfquery_in6m,lo_query_in6m_de_f,0);
self_loan_query_de_f_in3m=sum(selfquery_in3m,lo_query_in3m_de_f,0);
self_loan_query_de_f_in1m=sum(selfquery_in1m,lo_query_in1m_de_f,0);
self_loan_query_de_f_in12m=sum(selfquery_in12m,lo_query_in12m_de_f,0);
self_loan_query_de_f_in24m=sum(selfquery_in24m,lo_query_in24m_de_f,0);
self_loan_card_query_in6m=sum(selfquery_in6m,lo_query_in6m,0,card_query_in6m);
self_loan_card_query_in3m=sum(selfquery_in3m,lo_query_in3m,0,card_query_in3m);
self_loan_card_query_in1m=sum(selfquery_in1m,lo_query_in1m,0,card_query_in1m);
self_loan_card_query_in12m=sum(selfquery_in12m,lo_query_in12m,0,card_query_in12m);
self_loan_card_query_in24m=sum(selfquery_in24m,lo_query_in24m,0,card_query_in24m);
run;

proc sql;
create table orig.credit_query_alldata as
select a.apply_code, b.*
from approval.apply_time as a
inner join credit_all_data as b on a.id_card_no = b.id_card and datepart(a.apply_time) >= b.征信获取时间;
quit;

proc sort data = orig.credit_query_alldata nodupkey; by apply_code descending 征信获取时间; run;

/*查看数据的列名*/
ods trace on;
proc contents data=orig.credit_query_alldata;
ods output Variables=need_all;
run;
ods trace off;


/*---------------------------------*

/*-----------------------------------------------只取需要的查询次数数据-------------------------------------------------------------------------------------------------------*/;
data customer_query_num;
merge query_in3m1(in = a)
credit_derived_data(in = b) 
card_query_in3m(in = c) 
insur_query_in3m(in = d) 
self_query_in3m(in = e) 
lo_query_in3m(in = f) 
mana_loan_in3m(in = g) 
num_com(in = h)   
card_info(in = i)   
loan_info(in = j)  
; 
by report_number ;
if a;
self_loan_dv_in1m=sum( selfquery_in1m,-lo_query_in1m,0);
self_loan_dv_in3m=sum( selfquery_in3m,-lo_query_in3m,0);
self_loan_dv_in6m=sum( selfquery_in6m,-lo_query_in6m,0);
self_loan_dv_in12m=sum( selfquery_in12m,-lo_query_in12m,0);
self_loan_dv_in24m=sum( selfquery_in24m,-lo_query_in24m,0);
self_card_query_in6m=sum(selfquery_in6m,card_query_in6m,0);
self_card_query_in3m=sum(selfquery_in3m,card_query_in3m,0);
self_card_query_in1m=sum(selfquery_in1m,card_query_in1m,0);
self_card_query_in12m=sum(selfquery_in12m,card_query_in12m,0);
self_card_query_in24m=sum(selfquery_in24m,card_query_in24m,0);
self_loan_query_in6m=sum(selfquery_in6m,lo_query_in6m,0);
self_loan_query_in3m=sum(selfquery_in3m,lo_query_in3m,0);
self_loan_query_in1m=sum(selfquery_in1m,lo_query_in1m,0);
self_loan_query_in12m=sum(selfquery_in12m,lo_query_in12m,0);
self_loan_query_in24m=sum(selfquery_in24m,lo_query_in24m,0);
self_loan_query_de_f_in6m=sum(selfquery_in6m,lo_query_in6m_de_f,0);
self_loan_query_de_f_in3m=sum(selfquery_in3m,lo_query_in3m_de_f,0);
self_loan_query_de_f_in1m=sum(selfquery_in1m,lo_query_in1m_de_f,0);
self_loan_query_de_f_in12m=sum(selfquery_in12m,lo_query_in12m_de_f,0);
self_loan_query_de_f_in24m=sum(selfquery_in24m,lo_query_in24m_de_f,0);
self_loan_card_query_in6m=sum(selfquery_in6m,lo_query_in6m,0,card_query_in6m);
self_loan_card_query_in3m=sum(selfquery_in3m,lo_query_in3m,0,card_query_in3m);
self_loan_card_query_in1m=sum(selfquery_in1m,lo_query_in1m,0,card_query_in1m);
self_loan_card_query_in12m=sum(selfquery_in12m,lo_query_in12m,0,card_query_in12m);
self_loan_card_query_in24m=sum(selfquery_in24m,lo_query_in24m,0,card_query_in24m);
run;


proc sql;
create table orig.credit_query_data as
select a.apply_code, b.*
from approval.apply_time as a
inner join customer_query_num as b on a.id_card_no = b.id_card and datepart(a.apply_time) >= b.征信获取时间;
quit;

proc sort data = orig.credit_query_data nodupkey; by apply_code descending 征信获取时间; run;


/*查看数据的列名*/
ods trace on;
proc contents data=orig.credit_query_data;
ods output Variables=need;
run;
ods trace off;




libname orig "F:\TS\offline_model\01_Dataset\01_original";

/*前期测试IV值比较高的几个变量*/
data orig.credit_query_alldata2;
set cred.query_in3m(keep = apply_code max_cardline selfquery_cardquery_in6m cardquery_com_num cardquery_card_num_dvalue);
run;















































