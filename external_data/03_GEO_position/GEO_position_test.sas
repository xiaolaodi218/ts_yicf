option compress=yes validvarname=any;
option missing = 0;

libname daily "D:\mili\offline\daily";
libname cred "D:\mili\offline\offlinedata\credit";
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*������ȡ��500�����ҵ�������������;
ʱ��ά��Ϊ2017/12/20 - 2017/12/31*/
************************************
Bad   ���� ����֮���Զ��ܾ��Ŀͻ�
Good  ���� �Ѿ��ſ�Ŀͻ�
Indet ���� ����
************************************;

/*�Զ��ܾ��Ŀͻ�*/
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(12,21,2017);
dt_end=mdy(12,31,2017);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***ȡ2017��12��21�շݿ�ʼ�ķſ�***;
if auto_reject_time <= &dt_end.;	***ȡ2017��12��31�շݽ����ķſ�***;
run;


/*�Ѿ��ſ�Ŀͻ�*/
data make_loan_good;
set daily.daily_acquisition(keep = APPLY_CODE �ſ�״̬ �ſ����� ID_CARD_NO);
if �ſ�״̬ = "�ѷſ�";
if �ſ����� >= '21DEC2017'd;
if �ſ����� <= '31DEC2017'd;
run;

/*סַ�͹�˾סַ��Ϣ*/
data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1  ��סʡ ��ס�� ��ס��  RESIDENCE_ADDRESS ����ʡ ������ ������ COMP_ADDRESS);
��ס��ַ = cats(��סʡ, ��ס��, ��ס��, RESIDENCE_ADDRESS);
������ַ = cats(����ʡ, ������, ������, COMP_ADDRESS);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;


data test;
set auto_reject_bad  make_loan_good;
run;
proc sort data= test nodupkey ;by apply_code;run;


data apply_base;
set approval.apply_base(keep = apply_code ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;


data test_bb;
merge test(in = a) com_res_info(in = b) apply_base(in = c);
by apply_code;
if a ;
run;

/*32λMD5����*/
data test_bba;
set test_bb;
rename  NAME = ����  PHONE1=�ֻ���  ID_CARD_NO = ���֤��;
/*�ֻ��� = put(md5(PHONE1), $hex32.);*/
/*���֤�� = put(md5(ID_CARD_NO), $hex32.);*/
if auto_reject = 1 then y = 1;
else y = 0;
run;

data test_B18;
set test_bba(keep = ���� �ֻ��� ���֤�� ������ַ);
run;

data test_B19;
set test_bba(keep = ���� �ֻ��� ���֤�� ��ס��ַ);
run;

filename export "F:\TS\external_data_test\�ٶȽ���\data\test_B18.csv" encoding='utf-8';
PROC EXPORT DATA= test_B18 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\TS\external_data_test\�ٶȽ���\data\test_B19.csv" encoding='utf-8';
PROC EXPORT DATA= test_B19 
			 outfile = export
			 dbms = csv replace;
RUN;
