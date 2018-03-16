option compress = yes validvarname = any;
libname csdata odbc  datasrc=csdata_nf;
libname data "F:\����������Ԥ��\csdata";
libname repayFin "F:\����������Ԥ��\repayAnalysis";

data data.ctl_outsource_contract;
set csdata.ctl_outsource_contract;
run;
data data.ctl_outsource_pack;
set csdata.ctl_outsource_pack;
run;
data data.ctl_outsourcers;
set csdata.ctl_outsourcers;
run;

data _null_;
format dt yymmdd10.;
dt = today() - 1;
db=intnx("month",dt,0,"b");
/*dt=mdy(4,30,2017);*/
/*db=mdy(4,1,2017);*/
nd = dt-db;
lastweekf=intnx('week',dt,-1);
call symput("nd", nd);
call symput("db",db);
call symput("dt", dt);
call symput("lastweekf",lastweekf);
run;

*��֪��ctl_outsource_contract�᲻����ӣ����������䣩,��������id�������Ӧ���Ǿ��ж�һ�Եģ�ʣ�µľ���һ��contract_no��γ��ֵ�����;
proc sql;
create table haokan as
select a.CONTRACT_NO,a.OUTSOURCE_OVERDUEDAYS,a.OUTSOURCE_SUM_TOTAL,
b.OUTSOURCE_DATE,b.OUTSOURCE_END_DATE,b.OUTSOURCE_COMPANY_NAME,c.REMARK  from data.ctl_outsource_contract as a
left join data.ctl_outsource_pack as b on a.OUTSOURCE_PACK_ID=b.id
left join data.ctl_outsourcers as c on b.COMMISSION_RATIO=c.COMMISSION_RATIO and b.OUTSOURCE_COMPANY_CODE=c.OUTSOURCERS_CODE;
quit;
***������ݼ�;
data haokan1;
set haokan;
if kindex(contract_no,"PL");
format �����ʼ���� ����������� yymmdd10.;
�����ʼ����=datepart(OUTSOURCE_DATE);
�����������=datepart(OUTSOURCE_END_DATE);
drop OUTSOURCE_DATE OUTSOURCE_END_DATE;
run;

/*proc delete data=outsorcepayment;run;*/
/**�������ȷ��һ��ʱ���ֻ��һ�����,��Ϊҵ������:�ڶ����������ζ�ŵ�һ��ʧ��(����ֱ��ɾ����һ��ʧ�ܵ�)������nodupkey+descending �����ʼ���ھ�ʵ����;*/
/*%macro get_payment2;*/
/*%do i = -31 %to &nd.;*/
/*data _null_;*/
/*cut_dt = intnx("day", &db., &i.);*/
/*call symput("cut_dt", cut_dt);*/
/*run;*/
/*data macro;*/
/*set haokan1(where=(�����ʼ����<=&cut_dt.));*/
/*format cut_date yymmdd10.;*/
/*cut_date=&cut_dt.;*/
/*run;*/
/*proc sort data=macro ;by contract_no descending  �����ʼ����;run;*/
/*proc sort data=macro nodupkey;by contract_no;run;*/
/*proc append data=macro base=outsorcepayment;run;*/
/*%end;*/
/*%mend;*/
/*%get_payment2;*/

*********************************************************************************************************************;
data out_kan;
set repayFin.ct_payment_report;
if �ſ��·� in ("201612","201701","201702","201703","201704","201705","201706","201707","201708","201709");
*��仰����Ҫ��֮ǰһֱû����ӣ����½��ڴ߻��ʵķ�������&dt�󣬼��߻���ƫ�ߣ�������֮ǰ�Ĵ߻��ʲ���Ӱ�죬����Ҫ��Ҫ�޸�;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if �˻���ǩ not in ("������","�ۿ�ʧ��","δ�ſ�");
if CLEAR_DATE=. then ��������=sum(cut_date,-REPAY_DATE);
else ��������=sum(CLEAR_DATE,-REPAY_DATE);
if ��������>0 and CLEAR_DATE^=. then �߻�=1;
if ��������>0 then ����=1;

