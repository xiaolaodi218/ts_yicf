option compress = yes validvarname = any;
libname sss "F:\米粒逾期日报表\data";
libname repayFin "F:\米粒坏账率预测\repayAnalysis";

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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by 还款天数;run;


*整体;
data kan;
set ct_payment_report;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(cut_date,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 1<=逾期天数<=3 and BILL_STATUS="0000" then 逾期催回1_3=1;
else if 4<=逾期天数<=10 and BILL_STATUS="0000" then 逾期催回4_10=1;
else if 11<=逾期天数<=15 and BILL_STATUS="0000" then 逾期催回11_15=1;
else if 16<=逾期天数<=30 and BILL_STATUS="0000" then 逾期催回16_30=1;
else if 31<=逾期天数<=60 and BILL_STATUS="0000" then 逾期催回31_60=1;
else if 61<=逾期天数<=90 and BILL_STATUS="0000" then 逾期催回61_90=1;
else if 逾期天数>90 and BILL_STATUS="0000" then 逾期催回90=1;


if 逾期天数>3 then 逾期_a3=1;
if 逾期天数>10 then 逾期_a10=1;
if 逾期天数>15 then 逾期_a15=1;
if 逾期天数>30 then 逾期_a30=1;
if 逾期天数>60 then 逾期_a60=1;
if 逾期天数>90 then 逾期_a90=1;
run;
proc sql;
create table kan1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from kan group by 放款月份 ;
quit;
proc sql;
create table kan2 as
select 放款月份,sum(逾期催回1_3)/sum(逾期) as a1_3催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan3 as
select 放款月份,sum(逾期_a3)/count(*) as a3天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan4 as
select 放款月份,sum(逾期催回4_10)/sum(逾期_a3) as a4_10催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan5 as
select 放款月份,sum(逾期_a10)/count(*) as a10天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan6 as
select 放款月份,sum(逾期催回11_15)/sum(逾期_a10) as a11_15催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan7 as
select 放款月份,sum(逾期_a15)/count(*) as a15天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan8 as
select 放款月份,sum(逾期催回16_30)/sum(逾期_a15) as a16_30催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan9 as
select 放款月份,sum(逾期_a30)/count(*) as a30天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan10 as
select 放款月份,sum(逾期催回31_60)/sum(逾期_a30) as a31_60催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan11 as
select 放款月份,sum(逾期_a60)/count(*) as a60天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan12 as
select 放款月份,sum(逾期催回61_90)/sum(逾期_a60) as a61_90催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan13 as
select 放款月份,sum(逾期_a90)/count(*) as 总坏账率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan14 as
select 放款月份,sum(催回)/sum(逾期) as 总催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan_all as
select a.*,b.a1_3催回率,c.a3天以上逾期率,d.a4_10催回率,e.a10天以上逾期率,f.a11_15催回率,g.a15天以上逾期率,
h.a16_30催回率,i.a30天以上逾期率,j.a31_60催回率,k.a60天以上逾期率,l.a61_90催回率,m.总坏账率,n.总催回率 from kan1 as a
left join kan2 as b on a.放款月份=b.放款月份
left join kan3 as c on a.放款月份=c.放款月份
left join kan4 as d on a.放款月份=d.放款月份
left join kan5 as e on a.放款月份=e.放款月份
left join kan6 as f on a.放款月份=f.放款月份
left join kan7 as g on a.放款月份=g.放款月份
left join kan8 as h on a.放款月份=h.放款月份
left join kan9 as i on a.放款月份=i.放款月份
left join kan10 as j on a.放款月份=j.放款月份
left join kan11 as k on a.放款月份=k.放款月份
left join kan12 as l on a.放款月份=l.放款月份
left join kan13 as m on a.放款月份=m.放款月份
left join kan14 as n on a.放款月份=n.放款月份;
quit;

x "F:\米粒坏账率预测\坏账比率(米粒).xlsx";
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c1:r9c3';
data _null_;
set Work.Kan_all;
file DD;
put 放款月份 自然逾期率 a1_3催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c5:r9c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c7:r9c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c9:r9c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c11:r9c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c13:r9c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r3c15:r9c15';
data _null_;
set Work.Kan_all;
file DD;
put 总催回率;
run;


*新增;
data kan;
set ct_payment_report;
if 客户标签=1;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(&dt.,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 1<=逾期天数<=3 and BILL_STATUS="0000" then 逾期催回1_3=1;
else if 4<=逾期天数<=10 and BILL_STATUS="0000" then 逾期催回4_10=1;
else if 11<=逾期天数<=15 and BILL_STATUS="0000" then 逾期催回11_15=1;
else if 16<=逾期天数<=30 and BILL_STATUS="0000" then 逾期催回16_30=1;
else if 31<=逾期天数<=60 and BILL_STATUS="0000" then 逾期催回31_60=1;
else if 61<=逾期天数<=90 and BILL_STATUS="0000" then 逾期催回61_90=1;
else if 逾期天数>90 and BILL_STATUS="0000" then 逾期催回90=1;


if 逾期天数>3 then 逾期_a3=1;
if 逾期天数>10 then 逾期_a10=1;
if 逾期天数>15 then 逾期_a15=1;
if 逾期天数>30 then 逾期_a30=1;
if 逾期天数>60 then 逾期_a60=1;
if 逾期天数>90 then 逾期_a90=1;
run;
proc sql;
create table kan1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from kan group by 放款月份 ;
quit;
proc sql;
create table kan2 as
select 放款月份,sum(逾期催回1_3)/sum(逾期) as a1_3催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan3 as
select 放款月份,sum(逾期_a3)/count(*) as a3天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan4 as
select 放款月份,sum(逾期催回4_10)/sum(逾期_a3) as a4_10催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan5 as
select 放款月份,sum(逾期_a10)/count(*) as a10天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan6 as
select 放款月份,sum(逾期催回11_15)/sum(逾期_a10) as a11_15催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan7 as
select 放款月份,sum(逾期_a15)/count(*) as a15天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan8 as
select 放款月份,sum(逾期催回16_30)/sum(逾期_a15) as a16_30催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan9 as
select 放款月份,sum(逾期_a30)/count(*) as a30天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan10 as
select 放款月份,sum(逾期催回31_60)/sum(逾期_a30) as a31_60催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan11 as
select 放款月份,sum(逾期_a60)/count(*) as a60天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan12 as
select 放款月份,sum(逾期催回61_90)/sum(逾期_a60) as a61_90催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan13 as
select 放款月份,sum(逾期_a90)/count(*) as 总坏账率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan14 as
select 放款月份,sum(催回)/sum(逾期) as 总催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan_all as
select a.*,b.a1_3催回率,c.a3天以上逾期率,d.a4_10催回率,e.a10天以上逾期率,f.a11_15催回率,g.a15天以上逾期率,
h.a16_30催回率,i.a30天以上逾期率,j.a31_60催回率,k.a60天以上逾期率,l.a61_90催回率,m.总坏账率,n.总催回率 from kan1 as a
left join kan2 as b on a.放款月份=b.放款月份
left join kan3 as c on a.放款月份=c.放款月份
left join kan4 as d on a.放款月份=d.放款月份
left join kan5 as e on a.放款月份=e.放款月份
left join kan6 as f on a.放款月份=f.放款月份
left join kan7 as g on a.放款月份=g.放款月份
left join kan8 as h on a.放款月份=h.放款月份
left join kan9 as i on a.放款月份=i.放款月份
left join kan10 as j on a.放款月份=j.放款月份
left join kan11 as k on a.放款月份=k.放款月份
left join kan12 as l on a.放款月份=l.放款月份
left join kan13 as m on a.放款月份=m.放款月份
left join kan14 as n on a.放款月份=n.放款月份;
quit;

filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c1:r29c3';
data _null_;
set Work.Kan_all;
file DD;
put 放款月份 自然逾期率 a1_3催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c5:r29c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c7:r29c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c9:r29c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c11:r29c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c13:r29c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r23c15:r29c15';
data _null_;
set Work.Kan_all;
file DD;
put 总催回率;
run;

*复贷;
data kan;
set ct_payment_report;
if 客户标签>1;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(&dt.,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 1<=逾期天数<=3 and BILL_STATUS="0000" then 逾期催回1_3=1;
else if 4<=逾期天数<=10 and BILL_STATUS="0000" then 逾期催回4_10=1;
else if 11<=逾期天数<=15 and BILL_STATUS="0000" then 逾期催回11_15=1;
else if 16<=逾期天数<=30 and BILL_STATUS="0000" then 逾期催回16_30=1;
else if 31<=逾期天数<=60 and BILL_STATUS="0000" then 逾期催回31_60=1;
else if 61<=逾期天数<=90 and BILL_STATUS="0000" then 逾期催回61_90=1;
else if 逾期天数>90 and BILL_STATUS="0000" then 逾期催回90=1;


if 逾期天数>3 then 逾期_a3=1;
if 逾期天数>10 then 逾期_a10=1;
if 逾期天数>15 then 逾期_a15=1;
if 逾期天数>30 then 逾期_a30=1;
if 逾期天数>60 then 逾期_a60=1;
if 逾期天数>90 then 逾期_a90=1;
run;
proc sql;
create table kan1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from kan group by 放款月份 ;
quit;
proc sql;
create table kan2 as
select 放款月份,sum(逾期催回1_3)/sum(逾期) as a1_3催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan3 as
select 放款月份,sum(逾期_a3)/count(*) as a3天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan4 as
select 放款月份,sum(逾期催回4_10)/sum(逾期_a3) as a4_10催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan5 as
select 放款月份,sum(逾期_a10)/count(*) as a10天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan6 as
select 放款月份,sum(逾期催回11_15)/sum(逾期_a10) as a11_15催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan7 as
select 放款月份,sum(逾期_a15)/count(*) as a15天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan8 as
select 放款月份,sum(逾期催回16_30)/sum(逾期_a15) as a16_30催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan9 as
select 放款月份,sum(逾期_a30)/count(*) as a30天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan10 as
select 放款月份,sum(逾期催回31_60)/sum(逾期_a30) as a31_60催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan11 as
select 放款月份,sum(逾期_a60)/count(*) as a60天以上逾期率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan12 as
select 放款月份,sum(逾期催回61_90)/sum(逾期_a60) as a61_90催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan13 as
select 放款月份,sum(逾期_a90)/count(*) as 总坏账率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan14 as
select 放款月份,sum(催回)/sum(逾期) as 总催回率 format=percent7.2 from kan group by 放款月份;
quit;
proc sql;
create table kan_all as
select a.*,b.a1_3催回率,c.a3天以上逾期率,d.a4_10催回率,e.a10天以上逾期率,f.a11_15催回率,g.a15天以上逾期率,
h.a16_30催回率,i.a30天以上逾期率,j.a31_60催回率,k.a60天以上逾期率,l.a61_90催回率,m.总坏账率,n.总催回率 from kan1 as a
left join kan2 as b on a.放款月份=b.放款月份
left join kan3 as c on a.放款月份=c.放款月份
left join kan4 as d on a.放款月份=d.放款月份
left join kan5 as e on a.放款月份=e.放款月份
left join kan6 as f on a.放款月份=f.放款月份
left join kan7 as g on a.放款月份=g.放款月份
left join kan8 as h on a.放款月份=h.放款月份
left join kan9 as i on a.放款月份=i.放款月份
left join kan10 as j on a.放款月份=j.放款月份
left join kan11 as k on a.放款月份=k.放款月份
left join kan12 as l on a.放款月份=l.放款月份
left join kan13 as m on a.放款月份=m.放款月份
left join kan14 as n on a.放款月份=n.放款月份;
quit;

filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c1:r49c3';
data _null_;
set Work.Kan_all;
file DD;
put 放款月份 自然逾期率 a1_3催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c5:r49c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c7:r49c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c9:r49c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c11:r49c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c13:r49c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]工作表2!r43c15:r49c15';
data _null_;
set Work.Kan_all;
file DD;
put 总催回率;
run;

/**/
/*data  ckan;*/
/*set kan;*/
/*if 放款月份=201701;*/
/*if 逾期催回1_3=1;*/
/*run;*/
/*data  ckan1;*/
/*set kan;*/
/*if 放款月份=201701;*/
/*if 逾期催回1_3^=1 and 逾期=1;*/
/*run;*/
/*data  ckan2;*/
/*set kan;*/
/*if 放款月份=201612;*/
/*run;*/
/*data ckan3;*/
/*set kan;*/
/*if 放款月份=201612;*/
/*if 逾期_a3=1;*/
/*run;*/
