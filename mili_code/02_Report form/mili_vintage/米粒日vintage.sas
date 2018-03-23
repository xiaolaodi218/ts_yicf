option compress = yes validvarname = any;
libname repayFin "F:\米粒日vintage\data";
libname sss "F:\米粒逾期日报表\data";

proc printto log="F:\米粒日vintage\米粒日vintage.txt"  new;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;
*米粒放款客户;
data mili;
set sss.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
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

data repayfin.milipayment_report_m;
set payment;
format 报表标签 $20.;
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
proc sort data=repayfin.milipayment_report_m(where=(cut_date=&dt.)) out=ct_payment_report;by 还款天数;run;
*日vintage;
data vintage;
set repayfin.milipayment_report_m;
format 月mob $10.;
日mob=intck("day",repay_date,cut_date);
if 31<=日mob<=60 then 月mob="31-60";
else if 61<=日mob<=90 then 月mob="61-90";
else if 91<=日mob<=120 then 月mob="91-120";
else if 121<=日mob<=180 then 月mob="121-180";
else if 日mob>180 then 月mob="180+";
if od_days>=1 then do;overdue_1pst_amt=CURR_RECEIVE_CAPITAL_AMT;overdue_1pst_act=1;end;
if od_days>=5 then do;overdue_5pst_amt=CURR_RECEIVE_CAPITAL_AMT;overdue_5pst_act=1;end;
if repay_date<=cut_date then do;
if clear_date=. or clear_date>cut_date then od_本金=CURR_RECEIVE_CAPITAL_AMT;
else od_本金=0;
end;
if repay_date<=cut_date then do;
if clear_date=. or repay_date<clear_date then fpd=1;else fpd=0;
end;
run;
*****有用;
/*proc tabulate data=vintage(where=(0<=日mob<=30 and cut_date=&dt.)) out=kan_test(drop=_TYPE_ _PAGE_ _TABLE_ );*/
/*where loan_mon="&work_mon.";*/
/*class  LOAN_DATE 日mob;*/
/*var overdue_1pst_amt;*/
/*table LOAN_DATE,日mob*overdue_1pst_amt*(N*f=8. SUM)/misstext='0';*/
/*run;*/
/*proc sort data=kan_test;by  LOAN_DATE  日mob;run;*/
/*proc transpose data=kan_test out=kan_test1  prefix=Interest_;*/
/*by LOAN_DATE;*/
/*id 日mob;*/
/*var overdue_1pst_amt_Sum;*/
/*run;*/
*****有用;
x  "F:\米粒日vintage\米粒日VINTAGE.xls"; 

proc import datafile="F:\米粒日vintage\米粒报表配置表.xls"
out=lable dbms=excel replace;
SHEET="米粒日vintage";
scantext=no;
getnames=yes;
run;
data lable1;
set lable end=last;
call symput ("放款日期_"||compress(_n_),compress(loan_date));
TOTAL_TAT_L=_n_ +3;
TOTAL_TAT_27J=_n_ +4;
TOTAL_TAT_27F=_n_ +5;
TOTAL_TAT_27M=_n_ +6;
TOTAL_TAT_27A=_n_ +7;
TOTAL_TAT_27MA=_n_ +8;
TOTAL_TAT_27JU=_n_ +9;
TOTAL_TAT_27JUL=_n_ +10;
call symput("totale1_row_"||compress(_n_),compress(TOTAL_TAT_L));
call symput("totale1_row27J_"||compress(_n_),compress(TOTAL_TAT_27J));
call symput("totale1_row27F_"||compress(_n_),compress(TOTAL_TAT_27F));
call symput("totale1_row27M_"||compress(_n_),compress(TOTAL_TAT_27M));
call symput("totale1_row27A_"||compress(_n_),compress(TOTAL_TAT_27A));
call symput("totale1_row27MA_"||compress(_n_),compress(TOTAL_TAT_27MA));
call symput("totale1_row27JU_"||compress(_n_),compress(TOTAL_TAT_27JU));
call symput("totale1_row27JUL_"||compress(_n_),compress(TOTAL_TAT_27JUL));
if last then call symput("lpn",compress(_n_));
run;
*粘贴截止当前dt的.;
/*%macro city_table();*/
/*%do i =1 %to &lpn.;*/
/**/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,日mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 1<=日mob<=30)) group by loan_date,日MOB;*/
/*quit;*/
/*%let lon=1;*/
/*data _null_;*/
/*set kan end=last;*/
/*mob=日mob+6;*/
/*call symput ("mob_"||compress(_n_),compress(mob));*/
/*call symput ("日mob_"||compress(_n_),compress(日mob));*/
/*if last then call symput("lon",compress(_n_));*/
/*run;*/
/*%do m=1 %to &lon.;*/
/*data kan_m;*/
/*set kan;*/
/*if 日mob="&&日mob_&m..";*/
/*run;*/
/**/
/*filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row_&i..c&&mob_&m..:r&&totale1_row_&i..c&&mob_&m..";*/
/*data _null_;set kan_m;file DD;put overdue_1pst_amt;run;*/
/*%end;*/
/*%end;*/
/*%mend;*/
/*%city_table();*/
*amt;
proc tabulate data=vintage(where=(1<=日mob<=30  ) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date 日mob;
var overdue_1pst_amt;
table loan_date,日mob*overdue_1pst_amt*sum /misstext='0';
run;
proc sort data=kan ;by loan_date 日mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id 日mob;
var overdue_1pst_amt_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
*整体;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	   filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	   filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	   filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r1205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;

*期限;
proc import datafile="F:\米粒日vintage\米粒报表配置表.xls"
out=lable_period dbms=excel replace;
SHEET="米粒日vintage2";
scantext=no;
getnames=yes;
run;
data lable_period1;
set lable_period end=last;
call symput ("期数_"||compress(_n_),compress(期数));
if last then call symput("lqn",compress(_n_));
run;
%macro period_table();
%do i =1 %to &lqn.;
proc tabulate data=vintage(where=(1<=日mob<=30  and 还款天数=&&期数_&i..) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date 日mob;
var overdue_1pst_amt;
table loan_date,日mob*overdue_1pst_amt*sum /misstext='0';
run;
proc sort data=kan ;by loan_date 日mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id 日mob;
var overdue_1pst_amt_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13  ));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
%end;
%mend;
%period_table();

