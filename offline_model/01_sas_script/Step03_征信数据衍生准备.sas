option compress=yes validvarname=any;
option missing = 0;

libname approval "D:\mili\offline\offlinedata\approval";
libname centre "D:\mili\offline\centre_data\daily";
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
libname cred "D:\mili\offline\offlinedata\credit";
libname output "F:\TS\offline_model\database\data";
/*---output libname---*/
libname orig "F:\TS\offline_model\01_Dataset\01_original";


/*---------------------------------------------------------------------------*/
*��ѯԭ�ɣ�	
    query	    ��ѯ
	cardquery	���ÿ�����
	loquery	    ��������
	selfquery	���˲�ѯ
	selfquery5	���˲�ѯ(����������������Ϣ����ƽ̨)
	selfquery6	���˲�ѯ���ٹ�
	insurquery	��ǰ���
	manaquery	�������

ʱ�䣺	
    in1m	��1����
	in3m	��3����
	in6m	��6����
	in12m	��12����
	in24m	��24��

������	
    f	            �Ĵ���
	def	            ���Ĵ�������
	com	            ��˾
	prettyloan	    С�����
	webank	        ΢������
	consumerfinance	���ѽ���

�����	
    num				����
	max				���ֵ
	min				��Сֵ
	interval		ʱ����
	rate			��ֵ;
/*---------------------------------------------------------------------------*/


/*�������� ���Ƶ��ڲ�ѯ����*/
/*proc sort data=cred.credit_derived_data out =credit_derived_data nodupkey; by report_number; run; */
proc sort data=cred.credit_query_record out=credit_query_record; by report_number; run; /*��ѯ��ϸ���ϱ�������*/
proc sort data=cred.credit_info_base out=credit_info_base nodupkey; by report_number; run;
proc sort data=cred.credit_detail out = credit_detail;by report_number ;run;


data credit_query_record_info;
merge credit_query_record(in=a) credit_info_base(in=b);
by report_number;
if a;
*����"����"��ʱ��;
if query_date >= intnx("month", report_date, -1, "same") then in1month = 1; else in1month = 0;  /*��1����*/
if query_date >= intnx("month", report_date, -3, "same") then in3month = 1; else in3month = 0;  /*��2����*/
if query_date >= intnx("month", report_date, -6, "same") then in6month = 1; else in6month = 0;  /*��6����*/
if query_date >= intnx("month", report_date, -12, "same") then in12month = 1; else in12month = 0; /*��12����*/
if query_date >= intnx("month", report_date, -24, "same") then in24month = 1; else in24month = 0; /*��24����*/

run;

*********************************************************************
    REASON_1(1,"��������"),
    REASON_2(2,"���ÿ�����"),
    REASON_3(3,"�����ʸ����"),
    REASON_4(4,"�������"),
    REASON_5(5,"���˲�ѯ���ٹ�"),
    REASON_6(6,"���˲�ѯ(����������������Ϣ����ƽ̨)"),
    REASON_7(7,"��Լ�̻�ʵ�����"),
    REASON_8(8,"��ǰ���"),
    REASON_9(9,"�ͻ�׼���ʸ����"),
    REASON_10(10,"�������"),

*********************************************************************;

/*��3�²�ѯ����1:ϵͳ�߼�;*/
/*data query_in3m_1;*/
/*set crRaw.credit_derived_data(keep = REPORT_NUMBER LOAN_GUARANTEE_QUERY_03_MONTH_FR SELF_QUERY_03_MONTH_FREQUENCY_SA);*/
/*��3���²�ѯ���� = LOAN_GUARANTEE_QUERY_03_MONTH_FR + SELF_QUERY_03_MONTH_FREQUENCY_SA;*/
/*run;*/
/*��3�²�ѯ����1:ͬһ���ڵı��˲�ѯ����һ�Σ�ͬһ����1�������ظ���ѯ������һ�δ����ѯ����;*/


/*���˲�ѯ���ٹ�;���˲�ѯ(����������������Ϣ����ƽ̨)*/
data self_query;
set credit_query_record_info(where = (QUERY_REASON in ("5", "6")));
run;
proc sort data = self_query nodupkey; by report_number query_date; run;

proc sql;
create table self_query_in3m as
select report_number,
	   sum(in3month) as selfquery_in3m,
	   sum(in1month) as selfquery_in1m,
	   sum(in6month) as selfquery_in6m,
	   sum(in12month) as selfquery_in12m,
	   sum(in24month) as selfquery_in24m

from self_query
group by report_number
;
quit;

/*���Ų�ѯ��¼*/
data credit_query;
set credit_query_record_info;
length ��ѯ���� $50;
if index(QUERY_ORG, "/") then ��ѯ���� = scan(QUERY_ORG, 1, "/"); else ��ѯ���� = QUERY_ORG;
run;
proc sort data = credit_query; by report_number ��ѯ���� descending query_date; run;

data credit_query_organ;
set credit_query;
by report_number ��ѯ����;
format query_dt yymmdd10.;
retain query_dt;
	 if first.��ѯ���� then query_dt = query_date;   /*�Ե�һ�ε�һ�һ����Ĳ�ѯʱ��Ϊ׼*/
else if intck("day", query_date, query_dt) <= 30 then del = 1; /*intck���������������ڼ��С��30�����Ϊ1*/
else query_dt = query_date;
run;

/*��������;�����ʸ����;��ǰ���*/
data query_safe_guarantee_183;
set credit_query_organ(where = (QUERY_REASON in ("1", "8", "3")));
run;

proc sql;
create table loan_query_in3m as
select report_number,
		sum(in1month) as loan_query_in1m,
		sum(in3month) as loan_query_in3m,
		sum(in6month) as loan_query_in6m,
		sum(in12month) as loan_query_in12m,
		sum(in24month) as loan_query_in24m
from query_safe_guarantee_183
where del ^= 1
group by report_number
;
quit;

proc sort data = cred.credit_report out = credit_report nodupkey; by report_number; run;
proc sort data = self_query_in3m nodupkey; by report_number; run;
proc sort data = loan_query_in3m nodupkey; by report_number; run;

data query_in3m1;
merge credit_report(in = a) self_query_in3m(in = e) loan_query_in3m(in = f);
by report_number;
if a;
query_in3m_1 = sum(selfquery_in3m,loan_query_in3m,0);
query_in1m = sum(selfquery_in1m,loan_query_in1m,0);
query_in12m = sum(selfquery_in12m,loan_query_in12m,0);
query_in6m = sum(selfquery_in6m,loan_query_in6m,0);
query_in24m = sum(selfquery_in24m,loan_query_in24m,0);

