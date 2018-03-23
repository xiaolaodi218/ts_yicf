*******************************
		月底贷款余额子主题
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
format 月底状态 $20. 月底催回状态 $20.;
cut_month = put(&cut_dt., yymmn6.);
	 if repay_date > &cut_dt. then 月底状态 = "1.未到期";
else if clear_date ^=. and clear_date <= &cut_dt. then 月底状态 = "0.结清";
else do;
			 if min(overdue_days, &cut_dt. - repay_date) > 90 then 月底状态 = "7.逾期90+";
		else if min(overdue_days, &cut_dt. - repay_date) > 30 then 月底状态 = "6.逾期31-90";
		else if min(overdue_days, &cut_dt. - repay_date) > 15 then 月底状态 = "5.逾期16-30";
		else if min(overdue_days, &cut_dt. - repay_date) > 5 then 月底状态 = "4.逾期6-15";
		else if min(overdue_days, &cut_dt. - repay_date) > 0 then 月底状态 = "3.逾期1-5";
		else 月底状态 = "2.扣款失败";
	 end;
/*	 if 月底状态 in ("0.结清") and overdue_days >90 then do; 月底催回状态 = "催回90+";end;*/
/*	 if 月底状态 in ("0.结清") then delete;*/
/*	 if 月底状态 in ("0.结清") then do; 贷款余额 = CURR_RECEIVE_AMT; 贷款余额_本金 = CONTRACT_AMOUNT; end;*/
/*else */
do; 贷款余额 = CURR_RECEIVE_AMT; 贷款余额_本金 = CONTRACT_AMOUNT; end;
keep contract_no loan_date repay_date CLEAR_DATE overdue_days 月底状态 贷款余额 贷款余额_本金 cut_month;
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
if 月底状态 in ("0.结清") then 催回状态 = "催回90+";
run;

filename export "F:\celueji\sas_csv\mili_balance.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.mili_balance 
			 outfile = export
			 dbms = csv replace;
RUN;

***加一个字段，截止每个月月底的状态：催回状态;