if 1<=��������<=3 and BILL_STATUS="0000" then ���ڴ߻�1_3=1;
else if 4<=��������<=10 and BILL_STATUS="0000" then ���ڴ߻�4_10=1;
else if 11<=��������<=15 and BILL_STATUS="0000" then ���ڴ߻�11_15=1;
else if 16<=��������<=30 and BILL_STATUS="0000" then ���ڴ߻�16_30=1;

if 4<=��������<=30 and BILL_STATUS="0000" then ���ڴ߻�4_30=1;


if ��������>3 then ����_a3=1;
if ��������>10 then ����_a10=1;
if ��������>15 then ����_a15=1;
if ��������>30 then ����_a30=1;
run;

proc sort data=haokan1 ;by contract_no;run;
proc sort data=out_kan ;by contract_no;run;

data out_kankan;
merge haokan1(in=a) out_kan(in=b);
by CONTRACT_NO;
if b;
run;

**�����Ƿ������ǩ;
data out_in_kan;
set out_kankan;
if OUTSOURCE_COMPANY_NAME = "" then �ڴ�=1;
else ���=1;
run;


*************************************************************************;
**���;

data out_kankan1;
set out_in_kan;
if cut_date>=�����ʼ����;
if ���=1;
run;

/*data out_kankan;*/
/*set out_kankan;*/
/*if cut_date>=�����ʼ����;*/
/*run;*/

data out_huishenghuo;
set out_kankan1;
if OUTSOURCE_COMPANY_NAME = "������";
run;

proc sql;
create table kanout1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from out_huishenghuo group by �ſ��·� ;
quit;
proc sql;
create table kanout2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout3 as
select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout5 as
select �ſ��·�,sum(����_a10)/count(*) as a10������������ format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout7 as
select �ſ��·�,sum(����_a15)/count(*) as a15������������ format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout9 as
select �ſ��·�,sum(����_a30)/count(*) as a30������������ format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;
proc sql;
create table kanout14 as
select �ſ��·�,sum(���ڴ߻�4_30)/sum(����_a3) as �ܴ߻��� format=percent7.2 from out_huishenghuo group by �ſ��·�;
quit;

proc sql;
create table kan_out_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,n.�ܴ߻��� from kanout1 as a
left join kanout2 as b on a.�ſ��·�=b.�ſ��·�
left join kanout3 as c on a.�ſ��·�=c.�ſ��·�
left join kanout4 as d on a.�ſ��·�=d.�ſ��·�
left join kanout5 as e on a.�ſ��·�=e.�ſ��·�
left join kanout6 as f on a.�ſ��·�=f.�ſ��·�
left join kanout7 as g on a.�ſ��·�=g.�ſ��·�
left join kanout8 as h on a.�ſ��·�=h.�ſ��·�
left join kanout9 as i on a.�ſ��·�=i.�ſ��·�
left join kanout14 as n on a.�ſ��·�=n.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r23c1:r30c3';
data _null_;
set Work.kan_out_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r23c5:r30c5';
data _null_;
set Work.kan_out_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r23c7:r30c7';
data _null_;
set Work.kan_out_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r23c9:r30c9';
data _null_;
set Work.kan_out_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r23c11:r30c11';
data _null_;
set Work.kan_out_all;
file DD;
put �ܴ߻���;
run;

*********************************************************************************************;
**�ڴ�;
**�ϸ����������Ǽ���30��֮��������˾�����������;
data in_kankan1;
set out_in_kan;
if �ڴ�=1 or OUTSOURCE_COMPANY_NAME ^= "������" and OUTSOURCE_COMPANY_NAME^="";
/*if cut_date>�����ʼ����;*/
run;

**�����ɻ������ܳ�����;
proc sql;
create table in_kankan as
select * from in_kankan1 where contract_no not in (select contract_no from out_huishenghuo);
quit;

