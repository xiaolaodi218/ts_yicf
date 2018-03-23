    
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

data bqsreq ;
set submart.bqsreq;

format loc_ava_exp1 BEST12.;
format loc_tel_fm_rank1 BEST12.;
format loc_tel_po_rank1 BEST12.;
format loc_tel_py_rank1 BEST12.;
format loc_tel_qs_rank1 BEST12.;
format loc_tel_ts_rank1 BEST12.;
format loc_addresscnt1 BEST12.;
format loc_ava_limit1 BEST12.;
format loc_callcount1 BEST12.;
format loc_calledcount1 BEST12.;
format loc_inpast1st_calledtime1 BEST12.;
format loc_inpast1st_calltime1 BEST12.;
format loc_inpast2nd_calledtime1 BEST12.;
format loc_inpast2nd_calltime1 BEST12.;
format loc_inpast3rd_calledtime1 BEST12.;
format loc_inpast3rd_calltime1 BEST12.;
format loc_limit1 BEST12.;
format loc_phonenum1 BEST12.;
format loc_unusnalflag1 BEST12.;
format loc_CreditxScore1 BEST12.;

format loc_6mmaxcnt_silent1 BEST12.;
format loc_3mmaxcnt_silent1 BEST12.;
format loc_1mmaxcnt_silent1 BEST12.;
format loc_6mcnt_silent1 BEST12.;
format loc_3mcnt_silent1 BEST12.;
format loc_1mcnt_silent1 BEST12.;
format loc_zmscore1 BEST12.;


loc_ava_exp1 = loc_ava_exp;
loc_tel_fm_rank1 = loc_tel_fm_rank;
loc_tel_po_rank1 = loc_tel_po_rank;
loc_tel_py_rank1 = loc_tel_py_rank;
loc_tel_qs_rank1 = loc_tel_qs_rank;
loc_tel_ts_rank1 = loc_tel_ts_rank;
loc_addresscnt1 = loc_addresscnt;
loc_ava_limit1 = loc_ava_limit;
loc_callcount1 = loc_callcount;
loc_calledcount1 = loc_calledcount;
loc_inpast1st_calledtime1 = loc_inpast1st_calledtime;
loc_inpast1st_calltime1 = loc_inpast1st_calltime;
loc_inpast2nd_calledtime1 = loc_inpast2nd_calledtime;
loc_inpast2nd_calltime1 = loc_inpast2nd_calltime;
loc_inpast3rd_calledtime1  = loc_inpast3rd_calledtime;
loc_inpast3rd_calltime1 = loc_inpast3rd_calltime;
loc_limit1 = loc_limit;
loc_phonenum1 =loc_phonenum;
loc_unusnalflag1 = loc_unusnalflag;
loc_CreditxScore1 = loc_CreditxScore;

loc_6mmaxcnt_silent1 =loc_6mmaxcnt_silent;
loc_3mmaxcnt_silent1 = loc_3mmaxcnt_silent;
loc_1mmaxcnt_silent1 = loc_1mmaxcnt_silent;
loc_6mcnt_silent1 = loc_6mcnt_silent;
loc_3mcnt_silent1 = loc_3mcnt_silent;
loc_1mcnt_silent1 = loc_1mcnt_silent;
loc_zmscore1 = loc_zmscore;

run;

data loanevent;
set bqsreq(drop=loc_ava_exp loc_tel_fm_rank loc_tel_po_rank loc_tel_py_rank loc_tel_qs_rank loc_tel_ts_rank
loc_addresscnt
loc_ava_limit 
loc_callcount 
loc_calledcount 
loc_inpast1st_calledtime 
loc_inpast1st_calltime 
loc_inpast2nd_calledtime 
loc_inpast2nd_calltime 
loc_inpast3rd_calledtime 
loc_inpast3rd_calltime 
loc_limit 
loc_phonenum 
loc_unusnalflag 
loc_CreditxScore 

loc_6mmaxcnt_silent
loc_3mmaxcnt_silent
loc_1mmaxcnt_silent
loc_6mcnt_silent
loc_3mcnt_silent
loc_1mcnt_silent
loc_zmscore
);
rename loc_ava_exp1 = loc_ava_exp
loc_tel_fm_rank1 = loc_tel_fm_rank
loc_tel_po_rank1 = loc_tel_po_rank
loc_tel_py_rank1 = loc_tel_py_rank
loc_tel_qs_rank1 = loc_tel_qs_rank
loc_tel_ts_rank1 = loc_tel_ts_rank
loc_addresscnt1 = loc_addresscnt
loc_ava_limit1 = loc_ava_limit
loc_callcount1 = loc_callcount
loc_calledcount1 = loc_calledcount
loc_inpast1st_calledtime1 = loc_inpast1st_calledtime
loc_inpast1st_calltime1 = loc_inpast1st_calltime
loc_inpast2nd_calledtime1 = loc_inpast2nd_calledtime
loc_inpast2nd_calltime1 = loc_inpast2nd_calltime
loc_inpast3rd_calledtime1  = loc_inpast3rd_calledtime
loc_inpast3rd_calltime1 = loc_inpast3rd_calltime
loc_limit1 = loc_limit
loc_phonenum1 =loc_phonenum
loc_unusnalflag1 = loc_unusnalflag
loc_CreditxScore1 = loc_CreditxScore

