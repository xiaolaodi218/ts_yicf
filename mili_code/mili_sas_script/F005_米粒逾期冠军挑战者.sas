option compress = yes validvarname = any;
libname repayFin "F:\���������ձ���\data";
libname account "D:\mili\Datamart\rawdata\account";
libname submart "D:\mili\Datamart\data";

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
/*%let dt=mdy(11,29,2017);*/

***�����ſ�ͻ�;
data mili;
set repayFin.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
��������=NEXT_REPAY_DATE-LOAN_DATE;
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

proc delete data=payment ;run;

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
if �˻���ǩ^="δ�ſ�";
format �����ǩ $20.;
/*cut_date=&cut_dt.;*/
if REPAY_DATE-cut_date>=1 and REPAY_DATE-cut_date<=3 then �����ǩ="T_3";
else if 1<=od_days<=3 then �����ǩ="1one_three";
else if 4<=od_days<=6 then �����ǩ="2four_six";
else if 7<=od_days<=15 then �����ǩ="3seven_fifteen";
else if 16<=od_days<=30 then �����ǩ="4sixteen_thirty";
else if od_days>30 then �����ǩ="5thirty_";
else if od_days>90 then �����ǩ="6ninety_";
ͳ�Ƹ���=1;
�ſ��·�=put(LOAN_DATE,yymmn6.);
������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if �˻���ǩ="������" then ������=�������;
run;

proc sort data=repayfin.milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by ��������;run;

data repayfin.apply_flag;
set submart.apply_flag(keep = apply_code loc_abmoduleflag);
rename apply_code = contract_no;
run;

**����AB�ı�ǩ;
proc sort data=repayfin.apply_flag ;by contract_no;run;
proc sort data=repayfin.milipayment_report ;by contract_no;run;

data repayfin.milipayment_report_flag;
merge repayfin.milipayment_report(in = a) repayfin.apply_flag(in = b);
by contract_no;
if a;
run;
proc sort data = repayfin.milipayment_report_flag ; by contract_no; run;


data repayfin.milipayment_report_flag;
set repayfin.milipayment_report_flag;
format ���Ա�ǩ $30.;
if loc_abmoduleflag="A" then ���Ա�ǩ="�ھ�";
if loc_abmoduleflag="B" then ���Ա�ǩ="��ս��";
run;
