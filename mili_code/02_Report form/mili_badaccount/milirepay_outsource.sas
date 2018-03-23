option compress = yes validvarname = any;
libname csdata odbc  datasrc=csdata_nf;
libname data "F:\米粒坏账率预测\csdata";
libname repayFin "F:\米粒坏账率预测\repayAnalysis";

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

*不知道ctl_outsource_contract会不会叠加（多次外包分配）,但这里用id这个主键应该是具有独一性的，剩下的就是一个contract_no多次出现的问题;
proc sql;
create table haokan as
select a.CONTRACT_NO,a.OUTSOURCE_OVERDUEDAYS,a.OUTSOURCE_SUM_TOTAL,
b.OUTSOURCE_DATE,b.OUTSOURCE_END_DATE,b.OUTSOURCE_COMPANY_NAME,c.REMARK  from data.ctl_outsource_contract as a
left join data.ctl_outsource_pack as b on a.OUTSOURCE_PACK_ID=b.id
left join data.ctl_outsourcers as c on b.COMMISSION_RATIO=c.COMMISSION_RATIO and b.OUTSOURCE_COMPANY_CODE=c.OUTSOURCERS_CODE;
quit;
***外包数据集;
data haokan1;
set haokan;
if kindex(contract_no,"PL");
format 外包开始日期 外包结束日期 yymmdd10.;
外包开始日期=datepart(OUTSOURCE_DATE);
外包结束日期=datepart(OUTSOURCE_END_DATE);
drop OUTSOURCE_DATE OUTSOURCE_END_DATE;
run;

/*proc delete data=outsorcepayment;run;*/
/**这里可以确定一个时间点只有一个外包,因为业务特性:第二次外包就意味着第一次失败(所以直接删掉第一次失败的)，所以nodupkey+descending 外包开始日期就实现了;*/
/*%macro get_payment2;*/
/*%do i = -31 %to &nd.;*/
/*data _null_;*/
/*cut_dt = intnx("day", &db., &i.);*/
/*call symput("cut_dt", cut_dt);*/
/*run;*/
/*data macro;*/
/*set haokan1(where=(外包开始日期<=&cut_dt.));*/
/*format cut_date yymmdd10.;*/
/*cut_date=&cut_dt.;*/
/*run;*/
/*proc sort data=macro ;by contract_no descending  外包开始日期;run;*/
/*proc sort data=macro nodupkey;by contract_no;run;*/
/*proc append data=macro base=outsorcepayment;run;*/
/*%end;*/
/*%mend;*/
/*%get_payment2;*/

*********************************************************************************************************************;
data out_kan;
set repayFin.ct_payment_report;
if 放款月份 in ("201612","201701","201702","201703","201704","201705","201706","201707","201708","201709");
*这句话很重要，之前一直没有添加，导致近期催回率的分子是在&dt后，即催回率偏高，但很早之前的催回率不受影响，看看要不要修改;
if clear_date>cut_date then clear_date=.;
format CLEAR_DATE yymmdd10.;
if 账户标签 not in ("待还款","扣款失败","未放款");
if CLEAR_DATE=. then 逾期天数=sum(cut_date,-REPAY_DATE);
else 逾期天数=sum(CLEAR_DATE,-REPAY_DATE);
if 逾期天数>0 and CLEAR_DATE^=. then 催回=1;
if 逾期天数>0 then 逾期=1;

if 1<=逾期天数<=3 and BILL_STATUS="0000" then 逾期催回1_3=1;
else if 4<=逾期天数<=10 and BILL_STATUS="0000" then 逾期催回4_10=1;
else if 11<=逾期天数<=15 and BILL_STATUS="0000" then 逾期催回11_15=1;
else if 16<=逾期天数<=30 and BILL_STATUS="0000" then 逾期催回16_30=1;

if 4<=逾期天数<=30 and BILL_STATUS="0000" then 逾期催回4_30=1;


