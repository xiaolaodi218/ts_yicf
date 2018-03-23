option compress = yes validvarname = any;
libname sss "F:\���������ձ���\data";
libname repayFin "F:\����������Ԥ��\repayAnalysis";
libname submart "D:\mili\Datamart\data";

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
proc sort data=flag nodupkey;by contract_no;run;
proc sort data=ct_payment nodupkey;by contract_no;run;

data repayFin.ct_payment_report;
merge ct_payment(in = a) flag(in = b);
by contract_no;
if a;
run;
proc sort data = repayFin.ct_payment_report nodupkey; by contract_no; run;


*����;
data kan;
set repayFin.ct_payment_report;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707","201708","201709");
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

if 4<=��������<=30 and BILL_STATUS="0000" then ���ڴ߻�4_30=1;


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
create table kan15 as
select �ſ��·�,sum(���ڴ߻�90)/count(*) as a90�����ϻ����� format=percent7.2 from kan group by �ſ��·�;
quit;


proc sql;
create table kan_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,h.a16_30�߻���,
i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻���,o.a90�����ϻ����� from kan1 as a
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
left join kan14 as n on a.�ſ��·�=n.�ſ��·�
left join kan15 as o on a.�ſ��·�=o.�ſ��·�;
quit;

x "F:\����������Ԥ��\���˱���(����).xlsx";
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c1:r12c3';
data _null_;
set Work.Kan_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c5:r12c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c7:r12c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c9:r12c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c11:r12c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c13:r12c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r3c15:r12c16';
data _null_;
set Work.Kan_all;
file DD;
put �ܴ߻��� a90�����ϻ�����;
run;


*����;
data kan;
set repayFin.ct_payment_report;
if �ͻ���ǩ=1;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707","201708","201708","201709");
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
create table kan15 as
select �ſ��·�,sum(���ڴ߻�90)/count(*) as a90�����ϻ����� format=percent7.2 from kan group by �ſ��·�;
quit;

proc sql;
create table kan_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,h.a16_30�߻���,
i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻���,o.a90�����ϻ����� from kan1 as a
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
left join kan14 as n on a.�ſ��·�=n.�ſ��·�
left join kan15 as o on a.�ſ��·�=o.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c1:r32c3';
data _null_;
set Work.Kan_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c5:r32c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c7:r32c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c9:r32c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c11:r32c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c13:r32c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r23c15:r32c16';
data _null_;
set Work.Kan_all;
file DD;
put �ܴ߻��� a90�����ϻ�����;
run;


*����;
data kan;
set repayFin.ct_payment_report;
if �ͻ���ǩ>1;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707","201708","201709");
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
create table kan15 as
select �ſ��·�,sum(���ڴ߻�90)/count(*) as a90�����ϻ����� format=percent7.2 from kan group by �ſ��·�;
quit;

proc sql;
create table kan_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,h.a16_30�߻���,
i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻���,o.a90�����ϻ����� from kan1 as a
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
left join kan14 as n on a.�ſ��·�=n.�ſ��·�
left join kan15 as o on a.�ſ��·�=o.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c1:r52c3';
data _null_;
set Work.Kan_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c5:r52c5';
data _null_;
set Work.Kan_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c7:r52c7';
data _null_;
set Work.Kan_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c9:r52c9';
data _null_;
set Work.Kan_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c11:r52c11';
data _null_;
set Work.Kan_all;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c13:r52c13';
data _null_;
set Work.Kan_all;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r43c15:r52c16';
data _null_;
set Work.Kan_all;
file DD;
put �ܴ߻��� a90�����ϻ�����;
run;


*�ھ�;
data kan_A;
set repayFin.ct_payment_report;
if loc_abmoduleflag="A";
if �ſ��·� in ("201706","201707","201708","201709");
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
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan_A group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(����_a10)/count(*) as a10������������ format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(����_a15)/count(*) as a15������������ format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan9 as
select �ſ��·�,sum(����_a30)/count(*) as a30������������ format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan10 as
select �ſ��·�,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan11 as
select �ſ��·�,sum(����_a60)/count(*) as a60������������ format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan12 as
select �ſ��·�,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan13 as
select �ſ��·�,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan14 as
select �ſ��·�,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from kan_A group by �ſ��·�;
quit;
proc sql;
create table kan15 as
select �ſ��·�,sum(���ڴ߻�90)/count(*) as a90�����ϻ����� format=percent7.2 from kan group by �ſ��·�;
quit;

proc sql;
create table kan_all_A as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,h.a16_30�߻���,
i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻���,o.a90�����ϻ����� from kan1 as a
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
left join kan14 as n on a.�ſ��·�=n.�ſ��·�
left join kan15 as o on a.�ſ��·�=o.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c1:r78c3';
data _null_;
set Work.kan_all_A;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c5:r78c5';
data _null_;
set Work.kan_all_A;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c7:r78c7';
data _null_;
set Work.kan_all_A;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c9:r78c9';
data _null_;
set Work.kan_all_A;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c11:r78c11';
data _null_;
set Work.kan_all_A;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c13:r78c13';
data _null_;
set Work.kan_all_A;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r63c15:r78c16';
data _null_;
set Work.kan_all_A;
file DD;
put �ܴ߻��� a90�����ϻ�����;
run;

