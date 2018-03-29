/********************************************************************************************/
/* Revised log																				*/
/* 2017-12-08, 新建, Huangdengfeng  						   								    */
/* 2018-03-16, 修改, bad的定义是考虑表现期																						*/
/********************************************************************************************/

option compress = yes validvarname = any;
/*-----------------------------------------
代码需要用到的数据来源逻辑库（input libname）
和代码生成的数据存储逻辑库（output libname）
-----------------------------------------*/
/*---input libname---*/
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
/*---output libname---*/
libname orig "F:\TS\offline_model\01_Dataset\01_original";

/*-----------------------------------------------------
从逻辑库repay里的payment获取合同的还款情况。
------------------------------------------------------*/
/*---从远端把数据先set下来，节省后续target步里做变更时的时间---*/
data payment;
set repayFin.payment;
run;

%let month = '201803';

data target;
set payment(where = (12 >= mob > 6)
			keep = 产品小类 apply_code 营业部 产品大类 od_days od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUN2016'd;	***取2016年6月份开始的放款***;
if 产品大类 = "续贷" then delete;	***剔除续贷产品***;	
if not kindex(产品小类 ,"米粒");   ***剔除米粒产品***;	
run;

proc sort data = target nodupkey; by apply_code descending mob; run;
proc sort data = target nodupkey; by apply_code;run;

data orig.target;
set target;
if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;
if 营业部 in ("怀化市第一营业部","赤峰市第一营业部","呼和浩特市第一营业部") then delete;    ***剔除怀化，赤峰，呼和浩特营业部数据;
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


/*proc tabulate data = orig.target out = aaa;*/
/*class  营业部 target_label 放款月份;*/
/*var sample;*/
/*table (营业部 ALL)*(target_label ALL), 放款月份 ALL;*/
/*run;*/
/**/
/*proc sort data=aaa;by  营业部 target_label;run;*/
/*proc transpose data=aaa out=bbb prefix=M;*/
/*by 营业部 target_label;*/
/*id 放款月份;*/
/*var N;*/
/*run;*/


proc tabulate data = orig.target out = aaa;
class 产品大类 营业部 target_label 放款月份;
var sample;
table (产品大类 ALL)*(target_label ALL), 放款月份 ALL;
table (营业部 ALL)*(target_label ALL), (放款月份 ALL);
table (产品大类 ALL)*(target_label ALL), (放款月份 ALL)*sample*(sum*f=8. pctn<target_label ALL>)/misstext='0' box="产品大类_好坏分布";
table (营业部 ALL)*(target_label ALL), (放款月份 ALL)*sample*(sum*f=8. pctn<target_label ALL>)/misstext='0' box="营业部_好坏分布";
keylabel sum='#' pctn='%';
run;


proc sql;
create table model_data as
select 放款月份,count(*) as 放款数 from orig.target 
group by 放款月份,产品大类;
quit;


data tt;
set orig.target;
if target = 0 then Good=1;
if target = 1 then Bad=1;
if target = 2 then Indet=1;
run;

proc sql;
create table gbi as
select 放款月份,sum(Bad) as 坏客户, sum(Good) as 好客户, sum(Indet) as 中间客户  from tt 
group by 放款月份;
run;



/**********************************************分割线************************************************/



/*-----------------------------------------------------
下面是一些临时性的代码或历史代码，不用时可以注释掉。
------------------------------------------------------*/
/*---先初略看下样本的情况---*/
/*proc freq data = orig.target;*/
/*table 产品大类;*/
/*table 营业部;*/
/*table 放款月份;*/
/*table es;*/
/*table settled;*/
/*table 资金渠道;*/
/*run;*/
/*proc freq data = target(where = (target^=2));*/
/*table target;*/
/*run;*/
/**/
/*data a;*/
/*set target;*/
/*if 续贷 = 1;*/
/*run;*/
/*proc tabulate data = a;*/
/*class 费率 放款月份;*/
/*table 放款月份, 费率;*/
/*run;*/
/*data a;*/
/*set orig.target;*/
/*if index(营业部,"赤峰") or index(营业部,"呼和浩特") or index(营业部,"怀化") then delete;*/
/*run;*/
/*proc tabulate data = a;*/
/*class target_label 放款月份;*/
/*var sample;*/
/*table (target_label ALL), (放款月份 ALL)*sample*(sum*f=8. pctn<target_label ALL>)/misstext='0' box="好坏分布";*/
/*keylabel sum='#' pctn='%';*/
/*run;*/
/**/
/******************************/
/*好坏定义：*/
/*1.用Repay_analysis_vintage跑出来的payment，里面会对债权转让做处理，转让后的新合同的还款情况会拼接到原合同中*/
/*2.表现期定为9期*/
/*3.曾经逾期30天以上定义为坏，当前未逾期且曾经逾期不超过7天定义为好，其他定义为不确定*/
/*************************;*/
/*data des.target;*/
/*set repayfin.payment(keep = apply_code 产品大类 mob 放款月份 od_days_ever od_days 续贷 where = (mob = 9 and 产品大类 ^= "续贷"));*/
/*format target_label $20.;*/
/*	 if od_days_ever > 30 then do; bad = 1; target_label = "bad"; end;*/
/*else if od_days = 0 and od_days_ever <= 7 then do; bad = 0; target_label = "good"; end;*/
/*else do; bad = 0; target_label = "indet"; end;*/
/*total = 1;*/
/*run;*/
/*proc freq data = target;*/
/*table bad;*/
/*run;*/




/*%let month = '201803';*/
/**/
/*data data;*/
/*set payment(where = (12 >= mob > 6)*/
/*			keep = 产品小类 apply_code 营业部 产品大类 od_days od_days_ever */
/*                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);*/
/**/
/*if LOAN_DATE >= '01JUN2016'd;	***取2016年6月份开始的放款***;*/
/*if 产品大类 = "续贷" then reloan = 1;	***剔除续贷产品***;	*/
/*if cut_date - loan_date - od_days_ever <= 90 then fraud = 1;	***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;*/
/*if 营业部 in ("怀化市第一营业部","赤峰市第一营业部","呼和浩特市第一营业部") then 营业_delete = 1;*/
/*if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***还款表现期，跟真实的还款期数有一定区别***;*/
/**/
/*if not kindex(产品小类 ,"米粒");*/
/**/
/**/
/*format target_label $10.;*/
/*	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;*/
/*else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;*/
/*else do; target = 2; target_label = "Indet"; end;*/
/*sample = 1;*/
/*run;*/




data aaa;
set payment(where = (12 >= mob > 6)
			keep = 产品小类 apply_code 营业部 产品大类 od_days od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUN2016'd;	***取2016年6月份开始的放款***;
if 产品大类 = "续贷" then reloan = 1;	***剔除续贷产品***;	
if not kindex(产品小类 ,"米粒");   ***剔除米粒产品***;	
run;

proc sort data = aaa nodupkey; by apply_code descending mob; run;
proc sort data = aaa nodupkey; by apply_code;run;

data data;
set aaa;
if cut_date - loan_date - od_days_ever <= 90 then  fraud = 1;	  ***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;
if 营业部 in ("怀化市第一营业部","赤峰市第一营业部","呼和浩特市第一营业部") then 营业_delete = 1;    ***剔除怀化，赤峰，呼和浩特营业部数据;
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



proc sql;
create table delete_data as
select 放款月份,count(*) as 放款数 , sum(reloan) as reloan_cus, sum(fraud) as fraud_cus, sum(营业_delete) as 营业_delete from data group by 放款月份;
quit;
