option compress = yes validvarname = any;
libname ss "F:\米粒MTD\output";
libname data "D:\mili\Datamart\data";

/*使用A004_申请子主题和A005_审核子主题脚本跑出来的数据集*/
data ss.apply_submart;
set data.apply_submart;
run;
data ss.approval_submart;   /*订单类型在这个表里=a*/
set data.approval_submart;
run;

data _null_;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
bt=intnx("month",dt,0,"b");
call symput("bt",bt);
call symput("nt", nt);
当前月份=put(dt,yymmn6.);
call symput("nmonth",当前月份);
run;

proc sql;
create table mtd_base as
select a.*,b.loan_amt,b.period,b.复贷申请,b.放款月份,b.放款状态,b.放款日期,b.desired_product from ss.Approval_submart as a
left join ss.Apply_submart as b on a.apply_code=b.apply_code;
quit;

data mtd_base;
set mtd_base;
审核开始月份=compress(ksubstr(审核开始日期,1,4)||ksubstr(审核开始日期,6,2));   
format 金策略审批结果 $20. 审核开始日 放款日 yymmdd10.;
if 审批结果="系统通过" then 银策略筛选=1;
if 银策略筛选=1 then 金策略审批结果="系统拒绝";
if 金策略审批结果="" then 金策略审批结果=审批结果;

审核开始日=mdy(ksubstr(审核开始日期,6,2),ksubstr(审核开始日期,9,2),ksubstr(审核开始日期,1,4));
放款日=mdy(ksubstr(放款日期,6,2),ksubstr(放款日期,9,2),ksubstr(放款日期,1,4));

if 放款状态^="304" then do;放款月份="     .";放款日=.;放款日期="";end;  
run;

proc import datafile="F:\米粒MTD\米粒报表配置表_channel.xls"
out=lable dbms=excel replace;
SHEET="MTD_米粒审批日报";
scantext=no;
getnames=yes;
run;
data lable1;
set lable end=last;
call symput ("复贷申请_"||compress(_n_),compress(复贷申请));        
call symput ("放款月份_"||compress(_n_),compress(放款月份));        
call symput ("银策略筛选_"||compress(_n_),compress(银策略筛选));
call symput ("渠道标签_"||compress(_n_),compress(渠道标签));
call symput ("loc_abmoduleflag"||compress(_n_),compress(loc_abmoduleflag));
call symput ("订单类型_"||compress(_n_),compress(订单类型));
TOTAL_TAT_b1=10+(_n_-1)*90;
TOTAL_TAT_e1=60+(_n_-1)*90;

call symput ("totalb1_row_"||compress(_n_),compress(TOTAL_TAT_b1));
call symput("totale1_row_"||compress(_n_),compress(TOTAL_TAT_e1));

if last then call symput("lpn",compress(_n_));
run;

x  "F:\米粒MTD\MTD_米粒审批日报_channel.xlsx"; 

%macro city_table();
%do i =1 %to &lpn.;   
 
