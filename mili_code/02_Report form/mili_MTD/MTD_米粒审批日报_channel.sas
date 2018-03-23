option compress = yes validvarname = any;
libname ss "F:\����MTD\output";
libname data "D:\mili\Datamart\data";

/*ʹ��A004_�����������A005_���������ű��ܳ��������ݼ�*/
data ss.apply_submart;
set data.apply_submart;
run;
data ss.approval_submart;   /*�����������������=a*/
set data.approval_submart;
run;

data _null_;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
bt=intnx("month",dt,0,"b");
call symput("bt",bt);
call symput("nt", nt);
��ǰ�·�=put(dt,yymmn6.);
call symput("nmonth",��ǰ�·�);
run;

proc sql;
create table mtd_base as
select a.*,b.loan_amt,b.period,b.��������,b.�ſ��·�,b.�ſ�״̬,b.�ſ�����,b.desired_product from ss.Approval_submart as a
left join ss.Apply_submart as b on a.apply_code=b.apply_code;
quit;

data mtd_base;
set mtd_base;
��˿�ʼ�·�=compress(ksubstr(��˿�ʼ����,1,4)||ksubstr(��˿�ʼ����,6,2));   
format ������������ $20. ��˿�ʼ�� �ſ��� yymmdd10.;
if �������="ϵͳͨ��" then ������ɸѡ=1;
if ������ɸѡ=1 then ������������="ϵͳ�ܾ�";
if ������������="" then ������������=�������;

��˿�ʼ��=mdy(ksubstr(��˿�ʼ����,6,2),ksubstr(��˿�ʼ����,9,2),ksubstr(��˿�ʼ����,1,4));
�ſ���=mdy(ksubstr(�ſ�����,6,2),ksubstr(�ſ�����,9,2),ksubstr(�ſ�����,1,4));

if �ſ�״̬^="304" then do;�ſ��·�="     .";�ſ���=.;�ſ�����="";end;  
run;

proc import datafile="F:\����MTD\�����������ñ�_channel.xls"
out=lable dbms=excel replace;
SHEET="MTD_���������ձ�";
scantext=no;
getnames=yes;
run;
data lable1;
set lable end=last;
call symput ("��������_"||compress(_n_),compress(��������));        
call symput ("�ſ��·�_"||compress(_n_),compress(�ſ��·�));        
call symput ("������ɸѡ_"||compress(_n_),compress(������ɸѡ));
call symput ("������ǩ_"||compress(_n_),compress(������ǩ));
call symput ("loc_abmoduleflag"||compress(_n_),compress(loc_abmoduleflag));
call symput ("��������_"||compress(_n_),compress(��������));
TOTAL_TAT_b1=10+(_n_-1)*90;
TOTAL_TAT_e1=60+(_n_-1)*90;

call symput ("totalb1_row_"||compress(_n_),compress(TOTAL_TAT_b1));
call symput("totale1_row_"||compress(_n_),compress(TOTAL_TAT_e1));

if last then call symput("lpn",compress(_n_));
run;

x  "F:\����MTD\MTD_���������ձ�_channel.xlsx"; 

%macro city_table();
%do i =1 %to &lpn.;   
 
