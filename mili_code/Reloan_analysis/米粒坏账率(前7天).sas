option compress = yes validvarname = any;
libname sss "F:\���������ձ���\data";
libname repayFin "F:\����������Ԥ��\repayAnalysis";
libname haha "F:\�����绰����\data";

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
if sum(REPAY_DATE,-cut_date)=1 then �����ǩ="1one";
else if od_days=2 then �����ǩ="2two";
else if od_days=3 then �����ǩ="3three";
else if od_days=4 then �����ǩ="4four";
else if od_days=5 then �����ǩ="5five";
else if od_days=6 then �����ǩ="6six";
else if od_days=7 then �����ǩ="6seven";
ͳ�Ƹ���=1;
�ſ��·�=put(LOAN_DATE,yymmn6.);
������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if �˻���ǩ="������" then ������=�������;
/*if contract_no="PL148224156660201400005011" then �����ǩ="T_3";*/
/*if �˻���ǩ in ("������","�ۿ�ʧ��") then �˻���ǩ2="Current";*/
if PRODUCT_NAME="����10" then ���Ա�ǩ="������";else ���Ա�ǩ="�����";
run;
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=haha.ct_payment_report;by ��������;run;


*����;
data kan;
set ct_payment_report;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(cut_date,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if ��������=1 and BILL_STATUS="0000" then ���ڴ߻�1=1;
else if ��������=2 and BILL_STATUS="0000" then ���ڴ߻�2=1;
else if ��������=3 and BILL_STATUS="0000" then ���ڴ߻�3=1;
else if ��������=4 and BILL_STATUS="0000" then ���ڴ߻�4=1;
else if ��������=5 and BILL_STATUS="0000" then ���ڴ߻�5=1;
else if ��������=6 and BILL_STATUS="0000" then ���ڴ߻�6=1;
else if ��������=7 and BILL_STATUS="0000" then ���ڴ߻�7=1;


if ��������>=1 then ����_a1=1;
if ��������>=2 then ����_a2=1;
if ��������>=3 then ����_a3=1;
if ��������>=4 then ����_a4=1;
if ��������>=5 then ����_a5=1;
if ��������>=6 then ����_a6=1;
if ��������>=7 then ����_a7=1;
run;
proc sql;
create table kan1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1)/sum(����) as a1�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(���ڴ߻�2)/sum(����) as a2�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�3)/sum(����) as a3�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(���ڴ߻�4)/sum(����) as a4�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�5)/sum(����) as a5�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(���ڴ߻�6)/sum(����) as a6�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�7)/sum(����) as a7�߻��� format=percent7.2 from kan group by �ſ��·�;
quit;
proc sql;
create table kan_all as
select a.*,b.a1�߻���,c.a2�߻���,d.a3�߻���,e.a4�߻���,f.a5�߻���,g.a6�߻���,
h.a7�߻��� from kan1 as a
left join kan2 as b on a.�ſ��·�=b.�ſ��·�
left join kan3 as c on a.�ſ��·�=c.�ſ��·�
left join kan4 as d on a.�ſ��·�=d.�ſ��·�
left join kan5 as e on a.�ſ��·�=e.�ſ��·�
left join kan6 as f on a.�ſ��·�=f.�ſ��·�
left join kan7 as g on a.�ſ��·�=g.�ſ��·�
left join kan8 as h on a.�ſ��·�=h.�ſ��·�;
quit;


*����;
data kan_xz;
set ct_payment_report;
if �ͻ���ǩ=1;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(&dt.,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if ��������=1 and BILL_STATUS="0000" then ���ڴ߻�1=1;
else if ��������=2 and BILL_STATUS="0000" then ���ڴ߻�2=1;
else if ��������=3 and BILL_STATUS="0000" then ���ڴ߻�3=1;
else if ��������=4 and BILL_STATUS="0000" then ���ڴ߻�4=1;
else if ��������=5 and BILL_STATUS="0000" then ���ڴ߻�5=1;
else if ��������=6 and BILL_STATUS="0000" then ���ڴ߻�6=1;
else if ��������=7 and BILL_STATUS="0000" then ���ڴ߻�7=1;

if ��������>=1 then ����_a1=1;
if ��������>=2 then ����_a2=1;
if ��������>=3 then ����_a3=1;
if ��������>=4 then ����_a4=1;
if ��������>=5 then ����_a5=1;
if ��������>=6 then ����_a6=1;
if ��������>=7 then ����_a7=1;
run;
proc sql;
create table kan1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan_xz group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1)/sum(����) as a1�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(���ڴ߻�2)/sum(����) as a2�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�3)/sum(����) as a3�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(���ڴ߻�4)/sum(����) as a4�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�5)/sum(����) as a5�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(���ڴ߻�6)/sum(����) as a6�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�7)/sum(����) as a7�߻��� format=percent7.2 from kan_xz group by �ſ��·�;
quit;
proc sql;
create table kan_all_xz as
select a.*,b.a1�߻���,c.a2�߻���,d.a3�߻���,e.a4�߻���,f.a5�߻���,g.a6�߻���,
h.a7�߻��� from kan1 as a
left join kan2 as b on a.�ſ��·�=b.�ſ��·�
left join kan3 as c on a.�ſ��·�=c.�ſ��·�
left join kan4 as d on a.�ſ��·�=d.�ſ��·�
left join kan5 as e on a.�ſ��·�=e.�ſ��·�
left join kan6 as f on a.�ſ��·�=f.�ſ��·�
left join kan7 as g on a.�ſ��·�=g.�ſ��·�
left join kan8 as h on a.�ſ��·�=h.�ſ��·�;
quit;



