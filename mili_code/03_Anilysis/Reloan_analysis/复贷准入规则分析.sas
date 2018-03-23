****��һ���֣��۲���������;

option compress = yes validvarname = any;
libname sss "F:\���������ձ���\data";
libname repayFin "F:\����������Ԥ��\repayAnalysis";
libname submart "D:\mili\Datamart\data";

data a;
format dt  yymmdd10.;
dt = today() - 1;
call symput("dt", dt);
run;

*�����ſ�ͻ�;
data mili;
set sss.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
��������=sum(NEXT_REPAY_DATE,-LOAN_DATE);
if kindex(PRODUCT_NAME,"����");
if contract_no ^="PL148178693332002600000066";/*�����ɳ�񻪵�*/
if not kindex(contract_no,"PB");
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
od_days=sum(&cut_dt.,-REPAY_DATE);
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
od_days=sum(&cut_dt.,-REPAY_DATE);
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
if sum(REPAY_DATE,-cut_date)>=1 and sum(REPAY_DATE,-cut_date)<=3 then �����ǩ="T_3";
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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment;by ��������;run;

**���ϱ�ǩ;
data flag;
set submart.apply_flag;
rename apply_code = contract_no;
run;
data apply_submart;
set submart.apply_submart(keep = apply_code ������);
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


*����;
data kankan_total;
set repayFin.ct_payment_report;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707","201708");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(cut_date,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>=0 then ����=1;

if ��������=<0 and BILL_STATUS="0000" then ���ڻ���0=1;
else if ��������=1 and BILL_STATUS="0000" then ���ڻ���1=1;
else if ��������=2 and BILL_STATUS="0000" then ���ڻ���2=1;
else if ��������=3 and BILL_STATUS="0000" then ���ڻ���3=1;
else if ��������=4 and BILL_STATUS="0000" then ���ڻ���4=1;
else if ��������=5 and BILL_STATUS="0000" then ���ڻ���5=1;
else if ��������=6 and BILL_STATUS="0000" then ���ڻ���6=1;
else if ��������=7 and BILL_STATUS="0000" then ���ڻ���7=1;
else if ��������=8 and BILL_STATUS="0000" then ���ڻ���8=1;
else if ��������=9 and BILL_STATUS="0000" then ���ڻ���9=1;
else if ��������=10 and BILL_STATUS="0000" then ���ڻ���10=1;
else if ��������>10 and BILL_STATUS="0000" then ���ڻ���11=1;

if ��������>=0 and �˻���ǩ="����" and BILL_STATUS="0002" then ����δ����=1;

run;

proc sql;
create table kan_pay as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kankan_total group by �ſ��·� ;
quit;

**�¿ͻ�;
data kan_xz;
set kankan_total;
if �������� = "�¿ͻ�����";
run;
proc sql;
create table kan_pay_xz as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_xz group by �ſ��·� ;
quit;

**�����ͻ�;
data kan_fd;
set kankan_total;
if �������� = "�����ͻ�����";
run;
proc sql;
create table kan_pay_fd as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_fd group by �ſ��·� ;
quit;

***************************************
ϵͳͨ�����˹�ͨ�������ʱȽ� total;
*ϵͳ;
data kan_system;
set kankan_total;
if ������="ϵͳͨ��";
run;
proc sql;
create table kan_pay_system as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_system group by �ſ��·� ;
quit;

*�˹�;
data kan_review;
set kankan_total;
if ������="�˹�ͨ��";
run;
proc sql;
create table kan_pay_review as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_review group by �ſ��·� ;
quit;

*******�¿ͻ�;*******************************;
data kan_system_xz;
set kan_xz;
if ������="ϵͳͨ��";
run;
proc sql;
create table kan_pay_system_xz as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_system_xz group by �ſ��·� ;
quit;

*�˹�;
data kan_review_xz;
set kan_xz;
if ������="�˹�ͨ��";
run;
proc sql;
create table kan_pay_review_xz as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_review_xz group by �ſ��·� ;
quit;

