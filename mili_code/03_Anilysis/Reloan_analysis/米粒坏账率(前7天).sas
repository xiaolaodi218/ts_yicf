option compress = yes validvarname = any;
libname sss "F:\米粒逾期日报表\data";
libname repayFin "F:\米粒坏账率预测\repayAnalysis";
libname haha "F:\米粒电话催收\data";

data a;
format dt  yymmdd10.;
dt = today() - 3;
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
if sum(REPAY_DATE,-cut_date)=1 then 报表标签="1one";
else if od_days=2 then 报表标签="2two";
else if od_days=3 then 报表标签="3three";
else if od_days=4 then 报表标签="4four";
else if od_days=5 then 报表标签="5five";
else if od_days=6 then 报表标签="6six";
else if od_days=7 then 报表标签="6seven";
统计个数=1;
放款月份=put(LOAN_DATE,yymmn6.);
报表金额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if 账户标签="待还款" then 报表金额=贷款余额;
/*if contract_no="PL148224156660201400005011" then 报表标签="T_3";*/
/*if 账户标签 in ("待还款","扣款失败") then 账户标签2="Current";*/
if PRODUCT_NAME="米粒10" then 策略标签="银策略";else 策略标签="金策略";
run;
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=haha.ct_payment_report;by 还款天数;run;


*整体;
data kan;
set ct_payment_report;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706","201707");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(cut_date,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 逾期天数=1 and BILL_STATUS="0000" then 逾期催回1=1;
else if 逾期天数=2 and BILL_STATUS="0000" then 逾期催回2=1;
else if 逾期天数=3 and BILL_STATUS="0000" then 逾期催回3=1;
else if 逾期天数=4 and BILL_STATUS="0000" then 逾期催回4=1;
else if 逾期天数=5 and BILL_STATUS="0000" then 逾期催回5=1;
else if 逾期天数=6 and BILL_STATUS="0000" then 逾期催回6=1;
else if 逾期天数=7 and BILL_STATUS="0000" then 逾期催回7=1;


if 逾期天数>=1 then 逾期_a1=1;
if 逾期天数>=2 then 逾期_a2=1;
if 逾期天数>=3 then 逾期_a3=1;
if 逾期天数>=4 then 逾期_a4=1;
if 逾期天数>=5 then 逾期_a5=1;
if 逾期天数>=6 then 逾期_a6=1;
if 逾期天数>=7 then 逾期_a7=1;
run;
proc sql;
create table kan1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from kan group by 放款月份 ;
quit;
proc sql;
create table kan2 as
select 放款月份,sum(逾期催回1)/sum(逾期) as a1催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan3 as
select 放款月份,sum(逾期催回2)/sum(逾期) as a2催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan4 as
select 放款月份,sum(逾期催回3)/sum(逾期) as a3催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan5 as
select 放款月份,sum(逾期催回4)/sum(逾期) as a4催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan6 as
select 放款月份,sum(逾期催回5)/sum(逾期) as a5催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan7 as
select 放款月份,sum(逾期催回6)/sum(逾期) as a6催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan8 as
select 放款月份,sum(逾期催回7)/sum(逾期) as a7催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan_all as
select a.*,b.a1催回率,c.a2催回率,d.a3催回率,e.a4催回率,f.a5催回率,g.a6催回率,
h.a7催回率 from kan1 as a
left join kan2 as b on a.放款月份=b.放款月份
left join kan3 as c on a.放款月份=c.放款月份
left join kan4 as d on a.放款月份=d.放款月份
left join kan5 as e on a.放款月份=e.放款月份
left join kan6 as f on a.放款月份=f.放款月份
left join kan7 as g on a.放款月份=g.放款月份
left join kan8 as h on a.放款月份=h.放款月份;
quit;


*新增;
data kan_xz;
set ct_payment_report;
if 客户标签=1;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706","201707");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(&dt.,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 逾期天数=1 and BILL_STATUS="0000" then 逾期催回1=1;
else if 逾期天数=2 and BILL_STATUS="0000" then 逾期催回2=1;
else if 逾期天数=3 and BILL_STATUS="0000" then 逾期催回3=1;
else if 逾期天数=4 and BILL_STATUS="0000" then 逾期催回4=1;
else if 逾期天数=5 and BILL_STATUS="0000" then 逾期催回5=1;
else if 逾期天数=6 and BILL_STATUS="0000" then 逾期催回6=1;
else if 逾期天数=7 and BILL_STATUS="0000" then 逾期催回7=1;