*��ս��;
data kan_B;
set repayFin.ct_payment_report;
if loc_abmoduleflag="B";
if �ſ��·� in ("201706","201707","201708","201709");
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
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan_B group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(����_a10)/count(*) as a10������������ format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(����_a15)/count(*) as a15������������ format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan9 as
select �ſ��·�,sum(����_a30)/count(*) as a30������������ format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan10 as
select �ſ��·�,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan11 as
select �ſ��·�,sum(����_a60)/count(*) as a60������������ format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan12 as
select �ſ��·�,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan13 as
select �ſ��·�,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from kan_B group by �ſ��·�;
quit;
proc sql;
create table kan14 as
select �ſ��·�,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from kan_B group by �ſ��·�;
quit;

proc sql;
create table kan15 as
select �ſ��·�,sum(���ڴ߻�90)/count(*) as a90�����ϻ����� format=percent7.2 from kan group by �ſ��·�;
quit;

proc sql;
create table kan_all_B as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,h.a16_30�߻���,
i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻���,o.a90�����ϻ����� from kan1 as a
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
left join kan14 as n on a.�ſ��·�=n.�ſ��·�
left join kan15 as o on a.�ſ��·�=o.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c1:r98c3';
data _null_;
set Work.kan_all_B;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c5:r98c5';
data _null_;
set Work.kan_all_B;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c7:r98c7';
data _null_;
set Work.kan_all_B;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c9:r98c9';
data _null_;
set Work.kan_all_B;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c11:r98c11';
data _null_;
set Work.kan_all_B;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c13:r98c13';
data _null_;
set Work.kan_all_B;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���!r83c15:r98c16';
data _null_;
set Work.kan_all_B;
file DD;
put �ܴ߻��� a90�����ϻ�����;
run;


*************************************************************************;
***������Ϊά��(�¿ͻ�);
data kan_source;
set repayFin.ct_payment_report;
if �������� = "�¿ͻ�����";
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
select ��Դ����,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan2 as
select ��Դ����,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan3 as
select ��Դ����,sum(����_a3)/count(*) as a3������������ format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan4 as
select ��Դ����,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan5 as
select ��Դ����,sum(����_a10)/count(*) as a10������������ format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan6 as
select ��Դ����,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan7 as
select ��Դ����,sum(����_a15)/count(*) as a15������������ format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan8 as
select ��Դ����,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan9 as
select ��Դ����,sum(����_a30)/count(*) as a30������������ format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan10 as
select ��Դ����,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan11 as
select ��Դ����,sum(����_a60)/count(*) as a60������������ format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan12 as
select ��Դ����,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan13 as
select ��Դ����,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan14 as
select ��Դ����,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from kan_source group by ��Դ����;
quit;
proc sql;
create table kan_sc as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻��� from kan1 as a
left join kan2 as b on a.��Դ����=b.��Դ����
left join kan3 as c on a.��Դ����=c.��Դ����
left join kan4 as d on a.��Դ����=d.��Դ����
left join kan5 as e on a.��Դ����=e.��Դ����
left join kan6 as f on a.��Դ����=f.��Դ����
left join kan7 as g on a.��Դ����=g.��Դ����
left join kan8 as h on a.��Դ����=h.��Դ����
left join kan9 as i on a.��Դ����=i.��Դ����
left join kan10 as j on a.��Դ����=j.��Դ����
left join kan11 as k on a.��Դ����=k.��Դ����
left join kan12 as l on a.��Դ����=l.��Դ����
left join kan13 as m on a.��Դ����=m.��Դ����
left join kan14 as n on a.��Դ����=n.��Դ����;
quit;

proc sort data=kan_sc;by ��Դ���� ;run;

**ͳ�ƻ������;
proc freq data=kan_source noprint;
table ��Դ����/out=cac;
run;
proc sort data=cac;by ��Դ����;run;

data kan_source_channel;
merge kan_sc(in=a) cac(in=b);
by ��Դ����;
if a;
run;
proc sort data=kan_source_channel;by descending COUNT;run;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c1:r110c3';
data _null_;
set Work.kan_source_channel;
file DD;
put ��Դ���� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c5:r110c5';
data _null_;
set Work.kan_source_channel;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c7:r110c7';
data _null_;
set Work.kan_source_channel;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c9:r110c9';
data _null_;
set Work.kan_source_channel;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c11:r110c11';
data _null_;
set Work.kan_source_channel;
file DD;
put a31_60�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c13:r110c13';
data _null_;
set Work.kan_source_channel;
file DD;
put a61_90�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]�¿ͻ������ֲ�!r3c15:r110c16';
data _null_;
set Work.kan_source_channel;
file DD;
put �ܴ߻��� COUNT;
run;