format ���Ż�ȡʱ�� yymmdd10.;

���Ż�ȡʱ�� = datepart(created_time);
drop created_time ;
run;


/*���˲�ѯ*/

/*REASON_5(5,"���˲�ѯ���ٹ�"),*/
/*data self_query;*/
/*set credit_query_record(where = (QUERY_REASON in ("5", "6")));*/
/*run;*/
/*proc sort data = self_query nodupkey; by report_number query_date; run;*/

proc sql;
create table self_query_in3m_5 as
select report_number,
		sum(in1month) as selfquery5_in1m,
		sum(in3month) as selfquery5_in3m,
		sum(sum(in6month),-sum(in3month)) as selfquery5_inl3m,
		sum(in6month) as selfquery5_in6m,
		sum(in12month) as selfquery5_in12m,
		sum(in24month) as selfquery5_in24m
from self_query(where=(QUERY_REASON="5"))
group by report_number;
quit;
proc sql;
create table self_query_in3m_6 as
select report_number,
		sum(in1month) as selfquery6_in1m,
		sum(in3month) as selfquery6_in3m,

		sum(in6month) as selfquery6_in6m,
		sum(sum(in6month),-sum(in3month)) as selfquery6_inl3m,

		sum(in12month) as selfquery6_in12m,
		sum(in24month) as selfquery6_in24m
from self_query(where=(QUERY_REASON="6"))
group by report_number;
quit;
/*���˲�ѯ������*/
/*data self_query_weekday;*/
/*set self_query;*/
/*by report_number;*/
/*if first.report_number then do;week = weekday(query_date);end;*/
/*else do;delete;end;*/
/*if  in1month = 1 then max_time = 1;*/
/*else if in3month =1 then max_time =2;*/
/*else if in6month =1 then max_time =3;*/
/*else if in12month =1 then max_time =4;*/
/*else if in24month =1 then max_time =5;*/
/*else  max_time=0;*/
/*run;*/

/*��������±��˲�ѯ���ʱ����������(interval)*/
data self_query_interval;
set self_query(where=(in3month=1));
by report_number;
retain interval time;

if first.report_number then do;interval=. ;time = query_date;end;
else do; interval = intck("day",time,query_date);time=query_date;end;

drop time;
run;

/*��������±��˲�ѯ���ʱ����*/
proc sql;
create table  self_query_in3m_interval as 
select report_number,
min(interval) as selfquery_in3m_min_interval,
max(interval) as selfquery_in3m_max_interval 
from self_query_interval 
group by report_number;
quit;

data self_query_in3m;
merge self_query_in3m_interval self_query_in3m_5 self_query_in3m_6;
by report_number;
run;


/**/
/*proc sql;*/
/*create table loan_query_in3m as*/
/*select report_number,*/
/*		sum(in1month) as loan_query_in1m,*/
/*		sum(in3month) as loan_query_in3m,*/
/*		sum(in6month) as loan_query_in6m,*/
/*		sum(in12month) as loan_query_in12m,*/
/*		sum(in24month) as loan_query_in24m*/
/*from query_safe_guarantee where del ^= 1 and QUERY_REASON="1"*/
/*group by report_number*/
/*;*/
/*quit;*/

/*��������*/
data test;
set credit_query_organ(where = (QUERY_REASON in ("1")));
format ��ѯ�������� $10.;
if kindex(��ѯ����,"ũ������") or kindex(��ѯ����,"��������") or kindex(��ѯ����,"ũ����ҵ����") or kindex(��ѯ����,"ũ���������") then  do;��ѯ����="ũ���������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"�ɶ�����") then do; ��ѯ����="�ɶ�����" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"��ɳ����")  or kindex(��ѯ����,"��ɳ����ҵ����") then do; ��ѯ����="��ɳ����" ;��ѯ��������="����"; ��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"��ݸ����") then do; ��ѯ����="��ݸ����" ;��ѯ��������="����"; ��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"������Ͽ����") then do; ��ѯ����="������Ͽ����" ;��ѯ��������="����";��ѯ��������="����"; ��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"�㶫����") then do; ��ѯ����="�㶫��������" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"�㶫��������") then do; ��ѯ����="�㶫��������" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"�㷢����") then do; ��ѯ����="�㷢����" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"����������") then do; ��ѯ����="����������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"�������") then do; ��ѯ����="�������" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"���ճ�����ҵ����") then do; ��ѯ����="���ճ�����ҵ����" ;��ѯ��������="����";��ѯ����С��="�ط�����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"�й�������������") then do; ��ѯ����="�й�������������" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"�й�����") then do; ��ѯ����="�й�����" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"�й�ũҵ����") then do; ��ѯ����="�й�ũҵ����" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"�й���������") then do; ��ѯ����="�й���������" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"�й���������") then do; ��ѯ����="�й���������" ;��ѯ��������="����";��ѯ����С��="��������";end ;
if kindex(��ѯ����,"�й��������") then do; ��ѯ����="�й��������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"�й���������") then do; ��ѯ����="�й���������" ;��ѯ��������="����";end ;
if kindex(��ѯ����,"��������") then do; ��ѯ����="��������" ;��ѯ��������="����";end ;
/*if kindex(��ѯ����,"����") then ��ѯ��������="����"; */
if kindex(��ѯ����,"С�����") then ��ѯ��������="С�����"; 
if kindex(��ѯ����,"����") then ��ѯ��������="����"; 
if kindex(��ѯ����,"���ѽ���") then ��ѯ��������="���ѽ���"; 
if kindex(��ѯ����,"��������") then ��ѯ��������="��������"; 
if kindex(��ѯ����,"����") then ��ѯ��������="����"; 
if kindex(��ѯ����,"����") then ��ѯ��������="����"; 
if kindex(��ѯ����,"����") then ��ѯ��������="�������޹�˾"; 
if kindex(��ѯ����,"����") then ��ѯ��������="����"; 
if kindex(��ѯ����,"΢��") then ��ѯ��������="΢������"; 

if kindex(��ѯ����,"ס��������") then ��ѯ��������="ס��������"; 
if kindex(��ѯ����,"�к�ũ����Ŀ�������޹�˾") or kindex(��ѯ����,"����С����Ϣ��������") then ��ѯ��������="�Ŵ�"; 
if ��ѯ��������="" then ��ѯ��������="����" ; 
/*ũ�����ú�������*/
run;

