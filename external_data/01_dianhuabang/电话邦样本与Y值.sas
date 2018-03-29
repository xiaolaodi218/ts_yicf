option compress = yes validvarname = any;
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";

data payment;
set repayFin.payment;
run;

%let month = '201802';

data target;
set payment(where = (month = &month. and mob > 5)
			keep = apply_code BORROWER_TEL_ONE �ʽ����� ��ƷС��  Ӫҵ�� ��Ʒ���� od_days od_days_ever 
                   month mob �ſ��·� es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUL2017'd;	***ȡ2017��7�·ݿ�ʼ�ķſ�***;
if ��Ʒ���� = "����" then delete;	***�޳�������Ʒ***;	
/*if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***�޳����������Ƴ���ǰ3�ھͿ�ʼ�����Ҳ����ĺ�ͬ����������թ***;*/
/*if Ӫҵ�� in ("�����е�һӪҵ��","����е�һӪҵ��","���ͺ����е�һӪҵ��") then delete;    ***�޳���������壬���ͺ���Ӫҵ������;*/
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
set target(keep = apply_code BORROWER_TEL_ONE target);
rename target = y;
format tel_phone $11.;
tel_phone = "***"||substr(BORROWER_TEL_ONE, 3, 8);
drop BORROWER_TEL_ONE;
run;

filename export "F:\TS\external_data_test\�绰��\ͨ��_���Խ��\data\target_g.csv" encoding='utf-8';
proc export data = target_g
			 outfile = export
			 dbms = csv replace;
run;
