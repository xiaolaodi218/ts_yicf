libname account odbc datasrc=account_nf;
option compress = yes validvarname = any;
libname repayFin "F:\���������ͻ������ռ������\repayAnalysis";
%let bt=mdy(7,20,2017);

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;
*�����ſ�ͻ�;
data mili;
set account.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
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
left join account.repay_plan as b on a.contract_no=b.contract_no;
quit;
*�����ͻ���bill_main��;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join account.bill_main as b on a.contract_no=b.contract_no;
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

data repayfin.milipayment_report;
set payment;
format �����ǩ $20.;
if �˻���ǩ^="δ�ſ�";
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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by ��������;run;
proc sort data=Ct_payment_report ;by ID_NUMBER �ͻ���ǩ;run;
data kan;
set Ct_payment_report;
if �˻���ǩ="δ�ſ�" then delete;
format lag_����ʱ�� yymmdd10.;
lag_����ʱ��=lag(CLEAR_DATE);
�ͻ���ǩ_����=�ͻ���ǩ-1;
by ID_NUMBER �ͻ���ǩ;
if first.ID_NUMBER then lag_����ʱ��=clear_date;
run;
data kan1;
set kan;
if lag_����ʱ��^=. then
���=loan_date-lag_����ʱ��;
format �����ǩ $20.;
if ���=0 then �����ǩ="T+0";
else if ���=1 then �����ǩ="T+1";
else if ���=2 then �����ǩ="T+2";
else if 3<=���<=5 then �����ǩ="T+3-5";
else if 6<=���<=10 then �����ǩ="T+6-10";
else if 11<=���<=15 then �����ǩ="T+11-15";
else if 16<=���<=20 then �����ǩ="T+16-20";
else if 21<=���<=30 then �����ǩ="T+21-30";
else if 31<=���<=60 then �����ǩ="T+31-60";
else if 61<=���<=90 then �����ǩ="T+61-90";
else if ���>=91 then �����ǩ="T+91����";
keep �ͻ���ǩ ��� lag_����ʱ�� loan_date ID_NUMBER �ͻ���ǩ_���� contract_no �����ǩ CURR_RECEIVE_CAPITAL_AMT;
run;
proc sort data=kan1(where=(�ͻ���ǩ_����>0)) nodupkey out=kan2;by contract_no ;run;
proc sql;
create table kan3 as
select  �ͻ���ǩ_����,
sum(case when �����ǩ="T+0"  then 1 else 0 end ) as a0,
sum(case when �����ǩ="T+1"  then 1 else 0 end ) as a1,
sum(case when �����ǩ="T+2"  then 1 else 0 end ) as a2,
sum(case when �����ǩ="T+3-5"  then 1 else 0 end ) as a5,
sum(case when �����ǩ="T+6-10"  then 1 else 0 end ) as a10,
sum(case when �����ǩ="T+11-15"  then 1 else 0 end ) as a15,
sum(case when �����ǩ="T+16-20"  then 1 else 0 end ) as a20,
sum(case when �����ǩ="T+21-30"  then 1 else 0 end ) as a30,
sum(case when �����ǩ="T+31-60"  then 1 else 0 end ) as a60,
sum(case when �����ǩ="T+61-90"  then 1 else 0 end ) as a90,
sum(case when �����ǩ="T+91����"  then 1 else 0 end ) as a91
from kan2 group by �ͻ���ǩ_����;
quit;
proc sql;
create table kan3_je as
select  �ͻ���ǩ_����,
sum(case when �����ǩ="T+0"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a0,
sum(case when �����ǩ="T+1"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a1,
sum(case when �����ǩ="T+2"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a2,
sum(case when �����ǩ="T+3-5"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a5,
sum(case when �����ǩ="T+6-10"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a10,
sum(case when �����ǩ="T+11-15"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a15,
sum(case when �����ǩ="T+16-20"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a20,
sum(case when �����ǩ="T+21-30"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a30,
sum(case when �����ǩ="T+31-60"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a60,
sum(case when �����ǩ="T+61-90"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a90,
sum(case when �����ǩ="T+91����"  then CURR_RECEIVE_CAPITAL_AMT else 0 end ) as a91
from kan2 group by �ͻ���ǩ_����;
quit;
x  "F:\���������ͻ������ռ������\repayAnalysis\���������ͻ������ռ���±�.xlsx"; 
filename DD DDE 'EXCEL|[���������ͻ������ռ���±�.xlsx]����!r2c2:r16c12';
data _null_;set kan3;file DD;put a0 a1 a2 a5 a10 a15 a20 a30 a60 a90 a91;run;
filename DD DDE 'EXCEL|[���������ͻ������ռ���±�.xlsx]���!r2c2:r16c12';
data _null_;set kan3_je;file DD;put a0 a1 a2 a5 a10 a15 a20 a30 a60 a90 a91;run;
