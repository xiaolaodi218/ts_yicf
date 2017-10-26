****第一部分：观察逾期天数;

option compress = yes validvarname = any;
libname sss "F:\米粒逾期日报表\data";
libname repayFin "F:\米粒坏账率预测\repayAnalysis";
libname submart "D:\mili\Datamart\data";

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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment;by 还款天数;run;

**贴上标签;
data flag;
set submart.apply_flag;
rename apply_code = contract_no;
run;
data apply_submart;
set submart.apply_submart(keep = apply_code 申请结果);
rename apply_code = contract_no;
run;

proc sort data=flag nodupkey;by contract_no;run;
proc sort data=apply_submart nodupkey;by contract_no;run;
proc sort data=ct_payment nodupkey;by contract_no;run;

data repayFin.ct_payment_report;
merge ct_payment(in = a) flag(in = b) apply_submart(in=c);
by contract_no;
if a;
run;
proc sort data = repayFin.ct_payment_report nodupkey; by contract_no; run;


*整体;
data kankan_total;
set repayFin.ct_payment_report;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706","201707","201708");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(cut_date,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>=0 then 逾期=1;

if 逾期天数=<0 and BILL_STATUS="0000" then 逾期还款0=1;
else if 逾期天数=1 and BILL_STATUS="0000" then 逾期还款1=1;
else if 逾期天数=2 and BILL_STATUS="0000" then 逾期还款2=1;
else if 逾期天数=3 and BILL_STATUS="0000" then 逾期还款3=1;
else if 逾期天数=4 and BILL_STATUS="0000" then 逾期还款4=1;
else if 逾期天数=5 and BILL_STATUS="0000" then 逾期还款5=1;
else if 逾期天数=6 and BILL_STATUS="0000" then 逾期还款6=1;
else if 逾期天数=7 and BILL_STATUS="0000" then 逾期还款7=1;
else if 逾期天数=8 and BILL_STATUS="0000" then 逾期还款8=1;
else if 逾期天数=9 and BILL_STATUS="0000" then 逾期还款9=1;
else if 逾期天数=10 and BILL_STATUS="0000" then 逾期还款10=1;
else if 逾期天数>10 and BILL_STATUS="0000" then 逾期还款11=1;

if 逾期天数>=0 and 账户标签="逾期" and BILL_STATUS="0002" then 逾期未还款=1;

run;

proc sql;
create table kan_pay as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kankan_total group by 放款月份 ;
quit;

**新客户;
data kan_xz;
set kankan_total;
if 订单类型 = "新客户订单";
run;
proc sql;
create table kan_pay_xz as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_xz group by 放款月份 ;
quit;

**复贷客户;
data kan_fd;
set kankan_total;
if 订单类型 = "复贷客户订单";
run;
proc sql;
create table kan_pay_fd as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_fd group by 放款月份 ;
quit;

***************************************
系统通过和人工通过逾期率比较 total;
*系统;
data kan_system;
set kankan_total;
if 申请结果="系统通过";
run;
proc sql;
create table kan_pay_system as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_system group by 放款月份 ;
quit;

*人工;
data kan_review;
set kankan_total;
if 申请结果="人工通过";
run;
proc sql;
create table kan_pay_review as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_review group by 放款月份 ;
quit;

*******新客户;*******************************;
data kan_system_xz;
set kan_xz;
if 申请结果="系统通过";
run;
proc sql;
create table kan_pay_system_xz as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_system_xz group by 放款月份 ;
quit;

*人工;
data kan_review_xz;
set kan_xz;
if 申请结果="人工通过";
run;
proc sql;
create table kan_pay_review_xz as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_review_xz group by 放款月份 ;
quit;

*******复贷客户;****************************************;
data kan_system_fd;
set kan_fd;
if 申请结果="系统通过";
run;
proc sql;
create table kan_pay_system_fd as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_system_fd group by 放款月份 ;
quit;

*人工;
data kan_review_fd;
set kan_fd;
if 申请结果="人工通过";
run;
proc sql;
create table kan_pay_review_fd as
select 放款月份,
sum(逾期还款0) as 逾期还款0,
sum(逾期还款1) as 逾期还款1, 
sum(逾期还款2) as 逾期还款2,
sum(逾期还款3) as 逾期还款3,
sum(逾期还款4) as 逾期还款4,
sum(逾期还款5) as 逾期还款5,
sum(逾期还款6) as 逾期还款6,
sum(逾期还款7) as 逾期还款7,
sum(逾期还款8) as 逾期还款8,
sum(逾期还款9) as 逾期还款9,
sum(逾期还款10) as 逾期还款10,
sum(逾期还款11) as 逾期还款11,
sum(逾期未还款) as 逾期未还款
from kan_review_fd group by 放款月份 ;
quit;

