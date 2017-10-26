option compress = yes validvarname = any;
option missing = 0;
libname csdata odbc  datasrc=csdata_nf;
libname YY odbc  datasrc=res_nf;

libname DA "F:\米粒电话催收\csdata";
libname DB "F:\米粒电话催收\res_nf";
libname DD "F:\米粒电话催收";
libname repayFin "F:\米粒逾期日报表\data";

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
format 联系日期 yymmdd10.;
联系日期=datepart(CREATE_TIME);
联系月份=put(联系日期,yymmn6.);
通话时长_秒=sum(scan(DIAL_LENGTH,2,":")*60,scan(DIAL_LENGTH,3,":")*1);

if CALL_ACTION_ID ="OUTBOUND" then 拨打=1;

if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("承诺还款","拒接还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;

if CALL_ACTION_ID ="OUTBOUND" and RESULT="承诺还款"  then 承诺还款=1;else 承诺还款=0;
run;

**米粒逾期;
data milipayment_re;
set repayfin.milipayment_report(keep = CONTRACT_NO OVERDUE_DAYS ID_NUMBER LOAN_DATE 账户标签 cut_date);
if 账户标签 = "已还款";
if cut_date=&dt.;
run;

proc sort data = milipayment_re ; by ID_NUMBER descending LOAN_DATE; run;
proc sort data = milipayment_re nodupkey; by ID_NUMBER;run;

data cs_table_table;
set DD.cs_table1_tab(keep = CONTRACT_NO 拨打 拨通 RESULT CALL_ACTION_ID);
if CALL_ACTION_ID ="OUTBOUND" and RESULT in ("承诺还款","拒接还款","违约还款","已还款","留言/转告","无法转告","死亡/坐牢","无力偿还") then 拨通=1;else 拨通=0;
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
if RESULT = "空号错号" then 空号错号=1;else 空号错号=0;
if RESULT = "占线关机" then 占线关机=1;else 占线关机=0;
if RESULT = "拒绝还款" then 拒绝还款=1;else 拒绝还款=0;
if RESULT = "无力偿还" then 无力偿还=1;else 无力偿还=0;
if RESULT = "无法转告" then 无法转告=1;else 无法转告=0;
run;

proc sql;
create table reppp as
select CONTRACT_NO, sum(拨打) as 拨打次数 ,sum(拨通) as 拨通次数 ,OVERDUE_DAYS as 上笔贷款逾期天数,sum(空号错号) as 空号错号,sum(占线关机) as 占线关机,sum(拒绝还款) as 拒绝还款,sum(无力偿还) as 无力偿还, sum(无法转告) as 无法转告  
from repp group by CONTRACT_NO;
quit;

proc sort data = reppp nodupkey; by CONTRACT_NO;run;

data req;
set reppp;
if 空号错号 = 0 and 占线关机= 0  and 拒绝还款=0 and 无力偿还=0 and 无法转告=0 then 联系结果 = "正常";else 联系结果 = "不佳";
run;

****************************;

data haha10;
set req(drop = 空号错号 占线关机 拒绝还款 无力偿还 无法转告);
if 联系结果 = "正常";
if 拨打次数 > 1;
run;

data haha1;
set req(drop = 空号错号 占线关机 拒绝还款 无力偿还 无法转告);
if 联系结果 = "正常";
if 上笔贷款逾期天数<3 & 拨打次数<3;
run;

data haha2;
set req(drop = 空号错号 占线关机 拒绝还款 无力偿还 无法转告);
if 联系结果 = "正常";
**if 拨打次数 > 1;
if 上笔贷款逾期天数<6 & 拨打次数<7;
run;

filename export "F:\米粒电话催收\req.csv" encoding='utf-8';
PROC EXPORT DATA= haha
			 outfile = export
			 dbms = csv replace;
RUN;


/*proc freq data=haha noprint;*/
/*table 拨通次数/out=cac;*/
/*run;*/


/*data kankan;*/
/*set haha;*/
/*rename apply_code = contract_no;*/
/*if 拨通次数=0 then 拨通_0=1;*/
/*else if 拨通次数=1 then 拨通_1=1;*/
/*else if 拨通次数=2 then 拨通_2=1;*/
/*else if 拨通次数=3 then 拨通_3=1;*/
/*else if 拨通次数=4 then 拨通_4=1;*/
/*else if 5<=拨通次数<=6 then 拨通5_6=1;*/
/*else if 7<=拨通次数<=9 then 拨通7_9=1;*/
/*else if 10<=拨通次数<=16 then 拨通10_16=1;*/
/*run;*/
/**/
/*proc sql;*/
/*create table kankan_all as*/
/*select 联系结果,sum(拨通_0) as 拨通_0次,sum(拨通_1) as 拨通_1次 ,sum(拨通_2) as 拨通_2次,sum(拨通_3) as 拨通_3次,*/
/*sum(拨通_4) as 拨通_4次,sum(拨通5_6) as 拨通5_6次,sum(拨通7_9) as 拨通7_9次,sum(拨通10_16) as 拨通10_16次 from kankan group by 联系结果;*/
/*quit;*/





/*上笔贷款逾期天数<X & 呼出次数<Y



& 联系结果中没有出现所说的code（空号错号，占线关机，拒绝还款，无力偿还，无法转告对应code）*/
/**/
/*上笔贷款的逾期天数用跑米粒repayfin.milipayment_report的对身份证、放款日期排序取每个身份证最后一笔放款的逾期天数就可以了*/
/**/
/*取出每笔合同对应的逾期天数+呼出次数+联系结果中是否有出现那几个code;*/

data paypay;
merge haha(in=a) Payment(in=b);
by contract_no;
run;



**已经还款，且之前逾期过;
data re;
set repayfin.milipayment_report(keep = CONTRACT_NO OVERDUE_DAYS ID_NUMBER LOAN_DATE 账户标签 cut_date);
if 账户标签 = "已还款";
if OVERDUE_DAYS >0;
if cut_date=&dt.;
run;