proc sql;
create table test as
select ��˿�ʼ�·� as ʱ�� format=$20.,
sum(case when �������="ϵͳ�����" then 1 else 0 end) as ϵͳ�����,         
sum(case when �������="ϵͳ�ܾ�" then 1 else 0 end) as ϵͳ�ܾ�,
sum(case when ������� ="ϵͳͨ��" then 1 else 0 end) as ϵͳͨ��,
sum(case when �������="�˹��ܾ�" then 1 else 0 end) as �˹��ܾ�,
sum(case when �������="�˹�ͨ��" then 1 else 0 end) as �˹�ͨ��,
sum(case when �������="�˹�������" then 1 else 0 end) as �˹�������,
sum(case when �������="�˹�ȡ��" then 1 else 0 end) as �˹�ȡ��
from mtd_base(where=(�������� in (&&��������_&i) and ��˿�ʼ��^=&nt  and ������ɸѡ in (&&������ɸѡ_&i)  and ������ǩ in (&&������ǩ_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and �������� in (&&��������_&i))) group by ��˿�ʼ�·�;
quit;

proc sql;
create table test1 as
select �ſ��·� as ʱ�� format=$20.,count(*) as �ſ����,sum(loan_amt) as �ſ��� from mtd_base(where=(�ſ��·� ^="&&�ſ��·�_&i" and �������� in (&&��������_&i) and �ſ���^=&nt and ������ɸѡ in (&&������ɸѡ_&i) and ������ǩ in (&&������ǩ_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and �������� in (&&��������_&i))) group by �ſ��·�;
quit;

proc sql;
create table test_month as
select a.*,b.�ſ����,b.�ſ��� from test as a
left join test1 as b on a.ʱ��=b.ʱ��;
quit;

proc sql;
create table test3 as
select ��˿�ʼ���� as ʱ�� format=$20. ,
sum(case when �������="ϵͳ�����" then 1 else 0 end) as ϵͳ�����,
sum(case when �������="ϵͳ�ܾ�" then 1 else 0 end) as ϵͳ�ܾ�,
sum(case when ������� ="ϵͳͨ��" then 1 else 0 end) as ϵͳͨ��,
sum(case when �������="�˹��ܾ�" then 1 else 0 end) as �˹��ܾ�,
sum(case when �������="�˹�ͨ��" then 1 else 0 end) as �˹�ͨ��,
sum(case when �������="�˹�������" then 1 else 0 end) as �˹�������,
sum(case when �������="�˹�ȡ��" then 1 else 0 end) as �˹�ȡ��
from mtd_base(where=(�������� in (&&��������_&i) and &bt.<=��˿�ʼ��<=&dt. and ������ɸѡ in (&&������ɸѡ_&i) and ������ǩ in (&&������ǩ_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and �������� in (&&��������_&i))) group by ��˿�ʼ����;
quit;

proc sql;
create table test4 as
select �ſ����� as ʱ�� format=$20.,count(*) as �ſ����,sum(loan_amt) as �ſ��� 
from mtd_base(where=(�ſ��·� ^="&&�ſ��·�_&i" and �������� in (&&��������_&i) and &bt.<=�ſ���<=&dt. and ������ɸѡ in (&&������ɸѡ_&i) and ������ǩ in (&&������ǩ_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and �������� in (&&��������_&i))) group by �ſ�����;
quit;

proc sql;
create table test_date as
select a.*,b.�ſ����,b.�ſ��� from test3 as a
left join test4 as b on a.ʱ��=b.ʱ��;
quit;

data test_combine;
length ʱ�� $20.;
set test_month test_date;
id=_n_;
if ʱ��=compress(&nmonth.) then id=50;
run;
proc sort data=test_combine;by id;run;

filename DD DDE "EXCEL|[MTD_���������ձ�_channel.xlsx]Sheet1!r&&totalb1_row_&i..c1:r&&totale1_row_&i..c8";
data _null_;set test_combine;file DD;put ʱ�� ϵͳ����� ϵͳ�ܾ� ϵͳͨ�� �˹��ܾ� �˹�ͨ�� �˹������� �˹�ȡ�� ;run;
filename DD DDE "EXCEL|[MTD_���������ձ�_channel.xlsx]Sheet1!r&&totalb1_row_&i..c13:r&&totale1_row_&i..c14";
data _null_;set test_combine;file DD;put �ſ���� �ſ���;run;

%end;
%mend;
%city_table();



data zw_apply;
set data.apply_submart;
if ��������2 = "�����ͻ�����";
run;

proc freq data=zw_apply noprint;
table ������*�����ύ����/out=cac;
run;

proc sql;
create table zw_loan as
select �ſ�����, count(*) as �ſ����,sum(loan_amt) as �ſ���
from zw_apply group by �ſ�����;
quit;


data zw_mtd;
set Mtd_base;
if ��������2 = "�����ͻ�����";

if handle_type = "EXTERNAL" and handle_result = "REJECT" then ������� = "�����ܾ�";
else if handle_type = "EXTERNAL" and handle_result = "ACCEPT" then ������� = "����ͨ��";
else if handle_type = "EXTERNAL" then ������� = "���������";

run;

proc sql;
create table zw_test as
select ��˿�ʼ���� as ʱ�� format=$20. ,
sum(case when ������� ="���������" then 1 else 0 end) as ���������,
sum(case when �������="�����ܾ�" then 1 else 0 end) as �����ܾ�,
sum(case when �������="����ͨ��" then 1 else 0 end) as ����ͨ��
from zw_mtd group by ��˿�ʼ����;
quit;

filename DD DDE "EXCEL|[MTD_���������ձ�_channel.xlsx]Sheet1!r910c1:r917c4";
data _null_;set zw_test;file DD;put ʱ�� ��������� �����ܾ� ����ͨ�� ;run;


proc sql;
create table zw_loan1 as
select �ſ�����, count(*) as �ſ����, sum(loan_amt) as �ſ���
from zw_mtd group by �ſ�����;
quit;
