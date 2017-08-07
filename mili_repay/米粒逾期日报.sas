libname account odbc datasrc=account_nf;
option compress = yes validvarname = any;
libname repayFin "F:\米粒逾期日报表\data";

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
/*%let dt=mdy(7,2,2017);*/

***米粒放款客户;
data mili;
set repayFin.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
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

if PRODUCT_NAME="米粒10" then 策略标签="银策略";else 策略标签="金策略";
run;
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by 还款天数;run;


*************************************************************************************************************;
***米粒日逾期流转报表;

data month1day;
set repayFin.Milipayment_report(keep=contract_no  od_days cut_date 贷款余额 账户标签 客户标签 策略标签 PRODUCT_NAME)	;
if 账户标签="扣款失败" then 还款_当日扣款失败合同=1;
run;
proc sort data=month1day ;by CONTRACT_no cut_date;run;
data  cc;
set month1day;
format 期初标签 期末标签 流转标签 $30.;
if 客户标签=1 then do;
if 策略标签="银策略" then 流转标签="银策略";
else if 策略标签="金策略" then 流转标签="金策略";end;
else 流转标签="复贷客户";

last_oddays=lag(od_days);
last_贷款余额=lag(贷款余额);
last_还款_当日扣款失败合同=lag(还款_当日扣款失败合同);
by CONTRACT_no cut_date;
if first.contract_no then do ;last_oddays=od_days;last_贷款余额=贷款余额;last_还款_当日扣款失败合同=还款_当日扣款失败合同;end;
if cut_date=&dt.;
/*if cut_date=mdy(10,14,2016);*/
if 1<=last_oddays<=2 or (last_oddays=0 and last_还款_当日扣款失败合同=1)then 期初标签="01:1-3";
else if 3<=last_oddays<=14 then 期初标签="02:4-15";
else if 15<=last_oddays<=29 then 期初标签="03:16-30";
else if 30<=last_oddays<=59 then 期初标签="04:31-60";
else if 60<=last_oddays<=89 then 期初标签="05:61-90";


if 1<=od_days<=2 or (od_days in (0,.) and 还款_当日扣款失败合同=1)then 期末标签="01:1-3";
else if 3<=od_days<=14 then 期末标签="02:4-15";
else if 15<=od_days<=29 then 期末标签="03:16-30";
else if 30<=od_days<=59 then 期末标签="04:31-60";
else if 60<=od_days<=89 then 期末标签="05:61-90";

*新增;
if ((od_days=0 and 还款_当日扣款失败合同=1) or 
((od_days=3 or od_days=15  or od_days=30 or od_days=60 ) and last_oddays<od_days))
then  新增=1;else 新增=0;

*好转流出;
if ((1<=last_oddays<=2 or (last_oddays=0 and last_还款_当日扣款失败合同=1)) and od_days<1) or 
   (3<=last_oddays<=14 and od_days<3) or 
   (15<=last_oddays<=29 and od_days<15)  or
   (30<=last_oddays<=59 and od_days<30) or
   (60<=last_oddays<=89 and od_days<60)  then 好转流出=1;else 好转流出=0;
*恶化流出;
if ((1<=last_oddays<=2 or (last_oddays=0 and last_还款_当日扣款失败合同=1)) and od_days>2) or 
   (3<=last_oddays<=14 and od_days>14) or
   (15<=last_oddays<=29 and od_days>29)  or
   (30<=last_oddays<=59 and od_days>59) or
   (60<=last_oddays<=89 and od_days>89) then 恶化流出=1;else 恶化流出=0;
*催回;
   if od_days=0 and (last_oddays>0 or last_还款_当日扣款失败合同=1)  then 催回=1;else 催回=0;
run;
*由于下面代码取数时的筛选条件，结果表中期末标签=""是逾期180天以上的;
proc sql;
create table cc1(where=(期末标签^="")) as
select 期末标签,sum(新增) as 新增 ,count(*) as 期末,sum(贷款余额) as 贷款余额  from cc (where=(od_days>0 or (od_days=0 and 还款_当日扣款失败合同=1))) group by 期末标签;
quit;
*由于下面代码取数时的筛选条件，结果表中期初标签=""是逾期180天以上的;
proc sql;
create table cc1_1(where=(期初标签^="")) as
select 期初标签,sum(好转流出) as 好转流出,sum(恶化流出) as 恶化流出,count(*) as 期初  from cc (where=(last_oddays>0 or (last_oddays=0 and last_还款_当日扣款失败合同=1))) group by 期初标签;
quit;
*期初标签=""的是前天逾期，昨天催回的;
proc sql;
create table cc1_2(where=(期初标签^="")) as
select 期初标签,sum(催回) as 催回   from cc  group by 期初标签;
quit;
proc sql;
create table cc2 as
select a.*,b.*,c.催回 from cc1 as a
left join cc1_1 as b on a.期末标签=b.期初标签
left join cc1_2 as c on a.期末标签=c.期初标签;
quit;
data st1 st2;
set cc2;
if 期末标签 in ("01:1-3","02:4-15","03:16-30") then output st1;
else output st2;
run;
x  "F:\米粒逾期日报表\米粒日逾期流转报表.xlsx"; 
filename DD DDE 'EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r4c5:r6c9';
data _null_;set st1;file DD;put 期初 新增  好转流出 恶化流出 催回;run;
filename DD DDE 'EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r4c11:r6c12';
data _null_;set st1;file DD;put 期末 贷款余额;run;