********************************************;
*****************借款金额与借款期限的情况;
data receive_amt;
set repayFin.ct_payment_report;
if 订单类型 = "复贷客户订单";
if OVERDUE_DAYS > 0;

if 还款天数 = 7 then 还款天数7=1;
if 还款天数 = 14 then 还款天数14=1;
if 还款天数 = 21 then 还款天数21=1;
if 还款天数 = 28 then 还款天数28=1;

if CURR_RECEIVE_CAPITAL_AMT=500 then amt5 = 1;
if CURR_RECEIVE_CAPITAL_AMT=600 then amt6 = 1;
if CURR_RECEIVE_CAPITAL_AMT=700 then amt7 = 1;
if CURR_RECEIVE_CAPITAL_AMT=800 then amt8 = 1;
if CURR_RECEIVE_CAPITAL_AMT=900 then amt9 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1000 then amt10 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1100 then amt11 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1200 then amt12 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1300 then amt13 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1400 then amt14 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1500 then amt15 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1600 then amt16 = 1;
if CURR_RECEIVE_CAPITAL_AMT=1700 then amt17 = 1;
run;

proc sql;
create table kan_day_num as
select 放款月份,
sum(还款天数7) as 还款天数7,
sum(还款天数14) as 还款天数14,
sum(还款天数21) as 还款天数21,
sum(还款天数28) as 还款天数28
from receive_amt group by 放款月份;
run;

proc sql;
create table kan_amt_re as
select 放款月份,
sum(amt5) as amt5,
sum(amt6) as amt6,
sum(amt7) as amt7,
sum(amt8) as amt8,
sum(amt9) as amt9,
sum(amt10) as amt10,
sum(amt11) as amt11,
sum(amt12) as amt12,
sum(amt13) as amt13,
sum(amt14) as amt14,
sum(amt15) as amt15,
sum(amt16) as amt16,
sum(amt17) as amt17
from receive_amt group by 放款月份;
run;


*****************************************************************************************
复贷客户特征;
proc sort data=repayFin.ct_payment_report;by ID_NUMBER 客户标签;run;
data kan_feature;
set repayFin.ct_payment_report;
if 账户标签="未放款" then delete;
format lag_还清时间 yymmdd10.;
lag_还清时间=lag(CLEAR_DATE);
客户标签_复贷=客户标签-1;
by ID_NUMBER 客户标签;
if first.ID_NUMBER then lag_还清时间=clear_date;
run;
data kan_feature1;
set kan_feature;
if OVERDUE_DAYS > 0;

if lag_还清时间^=. then 间隔=loan_date-lag_还清时间;

if 间隔=0 then 间隔标签0=1;
if 间隔=1 then 间隔标签1=1;
if 间隔=2 then 间隔标签2=1;
if 间隔=3 then 间隔标签3=1;
if 4<=间隔<=5 then 间隔标签4_5=1;
if 6<=间隔<=10 then 间隔标签6_10=1;
if 11<=间隔<=30 then 间隔标签11_30=1;
if 31<=间隔<=60 then 间隔标签31_60=1;
if 间隔>60 then 间隔标签_61=1;

if 客户标签_复贷=1 then 复贷1 =1;
if 客户标签_复贷=2 then 复贷2 =1;
if 客户标签_复贷=3 then 复贷3 =1;
if 客户标签_复贷=4 then 复贷4 =1;
if 客户标签_复贷=5 then 复贷5 =1;
if 客户标签_复贷=6 then 复贷6 =1;
if 客户标签_复贷=7 then 复贷7 =1;
if 客户标签_复贷=8 then 复贷8 =1;
if 客户标签_复贷=9 then 复贷9 =1;
if 客户标签_复贷=10 then 复贷10 =1;
if 客户标签_复贷>10 then 复贷11 =1;

run;


proc sql;
create table kan_space as
select  放款月份,
sum(间隔标签0) as a0,
sum(间隔标签1) as a1,
sum(间隔标签2) as a2,
sum(间隔标签3) as a3,
sum(间隔标签4_5) as a4_5,
sum(间隔标签6_10) as a6_10,
sum(间隔标签11_30) as a11_30,
sum(间隔标签31_60) as a31_60,
sum(间隔标签_61) as a61
from kan_feature1 group by 放款月份;
quit;

