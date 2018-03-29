/********************************************************************************************/
/* ����΢�˿Ƽ����޹�˾��Ҫ������																				*/
/* 2018-01-12, �½�, Yichengfan  						   								    */


/*2018/3/19,���¸������ݣ�Yichengfan	*/
/********************************************************************************************/

/*��ȷ��ʱ��ά�Ⱥ���������С����ȷ��ȡ��Щ����*/
option compress = yes validvarname = any;

libname ly_data "\\ly\Datamart\�м��\daily";

libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname daily "D:\mili\offline\daily";
libname cre "D:\mili\offline\centre_data\daily";

libname credit "D:\mili\offline\offlinedata\credit";
libname approval "D:\mili\offline\offlinedata\approval";

libname test "F:\TS\external_data_test\data";


/*�û��Ķ���*/ 
option compress = yes validvarname = any;
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname orig "F:\TS\offline_model\01_Dataset\01_original";

%let month = '201803';

data target1;
set repayFin.payment(where = (month = &month. and mob > 8)
			keep = ��ƷС�� apply_code Ӫҵ�� ��Ʒ���� od_days od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);
if '20JUN2017'd=>LOAN_DATE >= '01MAY2017'd;	    ***ȡ2017��5�·ݿ�ʼ�ķſ�***;
if ��Ʒ���� = "����" then delete;	***�޳�������Ʒ***;	
if not kindex(��ƷС�� ,"����");     ***�޳�������Ʒ***;	
run;

proc sort data = target1 nodupkey; by apply_code descending mob; run;
proc sort data = target1 nodupkey; by apply_code;run;

data target2;
set target1;
/*if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***�޳����������Ƴ���ǰ3�ھͿ�ʼ�����Ҳ����ĺ�ͬ����������թ***;*/
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***��������ڣ�����ʵ�Ļ���������һ������***;

************************************
Bad   ���� ��ǰ12�������ڳ�����������30������
Good  ���� ��������ڴ���5����ǰ������Ǵ���5�������ڻ����Ǵ���7���� ��ǰδ���� �� ������������С��8���ŵ�˴߻أ�
Indet ���� ����
************************************;
format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;

data target3;
set target2(keep = apply_code od_days_ever mob �ſ��·� target_label target);
if target^=2;
run;

data target4;
set target3(firstobs=1 obs=1000);
run;


/*ȡһ�»�����Ϣ*/
data customer_info;
merge cre.customer_info(in = a) approval.apply_info(in = b) ;
by apply_code;
if a;
run;

data customer_info_2;
set customer_info(keep = 
/*ID_CARD_NO  PHONE1*/
apply_code  ����ʱ�� approve_��Ʒ BRANCH_NAME
DESIRED_LOAN_LIFE  DESIRED_LOAN_AMOUNT  CHILD_COUNT age �����̶� �Ա� ����״��  
��סʡ ��ס�� ��ס�� ����ʡ ������ ������ ס������ 
�������� ��λ���� ְλ COMP_ADDRESS CURRENT_INDUSTRY WORK_YEARS ��ְʱ�� ����ʡ ������ ������ 
��λ����  ��������  �����»� ���ÿ��»� �籣���� ��������� 
IS_HAS_CAR  IS_HAS_HOURSE    
׼���ǿ��»� ��ʵ���� ��ʵ�������� ������ծ YEARLY_INCOME MONTHLY_SALARY MONTHLY_OTHER_INCOME н�ʷ��ŷ�ʽ
);
/*����ָ���ַ���λ��ȡ�ַ���,��Ӫҵ������Ϊ������*/
format �������$50.;
	 if index(BRANCH_NAME, "���ͺ����е�һӪҵ��") then ������� = "���ͺ���";
else if index(BRANCH_NAME, "��³ľ���е�һӪҵ��") then ������� = "��³ľ��";
else �������=substr(BRANCH_NAME,1, 4);

/*�����������*/;
if DESIRED_LOAN_LIFE=341  then ������������=6;
else if DESIRED_LOAN_LIFE=342 then ������������=12;
else if DESIRED_LOAN_LIFE=343 then ������������=18;
else if DESIRED_LOAN_LIFE=344 then ������������=24;
else if DESIRED_LOAN_LIFE=345 then ������������=36;
else if ������������=0;

rename 
approve_��Ʒ = �����Ʒ      age = ����   COMP_ADDRESS = ��˾��ַ   CURRENT_INDUSTRY = ������ҵ
DESIRED_LOAN_AMOUNT = ���������  WORK_YEARS = ��������
CHILD_COUNT = ��Ů����  IS_HAS_CAR = �Ƿ��г�   IS_HAS_HOURSE = �Ƿ��з�
YEARLY_INCOME = ������  MONTHLY_SALARY = ������  MONTHLY_OTHER_INCOME = ����������
;

