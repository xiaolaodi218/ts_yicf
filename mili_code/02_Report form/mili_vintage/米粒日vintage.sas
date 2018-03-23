option compress = yes validvarname = any;
libname repayFin "F:\������vintage\data";
libname sss "F:\���������ձ���\data";

proc printto log="F:\������vintage\������vintage.txt"  new;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;
*�����ſ�ͻ�;
data mili;
set sss.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
��������=NEXT_REPAY_DATE-LOAN_DATE;
if kindex(PRODUCT_NAME,"����");
if contract_no ^="PL148178693332002600000066";/*�����ɳ�񻪵�*/
run;
proc sort data=mili;by id_number loan_date;run;
data mili1;
set mili;
by id_number loan_date;
if first.id_number then �ͻ���ǩ=1;
else �ͻ���ǩ+1;
run;

proc sort data=mili1 ;by NEXT_REPAY_DATE;run;
*�����ſ�ͻ��ĺ�ͬ���+��Ϣ;
proc sql;
create table mili_repay_plan as
select a.*,b.CURR_RECEIVE_CAPITAL_AMT,b.CURR_RECEIVE_INTEREST_AMT from mili1 as a
left join sss.repay_plan as b on a.contract_no=b.contract_no;
quit;
*�����ͻ���bill_main��;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join sss.bill_main as b on a.contract_no=b.contract_no;
quit;
proc sort data=mili_bill_main ;by repay_date;run;
*��ʱ��Ϊbill_main���curr_receive_amt�Ǽ�������õ�bill_fee_dtl���ܺ�;
*��ʱ���������ͻ����Ƕ�˽�ۿ���Բ�����Թ�����ֵ��߼����򵥵�;
%macro get_payment;
data _null_;
*����;
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
format cut_date yymmdd10. �˻���ǩ $20.;
cut_date=&cut_dt.;
*�ſ�ǰ;
if &cut_dt.<LOAN_DATE then do;
�˻���ǩ="δ�ſ�";
�����ͻ�=0;
end;
*������;
else if LOAN_DATE<=&cut_dt.<REPAY_DATE then do;
acc_interest=(&cut_dt.-loan_date)*CURR_RECEIVE_INTEREST_AMT/��������;
�������=sum(CURR_RECEIVE_CAPITAL_AMT,acc_interest);
�˻���ǩ="������";
�����ͻ�=1;
end;
*������;
else if &cut_dt.=REPAY_DATE then do;
if  CLEAR_DATE=. or &cut_dt.<CLEAR_DATE  then do;
�������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
�˻���ǩ="�ۿ�ʧ��";
�����ͻ�=1;
od_days=&cut_dt.-REPAY_DATE;
end;
else if CLEAR_DATE<=&cut_dt. then do;
�������=0;
�˻���ǩ="�ѻ���";
�����ͻ�=0;
od_days=0;
end;
end;
*������֮��;
else if &cut_dt. > repay_date then do;
if CLEAR_DATE=.  or &cut_dt.<CLEAR_DATE then do;
�������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
�˻���ǩ="����";
�����ͻ�=1;
od_days=&cut_dt.-REPAY_DATE;
end;

