option compress = yes validvarname = any;

libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname daily "D:\mili\offline\daily";


/*������ȡ��700�����ҵ�������������;
ʱ��ά��Ϊ2017/5/1 - 2017/6/31*/
************************************
Bad   ���� ��������30������
Good  ���� ��������ڴ���5����ǰ������Ǵ���5�������ڻ����Ǵ���7���� ��ǰδ���� �� ������������С��8���ŵ�˴߻أ�
Indet ���� ����
************************************;

data payment;
set repayFin.payment;
run;

%let month = '201801';

data target;
set payment(where = (month = &month. and mob > 6)
			keep = �ͻ����� ���֤���� BORROWER_TEL_ONE  apply_code  od_days ��ƷС�� od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01MAY2017'd;	***ȡ2016��6�·ݿ�ʼ�ķſ�***;
/*if ��Ʒ���� = "����" then delete;	***�޳�������Ʒ***;	*/
/*if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***�޳����������Ƴ���ǰ3�ھͿ�ʼ�����Ҳ����ĺ�ͬ����������թ***;*/
/*if Ӫҵ�� in ("�����е�һӪҵ��","����е�һӪҵ��","���ͺ����е�һӪҵ��") then delete;    ***�޳���������壬���ͺ���Ӫҵ������;*/
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***��������ڣ�����ʵ�Ļ���������һ������***;

if not kindex(��ƷС�� ,"����");

format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;

proc sql;
create table model_data as
select �ſ��·�,count(*) as �ſ��� from target group by �ſ��·� ;
quit;

data tt;
set target;
if target = 0 then Good=1;
if target = 1 then Bad=1;
if target = 2 then Indet=1;
run;

proc sql;
create table gbi as
select �ſ��·�,sum(Bad) as ���ͻ�, sum(Good) as �ÿͻ�, sum(Indet) as �м�ͻ�  from tt group by �ſ��·�;
run;

data target_g;
set target(keep = apply_code �ͻ����� ���֤���� BORROWER_TEL_ONE target);
if target ^= 2;
rename BORROWER_TEL_ONE = �绰����;
run;
proc sort data = target_g nodupkey;by apply_code;run;
/*ƴ����������*/
data apply_time;
set daily.daily_acquisition(keep = APPLY_CODE ��������);
run;
proc sort data = apply_time nodupkey;by apply_code;run;

data target_gg;
merge target_g(in=a) apply_time(in=b);
if a;
by apply_code;
run;

filename export "F:\TS\external_data_test\�����Ƽ�\data\target_old.csv" encoding='utf-8';
PROC EXPORT DATA= target_gg 
			 outfile = export
			 dbms = csv replace;
RUN;



/*�ڶ���������*/
libname daily "D:\mili\offline\daily";
libname cred "D:\mili\offline\offlinedata\credit";
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*������ȡ��300�����ҵ�������������;
ʱ��ά��Ϊ2018/1/1-2018/1/14*/
************************************
Bad   ���� ����֮���Զ��ܾ��Ŀͻ�
Good  ���� �Ѿ��ſ�Ŀͻ�
Indet ���� ����
************************************;

/*�Զ��ܾ��Ŀͻ�*/
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(1,1,2018);
dt_end=mdy(1,13,2018);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***ȡ2018��1��24�շݿ�ʼ�ķſ�***;
if auto_reject_time <= &dt_end.;	***ȡ2018��1��25�շݽ����ķſ�***;
run;


/*�Ѿ��ſ�Ŀͻ�*/
data make_loan_good;
set daily.daily_acquisition(keep = APPLY_CODE �ſ�״̬ �ſ����� ID_CARD_NO);
if �ſ�״̬ = "�ѷſ�";
if �ſ����� >= '1JAN2018'd;
if �ſ����� <= '13JAN2018'd;
run;

data test;
set auto_reject_bad  make_loan_good;
run;
proc sort data= test nodupkey ;by apply_code;run;


data apply_base;
set approval.apply_base(keep = apply_code ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;

data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;


data test_bb;
merge test(in = a) com_res_info(in = b) apply_base(in = c);
by apply_code;
if a ;
run;

data recent_test;
set test_bb(keep = APPLY_CODE NAME �ſ�״̬ ID_CARD_NO PHONE1);
rename  ID_CARD_NO = ���֤����   PHONE1 = �绰����;
if �ſ�״̬ = "�ѷſ�" then y = 0;
else y = 1;
run;

/*ƴ����������*/
data apply_time;
set daily.daily_acquisition(keep = APPLY_CODE ��������);
run;
proc sort data = apply_time nodupkey;by apply_code;run;

data recent_gg;
merge recent_test(in=a) apply_time(in=b);
if a;
by apply_code;
run;


filename export "F:\TS\external_data_test\�����Ƽ�\data\recent_gg.csv" encoding='utf-8';
PROC EXPORT DATA= recent_gg 
			 outfile = export
			 dbms = csv replace;
RUN;



