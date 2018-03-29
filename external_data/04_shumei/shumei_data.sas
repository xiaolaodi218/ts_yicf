option compress = yes validvarname = any;

libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname daily "D:\mili\offline\daily";


/*本次先取得700条左右的数据用来测试;
时间维度为2017/5/1 - 2017/6/31*/
************************************
Bad   —— 曾经逾期30天以上
Good  —— 还款表现期大于5（提前结清的是大于5，正常在还的是大于7）且 当前未逾期 且 曾经逾期天数小于8（门店端催回）
Indet —— 其他
************************************;

data payment;
set repayFin.payment;
run;

%let month = '201801';

data target;
set payment(where = (month = &month. and mob > 6)
			keep = 客户姓名 身份证号码 BORROWER_TEL_ONE  apply_code  od_days 产品小类 od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01MAY2017'd;	***取2016年6月份开始的放款***;
/*if 产品大类 = "续贷" then delete;	***剔除续贷产品***;	*/
/*if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;*/
/*if 营业部 in ("怀化市第一营业部","赤峰市第一营业部","呼和浩特市第一营业部") then delete;    ***剔除怀化，赤峰，呼和浩特营业部数据;*/
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***还款表现期，跟真实的还款期数有一定区别***;

if not kindex(产品小类 ,"米粒");

format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;

proc sql;
create table model_data as
select 放款月份,count(*) as 放款数 from target group by 放款月份 ;
quit;

data tt;
set target;
if target = 0 then Good=1;
if target = 1 then Bad=1;
if target = 2 then Indet=1;
run;

proc sql;
create table gbi as
select 放款月份,sum(Bad) as 坏客户, sum(Good) as 好客户, sum(Indet) as 中间客户  from tt group by 放款月份;
run;

data target_g;
set target(keep = apply_code 客户姓名 身份证号码 BORROWER_TEL_ONE target);
if target ^= 2;
rename BORROWER_TEL_ONE = 电话号码;
run;
proc sort data = target_g nodupkey;by apply_code;run;
/*拼接申请日期*/
data apply_time;
set daily.daily_acquisition(keep = APPLY_CODE 进件日期);
run;
proc sort data = apply_time nodupkey;by apply_code;run;

data target_gg;
merge target_g(in=a) apply_time(in=b);
if a;
by apply_code;
run;

filename export "F:\TS\external_data_test\数美科技\data\target_old.csv" encoding='utf-8';
PROC EXPORT DATA= target_gg 
			 outfile = export
			 dbms = csv replace;
RUN;



/*第二部分数据*/
libname daily "D:\mili\offline\daily";
libname cred "D:\mili\offline\offlinedata\credit";
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*本次先取得300条左右的数据用来测试;
时间维度为2018/1/1-2018/1/14*/
************************************
Bad   —— 申请之后自动拒绝的客户
Good  —— 已经放款的客户
Indet —— 其他
************************************;

/*自动拒绝的客户*/
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(1,1,2018);
dt_end=mdy(1,13,2018);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***取2018年1月24日份开始的放款***;
if auto_reject_time <= &dt_end.;	***取2018年1月25日份结束的放款***;
run;


/*已经放款的客户*/
data make_loan_good;
set daily.daily_acquisition(keep = APPLY_CODE 放款状态 放款日期 ID_CARD_NO);
if 放款状态 = "已放款";
if 放款日期 >= '1JAN2018'd;
if 放款日期 <= '13JAN2018'd;
run;

data test;
set auto_reject_bad  make_loan_good;
run;
proc sort data= test nodupkey ;by apply_code;run;


data apply_base;
set approval.apply_base(keep = apply_code ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;

data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;


data test_bb;
merge test(in = a) com_res_info(in = b) apply_base(in = c);
by apply_code;
if a ;
run;

data recent_test;
set test_bb(keep = APPLY_CODE NAME 放款状态 ID_CARD_NO PHONE1);
rename  ID_CARD_NO = 身份证号码   PHONE1 = 电话号码;
if 放款状态 = "已放款" then y = 0;
else y = 1;
run;

/*拼接申请日期*/
data apply_time;
set daily.daily_acquisition(keep = APPLY_CODE 进件日期);
run;
proc sort data = apply_time nodupkey;by apply_code;run;

data recent_gg;
merge recent_test(in=a) apply_time(in=b);
if a;
by apply_code;
run;


filename export "F:\TS\external_data_test\数美科技\data\recent_gg.csv" encoding='utf-8';
PROC EXPORT DATA= recent_gg 
			 outfile = export
			 dbms = csv replace;
RUN;