else if &cut_dt.>=CLEAR_DATE then do;
�������=0;
�˻���ǩ="�ѻ���";
�����ͻ�=0;
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
format �����ǩ $20.;
if REPAY_DATE-cut_date>=1 and REPAY_DATE-cut_date<=3 then �����ǩ="T_3";
else if 1<=od_days<=3 then �����ǩ="1one_three";
else if 4<=od_days<=15 then �����ǩ="2four_fifteen";
else if 16<=od_days<=30 then �����ǩ="3sixteen_thirty";
else if od_days>30 then �����ǩ="4thirty_";
else if od_days>90 then �����ǩ="5ninety_";
ͳ�Ƹ���=1;
�ſ��·�=put(LOAN_DATE,yymmn6.);
������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if �˻���ǩ="������" then ������=�������;
/*if contract_no="PL148224156660201400005011" then �����ǩ="T_3";*/
/*if �˻���ǩ in ("������","�ۿ�ʧ��") then �˻���ǩ2="Current";*/
if PRODUCT_NAME="����10" then ���Ա�ǩ="������";else ���Ա�ǩ="�����";
run;
proc sort data=repayfin.milipayment_report_m(where=(cut_date=&dt.)) out=ct_payment_report;by ��������;run;
*��vintage;
data vintage;
set repayfin.milipayment_report_m;
format ��mob $10.;
��mob=intck("day",repay_date,cut_date);
if 31<=��mob<=60 then ��mob="31-60";
else if 61<=��mob<=90 then ��mob="61-90";
else if 91<=��mob<=120 then ��mob="91-120";
else if 121<=��mob<=180 then ��mob="121-180";
else if ��mob>180 then ��mob="180+";
if od_days>=1 then do;overdue_1pst_amt=CURR_RECEIVE_CAPITAL_AMT;overdue_1pst_act=1;end;
if od_days>=5 then do;overdue_5pst_amt=CURR_RECEIVE_CAPITAL_AMT;overdue_5pst_act=1;end;
if repay_date<=cut_date then do;
if clear_date=. or clear_date>cut_date then od_����=CURR_RECEIVE_CAPITAL_AMT;
else od_����=0;
end;
if repay_date<=cut_date then do;
if clear_date=. or repay_date<clear_date then fpd=1;else fpd=0;
end;
run;
*****����;
/*proc tabulate data=vintage(where=(0<=��mob<=30 and cut_date=&dt.)) out=kan_test(drop=_TYPE_ _PAGE_ _TABLE_ );*/
/*where loan_mon="&work_mon.";*/
/*class  LOAN_DATE ��mob;*/
/*var overdue_1pst_amt;*/
/*table LOAN_DATE,��mob*overdue_1pst_amt*(N*f=8. SUM)/misstext='0';*/
/*run;*/
/*proc sort data=kan_test;by  LOAN_DATE  ��mob;run;*/
/*proc transpose data=kan_test out=kan_test1  prefix=Interest_;*/
/*by LOAN_DATE;*/
/*id ��mob;*/
/*var overdue_1pst_amt_Sum;*/
/*run;*/
*****����;
x  "F:\������vintage\������VINTAGE.xls"; 

proc import datafile="F:\������vintage\�����������ñ�.xls"
out=lable dbms=excel replace;
SHEET="������vintage";
scantext=no;
getnames=yes;
run;
data lable1;
set lable end=last;
call symput ("�ſ�����_"||compress(_n_),compress(loan_date));
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
*ճ����ֹ��ǰdt��.;
/*%macro city_table();*/
/*%do i =1 %to &lpn.;*/
/**/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and 1<=��mob<=30)) group by loan_date,��MOB;*/
/*quit;*/
/*%let lon=1;*/
/*data _null_;*/
/*set kan end=last;*/
/*mob=��mob+6;*/
/*call symput ("mob_"||compress(_n_),compress(mob));*/
/*call symput ("��mob_"||compress(_n_),compress(��mob));*/
/*if last then call symput("lon",compress(_n_));*/
/*run;*/
/*%do m=1 %to &lon.;*/
/*data kan_m;*/
/*set kan;*/
/*if ��mob="&&��mob_&m..";*/
/*run;*/
/**/
/*filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row_&i..c&&mob_&m..:r&&totale1_row_&i..c&&mob_&m..";*/
/*data _null_;set kan_m;file DD;put overdue_1pst_amt;run;*/
/*%end;*/
/*%end;*/
/*%mend;*/
/*%city_table();*/
*amt;
proc tabulate data=vintage(where=(1<=��mob<=30  ) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date ��mob;
var overdue_1pst_amt;
table loan_date,��mob*overdue_1pst_amt*sum /misstext='0';
run;
proc sort data=kan ;by loan_date ��mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id ��mob;
var overdue_1pst_amt_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
*����;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]���!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]���!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]���!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]���!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	   filename DD DDE "EXCEL|[������VINTAGE.xls]���!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	   filename DD DDE "EXCEL|[������VINTAGE.xls]���!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	   filename DD DDE "EXCEL|[������VINTAGE.xls]���!r1205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;

