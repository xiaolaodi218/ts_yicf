option compress=yes validvarname=any;
option missing = 0;

libname daily "D:\mili\offline\daily";
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";

libname cred "D:\mili\offline\offlinedata\credit";
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*本次取得5000条左右的数据用来测试;

线下			
	放款月份	数据量	备注
	201708	1000	有好坏表现
	201712	1000	有审批表现
			
米粒			
	201710	3000	有好坏表现


************************************
Bad   —— 申请之后自动拒绝的客户
Good  —— 已经放款的客户
Indet —— 其他
************************************;

*offline
/*自动拒绝的客户*/
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(12,14,2017);
dt_end=mdy(12,31,2017);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***取2017年12月11日份开始的放款***;
if auto_reject_time <= &dt_end.;	***取2017年12月31日份结束的放款***;
run;


/*已经放款的客户*/
data make_loan_good;
set daily.daily_acquisition(keep = APPLY_CODE 放款状态 放款日期 ID_CARD_NO);
if 放款状态 = "已放款";
if 放款日期 >= '14DEC2017'd;
if 放款日期 <= '31DEC2017'd;
run;

/*住址和公司住址信息*/
data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1  居住省 居住市 居住区  RESIDENCE_ADDRESS 工作省 工作市 工作区 COMP_ADDRESS);
居住地址 = cats(居住省, 居住市, 居住区, RESIDENCE_ADDRESS);
工作地址 = cats(工作省, 工作市, 工作区, COMP_ADDRESS);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;

/*自动拒绝客户*/
data test;
set auto_reject_bad  make_loan_good;
run;
proc sort data= test nodupkey ;by apply_code;run;


data apply_base;
set approval.apply_base(keep = apply_code  ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;


data test_offline01;
merge test(in = a) com_res_info(in = b) apply_base(in = c);
by apply_code;
if a ;
run;


/*201708放款的有好坏表现的客户*/

%let month = '201803';

data target1;
set repayFin.payment(where = (month = &month. and mob > 6)
			keep = 产品小类 apply_code 营业部 产品大类 od_days od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '02AUG2017'd;	    ***取2017年5月份开始的放款***;
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



/*获取数据*/
data last_loan_perfor;
set daily.daily_acquisition(keep = APPLY_CODE 放款状态 放款日期 ID_CARD_NO);
if 放款状态 = "已放款";
if 放款日期 >= '02AUG2017'd;
if 放款日期 <= '31AUG2017'd;
run;

/*住址和公司住址信息*/
data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1  居住省 居住市 居住区  RESIDENCE_ADDRESS 工作省 工作市 工作区 COMP_ADDRESS);
居住地址 = cats(居住省, 居住市, 居住区, RESIDENCE_ADDRESS);
工作地址 = cats(工作省, 工作市, 工作区, COMP_ADDRESS);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;

/*单独取身份证号码*/
data apply_base;
set approval.apply_base(keep = apply_code ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;

data test_offline02;
merge last_loan_perfor(in = a) com_res_info(in = b) apply_base(in = c) target3(in = d);
by apply_code;
if a ;
run;


filename export "F:\TS\external_data_test\百度金融\data\test_offline01.csv" encoding='utf-8';
PROC EXPORT DATA= test_offline01 
			 outfile = export
			 dbms = csv replace;
RUN;
filename export "F:\TS\external_data_test\百度金融\second_test\data\test_offline02.csv" encoding='utf-8';
PROC EXPORT DATA= test_offline02 
			 outfile = export
			 dbms = csv replace;
RUN;


*米粒的客户;
option compress = yes validvarname = any;
libname ss "F:\米粒MTD\output";

/*使用A004_申请子主题和A005_审核子主题脚本跑出来的数据集*/
data ss.apply_submart;
set data.apply_submart;
run;
data ss.approval_submart;   /*订单类型在这个表里=a*/
set data.approval_submart;
run;


option compress = yes validvarname = any;

libname data "D:\mili\Datamart\data";
libname repayFin "F:\米粒逾期日报表\data";

/****客户逾期和曾经发生逾期数据;*/

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 70, 13, "same"); else dt = today() - 70;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

data milipayment_report;
set repayfin.milipayment_report;
if 放款月份 = "201710";
run;

proc sort data=milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by CONTRACT_NO;run;

data repay_r;
set ct_payment_report;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 曾经逾期天数=sum(cut_date,-REPAY_DATE);
else 曾经逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
run;

**定义好坏;
data repay;
set repay_r;
/*length target_label $20.;*/
/****
bad:当前或曾经逾期15天以上
good:未逾期或逾期了但是不超过3天就结清了的客户
indent：逾期了3天以上15天以下已结清、或当前还处于逾期
****/
if 曾经逾期天数 > 15 then do; target_label = "逾期15天以上"; y = 1;end;
else if bill_status = "0000" and 曾经逾期天数 <=3 then do;target_label = "逾期不超3天";y = 0;end;
else do;target_label = "逾期3_15天";y = 2;end;
*if bill_status = "0000" and 曾经逾期天数 <=3 then y = 0;
*if 曾经逾期天数 > 3 then y = 1;
run;

data repay_10;
set repay(keep =CONTRACT_NO LOAN_DATE BORROWER_TEL_ONE y);
rename CONTRACT_NO = apply_code;
if y ^= "";
if y ^= 2;
if LOAN_DATE > '26OCT2017'd;
run;

proc sort data=repay_10 nodupkey;by apply_code;run;

/*拼接一个user_code 使用*/
proc sort data=data.Id_submart nodupkey;by apply_code;run;

data id_repay;
merge repay_10(in = a) data.Id_submart(in = b);
by apply_code;
if a;
run;

data address_base;
set data.Baseinfo_submart(keep =USER_CODE  USER_NAME  ID_CARD  JOB_COMPANY_ADDRESS RESIDENCE_ADDRESS);
run;

proc sort data = address_base ; by user_code;run;
proc sort data = id_repay ;by user_code;run;

data id_repay_address;
merge id_repay(in = a) address_base(in = b);
by user_code;
if a;
run;

data id_repay_address1;
set id_repay_address(keep = apply_code USER_NAME BORROWER_TEL_ONE ID_CARD RESIDENCE_ADDRESS JOB_COMPANY_ADDRESS y);
run;

filename export "F:\TS\external_data_test\百度金融\data\mili_test.csv" encoding='utf-8';
PROC EXPORT DATA= id_repay_address1 
			 outfile = export
			 dbms = csv replace;
RUN;