/*�����ֲ�*/
proc freq data = test;
table ��ѯ����;
run;
/*proc freq data=test noprint;*/
/*table ��ѯ����/out=cac;*/
/*run;*/

/*΢������*/
data webank ;
set credit_query_organ(where=(kindex(��ѯ����,"΢��")));
run;

proc sql;
create table webank_query1 as 
             select report_number,
			 sum(in1month) as webank_query_in1m,
			 sum(in3month) as webank_query_in3m,
			 sum(in6month) as webank_query_in6m,
			 sum(in12month) as webank_query_in12m,
			 sum(in24month) as webank_query_in24m

from webank 
group by report_number;
quit;
proc sql;
create table webank_query_qc as 
             select report_number,
			 sum(in1month) as webank_query_qc_in1m,
			 sum(in3month) as webank_query_qc_in3m,
			 sum(in6month) as webank_query_qc_in6m,
			 sum(in12month) as webank_query_qc_in12m,
			 sum(in24month) as webank_query_qc_in24m

from webank(where=(del ^= 1)) 
group by report_number;
quit;
proc sql;
create table webank_query_1 as 
             select report_number,
			 sum(in1month) as webank_loquery_in1m,
			 sum(in3month) as webank_loquery_in3m,
			 sum(in6month) as webank_loquery_in6m,
			 sum(in12month) as webank_loquery_in12m,
			 sum(in24month) as webank_loquery_in24m

from webank(where=(QUERY_REASON ="1")) 
group by report_number;
quit;
proc sql;
create table webank_query_4 as 
             select report_number,
			 sum(in1month) as webank_manaquery_in1m,
			 sum(in3month) as webank_manaquery_in3m,
			 sum(in6month) as webank_manaquery_in6m,
			 sum(in12month) as webank_manaquery_in12m,
			 sum(in24month) as webank_manaquery_in24m

from webank(where=(QUERY_REASON ="4")) 
group by report_number;
quit;
data webank_query;
merge webank_query1  webank_query_1 webank_query_4 webank_query_qc;
by report_number;
run;


/*���ѽ���*/
data consumer_finance ;
set credit_query_organ(where=(kindex(��ѯ����,"���ѽ���")));
run;

proc sql;
create table consumer_finance_query1 as select report_number,
		sum(in1month) as consumerfinance_query_in1m,           /*��1�������ѽ��ڻ�����ѯ����*/
		sum(in3month) as consumerfinance_query_in3m,
		sum(in6month) as consumerfinance_query_in6m,
		sum(in12month) as consumerfinance_query_in12m,
		sum(in24month) as consumerfinance_query_in24m

from consumer_finance group by report_number;quit;

proc sql;
create table consumer_finance_query_1 as select report_number,
		sum(in1month) as consumerfinance_loquery_in1m,        /*��1�������ѽ��ڻ�������������ѯ����*/
		sum(in3month) as consumerfinance_loquery_in3m,  
		sum(in6month) as consumerfinance_loquery_in6m,
		sum(in12month) as consumerfinance_loquery_in12m,
		sum(in24month) as consumerfinance_loquery_in24m

from consumer_finance(where=(QUERY_REASON ="1")) group by report_number;quit;

proc sql;
create table consumer_finance_query_4 as select report_number,
		sum(in1month) as consumerfinance_manaquery_in1m,          /*��1�������ѽ��ڻ�����������ѯ����*/
		sum(in3month) as consumerfinance_manaquery_in3m,
		sum(in6month) as consumerfinance_manaquery_in6m,
		sum(in12month) as consumerfinance_manaquery_in12m,
		sum(in24month) as consumerfinance_manaquery_in24m

from consumer_finance(where=(QUERY_REASON ="4")) group by report_number;quit;

data consumer_finance_query;
merge consumer_finance_query1  consumer_finance_query_1 consumer_finance_query_4;
by report_number;
run;


/*С�����*/
data petty_loan ;
set credit_query_organ(where=(kindex(��ѯ����,"С�����")));
run;

proc sql;
create table petty_loan_query1 as select report_number,
		sum(in1month) as pettyloan_query_in1m,
		sum(in3month) as pettyloan_query_in3m,
		sum(in6month) as pettyloan_query_in6m,
		sum(in12month) as pettyloan_query_in12m,
		sum(in24month) as pettyloan_query_in24m

from petty_loan group by report_number;quit;

proc sql;
create table petty_loan_query_1 as select report_number,
		sum(in1month) as pettyloan_loquery_in1m_1,
		sum(in3month) as pettyloan_loquery_in3m_1,
		sum(in6month) as pettyloan_loquery_in6m_1,
		sum(in12month) as pettyloan_loquery_in12m_1,
		sum(in24month) as pettyloan_loquery_in24m_1

from petty_loan(where=(QUERY_REASON ="1")) group by report_number;quit;

proc sql;
create table petty_loan_query_4 as select report_number,
		sum(in1month) as pettyloan_manaquery_in1m,
		sum(in3month) as pettyloan_manaquery_in3m,
		sum(in6month) as pettyloan_manaquery_in6m,
		sum(in12month) as pettyloan_manaquery_in12m,
		sum(in24month) as pettyloan_manaquery_in24m

from petty_loan(where=(QUERY_REASON ="4")) group by report_number;quit;

data petty_loan_query;
merge petty_loan_query1  petty_loan_query_1 petty_loan_query_4;
by report_number;
run;


/*��ǰ��顢������ÿ�����������*/
proc sort data = credit_query_organ  out = loan_query_com nodupkey;by report_number ��ѯ���� QUERY_REASON;run;
proc sql;
create table card_qurry_com_num as 
select report_number,count(��ѯ����) as cardqurry_com_num 
from loan_query_com(where=(QUERY_REASON ="2")) 
group by report_number;
quit;
proc sql;
create table insur_qurry_com_num as 
select report_number,count(��ѯ����) as insurqurry_com_num
from loan_query_com(where=(QUERY_REASON ="8")) 
group by report_number;
quit;
proc sql;
create table lo_qurry_com_num as 
select report_number,count(��ѯ����) as loqurry_com_num
from loan_query_com(where=(QUERY_REASON ="1")) 
group by report_number;quit;
proc sql;
create table num_petty_loan as 
select report_number,count(��ѯ����) as num_pettyloan 
from loan_query_com(where=(QUERY_REASON ="1" and kindex(��ѯ����,"С�����"))) 
group by report_number;quit;