filename DD DDE 'EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r8c5:r9c9';
data _null_;set st2;file DD;put 期初 新增  好转流出 恶化流出 催回;run;
filename DD DDE 'EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r8c11:r9c12';
data _null_;set st2;file DD;put 期末 贷款余额;run;
proc sql;
create table aall as
select count(CONTRACT_NO) as 未结清笔数,sum(贷款余额) as 未结清贷款余额 from cc(where=(账户标签 in ("扣款失败","逾期")));
quit;
filename DD DDE 'EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r4c2:r4c3';
data _null_;set aall;file DD;put 未结清笔数 未结清贷款余额;run;


proc import datafile="F:\米粒逾期日报表\米粒日逾期流转报表配置表.xls"
out=lable dbms=excel replace;
SHEET="Sheet1$";
scantext=no;
getnames=yes;
run;
data lable1;
set lable end=last;
call symput ("lable_"||compress(_n_),compress(标签));
TOTAL_TAT_b1=4+_n_*9;
TOTAL_TAT_b2=8+_n_*9;
TOTAL_TAT_e1=6+_n_*9;
TOTAL_TAT_e2=9+_n_*9;
call symput ("totalb1_row_"||compress(_n_),compress(TOTAL_TAT_b1));
call symput ("totalb2_row_"||compress(_n_),compress(TOTAL_TAT_b2));
call symput("totale1_row_"||compress(_n_),compress(TOTAL_TAT_e1));
call symput("totale2_row_"||compress(_n_),compress(TOTAL_TAT_e2));

if last then call symput("lpn",compress(_n_));
run;

%macro city_table();
%do i =1 %to &lpn.;
proc sql;
create table cc1(where=(期末标签^="")) as
select 期末标签,sum(新增) as 新增 ,count(*) as 期末,sum(贷款余额) as 贷款余额  from cc (where=((od_days>0 or (od_days=0 and 还款_当日扣款失败合同=1)) and 流转标签="&&lable_&i")) group by 期末标签;
quit;

proc sql;
create table cc1_1(where=(期初标签^="")) as
select 期初标签,sum(好转流出) as 好转流出,sum(恶化流出) as 恶化流出,count(*) as 期初  from cc (where=((last_oddays>0 or (last_oddays=0 and last_还款_当日扣款失败合同=1))and 流转标签="&&lable_&i")) group by 期初标签;
quit;
proc sql;
create table cc1_2(where=(期初标签^="")) as
select 期初标签,sum(催回) as 催回   from cc(where=( 流转标签="&&lable_&i"))  group by 期初标签;
quit;
proc sql;
create table cc2 as
select a.*,b.*,c.催回 from cc1 as a
left join cc1_1 as b on a.期末标签=b.期初标签
left join cc1_2 as c on a.期末标签=c.期初标签;
quit;
data st1 st2;
set cc2;
if 期末标签 in ("01:1-3","02:4-15","03:16-30") then output st1;
else output st2;
run;
filename DD DDE "EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r&&totalb1_row_&i..c5:r&&totale1_row_&i..c9";
data _null_;set st1;file DD;put 期初 新增  好转流出 恶化流出 催回;run;
filename DD DDE "EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r&&totalb1_row_&i..c11:r&&totale1_row_&i..c12";
data _null_;set st1;file DD;put 期末 贷款余额;run;

filename DD DDE "EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r&&totalb2_row_&i..c5:r&&totale2_row_&i..c9";
data _null_;set st2;file DD;put 期初 新增  好转流出 恶化流出 催回;run;
filename DD DDE "EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r&&totalb2_row_&i..c11:r&&totale2_row_&i..c12";
data _null_;set st2;file DD;put 期末 贷款余额;run;
proc sql;
create table aall as
select count(CONTRACT_NO) as 未结清笔数,sum(贷款余额) as 未结清贷款余额 from cc(where=(账户标签 in ("扣款失败","逾期") and 流转标签="&&lable_&i"));
quit;
filename DD DDE "EXCEL|[米粒日逾期流转报表.xlsx]Sheet1!r&&totalb1_row_&i..c2:r&&totalb1_row_&i..c3";
data _null_;set aall;file DD;put 未结清笔数 未结清贷款余额;run;
%end;
%mend;
%city_table();


/**周一做报表是用;*/
/*data  kan;*/
/*set month1day;*/
/*last_oddays=lag(od_days);*/
/*last_还款_当日扣款失败合同=lag(还款_当日扣款失败合同);*/
/*by CONTRACT_no cut_date;*/
/*if first.contract_no then do ;last_oddays=od_days;last_贷款余额=贷款余额;last_还款_当日扣款失败合同=还款_当日扣款失败合同;end;*/
/*if cut_date=&dt.-1;*/
/*if od_days=0 and (last_oddays>0 or last_还款_当日扣款失败合同=1);*/
/*run;*/
/*data  kan1;*/
/*set month1day;*/
/*last_oddays=lag(od_days);*/
/*last_还款_当日扣款失败合同=lag(还款_当日扣款失败合同);*/
/*by CONTRACT_no cut_date;*/
/*if first.contract_no then do ;last_oddays=od_days;last_贷款余额=贷款余额;last_还款_当日扣款失败合同=还款_当日扣款失败合同;end;*/
/*if cut_date=&dt.-2;*/
/*if od_days=0 and (last_oddays>0 or last_还款_当日扣款失败合同=1);*/
/*run;*/
