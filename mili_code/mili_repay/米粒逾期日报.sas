libname account odbc datasrc=account_nf;
option compress = yes validvarname = any;
libname repayFin "F:\���������ձ���\data";

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

/*������ܳ���ĩ�ı���,ʹ��ȫ�ֱ���*/
/*%let dt=mdy(7,2,2017);*/

***�����ſ�ͻ�;
data mili;
set repayFin.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
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
***�����ſ�ͻ��ĺ�ͬ���+��Ϣ;
proc sql;
create table mili_repay_plan as
select a.*,b.CURR_RECEIVE_CAPITAL_AMT,b.CURR_RECEIVE_INTEREST_AMT from mili1 as a
left join repayFin.repay_plan as b on a.contract_no=b.contract_no;
quit;
***�����ͻ���bill_main��;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join repayFin.bill_main as b on a.contract_no=b.contract_no;
quit;
proc sort data=mili_bill_main ;by repay_date;run;
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

if PRODUCT_NAME="����10" then ���Ա�ǩ="������";else ���Ա�ǩ="�����";
run;
proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by ��������;run;


*************************************************************************************************************;
***������������ת����;

data month1day;
set repayFin.Milipayment_report(keep=contract_no  od_days cut_date ������� �˻���ǩ �ͻ���ǩ ���Ա�ǩ PRODUCT_NAME)	;
if �˻���ǩ="�ۿ�ʧ��" then ����_���տۿ�ʧ�ܺ�ͬ=1;
run;
proc sort data=month1day ;by CONTRACT_no cut_date;run;
data  cc;
set month1day;
format �ڳ���ǩ ��ĩ��ǩ ��ת��ǩ $30.;
if �ͻ���ǩ=1 then do;
if ���Ա�ǩ="������" then ��ת��ǩ="������";
else if ���Ա�ǩ="�����" then ��ת��ǩ="�����";end;
else ��ת��ǩ="�����ͻ�";

last_oddays=lag(od_days);
last_�������=lag(�������);
last_����_���տۿ�ʧ�ܺ�ͬ=lag(����_���տۿ�ʧ�ܺ�ͬ);
by CONTRACT_no cut_date;
if first.contract_no then do ;last_oddays=od_days;last_�������=�������;last_����_���տۿ�ʧ�ܺ�ͬ=����_���տۿ�ʧ�ܺ�ͬ;end;
if cut_date=&dt.;
/*if cut_date=mdy(10,14,2016);*/
if 1<=last_oddays<=2 or (last_oddays=0 and last_����_���տۿ�ʧ�ܺ�ͬ=1)then �ڳ���ǩ="01:1-3";
else if 3<=last_oddays<=14 then �ڳ���ǩ="02:4-15";
else if 15<=last_oddays<=29 then �ڳ���ǩ="03:16-30";
else if 30<=last_oddays<=59 then �ڳ���ǩ="04:31-60";
else if 60<=last_oddays<=89 then �ڳ���ǩ="05:61-90";


if 1<=od_days<=2 or (od_days in (0,.) and ����_���տۿ�ʧ�ܺ�ͬ=1)then ��ĩ��ǩ="01:1-3";
else if 3<=od_days<=14 then ��ĩ��ǩ="02:4-15";
else if 15<=od_days<=29 then ��ĩ��ǩ="03:16-30";
else if 30<=od_days<=59 then ��ĩ��ǩ="04:31-60";
else if 60<=od_days<=89 then ��ĩ��ǩ="05:61-90";

*����;
if ((od_days=0 and ����_���տۿ�ʧ�ܺ�ͬ=1) or 
((od_days=3 or od_days=15  or od_days=30 or od_days=60 ) and last_oddays<od_days))
then  ����=1;else ����=0;

*��ת����;
if ((1<=last_oddays<=2 or (last_oddays=0 and last_����_���տۿ�ʧ�ܺ�ͬ=1)) and od_days<1) or 
   (3<=last_oddays<=14 and od_days<3) or 
   (15<=last_oddays<=29 and od_days<15)  or
   (30<=last_oddays<=59 and od_days<30) or
   (60<=last_oddays<=89 and od_days<60)  then ��ת����=1;else ��ת����=0;