drop BRANCH_NAME DESIRED_LOAN_LIFE;

run;


data test_ex;
merge target4(in = a) customer_info_2(in = b) ;
by apply_code;
if a;
/*drop  ;*/
run;


/*filename export "F:\TS\external_data_test\����΢��\second_test\output\user_baseinfo.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= test_ex*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/

PROC EXPORT DATA=test_ex
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="user_baseinfo"; 
RUN;



/*��������*/

data test_applycode;
set test_ex(keep = apply_code);
run;

proc sort data=test_applycode nodupkey; by apply_code; run;

proc sort data=credit.Credit_report nodupkey out = crt; by apply_code; run;

/*pboc_credit*/
data pboc_credit;
merge crt(in = a)  test_applycode(in = b);
by apply_code;
if b;
run;

proc sort data=pboc_credit nodupkey; by apply_code; run;

data pboc_credit;
set pboc_credit;
if apply_code ^= "";
run;



/*pboc_base*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_info_base ; by REPORT_NUMBER; run;

data pboc_base;
merge  pboc_credit(in = a)  credit.Credit_info_base(in = b);
by REPORT_NUMBER;
if a;
drop ID ID_CARD ID_NUMBER; 
run;

/*filename export "F:\TS\external_data_test\����΢��\second_test\output\pboc_base.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_base*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_base
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_base"; 
RUN;



/*pboc_detail*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
data Credit_detail;
set credit.Credit_detail(drop =CREDIT_LINE_AMT_CNY	USEDCREDIT_LINE_AMT_CNY
LOAN_PERIOD	MONTHLY_PAYMENT	CREDIT_BALANCE	OVERDRAFT_BALANCE );
run;
proc sort data=Credit_detail ; by REPORT_NUMBER; run;

data pboc_detail;
merge  pboc_credit(in = a)  Credit_detail(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD;
run;

data pboc_detail;
set pboc_detail;
if apply_code ^= "";
run;

/*filename export "F:\TS\external_data_test\����΢��\second_test\output\pboc_detail.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_detail*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_detail
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_detail"; 
RUN;

/*pboc_query*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_query_record out = cqrd ; by REPORT_NUMBER; run;

data pboc_query;
merge pboc_credit(in = a)  cqrd(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD QUERY_OPERATOR;
run;


data pboc_query;
set pboc_query;
if apply_code ^= "";
run;


/*filename export "F:\TS\external_data_test\����΢��\second_test\output\pboc_query.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_query*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_query
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_query"; 
RUN;



/***��ϣ����,ƴ�Ӵ����ݼ�;*/
/**/
/*%macro InitVariableInDataset(dataset,withoutvar, withoutvar2='');*/
/**/
/*	%local dsid i nvar vname vtype rc strN strC;*/
/*	%let strN = %str(=.;);*/
/*	%let strC = %str(='';);*/
/*	%let dsid = %sysfunc(open(&dataset));*/
/*	%if &dsid %then*/
/*		%do;*/
/*			%let nvar = %sysfunc(attrn(&dsid,NVARS));*/
/*%*			%put &nvar;*/
/*		   	%do i = 1 %to &nvar;*/
/*		      %let vname = %sysfunc(varname(&dsid,&i));*/
/*			  %if %UPCASE(&vname) ^= %UPCASE(&withoutvar) */
/*				and %UPCASE(&vname) ^= %UPCASE(&withoutvar2) %then %do;*/
/*			      %let vtype = %sysfunc(vartype(&dsid,&i));*/
/*	%*			  	%put _%sysfunc(compress(&vtype))_;*/
/*				  %if %sysfunc(compress(&vtype)) = N %then %do;*/
/*&vname &strN; */
/*				  %end; %else %do;*/
/*&vname &strC;*/
/*				  %end;*/
/**/
/*			  %end;*/
/*		   	%end;*/
/**/
/*			%let rc = %sysfunc(close(&dsid));*/
/*		%end;*/
/*	%else %put %sysfunc(sysmsg());*/
/**/
/*%mend;*/
/**/
/*proc sort data=pboc_credit ; by REPORT_NUMBER; run;*/
/*proc sort data=credit.Credit_query_record out=cqrd; by REPORT_NUMBER; run;*/
/**/
/*data ass;*/
/*	if _n_ = 0 then set pboc_credit;*/
/*	if _n_ = 1 then do;*/
/*		declare hash share(dataset:'pboc_credit');*/
/*					 share.definekey('report_number');*/
/*					 share.definedata(all:'yes');*/
/*					 share.definedone();*/
/*	call missing (of _all_);*/
/*	end;*/
/*	set cqrd;*/
/*	if share.find() = 0 then do; end;*/
/*	else do; %InitVariableInDataset(pboc_credit,report_number); end;*/
/*run;*/
/**/
/**/
/**/





