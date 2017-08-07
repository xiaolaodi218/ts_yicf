*****************************************
	策略入参子主题
*****************************************;
option compress = yes validvarname = any;
/**/
libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";

**Loanevent_in;
proc import datafile="D:\mili\Datamart\pyscript\submart\bqsreq.xlsx"
out=submart.bqsreq dbms=excel replace;
getnames=yes;
run;

**Cxfeature_na;
proc import datafile="D:\mili\Datamart\pyscript\submart\cxreq.xlsx"
out=submart.Cxfeature_na dbms=excel replace;
getnames=yes;
run;

**TQ_score;
proc import datafile="D:\mili\Datamart\pyscript\submart\tqreq.xlsx"
out=submart.tqreq_score dbms=excel replace;
getnames=yes;
run;

***贷款事件;
data loanevent;
set submart.loanBQS_loan_submart(keep = apply_code main_info_id execut日期 execut月份 os_type execut状态);
run;
data main_log_id;
set dpraw.bqs_main_info(keep = id data_query_log_id);
rename id = main_info_id;
run;
proc sort data = loanevent nodupkey; by main_info_id; run;
proc sort data = main_log_id nodupkey; by main_info_id;run;
data loanevent;
merge loanevent(in = a) main_log_id(in = b);
by main_info_id;
if a;
run;

***贷款事件策略入参;
data loanevent_in;
set submart.bqsreq;
rename id = data_query_log_id;
run;

proc sort data = loanevent nodupkey; by data_query_log_id; run;
proc sort data = loanevent_in nodupkey; by data_query_log_id; run;

data submart.loanevent_in;
merge loanevent(in = a) loanevent_in(in = b); 
by data_query_log_id;
if a;
run;

**拼接距离数据;
proc sort data = submart.loanevent_in nodupkey; by apply_code; run;
proc sort data = submart.every_distance(drop = gps_address job_company_address residence_address) nodupkey; by apply_code; run;

data submart.loanevent_in;
merge submart.loanevent_in(in = a) submart.every_distance(in = b); 
by apply_code;
if a;
run;

**决策事件;
data decisionevent;
set submart.Loanbqs_decision_submart(keep = apply_code main_info_id execut日期 execut月份 os_type execut状态);
run;
data main_log_id;
set dpraw.bqs_main_info(keep = id data_query_log_id);
rename id = main_info_id;
run;
proc sort data = decisionevent nodupkey; by main_info_id; run;
proc sort data = main_log_id nodupkey; by main_info_id;run;
data decisionevent;
merge decisionevent(in = a) main_log_id(in = b);
by main_info_id;
if a;
run;

***决策事件策略入参;

**天启分;

data tqreq;
set submart.tqreq_score(keep = id loc_tqscore);
rename id = data_query_log_id;
run;

proc sort data = decisionevent nodupkey; by data_query_log_id; run;
proc sort data = tqreq nodupkey; by data_query_log_id; run;

data submart.decisionevent_in;
merge decisionevent(in = a) tqreq(in = b); 
by data_query_log_id;
if a;
run;

**拼接贷款事件和决策事件入参;

proc sort data = submart.loanevent_in nodupkey; by apply_code;run;
proc sort data = submart.decisionevent_in nodupkey; by apply_code;run;

data submart.loanevent_in;
merge submart.loanevent_in(in = a) submart.decisionevent_in(in =b);
by apply_code;
if a;
run;

********************************************************;

%macro InitVariableInDataset(dataset,withoutvar, withoutvar2='');

	%local dsid i nvar vname vtype rc strN strC;
	%let strN = %str(=.;);
	%let strC = %str(='';);
	%let dsid = %sysfunc(open(&dataset));
	%if &dsid %then
		%do;
			%let nvar = %sysfunc(attrn(&dsid,NVARS));
%*			%put &nvar;
		   	%do i = 1 %to &nvar;
		      %let vname = %sysfunc(varname(&dsid,&i));
			  %if %UPCASE(&vname) ^= %UPCASE(&withoutvar) 
				and %UPCASE(&vname) ^= %UPCASE(&withoutvar2) %then %do;
			      %let vtype = %sysfunc(vartype(&dsid,&i));
	%*			  	%put _%sysfunc(compress(&vtype))_;
				  %if %sysfunc(compress(&vtype)) = N %then %do;
&vname &strN; 
				  %end; %else %do;
&vname &strC;
				  %end;

			  %end;
		   	%end;

			%let rc = %sysfunc(close(&dsid));
		%end;
	%else %put %sysfunc(sysmsg());

%mend;

data register_date;
set dpraw.jxl_data_summary(keep = user_code phone_no_register_time);
register_date = scan(phone_no_register_time,1,"");
drop phone_no_register_time;
run;
data apply_user_code;
set dpraw.apply_info(keep = apply_code user_code);
run;

data loc_register_date;
	if _n_ = 0 then set register_date;
	if _n_ = 1 then do;
		declare hash share(dataset:'register_date');
					share.definekey('user_code');
					share.definedata(all:'yes');
					share.definedone();
	call missing (of _all_);
	end;
	set apply_user_code;
	if share.find() = 0;
run;

data loanevent_in;
	if _n_ = 0 then set loc_register_date;
	if _n_ = 1 then do;
		declare hash share(dataset:'loc_register_date');
					share.definekey('apply_code');
					share.definedata(all:'yes');
					share.definedone();
	call missing (of _all_);
	end;
	set submart.loanevent_in;
	if share.find() = 0 then do; end;
	else do; %InitVariableInDataset(loc_register_date,apply_code); end;
run;

data submart.loanevent_in;
set loanevent_in;
if loc_register_date = "" then loc_register_date = register_date;
drop user_code register_date;
run;

/*data zm_score;*/
/*set submart.loanevent_in(keep=apply_code execut日期 execut月份 data_query_log_id loc_zmscore loc_tqscore loc_CreditxScore);*/
/*run;*/
/**/
/*filename export "F:\BQS\loc_score.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= zm_score */
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