*������;
if ((1<=last_oddays<=2 or (last_oddays=0 and last_����_���տۿ�ʧ�ܺ�ͬ=1)) and od_days>2) or 
   (3<=last_oddays<=14 and od_days>14) or
   (15<=last_oddays<=29 and od_days>29)  or
   (30<=last_oddays<=59 and od_days>59) or
   (60<=last_oddays<=89 and od_days>89) then ������=1;else ������=0;
*�߻�;
   if od_days=0 and (last_oddays>0 or last_����_���տۿ�ʧ�ܺ�ͬ=1)  then �߻�=1;else �߻�=0;
run;
*�����������ȡ��ʱ��ɸѡ���������������ĩ��ǩ=""������180�����ϵ�;
proc sql;
create table cc1(where=(��ĩ��ǩ^="")) as
select ��ĩ��ǩ,sum(����) as ���� ,count(*) as ��ĩ,sum(�������) as �������  from cc (where=(od_days>0 or (od_days=0 and ����_���տۿ�ʧ�ܺ�ͬ=1))) group by ��ĩ��ǩ;
quit;
*�����������ȡ��ʱ��ɸѡ��������������ڳ���ǩ=""������180�����ϵ�;
proc sql;
create table cc1_1(where=(�ڳ���ǩ^="")) as
select �ڳ���ǩ,sum(��ת����) as ��ת����,sum(������) as ������,count(*) as �ڳ�  from cc (where=(last_oddays>0 or (last_oddays=0 and last_����_���տۿ�ʧ�ܺ�ͬ=1))) group by �ڳ���ǩ;
quit;
*�ڳ���ǩ=""����ǰ�����ڣ�����߻ص�;
proc sql;
create table cc1_2(where=(�ڳ���ǩ^="")) as
select �ڳ���ǩ,sum(�߻�) as �߻�   from cc  group by �ڳ���ǩ;
quit;
proc sql;
create table cc2 as
select a.*,b.*,c.�߻� from cc1 as a
left join cc1_1 as b on a.��ĩ��ǩ=b.�ڳ���ǩ
left join cc1_2 as c on a.��ĩ��ǩ=c.�ڳ���ǩ;
quit;
data st1 st2;
set cc2;
if ��ĩ��ǩ in ("01:1-3","02:4-15","03:16-30") then output st1;
else output st2;
run;
x  "F:\���������ձ���\������������ת����.xlsx"; 
filename DD DDE 'EXCEL|[������������ת����.xlsx]Sheet1!r4c5:r6c9';
data _null_;set st1;file DD;put �ڳ� ����  ��ת���� ������ �߻�;run;
filename DD DDE 'EXCEL|[������������ת����.xlsx]Sheet1!r4c11:r6c12';
data _null_;set st1;file DD;put ��ĩ �������;run;

filename DD DDE 'EXCEL|[������������ת����.xlsx]Sheet1!r8c5:r9c9';
data _null_;set st2;file DD;put �ڳ� ����  ��ת���� ������ �߻�;run;
filename DD DDE 'EXCEL|[������������ת����.xlsx]Sheet1!r8c11:r9c12';
data _null_;set st2;file DD;put ��ĩ �������;run;
proc sql;
create table aall as
select count(CONTRACT_NO) as δ�������,sum(�������) as δ���������� from cc(where=(�˻���ǩ in ("�ۿ�ʧ��","����")));
quit;
filename DD DDE 'EXCEL|[������������ת����.xlsx]Sheet1!r4c2:r4c3';
data _null_;set aall;file DD;put δ������� δ����������;run;


proc import datafile="F:\���������ձ���\������������ת�������ñ�.xls"
out=lable dbms=excel replace;
SHEET="Sheet1$";
scantext=no;
getnames=yes;
run;
data lable1;
set lable end=last;
call symput ("lable_"||compress(_n_),compress(��ǩ));
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
create table cc1(where=(��ĩ��ǩ^="")) as
select ��ĩ��ǩ,sum(����) as ���� ,count(*) as ��ĩ,sum(�������) as �������  from cc (where=((od_days>0 or (od_days=0 and ����_���տۿ�ʧ�ܺ�ͬ=1)) and ��ת��ǩ="&&lable_&i")) group by ��ĩ��ǩ;
quit;

