/********************************************************************************************/
/* Revised log																				*/
/* 2017-12-08, �½�, Huangdengfeng  						   								    */
/*																							*/
/********************************************************************************************/

option compress = yes validvarname = any;

/*-----------------------------------------
������Ҫ�õ���������Դ�߼��⣨input libname��
�ʹ������ɵ����ݴ洢�߼��⣨output libname��
-----------------------------------------*/
/*---input libname---*/
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";
/*---output libname---*/
libname orig "F:\TS\offline_model\01_Dataset\01_original";

/*-----------------------------------------------------
���߼���repay���payment��ȡ��ͬ�Ļ��������
------------------------------------------------------*/
/*---��Զ�˰�������set��������ʡ����target���������ʱ��ʱ��---*/
data payment;
set repayFin.payment;
run;

%let month = '201801';

data orig.target;
set payment(where = (month = &month. and mob > 7)
			keep = �ʽ����� ��ƷС�� apply_code Ӫҵ�� ��Ʒ���� od_days od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUN2016'd;	***ȡ2016��6�·ݿ�ʼ�ķſ�***;
if ��Ʒ���� = "����" then delete;	***�޳�������Ʒ***;	
if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***�޳����������Ƴ���ǰ3�ھͿ�ʼ�����Ҳ����ĺ�ͬ����������թ***;
if Ӫҵ�� in ("�����е�һӪҵ��","����е�һӪҵ��","���ͺ����е�һӪҵ��") then delete;    ***�޳���������壬���ͺ���Ӫҵ������;
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***��������ڣ�����ʵ�Ļ���������һ������***;

if not kindex(��ƷС�� ,"����");

************************************
Bad   ���� ��������30������
Good  ���� ��������ڴ���5����ǰ������Ǵ���5�������ڻ����Ǵ���7���� ��ǰδ���� �� ������������С��8���ŵ�˴߻أ�
Indet ���� ����
************************************;
format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;


proc tabulate data = orig.target;
class ��Ʒ���� Ӫҵ�� target_label �ſ��·�;
var sample;
table (��Ʒ���� ALL), �ſ��·� ALL;
run;


proc tabulate data = orig.target;
class ��Ʒ���� Ӫҵ�� target_label �ſ��·�;
var sample;
table (��Ʒ���� ALL)*(target_label ALL), �ſ��·� ALL;
table (��Ʒ���� ALL)*(target_label ALL), (�ſ��·� ALL)*sample*(sum*f=8. pctn<target_label ALL>)/misstext='0' box="��Ʒ����_�û��ֲ�";
table (Ӫҵ�� ALL)*(target_label ALL), (�ſ��·� ALL)*sample*(sum*f=8. pctn<target_label ALL>)/misstext='0' box="Ӫҵ��_�û��ֲ�";
keylabel sum='#' pctn='%';
run;


proc sql;
create table model_data as
select �ſ��·�,count(*) as �ſ��� from orig.target group by �ſ��·� ��Ʒ����;
quit;


data tt;
set orig.target;
if target = 0 then Good=1;
if target = 1 then Bad=1;
if target = 2 then Indet=1;
run;

proc sql;
create table gbi as
select �ſ��·�,sum(Bad) as ���ͻ�, sum(Good) as �ÿͻ�, sum(Indet) as �м�ͻ�  from tt group by �ſ��·�;
run;


/**********************************************�ָ���************************************************/



/*-----------------------------------------------------
������һЩ��ʱ�ԵĴ������ʷ���룬����ʱ����ע�͵���
------------------------------------------------------*/
/*---�ȳ��Կ������������---*/
/*proc freq data = orig.target;*/
/*table ��Ʒ����;*/
/*table Ӫҵ��;*/
/*table �ſ��·�;*/
/*table es;*/
/*table settled;*/
/*table �ʽ�����;*/
/*run;*/
/*proc freq data = target(where = (target^=2));*/
/*table target;*/
/*run;*/
/**/
/*data a;*/
/*set target;*/
/*if ���� = 1;*/
/*run;*/
/*proc tabulate data = a;*/
/*class ���� �ſ��·�;*/
/*table �ſ��·�, ����;*/
/*run;*/
/*data a;*/
/*set orig.target;*/
/*if index(Ӫҵ��,"���") or index(Ӫҵ��,"���ͺ���") or index(Ӫҵ��,"����") then delete;*/
/*run;*/
/*proc tabulate data = a;*/
/*class target_label �ſ��·�;*/
/*var sample;*/
/*table (target_label ALL), (�ſ��·� ALL)*sample*(sum*f=8. pctn<target_label ALL>)/misstext='0' box="�û��ֲ�";*/
/*keylabel sum='#' pctn='%';*/
/*run;*/
/**/
/******************************/
/*�û����壺*/
/*1.��Repay_analysis_vintage�ܳ�����payment��������ծȨת��������ת�ú���º�ͬ�Ļ��������ƴ�ӵ�ԭ��ͬ��*/
/*2.�����ڶ�Ϊ9��*/
/*3.��������30�����϶���Ϊ������ǰδ�������������ڲ�����7�춨��Ϊ�ã���������Ϊ��ȷ��*/
/*************************;*/
/*data des.target;*/
/*set repayfin.payment(keep = apply_code ��Ʒ���� mob �ſ��·� od_days_ever od_days ���� where = (mob = 9 and ��Ʒ���� ^= "����"));*/
/*format target_label $20.;*/
/*	 if od_days_ever > 30 then do; bad = 1; target_label = "bad"; end;*/
/*else if od_days = 0 and od_days_ever <= 7 then do; bad = 0; target_label = "good"; end;*/
/*else do; bad = 0; target_label = "indet"; end;*/
/*total = 1;*/
/*run;*/
/*proc freq data = target;*/
/*table bad;*/
/*run;*/




%let month = '201801';

data data;
set payment(where = (month = &month. and mob > 7)
			keep = �ʽ����� ��ƷС�� apply_code Ӫҵ�� ��Ʒ���� od_days od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);

if LOAN_DATE >= '01JUN2016'd;	***ȡ2016��6�·ݿ�ʼ�ķſ�***;
if ��Ʒ���� = "����" then reloan = 1;	***�޳�������Ʒ***;	
if cut_date - loan_date - od_days_ever <= 90 then fraud = 1;	***�޳����������Ƴ���ǰ3�ھͿ�ʼ�����Ҳ����ĺ�ͬ����������թ***;
if Ӫҵ�� in ("�����е�һӪҵ��","����е�һӪҵ��","���ͺ����е�һӪҵ��") then Ӫҵ_delete = 1;
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***��������ڣ�����ʵ�Ļ���������һ������***;

if not kindex(��ƷС�� ,"����");


format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;

proc sql;
create table delete_data as
select �ſ��·�,count(*) as �ſ��� , sum(reloan) as reloan_cus, sum(fraud) as fraud_cus, sum(Ӫҵ_delete) as Ӫҵ_delete from data group by �ſ��·�;
quit;
