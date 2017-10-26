option compress = yes validvarname = any;

libname submart "D:\mili\Datamart\data";
libname ssst "F:\通善金融\染黑度_催收测试\data";

data phone_number;
set submart.id_submart(keep = apply_code PHONE_NO);
本机号码1=PHONE_NO;
run;

data phone_num;
set phone_number;
本机号码 = substr(本机号码1,0,0)||"***"||substr(本机号码1,4,8);
drop 本机号码1;
run;


proc sort data = phone_num nodupkey;by PHONE_NO;run;

data phone_num;
set phone_num(keep = PHONE_NO 本机号码);
run;

filename export "F:\通善金融\染黑度_催收测试\data\phone_number.csv" encoding='utf-8';
PROC EXPORT DATA= phone_num
			 outfile = export
			 dbms = csv replace;
RUN;





***逾期数据;
data a;
format dt  yymmdd10.;
dt = today() - 1;
call symput("dt", dt);
run;

*米粒放款客户;
data mili;
set sss.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
还款天数=sum(NEXT_REPAY_DATE,-LOAN_DATE);
if kindex(PRODUCT_NAME,"米粒");
if contract_no ^="PL148178693332002600000066";/*这个是沙振华的*/
run;
proc sort data=mili;by id_number loan_date;run;
data mili1;
set mili;
by id_number loan_date;
if first.id_number then 客户标签=1;
else 客户标签+1;
run;

proc sort data=mili1 ;by NEXT_REPAY_DATE;run;
*米粒放款客户的合同金额+利息;
proc sql;
create table mili_repay_plan as
select a.*,b.CURR_RECEIVE_CAPITAL_AMT,b.CURR_RECEIVE_INTEREST_AMT from mili1 as a
left join sss.repay_plan as b on a.contract_no=b.contract_no;
quit;
*米粒客户的bill_main表;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join sss.bill_main as b on a.contract_no=b.contract_no;
quit;
proc sort data=mili_bill_main ;by repay_date;run;
*暂时认为bill_main表的curr_receive_amt是技术部算好的bill_fee_dtl的总和;
*暂时当做米粒客户都是对私扣款，所以不加入对公还款部分的逻辑，简单点;
%macro get_payment;
data _null_;
*早上;
n = &dt.-mdy(12,27,2016) ;
call symput("n", n);
run;
%do i = 0 %to &n.;
data _null_;
start_dt =mdy(12,27,2016);
cut_dt = intnx("day", start_dt, &i.);
call symput("cut_dt", cut_dt);
run;
data temp_result;
set mili_bill_main;
format cut_date yymmdd10. 账户标签 $20.;
cut_date=&cut_dt.;
*放款前;
if &cut_dt.<LOAN_DATE then do;
账户标签="未放款";
存量客户=0;
end;
*待还款;
else if LOAN_DATE<=&cut_dt.<REPAY_DATE then do;
acc_interest=(&cut_dt.-loan_date)*CURR_RECEIVE_INTEREST_AMT/还款天数;
贷款余额=sum(CURR_RECEIVE_CAPITAL_AMT,acc_interest);
账户标签="待还款";
存量客户=1;
end;
*还款日;
else if &cut_dt.=REPAY_DATE then do;
if  CLEAR_DATE=. or &cut_dt.<CLEAR_DATE  then do;
贷款余额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
账户标签="扣款失败";
存量客户=1;
od_days=sum(&cut_dt.,-REPAY_DATE);
end;
else if CLEAR_DATE<=&cut_dt. then do;
贷款余额=0;
账户标签="已还款";
存量客户=0;
od_days=0;
end;
end;
*还款日之后;
else if &cut_dt. > repay_date then do;
if CLEAR_DATE=.  or &cut_dt.<CLEAR_DATE then do;
贷款余额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
账户标签="逾期";
存量客户=1;
od_days=sum(&cut_dt.,-REPAY_DATE);
end;

else if &cut_dt.>=CLEAR_DATE then do;
贷款余额=0;
账户标签="已还款";
存量客户=0;
od_days=0;
end;
end;

run;
proc append base = payment data = temp_result; run;
%end;
%mend;
%get_payment;

data repayfin.milipayment_report;
set payment;
format 报表标签 $20.;
if 账户标签^="未放款";
if sum(REPAY_DATE,-cut_date)>=1 and sum(REPAY_DATE,-cut_date)<=3 then 报表标签="T_3";
else if 1<=od_days<=3 then 报表标签="1one_three";
else if 4<=od_days<=15 then 报表标签="2four_fifteen";
else if 16<=od_days<=30 then 报表标签="3sixteen_thirty";
else if od_days>30 then 报表标签="4thirty_";
else if od_days>90 then 报表标签="5ninety_";
统计个数=1;
放款月份=put(LOAN_DATE,yymmn6.);
报表金额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if 账户标签="待还款" then 报表金额=贷款余额;
/*if contract_no="PL148224156660201400005011" then 报表标签="T_3";*/
/*if 账户标签 in ("待还款","扣款失败") then 账户标签2="Current";*/
if PRODUCT_NAME="米粒10" then 策略标签="银策略";else 策略标签="金策略";
run;
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=repayFin.ct_payment;by 还款天数;run;

data repay_r;
set repayFin.ct_payment_report;
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
indent：逾期了3天以上15天一下已结清、或当前还处于逾期
****/
/*if 曾经逾期天数 > 15 then do; target_label = "逾期天数15天以上"; target = 1;end;*/
/*else if bill_status = "0000" and 曾经逾期天数 <=3 then do;target_label = "逾期天数不超过3天";target = 0;end;*/
/*else do;target_label = "逾期3-15天";target = 2;end;*/
if bill_status = "0000" and 曾经逾期天数 <=3 then y = 0;
if 曾经逾期天数 > 15 then y = 1;
run;

data repay;
set repay(drop =ACCOUNT_TYPE FUND_CHANNEL_CODE PRODUCT_NAME PERIOD CURR_RECEIVE_AMT CURR_RECEIVE_CAPITAL_AMT CURR_RECEIVE_INTEREST_AMT LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE 存量客户 acc_interest 贷款余额 报表标签 报表金额 统计个数 银策略筛选 loc_abmoduleflag 策略标签);
rename CONTRACT_NO = apply_code;
if y ^=  "";
run;

proc sort data=repay nodupkey;by apply_code;run;

filename export "F:\moudle\prepare\data\repay.csv" encoding='utf-8';
PROC EXPORT DATA= repay
			 outfile = export
			 dbms = csv replace;
RUN;