data num_com;
merge card_qurry_com_num insur_qurry_com_num num_petty_loan lo_qurry_com_num;
by report_number;
run;

/*ͬһ�һ����Ĳ�ѯ*/
proc sql;
create table com_same_loan  as 
select report_number,��ѯ����,QUERY_REASON,count(��ѯ����) as com_querry_num
from credit_query_organ 
group by report_number,��ѯ����,QUERY_REASON;
quit;
/*ת������*/
proc transpose data = com_same_loan(where=(QUERY_REASON in ("1","2","8"))) out = com_same_loan1 prefix=D;
id QUERY_REASON;
var com_querry_num;
by  report_number ��ѯ����;
run;
/*��ѯ�������������������ֵ*/
proc sql;
create table com_same_loan2 as 
		select  report_number,
		max(D1) as com_loqurry_num,
		max(D2) as com_locard_num,
		max(D8) as same_com_insur_qurry_num 
from com_same_loan1
group by report_number;
quit;


/*��������*/
proc sql;
create table com_same_loan_in3m  as 
			 select report_number,
			 ��ѯ����,
			 QUERY_REASON,
			 count(��ѯ����) as com_querry_num
from credit_query_organ(where=(in3month=1)) 
group by report_number,��ѯ����,QUERY_REASON;
quit;

/*��ѯ�������������������ֵ*/
proc transpose data = com_same_loan_in3m(where=(QUERY_REASON in ("1","2","8"))) out = com_same_loan1_in3m prefix=D;
id QUERY_REASON;
var com_querry_num;
by  report_number ��ѯ����;
run;
/*��ѯ�������������������ֵ*/
proc sql;
create table com_same_loan2_in3m as 
			 select  report_number,
			 max(D1) as same_com_lo_qurry_num_3m ,
			 max(D2) as same_com_lo_card_num_3m ,
			 max(D8) as same_com_insur_qurry_num_3m 
from com_same_loan1_in3m
group by report_number;
quit;

data com_same_loan_num;
merge  com_same_loan2 com_same_loan2_in3m ;
by report_number;
run;


/*���ÿ���������*/
data card_qurry;
set credit_query_organ(where = (QUERY_REASON ="2"));
run;
proc sql;
create table card_query_in3m as
select report_number,
		sum(in1month) as card_query_in1m,
		sum(in3month) as card_query_in3m,
		sum(in6month) as card_query_in6m,
		sum(in12month) as card_query_in12m,
		sum(in24month) as card_query_in24m
from card_qurry(where=(del^=1))
group by report_number;
quit;
proc sql;
create table card_query_in3m_max_1 as
select report_number,��ѯ����,
		sum(in1month) as card_query_in1m,
		sum(in3month) as card_query_in3m,
		sum(in6month) as card_query_in6m,
		sum(in12month) as card_query_in12m,
		sum(in24month) as card_query_in24m
from card_qurry
group by report_number,��ѯ����;
quit;
proc sql;
create table card_query_in3m_max as
select report_number,
		max(card_query_in1m) as card_query_in1m_max,
		max(card_query_in3m) as card_query_in3m_max,
		max(card_query_in6m) as card_query_in6m_max,
		max(card_query_in12m) as card_query_in12m_max,
		max(card_query_in24m) as card_query_in24m_max
from card_query_in3m_max_1
group by report_number;
quit;

/*�������*/
data management_loan;
set credit_query_organ(where = (QUERY_REASON ="4"));
run;
proc sql;
create table mana_loan_in3m as
select report_number,
		sum(in1month) as mana_loan_in1m,
		sum(in3month) as mana_loan_in3m,
		sum(in6month) as mana_loan_in6m,
		sum(in12month) as mana_loan_in12m,
		sum(in24month) as mana_loan_in24m
from management_loan
group by report_number;
quit;

proc sql;
create table mana_loan_f as
select report_number,
		sum(in1month) as mana_loan_in1m_f,
		sum(in3month) as mana_loan_in3m_f,
		sum(in6month) as mana_loan_in6m_f,
		sum(in12month) as mana_loan_in12m_f,
		sum(in24month) as mana_loan_in24m_f
from management_loan(where=(index(��ѯ����,"�й�����") or index(��ѯ����,"�й���������") 
or index(��ѯ����,"�й�ũҵ����")  or index(��ѯ����,"�й���������")))
group by report_number;
quit;

proc sort data = mana_loan_in3m;by report_number;run;
proc sort data = mana_loan_f;by report_number;run;

data mana_loan_in3m;
merge mana_loan_in3m mana_loan_f;
by report_number;
mana_loan_in1m_de_f = sum(mana_loan_in1m, -mana_loan_in1m_f);
mana_loan_in3m_de_f = sum(mana_loan_in3m, -mana_loan_in3m_f);
mana_loan_in6m_de_f = sum(mana_loan_in6m, -mana_loan_in6m_f);
mana_loan_in12m_de_f = sum(mana_loan_in12m, -mana_loan_in12m_f);
mana_loan_in24m_de_f = sum(mana_loan_in24m, -mana_loan_in24m_f);

run;


/*������������*/
data insur_qurry;
set credit_query_organ(where = (QUERY_REASON in("8")));
run;

proc sql;
create table insur_query_in3m as
select report_number,
		sum(in1month) as insur_query_in1m,
		sum(in3month) as insur_query_in3m,
		sum(in6month) as insur_query_in6m,
		sum(in12month) as insur_query_in12m,
		sum(in24month) as insur_query_in24m

from insur_qurry
group by report_number;
quit;

/*������������*/
data lo_qurry;
set credit_query_organ(where = (QUERY_REASON ="1"));
run;

proc sql;
create table lo_query_in3m as
select report_number,
		sum(in1month) as lo_query_in1m,
		sum(in3month) as lo_query_in3m,
		sum(in6month) as lo_query_in6m,
		sum(in12month) as lo_query_in12m,
		sum(in24month) as lo_query_in24m
from lo_qurry(where=(del^=1))
group by report_number;
quit;

proc sql;
create table lo_query_f as
select report_number,
		sum(in1month) as lo_query_in1m_f,
		sum(in3month) as lo_query_in3m_f,
		sum(in6month) as lo_query_in6m_f,
		sum(in12month) as lo_query_in12m_f,
		sum(in24month) as lo_query_in24m_f