option compress=yes validvarname=any;
libname appRaw odbc  datasrc=approval_nf;
libname brlist "D:\mili\offline\br_blacklist";

data brlist.early_warning_info;
set appraw.early_warning_info;
run;
/*����������*/
proc sql;
create table br_blacklist as 
SELECT * FROM  brlist.early_warning_info WHERE SOURCE = 'blackList'; quit;
/*������������*/
data br_blacklist1;
set br_blacklist;
if LEVEL ="BRB";
run;

proc sort data = br_blacklist1 out = br_blacklist2 nodupkey;by apply_no;run;

data br_blacklist3;
set br_blacklist2(keep=APPLY_NO  VALUE_  CONTENT);
rename apply_no = apply_code;
run;

data external_br_blacklist;
merge test_applycode(in = a) br_blacklist3(in = b);
by apply_code;
if a;
run;

filename export "F:\TS\external_data_test\����΢��\second_test\output\external_br_blacklist.csv" encoding='utf-8';
PROC EXPORT DATA= external_br_blacklist
			 outfile = export
			 dbms = csv replace;
RUN;






*************************************************************************************************;
*��Ҫcredit_score����ķ�����������;

proc import datafile="F:\TS\external_data_test\����΢��\���ݺͲ��Խ��\test_data result.xlsx"
out=lable dbms=excel replace;
SHEET="Data";
scantext=no;
getnames=yes;
run;

data zhongrongwm;
merge lable(in = a) approval.credit_score(in = b);
by apply_code;
if a;
keep apply_code decile �Ƿ�ͨ�� score group_Level risk_level;
run;



























/*2018/3/21,���¸������ݣ�Yichengfan,���λ�Ҫ����300�����Զ��ܾ��Ŀͻ�������	*/
/********************************************************************************************/

/*��ȷ��ʱ��ά�Ⱥ���������С����ȷ��ȡ��Щ����*/
option compress = yes validvarname = any;

libname ly_data "\\ly\Datamart\�м��\daily";

libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname daily "D:\mili\offline\daily";
libname cre "D:\mili\offline\centre_data\daily";

libname credit "D:\mili\offline\offlinedata\credit";
libname approval "D:\mili\offline\offlinedata\approval";

libname test "F:\TS\external_data_test\data";


************************************
�Զ��ܾ��ͻ�  100
�����ܾ�      100
ǩԼ�ܾ�      100
************************************;


*offline
/*�Զ��ܾ��Ŀͻ�  100��*/;
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(1,1,2018);
dt_end=mdy(1,10,2018);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***ȡ2017��12��11�շݿ�ʼ�ķſ�***;
if auto_reject_time <= &dt_end.;	***ȡ2017��12��31�շݽ����ķſ�***;
run;

data auto_reject_bad1;
set auto_reject_bad(firstobs=1 obs=100);
run;

*offline
/*�˹�(����)�ܾ��Ŀͻ�  100��*/;

data approval_reject;
set daily.daily_acquisition(keep =APPLY_CODE �ܾ� �������� ��������  );
if  �ܾ� = 1;
if '03JAN2018'd=>�������� >= '01JAN2018'd;	    ***ȡ2018��1�·ݿ�ʼ�ķſ�***;
run;

data approval_reject1;
set approval_reject(firstobs=1 obs=100);
run;


*offline
/*�˹�(ǩԼ)�ܾ��Ŀͻ�  100��*/;
data sign_reject;
set daily.approval_refuse_his(keep =APPLY_CODE �����·� �������� �ſ�״̬ refuse_type );
if  refuse_type = "�ܾ�";
if �����·� = "201801";	    ***ȡ2018��1�·ݿ�ʼ�ķſ�***;
run;

data sign_reject1;
set sign_reject(firstobs=1 obs=100);
run;

/*ƴ����Щ�ܾ�������*/
data refuse_customer;
set auto_reject_bad1  approval_reject1  sign_reject1;
run;


/*ȡһ�¿ͻ�������Ϣ*/
data customer_info;
merge cre.customer_info(in = a) approval.apply_info(in = b) ;
by apply_code;
if a;
run;

data customer_info_2;
set customer_info(keep = 
/*ID_CARD_NO  PHONE1*/
apply_code  ����ʱ�� approve_��Ʒ BRANCH_NAME
DESIRED_LOAN_LIFE  DESIRED_LOAN_AMOUNT  CHILD_COUNT age �����̶� �Ա� ����״��  
��סʡ ��ס�� ��ס�� ����ʡ ������ ������ ס������ 
�������� ��λ���� ְλ COMP_ADDRESS CURRENT_INDUSTRY WORK_YEARS ��ְʱ�� ����ʡ ������ ������ 
��λ����  ��������  �����»� ���ÿ��»� �籣���� ��������� 
IS_HAS_CAR  IS_HAS_HOURSE    
׼���ǿ��»� ��ʵ���� ��ʵ�������� ������ծ YEARLY_INCOME MONTHLY_SALARY MONTHLY_OTHER_INCOME н�ʷ��ŷ�ʽ
);
/*����ָ���ַ���λ��ȡ�ַ���,��Ӫҵ������Ϊ������*/
format �������$50.;
	 if index(BRANCH_NAME, "���ͺ����е�һӪҵ��") then ������� = "���ͺ���";
