libname account odbc datasrc=account_nf;
option compress = yes validvarname = any;
libname repayFin "F:\米粒复贷客户申请日间隔报表\repayAnalysis";
%let bt=mdy(7,20,2017);

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;
*米粒放款客户;
data mili;
set account.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
还款天数=NEXT_REPAY_DATE-LOAN_DATE;
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
left join account.repay_plan as b on a.contract_no=b.contract_no;
quit;
*米粒客户的bill_main表;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join account.bill_main as b on a.contract_no=b.contract_no;
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
od_days=&cut_dt.-REPAY_DATE;
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
od_days=&cut_dt.-REPAY_DATE;
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
if REPAY_DATE-cut_date>=1 and REPAY_DATE-cut_date<=3 then 报表标签="T_3";
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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by 还款天数;run;
proc sort data=Ct_payment_report ;by ID_NUMBER 客户标签;run;
data kan;
set Ct_payment_report;
if 账户标签="未放款" then delete;
format lag_还清时间 yymmdd10.;
lag_还清时间=lag(CLEAR_DATE);
客户标签_复贷=客户标签-1;
by ID_NUMBER 客户标签;
if first.ID_NUMBER then lag_还清时间=clear_date;
run;
data kan1;
set kan;
if lag_还清时间^=. then
间隔=loan_date-lag_还清时间;
format 间隔标签 $20.;
if 间隔=0 then 间隔标签="T+0";
else if 间隔=1 then 间隔标签="T+1";
else if 间隔=2 then 间隔标签="T+2";
else if 3<=间隔<=5 then 间隔标签="T+3-5";
else if 6<=间隔<=10 then 间隔标签="T+6-10";
else if 11<=间隔<=15 then 间隔标签="T+11-15";
else if 16<=间隔<=20 then 间隔标签="T+16-20";
else if 21<=间隔<=30 then 间隔标签="T+21-30";
else if 31<=间隔<=60 then 间隔标签="T+31-60";
else if 61<=间隔<=90 then 间隔标签="T+61-90";
else if 间隔>=91 then 间隔标签="T+91以上";
keep 客户标签 间隔 lag_还清时间 loan_date ID_NUMBER 客户标签_复贷 contract_no 间隔标签 CURR_RECEIVE_CAPITAL_AMT;
run;
proc sort data=kan1(where=(客户标签_复贷>0)) nodupkey out=kan2;by contract_no ;run;
proc sql;
create table kan3 as
select  客户标签_复贷,
sum(case when 间隔标签="T+0"  then 1 else 0 end ) as a0,
sum(case when 间隔标签="T+1"  then 1 else 0 end ) as a1,
sum(case when 间隔标签="T+2"  then 1 else 0 end ) as a2,
sum(case when 间隔标签="T+3-5"  then 1 else 0 end ) as a5,
sum(case when 间隔标签="T+6-10"  then 1 else 0 end ) as a10,
sum(case when 间隔标签="T+11-15"  then 1 else 0 end ) as a15,
sum(case when 间隔标签="T+16-20"  then 1 else 0 end ) as a20,
sum(case when 间隔标签="T+21-30"  then 1 else 0 end ) as a30,
sum(case when 间隔标签="T+31-60"  then 1 else 0 end ) as a60,
sum(case when 间隔标签="T+61-90"  then 1 else 0 end ) as a90,
sum(case when 间隔标签="T+91以上"  then 1 else 0 end ) as a91
from kan2 group by 客户标签_复贷;
quit;
proc sql;
create table kan3_je as
select  客户标签_复贷,
sum(case when 间隔标签="T+0"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a0,
sum(case when 间隔标签="T+1"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a1,
sum(case when 间隔标签="T+2"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a2,
sum(case when 间隔标签="T+3-5"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a5,
sum(case when 间隔标签="T+6-10"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a10,
sum(case when 间隔标签="T+11-15"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a15,
sum(case when 间隔标签="T+16-20"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a20,
sum(case when 间隔标签="T+21-30"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a30,
sum(case when 间隔标签="T+31-60"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a60,
sum(case when 间隔标签="T+61-90"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a90,
sum(case when 间隔标签="T+91以上"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a91
from kan2 group by 客户标签_复贷;
quit;
x  "F:\米粒复贷客户申请日间隔报表\repayAnalysis\米粒复贷客户申请日间隔月报.xlsx"; 
filename DD DDE 'EXCEL|[米粒复贷客户申请日间隔月报.xlsx]个数!r2c2:r16c12';
data _null_;set kan3;file DD;put a0 a1 a2 a5 a10 a15 a20 a30 a60 a90 a91;run;
filename DD DDE 'EXCEL|[米粒复贷客户申请日间隔月报.xlsx]金额!r2c2:r16c12';
data _null_;set kan3_je;file DD;put a0 a1 a2 a5 a10 a15 a20 a30 a60 a90 a91;run;