*����;
proc import datafile="F:\������vintage\�����������ñ�.xls"
out=lable_period dbms=excel replace;
SHEET="������vintage2";
scantext=no;
getnames=yes;
run;
data lable_period1;
set lable_period end=last;
call symput ("����_"||compress(_n_),compress(����));
if last then call symput("lqn",compress(_n_));
run;
%macro period_table();
%do i =1 %to &lqn.;
proc tabulate data=vintage(where=(1<=��mob<=30  and ��������=&&����_&i..) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date ��mob;
var overdue_1pst_amt;
table loan_date,��mob*overdue_1pst_amt*sum /misstext='0';
run;
proc sort data=kan ;by loan_date ��mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id ��mob;
var overdue_1pst_amt_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13  ));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
%end;
%mend;
%period_table();

*act;
proc tabulate data=vintage(where=(1<=��mob<=30  ) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date ��mob;
var overdue_1pst_act;
table loan_date,��mob*overdue_1pst_act*sum /misstext='0';
run;
proc sort data=kan ;by loan_date ��mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id ��mob;
var overdue_1pst_act_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
*����;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]����!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]����!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]����!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]����!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]����!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]����!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    filename DD DDE "EXCEL|[������VINTAGE.xls]����!r205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
*����;

%macro period_table();
%do i =1 %to &lqn.;
proc tabulate data=vintage(where=(1<=��mob<=30  and ��������=&&����_&i..) ) out=kan(drop=_type_ _TABLE_ _page_);
class loan_date ��mob;
var overdue_1pst_act;
table loan_date,��mob*overdue_1pst_act*sum /misstext='0';
run;
proc sort data=kan ;by loan_date ��mob;run;
proc transpose data=kan out=kan_tran(drop=_NAME_) prefix=mob;
by loan_date;
id ��mob;
var overdue_1pst_act_Sum;
run;
proc sql;
create table kan30 as
select a.*,b.* from lable as a
left join kan_tran as b on a.loan_date=b.loan_date;
quit;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r4c7:r16c36";
data _null_;set kan30(where=(1<=id<=13  ));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r18c7:r48c36";
data _null_;set kan30(where=(14<=id<=44));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r50c7:r77c36";
data _null_;set kan30(where=(45<=id<=72));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r79c7:r109c36";
data _null_;set kan30(where=(73<=id<=103));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r111c7:r140c36";
data _null_;set kan30(where=(104<=id<=133));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r142c7:r172c36";
data _null_;set kan30(where=(134<=id<=164));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r174c7:r203c36";
data _null_;set kan30(where=(165<=id<=194));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
    	filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r205c7:r235c36";
data _null_;set kan30(where=(195<=id<=225));file DD;
put mob1 mob2 mob3 mob4 mob5 mob6 mob7 mob8 mob9 mob10 
    mob11 mob12 mob13 mob14 mob15 mob16 mob17 mob18 mob19 mob20 
    mob21 mob22 mob23 mob24 mob25 mob26 mob27 mob28 mob29 mob30;run;
%end;
%mend;
%period_table();


proc import datafile="F:\����MTD\�����������ñ�.xls"
out=lable_m dbms=excel replace;
SHEET="������vintage1";
scantext=no;
getnames=yes;
run;
*����������ķ�������Ȼ31-60�������ó����Ľ����ʵ����30����ۼ�,�ۺϿ��ǻ�����������ʷ�����������õ�ǰdtֵ��һ��;
data lable_m1;
set lable_m end=last;
rmob=_n_+36;
call symput ("��mob_"||compress(_n_),compress(��mob));
call symput("rmob_"||compress(_n_),compress(rmob));
if last then call symput("lmn",compress(_n_));
run;
*ճ����ֹ��ǰdt��.;
*amt;
/*%macro city_table_month_amt();*/
/*%do i =1 %to &lpn.;*/
/**/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;*/
/*quit;*/
/**/
/*%do m=1 %to &lmn.;*/
/*data kan_m;*/
/*set kan;*/
/*if ��mob=&&��mob_&m..;*/
/*run;*/
/*filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";*/
/*data _null_;set kan_m;file DD;put overdue_1pst_amt;run;*/
/*%end;*/
/*%end;*/
/*%mend;*/
/*%city_table_month_amt();*/