if 逾期天数>3 then 逾期_a3=1;
if 逾期天数>10 then 逾期_a10=1;
if 逾期天数>15 then 逾期_a15=1;
if 逾期天数>30 then 逾期_a30=1;
run;

proc sort data=haokan1 ;by contract_no;run;
proc sort data=out_kan ;by contract_no;run;

data out_kankan;
merge haokan1(in=a) out_kan(in=b);
by CONTRACT_NO;
if b;
run;

**打上是否外包标签;
data out_in_kan;
set out_kankan;
if OUTSOURCE_COMPANY_NAME = "" then 内催=1;
else 外包=1;
run;


*************************************************************************;
**外包;

data out_kankan1;
set out_in_kan;
if cut_date>=外包开始日期;
if 外包=1;
run;

/*data out_kankan;*/
/*set out_kankan;*/
/*if cut_date>=外包开始日期;*/
/*run;*/

data out_huishenghuo;
set out_kankan1;
if OUTSOURCE_COMPANY_NAME = "慧生活";
run;

proc sql;
create table kanout1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from out_huishenghuo group by 放款月份 ;
quit;
proc sql;
create table kanout2 as
select 放款月份,sum(逾期催回1_3)/sum(逾期) as a1_3催回率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout3 as
select 放款月份,sum(逾期_a3)/count(*) as a3天以上逾期率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout4 as
select 放款月份,sum(逾期催回4_10)/sum(逾期_a3) as a4_10催回率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout5 as
select 放款月份,sum(逾期_a10)/count(*) as a10天以上逾期率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout6 as
select 放款月份,sum(逾期催回11_15)/sum(逾期_a10) as a11_15催回率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout7 as
select 放款月份,sum(逾期_a15)/count(*) as a15天以上逾期率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout8 as
select 放款月份,sum(逾期催回16_30)/sum(逾期_a15) as a16_30催回率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout9 as
select 放款月份,sum(逾期_a30)/count(*) as a30天以上逾期率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;
proc sql;
create table kanout14 as
select 放款月份,sum(逾期催回4_30)/sum(逾期_a3) as 总催回率 format=percent7.2 from out_huishenghuo group by 放款月份;
quit;

proc sql;
create table kan_out_all as
select a.*,b.a1_3催回率,c.a3天以上逾期率,d.a4_10催回率,e.a10天以上逾期率,f.a11_15催回率,g.a15天以上逾期率,
h.a16_30催回率,i.a30天以上逾期率,n.总催回率 from kanout1 as a
left join kanout2 as b on a.放款月份=b.放款月份
left join kanout3 as c on a.放款月份=c.放款月份
left join kanout4 as d on a.放款月份=d.放款月份
left join kanout5 as e on a.放款月份=e.放款月份
left join kanout6 as f on a.放款月份=f.放款月份
left join kanout7 as g on a.放款月份=g.放款月份
left join kanout8 as h on a.放款月份=h.放款月份
left join kanout9 as i on a.放款月份=i.放款月份
left join kanout14 as n on a.放款月份=n.放款月份;
quit;

filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r23c1:r30c3';
data _null_;
set Work.kan_out_all;
file DD;
put 放款月份 自然逾期率 a1_3催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r23c5:r30c5';
data _null_;
set Work.kan_out_all;
file DD;
put a4_10催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r23c7:r30c7';
data _null_;
set Work.kan_out_all;
file DD;
put a11_15催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r23c9:r30c9';
data _null_;
set Work.kan_out_all;
file DD;
put a16_30催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r23c11:r30c11';
data _null_;
set Work.kan_out_all;
file DD;
put 总催回率;
run;

*********************************************************************************************;
**内催;
**严格来讲，我们假设30天之后的外包公司不参与慧生活;
data in_kankan1;
set out_in_kan;
if 内催=1 or OUTSOURCE_COMPANY_NAME ^= "慧生活" and OUTSOURCE_COMPANY_NAME^="";
/*if cut_date>外包开始日期;*/
run;