from lo_qurry( where=((del^=1) and (index(��ѯ����,"�й�����")  or index(��ѯ����,"�й���������") 
or index(��ѯ����,"�й�ũҵ����") or index(��ѯ����,"�й���������"))))
group by report_number;
quit;
proc sort data = lo_query_in3m;by report_number;run;
proc sort data = lo_query_f;by report_number;run;

data lo_query_in3m;
merge lo_query_in3m lo_query_f;
by report_number;
lo_query_in1m_de_f = sum(lo_query_in1m,-lo_query_in1m_f);
lo_query_in3m_de_f = sum(lo_query_in3m,-lo_query_in3m_f);
lo_query_in6m_de_f = sum(lo_query_in6m,-lo_query_in6m_f);
lo_query_in12m_de_f = sum(lo_query_in12m,-lo_query_in12m_f);
lo_query_in24m_de_f = sum(lo_query_in24m,-lo_query_in24m_f);

run;


/*/*���3�²�ѯ����2: ������������ǰ��顢�����ʸ���顢���˲�ѯ*/*/
/*proc sql;*/
/*create table query_in3m_2 as*/
/*select report_number,*/
/*		sum(in3month) as query_in3m_2*/
/*from credit_query_record*/
/*where QUERY_REASON in ("1", "8", "3", "5", "6")*/
/*group by report_number*/
/*;*/
/*quit;*/
/**/
/*/*���3�²�ѯ����3: ������������ǰ��顢�����ʸ���顢���˲�ѯ�����ÿ�����*/*/
/*proc sql;*/
/*create table query_in3m_3 as*/
/*select report_number,*/
/*		sum(in3month) as query_in3m_3*/
/*from credit_query_record*/
/*where QUERY_REASON in ("1", "8", "3", "5", "6", "2")*/
/*group by report_number*/
/*;*/
/*quit;

data record;
merge credit_info_base  credit_detail;
by report_number;
run;

/*���ÿ����*/
data test2;
set record;
if BUSI_TYPE="CREDIT_CARD" and CURRENCY_TYPE = "�����"  then �������ÿ�=1;
else  if BUSI_TYPE="CREDIT_CARD" and CURRENCY_TYPE ^= "�����"  then �������ÿ�=1;
if �������ÿ� then �������ÿ����=CREDIT_LINE_AMT;
if �������ÿ� and ACCT_STATUS in( "11","17")    then ����ʹ���е����ÿ�=1;
else if �������ÿ� and ACCT_STATUS="14" then �������ÿ�=1;
else if �������ÿ� and ACCT_STATUS="15" then �������ÿ�=1;
else if �������ÿ� and ACCT_STATUS="16" then δ�������ÿ�=1;

if �������ÿ� and ACCT_STATUS="11" then ����ʹ���е����ÿ�=1;
else if  �������ÿ� and ACCT_STATUS="17" then Ŀǰ���ڵ����ÿ�=1;

if ����ʹ���е����ÿ� and PASTDUE_BY60_CNT>0 then ����С��90�������ʹ���е����ÿ�=1;
if ����ʹ���е����ÿ� and PASTDUE_M3_BY60_CNT>0 then ���ڴ���90�������ʹ���е����ÿ�=1;
if  PASTDUE_BY60_CNT>0 then ����С��90������ÿ�=1;
if  PASTDUE_M3_BY60_CNT>0 then ���ڴ���90������ÿ�=1;

if intck ("year",DATE_OPENED,REPORT_DATE)<=2 and �������ÿ� then �����꿪�����ÿ�=1;
ʱ����=intck ("year",DATE_OPENED,REPORT_DATE);

if kindex(ORG_NAME,"�й�����") or index(ORG_NAME,"�й���������") 
or index(ORG_NAME,"�й�ũҵ����")  or index(ORG_NAME,"�й���������") then �Ĵ��ж��=CREDIT_LINE_AMT;

run;

proc sql;
create table card_info  as 
select report_number,
sum(�������ÿ�) as credit_card_num_cn,
sum(�������ÿ�) as credit_card_num_fo,
sum(����ʹ���е����ÿ�)as use_credit_card_numb,
sum(�������ÿ�) as can_card_num,
sum(�������ÿ�)/count(*)as can_card_rate, 
sum(δ�������ÿ�) as inac_card_num,
sum(δ�������ÿ�)/count(*) as inac_card_rate ,
sum(�������ÿ�) as bad_card_num,
sum(�������ÿ�)/sum(�������ÿ�) as bad_card_rate,
sum(����ʹ���е����ÿ�) as normal_card_num,
sum(Ŀǰ���ڵ����ÿ�) as pres_overdue_num,
sum(Ŀǰ���ڵ����ÿ�)/sum(����ʹ���е����ÿ�) as pres_overdue_card_rate,
count(����С��90������ÿ�)/sum(�������ÿ�) as his_overdue_card_rate, 
count(����С��90������ÿ�) as his_overdue_card_num ,
sum(�����꿪�����ÿ�) as near_2y_card_num,
max(�������ÿ����) as max_card_line,
mean(�������ÿ����) as mean_card_line,
min(�������ÿ����)as min_card_line,
var(�������ÿ����)as var_card_line,
max(�Ĵ��ж��) as max_card_line_bf,
min(�Ĵ��ж��) as min_card_line_bf,
mean(�Ĵ��ж��) as mean_card_line_bf,
var(�Ĵ��ж��) as var_card_line_bf

from test2(where=(BUSI_TYPE="CREDIT_CARD")) 
group by report_number;
quit;

/*�������*/
/*ʱ�� ��� ���� ����ԭ�� ����״̬*/
data test3;
set record(where=(BUSI_TYPE="LOAN" ));
if ACCT_STATUS="3" and intck ("month",DATE_OPENED,REPORT_DATE)<=6  then ������������=1;
if ACCT_STATUS="3" and intck ("month",DATE_OPENED,REPORT_DATE)<=12  then ��һ��������=1;
if ACCT_STATUS="3" and intck ("month",DATE_OPENED,REPORT_DATE)<=24  then ������������=1;
if intck ("month",DATE_OPENED,REPORT_DATE)<=24  then ����������=1;

