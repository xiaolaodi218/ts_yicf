*******************************
		�µ״������������
*******************************;

option compress = yes validvarname = any;
libname submart "D:\mili\Datamart\data";

%macro mili_balance;
data _null_;
n = intck("month", mdy(12,1,2016), today());
call symput("n", n);
run;
%put &n.;

%do i = 0 %to &n.;

data _null_;
cut_dt = intnx("month", mdy(12,1,2016), &i., "e");
if cut_dt > today() then cut_dt = today();
call symput("cut_dt", cut_dt);
run;

data temp;
set submart.mili_bill_main(where = (loan_date <= &cut_dt.));
format �µ�״̬ $20. �µ״߻�״̬ $20.;
cut_month = put(&cut_dt., yymmn6.);
	 if repay_date > &cut_dt. then �µ�״̬ = "1.δ����";
else if clear_date ^=. and clear_date <= &cut_dt. then �µ�״̬ = "0.����";
else do;
			 if min(overdue_days, &cut_dt. - repay_date) > 90 then �µ�״̬ = "7.����90+";
		else if min(overdue_days, &cut_dt. - repay_date) > 30 then �µ�״̬ = "6.����31-90";
		else if min(overdue_days, &cut_dt. - repay_date) > 15 then �µ�״̬ = "5.����16-30";
		else if min(overdue_days, &cut_dt. - repay_date) > 5 then �µ�״̬ = "4.����6-15";
		else if min(overdue_days, &cut_dt. - repay_date) > 0 then �µ�״̬ = "3.����1-5";
		else �µ�״̬ = "2.�ۿ�ʧ��";
	 end;
/*	 if �µ�״̬ in ("0.����") and overdue_days >90 then do; �µ״߻�״̬ = "�߻�90+";end;*/
/*	 if �µ�״̬ in ("0.����") then delete;*/
/*	 if �µ�״̬ in ("0.����") then do; ������� = CURR_RECEIVE_AMT; �������_���� = CONTRACT_AMOUNT; end;*/
/*else */
do; ������� = CURR_RECEIVE_AMT; �������_���� = CONTRACT_AMOUNT; end;
keep contract_no loan_date repay_date CLEAR_DATE overdue_days �µ�״̬ ������� �������_���� cut_month;
run;

%if &i. = 0 %then %do;
data submart.mili_balance;
set temp;
run;
%end;
%else %do;
proc append base = submart.mili_balance data = temp; run;
%end;

%end;
%mend;
%mili_balance;
proc sort data = submart.mili_balance; by contract_no cut_month; run;

data aaa;
set submart.mili_balance;
if overdue_days >90;
if �µ�״̬ in ("0.����") then �߻�״̬ = "�߻�90+";
run;

filename export "F:\celueji\sas_csv\mili_balance.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.mili_balance 
			 outfile = export
			 dbms = csv replace;
RUN;

***��һ���ֶΣ���ֹÿ�����µ׵�״̬���߻�״̬;
