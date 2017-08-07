option compress = yes validvarname = any;

libname submart "D:\mili\Datamart\data";

***策略漏斗;
filename export "F:\celueji\sas_csv\loanfunnel_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.loanfunnel_submart 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\reloanfunnel_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.RELOANFUNNEL_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\reloansimplefunnel_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.RELOANSIMPLEFUNNEL_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\loangoldfunnel_submart.csv" encoding='utf-8';
proc export data = SUBMART.LOANGOLDFUNNEL_SUBMART
			 outfile = export
			 dbms = csv replace;
run;

filename export "F:\celueji\sas_csv\loansilverfunnel_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.LOANSILVERFUNNEL_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

***事件结果;
filename export "F:\celueji\sas_csv\reloanbqs_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.RELOANBQS_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\reloantd_submart.csv" encoding='utf-8';
data reloantd_submart;
set SUBMART.RELOANTD_SUBMART(drop = event_name);
event_name = 'td';
run;
PROC EXPORT DATA= RELOANTD_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\reloansimplebqs_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.RELOANSIMPLEBQS_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\loanbqs_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.LOANBQS_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\loantd_submart.csv" encoding='utf-8';
data loantd_submart;
set SUBMART.LOANTD_SUBMART(drop = event_name);
event_name = 'td';
run;
PROC EXPORT DATA= loantd_submart 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\loancx_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.LOANCX_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

***规则命中;
filename export "F:\celueji\sas_csv\bqsrule_jbgz_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_JBGZ_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_fsyys_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_FSYYS_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_fsds_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_FSDS_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_glgz_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_GLGZ_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_mddh_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_MDDH_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_fdjbgz_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_FDJBGZ_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_fdzr_submart.csv" encoding='utf-8';
PROC EXPORT DATA= SUBMART.BQSRULE_FDZR_SUBMART 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\cx_anti_fraud.csv" encoding='utf-8';
data cx_anti_fraud;
set submart.cx_anti_fraud;
event_name = 'cx';
execut状态 = 'FINISHED';
rename 规则命中月份 = execut月份 规则命中日期 = execut日期;
run;
PROC EXPORT DATA= cx_anti_fraud 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\cxrule_submart.csv" encoding='utf-8';
data cxrule_submart;
set submart.cxrule_submart;
event_type = 'LOAN';
event_name = 'cx';
	 if riskLevel = '3' then rule_decision = 'Reject';
else if riskLevel = '2' then rule_decision = 'Review';
else rule_decision = 'Accept';
rename riskDesc = rule_name_normal;
run;
PROC EXPORT DATA= cxrule_submart 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\tdrule_submart.csv" encoding='utf-8';
data tdrule_submart;
set submart.tdrule_submart;
event_name = 'td';
rename rule_name = rule_name_normal;
run;

PROC EXPORT DATA= tdrule_submart 
			 outfile = export
			 dbms = csv replace;
RUN;


data bqsrule_submart;
set submart.bqsrule_jbgz_submart
	submart.bqsrule_fdzr_submart
	submart.bqsrule_fdjbgz_submart
	submart.bqsrule_fsyys_submart
	submart.bqsrule_fsyys_b_submart
	submart.bqsrule_fsds_submart
	submart.bqsrule_glgz_submart
	submart.bqsrule_mddh_submart
	submart.bqsrule_face_submart
;
run;

filename export "F:\celueji\sas_csv\bqsrule_submart.csv" encoding='utf-8';
PROC EXPORT DATA= bqsrule_submart 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\celueji\sas_csv\bqsrule_fsyys_b_submart.csv" encoding='utf-8';
PROC EXPORT DATA= submart.bqsrule_fsyys_b_submart 
			 outfile = export
			 dbms = csv replace;
RUN;
