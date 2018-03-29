option compress=yes validvarname=any;
option missing = 0;

libname daily "D:\mili\offline\daily";
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";

libname cred "D:\mili\offline\offlinedata\credit";
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*����ȡ��5000�����ҵ�������������;

����			
	�ſ��·�	������	��ע
	201708	1000	�кû�����
	201712	1000	����������
			
����			
	201710	3000	�кû�����


************************************
Bad   ���� ����֮���Զ��ܾ��Ŀͻ�
Good  ���� �Ѿ��ſ�Ŀͻ�
Indet ���� ����
************************************;

*offline
/*�Զ��ܾ��Ŀͻ�*/
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(12,14,2017);
dt_end=mdy(12,31,2017);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***ȡ2017��12��11�շݿ�ʼ�ķſ�***;
if auto_reject_time <= &dt_end.;	***ȡ2017��12��31�շݽ����ķſ�***;
run;


/*�Ѿ��ſ�Ŀͻ�*/
data make_loan_good;
set daily.daily_acquisition(keep = APPLY_CODE �ſ�״̬ �ſ����� ID_CARD_NO);
if �ſ�״̬ = "�ѷſ�";
if �ſ����� >= '14DEC2017'd;
if �ſ����� <= '31DEC2017'd;
run;

/*סַ�͹�˾סַ��Ϣ*/
data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1  ��סʡ ��ס�� ��ס��  RESIDENCE_ADDRESS ����ʡ ������ ������ COMP_ADDRESS);
��ס��ַ = cats(��סʡ, ��ס��, ��ס��, RESIDENCE_ADDRESS);
������ַ = cats(����ʡ, ������, ������, COMP_ADDRESS);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;

/*�Զ��ܾ��ͻ�*/
data test;
set auto_reject_bad  make_loan_good;
run;
proc sort data= test nodupkey ;by apply_code;run;


data apply_base;
set approval.apply_base(keep = apply_code  ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;


data test_offline01;
merge test(in = a) com_res_info(in = b) apply_base(in = c);
by apply_code;
if a ;
run;


/*201708�ſ���кû����ֵĿͻ�*/

%let month = '201803';

data target1;
set repayFin.payment(where = (month = &month. and mob > 6)
			keep = ��ƷС�� apply_code Ӫҵ�� ��Ʒ���� od_days od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '02AUG2017'd;	    ***ȡ2017��5�·ݿ�ʼ�ķſ�***;
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



/*��ȡ����*/
data last_loan_perfor;
set daily.daily_acquisition(keep = APPLY_CODE �ſ�״̬ �ſ����� ID_CARD_NO);
if �ſ�״̬ = "�ѷſ�";
if �ſ����� >= '02AUG2017'd;
if �ſ����� <= '31AUG2017'd;
run;

/*סַ�͹�˾סַ��Ϣ*/
data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1  ��סʡ ��ס�� ��ס��  RESIDENCE_ADDRESS ����ʡ ������ ������ COMP_ADDRESS);
��ס��ַ = cats(��סʡ, ��ס��, ��ס��, RESIDENCE_ADDRESS);
������ַ = cats(����ʡ, ������, ������, COMP_ADDRESS);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;

/*����ȡ���֤����*/
data apply_base;
set approval.apply_base(keep = apply_code ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;

data test_offline02;
merge last_loan_perfor(in = a) com_res_info(in = b) apply_base(in = c) target3(in = d);
by apply_code;
if a ;
run;


filename export "F:\TS\external_data_test\�ٶȽ���\data\test_offline01.csv" encoding='utf-8';
PROC EXPORT DATA= test_offline01 
			 outfile = export
			 dbms = csv replace;
RUN;
filename export "F:\TS\external_data_test\�ٶȽ���\second_test\data\test_offline02.csv" encoding='utf-8';
PROC EXPORT DATA= test_offline02 
			 outfile = export
			 dbms = csv replace;
RUN;


*�����Ŀͻ�;
option compress = yes validvarname = any;
libname ss "F:\����MTD\output";

/*ʹ��A004_�����������A005_���������ű��ܳ��������ݼ�*/
data ss.apply_submart;
set data.apply_submart;
run;
data ss.approval_submart;   /*�����������������=a*/
set data.approval_submart;
run;


option compress = yes validvarname = any;

libname data "D:\mili\Datamart\data";
libname repayFin "F:\���������ձ���\data";

/****�ͻ����ں�����������������;*/

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 70, 13, "same"); else dt = today() - 70;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

data milipayment_report;
set repayfin.milipayment_report;
if �ſ��·� = "201710";
run;

proc sort data=milipayment_report(where=(cut_date=&dt.)) out=ct_payment_report;by CONTRACT_NO;run;

data repay_r;
set ct_payment_report;
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
indent��������3������15�������ѽ��塢��ǰ����������
****/
if ������������ > 15 then do; target_label = "����15������"; y = 1;end;
else if bill_status = "0000" and ������������ <=3 then do;target_label = "���ڲ���3��";y = 0;end;
else do;target_label = "����3_15��";y = 2;end;
*if bill_status = "0000" and ������������ <=3 then y = 0;
*if ������������ > 3 then y = 1;
run;

data repay_10;
set repay(keep =CONTRACT_NO LOAN_DATE BORROWER_TEL_ONE y);
rename CONTRACT_NO = apply_code;
if y ^= "";
if y ^= 2;
if LOAN_DATE > '26OCT2017'd;
run;

proc sort data=repay_10 nodupkey;by apply_code;run;

/*ƴ��һ��user_code ʹ��*/
proc sort data=data.Id_submart nodupkey;by apply_code;run;

data id_repay;
merge repay_10(in = a) data.Id_submart(in = b);
by apply_code;
if a;
run;

data address_base;
set data.Baseinfo_submart(keep =USER_CODE  USER_NAME  ID_CARD  JOB_COMPANY_ADDRESS RESIDENCE_ADDRESS);
run;

proc sort data = address_base ; by user_code;run;
proc sort data = id_repay ;by user_code;run;

data id_repay_address;
merge id_repay(in = a) address_base(in = b);
by user_code;
if a;
run;

data id_repay_address1;
set id_repay_address(keep = apply_code USER_NAME BORROWER_TEL_ONE ID_CARD RESIDENCE_ADDRESS JOB_COMPANY_ADDRESS y);
run;

filename export "F:\TS\external_data_test\�ٶȽ���\data\mili_test.csv" encoding='utf-8';
PROC EXPORT DATA= id_repay_address1 
			 outfile = export
			 dbms = csv replace;
RUN;