proc sort data=kan_feature1(where=(客户标签_复贷>0)) nodupkey out=kan_feature2;by contract_no ;run;

proc sql;
create table kan_fd_number as
select 放款月份,
sum(复贷1) as 复贷1,
sum(复贷2) as 复贷2,
sum(复贷3) as 复贷3,
sum(复贷4) as 复贷4,
sum(复贷5) as 复贷5,
sum(复贷6) as 复贷6,
sum(复贷7) as 复贷7,
sum(复贷8) as 复贷8,
sum(复贷9) as 复贷9,
sum(复贷10) as 复贷10,
sum(复贷11) as 复贷11
from kan_feature2 group by 放款月份;
quit;


*************第二部分：上笔逾期天数拨打和拨通次数;

option compress = yes validvarname = any;
option missing = 0;
libname csdata odbc  datasrc=csdata_nf;
libname YY odbc  datasrc=res_nf;

libname submart "D:\mili\Datamart\data";
libname data "F:\米粒电话催收\复贷准入\data";
libname DA "F:\米粒电话催收\csdata";
libname DB "F:\米粒电话催收\res_nf";
libname DD "F:\米粒电话催收";
libname repayFin "F:\米粒坏账率预测\repayAnalysis";
data DB.ca_staff;
set yy.ca_staff;
run;

data DB.optionitem;
set yy.optionitem;
run;

data DA.Ctl_call_record;
set csdata.Ctl_call_record;
run;

data DA.Ctl_task_assign;
set csdata.Ctl_task_assign;
run;

data DA.Ctl_loaninstallment;
set csdata.Ctl_loaninstallment;
run;


data _null_;
format dt yymmdd10.;
dt = today() - 2;
db=intnx("month",dt,0,"b");
nd = dt-db;
weekf=intnx('week',dt,0);
call symput("nd", nd);
call symput("db",db);
if weekday(dt)=1 then call symput("dt",dt-2);
else call symput("dt",dt);
call symput("weekf",weekf);
run;

data ca_staff;
set DB.ca_staff;
id1=compress(put(id,$20.));
run;

proc sql;
create table cs_table1(where=( kindex(contract_no,"PL"))) as
select a.CALL_RESULT_ID,a.CALL_ACTION_ID,a.DIAL_TELEPHONE_NO,a.DIAL_LENGTH,a.CONTACTS_NAME,a.PROMISE_REPAYMENT,a.PROMISE_REPAYMENT_DATE,
       a.CREATE_TIME,a.REMARK,c.userName,d.CONTRACT_NO,d.CUSTOMER_NAME
from DA.Ctl_call_record as a 
left join DA.Ctl_task_assign as b on a.TASK_ASSIGN_ID=b.id
left join ca_staff as c on b.emp_id=c.id1
left join DA.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sql;
create table cs_table_ta as
select a.*,b.itemName_zh as RESULT from cs_table1 as a
left join DB.optionitem(where=(groupCode="CSJL")) as b on a.CALL_RESULT_ID=b.itemCode ;
quit;

data DD.cs_table1_tab;
set cs_table_ta;
format 联系日期 yymmdd10.;
联系日期=datepart(CREATE_TIME);
联系月份=put(联系日期,yymmn6.);
通话时长_秒=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);

if CALL_ACTION_ID ="OUTBOUND" then 拨打=1;

/*if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("承诺还款","拒接还款","违约还款","提醒还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;*/

if CALL_ACTION_ID ="OUTBOUND" and RESULT="承诺还款" then 承诺还款=1;else 承诺还款=0;
run;

***查看各个码的占比;
proc freq data=DD.Cs_table1_tab noprint;
table RESULT/out=cac;
run;

**;

**米粒逾期;
data milipayment_re;
set repayfin.milipayment_report(keep = CONTRACT_NO 放款月份 OVERDUE_DAYS ID_NUMBER LOAN_DATE 账户标签 cut_date);
if 账户标签 not in ("待还款","扣款失败","未放款");
if cut_date=&dt.;
run;

***保留每个客户最后一次借款状态;
proc sort data = milipayment_re nodupkey; by ID_NUMBER descending LOAN_DATE; run;
proc sort data = milipayment_re nodupkey; by ID_NUMBER;run;