proc sql;
create table kanin1 as
select �ſ��·�,sum(����)/count(*) as ��Ȼ������ format=percent7.2 from in_kankan group by �ſ��·� ;
quit;
proc sql;
create table kanin2 as
select �ſ��·�,sum(���ڴ߻�1_3)/sum(����) as a1_3�߻��� format=percent7.2 from in_kankan group by �ſ��·�;
quit;
/*proc sql;*/
/*create table kanin3 as*/
/*select �ſ��·�,sum(����_a3)/count(*) as a3������������ format=percent7.2 from in_kankan group by �ſ��·�;*/
/*quit;*/

proc sql;
create table kanin3 as
select �ſ��·�,sum(����_a3)/count(����_a3) as a3������������ format=percent7.2 from in_kankan group by �ſ��·�;
quit;

proc sql;
create table kanin4 as
select �ſ��·�,sum(���ڴ߻�4_10)/sum(����_a3) as a4_10�߻��� format=percent7.2 from in_kankan group by �ſ��·�;
quit;
proc sql;
create table kanin5 as
select �ſ��·�,sum(����_a10)/count(����_a3) as a10������������ format=percent7.2 from in_kankan group by �ſ��·�;
quit;
proc sql;
create table kanin6 as
select �ſ��·�,sum(���ڴ߻�11_15)/sum(����_a10) as a11_15�߻��� format=percent7.2 from in_kankan group by �ſ��·�;
quit;
proc sql;
create table kanin7 as
select �ſ��·�,sum(����_a15)/count(����_a3) as a15������������ format=percent7.2 from in_kankan group by �ſ��·�;
quit;
proc sql;
create table kanin8 as
select �ſ��·�,sum(���ڴ߻�16_30)/sum(����_a15) as a16_30�߻��� format=percent7.2 from in_kankan group by �ſ��·�;
quit;
proc sql;
create table kanin9 as
select �ſ��·�,sum(����_a30)/count(����_a3) as a30������������ format=percent7.2 from in_kankan group by �ſ��·�;
quit;
proc sql;
create table kanin14 as
select �ſ��·�,sum(���ڴ߻�4_30)/sum(����_a3) as �ܴ߻��� format=percent7.2 from in_kankan group by �ſ��·�;
quit;

proc sql;
create table kan_in_all as
select a.*,b.a1_3�߻���,c.a3������������,d.a4_10�߻���,e.a10������������,f.a11_15�߻���,g.a15������������,
h.a16_30�߻���,i.a30������������,n.�ܴ߻��� from kanin1 as a
left join kanin2 as b on a.�ſ��·�=b.�ſ��·�
left join kanin3 as c on a.�ſ��·�=c.�ſ��·�
left join kanin4 as d on a.�ſ��·�=d.�ſ��·�
left join kanin5 as e on a.�ſ��·�=e.�ſ��·�
left join kanin6 as f on a.�ſ��·�=f.�ſ��·�
left join kanin7 as g on a.�ſ��·�=g.�ſ��·�
left join kanin8 as h on a.�ſ��·�=h.�ſ��·�
left join kanin9 as i on a.�ſ��·�=i.�ſ��·�
left join kanin14 as n on a.�ſ��·�=n.�ſ��·�;
quit;

filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r3c1:r12c3';
data _null_;
set Work.kan_in_all;
file DD;
put �ſ��·� ��Ȼ������ a1_3�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r3c5:r12c5';
data _null_;
set Work.kan_in_all;
file DD;
put a4_10�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r3c7:r12c7';
data _null_;
set Work.kan_in_all;
file DD;
put a11_15�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r3c9:r12c9';
data _null_;
set Work.kan_in_all;
file DD;
put a16_30�߻���;
run;
filename DD DDE 'EXCEL|[���˱���(����).xlsx]���˱���_�ڴ����!r3c11:r12c11';
data _null_;
set Work.kan_in_all;
file DD;
put �ܴ߻���;
run;
