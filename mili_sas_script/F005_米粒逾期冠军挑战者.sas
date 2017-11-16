option compress = yes validvarname = any;
libname repayFin "F:\米粒逾期日报表\data";
libname account "D:\mili\Datamart\rawdata\account";
libname submart "D:\mili\Datamart\data";

***set account data;
data repayFin.bill_main;
set account.bill_main;
run;
data repayFin.account_info;
set account.account_info; 
run;                            
data repayFin.repay_plan;
set account.repay_plan;
run;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

/*宏可以跑出周末的报表,使用全局变量*/
/*%let dt=mdy(10,13,2017);*/

***米粒放款客户;
data mili;
set repayFin.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
还款天数=NEXT_REPAY_DATE-LOAN_DATE;
if kindex(PRODUCT_NAME,"米粒");
if contract_no ^="PL148178693332002600000066";/*这个是沙振华的*/
if not kindex(contract_no,"PB");
run;
proc sort data=mili;by id_number loan_date;run;
data mili1;
set mili;
by id_number loan_date;
if first.id_number then 客户标签=1;
else 客户标签+1;
run;

proc sort data=mili1 ;by NEXT_REPAY_DATE;run;
***米粒放款客户的合同金额+利息;
proc sql;
create table mili_repay_plan as
select a.*,b.CURR_RECEIVE_CAPITAL_AMT,b.CURR_RECEIVE_INTEREST_AMT from mili1 as a
left join repayFin.repay_plan as b on a.contract_no=b.contract_no;
quit;
***米粒客户的bill_main表;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join repayFin.bill_main as b on a.contract_no=b.contract_no;
quit;
proc sort data=mili_bill_main ;by repay_date;run;

proc delete data=payment ;run;

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
if 账户标签^="未放款";
format 报表标签 $20.;
/*cut_date=&cut_dt.;*/
if REPAY_DATE-cut_date>=1 and REPAY_DATE-cut_date<=3 then 报表标签="T_3";
else if 1<=od_days<=3 then 报表标签="1one_three";
else if 4<=od_days<=6 then 报表标签="2four_six";
else if 7<=od_days<=15 then 报表标签="3seven_fifteen";
else if 16<=od_days<=30 then 报表标签="4sixteen_thirty";
else if od_days>30 then 报表标签="5thirty_";
else if od_days>90 then 报表标签="6ninety_";
统计个数=1;
放款月份=put(LOAN_DATE,yymmn6.);
报表金额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if 账户标签="待还款" then 报表金额=贷款余额;
run;
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by 还款天数;run;


data repayfin.apply_flag;
set submart.apply_flag(keep = apply_code loc_abmoduleflag);
rename apply_code = contract_no;
run;

**贴上AB的标签;
proc sort data=repayfin.apply_flag ;by contract_no;run;
proc sort data=repayfin.milipayment_report ;by contract_no;run;

data repayfin.milipayment_report;
merge repayfin.milipayment_report(in = a) repayfin.apply_flag(in = b);
by contract_no;
if a;
run;
proc sort data = repayfin.milipayment_report ; by contract_no; run;


data repayfin.milipayment_report;
set repayfin.milipayment_report;
format 策略标签 $30.;
if loc_abmoduleflag="A" then 策略标签="冠军";
if loc_abmoduleflag="B" then 策略标签="挑战者";
run;