if ACCT_STATUS="3"   then �������=1;
if ACCT_STATUS="1" then δ�������=1;
if ACCT_STATUS="3" and CREDIT_LINE_AMT>1000  then ��Ԫ���Ͻ���=1;
time = intck ("month",DATE_OPENED,REPORT_DATE);
end_time = intck("month",REPORT_DATE,DATE_CLOSED);
if kindex(ORG_NAME,"���ѽ���") then ���ѽ��ڴ���=1;
if ���ѽ��ڴ��� and ACCT_STATUS="3" and CREDIT_LINE_AMT>10000 then  δ�������ѽ��ڴ���=1;
if ����������=1 and kindex(ORG_NAME,"С�����") then С�����=1;
if ������������=1 and kindex(ORG_NAME,"����") then ���н������=1;
if ����������=1 and kindex(ORG_NAME,"΢��") then ΢������=1;
if ����������=1 and kindex(ORG_NAME,"����") then ���д���=1;

if ����������=1 and kindex(ORG_NAME,"�й�����") or 
                   index(ORG_NAME,"�й���������") or 
                   index(ORG_NAME,"�й�ũҵ����")  or 
                   index(ORG_NAME,"�й���������") then �Ĵ��д���=1;
if ����������=1 and kindex(SUB_BUSI_TYPE,"��������") then �������Ѵ���=1;
if ����������=1 and kindex(SUB_BUSI_TYPE,"���˾�Ӫ") then ���˾�Ӫ����=1;
if ����������=1 and kindex(SUB_BUSI_TYPE,"����") then ��������=1;
if ����������=1 and kindex(SUB_BUSI_TYPE,"������������") or 
                    kindex(SUB_BUSI_TYPE,"����ס��") or 
                    kindex(SUB_BUSI_TYPE,"�������÷�") or 
                    kindex(SUB_BUSI_TYPE,"������ѧ����") then ���˸����Ѵ���=1;
run;

/*�������*/
/*-------------------------------------------�����������-------------------------------------*/
data loan_org;
set record(where=(BUSI_TYPE="LOAN" ));
if intck ("month",DATE_OPENED,REPORT_DATE)<=24 and ACCT_STATUS="1";

format ��ѯ�������� $10.;
if kindex(ORG_NAME,"ũ������") or  kindex(ORG_NAME,"��������") or 
								   kindex(ORG_NAME,"ũ����ҵ����") or 
                                   kindex(ORG_NAME,"ũ���������") then  do;��ѯ����="ũ���������" ;��ѯ��������="ũ������";end ;

if kindex(ORG_NAME,"��������") then ��ѯ��������="��������"; 
if kindex(ORG_NAME,"����") then ��ѯ��������="����"; 
if kindex(ORG_NAME,"С�����") then ��ѯ��������="С�����"; 
if kindex(ORG_NAME,"����") then ��ѯ��������="����"; 
if kindex(ORG_NAME,"���ѽ���") then ��ѯ��������="���ѽ���"; 
if kindex(ORG_NAME,"��������") then ��ѯ��������="��������"; 
if kindex(ORG_NAME,"����") then ��ѯ��������="����"; 
if kindex(ORG_NAME,"����") then ��ѯ��������="����"; 
if kindex(ORG_NAME,"����") then ��ѯ��������="�������޹�˾"; 
if kindex(ORG_NAME,"����") then ��ѯ��������="����"; 
if kindex(ORG_NAME,"΢��") then ��ѯ��������="΢������"; 

if kindex(ORG_NAME,"ס��������") then ��ѯ��������="ס��������"; 
if kindex(ORG_NAME,"�к�ũ����Ŀ�������޹�˾") or kindex(��ѯ����,"����С����Ϣ��������") then ��ѯ��������="�Ŵ�"; 
if kindex(ORG_NAME,"��������") then ��ѯ��������="С�����"; 
if kindex(ORG_NAME,"��������") then ��ѯ��������="��������"; 

if ��ѯ��������="" then ��ѯ��������="����" ; 

run;

proc sql;
create table test4  as select report_number ,��ѯ��������,count(*) as ������� from loan_org group by report_number,��ѯ��������;
quit;

proc transpose data = test4 out =aaa(drop=_NAME_);
var �������;
ID ��ѯ��������;
by report_number ;
run;
data aaa1;
set aaa;
run;


/*==================================================end=========================================================*/

proc sql;
create table loan_info_per as 
select report_number,

count(*) as loan_num ,
count(PASTDUE_BY60_CNT) as credit_card_number_l60,
count(PASTDUE_M3_BY60_CNT) as credit_card_number_m90,
count(PASTDUE_M3_BY60_CNT)/count(*)as credit_card_number_m90_rate,
count(PASTDUE_BY60_CNT)/count(*) as credit_card_number_l60_rate,

sum(���ѽ��ڴ���) as consumer_finance_loan_num ,
sum(���˸����Ѵ���) as high_consum_loan_num,
sum(������������) as clear_loan_num_6m ,
sum(��һ��������) as clear_loan_num_12m, 
sum(������������)as clear_loan_num_24m,
sum(�������Ѵ���) as consum_loan_num,
sum(δ�������) as unclear_loan_num,
sum(�������) as clear_loan_num,
sum(С�����) as petty_loan_num,
sum(���˾�Ӫ����) as bus_loan_num,
sum(����������) as loan_num_in24m,
sum(���н������) as ���н������,
sum(��������)as  other_loan_num,
sum(�Ĵ��д���) as �Ĵ��д���,
sum(΢������) as webank_loan,
sum(���д���) as ���д���,

min(time) as near_loan_time,
max(time) as far_loan_time,
max(CREDIT_LINE_AMT) as max_loanline

from  test3 
group by report_number ;
quit;

data loan_info1;
set loan_info_per;
if ���д��� <1  and consumer_finance_loan_num >=1  then �������� =2 ;
else if ���д��� <1  and consumer_finance_loan_num <1  then �������� =0 ;
else if ���д��� >0  and consumer_finance_loan_num <1  then �������� =1 ;
else if ���д��� >0  and consumer_finance_loan_num >=1  then �������� =3 ;

if ���д��� <1  and petty_loan_num >=1  then ����С�� =2 ;
else if ���д��� <1  and petty_loan_num <1  then �������� =0 ;
else if ���д��� >0  and petty_loan_num <1  then �������� =1 ;
else if ���д��� >0  and petty_loan_num >=1  then �������� =3 ;

if ���д��� <1  and  sum(consumer_finance_loan_num,petty_loan_num)  >=1  then �����������Ѵ� =2 ;
else if ���д��� <1  and sum(consumer_finance_loan_num,petty_loan_num) <1  then �������� =0 ;
else if ���д��� >0  and sum(consumer_finance_loan_num,petty_loan_num) <1  then �������� =1 ;
else if ���д��� >0  and sum(consumer_finance_loan_num,petty_loan_num) >=1  then �������� =3 ;

