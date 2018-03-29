option compress=yes validvarname=any;
option missing = 0;

libname daily "D:\mili\offline\daily";
libname centre "D:\mili\offline\centre_data\daily";

/*样本数据的准备阶段*/
data loan_all;
set daily.daily_acquisition(keep = APPLY_CODE ID_CARD_NO NAME 进件日期 放款状态 input_complete);
if input_complete = 1;
if 进件日期 >= '01JAN2017'd;
if 进件日期 <= '13MAR2018'd;
if 放款状态 = "已放款";
run;

data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;


data loan_all2017;
merge loan_all(in = a) com_res_info(in = b);
by apply_code;
if a;
run;

proc sort data = loan_all2017 ;by 进件日期;run;

/*filename export "F:\TS\external_data_test\天启\data\loan_all2017.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= loan_all2017 */
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/



proc import datafile="F:\TS\external_data_test\天启\天启测试结果_20180316\测试结果_20180316.xlsx"
out=tq_test_data dbms=excel replace;
SHEET="测试结果";
scantext=no;
getnames=yes;
run;





/*好坏的定义*/ 
option compress = yes validvarname = any;
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname orig "F:\TS\offline_model\01_Dataset\01_original";


data target;
set repayFin.payment(where = (12 >= mob > 7)
			keep = 产品小类 apply_code 营业部 产品大类 od_days od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUN2016'd;	    ***取2016年6月份开始的放款***;
if 产品大类 = "续贷" then delete;	***剔除续贷产品***;	
if not kindex(产品小类 ,"米粒");     ***剔除米粒产品***;	
run;

proc sort data = target nodupkey; by apply_code descending mob; run;
proc sort data = target nodupkey; by apply_code;run;

data orig.target;
set target;
if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;
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


proc sort data = orig.target ;by apply_code;run;
proc sort data = tq_test_data;by apply_code;run;

data tp_all_target;
merge tq_test_data(in = a)  orig.target(in = b);
by apply_code;
if a;
run;

data tp_all_target2;
set tp_all_target;
if 放款月份 ^= "";
/*if target ^= 2;*/
run;

filename export "F:\TS\external_data_test\天启\data\原始_data_有表现..csv" encoding='utf-8';
PROC EXPORT DATA= tp_all_target2 
			 outfile = export
			 dbms = csv replace;
RUN;


***推广结论;
data tp_target_tui;
set tp_all_target;
if loan_dt1 >= '29JUL2017'd;
run;

filename export "F:\TS\external_data_test\天启\data\tp_target_tui.csv" encoding='utf-8';
PROC EXPORT DATA= tp_all_target 
			 outfile = export
			 dbms = csv replace;
RUN;