else if index(BRANCH_NAME, "��³ľ���е�һӪҵ��") then ������� = "��³ľ��";
else �������=substr(BRANCH_NAME,1, 4);

/*�����������*/;
if DESIRED_LOAN_LIFE=341  then ������������=6;
else if DESIRED_LOAN_LIFE=342 then ������������=12;
else if DESIRED_LOAN_LIFE=343 then ������������=18;
else if DESIRED_LOAN_LIFE=344 then ������������=24;
else if DESIRED_LOAN_LIFE=345 then ������������=36;
else if ������������=0;

rename 
approve_��Ʒ = �����Ʒ      age = ����   COMP_ADDRESS = ��˾��ַ   CURRENT_INDUSTRY = ������ҵ
DESIRED_LOAN_AMOUNT = ���������  WORK_YEARS = ��������
CHILD_COUNT = ��Ů����  IS_HAS_CAR = �Ƿ��г�   IS_HAS_HOURSE = �Ƿ��з�
YEARLY_INCOME = ������  MONTHLY_SALARY = ������  MONTHLY_OTHER_INCOME = ����������
;

drop BRANCH_NAME DESIRED_LOAN_LIFE;

run;

proc sort data = refuse_customer nodupkey ; by apply_code;run;
proc sort data = customer_info_2 nodupkey ; by apply_code;run;

data test_ex;
merge refuse_customer(in = a) customer_info_2(in = b) ;
by apply_code;
if a;
run;


/*filename export "F:\TS\external_data_test\����΢��\second_test\output\user_baseinfo_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= test_ex*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/

PROC EXPORT DATA=test_ex
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test_300(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="user_baseinfo_300"; 
RUN;



/*��������*/

data test_applycode;
set test_ex(keep = apply_code);
run;

proc sort data=test_applycode nodupkey; by apply_code; run;

proc sort data=credit.Credit_report nodupkey out = crt; by apply_code; run;

/*pboc_credit*/
data pboc_credit;
merge crt(in = a)  test_applycode(in = b);
by apply_code;
if b;
run;

proc sort data=pboc_credit nodupkey; by apply_code; run;

data pboc_credit;
set pboc_credit;
if apply_code ^= "";
run;



/*pboc_base*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_info_base ; by REPORT_NUMBER; run;

data pboc_base;
merge  pboc_credit(in = a)  credit.Credit_info_base(in = b);
by REPORT_NUMBER;
if a;
drop ID ID_CARD ID_NUMBER; 
run;

/*filename export "F:\TS\external_data_test\����΢��\second_test\output\pboc_base_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_base*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_base
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test_300(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_base_300"; 
RUN;



/*pboc_detail*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
data Credit_detail;
set credit.Credit_detail(drop =CREDIT_LINE_AMT_CNY	USEDCREDIT_LINE_AMT_CNY
LOAN_PERIOD	MONTHLY_PAYMENT	CREDIT_BALANCE	OVERDRAFT_BALANCE );
run;
proc sort data=Credit_detail ; by REPORT_NUMBER; run;

data pboc_detail;
merge  pboc_credit(in = a)  Credit_detail(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD;
run;

data pboc_detail;
set pboc_detail;
if apply_code ^= "";
run;

/*filename export "F:\TS\external_data_test\����΢��\second_test\output\pboc_detail_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_detail*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_detail
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test_300(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_detail_300"; 
RUN;



/*pboc_query*/
proc sort data = pboc_credit; by REPORT_NUMBER; run;
proc sort data=credit.Credit_query_record out = cqrd ; by REPORT_NUMBER; run;

data pboc_query;
merge pboc_credit(in = a)  cqrd(in = b);
by REPORT_NUMBER;
if b;
drop ID ID_CARD QUERY_OPERATOR;
run;


data pboc_query;
set pboc_query;
if apply_code ^= "";
run;


/*filename export "F:\TS\external_data_test\����΢��\second_test\output\pboc_query_300.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= pboc_query*/
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/
PROC EXPORT DATA=pboc_query
OUTFILE= "F:\TS\external_data_test\����΢��\second_test\output\zhongrong_test_300(��Yֵ).xls" DBMS=EXCEL REPLACE;
SHEET="pboc_query_300"; 
RUN;