*act;
proc tabulate data=vintage(where=(1<=日mob<=30  ) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date 日mob;
var overdue_1pst_act;
table loan_date,日mob*overdue_1pst_act*sum /misstext='0';
run;
proc sort data=kan ;by loan_date 日mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id 日mob;
var overdue_1pst_act_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
*整体;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
*期限;

%macro period_table();
%do i =1 %to &lqn.;
proc tabulate data=vintage(where=(1<=日mob<=30  and 还款天数=&&期数_&i..) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date 日mob;
var overdue_1pst_act;
table loan_date,日mob*overdue_1pst_act*sum /misstext='0';
run;
proc sort data=kan ;by loan_date 日mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id 日mob;
var overdue_1pst_act_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13  ));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    	filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
%end;
%mend;
%period_table();


proc import datafile="F:\米粒MTD\米粒报表配置表.xls"
out=lable_m dbms=excel replace;
SHEET="米粒日vintage1";
scantext=no;
getnames=yes;
run;
*不能用上面的方法，不然31-60这个区间得出来的金额其实是这30天的累加,综合考虑还是上面用历史迭代，下面用当前dt值好一点;
data lable_m1;
set lable_m end=last;
rmob=_n_+36;
call symput ("月mob_"||compress(_n_),compress(月mob));
call symput("rmob_"||compress(_n_),compress(rmob));
if last then call symput("lmn",compress(_n_));
run;
*粘贴截止当前dt的.;
*amt;
/*%macro city_table_month_amt();*/
/*%do i =1 %to &lpn.;*/
/**/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;*/
/*quit;*/
/**/
/*%do m=1 %to &lmn.;*/
/*data kan_m;*/
/*set kan;*/
/*if 月mob=&&月mob_&m..;*/
/*run;*/
/*filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";*/
/*data _null_;set kan_m;file DD;put overdue_1pst_amt;run;*/
/*%end;*/
/*%end;*/
/*%mend;*/
/*%city_table_month_amt();*/


*整体;
%macro city_table_month_amt();
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();

*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();

*整体;
%macro city_table_month_amt();
%do i =14 %to 44;
proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();

*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;

%do i =14 %to 44;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();

*整体;
%macro city_table_month_amt();
%do i =45 %to 72;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*期数;
%macro city_table_month_amt();

%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;

%do i =45 %to 72;
proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*整体;
%macro city_table_month_amt();
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*整体;
%macro city_table_month_amt();

%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*整体;
%macro city_table_month_amt();

%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*整体;
%macro city_table_month_amt();

%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*整体;
%macro city_table_month_amt();

%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*期数;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天金额!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();


*act;