if sum(���д���,webank_loan) <1   then ����΢�� =0 ;else ����΢��=1 ;

run;


proc sql;
create table loan_info1_1 as 
select report_number, sum(CREDIT_LINE_AMT) as new_loan_in12m
from  test3(where=(time<=12)) 
group by report_number ;
quit;

proc sql;
create table loan_info1_2 as 
select report_number, sum(LOAN_BALANCE) as due_cos_loan_balance_in12m
from  test3(where=(end_time<=12)) 
group by report_number ;
quit;

proc sql;
create table loan_info1_3 as 
select report_number, sum(LOAN_BALANCE) as unclear_loan_amount,
sum(MONTHLY_PAYMENT) as umclear_month_pay
from  test3(where=(δ�������=1)) 
group by report_number ;
quit;

proc sql;
create table loan_info2 as 
select report_number,max(CREDIT_LINE_AMT) as max_car_loan_line,
mean(CREDIT_LINE_AMT) as ave_car_loan_line, 
min(time) as near_car_loan  ,
min(CREDIT_LINE_AMT) as min_car_loan_line,
sum(CREDIT_LINE_AMT)  as ��������������
from  test3(where=(kindex(SUB_BUSI_TYPE,"������������") and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;
proc sql;
create table loan_info3 as 
select report_number,max(CREDIT_LINE_AMT) as max_man_loan_line,
mean(CREDIT_LINE_AMT) as ave_man_loan_line
, min(time) as near_man_loan  ,
min(CREDIT_LINE_AMT) as min_man_loan_line,
sum(CREDIT_LINE_AMT)  as ���˾�Ӫ��
from test3(where=(kindex(SUB_BUSI_TYPE,"���˾�Ӫ") and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;
proc sql;
create table loan_info4 as 
select report_number,max(CREDIT_LINE_AMT) as max_house_loan_line,
mean(CREDIT_LINE_AMT) as ave_house_loan_line,
min(time) as near_house_loan ,
min(CREDIT_LINE_AMT) as min_house_loan_line,
sum(CREDIT_LINE_AMT)  as ����ס��
from test3(where=((kindex(SUB_BUSI_TYPE,"����ס��")or kindex(SUB_BUSI_TYPE,"�������÷�")) and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;
proc sql;
create table loan_info4 as 
select report_number,
max(CREDIT_LINE_AMT) as max_percos_loan_line,
mean(CREDIT_LINE_AMT) as ave_percos_loan_line,
min(time) as near_percos_loan ,
min(CREDIT_LINE_AMT) as min_percos_loan_line,
sum(CREDIT_LINE_AMT)  as ��������
from  test3(where=((kindex(SUB_BUSI_TYPE,"��������")) and BUSI_TYPE="LOAN")) 
group by report_number ;
quit;

data loan_info;
merge loan_info1 loan_info1_1 loan_info1_2 loan_info2 loan_info3 loan_info4 loan_info1_3;
by report_number;
run;



/*�����ѯ��δ�ſ�Ļ���������*/
data org_loan;
set record(where=(BUSI_TYPE="LOAN"  ));
if intck ("year",DATE_OPENED,REPORT_DATE)<=2;
/*if kindex(ORG_NAME,"");*/
run;
/*proc sort data = xiaojin_loan nodupkey ;by report_number ORG_NAME;run;*/

proc sql ;
create table not_loan_query_1 as 
select a.*,b.* from lo_qurry as a inner join org_loan as b  on a.report_number = b.report_number and a.��ѯ����=b.ORG_NAME and a.query_dt < b.DATE_OPENED;
quit;
proc sort data = not_loan_query_1 nodupkey;by report_number ��ѯ���� ;run;
proc sql ;
create table loan_query_2 as 
select report_number,count(*) as ���Ŵ����� from not_loan_query_1 group by report_number ;
quit;
/*δ�������ÿ�*/
data org_card;
set record(where=(BUSI_TYPE="CREDIT_CARD"));
if intck ("year",DATE_OPENED,REPORT_DATE)<=2;
/*if kindex(ORG_NAME,"");*/
run;
/*proc sort data = xiaojin_loan nodupkey ;by report_number ORG_NAME;run;*/


proc sql ;
create table not_card_query_1 as 
select a.*,b.* from card_qurry as a inner join org_card as b  on a.report_number = b.report_number and a.��ѯ����=b.ORG_NAME and a.query_dt < b.DATE_OPENED;
quit;
proc sort data = not_card_query_1 nodupkey;by report_number ��ѯ���� ;run;
proc sql ;
create table card_query_2 as 
select report_number,count(*) as �������ÿ��� from not_card_query_1 
group by report_number ;
quit;


proc sort data = self_query_in3m nodupkey; by report_number; run;
proc sort data = loan_query_in3m nodupkey; by report_number; run;
proc sort data = card_query_in3m nodupkey; by report_number; run;
proc sort data = insur_query_in3m nodupkey; by report_number; run;
proc sort data = lo_query_in3m nodupkey; by report_number; run;
proc sort data = mana_loan_in3m nodupkey; by report_number; run;
proc sort data = num_com nodupkey; by report_number; run;

proc sort data = cred.credit_derived_data out =credit_derived_data(keep = REPORT_NUMBER ID_CARD)  nodupkey; by report_number; run;


/*--------------------��������-------------------------*/
data credit_all_data;
merge query_in3m1(in = a)
credit_derived_data(in = b) 
card_query_in3m(in = c) 
/*insur_query_in3m(in = d) */
self_query_in3m(in = e) 
lo_query_in3m(in = f) 
mana_loan_in3m(in = g)  
num_com(in = h)   
card_info(in = i)   
loan_info(in = j)   
loan_query_2(in = k)  
/*webank_query(in = l)  */
consumer_finance_query(in = m)  
petty_loan_query(in = n)  
card_query_in3m_max(in = o)  
card_query_2(in = p) 
com_same_loan_num(in = q)  
; 
by report_number ;
if a;

self_loan_dv_in1m=sum( selfquery_in1m,-lo_query_in1m,0);
self_loan_dv_in3m=sum( selfquery_in3m,-lo_query_in3m,0);
self_loan_dv_in6m=sum( selfquery_in6m,-lo_query_in6m,0);
self_loan_dv_in12m=sum( selfquery_in12m,-lo_query_in12m,0);
self_loan_dv_in24m=sum( selfquery_in24m,-lo_query_in24m,0);
self_card_query_in6m=sum(selfquery_in6m,card_query_in6m,0);
self_card_query_in3m=sum(selfquery_in3m,card_query_in3m,0);
self_card_query_in1m=sum(selfquery_in1m,card_query_in1m,0);
self_card_query_in12m=sum(selfquery_in12m,card_query_in12m,0);
self_card_query_in24m=sum(selfquery_in24m,card_query_in24m,0);
self_loan_query_in6m=sum(selfquery_in6m,lo_query_in6m,0);
self_loan_query_in3m=sum(selfquery_in3m,lo_query_in3m,0);
self_loan_query_in1m=sum(selfquery_in1m,lo_query_in1m,0);
self_loan_query_in12m=sum(selfquery_in12m,lo_query_in12m,0);
self_loan_query_in24m=sum(selfquery_in24m,lo_query_in24m,0);
self_loan_query_de_f_in6m=sum(selfquery_in6m,lo_query_in6m_de_f,0);
self_loan_query_de_f_in3m=sum(selfquery_in3m,lo_query_in3m_de_f,0);
self_loan_query_de_f_in1m=sum(selfquery_in1m,lo_query_in1m_de_f,0);
self_loan_query_de_f_in12m=sum(selfquery_in12m,lo_query_in12m_de_f,0);
self_loan_query_de_f_in24m=sum(selfquery_in24m,lo_query_in24m_de_f,0);
self_loan_card_query_in6m=sum(selfquery_in6m,lo_query_in6m,0,card_query_in6m);
self_loan_card_query_in3m=sum(selfquery_in3m,lo_query_in3m,0,card_query_in3m);
self_loan_card_query_in1m=sum(selfquery_in1m,lo_query_in1m,0,card_query_in1m);
self_loan_card_query_in12m=sum(selfquery_in12m,lo_query_in12m,0,card_query_in12m);
self_loan_card_query_in24m=sum(selfquery_in24m,lo_query_in24m,0,card_query_in24m);
run;

proc sql;
create table orig.credit_query_alldata as
select a.apply_code, b.*
from approval.apply_time as a
inner join credit_all_data as b on a.id_card_no = b.id_card and datepart(a.apply_time) >= b.���Ż�ȡʱ��;
quit;

proc sort data = orig.credit_query_alldata nodupkey; by apply_code descending ���Ż�ȡʱ��; run;

/*�鿴���ݵ�����*/
ods trace on;
proc contents data=orig.credit_query_alldata;
ods output Variables=need_all;
run;
ods trace off;


/*---------------------------------*

/*-----------------------------------------------ֻȡ��Ҫ�Ĳ�ѯ��������-------------------------------------------------------------------------------------------------------*/;
data customer_query_num;
merge query_in3m1(in = a)
credit_derived_data(in = b) 
card_query_in3m(in = c) 
insur_query_in3m(in = d) 
self_query_in3m(in = e) 
lo_query_in3m(in = f) 
mana_loan_in3m(in = g) 
num_com(in = h)   
card_info(in = i)   
loan_info(in = j)  
; 
by report_number ;
if a;
self_loan_dv_in1m=sum( selfquery_in1m,-lo_query_in1m,0);
self_loan_dv_in3m=sum( selfquery_in3m,-lo_query_in3m,0);
self_loan_dv_in6m=sum( selfquery_in6m,-lo_query_in6m,0);
self_loan_dv_in12m=sum( selfquery_in12m,-lo_query_in12m,0);
self_loan_dv_in24m=sum( selfquery_in24m,-lo_query_in24m,0);
self_card_query_in6m=sum(selfquery_in6m,card_query_in6m,0);
self_card_query_in3m=sum(selfquery_in3m,card_query_in3m,0);
self_card_query_in1m=sum(selfquery_in1m,card_query_in1m,0);
self_card_query_in12m=sum(selfquery_in12m,card_query_in12m,0);
self_card_query_in24m=sum(selfquery_in24m,card_query_in24m,0);
self_loan_query_in6m=sum(selfquery_in6m,lo_query_in6m,0);
self_loan_query_in3m=sum(selfquery_in3m,lo_query_in3m,0);
self_loan_query_in1m=sum(selfquery_in1m,lo_query_in1m,0);
self_loan_query_in12m=sum(selfquery_in12m,lo_query_in12m,0);
self_loan_query_in24m=sum(selfquery_in24m,lo_query_in24m,0);
self_loan_query_de_f_in6m=sum(selfquery_in6m,lo_query_in6m_de_f,0);
self_loan_query_de_f_in3m=sum(selfquery_in3m,lo_query_in3m_de_f,0);
self_loan_query_de_f_in1m=sum(selfquery_in1m,lo_query_in1m_de_f,0);
self_loan_query_de_f_in12m=sum(selfquery_in12m,lo_query_in12m_de_f,0);
self_loan_query_de_f_in24m=sum(selfquery_in24m,lo_query_in24m_de_f,0);
self_loan_card_query_in6m=sum(selfquery_in6m,lo_query_in6m,0,card_query_in6m);
self_loan_card_query_in3m=sum(selfquery_in3m,lo_query_in3m,0,card_query_in3m);
self_loan_card_query_in1m=sum(selfquery_in1m,lo_query_in1m,0,card_query_in1m);
self_loan_card_query_in12m=sum(selfquery_in12m,lo_query_in12m,0,card_query_in12m);
self_loan_card_query_in24m=sum(selfquery_in24m,lo_query_in24m,0,card_query_in24m);
run;


proc sql;
create table orig.credit_query_data as
select a.apply_code, b.*
from approval.apply_time as a
inner join customer_query_num as b on a.id_card_no = b.id_card and datepart(a.apply_time) >= b.���Ż�ȡʱ��;
quit;

proc sort data = orig.credit_query_data nodupkey; by apply_code descending ���Ż�ȡʱ��; run;


/*�鿴���ݵ�����*/
ods trace on;
proc contents data=orig.credit_query_data;
ods output Variables=need;
run;
ods trace off;




libname orig "F:\TS\offline_model\01_Dataset\01_original";

/*ǰ�ڲ���IVֵ�Ƚϸߵļ�������*/
data orig.credit_query_alldata2;
set cred.query_in3m(keep = apply_code max_cardline selfquery_cardquery_in6m cardquery_com_num cardquery_card_num_dvalue);
run;















