if 逾期天数>=1 then 逾期_a1=1;
if 逾期天数>=2 then 逾期_a2=1;
if 逾期天数>=3 then 逾期_a3=1;
if 逾期天数>=4 then 逾期_a4=1;
if 逾期天数>=5 then 逾期_a5=1;
if 逾期天数>=6 then 逾期_a6=1;
if 逾期天数>=7 then 逾期_a7=1;
run;
proc sql;
create table kan1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from kan_xz group by 放款月份 ;
quit;
proc sql;
create table kan2 as
select 放款月份,sum(逾期催回1)/sum(逾期) as a1催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan3 as
select 放款月份,sum(逾期催回2)/sum(逾期) as a2催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan4 as
select 放款月份,sum(逾期催回3)/sum(逾期) as a3催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan5 as
select 放款月份,sum(逾期催回4)/sum(逾期) as a4催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan6 as
select 放款月份,sum(逾期催回5)/sum(逾期) as a5催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan7 as
select 放款月份,sum(逾期催回6)/sum(逾期) as a6催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan8 as
select 放款月份,sum(逾期催回7)/sum(逾期) as a7催回率 format=percent7.2 from kan_xz group by 放款月份;
quit;
proc sql;
create table kan_all_xz as
select a.*,b.a1催回率,c.a2催回率,d.a3催回率,e.a4催回率,f.a5催回率,g.a6催回率,
h.a7催回率 from kan1 as a
left join kan2 as b on a.放款月份=b.放款月份
left join kan3 as c on a.放款月份=c.放款月份
left join kan4 as d on a.放款月份=d.放款月份
left join kan5 as e on a.放款月份=e.放款月份
left join kan6 as f on a.放款月份=f.放款月份
left join kan7 as g on a.放款月份=g.放款月份
left join kan8 as h on a.放款月份=h.放款月份;
quit;



*复贷;
data kan_fd;
set ct_payment_report;
if 客户标签>1;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706","201707");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(&dt.,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 逾期天数=1 and BILL_STATUS="0000" then 逾期催回1=1;
else if 逾期天数=2 and BILL_STATUS="0000" then 逾期催回2=1;
else if 逾期天数=3 and BILL_STATUS="0000" then 逾期催回3=1;
else if 逾期天数=4 and BILL_STATUS="0000" then 逾期催回4=1;
else if 逾期天数=5 and BILL_STATUS="0000" then 逾期催回5=1;
else if 逾期天数=6 and BILL_STATUS="0000" then 逾期催回6=1;
else if 逾期天数=7 and BILL_STATUS="0000" then 逾期催回7=1;


if 逾期天数>=1 then 逾期_a1=1;
if 逾期天数>=2 then 逾期_a2=1;
if 逾期天数>=3 then 逾期_a3=1;
if 逾期天数>=4 then 逾期_a4=1;
if 逾期天数>=5 then 逾期_a5=1;
if 逾期天数>=6 then 逾期_a6=1;
if 逾期天数>=7 then 逾期_a7=1;
run;
proc sql;
create table kan1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from kan_fd group by 放款月份 ;
quit;
proc sql;
create table kan2 as
select 放款月份,sum(逾期催回1)/sum(逾期) as a1催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan3 as
select 放款月份,sum(逾期催回2)/sum(逾期) as a2催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan4 as
select 放款月份,sum(逾期催回3)/sum(逾期) as a3催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan5 as
select 放款月份,sum(逾期催回4)/sum(逾期) as a4催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan6 as
select 放款月份,sum(逾期催回5)/sum(逾期) as a5催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan7 as
select 放款月份,sum(逾期催回6)/sum(逾期) as a6催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan8 as
select 放款月份,sum(逾期催回7)/sum(逾期) as a7催回率 format=percent7.2 from kan_fd group by 放款月份;
quit;
proc sql;
create table kan_all_fd as
select a.*,b.a1催回率,c.a2催回率,d.a3催回率,e.a4催回率,f.a5催回率,g.a6催回率,
h.a7催回率 from kan1 as a
left join kan2 as b on a.放款月份=b.放款月份
left join kan3 as c on a.放款月份=c.放款月份
left join kan4 as d on a.放款月份=d.放款月份
left join kan5 as e on a.放款月份=e.放款月份
left join kan6 as f on a.放款月份=f.放款月份
left join kan7 as g on a.放款月份=g.放款月份
left join kan8 as h on a.放款月份=h.放款月份;
quit;



*整体精确到个数;
data kan_num_all;
set haha.ct_payment_report;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706","201707");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(cut_date,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 逾期天数=1 and BILL_STATUS="0000" then 逾期催回1=1;
else if 逾期天数=2 and BILL_STATUS="0000" then 逾期催回2=1;
else if 逾期天数=3 and BILL_STATUS="0000" then 逾期催回3=1;
else if 逾期天数=4 and BILL_STATUS="0000" then 逾期催回4=1;
else if 逾期天数=5 and BILL_STATUS="0000" then 逾期催回5=1;
else if 逾期天数=6 and BILL_STATUS="0000" then 逾期催回6=1;
else if 逾期天数=7 and BILL_STATUS="0000" then 逾期催回7=1;


if 逾期天数>=1 then 逾期_a1=1;
if 逾期天数>=2 then 逾期_a2=1;
if 逾期天数>=3 then 逾期_a3=1;
if 逾期天数>=4 then 逾期_a4=1;
if 逾期天数>=5 then 逾期_a5=1;
if 逾期天数>=6 then 逾期_a6=1;
if 逾期天数>=7 then 逾期_a7=1;
run;
proc sql;
create table kan_sum1 as
select 放款月份,sum(逾期) as 自然逾期个数,sum(逾期催回1) as a1催回个数,sum(逾期催回2) as a2催回个数,sum(逾期催回3) as a3催回个数, sum(逾期催回4) as a4催回个数,
sum(逾期催回5) as a5催回率,sum(逾期催回6) as a6催回个数 ,sum(逾期催回7) as a7催回个数  from kan_num_all group by 放款月份 ;
quit;