proc sql;
create table test as
select 审核开始月份 as 时间 format=$20.,
sum(case when 审批结果="系统审核中" then 1 else 0 end) as 系统审核中,         
sum(case when 审批结果="系统拒绝" then 1 else 0 end) as 系统拒绝,
sum(case when 审批结果 ="系统通过" then 1 else 0 end) as 系统通过,
sum(case when 审批结果="人工拒绝" then 1 else 0 end) as 人工拒绝,
sum(case when 审批结果="人工通过" then 1 else 0 end) as 人工通过,
sum(case when 审批结果="人工复核中" then 1 else 0 end) as 人工复核中,
sum(case when 审批结果="人工取消" then 1 else 0 end) as 人工取消
from mtd_base(where=(复贷申请 in (&&复贷申请_&i) and 审核开始日^=&nt  and 银策略筛选 in (&&银策略筛选_&i)  and 渠道标签 in (&&渠道标签_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and 订单类型 in (&&订单类型_&i))) group by 审核开始月份;
quit;

proc sql;
create table test1 as
select 放款月份 as 时间 format=$20.,count(*) as 放款笔数,sum(loan_amt) as 放款金额 from mtd_base(where=(放款月份 ^="&&放款月份_&i" and 复贷申请 in (&&复贷申请_&i) and 放款日^=&nt and 银策略筛选 in (&&银策略筛选_&i) and 渠道标签 in (&&渠道标签_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and 订单类型 in (&&订单类型_&i))) group by 放款月份;
quit;

proc sql;
create table test_month as
select a.*,b.放款笔数,b.放款金额 from test as a
left join test1 as b on a.时间=b.时间;
quit;

proc sql;
create table test3 as
select 审核开始日期 as 时间 format=$20. ,
sum(case when 审批结果="系统审核中" then 1 else 0 end) as 系统审核中,
sum(case when 审批结果="系统拒绝" then 1 else 0 end) as 系统拒绝,
sum(case when 审批结果 ="系统通过" then 1 else 0 end) as 系统通过,
sum(case when 审批结果="人工拒绝" then 1 else 0 end) as 人工拒绝,
sum(case when 审批结果="人工通过" then 1 else 0 end) as 人工通过,
sum(case when 审批结果="人工复核中" then 1 else 0 end) as 人工复核中,
sum(case when 审批结果="人工取消" then 1 else 0 end) as 人工取消
from mtd_base(where=(复贷申请 in (&&复贷申请_&i) and &bt.<=审核开始日<=&dt. and 银策略筛选 in (&&银策略筛选_&i) and 渠道标签 in (&&渠道标签_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and 订单类型 in (&&订单类型_&i))) group by 审核开始日期;
quit;

proc sql;
create table test4 as
select 放款日期 as 时间 format=$20.,count(*) as 放款笔数,sum(loan_amt) as 放款金额 
from mtd_base(where=(放款月份 ^="&&放款月份_&i" and 复贷申请 in (&&复贷申请_&i) and &bt.<=放款日<=&dt. and 银策略筛选 in (&&银策略筛选_&i) and 渠道标签 in (&&渠道标签_&i) and loc_abmoduleflag in (&&loc_abmoduleflag&i) and 订单类型 in (&&订单类型_&i))) group by 放款日期;
quit;

proc sql;
create table test_date as
select a.*,b.放款笔数,b.放款金额 from test3 as a
left join test4 as b on a.时间=b.时间;
quit;

data test_combine;
length 时间 $20.;
set test_month test_date;
id=_n_;
if 时间=compress(&nmonth.) then id=50;
run;
proc sort data=test_combine;by id;run;

filename DD DDE "EXCEL|[MTD_米粒审批日报_channel.xlsx]Sheet1!r&&totalb1_row_&i..c1:r&&totale1_row_&i..c8";
data _null_;set test_combine;file DD;put 时间 系统审核中 系统拒绝 系统通过 人工拒绝 人工通过 人工复核中 人工取消 ;run;
filename DD DDE "EXCEL|[MTD_米粒审批日报_channel.xlsx]Sheet1!r&&totalb1_row_&i..c13:r&&totale1_row_&i..c14";
data _null_;set test_combine;file DD;put 放款笔数 放款金额;run;

%end;
%mend;
%city_table();



data zw_apply;
set data.apply_submart;
if 订单类型2 = "众网客户订单";
run;

proc freq data=zw_apply noprint;
table 申请结果*申请提交日期/out=cac;
run;

proc sql;
create table zw_loan as
select 放款日期, count(*) as 放款笔数,sum(loan_amt) as 放款金额
from zw_apply group by 放款日期;
quit;


data zw_mtd;
set Mtd_base;
if 订单类型2 = "众网客户订单";

if handle_type = "EXTERNAL" and handle_result = "REJECT" then 审批结果 = "众网拒绝";
else if handle_type = "EXTERNAL" and handle_result = "ACCEPT" then 审批结果 = "众网通过";
else if handle_type = "EXTERNAL" then 审批结果 = "众网审核中";

run;

proc sql;
create table zw_test as
select 审核开始日期 as 时间 format=$20. ,
sum(case when 审批结果 ="众网审核中" then 1 else 0 end) as 众网审核中,
sum(case when 审批结果="众网拒绝" then 1 else 0 end) as 众网拒绝,
sum(case when 审批结果="众网通过" then 1 else 0 end) as 众网通过
from zw_mtd group by 审核开始日期;
quit;

filename DD DDE "EXCEL|[MTD_米粒审批日报_channel.xlsx]Sheet1!r910c1:r917c4";
data _null_;set zw_test;file DD;put 时间 众网审核中 众网拒绝 众网通过 ;run;


proc sql;
create table zw_loan1 as
select 放款日期, count(*) as 放款笔数, sum(loan_amt) as 放款金额
from zw_mtd group by 放款日期;
quit;
