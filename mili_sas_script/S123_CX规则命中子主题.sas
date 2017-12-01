*****************************************
	CX规则命中子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

libname dwdata "D:\mili\Datamart\rawdata\dwdata";

data apply_date;
set submart.apply_submart(keep = apply_code 申请提交月份 申请提交日期);
run;

data creditx_anti_fraud;
set dpraw.creditx_anti_fraud(keep = apply_code last_updated);
规则命中月份 = put(datepart(last_updated), yymmn6.);
规则命中日期 = put(datepart(last_updated), yymmdd10.);
run;
proc sort data = creditx_anti_fraud nodupkey; by apply_code; run;
proc sort data = apply_date nodupkey; by apply_code; run;
data submart.CX_anti_fraud;
merge creditx_anti_fraud(in = a) apply_date(in = b);
by apply_code;
if a;
run;


filename export "D:\mili\Datamart\rawdata_csv_py\dwdata\risk_creditx_resp.csv" encoding='utf-8';
PROC IMPORT out= dwdata.risk_creditx_resp 
			 datafile = export
			 dbms = csv replace;
RUN;
data DWDATA.RISK_CREDITX_RESP    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile EXPORT delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
informat apply_code $26. ;
informat ruleID $16. ;
informat riskDesc $38. ;
informat riskLevel best32. ;
informat ruleType $12. ;
format apply_code $26. ;
format ruleID $16. ;
format riskDesc $38. ;
format riskLevel best12. ;
format ruleType $12. ;
input
apply_code $
ruleID $
riskDesc $
riskLevel
ruleType $
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data creditx_hit_rule;
set dwdata.risk_creditx_resp;
run;

proc sort data = submart.CX_anti_fraud out = creditx_anti_fraud nodupkey; by apply_code; run;
proc sort data = creditx_hit_rule; by apply_code; run;
data submart.CXrule_submart;
merge creditx_anti_fraud(in = a) creditx_hit_rule(in = b);
by apply_code;
if a;
run;


