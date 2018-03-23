option compress = yes validvarname = any;
libname sss "F:\���������ձ���\data";
libname repayFin "F:\����������Ԥ��\repayAnalysis";

data a;
format dt  yymmdd10.;
dt = today() - 3;
call symput("dt", dt);
run;

*�����ſ�ͻ�;
data mili;
set sss.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
��������=sum(NEXT_REPAY_DATE,-LOAN_DATE);
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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by ��������;run;


*����;
data kan;
set ct_payment_report;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(cut_date,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if 1<=��������<=3 and BILL_STATUS="0000" then ���ڴ߻�1_3=1;
else if 4<=��������<=10 and BILL_STATUS="0000" then ���ڴ߻�4_10=1;
else if 11<=��������<=15 and BILL_STATUS="0000" then ���ڴ߻�11_15=1;
else if 16<=��������<=30 and BILL_STATUS="0000" then ���ڴ߻�16_30=1;
else if 31<=��������<=60 and BILL_STATUS="0000" then ���ڴ߻�31_60=1;
else if 61<=��������<=90 and BILL_STATUS="0000" then ���ڴ߻�61_90=1;
else if ��������>90 and BILL_STATUS="0000" then ���ڴ߻�90=1;


if ��������>3 then ����_a3=1;
if ��������>10 then ����_a10=1;
if ��������>15 then ����_a15=1;
if ��������>30 then ����_a30=1;
if ��������>60 then ����_a60=1;
if ��������>90 then ����_a90=1;
run;
proc sql;
create table kan1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(����_a10)/count(*) as a10������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(����_a15)/count(*) as a15������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan9 as
select �ſ��·�,sum(����_a30)/count(*) as a30������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan10 as
select �ſ��·�,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan11 as
select �ſ��·�,sum(����_a60)/count(*) as a60������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan12 as
select �ſ��·�,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan13 as
select �ſ��·�,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan14 as
select �ſ��·�,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻��� from kan1 as a
left join kan2 as b on a.�ſ��·�=b.�ſ��·�
left join kan3 as c on a.�ſ��·�=c.�ſ��·�
left join kan4 as d on a.�ſ��·�=d.�ſ��·�
left join kan5 as e on a.�ſ��·�=e.�ſ��·�
left join kan6 as f on a.�ſ��·�=f.�ſ��·�
left join kan7 as g on a.�ſ��·�=g.�ſ��·�
left join kan8 as h on a.�ſ��·�=h.�ſ��·�
left join kan9 as i on a.�ſ��·�=i.�ſ��·�
left join kan10 as j on a.�ſ��·�=j.�ſ��·�
left join kan11 as k on a.�ſ��·�=k.�ſ��·�
left join kan12 as l on a.�ſ��·�=l.�ſ��·�
left join kan13 as m on a.�ſ��·�=m.�ſ��·�
left join kan14 as n on a.�ſ��·�=n.�ſ��·�;
quit;

x "F:\����������Ԥ��\���˱���(����).xlsx";
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c1:r9c3';
data _null_;
set Work.Kan_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c5:r9c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c7:r9c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c9:r9c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c11:r9c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c13:r9c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r3c15:r9c15';
data _null_;
set Work.Kan_all;
file DD;
put �ܴ߻���;
run;


*����;
data kan;
set ct_payment_report;
if �ͻ���ǩ=1;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(&dt.,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if 1<=��������<=3 and BILL_STATUS="0000" then ���ڴ߻�1_3=1;
else if 4<=��������<=10 and BILL_STATUS="0000" then ���ڴ߻�4_10=1;
else if 11<=��������<=15 and BILL_STATUS="0000" then ���ڴ߻�11_15=1;
else if 16<=��������<=30 and BILL_STATUS="0000" then ���ڴ߻�16_30=1;
else if 31<=��������<=60 and BILL_STATUS="0000" then ���ڴ߻�31_60=1;
else if 61<=��������<=90 and BILL_STATUS="0000" then ���ڴ߻�61_90=1;
else if ��������>90 and BILL_STATUS="0000" then ���ڴ߻�90=1;


if ��������>3 then ����_a3=1;
if ��������>10 then ����_a10=1;
if ��������>15 then ����_a15=1;
if ��������>30 then ����_a30=1;
if ��������>60 then ����_a60=1;
if ��������>90 then ����_a90=1;
run;
proc sql;
create table kan1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(����_a10)/count(*) as a10������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(����_a15)/count(*) as a15������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan9 as
select �ſ��·�,sum(����_a30)/count(*) as a30������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan10 as
select �ſ��·�,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan11 as
select �ſ��·�,sum(����_a60)/count(*) as a60������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan12 as
select �ſ��·�,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan13 as
select �ſ��·�,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan14 as
select �ſ��·�,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻��� from kan1 as a
left join kan2 as b on a.�ſ��·�=b.�ſ��·�
left join kan3 as c on a.�ſ��·�=c.�ſ��·�
left join kan4 as d on a.�ſ��·�=d.�ſ��·�
left join kan5 as e on a.�ſ��·�=e.�ſ��·�
left join kan6 as f on a.�ſ��·�=f.�ſ��·�
left join kan7 as g on a.�ſ��·�=g.�ſ��·�
left join kan8 as h on a.�ſ��·�=h.�ſ��·�
left join kan9 as i on a.�ſ��·�=i.�ſ��·�
left join kan10 as j on a.�ſ��·�=j.�ſ��·�
left join kan11 as k on a.�ſ��·�=k.�ſ��·�
left join kan12 as l on a.�ſ��·�=l.�ſ��·�
left join kan13 as m on a.�ſ��·�=m.�ſ��·�
left join kan14 as n on a.�ſ��·�=n.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c1:r29c3';
data _null_;
set Work.Kan_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c5:r29c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c7:r29c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c9:r29c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c11:r29c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c13:r29c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r23c15:r29c15';
data _null_;
set Work.Kan_all;
file DD;
put �ܴ߻���;
run;

*����;
data kan;
set ct_payment_report;
if �ͻ���ǩ>1;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(&dt.,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if 1<=��������<=3 and BILL_STATUS="0000" then ���ڴ߻�1_3=1;
else if 4<=��������<=10 and BILL_STATUS="0000" then ���ڴ߻�4_10=1;
else if 11<=��������<=15 and BILL_STATUS="0000" then ���ڴ߻�11_15=1;
else if 16<=��������<=30 and BILL_STATUS="0000" then ���ڴ߻�16_30=1;
else if 31<=��������<=60 and BILL_STATUS="0000" then ���ڴ߻�31_60=1;
else if 61<=��������<=90 and BILL_STATUS="0000" then ���ڴ߻�61_90=1;
else if ��������>90 and BILL_STATUS="0000" then ���ڴ߻�90=1;


if ��������>3 then ����_a3=1;
if ��������>10 then ����_a10=1;
if ��������>15 then ����_a15=1;
if ��������>30 then ����_a30=1;
if ��������>60 then ����_a60=1;
if ��������>90 then ����_a90=1;
run;
proc sql;
create table kan1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(����_a10)/count(*) as a10������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(����_a15)/count(*) as a15������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan9 as
select �ſ��·�,sum(����_a30)/count(*) as a30������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan10 as
select �ſ��·�,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan11 as
select �ſ��·�,sum(����_a60)/count(*) as a60������������ format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan12 as
select �ſ��·�,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan13 as
select �ſ��·�,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan14 as
select �ſ��·�,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻��� from kan1 as a
left join kan2 as b on a.�ſ��·�=b.�ſ��·�
left join kan3 as c on a.�ſ��·�=c.�ſ��·�
left join kan4 as d on a.�ſ��·�=d.�ſ��·�
left join kan5 as e on a.�ſ��·�=e.�ſ��·�
left join kan6 as f on a.�ſ��·�=f.�ſ��·�
left join kan7 as g on a.�ſ��·�=g.�ſ��·�
left join kan8 as h on a.�ſ��·�=h.�ſ��·�
left join kan9 as i on a.�ſ��·�=i.�ſ��·�
left join kan10 as j on a.�ſ��·�=j.�ſ��·�
left join kan11 as k on a.�ſ��·�=k.�ſ��·�
left join kan12 as l on a.�ſ��·�=l.�ſ��·�
left join kan13 as m on a.�ſ��·�=m.�ſ��·�
left join kan14 as n on a.�ſ��·�=n.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c1:r49c3';
data _null_;
set Work.Kan_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c5:r49c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c7:r49c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c9:r49c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c11:r49c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c13:r49c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]������2!r43c15:r49c15';
data _null_;
set Work.Kan_all;
file DD;
put �ܴ߻���;
run;

/**/
/*data  ckan;*/
/*set kan;*/
/*if �ſ��·�=201701;*/
/*if ���ڴ߻�1_3=1;*/
/*run;*/
/*data  ckan1;*/
/*set kan;*/
/*if �ſ��·�=201701;*/
/*if ���ڴ߻�1_3^=1 and ����=1;*/
/*run;*/
/*data  ckan2;*/
/*set kan;*/
/*if �ſ��·�=201612;*/
/*run;*/
/*data ckan3;*/
/*set kan;*/
/*if �ſ��·�=201612;*/
/*if ����_a3=1;*/
/*run;*/
