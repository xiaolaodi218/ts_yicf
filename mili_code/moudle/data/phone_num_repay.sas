option compress = yes validvarname = any;

libname submart "D:\mili\Datamart\data";
libname ssst "F:\ͨ�ƽ���\Ⱦ�ڶ�_���ղ���\data";

data phone_number;
set submart.id_submart(keep = apply_code PHONE_NO);
��������1=PHONE_NO;
run;

data phone_num;
set phone_number;
�������� = substr(��������1,0,0)||"***"||substr(��������1,4,8);
drop ��������1;
run;


proc sort data = phone_num nodupkey;by PHONE_NO;run;

data phone_num;
set phone_num(keep = PHONE_NO ��������);
run;

filename export "F:\ͨ�ƽ���\Ⱦ�ڶ�_���ղ���\data\phone_number.csv" encoding='utf-8';
PROC EXPORT DATA= phone_num
			 outfile = export
			 dbms = csv replace;
RUN;





***��������;
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
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=repayFin.ct_payment;by ��������;run;

data repay_r;
set repayFin.ct_payment_report;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ������������=sum(cut_date,-REPAY_DATE);
else ������������=sum(CLEAR_DATE,-REPAY_DATE);
run;

**����û�;
data repay;
set repay_r;
/*length target_label $20.;*/
/****
bad:��ǰ����������15������
good:δ���ڻ������˵��ǲ�����3��ͽ����˵Ŀͻ�
indent��������3������15��һ���ѽ��塢��ǰ����������
****/
/*if ������������ > 15 then do; target_label = "��������15������"; target = 1;end;*/
/*else if bill_status = "0000" and ������������ <=3 then do;target_label = "��������������3��";target = 0;end;*/
/*else do;target_label = "����3-15��";target = 2;end;*/
if bill_status = "0000" and ������������ <=3 then y = 0;
if ������������ > 15 then y = 1;
run;

data repay;
set repay(drop =ACCOUNT_TYPE FUND_CHANNEL_CODE PRODUCT_NAME PERIOD CURR_RECEIVE_AMT CURR_RECEIVE_CAPITAL_AMT CURR_RECEIVE_INTEREST_AMT LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE �����ͻ� acc_interest ������� �����ǩ ������ ͳ�Ƹ��� ������ɸѡ loc_abmoduleflag ���Ա�ǩ);
rename CONTRACT_NO = apply_code;
if y ^=  "";
run;

proc sort data=repay nodupkey;by apply_code;run;

filename export "F:\moudle\prepare\data\repay.csv" encoding='utf-8';
PROC EXPORT DATA= repay
			 outfile = export
			 dbms = csv replace;
RUN;