/*%macro city_table_month_act();*/
/*%do i =1 %to &lpn.;*/
/**/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  */
/*from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;*/
/*quit;*/
/**/
/*%do m=1 %to &lmn.;*/
/*data kan_m;*/
/*set kan;*/
/*if 月mob=&&月mob_&m..;*/
/*run;*/
/*filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";*/
/*data _null_;set kan_m;file DD;put overdue_1pst_act;run;*/
/*%end;*/
/*%end;*/
/*%mend;*/
/*%city_table_month_act();*/
*整体;
%macro city_table_month_act();
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =14 %to 44;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =14 %to 44;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =45 %to 72;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =45 %to 72;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_P(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*整体;
%macro city_table_month_act();
%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*期数;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if 还款天数=&&期数_&k..;
run;
%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,月mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&放款日期_&i and cut_date=&dt. and 月mob^="")) group by loan_date,月mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if 月mob=&&月mob_&m..;
run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&k..天个数!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*amt;
*整体;
proc sql;
create table kan_j as
select a.*,b.放款金额,c.未还本金,d.fpd
from lable as a
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as 放款金额 from vintage(where=(cut_date=&dt. and loan_date<=&dt.)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,sum(od_本金) as 未还本金 from vintage(where=(od_本金>0 and cut_date=&dt.)) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as fpd from vintage(where=(fpd=1 and cut_date=&dt.)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]金额!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put 放款金额 未还本金 fpd;run;
*期数;
%macro kfs();
%do i=1 %to &lqn.;
proc sql;
create table kan_j as
select a.*,b.放款金额,c.未还本金,d.fpd
from lable as a
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as 放款金额 from vintage(where=(cut_date=&dt. and loan_date<=&dt. and 还款天数=&&期数_&i..)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,sum(od_本金) as 未还本金 from vintage(where=(od_本金>0 and cut_date=&dt. and 还款天数=&&期数_&i.. )) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as fpd from vintage(where=(fpd=1 and cut_date=&dt. and 还款天数=&&期数_&i..)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put 放款金额 未还本金 fpd;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天金额!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put 放款金额 未还本金 fpd;run;
%end;
%mend;
%kfs();

*act;
proc sql;
create table kan_j as
select a.*,b.放款个数,c.未还个数,d.fpd个数
from lable as a
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as 放款个数 from vintage(where=(cut_date=&dt. and loan_date<=&dt.)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,count(od_本金) as 未还个数 from vintage(where=(od_本金>0 and cut_date=&dt.)) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as fpd个数 from vintage(where=(fpd=1 and cut_date=&dt.)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]个数!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put 放款个数 未还个数 fpd个数;run;
%macro kfs();
%do i=1 %to &lqn.;
proc sql;
create table kan_j as
select a.*,b.放款个数,c.未还个数,d.fpd个数
from lable as a
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as 放款个数 from vintage(where=(cut_date=&dt. and loan_date<=&dt. and 还款天数=&&期数_&i..)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,count(od_本金) as 未还个数 from vintage(where=(od_本金>0 and cut_date=&dt. and 还款天数=&&期数_&i..)) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as fpd个数 from vintage(where=(fpd=1 and cut_date=&dt. and 还款天数=&&期数_&i..)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put 放款个数 未还个数 fpd个数;run;
filename DD DDE "EXCEL|[米粒日VINTAGE.xls]&&期数_&i..天个数!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put 放款个数 未还个数 fpd个数;run;
%end;
%mend;
%kfs();

/*filename sas2xl dde 'excel|system';*/
/*data _null_;*/
/*file sas2xl;*/
/*put '[save()]';*/
/*put '[quit()]';*/
/*run;*/














/*proc sql;*/
/*create table kan_ as*/
/*select loan_date,日mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=mdy(2,13,2017) and cut_date=&dt. and 1<=日mob<=30)) group by loan_date,日MOB;*/
/*quit;*/
/**/
/*proc sql;*/
/*create table kank as*/
/*select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as 放款金额 from vintage(where=(loan_date=&dt.)) group by loan_date;*/
/*quit;*/
/*data kan1;*/
/*set vintage;*/
/*if loan_date=mdy(12,26,2016) and cut_date=&dt.;*/
/*keep contract_no overdue_1pst_amt 日MOB repay_date loan_date clear_date od_days;*/
/*run;*/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,月MOB,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=mdy(12,26,2016) and cut_date=&dt. and 月mob^="" )) group by loan_date,月MOB;*/
/*quit;*/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,日mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=mdy(2,21,2017) and cut_date=&dt. and 1<=日mob<=30)) group by loan_date,日MOB;*/
/*quit;*/
/*data kan11;*/
/*set vintage;*/
/*if loan_date=mdy(3,7,2017) and od_本金>0 and cut_date=&dt.;*/
/*run;*/
/**/
/*proc sql;*/
/*create table hehe as*/
/*select sum(CURR_RECEIVE_CAPITAL_AMT) from vintage where cut_date=&dt. ;*/
/*quit;*/