data cs_table_table;
set DD.cs_table1_tab(keep = CONTRACT_NO CREATE_TIME DIAL_TELEPHONE_NO CONTACTS_NAME CUSTOMER_NAME 拨打 RESULT CALL_ACTION_ID);
if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("承诺还款","拒绝还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;
run;
proc sort data = cs_table_table ; by CONTRACT_NO;run;
proc sort data = milipayment_re nodupkey; by CONTRACT_NO;run;


data repay;
merge milipayment_re(in = a) cs_table_table(in = b);
by CONTRACT_NO;  
if a;
run;

proc sort data = repay out = repay1 nodupkey; by ID_NUMBER CREATE_TIME; run;

**打催收标签;

data repay12;
set repay1;
by ID_NUMBER CREATE_TIME;
retain 第几次联系 1;
	 if first.ID_NUMBER then 第几次联系 = 1;
else 第几次联系 = 第几次联系 + 1;
if first.ID_NUMBER then 首次联系 = 1;
if last.ID_NUMBER then 最新联系 = 1;
run;

******************;
**算一下每个客户被拨打的次数，保留最大一次联系;
proc sort data = repay12 out=contact; by ID_NUMBER descending 第几次联系;run;
proc sort data = contact nodupkey; by ID_NUMBER;run;  **客户被联系多少次;

data kan_call;
set contact;
if OVERDUE_DAYS<6;
if CALL_ACTION_ID ="" then 拨打0=1;
else if 第几次联系=1 and 拨打=1 then 拨打1=1;
else if 第几次联系=2 then 拨打2=1;
else if 第几次联系=3 then 拨打3=1;
else if 第几次联系=4 then 拨打4=1;
else if 第几次联系=5 then 拨打5=1;
else if 第几次联系=6 then 拨打6=1;
else if 第几次联系=7 then 拨打7=1;
else if 第几次联系=8 then 拨打8=1;
else if 第几次联系=9 then 拨打9=1;
else if 第几次联系=10 then 拨打10=1;
else if 第几次联系>10 then 拨打11=1;
run;

proc sql;
create table kanpay_call as
select 放款月份,
sum(拨打0) as 拨打0,
sum(拨打1) as 拨打1, 
sum(拨打2) as 拨打2,
sum(拨打3) as 拨打3,
sum(拨打4) as 拨打4,
sum(拨打5) as 拨打5,
sum(拨打6) as 拨打6,
sum(拨打7) as 拨打7,
sum(拨打8) as 拨打8,
sum(拨打9) as 拨打9,
sum(拨打10) as 拨打10,
sum(拨打11) as 拨打11
from kan_call group by 放款月份 ;
quit;


***************************************;
****计算合同里面出现各种码的次数;

data apply_flag;
set submart.apply_flag;
rename apply_code = contract_no;
run;

proc sort data = apply_flag nodupkey; by contract_no;run;
proc sort data = repay12; by contract_no;run;

data data.paypaypay;
merge repay12(in =a) apply_flag(in = b);
by contract_no;
if a;
run;

data paypaypay2;
set data.paypaypay;
if RESULT = "空号错号" then 空号错号=1;
if RESULT = "占线关机" then 占线关机=1;
if RESULT = "拒绝还款" then 拒绝还款=1;
if RESULT = "无力偿还" then 无力偿还=1;
if RESULT = "无法转告" then 无法转告=1;
if RESULT = "无人接听" then 无人接听=1;
if RESULT = "留言/转告" then 留言转告=1;

if RESULT = "承诺还款" then 承诺还款=1;
if RESULT = "提醒还款" then 提醒还款=1;
if RESULT = "违约还款" then 违约还款=1;
if RESULT = "拒接挂线" then 拒接挂线=1;
if RESULT = "来电提醒" then 来电提醒=1;
if RESULT = "欠费停机" then 欠费停机=1;
if RESULT = "无法接通" then 无法接通=1;


*if RESULT in("承诺还款","提醒还款","违约还款","拒接挂线","来电提醒","欠费停机","无法接通""死亡/坐牢","其他事项","电催失联") then 其他=1;
if RESULT in("其他事项""电催失联","死亡/坐牢","提醒还款","来电提醒") then 其他=1;

if RESULT ^= "" then 催收记录=1;
if OVERDUE_DAYS <6;
run;

proc sql;
create table kan_total_5 as
select 放款月份,
sum(空号错号) as 空号错号,
sum(占线关机) as 占线关机,
sum(拒绝还款) as 拒绝还款,
sum(无力偿还) as 无力偿还,
sum(无法转告) as 无法转告, 
sum(无人接听) as 无人接听,
sum(留言转告) as 留言转告,

sum(承诺还款) as 承诺还款,
sum(违约还款) as 违约还款,
sum(拒接挂线) as 拒接挂线,
sum(欠费停机) as 欠费停机,
sum(无法接通) as 无法接通, 
 
sum(其他) as 其他, 
sum(催收记录) as 催收记录
from paypaypay2 group by 放款月份 ;
quit;


****************************;
*计算逾期>3天每个客户的可联系率;

**打上可联和不可联的标签;
data connection;
set data.paypaypay;
format 联系标签 $20.;
if RESULT in("承诺还款","拒接还款","拒绝还款","留言/转告","其他事项","提醒还款","违约还款","无法转告","无力偿还","已还款") then 联系标签="可联";
if RESULT in("空号错号","电催失联","拒接挂线","来电提醒","欠费停机","死亡/坐牢","占线关机","无人接听","无法接通") then 联系标签="不可联";
if 联系标签="可联" then 可联=1;
run;

proc tabulate data =connection out=connection1;
class contract_no ;
var 可联;
table contract_no all,可联 all;
run;

data connection2;
set connection1;
可联率= 可联_Sum/N ;
run;

**保留最大的一次拨打次数;
proc sort data = connection out=connection12; by contract_no descending 第几次联系;run;
proc sort data = connection12 nodupkey; by contract_no;run;  **客户被联系多少次;

proc sort data = connection2 nodupkey; by contract_no;
data connection3;
merge connection2(in = a) connection12(in = b);
by contract_no;
if a;
run;

data connection4;
set connection3;
format 可联率区间 $20.;
if 可联率=0 then 可联率区间="1.(0)";
else if 0<可联率<0.2 then 可联率区间="2.(0,20%)";
else if 0.2=<可联率<0.5 then 可联率区间="3.[20%,50%)";
else if 0.5=<可联率<0.8 then 可联率区间="4.[50%,80%)";
else if 0.8=<可联率=<1 then 可联率区间="5.[80%,100%]";
if OVERDUE_DAYS <5;
run;

data connection5;
set connection4;
if 可联率区间="1.(0)" then 可联率0 = 1;
if 可联率区间="2.(0,20%)" then 可联率0_02 =1;
if 可联率区间="3.[20%,50%)" then 可联率02_05 =1;
if 可联率区间="4.[50%,80%)" then 可联率05_08 =1;
if 可联率区间="5.[80%,100%]" then 可联率08_10 =1;
run;

proc sql;
create table kan_connection as
select 放款月份,
sum(可联率0) as 可联率0,
sum(可联率0_02) as 可联率0_02, 
sum(可联率02_05) as 可联率02_05,
sum(可联率05_08) as 可联率05_08,
sum(可联率08_10) as 可联率08_10
from connection5 group by 放款月份 ;
quit;

*************************************************************;
**对于有催收记录的，观察催收拨打联系人的情况，记录打本人，打本人+1联系人等;

proc sort data = connection out = connection6 nodupkey;by contract_no DIAL_TELEPHONE_NO ;run;

proc sql;
create table connection7  as select contract_no,count(*) as 人数,放款月份,OVERDUE_DAYS  from connection6(where=(DIAL_TELEPHONE_NO^="")) group by contract_no,放款月份;
quit;

data connection8;
set connection7;
if 人数=1 then 联系本人 = 1;
if 人数=2 then 联系本人加1=1;
if 人数=3 then 联系本人加2=1;
if 人数=4 then 联系本人加3=1;
if 人数=5 then 联系本人加4=1;
if 人数>5 then 联系本人大于4=1;
if OVERDUE_DAYS <6;
run;

proc sql;
create table kan_con as
select 放款月份,
sum(联系本人) as 联系本人,
sum(联系本人加1) as 联系本人加1, 
sum(联系本人加2) as 联系本人加2,
sum(联系本人加3) as 联系本人加3,
sum(联系本人加4) as 联系本人加4,
sum(联系本人大于4) as 联系本人大于4
from connection8 group by 放款月份 ;
quit;


***逾期>3未催收电话过但是回款了;

data aaaaaa;
set connection3;
if CALL_ACTION_ID="";
if 0<OVERDUE_DAYS<10;
if 账户标签 = "已还款";
run;