loc_6mmaxcnt_silent1 =loc_6mmaxcnt_silent
loc_3mmaxcnt_silent1 = loc_3mmaxcnt_silent
loc_1mmaxcnt_silent1 = loc_1mmaxcnt_silent
loc_6mcnt_silent1 = loc_6mcnt_silent
loc_3mcnt_silent1 = loc_3mcnt_silent
loc_1mcnt_silent1 = loc_1mcnt_silent
loc_zmscore1 = loc_zmscore;
run;

/*data submart.bqsreq ;*/
/*set submart.bqsreq(drop=loc_ava_exp loc_tel_fm_rank loc_tel_po_rank loc_tel_py_rank loc_tel_qs_rank loc_tel_ts_rank);*/
/*run;*/

**Cxfeature_na;
proc import datafile="D:\mili\Datamart\pyscript\submart\cxreq.xlsx"
out=submart.Cxfeature_na dbms=excel replace;
getnames=yes;
run;

**TQ_score;
proc import datafile="D:\mili\Datamart\pyscript\submart\decreq.xlsx"
out=submart.decreq_score dbms=excel replace;
getnames=yes;
run;

data decreq_score ;
set submart.decreq_score;
format loc_bjscore1 BEST12.;

loc_bjscore1 = loc_bjscore;

run;

data decreq_score;
set decreq_score(drop=loc_bjscore );

rename loc_bjscore1 = loc_bjscore;

run;

**reloan;
proc import datafile="D:\mili\Datamart\pyscript\submart\req_bqs_reloan.xlsx"
out=submart.req_bqs_reloan dbms=excel replace;
getnames=yes;
run;

data req_bqs_reloan ;
set submart.req_bqs_reloan;

format loc_6mmaxcnt_silent1 BEST12.;
format loc_3mmaxcnt_silent1 BEST12.;
format loc_1mmaxcnt_silent1 BEST12.;
format loc_6mcnt_silent1 BEST12.;
format loc_3mcnt_silent1 BEST12.;
format loc_1mcnt_silent1 BEST12.;
format loc_zmscore1 BEST12.;

loc_6mmaxcnt_silent1 =loc_6mmaxcnt_silent;
loc_3mmaxcnt_silent1 = loc_3mmaxcnt_silent;
loc_1mmaxcnt_silent1 = loc_1mmaxcnt_silent;
loc_6mcnt_silent1 = loc_6mcnt_silent;
loc_3mcnt_silent1 = loc_3mcnt_silent;
loc_1mcnt_silent1 = loc_1mcnt_silent;
loc_zmscore1 = loc_zmscore;

run;

data req_bqs_reloan1;
set req_bqs_reloan(drop = loc_6mmaxcnt_silent
loc_3mmaxcnt_silent
loc_1mmaxcnt_silent
loc_6mcnt_silent
loc_3mcnt_silent
loc_1mcnt_silent
loc_zmscore
);

rename loc_6mmaxcnt_silent1 =loc_6mmaxcnt_silent
loc_3mmaxcnt_silent1 = loc_3mmaxcnt_silent
loc_1mmaxcnt_silent1 = loc_1mmaxcnt_silent
loc_6mcnt_silent1 = loc_6mcnt_silent
loc_3mcnt_silent1 = loc_3mcnt_silent
loc_1mcnt_silent1 = loc_1mcnt_silent
loc_zmscore1 = loc_zmscore;

