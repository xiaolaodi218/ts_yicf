option compress=yes validvarname=any;
option missing = 0;

libname daily "D:\mili\offline\daily";
libname centre "D:\mili\offline\centre_data\daily";

/*�������ݵ�׼���׶�*/
data loan_all;
set daily.daily_acquisition(keep = APPLY_CODE ID_CARD_NO NAME �������� �ſ�״̬ input_complete);
if input_complete = 1;
if �������� >= '01JAN2017'd;
if �������� <= '13MAR2018'd;
if �ſ�״̬ = "�ѷſ�";
run;

data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;


data loan_all2017;
merge loan_all(in = a) com_res_info(in = b);
by apply_code;
if a;
run;

proc sort data = loan_all2017 ;by ��������;run;

/*filename export "F:\TS\external_data_test\����\data\loan_all2017.csv" encoding='utf-8';*/
/*PROC EXPORT DATA= loan_all2017 */
/*			 outfile = export*/
/*			 dbms = csv replace;*/
/*RUN;*/



proc import datafile="F:\TS\external_data_test\����\�������Խ��_20180316\���Խ��_20180316.xlsx"
out=tq_test_data dbms=excel replace;
SHEET="���Խ��";
scantext=no;
getnames=yes;
run;





/*�û��Ķ���*/ 
option compress = yes validvarname = any;
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname orig "F:\TS\offline_model\01_Dataset\01_original";


data target;
set repayFin.payment(where = (12 >= mob > 7)
			keep = ��ƷС�� apply_code Ӫҵ�� ��Ʒ���� od_days od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUN2016'd;	    ***ȡ2016��6�·ݿ�ʼ�ķſ�***;
if ��Ʒ���� = "����" then delete;	***�޳�������Ʒ***;	
if not kindex(��ƷС�� ,"����");     ***�޳�������Ʒ***;	
run;

proc sort data = target nodupkey; by apply_code descending mob; run;
proc sort data = target nodupkey; by apply_code;run;

data orig.target;
set target;
if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***�޳����������Ƴ���ǰ3�ھͿ�ʼ�����Ҳ����ĺ�ͬ����������թ***;
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


proc sort data = orig.target ;by apply_code;run;
proc sort data = tq_test_data;by apply_code;run;

data tp_all_target;
merge tq_test_data(in = a)  orig.target(in = b);
by apply_code;
if a;
run;

data tp_all_target2;
set tp_all_target;
if �ſ��·� ^= "";
/*if target ^= 2;*/
run;

filename export "F:\TS\external_data_test\����\data\ԭʼ_data_�б���..csv" encoding='utf-8';
PROC EXPORT DATA= tp_all_target2 
			 outfile = export
			 dbms = csv replace;
RUN;


***�ƹ����;
data tp_target_tui;
set tp_all_target;
if loan_dt1 >= '29JUL2017'd;
run;

filename export "F:\TS\external_data_test\����\data\tp_target_tui.csv" encoding='utf-8';
PROC EXPORT DATA= tp_all_target 
			 outfile = export
			 dbms = csv replace;
RUN;