*******�����ͻ�;****************************************;
data kan_system_fd;
set kan_fd;
if ������="ϵͳͨ��";
run;
proc sql;
create table kan_pay_system_fd as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_system_fd group by �ſ��·� ;
quit;

*�˹�;
data kan_review_fd;
set kan_fd;
if ������="�˹�ͨ��";
run;
proc sql;
create table kan_pay_review_fd as
select �ſ��·�,
sum(���ڻ���0) as ���ڻ���0,
sum(���ڻ���1) as ���ڻ���1, 
sum(���ڻ���2) as ���ڻ���2,
sum(���ڻ���3) as ���ڻ���3,
sum(���ڻ���4) as ���ڻ���4,
sum(���ڻ���5) as ���ڻ���5,
sum(���ڻ���6) as ���ڻ���6,
sum(���ڻ���7) as ���ڻ���7,
sum(���ڻ���8) as ���ڻ���8,
sum(���ڻ���9) as ���ڻ���9,
sum(���ڻ���10) as ���ڻ���10,
sum(���ڻ���11) as ���ڻ���11,
sum(����δ����) as ����δ����
from kan_review_fd group by �ſ��·� ;
quit;

********************************************;
*****************������������޵����;
data receive_amt;
set repayFin.ct_payment_report;
if �������� = "�����ͻ�����";
if OVERDUE_DAYS > 0;

if �������� = 7 then ��������7=1;
if �������� = 14 then ��������14=1;
if �������� = 21 then ��������21=1;
if �������� = 28 then ��������28=1;

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
select �ſ��·�,
sum(��������7) as ��������7,
sum(��������14) as ��������14,
sum(��������21) as ��������21,
sum(��������28) as ��������28
from receive_amt group by �ſ��·�;
run;

proc sql;
create table kan_amt_re as
select �ſ��·�,
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
from receive_amt group by �ſ��·�;
run;


*****************************************************************************************
�����ͻ�����;
proc sort data=repayFin.ct_payment_report;by ID_NUMBER �ͻ���ǩ;run;
data kan_feature;
set repayFin.ct_payment_report;
if �˻���ǩ="δ�ſ�" then delete;
format lag_����ʱ�� yymmdd10.;
lag_����ʱ��=lag(CLEAR_DATE);
�ͻ���ǩ_����=�ͻ���ǩ-1;
by ID_NUMBER �ͻ���ǩ;
if first.ID_NUMBER then lag_����ʱ��=clear_date;
run;
data kan_feature1;
set kan_feature;
if OVERDUE_DAYS > 0;

if lag_����ʱ��^=. then ���=loan_date-lag_����ʱ��;

if ���=0 then �����ǩ0=1;
if ���=1 then �����ǩ1=1;
if ���=2 then �����ǩ2=1;
if ���=3 then �����ǩ3=1;
if 4<=���<=5 then �����ǩ4_5=1;
if 6<=���<=10 then �����ǩ6_10=1;
if 11<=���<=30 then �����ǩ11_30=1;
if 31<=���<=60 then �����ǩ31_60=1;
if ���>60 then �����ǩ_61=1;

if �ͻ���ǩ_����=1 then ����1 =1;
if �ͻ���ǩ_����=2 then ����2 =1;
if �ͻ���ǩ_����=3 then ����3 =1;
if �ͻ���ǩ_����=4 then ����4 =1;
if �ͻ���ǩ_����=5 then ����5 =1;
if �ͻ���ǩ_����=6 then ����6 =1;
if �ͻ���ǩ_����=7 then ����7 =1;
if �ͻ���ǩ_����=8 then ����8 =1;
if �ͻ���ǩ_����=9 then ����9 =1;
if �ͻ���ǩ_����=10 then ����10 =1;
if �ͻ���ǩ_����>10 then ����11 =1;

run;