run;






*************贷款事件*******************************************;
data loanBQS;
set submart.loanBQS_loan_submart(keep = apply_code main_info_id execut日期 execut月份 os_type execut状态);
run;
data main_log_id;
set dpraw.bqs_main_info(keep = id data_query_log_id);
rename id = main_info_id;
run;
proc sort data = loanBQS nodupkey; by main_info_id; run;
proc sort data = main_log_id nodupkey; by main_info_id;run;
data loan_bqs;
merge loanBQS(in = a) main_log_id(in = b);
by main_info_id;
if a;
run;

***贷款事件策略入参;
data loanevent_in;
set loanevent;
rename id = data_query_log_id;
run;

proc sort data = loan_bqs nodupkey; by data_query_log_id; run;
proc sort data = loanevent_in nodupkey; by data_query_log_id; run;

data submart.loanevent_in;
merge loan_bqs(in = a) loanevent_in(in = b); 
by data_query_log_id;
if a;
run;

**拼接距离数据;
proc sort data = submart.loanevent_in nodupkey; by apply_code; run;
proc sort data = submart.every_distance nodupkey; by apply_code; run;
/*proc sort data = submart.every_distance(drop = gps_address job_company_address residence_address) nodupkey; by apply_code; run;*/

data submart.loanevent_in;
merge submart.loanevent_in(in = a) submart.every_distance(in = b); 
by apply_code;
if a;
run;


**************复贷事件***********************************************;
data Reloanbqs;
set submart.Reloanbqs_loan_submart(keep = apply_code main_info_id execut日期 execut月份 os_type execut状态);
run;
data Reloansimplebqs;
set submart.Reloansimplebqs_loan_submart(keep = apply_code main_info_id execut日期 execut月份 os_type execut状态);
run;
data reloanevent;
set Reloanbqs Reloansimplebqs;
run;

data main_log_id;
set dpraw.bqs_main_info(keep = id data_query_log_id);
rename id = main_info_id;
run;
proc sort data = reloanevent nodupkey; by main_info_id; run;
proc sort data = main_log_id nodupkey; by main_info_id;run;
data reloanevent;
merge reloanevent(in = a) main_log_id(in = b);
by main_info_id;
if a;
run;

data req_bqs_reloan;
set req_bqs_reloan1;
rename id = data_query_log_id;
run;

proc sort data = reloanevent nodupkey; by data_query_log_id; run;
proc sort data = req_bqs_reloan nodupkey; by data_query_log_id; run;

data submart.reloanevent_in;
merge reloanevent(in = a) req_bqs_reloan(in = b); 
by data_query_log_id;
if a;
run;


***决策事件策略入参**************************************************;
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

**天启分，冰鉴分;

data dereq;
set decreq_score(keep = id loc_tqscore loc_bjscore);
rename id = data_query_log_id;
run;

proc sort data = decisionevent nodupkey; by data_query_log_id; run;
proc sort data = dereq nodupkey; by data_query_log_id; run;

data submart.decisionevent_in;
merge decisionevent(in = a) dereq(in = b); 
by data_query_log_id;
if a;
run;

**拼接贷款事件和决策事件入参;

proc sort data = submart.loanevent_in nodupkey; by apply_code;run;
proc sort data = submart.decisionevent_in nodupkey; by apply_code;run;


data submart.loanevent_de;
merge submart.loanevent_in(in = a) submart.decisionevent_in(in =b);
by apply_code;
if a;
run;

***拼接贷款事件和复贷事件;
proc sort data = submart.loanevent_de nodupkey; by apply_code;run;
proc sort data = submart.reloanevent_in nodupkey; by apply_code;run;

data submart.event_all;
set submart.loanevent_de submart.reloanevent_in;
run;

********************************************************;
**哈希函数,拼接大数据集;

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

data event_all;
	if _n_ = 0 then set loc_register_date;
	if _n_ = 1 then do;
		declare hash share(dataset:'loc_register_date');
					share.definekey('apply_code');
					share.definedata(all:'yes');
					share.definedone();
	call missing (of _all_);
	end;
	set submart.event_all;
	if share.find() = 0 then do; end;
	else do; %InitVariableInDataset(loc_register_date,apply_code); end;
run;

data submart.event_all;
set event_all;
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