**不是由慧生活跑出来的;
proc sql;
create table in_kankan as
select * from in_kankan1 where contract_no not in (select contract_no from out_huishenghuo);
quit;

proc sql;
create table kanin1 as
select 放款月份,sum(逾期)/count(*) as 自然逾期率 format=percent7.2 from in_kankan group by 放款月份 ;
quit;
proc sql;
create table kanin2 as
select 放款月份,sum(逾期催回1_3)/sum(逾期) as a1_3催回率 format=percent7.2 from in_kankan group by 放款月份;
quit;
/*proc sql;*/
/*create table kanin3 as*/
/*select 放款月份,sum(逾期_a3)/count(*) as a3天以上逾期率 format=percent7.2 from in_kankan group by 放款月份;*/
/*quit;*/

proc sql;
create table kanin3 as
select 放款月份,sum(逾期_a3)/count(逾期_a3) as a3天以上逾期率 format=percent7.2 from in_kankan group by 放款月份;
quit;

proc sql;
create table kanin4 as
select 放款月份,sum(逾期催回4_10)/sum(逾期_a3) as a4_10催回率 format=percent7.2 from in_kankan group by 放款月份;
quit;
proc sql;
create table kanin5 as
select 放款月份,sum(逾期_a10)/count(逾期_a3) as a10天以上逾期率 format=percent7.2 from in_kankan group by 放款月份;
quit;
proc sql;
create table kanin6 as
select 放款月份,sum(逾期催回11_15)/sum(逾期_a10) as a11_15催回率 format=percent7.2 from in_kankan group by 放款月份;
quit;
proc sql;
create table kanin7 as
select 放款月份,sum(逾期_a15)/count(逾期_a3) as a15天以上逾期率 format=percent7.2 from in_kankan group by 放款月份;
quit;
proc sql;
create table kanin8 as
select 放款月份,sum(逾期催回16_30)/sum(逾期_a15) as a16_30催回率 format=percent7.2 from in_kankan group by 放款月份;
quit;
proc sql;
create table kanin9 as
select 放款月份,sum(逾期_a30)/count(逾期_a3) as a30天以上逾期率 format=percent7.2 from in_kankan group by 放款月份;
quit;
proc sql;
create table kanin14 as
select 放款月份,sum(逾期催回4_30)/sum(逾期_a3) as 总催回率 format=percent7.2 from in_kankan group by 放款月份;
quit;

proc sql;
create table kan_in_all as
select a.*,b.a1_3催回率,c.a3天以上逾期率,d.a4_10催回率,e.a10天以上逾期率,f.a11_15催回率,g.a15天以上逾期率,
h.a16_30催回率,i.a30天以上逾期率,n.总催回率 from kanin1 as a
left join kanin2 as b on a.放款月份=b.放款月份
left join kanin3 as c on a.放款月份=c.放款月份
left join kanin4 as d on a.放款月份=d.放款月份
left join kanin5 as e on a.放款月份=e.放款月份
left join kanin6 as f on a.放款月份=f.放款月份
left join kanin7 as g on a.放款月份=g.放款月份
left join kanin8 as h on a.放款月份=h.放款月份
left join kanin9 as i on a.放款月份=i.放款月份
left join kanin14 as n on a.放款月份=n.放款月份;
quit;

filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r3c1:r12c3';
data _null_;
set Work.kan_in_all;
file DD;
put 放款月份 自然逾期率 a1_3催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r3c5:r12c5';
data _null_;
set Work.kan_in_all;
file DD;
put a4_10催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r3c7:r12c7';
data _null_;
set Work.kan_in_all;
file DD;
put a11_15催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r3c9:r12c9';
data _null_;
set Work.kan_in_all;
file DD;
put a16_30催回率;
run;
filename DD DDE 'EXCEL|[坏账比率(米粒).xlsx]坏账比率_内催外包!r3c11:r12c11';
data _null_;
set Work.kan_in_all;
file DD;
put 总催回率;
run;