proc sql;
create table kan_space as
select  �ſ��·�,
sum(�����ǩ0) as a0,
sum(�����ǩ1) as a1,
sum(�����ǩ2) as a2,
sum(�����ǩ3) as a3,
sum(�����ǩ4_5) as a4_5,
sum(�����ǩ6_10) as a6_10,
sum(�����ǩ11_30) as a11_30,
sum(�����ǩ31_60) as a31_60,
sum(�����ǩ_61) as a61
from kan_feature1 group by �ſ��·�;
quit;

proc sort data=kan_feature1(where=(�ͻ���ǩ_����>0)) nodupkey out=kan_feature2;by contract_no ;run;

proc sql;
create table kan_fd_number as
select �ſ��·�,
sum(����1) as ����1,
sum(����2) as ����2,
sum(����3) as ����3,
sum(����4) as ����4,
sum(����5) as ����5,
sum(����6) as ����6,
sum(����7) as ����7,
sum(����8) as ����8,
sum(����9) as ����9,
sum(����10) as ����10,
sum(����11) as ����11
from kan_feature2 group by �ſ��·�;
quit;


*************�ڶ����֣��ϱ�������������Ͳ�ͨ����;

option compress = yes validvarname = any;
option missing = 0;
libname csdata odbc  datasrc=csdata_nf;
libname YY odbc  datasrc=res_nf;

libname submart "D:\mili\Datamart\data";
libname data "F:\�����绰����\����׼��\data";
libname DA "F:\�����绰����\csdata";
libname DB "F:\�����绰����\res_nf";
libname DD "F:\�����绰����";
libname repayFin "F:\����������Ԥ��\repayAnalysis";
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
format ��ϵ���� yymmdd10.;
��ϵ����=datepart(CREATE_TIME);
��ϵ�·�=put(��ϵ����,yymmn6.);
ͨ��ʱ��_��=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);

if CALL_ACTION_ID ="OUTBOUND" then ����=1;

/*if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("��ŵ����","�ܽӻ���","ΥԼ����","���ѻ���","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;*/

if CALL_ACTION_ID ="OUTBOUND" and RESULT="��ŵ����" then ��ŵ����=1;else ��ŵ����=0;
run;

***�鿴�������ռ��;
proc freq data=DD.Cs_table1_tab noprint;
table RESULT/out=cac;
run;

**;

**��������;
data milipayment_re;
set repayfin.milipayment_report(keep = CONTRACT_NO �ſ��·� OVERDUE_DAYS ID_NUMBER LOAN_DATE �˻���ǩ cut_date);
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if cut_date=&dt.;
run;

***����ÿ���ͻ����һ�ν��״̬;
proc sort data = milipayment_re nodupkey; by ID_NUMBER descending LOAN_DATE; run;
proc sort data = milipayment_re nodupkey; by ID_NUMBER;run;