*����;
%macro city_table_month_amt();
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();

*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();

*����;
%macro city_table_month_amt();
%do i =14 %to 44;
proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();

*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;

%do i =14 %to 44;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();

*����;
%macro city_table_month_amt();
%do i =45 %to 72;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();

%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;

%do i =45 %to 72;
proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();

%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();

%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();

%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();

%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_amt;run;
%end;
%end;
%mend;
%city_table_month_amt();
*����;
%macro city_table_month_amt();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..����!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
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
/*select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  */
/*from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;*/
/*quit;*/
/**/
/*%do m=1 %to &lmn.;*/
/*data kan_m;*/
/*set kan;*/
/*if ��mob=&&��mob_&m..;*/
/*run;*/
/*filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";*/
/*data _null_;set kan_m;file DD;put overdue_1pst_act;run;*/
/*%end;*/
/*%end;*/
/*%mend;*/
/*%city_table_month_act();*/
*����;
%macro city_table_month_act();
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =1 %to 13;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row_&i..c&&rmob_&m..:r&&totale1_row_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =14 %to 44;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =14 %to 44;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27J_&i..c&&rmob_&m..:r&&totale1_row27J_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =45 %to 72;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =45 %to 72;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_P(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27F_&i..c&&rmob_&m..:r&&totale1_row27F_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =73 %to 103;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27M_&i..c&&rmob_&m..:r&&totale1_row27M_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =104 %to 133;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27A_&i..c&&rmob_&m..:r&&totale1_row27A_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =134 %to 164;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27MA_&i..c&&rmob_&m..:r&&totale1_row27MA_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =165 %to 194;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27JU_&i..c&&rmob_&m..:r&&totale1_row27JU_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%mend;
%city_table_month_act();
*����;
%macro city_table_month_act();
%do k =1 %to &lqn.;
data vintage_p;
set vintage;
if ��������=&&����_&k..;
run;
%do i =195 %to 225;

proc sql;
create table kan as
select loan_date,��mob,sum(overdue_1pst_act) as overdue_1pst_act  
from vintage_p(where=(loan_date=&&�ſ�����_&i and cut_date=&dt. and ��mob^="")) group by loan_date,��mob;
quit;

%do m=1 %to &lmn.;
data kan_m;
set kan;
if ��mob=&&��mob_&m..;
run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&k..�����!r&&totale1_row27JUL_&i..c&&rmob_&m..:r&&totale1_row27JUL_&i..c&&rmob_&m..";
data _null_;set kan_m;file DD;put overdue_1pst_act;run;
%end;
%end;
%end;
%mend;
%city_table_month_act();
*amt;
*����;
proc sql;
create table kan_j as
select a.*,b.�ſ���,c.δ������,d.fpd
from lable as a
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as �ſ��� from vintage(where=(cut_date=&dt. and loan_date<=&dt.)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,sum(od_����) as δ������ from vintage(where=(od_����>0 and cut_date=&dt.)) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as fpd from vintage(where=(fpd=1 and cut_date=&dt.)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]���!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put �ſ��� δ������ fpd;run;
*����;
%macro kfs();
%do i=1 %to &lqn.;
proc sql;
create table kan_j as
select a.*,b.�ſ���,c.δ������,d.fpd
from lable as a
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as �ſ��� from vintage(where=(cut_date=&dt. and loan_date<=&dt. and ��������=&&����_&i..)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,sum(od_����) as δ������ from vintage(where=(od_����>0 and cut_date=&dt. and ��������=&&����_&i.. )) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as fpd from vintage(where=(fpd=1 and cut_date=&dt. and ��������=&&����_&i..)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put �ſ��� δ������ fpd;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..����!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put �ſ��� δ������ fpd;run;
%end;
%mend;
%kfs();

*act;
proc sql;
create table kan_j as
select a.*,b.�ſ����,c.δ������,d.fpd����
from lable as a
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as �ſ���� from vintage(where=(cut_date=&dt. and loan_date<=&dt.)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,count(od_����) as δ������ from vintage(where=(od_����>0 and cut_date=&dt.)) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as fpd���� from vintage(where=(fpd=1 and cut_date=&dt.)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]����!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put �ſ���� δ������ fpd����;run;
%macro kfs();
%do i=1 %to &lqn.;
proc sql;
create table kan_j as
select a.*,b.�ſ����,c.δ������,d.fpd����
from lable as a
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as �ſ���� from vintage(where=(cut_date=&dt. and loan_date<=&dt. and ��������=&&����_&i..)) group by loan_date) as b on a.loan_date=b.loan_date
left join (select loan_date,count(od_����) as δ������ from vintage(where=(od_����>0 and cut_date=&dt. and ��������=&&����_&i..)) group by loan_date) as c on a.loan_date=c.loan_date
left join (select loan_date,count(CURR_RECEIVE_CAPITAL_AMT) as fpd���� from vintage(where=(fpd=1 and cut_date=&dt. and ��������=&&����_&i..)) group by loan_date) as d on a.loan_date=d.loan_date;
quit;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r4c4:r16c6";
data _null_;set kan_j(where=(1<=id<=13));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r18c4:r48c6";
data _null_;set kan_j(where=(14<=id<=44));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r50c4:r77c6";
data _null_;set kan_j(where=(45<=id<=72));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r79c4:r109c6";
data _null_;set kan_j(where=(73<=id<=103));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r111c4:r140c6";
data _null_;set kan_j(where=(104<=id<=133));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r142c4:r172c6";
data _null_;set kan_j(where=(134<=id<=164));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r174c4:r203c6";
data _null_;set kan_j(where=(165<=id<=194));file DD;put �ſ���� δ������ fpd����;run;
filename DD DDE "EXCEL|[������VINTAGE.xls]&&����_&i..�����!r205c4:r235c6";
data _null_;set kan_j(where=(195<=id<=225));file DD;put �ſ���� δ������ fpd����;run;
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
/*select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=mdy(2,13,2017) and cut_date=&dt. and 1<=��mob<=30)) group by loan_date,��MOB;*/
/*quit;*/
/**/
/*proc sql;*/
/*create table kank as*/
/*select loan_date,sum(CURR_RECEIVE_CAPITAL_AMT) as �ſ��� from vintage(where=(loan_date=&dt.)) group by loan_date;*/
/*quit;*/
/*data kan1;*/
/*set vintage;*/
/*if loan_date=mdy(12,26,2016) and cut_date=&dt.;*/
/*keep contract_no overdue_1pst_amt ��MOB repay_date loan_date clear_date od_days;*/
/*run;*/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,��MOB,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=mdy(12,26,2016) and cut_date=&dt. and ��mob^="" )) group by loan_date,��MOB;*/
/*quit;*/
/*proc sql;*/
/*create table kan as*/
/*select loan_date,��mob,sum(overdue_1pst_amt) as overdue_1pst_amt  */
/*from vintage(where=(loan_date=mdy(2,21,2017) and cut_date=&dt. and 1<=��mob<=30)) group by loan_date,��MOB;*/
/*quit;*/
/*data kan11;*/
/*set vintage;*/
/*if loan_date=mdy(3,7,2017) and od_����>0 and cut_date=&dt.;*/
/*run;*/
/**/
/*proc sql;*/
/*create table hehe as*/
/*select sum(CURR_RECEIVE_CAPITAL_AMT) from vintage where cut_date=&dt. ;*/
/*quit;*/
