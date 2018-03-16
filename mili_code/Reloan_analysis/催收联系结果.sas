option compress = yes validvarname = any;
option missing = 0;
libname csdata odbc  datasrc=csdata_nf;
libname YY odbc  datasrc=res_nf;

libname DA "F:\�����绰����\csdata";
libname DB "F:\�����绰����\res_nf";
libname DD "F:\�����绰����";
libname repayFin "F:\���������ձ���\data";

data DB.ca_staff;
set yy.ca_staff;
run;

data DB.optionitem;
set yy.optionitem;
run;

data DA.Ctl_call_record;
set csdata.Ctl_call_record;
run;

data DA.Ctl_task_assign;
set csdata.Ctl_task_assign;
run;

data DA.Ctl_loaninstallment;
set csdata.Ctl_loaninstallment;
run;


data _null_;
format dt yymmdd10.;
 dt = today() - 1;
 db=intnx("month",dt,0,"b");
 nd = dt-db;
weekf=intnx('week',dt,0);
call symput("nd", nd);
call symput("db",db);
if weekday(dt)=1 then call symput("dt",dt-2);
else call symput("dt",dt);
call symput("weekf",weekf);
run;

data ca_staff;
set DB.ca_staff;
id1=compress(put(id,$20.));
run;

proc sql;
create table cs_table1(where=( kindex(contract_no,"PL"))) as
select a.CALL_RESULT_ID,a.CALL_ACTION_ID,a.DIAL_TELEPHONE_NO,a.DIAL_LENGTH,a.CONTACTS_NAME,a.PROMISE_REPAYMENT,a.PROMISE_REPAYMENT_DATE,
       a.CREATE_TIME,a.REMARK,c.userName,d.CONTRACT_NO,d.CUSTOMER_NAME
from DA.Ctl_call_record as a 
left join DA.Ctl_task_assign as b on a.TASK_ASSIGN_ID=b.id
left join ca_staff as c on b.emp_id=c.id1
left join DA.Ctl_loaninstallment as d on a.OVERDUE_LOAN_ID=d.id;
quit;

proc sql;
create table cs_table_ta as
select a.*,b.itemName_zh as RESULT from cs_table1 as a
left join DB.optionitem(where=(groupCode="CSJL")) as b on a.CALL_RESULT_ID=b.itemCode ;
quit;

data DD.cs_table1_tab;
set cs_table_ta;
format ��ϵ���� yymmdd10.;
��ϵ����=datepart(CREATE_TIME);
��ϵ�·�=put(��ϵ����,yymmn6.);
ͨ��ʱ��_��=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);

if CALL_ACTION_ID ="OUTBOUND" then ����=1;