*************************************************************************************************
***������Ϊά�ȵķſ��·ݷֲ�;
data kan_every_month;
set repayFin.ct_payment_report;
if �������� = "�¿ͻ�����";
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707","201708","201709");
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

***��һ�����ڷſ��µĺ����������ʹ��;
proc sort data=kan_every_month(keep= �ſ��·� loan_date cut_date where=(cut_date=&dt.))  out=month_list nodupkey;by �ſ��·� ;run;
proc sort data=month_list;by loan_date;run;
data _null_;
set month_list end=last;     
call symput ("month_"||compress(_n_),compress(�ſ��·�));        
if last then call symput("lcn",compress(_n_));
run;


%macro demo_0(use_database);

%do k=1 %to &lcn.;

data use_kfc;
set &use_database.;
**��kan_every_month���������·�;
if �ſ��·�=&&month_&k;
run;

proc sql;
create table kan1_&&month_&k as
select ��Դ����,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan2_&&month_&k as
select ��Դ����,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan3_&&month_&k as
select ��Դ����,sum(����_a3)/count(*) as a3������������ format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan4_&&month_&k as
select ��Դ����,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan5_&&month_&k as
select ��Դ����,sum(����_a10)/count(*) as a10������������ format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan6_&&month_&k as
select ��Դ����,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan7_&&month_&k as
select ��Դ����,sum(����_a15)/count(*) as a15������������ format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan8_&&month_&k as
select ��Դ����,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan9_&&month_&k as
select ��Դ����,sum(����_a30)/count(*) as a30������������ format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan10_&&month_&k as
select ��Դ����,sum(���ڴ߻�31_60)/sum(����_a30) as a31_60�߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan11_&&month_&k as
select ��Դ����,sum(����_a60)/count(*) as a60������������ format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan12_&&month_&k as
select ��Դ����,sum(���ڴ߻�61_90)/sum(����_a60) as a61_90�߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan13_&&month_&k as
select ��Դ����,sum(����_a90)/count(*) as �ܻ����� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan14_&&month_&k as
select ��Դ����,sum(�߻�)/sum(����) as �ܴ߻��� format=percent7.2 from use_kfc group by ��Դ����;
quit;
proc sql;
create table kan_sc_&&month_&k as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,j.a31_60�߻���,k.a60������������,l.a61_90�߻���,m.�ܻ�����,n.�ܴ߻��� from kan1_&&month_&k as a
left join kan2_&&month_&k as b on a.��Դ����=b.��Դ����
left join kan3_&&month_&k as c on a.��Դ����=c.��Դ����
left join kan4_&&month_&k as d on a.��Դ����=d.��Դ����
left join kan5_&&month_&k as e on a.��Դ����=e.��Դ����
left join kan6_&&month_&k as f on a.��Դ����=f.��Դ����
left join kan7_&&month_&k as g on a.��Դ����=g.��Դ����
left join kan8_&&month_&k as h on a.��Դ����=h.��Դ����
left join kan9_&&month_&k as i on a.��Դ����=i.��Դ����
left join kan10_&&month_&k as j on a.��Դ����=j.��Դ����
left join kan11_&&month_&k as k on a.��Դ����=k.��Դ����
left join kan12_&&month_&k as l on a.��Դ����=l.��Դ����
left join kan13_&&month_&k as m on a.��Դ����=m.��Դ����
left join kan14_&&month_&k as n on a.��Դ����=n.��Դ����;
quit;

proc sort data=kan_sc_&&month_&k;by ��Դ���� ;run;

**ͳ�ƻ������;
proc freq data=use_kfc noprint;
table ��Դ����/out=cac_&&month_&k;
run;
proc sort data=cac_&&month_&k;by ��Դ����;run;

data kan_source_channel_&&month_&k;
merge kan_sc_&&month_&k(in=a) cac_&&month_&k(in=b);
by ��Դ����;
if a;
run;
proc sort data=kan_source_channel_&&month_&k;by descending COUNT;run;

**������;
filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c1:r40c3";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put ��Դ���� ��Ȼ������ a1_3�߻���;
run;

filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c5:r40c5";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put a4_10�߻���;
run;

filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c7:r40c7";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put a11_15�߻���;
run;

filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c9:r40c9";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put a16_30�߻���;
run;

filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c11:r40c11";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put a31_60�߻���;
run;

filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c13:r40c13";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put a61_90�߻���;
run;

filename DD DDE "EXCEL|[���˱���(����).xlsx]&&month_&k!r4c15:r40c16";
data _null_;
set Work.kan_source_channel_&&month_&k;
file DD;
put �ܴ߻��� COUNT;
run;

%end;
%mend;

%demo_0(use_database=kan_every_month);