*����;
data kan_fd;
set ct_payment_report;
if �ͻ���ǩ>1;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(&dt.,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if ��������=1 and BILL_STATUS="0000" then ���ڴ߻�1=1;
else if ��������=2 and BILL_STATUS="0000" then ���ڴ߻�2=1;
else if ��������=3 and BILL_STATUS="0000" then ���ڴ߻�3=1;
else if ��������=4 and BILL_STATUS="0000" then ���ڴ߻�4=1;
else if ��������=5 and BILL_STATUS="0000" then ���ڴ߻�5=1;
else if ��������=6 and BILL_STATUS="0000" then ���ڴ߻�6=1;
else if ��������=7 and BILL_STATUS="0000" then ���ڴ߻�7=1;


if ��������>=1 then ����_a1=1;
if ��������>=2 then ����_a2=1;
if ��������>=3 then ����_a3=1;
if ��������>=4 then ����_a4=1;
if ��������>=5 then ����_a5=1;
if ��������>=6 then ����_a6=1;
if ��������>=7 then ����_a7=1;
run;
proc sql;
create table kan1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from kan_fd group by �ſ��·� ;
quit;
proc sql;
create table kan2 as
select �ſ��·�,sum(���ڴ߻�1)/sum(����) as a1�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan3 as
select �ſ��·�,sum(���ڴ߻�2)/sum(����) as a2�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan4 as
select �ſ��·�,sum(���ڴ߻�3)/sum(����) as a3�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan5 as
select �ſ��·�,sum(���ڴ߻�4)/sum(����) as a4�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan6 as
select �ſ��·�,sum(���ڴ߻�5)/sum(����) as a5�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan7 as
select �ſ��·�,sum(���ڴ߻�6)/sum(����) as a6�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan8 as
select �ſ��·�,sum(���ڴ߻�7)/sum(����) as a7�߻��� format=percent7.2 from kan_fd group by �ſ��·�;
quit;
proc sql;
create table kan_all_fd as
select a.*,b.a1�߻���,c.a2�߻���,d.a3�߻���,e.a4�߻���,f.a5�߻���,g.a6�߻���,
h.a7�߻��� from kan1 as a
left join kan2 as b on a.�ſ��·�=b.�ſ��·�
left join kan3 as c on a.�ſ��·�=c.�ſ��·�
left join kan4 as d on a.�ſ��·�=d.�ſ��·�
left join kan5 as e on a.�ſ��·�=e.�ſ��·�
left join kan6 as f on a.�ſ��·�=f.�ſ��·�
left join kan7 as g on a.�ſ��·�=g.�ſ��·�
left join kan8 as h on a.�ſ��·�=h.�ſ��·�;
quit;



*���徫ȷ������;
data kan_num_all;
set haha.ct_payment_report;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(cut_date,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if ��������=1 and BILL_STATUS="0000" then ���ڴ߻�1=1;
else if ��������=2 and BILL_STATUS="0000" then ���ڴ߻�2=1;
else if ��������=3 and BILL_STATUS="0000" then ���ڴ߻�3=1;
else if ��������=4 and BILL_STATUS="0000" then ���ڴ߻�4=1;
else if ��������=5 and BILL_STATUS="0000" then ���ڴ߻�5=1;
else if ��������=6 and BILL_STATUS="0000" then ���ڴ߻�6=1;
else if ��������=7 and BILL_STATUS="0000" then ���ڴ߻�7=1;


if ��������>=1 then ����_a1=1;
if ��������>=2 then ����_a2=1;
if ��������>=3 then ����_a3=1;
if ��������>=4 then ����_a4=1;
if ��������>=5 then ����_a5=1;
if ��������>=6 then ����_a6=1;
if ��������>=7 then ����_a7=1;
run;
proc sql;
create table kan_sum1 as
select �ſ��·�,sum(����) as ��Ȼ���ڸ���,sum(���ڴ߻�1) as a1�߻ظ���,sum(���ڴ߻�2) as a2�߻ظ���,sum(���ڴ߻�3) as a3�߻ظ���, sum(���ڴ߻�4) as a4�߻ظ���,
sum(���ڴ߻�5) as a5�߻���,sum(���ڴ߻�6) as a6�߻ظ��� ,sum(���ڴ߻�7) as a7�߻ظ���  from kan_num_all group by �ſ��·� ;
quit;