data cs_table_table;
set DD.cs_table1_tab(keep = CONTRACT_NO CREATE_TIME DIAL_TELEPHONE_NO CONTACTS_NAME CUSTOMER_NAME ���� RESULT CALL_ACTION_ID);
if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("��ŵ����","�ܾ�����","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;
run;
proc sort data = cs_table_table ; by CONTRACT_NO;run;
proc sort data = milipayment_re nodupkey; by CONTRACT_NO;run;


data repay;
merge milipayment_re(in = a) cs_table_table(in = b);
by CONTRACT_NO;  
if a;
run;

proc sort data = repay out = repay1 nodupkey; by ID_NUMBER CREATE_TIME; run;

**����ձ�ǩ;

data repay12;
set repay1;
by ID_NUMBER CREATE_TIME;
retain �ڼ�����ϵ 1;
	 if first.ID_NUMBER then �ڼ�����ϵ = 1;
else �ڼ�����ϵ = �ڼ�����ϵ + 1;
if first.ID_NUMBER then �״���ϵ = 1;
if last.ID_NUMBER then ������ϵ = 1;
run;

******************;
**��һ��ÿ���ͻ�������Ĵ������������һ����ϵ;
proc sort data = repay12 out=contact; by ID_NUMBER descending �ڼ�����ϵ;run;
proc sort data = contact nodupkey; by ID_NUMBER;run;  **�ͻ�����ϵ���ٴ�;

data kan_call;
set contact;
if OVERDUE_DAYS<6;
if CALL_ACTION_ID ="" then ����0=1;
else if �ڼ�����ϵ=1 and ����=1 then ����1=1;
else if �ڼ�����ϵ=2 then ����2=1;
else if �ڼ�����ϵ=3 then ����3=1;
else if �ڼ�����ϵ=4 then ����4=1;
else if �ڼ�����ϵ=5 then ����5=1;
else if �ڼ�����ϵ=6 then ����6=1;
else if �ڼ�����ϵ=7 then ����7=1;
else if �ڼ�����ϵ=8 then ����8=1;
else if �ڼ�����ϵ=9 then ����9=1;
else if �ڼ�����ϵ=10 then ����10=1;
else if �ڼ�����ϵ>10 then ����11=1;
run;

proc sql;
create table kanpay_call as
select �ſ��·�,
sum(����0) as ����0,
sum(����1) as ����1, 
sum(����2) as ����2,
sum(����3) as ����3,
sum(����4) as ����4,
sum(����5) as ����5,
sum(����6) as ����6,
sum(����7) as ����7,
sum(����8) as ����8,
sum(����9) as ����9,
sum(����10) as ����10,
sum(����11) as ����11
from kan_call group by �ſ��·� ;
quit;


***************************************;
****�����ͬ������ָ�����Ĵ���;

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
if RESULT = "�պŴ��" then �պŴ��=1;
if RESULT = "ռ�߹ػ�" then ռ�߹ػ�=1;
if RESULT = "�ܾ�����" then �ܾ�����=1;
if RESULT = "��������" then ��������=1;
if RESULT = "�޷�ת��" then �޷�ת��=1;
if RESULT = "���˽���" then ���˽���=1;
if RESULT = "����/ת��" then ����ת��=1;

if RESULT = "��ŵ����" then ��ŵ����=1;
if RESULT = "���ѻ���" then ���ѻ���=1;
if RESULT = "ΥԼ����" then ΥԼ����=1;
if RESULT = "�ܽӹ���" then �ܽӹ���=1;
if RESULT = "��������" then ��������=1;
if RESULT = "Ƿ��ͣ��" then Ƿ��ͣ��=1;
if RESULT = "�޷���ͨ" then �޷���ͨ=1;


*if RESULT in("��ŵ����","���ѻ���","ΥԼ����","�ܽӹ���","��������","Ƿ��ͣ��","�޷���ͨ""����/����","��������","���ʧ��") then ����=1;
if RESULT in("��������""���ʧ��","����/����","���ѻ���","��������") then ����=1;

if RESULT ^= "" then ���ռ�¼=1;
if OVERDUE_DAYS <6;
run;

proc sql;
create table kan_total_5 as
select �ſ��·�,
sum(�պŴ��) as �պŴ��,
sum(ռ�߹ػ�) as ռ�߹ػ�,
sum(�ܾ�����) as �ܾ�����,
sum(��������) as ��������,
sum(�޷�ת��) as �޷�ת��, 
sum(���˽���) as ���˽���,
sum(����ת��) as ����ת��,

sum(��ŵ����) as ��ŵ����,
sum(ΥԼ����) as ΥԼ����,
sum(�ܽӹ���) as �ܽӹ���,
sum(Ƿ��ͣ��) as Ƿ��ͣ��,
sum(�޷���ͨ) as �޷���ͨ, 
 
sum(����) as ����, 
sum(���ռ�¼) as ���ռ�¼
from paypaypay2 group by �ſ��·� ;
quit;


****************************;
*��������>3��ÿ���ͻ��Ŀ���ϵ��;

**���Ͽ����Ͳ������ı�ǩ;
data connection;
set data.paypaypay;
format ��ϵ��ǩ $20.;
if RESULT in("��ŵ����","�ܽӻ���","�ܾ�����","����/ת��","��������","���ѻ���","ΥԼ����","�޷�ת��","��������","�ѻ���") then ��ϵ��ǩ="����";
if RESULT in("�պŴ��","���ʧ��","�ܽӹ���","��������","Ƿ��ͣ��","����/����","ռ�߹ػ�","���˽���","�޷���ͨ") then ��ϵ��ǩ="������";
if ��ϵ��ǩ="����" then ����=1;
run;

proc tabulate data =connection out=connection1;
class contract_no ;
var ����;
table contract_no all,���� all;
run;

data connection2;
set connection1;
������= ����_Sum/N ;
run;

**��������һ�β������;
proc sort data = connection out=connection12; by contract_no descending �ڼ�����ϵ;run;
proc sort data = connection12 nodupkey; by contract_no;run;  **�ͻ�����ϵ���ٴ�;

proc sort data = connection2 nodupkey; by contract_no;
data connection3;
merge connection2(in = a) connection12(in = b);
by contract_no;
if a;
run;

data connection4;
set connection3;
format ���������� $20.;
if ������=0 then ����������="1.(0)";
else if 0<������<0.2 then ����������="2.(0,20%)";
else if 0.2=<������<0.5 then ����������="3.[20%,50%)";
else if 0.5=<������<0.8 then ����������="4.[50%,80%)";
else if 0.8=<������=<1 then ����������="5.[80%,100%]";
if OVERDUE_DAYS <5;
run;

data connection5;
set connection4;
if ����������="1.(0)" then ������0 = 1;
if ����������="2.(0,20%)" then ������0_02 =1;
if ����������="3.[20%,50%)" then ������02_05 =1;
if ����������="4.[50%,80%)" then ������05_08 =1;
if ����������="5.[80%,100%]" then ������08_10 =1;
run;

proc sql;
create table kan_connection as
select �ſ��·�,
sum(������0) as ������0,
sum(������0_02) as ������0_02, 
sum(������02_05) as ������02_05,
sum(������05_08) as ������05_08,
sum(������08_10) as ������08_10
from connection5 group by �ſ��·� ;
quit;

*************************************************************;
**�����д��ռ�¼�ģ��۲���ղ�����ϵ�˵��������¼���ˣ�����+1��ϵ�˵�;

proc sort data = connection out = connection6 nodupkey;by contract_no DIAL_TELEPHONE_NO ;run;

proc sql;
create table connection7  as select contract_no,count(*) as ����,�ſ��·�,OVERDUE_DAYS  from connection6(where=(DIAL_TELEPHONE_NO^="")) group by contract_no,�ſ��·�;
quit;

data connection8;
set connection7;
if ����=1 then ��ϵ���� = 1;
if ����=2 then ��ϵ���˼�1=1;
if ����=3 then ��ϵ���˼�2=1;
if ����=4 then ��ϵ���˼�3=1;
if ����=5 then ��ϵ���˼�4=1;
if ����>5 then ��ϵ���˴���4=1;
if OVERDUE_DAYS <6;
run;

proc sql;
create table kan_con as
select �ſ��·�,
sum(��ϵ����) as ��ϵ����,
sum(��ϵ���˼�1) as ��ϵ���˼�1, 
sum(��ϵ���˼�2) as ��ϵ���˼�2,
sum(��ϵ���˼�3) as ��ϵ���˼�3,
sum(��ϵ���˼�4) as ��ϵ���˼�4,
sum(��ϵ���˴���4) as ��ϵ���˴���4
from connection8 group by �ſ��·� ;
quit;


***����>3δ���յ绰�����ǻؿ���;

data aaaaaa;
set connection3;
if CALL_ACTION_ID="";
if 0<OVERDUE_DAYS<10;
if �˻���ǩ = "�ѻ���";
run;