if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("��ŵ����","�ܽӻ���","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;

if CALL_ACTION_ID ="OUTBOUND" and RESULT="��ŵ����"  then ��ŵ����=1;else ��ŵ����=0;
run;

**��������;
data milipayment_re;
set repayfin.milipayment_report(keep = CONTRACT_NO OVERDUE_DAYS ID_NUMBER LOAN_DATE �˻���ǩ cut_date);
if �˻���ǩ = "�ѻ���";
if cut_date=&dt.;
run;

proc sort data = milipayment_re ; by ID_NUMBER descending LOAN_DATE; run;
proc sort data = milipayment_re nodupkey; by ID_NUMBER;run;

data cs_table_table;
set DD.cs_table1_tab(keep = CONTRACT_NO ���� ��ͨ RESULT CALL_ACTION_ID);
if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("��ŵ����","�ܽӻ���","ΥԼ����","�ѻ���","����/ת��","�޷�ת��","����/����","��������") then ��ͨ=1;else ��ͨ=0;
run;
proc sort data = cs_table_table ; by CONTRACT_NO;run;
proc sort data = milipayment_re nodupkey; by CONTRACT_NO;run;


data repay;
merge milipayment_re(in = a) cs_table_table(in = b);
by CONTRACT_NO;  
if a;
run;

proc sort data = repay; by CONTRACT_NO; run;

data repp;
set repay;
if RESULT = "�պŴ��" then �պŴ��=1;else �պŴ��=0;
if RESULT = "ռ�߹ػ�" then ռ�߹ػ�=1;else ռ�߹ػ�=0;
if RESULT = "�ܾ�����" then �ܾ�����=1;else �ܾ�����=0;
if RESULT = "��������" then ��������=1;else ��������=0;
if RESULT = "�޷�ת��" then �޷�ת��=1;else �޷�ת��=0;
run;

proc sql;
create table reppp as
select CONTRACT_NO, sum(����) as ������� ,sum(��ͨ) as ��ͨ���� ,OVERDUE_DAYS as �ϱʴ�����������,sum(�պŴ��) as �պŴ��,sum(ռ�߹ػ�) as ռ�߹ػ�,sum(�ܾ�����) as �ܾ�����,sum(��������) as ��������, sum(�޷�ת��) as �޷�ת��  
from repp group by CONTRACT_NO;
quit;

proc sort data = reppp nodupkey; by CONTRACT_NO;run;

data req;
set reppp;
if �պŴ�� = 0 and ռ�߹ػ�= 0  and �ܾ�����=0 and ��������=0 and �޷�ת��=0 then ��ϵ��� = "����";else ��ϵ��� = "����";
run;

****************************;

data haha10;
set req(drop = �պŴ�� ռ�߹ػ� �ܾ����� �������� �޷�ת��);
if ��ϵ��� = "����";
if ������� > 1;
run;

data haha1;
set req(drop = �պŴ�� ռ�߹ػ� �ܾ����� �������� �޷�ת��);
if ��ϵ��� = "����";
if �ϱʴ�����������<3 & �������<3;
run;

data haha2;
set req(drop = �պŴ�� ռ�߹ػ� �ܾ����� �������� �޷�ת��);
if ��ϵ��� = "����";
**if ������� > 1;
if �ϱʴ�����������<6 & �������<7;
run;

filename export "F:\�����绰����\req.csv" encoding='utf-8';
PROC EXPORT DATA= haha
			 outfile = export
			 dbms = csv replace;
RUN;


/*proc freq data=haha noprint;*/
/*table ��ͨ����/out=cac;*/
/*run;*/


/*data kankan;*/
/*set haha;*/
/*rename apply_code = contract_no;*/
/*if ��ͨ����=0 then ��ͨ_0=1;*/
/*else if ��ͨ����=1 then ��ͨ_1=1;*/
/*else if ��ͨ����=2 then ��ͨ_2=1;*/
/*else if ��ͨ����=3 then ��ͨ_3=1;*/
/*else if ��ͨ����=4 then ��ͨ_4=1;*/
/*else if 5<=��ͨ����<=6 then ��ͨ5_6=1;*/
/*else if 7<=��ͨ����<=9 then ��ͨ7_9=1;*/
/*else if 10<=��ͨ����<=16 then ��ͨ10_16=1;*/
/*run;*/
/**/
/*proc sql;*/
/*create table kankan_all as*/
/*select ��ϵ���,sum(��ͨ_0) as ��ͨ_0��,sum(��ͨ_1) as ��ͨ_1�� ,sum(��ͨ_2) as ��ͨ_2��,sum(��ͨ_3) as ��ͨ_3��,*/
/*sum(��ͨ_4) as ��ͨ_4��,sum(��ͨ5_6) as ��ͨ5_6��,sum(��ͨ7_9) as ��ͨ7_9��,sum(��ͨ10_16) as ��ͨ10_16�� from kankan group by ��ϵ���;*/
/*quit;*/





/*�ϱʴ�����������<X & ��������<Y



& ��ϵ�����û�г�����˵��code���պŴ�ţ�ռ�߹ػ����ܾ���������������޷�ת���Ӧcode��*/
/**/
/*�ϱʴ��������������������repayfin.milipayment_report�Ķ����֤���ſ���������ȡÿ�����֤���һ�ʷſ�����������Ϳ�����*/
/**/
/*ȡ��ÿ�ʺ�ͬ��Ӧ����������+��������+��ϵ������Ƿ��г����Ǽ���code;*/

data paypay;
merge haha(in=a) Payment(in=b);
by contract_no;
run;



**�Ѿ������֮ǰ���ڹ�;
data re;
set repayfin.milipayment_report(keep = CONTRACT_NO OVERDUE_DAYS ID_NUMBER LOAN_DATE �˻���ǩ cut_date);
if �˻���ǩ = "�ѻ���";
if OVERDUE_DAYS >0;
if cut_date=&dt.;
run;