proc sql;
create table cc1_1(where=(�ڳ���ǩ^="")) as
select �ڳ���ǩ,sum(��ת����) as ��ת����,sum(������) as ������,count(*) as �ڳ�  from cc (where=((last_oddays>0 or (last_oddays=0 and last_����_���տۿ�ʧ�ܺ�ͬ=1))and ��ת��ǩ="&&lable_&i")) group by �ڳ���ǩ;
quit;
proc sql;
create table cc1_2(where=(�ڳ���ǩ^="")) as
select �ڳ���ǩ,sum(�߻�) as �߻�   from cc(where=( ��ת��ǩ="&&lable_&i"))  group by �ڳ���ǩ;
quit;
proc sql;
create table cc2 as
select a.*,b.*,c.�߻� from cc1 as a
left join cc1_1 as b on a.��ĩ��ǩ=b.�ڳ���ǩ
left join cc1_2 as c on a.��ĩ��ǩ=c.�ڳ���ǩ;
quit;
data st1 st2;
set cc2;
if ��ĩ��ǩ in ("01:1-3","02:4-15","03:16-30") then output st1;
else output st2;
run;
filename DD DDE "EXCEL|[������������ת����.xlsx]Sheet1!r&&totalb1_row_&i..c5:r&&totale1_row_&i..c9";
data _null_;set st1;file DD;put �ڳ� ����  ��ת���� ������ �߻�;run;
filename DD DDE "EXCEL|[������������ת����.xlsx]Sheet1!r&&totalb1_row_&i..c11:r&&totale1_row_&i..c12";
data _null_;set st1;file DD;put ��ĩ �������;run;

filename DD DDE "EXCEL|[������������ת����.xlsx]Sheet1!r&&totalb2_row_&i..c5:r&&totale2_row_&i..c9";
data _null_;set st2;file DD;put �ڳ� ����  ��ת���� ������ �߻�;run;
filename DD DDE "EXCEL|[������������ת����.xlsx]Sheet1!r&&totalb2_row_&i..c11:r&&totale2_row_&i..c12";
data _null_;set st2;file DD;put ��ĩ �������;run;
proc sql;
create table aall as
select count(CONTRACT_NO) as δ�������,sum(�������) as δ���������� from cc(where=(�˻���ǩ in ("�ۿ�ʧ��","����") and ��ת��ǩ="&&lable_&i"));
quit;
filename DD DDE "EXCEL|[������������ת����.xlsx]Sheet1!r&&totalb1_row_&i..c2:r&&totalb1_row_&i..c3";
data _null_;set aall;file DD;put δ������� δ����������;run;
%end;
%mend;
%city_table();


/**��һ����������;*/
/*data  kan;*/
/*set month1day;*/
/*last_oddays=lag(od_days);*/
/*last_����_���տۿ�ʧ�ܺ�ͬ=lag(����_���տۿ�ʧ�ܺ�ͬ);*/
/*by CONTRACT_no cut_date;*/
/*if first.contract_no then do ;last_oddays=od_days;last_�������=�������;last_����_���տۿ�ʧ�ܺ�ͬ=����_���տۿ�ʧ�ܺ�ͬ;end;*/
/*if cut_date=&dt.-1;*/
/*if od_days=0 and (last_oddays>0 or last_����_���տۿ�ʧ�ܺ�ͬ=1);*/
/*run;*/
/*data  kan1;*/
/*set month1day;*/
/*last_oddays=lag(od_days);*/
/*last_����_���տۿ�ʧ�ܺ�ͬ=lag(����_���տۿ�ʧ�ܺ�ͬ);*/
/*by CONTRACT_no cut_date;*/
/*if first.contract_no then do ;last_oddays=od_days;last_�������=�������;last_����_���տۿ�ʧ�ܺ�ͬ=����_���տۿ�ʧ�ܺ�ͬ;end;*/
/*if cut_date=&dt.-2;*/
/*if od_days=0 and (last_oddays>0 or last_����_���տۿ�ʧ�ܺ�ͬ=1);*/
/*run;*/
