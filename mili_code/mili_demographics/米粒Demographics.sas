option compress = yes validvarname = any;
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";
libname bjb "F:\米粒Demographics\data";
libname repayFin "F:\米粒逾期日报表\data";

/*proc printto log="F:\米粒Demographics\米粒Demographics.txt"  new;*/
proc printto;run;

********************************************;
***set account data;
data bjb.bill_main;
set repayFin.bill_main;
run;

data bjb.account_info;
set repayFin.account_info; 
run;

data bjb.repay_plan;
set repayFin.repay_plan;
run;
********************************************;
***from submart
*1;
data bjb.apply_cnt_td;
set submart.apply_cnt_td;
run;
*2;
data bjb.apply_submart;
set submart.apply_submart;
run;
*3;
data bjb.applyvar_submart;
set submart.applyvar_submart;
run;
*4;
data bjb.approval_submart;
set submart.approval_submart;
run;
*5;
data bjb.baseinfo_submart;
set submart.baseinfo_submart;
run;
*6;
data bjb.bqsrule_face_submart;
set submart.bqsrule_face_submart;
run;
*7;
data bjb.bqsrule_fsyys_submart;
set submart.bqsrule_fsyys_submart;
run;
*8;
data bjb.bqsrule_jbgz_submart;
set submart.bqsrule_jbgz_submart;
run;
*9;
data bjb.bqsrule_shixin_submart;
set submart.bqsrule_shixin_submart;
run;
*10;
data bjb.bqsrule_ycsq_submart;
set submart.bqsrule_ycsq_submart;
run;
*11;
data bjb.Bqsrule_fsds_submart;
set submart.Bqsrule_fsds_submart;
run;
*12;
data bjb.tdrule_submart;
set submart.tdrule_submart;
run;
**from python get data
*13;
data bjb.risk_creditx_resp;
set dwdata.risk_creditx_resp;
*14;
*氪信数据;
data bjb.Cxfeature;
set submart.Cxfeature_na;
*15;
*白骑士数据;
data bjb.event_all;
set submart.event_all;
run;
*16;
*标签;
data bjb.apply_flag;
set submart.apply_flag(keep = 首次申请 订单类型 apply_code loc_abmoduleflag 渠道标签);
run;

**********************************************************************************************************;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;
*米粒放款客户;
data mili;
set bjb.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
还款天数=NEXT_REPAY_DATE-LOAN_DATE;
if kindex(PRODUCT_NAME,"米粒");
if contract_no ^="PL148178693332002600000066";/*这个是沙振华的*/
if not kindex(contract_no,"PB");
run;
proc sort data=mili;by id_number loan_date;run;
data mili1;
set mili;
by id_number loan_date;
if first.id_number then 客户标签=1;
else 客户标签+1;
run;

proc sort data=mili1 ;by NEXT_REPAY_DATE;run;
*米粒放款客户的合同金额+利息;
proc sql;
create table mili_repay_plan as
select a.*,b.CURR_RECEIVE_CAPITAL_AMT,b.CURR_RECEIVE_INTEREST_AMT from mili1 as a
left join bjb.repay_plan as b on a.contract_no=b.contract_no;
quit;
*米粒客户的bill_main表;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join bjb.bill_main as b on a.contract_no=b.contract_no;
quit;
proc sort data=mili_bill_main ;by repay_date;run;

*暂时认为bill_main表的curr_receive_amt是技术部算好的bill_fee_dtl的总和;
*暂时当做米粒客户都是对私扣款，所以不加入对公还款部分的逻辑，简单点;
proc delete data=payment ;run;
%macro get_payment;
data _null_;
*早上;
n = &dt.-mdy(12,27,2016) ;
call symput("n", n);
run;
%do i = 0 %to &n.;
data _null_;
start_dt =mdy(12,27,2016);
cut_dt = intnx("day", start_dt, &i.);
call symput("cut_dt", cut_dt);
run;
data temp_result;
set mili_bill_main;
format cut_date yymmdd10. 账户标签 $20.;
cut_date=&cut_dt.;
*放款前;
if &cut_dt.<LOAN_DATE then do;
账户标签="未放款";
存量客户=0;
end;
*待还款;
else if LOAN_DATE<=&cut_dt.<REPAY_DATE then do;
acc_interest=(&cut_dt.-loan_date)*CURR_RECEIVE_INTEREST_AMT/还款天数;
贷款余额=sum(CURR_RECEIVE_CAPITAL_AMT,acc_interest);
账户标签="待还款";
存量客户=1;
end;
*还款日;
else if &cut_dt.=REPAY_DATE then do;
if  CLEAR_DATE=. or &cut_dt.<CLEAR_DATE  then do;
贷款余额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
账户标签="扣款失败";
存量客户=1;
od_days=&cut_dt.-REPAY_DATE;
end;
else if CLEAR_DATE<=&cut_dt. then do;
贷款余额=0;
账户标签="已还款";
存量客户=0;
od_days=0;
end;
end;
*还款日之后;
else if &cut_dt. > repay_date then do;
if CLEAR_DATE=.  or &cut_dt.<CLEAR_DATE then do;
贷款余额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
账户标签="逾期";
存量客户=1;
od_days=&cut_dt.-REPAY_DATE;
end;

else if &cut_dt.>=CLEAR_DATE then do;
贷款余额=0;
账户标签="已还款";
存量客户=0;
od_days=0;
end;
end;

run;
proc append base = payment data = temp_result; run;
%end;
%mend;
%get_payment;

data bjb.milipayment_report;
set payment;
format 报表标签 $20.;
if 账户标签^="未放款";
if REPAY_DATE-cut_date>=1 and REPAY_DATE-cut_date<=3 then 报表标签="T_3";
else if 1<=od_days<=3 then 报表标签="1one_three";
else if 4<=od_days<=15 then 报表标签="2four_fifteen";
else if 16<=od_days<=30 then 报表标签="3sixteen_thirty";
else if od_days>30 then 报表标签="4thirty_";
else if od_days>90 then 报表标签="5ninety_";
统计个数=1;
放款月份=put(LOAN_DATE,yymmn6.);
报表金额=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if 账户标签="待还款" then 报表金额=贷款余额;
/*if contract_no="PL148224156660201400005011" then 报表标签="T_3";*/
/*if 账户标签 in ("待还款","扣款失败") then 账户标签2="Current";*/
run;
data bjb.milipayment_report_demo;
set bjb.milipayment_report;
run;

*后续修正一下加入审核月份放在NB-20170217（周五下班);
*TTD;

proc sql;
create table ttd_use as
select a.apply_code,a.申请提交月份,a.申请通过,a.申请拒绝,a.复贷申请,b.RESIDENCE_CITY_NAME,b.JOB_COMPANY_CITY_NAME,
a.申请结果,a.申请提交日期,a.来源渠道,a.period,b.DEGREE_NAME,b.MARRIAGE_NAME,b.SEX_NAME,b.ID_CARD,b.RESIDENCE_PROVINCE_NAME,
b.RESIDENCE_CONDITION_NAME,b.JOB_COMPANY_CONDITION_NAME,b.CURR_JOB_SENIORITY_NAME,b.JOB_COMPANY_PROVINCE_NAME,
b.MONTH_SALARY_NAME,c.审核处理月份,c.审核处理日期,c.refuse_name from bjb.apply_submart as a 
left join bjb.Baseinfo_submart as b on a.user_code=b.user_code
left join bjb.approval_submart as c on a.apply_code=c.apply_code;
quit;
proc sort data=bjb.event_all nodupkey;by apply_code;run;
proc sql;
create table ttd_use1 as
select a.*,b.loc_addresscnt,b.loc_appsl,b.loc_ava_exp,b.loc_callcount,b.loc_zmscore,b.loc_calledcount,
b.loc_inpast1st_calledtime,b.loc_inpast1st_calltime,b.loc_inpast2nd_calledtime,b.loc_inpast2nd_calltime,
b.loc_inpast3rd_calledtime,b.loc_inpast3rd_calltime,b.loc_phonenum,b.loc_register_date,b.loc_tel_fm_rank,
b.loc_tel_jm_rank,b.loc_tel_po_rank,b.loc_tel_py_rank,b.loc_tel_qs_rank,b.loc_tel_qt_rank,b.loc_tel_ts_rank,
b.loc_tel_tx_rank,b.loc_tel_xd_rank,b.loc_tel_zn_rank,b.loc_txlsl,b.loc_3mcnt_silent,b.loc_3mmaxcnt_silent,
b.loc_1mcnt_silent,b.loc_1mmaxcnt_silent,b.loc_tqscore,b.loc_CreditxScore,b.ja_distance,b.ag_distance,b.jg_distance,b.住址与收货地距离,
b.单位与收货地距离,b.loc_bjscore from ttd_use as a left join bjb.event_all as  b on a.apply_code=b.apply_code;
quit;
proc sort data=ttd_use1 nodupkey;by apply_code;run;

**Tdrule;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=list dbms=excel replace;
sheet="Sheet1";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(变量));
call symput("gzn_"||compress(_n_),compress(变量名));
if last then call symput("lpn",compress(_n_));
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use1 as 
select a.*,case when c.rule_decision^="" then "1.是" else "2.否" end as &&gzn_&i
from ttd_use1 as a
left join bjb.Tdrule_submart(where=(rule_name="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use1 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**BQSrule_ycsq 异常申请;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=list dbms=excel replace;
sheet="Sheet2";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(变量));
call symput("gzn_"||compress(_n_),compress(变量名));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use2;
set ttd_use1;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use2 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as &&gzn_&i
from ttd_use2 as a
left join bjb.BQSrule_ycsq_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use2 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**BQSrule_jbgz;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=list dbms=excel replace;
sheet="Sheet3";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(变量));
call symput("gzn_"||compress(_n_),compress(变量名));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use3;
set ttd_use2;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use3 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as &&gzn_&i
from ttd_use3 as a
left join bjb.BQSrule_jbgz_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use3 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**BQSrule_shixin;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=list dbms=excel replace;
sheet="Sheet4";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(变量));
call symput("gzn_"||compress(_n_),compress(变量名));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use4;
set ttd_use3;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use4 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as &&gzn_&i
from ttd_use4 as a
left join bjb.BQSrule_shixin_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**Bqsrule_fsds;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=list dbms=excel replace;
sheet="Sheet5";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(变量));
call symput("gzn_"||compress(_n_),compress(变量名));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use5;
set ttd_use4;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use5 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as &&gzn_&i
from ttd_use5 as a
left join bjb.Bqsrule_fsds_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use5 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

*使用bjb.loanBQS_face_submart来补，严格来说应该换过来，因为bjb.loanBQS_face_submart是最新的存储地方，但是，不管啦，忙死了-20170228;
proc sql;
create table ttd_use4_1 as
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as JBAA009
from ttd_use5 as a
left join bjb.Bqsrule_face_submart(where=(rule_name_normal="JBAA009_照片比对结果需要人工审核")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4_1 nodupkey;by apply_code;run;

proc sql;
create table ttd_use4_2 as
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as JBAA012
from ttd_use4_1 as a
left join bjb.Bqsrule_face_submart(where=(rule_name_normal="JBAA012_未获取到网纹照")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4_2 nodupkey;by apply_code;run;
proc sql;
create table ttd_use4_3 as
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.是" else "2.否" end as FSSJ005
from ttd_use4_2 as a
left join bjb.Bqsrule_fsyys_submart(where=(rule_name="FSSJ005_手机号归属地与居住及工作地均不一致" and event_name="loan")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4_3 nodupkey;by apply_code;run;
proc sql;
create table ttd_use5 as
select a.*,b.grp_申请距注册,b.grp_cx_score,c.user_code,c.date_created as 申请提交时间,d.apply_cnt_in7d,d.apply_cnt_in1m,d.apply_cnt_in3m,e.last_record_time,e.date_created
  from ttd_use4_3 as a
left join bjb.applyVar_submart as b on a.apply_code=b.apply_code
left join dpRaw.apply_info as c on a.apply_code=c.apply_code
left join bjb.Apply_cnt_td as d on a.apply_code=d.apply_code
left join dpraw.fushu_operator_raw_data as e on c.user_code=e.user_code;
quit;

proc sort data=ttd_use5;by apply_code date_created;run;
proc sort data=ttd_use5 nodupkey;by apply_code;run;
proc sort data=bjb.Cxfeature nodupkey out=bjb.Cxfeature_na;by apply_code;run;
proc sql;
create table ttd_use6 as 
select a.*,b.app_type_cnt,b.recent_device_available_capacity,b.last1m_callcnt_agg,b.last3m_callcnt_agg,b.last1m_callcnt_rate_in,
b.last1m_callcnt_agg_shrt,b.last1m_callcnt_agg_shrt_out,b.last3m_callcnt_agg_shrt,b.last3m_callcnt_agg_shrt_out,b.last1m_callcnt_agg_ctct,
b.last3m_callcnt_agg_ctct,b.last1m_callcnt_with_emergency,b.last3m_callcnt_with_emergency,b.last1m_callcnt_homeplace,b.last3m_callcnt_homeplace,
b.last1m_callplc_below_tier3cnt,b.last3m_callplc_below_tier3cnt,b.last1m_callcnt_agg_coll_in,b.last3m_callcnt_agg_coll_in,b.last1m_callcnt_agg_spc_in,
b.last3m_callcnt_agg_spc_in,b.last1m_callplc_mostFreq,b.last3m_callplc_mostFreq,b.app_total_cnt from ttd_use5 as a
left join bjb.Cxfeature_na as b on a.apply_code=b.apply_code;
quit;

**risk_creditx;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=list dbms=excel replace;
sheet="Sheet6";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(变量));
call symput("gzn_"||compress(_n_),compress(变量名));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use7;
set ttd_use6;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table bjb.ttd_use7 as 
select a.*,case when c.ruleType^="" then "1.是" else "2.否" end as &&gzn_&i
from ttd_use7 as a
left join bjb.risk_creditx_resp(where=(riskDesc="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=bjb.ttd_use7 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();
 
data bjb.ml_Demograph;
set bjb.ttd_use7(drop=一月多台 三月多台 七天多台);
input_complete=1;
*联系人通讯录排名:0-没填,999-填了没通过话,缺失-之前没这个功能;

loc_addresscnt1 = input(loc_addresscnt,best12.);

/*format loc_register_date best32.;*/
format 申请提交日  审核处理日   
互通电话号码  过去第1个月被叫时长 过去第2个月被叫时长 过去第1个月主叫时长 过去第2个月主叫时长 过去第3个月被叫时长 月均消费金额 8.;
互通电话号码=loc_phonenum;
月均消费金额=loc_ava_exp;
过去第1个月被叫时长=loc_inpast1st_calledtime;
过去第2个月被叫时长=loc_inpast2nd_calledtime;
过去第3个月被叫时长=loc_inpast3rd_calledtime;
过去3个月被叫时长=sum(过去第1个月被叫时长,过去第2个月被叫时长,过去第3个月被叫时长);
过去第1个月主叫时长=loc_inpast1st_calltime;
过去第2个月主叫时长=loc_inpast2nd_calltime;
过去第3个月主叫时长=loc_inpast3rd_calltime;
过去3个月主叫时长=sum(过去第1个月主叫时长,过去第2个月主叫时长,过去第3个月主叫时长);

过去第1个月主被叫时长=sum(过去第1个月主叫时长,过去第1个月被叫时长);
过去第2个月主被叫时长=sum(过去第2个月主叫时长,过去第2个月被叫时长);
过去第3个月主被叫时长=sum(过去第3个月主叫时长,过去第3个月被叫时长);

过去3个月主被叫时长=sum(过去第1个月主被叫时长,过去第2个月主被叫时长,过去第3个月主被叫时长);

审核处理日=mdy(ksubstr(审核处理日期,6,2),ksubstr(审核处理日期,9,2),ksubstr(审核处理日期,1,4));
申请提交日=datepart(申请提交时间);

注册时年龄=ksubstr(申请提交日期,1,4)-ksubstr(ID_CARD,7,4);

if JBAA012="1.是" then 未获网纹="1.是";
if JBAA009="1.是" then 照需人="1.是";
申请提交点=hour(申请提交时间);

format  网龄时长 互通电话号码区间 
过去第1个月被叫区间 过去第1个月主叫区间 过去第2个月被叫区间 过去第2个月主叫区间 
过去第3个月被叫区间 过去第3个月主叫区间 过去3个月被叫区间 过去3个月主叫区间 
过去第1个月主被叫区间 过去第2个月主被叫区间 过去第3个月主被叫区间 过去3个月主被叫区间 月均消费金额区间
配偶排名 父母排名 子女排名 兄弟排名 姐妹排名 亲属排名 同事排名 同学排名 朋友排名 其他排名 收货地址区间
SEX_NAME_group age_g MARRIAGE_NAME_g DEGREE_NAME_g period_g JOB_g home_g company_g 
salary_g loc_appsl_g loc_txlsl_g  申请提交点_g 七天多台 一月多台 三月多台 芝麻分区间 通话距离申请区间 近三最静默区间 
近三静默区间 近一最静默区间 近一静默区间 app个数区间 app种类区间 手容占比 过一通次 过三通次 过一被叫比 过一短通次 过一短主叫 
过三短通次 过三短主叫 过一紧通次 过三紧通次 过一户通次 过三户通次 过一三线通次 过三三线通次 最一被催次 最三被催次 最一被特殊次  
最三被特殊次 单位地址和住址距离区间 住址与GPS距离区间 单位与GPS距离区间 住址与收货地距离区间 单位与收货地距离区间 天启分区间 冰鉴分区间 $20.;

length company_province_g $100.;
format company_province_g $100.;

**定义入网时间;
format 入网时间 yymmdd10.;
入网时间=mdy(substr(loc_register_date,6,2),substr(loc_register_date,9,2),substr(loc_register_date,1,4));
网龄月份=intck("month",入网时间,申请提交日);

format 最近通话时间 datetime20.;
最近通话时间=dhms(mdy(ksubstr(last_record_time,6,2),ksubstr(last_record_time,9,2),ksubstr(last_record_time,1,4)),ksubstr(last_record_time,12,2),ksubstr(last_record_time,15,2),ksubstr(last_record_time,18,2));
通话距离申请=sum(申请提交时间,-最近通话时间)/(24*60*60);
if 通话距离申请<0 or last_record_time="" then 通话距离申请=.;

if last3m_callcnt_agg_spc_in =. then 最三被特殊次="z-Missing";
else if last3m_callcnt_agg_spc_in=0 then 最三被特殊次="1.[0]";
else if last3m_callcnt_agg_spc_in=1 then 最三被特殊次="2.[1]";
else if last3m_callcnt_agg_spc_in=2 then 最三被特殊次="3.[2]";
else if last3m_callcnt_agg_spc_in=3 then 最三被特殊次="4.[3]";
else if last3m_callcnt_agg_spc_in=4 then 最三被特殊次="5.[4]";
else if last3m_callcnt_agg_spc_in=5 then 最三被特殊次="6.[5]";
else if last3m_callcnt_agg_spc_in=6 then 最三被特殊次="7.[6]";
else if last3m_callcnt_agg_spc_in=7 then 最三被特殊次="8.[7]";
else if last3m_callcnt_agg_spc_in<=9 then 最三被特殊次="9.[8,9]";
else if last3m_callcnt_agg_spc_in>9 then 最三被特殊次="9_1.[10+]";


if last1m_callcnt_agg_spc_in =. then 最一被特殊次="z-Missing";
else if last1m_callcnt_agg_spc_in=0 then 最一被特殊次="1.[0]";
else if last1m_callcnt_agg_spc_in=1 then 最一被特殊次="2.[1]";
else if last1m_callcnt_agg_spc_in=2 then 最一被特殊次="3.[2]";
else if last1m_callcnt_agg_spc_in=3 then 最一被特殊次="4.[3]";
else if last1m_callcnt_agg_spc_in=4 then 最一被特殊次="5.[4]";
else if last1m_callcnt_agg_spc_in<=6 then 最一被特殊次="6.[5,6]";
else if last1m_callcnt_agg_spc_in>6 then 最一被特殊次="7.[7+]";


if last3m_callcnt_agg_coll_in =. then 最三被催次="z-Missing";
else if last3m_callcnt_agg_coll_in=0 then 最三被催次="1.[0]";
else if last3m_callcnt_agg_coll_in=1 then 最三被催次="2.[1]";
else if last3m_callcnt_agg_coll_in=2 then 最三被催次="3.[2]";
else if last3m_callcnt_agg_coll_in=3 then 最三被催次="4.[3]";
else if last3m_callcnt_agg_coll_in<=5 then 最三被催次="5.[4,5]";
else if last3m_callcnt_agg_coll_in>5 then 最三被催次="6.[6+]";


if last1m_callcnt_agg_coll_in =. then 最一被催次="z-Missing";
else if last1m_callcnt_agg_coll_in=0 then 最一被催次="1.[0]";
else if last1m_callcnt_agg_coll_in=1 then 最一被催次="2.[1]";
else if last1m_callcnt_agg_coll_in=2 then 最一被催次="3.[2]";
else if last1m_callcnt_agg_coll_in=3 then 最一被催次="4.[3]";
else if last1m_callcnt_agg_coll_in>3 then 最一被催次="5.[4+]";


if last3m_callplc_below_tier3cnt =. then 过三三线通次="z-Missing";
else if last3m_callplc_below_tier3cnt=0 then 过三三线通次="1.[0]";
else if last3m_callplc_below_tier3cnt<=10 then 过三三线通次="2.[1,10]";
else if last3m_callplc_below_tier3cnt<=45 then 过三三线通次="3.[11,45]";
else if last3m_callplc_below_tier3cnt<=120 then 过三三线通次="4.[46,120]";
else if last3m_callplc_below_tier3cnt<=250 then 过三三线通次="5.[121,250]";
else if last3m_callplc_below_tier3cnt<=400 then 过三三线通次="6.[251,400]";
else if last3m_callplc_below_tier3cnt<=550 then 过三三线通次="7.[401,550]";
else if last3m_callplc_below_tier3cnt<=750 then 过三三线通次="8.[551,750]";
else if last3m_callplc_below_tier3cnt<=1000 then 过三三线通次="9.[751,1000]";
else if last3m_callplc_below_tier3cnt<=1400 then 过三三线通次="9_1.[1001,1400]";
else if last3m_callplc_below_tier3cnt>1400 then 过三三线通次="9_2.[1401+]";

if last1m_callplc_below_tier3cnt =. then 过一三线通次="z-Missing";
else if last1m_callplc_below_tier3cnt=0 then 过一三线通次="1.[0]";
else if last1m_callplc_below_tier3cnt<=30 then 过一三线通次="2.[1,30]";
else if last1m_callplc_below_tier3cnt<=80 then 过一三线通次="3.[31,80]";
else if last1m_callplc_below_tier3cnt<=160 then 过一三线通次="4.[81,160]";
else if last1m_callplc_below_tier3cnt<=250 then 过一三线通次="5.[161,250]";
else if last1m_callplc_below_tier3cnt<=360 then 过一三线通次="6.[251,360]";
else if last1m_callplc_below_tier3cnt<=470 then 过一三线通次="7.[361,470]";
else if last1m_callplc_below_tier3cnt<=620 then 过一三线通次="8.[471,620]";
else if last1m_callplc_below_tier3cnt<=830 then 过一三线通次="9.[621,830]";
else if last1m_callplc_below_tier3cnt<=1200 then 过一三线通次="9_1.[831,1200]";
else if last1m_callplc_below_tier3cnt>1200 then 过一三线通次="9_2.[1201+]";

if last3m_callcnt_homeplace =. then 过三户通次="z-Missing";
else if last3m_callcnt_homeplace=0 then 过三户通次="1.[0]";
else if last3m_callcnt_homeplace<=30 then 过三户通次="2.[1,30]";
else if last3m_callcnt_homeplace<=90 then 过三户通次="3.[31,90]";
else if last3m_callcnt_homeplace<=170 then 过三户通次="4.[91,170]";
else if last3m_callcnt_homeplace<=255 then 过三户通次="5.[171,255]";
else if last3m_callcnt_homeplace<=370 then 过三户通次="6.[256,370]";
else if last3m_callcnt_homeplace<=480 then 过三户通次="7.[371,480]";
else if last3m_callcnt_homeplace<=630 then 过三户通次="8.[481,630]";
else if last3m_callcnt_homeplace<=830 then 过三户通次="9.[631,830]";
else if last3m_callcnt_homeplace<=1200 then 过三户通次="9_1.[831,1200]";
else if last3m_callcnt_homeplace>1200 then 过三户通次="9_2.[1201+]";

if last1m_callcnt_homeplace =. then 过一户通次="z-Missing";
else if last1m_callcnt_homeplace=0 then 过一户通次="1.[0]";
else if last1m_callcnt_homeplace<=10 then 过一户通次="2.[1,10]";
else if last1m_callcnt_homeplace<=30 then 过一户通次="3.[11,30]";
else if last1m_callcnt_homeplace<=50 then 过一户通次="4.[31,50]";
else if last1m_callcnt_homeplace<=85 then 过一户通次="5.[51,85]";
else if last1m_callcnt_homeplace<=120 then 过一户通次="6.[86,120]";
else if last1m_callcnt_homeplace<=160 then 过一户通次="7.[121,160]";
else if last1m_callcnt_homeplace<=215 then 过一户通次="8.[161,215]";
else if last1m_callcnt_homeplace<=290 then 过一户通次="9.[216,290]";
else if last1m_callcnt_homeplace<=400 then 过一户通次="9_1.[291,400]";
else if last1m_callcnt_homeplace>400 then 过一户通次="9_2.[401+]";


if last3m_callcnt_agg_shrt_out =. then 过三紧通次="z-Missing";
else if last3m_callcnt_agg_shrt_out=0 then 过三紧通次="1.[0]";
else if last3m_callcnt_agg_shrt_out<=10 then 过三紧通次="2.[1,10]";
else if last3m_callcnt_agg_shrt_out<=20 then 过三紧通次="3.[11,20]";
else if last3m_callcnt_agg_shrt_out<=35 then 过三紧通次="4.[21,35]";
else if last3m_callcnt_agg_shrt_out<=50 then 过三紧通次="5.[36,50]";
else if last3m_callcnt_agg_shrt_out<=70 then 过三紧通次="6.[51,70]";
else if last3m_callcnt_agg_shrt_out<=95 then 过三紧通次="7.[71,95]";
else if last3m_callcnt_agg_shrt_out<=130 then 过三紧通次="8.[96,130]";
else if last3m_callcnt_agg_shrt_out<=180 then 过三紧通次="9.[131,180]";
else if last3m_callcnt_agg_shrt_out<=270 then 过三紧通次="9_1.[181,270]";
else if last3m_callcnt_agg_shrt_out>270 then 过三紧通次="9_2.[271+]";


if last1m_callcnt_with_emergency =. then 过一紧通次="z-Missing";
else if last1m_callcnt_with_emergency=0 then 过一紧通次="1.[0]";
else if last1m_callcnt_with_emergency<=3 then 过一紧通次="2.[1,3]";
else if last1m_callcnt_with_emergency<=8 then 过一紧通次="3.[4,8]";
else if last1m_callcnt_with_emergency<=14 then 过一紧通次="4.[9,14]";
else if last1m_callcnt_with_emergency<=21 then 过一紧通次="5.[15,21]";
else if last1m_callcnt_with_emergency<=31 then 过一紧通次="6.[22,31]";
else if last1m_callcnt_with_emergency<=46 then 过一紧通次="7.[32,46]";
else if last1m_callcnt_with_emergency<=68 then 过一紧通次="8.[47,68]";
else if last1m_callcnt_with_emergency<=117 then 过一紧通次="9.[69,117]";
else if last1m_callcnt_with_emergency>117 then 过一紧通次="9_1.[118+]";


if last3m_callcnt_agg_shrt_out =. then 过三短主叫="z-Missing";
else if last3m_callcnt_agg_shrt_out=0 then 过三短主叫="1.[0]";
else if last3m_callcnt_agg_shrt_out<=5 then 过三短主叫="2.[1,5]";
else if last3m_callcnt_agg_shrt_out<=9 then 过三短主叫="3.[6,9]";
else if last3m_callcnt_agg_shrt_out<=12 then 过三短主叫="4.[10,12]";
else if last3m_callcnt_agg_shrt_out<=16 then 过三短主叫="5.[13,16]";
else if last3m_callcnt_agg_shrt_out<=20 then 过三短主叫="6.[17,20]";
else if last3m_callcnt_agg_shrt_out<=26 then 过三短主叫="7.[21,26]";
else if last3m_callcnt_agg_shrt_out<=33 then 过三短主叫="8.[27,33]";
else if last3m_callcnt_agg_shrt_out<=44 then 过三短主叫="9.[34,44]";
else if last3m_callcnt_agg_shrt_out<=65 then 过三短主叫="9_1.[45,65]";
else if last3m_callcnt_agg_shrt_out>65 then 过三短主叫="9_2.[66+]";

if last3m_callcnt_agg_shrt =. then 过三短通次="z-Missing";
else if last3m_callcnt_agg_shrt=0 then 过三短通次="1.[0]";
else if last3m_callcnt_agg_shrt<=14 then 过三短通次="2.[1,14]";
else if last3m_callcnt_agg_shrt<=23 then 过三短通次="3.[15,23]";
else if last3m_callcnt_agg_shrt<=30 then 过三短通次="4.[24,30]";
else if last3m_callcnt_agg_shrt<=40 then 过三短通次="5.[31,40]";
else if last3m_callcnt_agg_shrt<=50 then 过三短通次="6.[41,50]";
else if last3m_callcnt_agg_shrt<=60 then 过三短通次="7.[51,60]";
else if last3m_callcnt_agg_shrt<=70 then 过三短通次="8.[61,70]";
else if last3m_callcnt_agg_shrt<=95 then 过三短通次="9.[71,95]";
else if last3m_callcnt_agg_shrt<=130 then 过三短通次="9_1.[96,130]";
else if last3m_callcnt_agg_shrt>130 then 过三短通次="9_2.[131+]";


if last1m_callcnt_agg_shrt_out =. then 过一短主叫="z-Missing";
else if last1m_callcnt_agg_shrt_out=0 then 过一短主叫="1.[0]";
else if last1m_callcnt_agg_shrt_out<=2 then 过一短主叫="2.[1,2]";
else if last1m_callcnt_agg_shrt_out<=4 then 过一短主叫="3.[3,4]";
else if last1m_callcnt_agg_shrt_out<=6 then 过一短主叫="4.[5,6]";
else if last1m_callcnt_agg_shrt_out<=8 then 过一短主叫="5.[7,8]";
else if last1m_callcnt_agg_shrt_out<=10 then 过一短主叫="6.[9,10]";
else if last1m_callcnt_agg_shrt_out<=14 then 过一短主叫="7.[11,14]";
else if last1m_callcnt_agg_shrt_out<=19 then 过一短主叫="8.[15,19]";
else if last1m_callcnt_agg_shrt_out<=35 then 过一短主叫="9.[20,35]";
else if last1m_callcnt_agg_shrt_out>35 then 过一短主叫="9_1.[36+]";


if last1m_callcnt_agg_shrt =. then 过一短通次="z-Missing";
else if last1m_callcnt_agg_shrt=0 then 过一短通次="1.[0]";
else if last1m_callcnt_agg_shrt<=4 then 过一短通次="2.[1,4]";
else if last1m_callcnt_agg_shrt<=7 then 过一短通次="3.[5,7]";
else if last1m_callcnt_agg_shrt<=10 then 过一短通次="4.[8,10]";
else if last1m_callcnt_agg_shrt<=13 then 过一短通次="5.[11,13]";
else if last1m_callcnt_agg_shrt<=17 then 过一短通次="6.[14,17]";
else if last1m_callcnt_agg_shrt<=21 then 过一短通次="7.[18,21]";
else if last1m_callcnt_agg_shrt<=26 then 过一短通次="8.[22,26]";
else if last1m_callcnt_agg_shrt<=34 then 过一短通次="9.[27,34]";
else if last1m_callcnt_agg_shrt<=50 then 过一短通次="9_1.[35,50]";
else if last1m_callcnt_agg_shrt>50 then 过一短通次="9_2.[51+]";


if app_type_cnt =. then app种类区间="z-Missing";
else if app_type_cnt=0 then app种类区间="1.[0]";
else if app_type_cnt<=4 then app种类区间="2.[1,4]";
else if app_type_cnt=5 then app种类区间="3.[5]";
else if app_type_cnt=6 then app种类区间="4.[6]";
else if app_type_cnt=7 then app种类区间="5.[7]";
else if app_type_cnt<=15 then app种类区间="6.[8,15]";
else if app_type_cnt>=16 then app种类区间="7.[16+]";

if app_total_cnt =. then app个数区间="z-Missing";
else if app_total_cnt=0 then app个数区间="1.[0]";
else if app_total_cnt<=5 then app个数区间="2.[1,5]";
else if app_total_cnt<=9 then app个数区间="3.[6,9]";
else if app_total_cnt<=14 then app个数区间="4.[10,14]";
else if app_total_cnt<=18 then app个数区间="5.[15,18]";
else if app_total_cnt<=33 then app个数区间="6.[19,33]";
else if app_total_cnt<=47 then app个数区间="7.[34,47]";
else if app_total_cnt<=60 then app个数区间="8.[48,60]";
else if app_total_cnt<=75 then app个数区间="9.[61,75]";
else if app_total_cnt<=100 then app个数区间="9_1.[76,100]";
else if app_total_cnt>=101 then app个数区间="9_2.[101+]";


if recent_device_available_capacity =. then 手容占比="z-Missing";
else if recent_device_available_capacity=0 then 手容占比="1.[0]";
else if recent_device_available_capacity<=0.04 then 手容占比="2.[1%,4%]";
else if recent_device_available_capacity<=0.08 then 手容占比="3.[5%,8%]";
else if recent_device_available_capacity<=0.14 then 手容占比="4.[9%,14%]";
else if recent_device_available_capacity<=0.23 then 手容占比="5.[15%,23%]";
else if recent_device_available_capacity<=0.35 then 手容占比="6.[24%,35%]";
else if recent_device_available_capacity<=0.50 then 手容占比="7.[36%,50%]";
else if recent_device_available_capacity<=0.65 then 手容占比="8.[51%,65%]";
else if recent_device_available_capacity<=0.80 then 手容占比="9.[66%,80%]";
else if recent_device_available_capacity<=0.90 then 手容占比="9_1.[81%,90%]";
else if recent_device_available_capacity<=1 then 手容占比="9_2.[91%+]";

if last1m_callcnt_agg =. then 过一通次="z-Missing";
else if last1m_callcnt_agg=0 then 过一通次="1.[0]";
else if last1m_callcnt_agg<=50 then 过一通次="2.[1,50]";
else if last1m_callcnt_agg<=100 then 过一通次="3.[51,100]";
else if last1m_callcnt_agg<=150 then 过一通次="4.[101,150]";
else if last1m_callcnt_agg<=175 then 过一通次="5.[151,175]";
else if last1m_callcnt_agg<=200 then 过一通次="6.[176,200]";
else if last1m_callcnt_agg<=250 then 过一通次="7.[201,250]";
else if last1m_callcnt_agg<=300 then 过一通次="8.[251,300]";
else if last1m_callcnt_agg<=400 then 过一通次="9.[301,400]";
else if last1m_callcnt_agg<=550 then 过一通次="9_1.[401,550]";
else if last1m_callcnt_agg>550 then 过一通次="9_2.[551+]";

if last3m_callcnt_agg =. then 过三通次="z-Missing";
else if last3m_callcnt_agg=0 then 过三通次="1.[0]";
else if last3m_callcnt_agg<=120 then 过三通次="2.[1,120]";
else if last3m_callcnt_agg<=250 then 过三通次="3.[121,250]";
else if last3m_callcnt_agg<=350 then 过三通次="4.[251,350]";
else if last3m_callcnt_agg<=450 then 过三通次="5.[351,450]";
else if last3m_callcnt_agg<=550 then 过三通次="6.[451,550]";
else if last3m_callcnt_agg<=650 then 过三通次="7.[551,650]";
else if last3m_callcnt_agg<=800 then 过三通次="8.[651,800]";
else if last3m_callcnt_agg<=950 then 过三通次="9.[801,950]";
else if last3m_callcnt_agg<=1200 then 过三通次="9_1.[951,1200]";
else if last3m_callcnt_agg<=1600 then 过三通次="9_2.[1201,1600]";
else if last3m_callcnt_agg>1600 then 过三通次="9_3.[1601+]";

if last1m_callcnt_rate_in =. then 过一被叫比="z-Missing";
else if last1m_callcnt_rate_in=0 then 过一被叫比="1.[0]";
else if last1m_callcnt_rate_in<=0.3 then 过一被叫比="2.[1%,30%]";
else if last1m_callcnt_rate_in<=0.4 then 过一被叫比="3.[31%,40%]";
else if last1m_callcnt_rate_in<=0.45 then 过一被叫比="4.[41%,45%]";
else if last1m_callcnt_rate_in<=0.5 then 过一被叫比="5.[46%,50%]";
else if last1m_callcnt_rate_in<=0.55 then 过一被叫比="6.[51%,55%]";
else if last1m_callcnt_rate_in<=0.6 then 过一被叫比="7.[56%,60%]";
else if last1m_callcnt_rate_in<=0.65 then 过一被叫比="8.[61%,65%]";
else if last1m_callcnt_rate_in<=0.7 then 过一被叫比="9.[66%,70%]";
else if last1m_callcnt_rate_in>0.7 then 过一被叫比="9_1.[71%+]";

if 通话距离申请=. then 通话距离申请区间="z-Missing";
else if 0<通话距离申请<=5 then 通话距离申请区间="1.[1,5]";
else if 5<通话距离申请<=15 then 通话距离申请区间="2.[5,15]";
else if 15<通话距离申请<=30 then 通话距离申请区间="3.[15,30]";
else if 通话距离申请>30 then 通话距离申请区间="4.[30+]";

if loc_3mmaxcnt_silent=. then 近三最静默区间="z-Missing";
else if loc_3mmaxcnt_silent=0 then 近三最静默区间="1.[0]";
else if 0<loc_3mmaxcnt_silent<=5 then 近三最静默区间="2.[1,5]";
else if 5<loc_3mmaxcnt_silent<=15 then 近三最静默区间="3.[5,15]";
else if 15<loc_3mmaxcnt_silent<=30 then 近三最静默区间="4.[15,30]";
else if loc_3mmaxcnt_silent>30 then 近三最静默区间="5.[30+]";

if loc_3mcnt_silent=. then 近三静默区间="z-Missing";
else if loc_3mcnt_silent=0 then 近三静默区间="1.[0]";
else if 0<loc_3mcnt_silent<=5 then 近三静默区间="2.[1,5]";
else if 5<loc_3mcnt_silent<=15 then 近三静默区间="3.[5,15]";
else if 15<loc_3mcnt_silent<=30 then 近三静默区间="4.[15,30]";
else if loc_3mcnt_silent>30 then 近三静默区间="5.[30+]";

if loc_1mmaxcnt_silent=. then 近一最静默区间="z-Missing";
else if loc_1mmaxcnt_silent=0 then 近一最静默区间="1.[0]";
else if 0<loc_1mmaxcnt_silent<=5 then 近一最静默区间="2.[1,5]";
else if 5<loc_1mmaxcnt_silent<=15 then 近一最静默区间="3.[5,15]";
else if 15<loc_1mmaxcnt_silent<=30 then 近一最静默区间="4.[15,30]";
else if loc_1mmaxcnt_silent>30 then 近一最静默区间="5.[30+]";

if loc_1mcnt_silent=. then 近一静默区间="z-Missing";
else if loc_1mcnt_silent=0 then 近一静默区间="1.[0]";
else if 0<loc_1mcnt_silent<=5 then 近一静默区间="2.[1,5]";
else if 5<loc_1mcnt_silent<=15 then 近一静默区间="3.[5,15]";
else if 15<loc_1mcnt_silent<=30 then 近一静默区间="4.[15,30]";
else if loc_1mcnt_silent>30 then 近一静默区间="5.[30+]";


if loc_tel_qt_rank=0 then 其他排名="1.没填";
else if 1<=loc_tel_qt_rank<=5 then 其他排名="2.1-5名";
else if 5<loc_tel_qt_rank<=10 then 其他排名="3.5-10名";
else if loc_tel_qt_rank>10 then 其他排名="4.10名以上";
else if loc_tel_qt_rank=999 then 其他排名="5.填了没打";
else if loc_tel_qt_rank=. then 其他排名="6.无";

if loc_tel_py_rank=0 then 朋友排名="1.没填";
else if 1<=loc_tel_py_rank<=5 then 朋友排名="2.1-5名";
else if 5<loc_tel_py_rank<=10 then 朋友排名="3.5-10名";
else if loc_tel_py_rank>10 then 朋友排名="4.10名以上";
else if loc_tel_py_rank=999 then 朋友排名="5.填了没打";
else if loc_tel_py_rank=. then 朋友排名="6.无";

if loc_tel_tx_rank=0 then 同学排名="1.没填";
else if 1<=loc_tel_tx_rank<=5 then 同学排名="2.1-5名";
else if 5<loc_tel_tx_rank<=10 then 同学排名="3.5-10名";
else if loc_tel_tx_rank>10 then 同学排名="4.10名以上";
else if loc_tel_tx_rank=999 then 同学排名="5.填了没打";
else if loc_tel_tx_rank=. then 同学排名="6.无";

if loc_tel_ts_rank=0 then 同事排名="1.没填";
else if 1<=loc_tel_ts_rank<=5 then 同事排名="2.1-5名";
else if 5<loc_tel_ts_rank<=10 then 同事排名="3.5-10名";
else if loc_tel_ts_rank>10 then 同事排名="4.10名以上";
else if loc_tel_ts_rank=999 then 同事排名="5.填了没打";
else if loc_tel_ts_rank=. then 同事排名="6.无";

if loc_tel_qs_rank=0 then 亲属排名="1.没填";
else if 1<=loc_tel_qs_rank<=5 then 亲属排名="2.1-5名";
else if 5<loc_tel_qs_rank<=10 then 亲属排名="3.5-10名";
else if loc_tel_qs_rank>10 then 亲属排名="4.10名以上";
else if loc_tel_qs_rank=999 then 亲属排名="5.填了没打";
else if loc_tel_qs_rank=. then 亲属排名="6.无";

if loc_tel_jm_rank=0 then 姐妹排名="1.没填";
else if 1<=loc_tel_jm_rank<=5 then 姐妹排名="2.1-5名";
else if 5<loc_tel_jm_rank<=10 then 姐妹排名="3.5-10名";
else if loc_tel_jm_rank>10 then 姐妹排名="4.10名以上";
else if loc_tel_jm_rank=999 then 姐妹排名="5.填了没打";
else if loc_tel_jm_rank=. then 姐妹排名="6.无";

if loc_tel_xd_rank=0 then 兄弟排名="1.没填";
else if 1<=loc_tel_xd_rank<=5 then 兄弟排名="2.1-5名";
else if 5<loc_tel_xd_rank<=10 then 兄弟排名="3.5-10名";
else if loc_tel_xd_rank>10 then 兄弟排名="4.10名以上";
else if loc_tel_xd_rank=999 then 兄弟排名="5.填了没打";
else if loc_tel_xd_rank=. then 兄弟排名="6.无";

if loc_tel_zn_rank=0 then 子女排名="1.没填";
else if 1<=loc_tel_zn_rank<=5 then 子女排名="2.1-5名";
else if 5<loc_tel_zn_rank<=10 then 子女排名="3.5-10名";
else if loc_tel_zn_rank>10 then 子女排名="4.10名以上";
else if loc_tel_zn_rank=999 then 子女排名="5.填了没打";
else if loc_tel_zn_rank=. then 子女排名="6.无";

if loc_tel_fm_rank=0 then 父母排名="1.没填";
else if 1<=loc_tel_fm_rank<=5 then 父母排名="2.1-5名";
else if 5<loc_tel_fm_rank<=10 then 父母排名="3.5-10名";
else if 10<loc_tel_fm_rank<=20 then 父母排名="4.10-20名";
else if 20<loc_tel_fm_rank<=30 then 父母排名="5.20-30名";
else if 30<loc_tel_fm_rank<=40 then 父母排名="6.30-40名";
else if 40<loc_tel_fm_rank<=50 then 父母排名="7.40-50名";
else if loc_tel_fm_rank>50 then 父母排名="8.50名以上";
else if loc_tel_fm_rank=999 then 父母排名="9.填了没打";
else if loc_tel_fm_rank=. then 父母排名="9_1.无";

if loc_tel_po_rank=0 then 配偶排名="1.没填";
else if 1<=loc_tel_po_rank<=5 then 配偶排名="2.1-5名";
else if 5<=loc_tel_po_rank<=10 then 配偶排名="3.5-10名";
else if loc_tel_po_rank>10 then 配偶排名="4.10名以上";
else if loc_tel_po_rank=999 then 配偶排名="5.填了没打";
else if loc_tel_po_rank=. then 配偶排名="6.无";

if 月均消费金额=0 then 月均消费金额区间="1.0元";
else if  0<月均消费金额<=20000 then 月均消费金额区间="2.0-200元";
else if  20000<月均消费金额<=50000 then 月均消费金额区间="3.200-500元";
else if        月均消费金额>50000 then 月均消费金额区间="4.500元+";
else if 月均消费金额=. then 月均消费金额区间="5.无";

if loc_addresscnt1=0 then 收货地址区间="1.0个";
else if  0<loc_addresscnt1<=4 then 收货地址区间="2.1-4个";
else if  loc_addresscnt1>4 then 收货地址区间="3.4个+";
else if loc_addresscnt1=. then 收货地址区间="4.无";

if 0<=过去3个月主被叫时长<=27000 then 过去3个月主被叫区间="1.0-450分钟";
else if  27000<过去3个月主被叫时长<=45000 then 过去3个月主被叫区间="2.450-750分钟";
else if  过去3个月主被叫时长>45000 then 过去3个月主被叫区间="3.750分钟+";
else if 过去3个月主被叫时长=. then 过去3个月主被叫区间="4.无";

if 0<=过去第3个月主被叫时长<=10200 then 过去第3个月主被叫区间="1.0-170分钟";
else if  10200<过去第3个月主被叫时长<=18000 then 过去第3个月主被叫区间="2.170-300分钟";
else if  过去第3个月主被叫时长>18000 then 过去第3个月主被叫区间="3.300分钟+";
else if 过去第3个月主被叫时长=. then 过去第3个月主被叫区间="4.无";

if 0<=过去第2个月主被叫时长<=10200 then 过去第2个月主被叫区间="1.0-170分钟";
else if  10200<过去第2个月主被叫时长<=18000 then 过去第2个月主被叫区间="2.170-300分钟";
else if  过去第2个月主被叫时长>18000 then 过去第2个月主被叫区间="3.300分钟+";
else if 过去第2个月主被叫时长=. then 过去第2个月主被叫区间="4.无";

if 0<=过去第1个月主被叫时长<=3000 then 过去第1个月主被叫区间="1.0-50分钟";
else if  3000<过去第1个月主被叫时长<=7800 then 过去第1个月主被叫区间="2.50-130分钟";
else if  过去第1个月主被叫时长>7800 then 过去第1个月主被叫区间="3.130分钟+";
else if 过去第1个月主被叫时长=. then 过去第1个月主被叫区间="4.无";

if 0<=过去3个月主叫时长<=12000 then 过去3个月主叫区间="1.0-200分钟";
else if  12000<过去3个月主叫时长<=21000 then 过去3个月主叫区间="2.200-350分钟";
else if  过去3个月主叫时长>21000 then 过去3个月主叫区间="3.350分钟+";
else if 过去3个月主叫时长=. then 过去3个月主叫区间="4.无";

if 0<=过去3个月被叫时长<=12000 then 过去3个月被叫区间="1.0-200分钟";
else if  12000<过去3个月被叫时长<=21000 then 过去3个月被叫区间="2.200-350分钟";
else if  过去3个月被叫时长>21000 then 过去3个月被叫区间="3.350分钟+";
else if 过去3个月被叫时长=. then 过去3个月被叫区间="4.无";

if 0<=过去第3个月主叫时长<=4800 then 过去第3个月主叫区间="1.0-80分钟";
else if  4800<过去第3个月主叫时长<=9000 then 过去第3个月主叫区间="2.80-150分钟";
else if  过去第3个月主叫时长>9000 then 过去第3个月主叫区间="3.150分钟+";
else if 过去第3个月主叫时长=. then 过去第3个月主叫区间="4.无";

if 0<=过去第3个月被叫时长<=4800 then 过去第3个月被叫区间="1.0-80分钟";
else if  4800<过去第3个月被叫时长<=9000 then 过去第3个月被叫区间="2.80-150分钟";
else if  过去第3个月被叫时长>9000 then 过去第3个月被叫区间="3.150分钟+";
else if 过去第3个月被叫时长=. then 过去第3个月被叫区间="4.无";

if 0<=过去第2个月主叫时长<=4800 then 过去第2个月主叫区间="1.0-80分钟";
else if  4800<过去第2个月主叫时长<=9000 then 过去第2个月主叫区间="2.80-150分钟";
else if  过去第2个月主叫时长>9000 then 过去第2个月主叫区间="3.150分钟+";
else if 过去第2个月主叫时长=. then 过去第2个月主叫区间="4.无";

if 0<=过去第2个月被叫时长<=4800 then 过去第2个月被叫区间="1.0-80分钟";
else if  4800<过去第2个月被叫时长<=9000 then 过去第2个月被叫区间="2.80-150分钟";
else if  过去第2个月被叫时长>9000 then 过去第2个月被叫区间="3.150分钟+";
else if 过去第2个月被叫时长=. then 过去第2个月被叫区间="4.无";


if 0<=过去第1个月主叫时长<=1200 then 过去第1个月主叫区间="1.0-20分钟";
else if  1200<过去第1个月主叫时长<=4200 then 过去第1个月主叫区间="2.20-70分钟";
else if  过去第1个月主叫时长>4200 then 过去第1个月主叫区间="3.70分钟+";
else if 过去第1个月主叫时长=. then 过去第1个月主叫区间="4.无";

if 0<=过去第1个月被叫时长<=1200 then 过去第1个月被叫区间="1.0-20分钟";
else if  1200<过去第1个月被叫时长<=4200 then 过去第1个月被叫区间="2.20-70分钟";
else if  过去第1个月被叫时长>4200 then 过去第1个月被叫区间="3.70分钟+";
else if 过去第1个月被叫时长=. then 过去第1个月被叫区间="4.无";

if 0<=网龄月份<=12 then 网龄时长="1.0-1年";
else if 12<网龄月份<=24 then  网龄时长="2.1-2年";
else if 24<网龄月份<=36 then  网龄时长="3.2-3年";
else if 36<网龄月份<=48 then  网龄时长="4.3-4年";
else if 48<网龄月份<=60 then  网龄时长="5.4-5年";
else if 60<网龄月份<=96 then  网龄时长="6.5-8年";
else if    网龄月份>96 then  网龄时长="7.8年+";
else if 网龄月份=. then 网龄时长="8.无";

if 0<=互通电话号码<=30 then 互通电话号码区间="1.0-30个";
else if  30<互通电话号码<=50 then 互通电话号码区间="2.30-50个";
else if  互通电话号码>50 then 互通电话号码区间="3.50个+";
else if 互通电话号码=. then 互通电话号码区间="4.无";


if 0<=apply_cnt_in7d<=2 then 七天多台="1.0-2个";
else if 2<apply_cnt_in7d<=3 then 七天多台="2.3个";
else if 3<apply_cnt_in7d<=4 then 七天多台="3.4个";
else if 4<apply_cnt_in7d<=5 then 七天多台="4.5个";
else if 5<apply_cnt_in7d<=6 then 七天多台="5.6个";
else if 6<apply_cnt_in7d<=10 then 七天多台="6.7-10个";
else if apply_cnt_in7d>10 then 七天多台="7.11个以上";
if apply_cnt_in7d=. then 七天多台="8.无";

if 0<=apply_cnt_in1m<=2 then 一月多台="1.0-2个";
else if 2<apply_cnt_in1m<=5 then 一月多台="2.3-5个";
else if 5<apply_cnt_in1m<=8 then 一月多台="3.6-8个";
else if apply_cnt_in1m>8 then 一月多台="4.9个以上";
if apply_cnt_in1m=. then 一月多台="5.无";

if 0<=apply_cnt_in3m<=5 then 三月多台="1.0-5个";
else if 5<apply_cnt_in3m<=10 then 三月多台="2.6-10个";
else if 10<apply_cnt_in3m<=14 then 三月多台="3.11-14个";
else if 14<apply_cnt_in3m<=15 then 三月多台="4.15个";
else if apply_cnt_in3m>15 then 三月多台="5.16个以上";
if apply_cnt_in3m=. then 三月多台="6.无";

if 1<=申请提交点<=5 then 申请提交点_g="1.1-5点";
else if 6<=申请提交点<=10 then 申请提交点_g="2.6-10点";
else if 11<=申请提交点<=15 then 申请提交点_g="3.11-15点";
else if 16<=申请提交点<=20 then 申请提交点_g="4.16-20点";
else if 申请提交点>=21 or 申请提交点=0 then 申请提交点_g="5.21-24点";


if 0<=loc_txlsl<10 then loc_txlsl_g="1. 0-9个";
else if 10<=loc_txlsl<20 then loc_txlsl_g="2. 10-19个";
else if 20<=loc_txlsl<30 then loc_txlsl_g="3. 20-29个";
else if 30<=loc_txlsl<50 then loc_txlsl_g="4. 30-49个";
else if 50<=loc_txlsl<100 then loc_txlsl_g="5. 50-99个";
else if loc_txlsl>=100 then loc_txlsl_g="6. 100个以上";


if loc_appsl=0 then loc_appsl_g="1. 0个";
else if loc_appsl=1 then loc_appsl_g="2. 1个";
else if loc_appsl=2 then loc_appsl_g="3. 2个";
else if loc_appsl=3 then loc_appsl_g="4. 3个";
else if loc_appsl=4 then loc_appsl_g="5. 4个";
else if loc_appsl=5 then loc_appsl_g="6. 5个";
else if 5<loc_appsl<=10 then loc_appsl_g="7. 6-10个";
else if 10<loc_appsl<=15 then loc_appsl_g="8. 11-15个";
else if loc_appsl>15 then loc_appsl_g="9. 16个以上";

if 申请结果="人工通过" then check_final=1;else check_final=0;

if  MONTH_SALARY_NAME="2000以下" then salary_g="1.2000以下";
else if MONTH_SALARY_NAME="2000-2999" then salary_g="2.2000-2999";
else if MONTH_SALARY_NAME="3000-4999" then salary_g="3.3000-4999";
else if MONTH_SALARY_NAME="5000-7999" then salary_g="4.5000-7999";
else if MONTH_SALARY_NAME="8000-11999" then salary_g="5.8000-11999";
else if MONTH_SALARY_NAME="12000及以上" then salary_g="6.12000及以上";

if SEX_NAME="男" then SEX_NAME_group="214-男";
else if SEX_NAME="女" then SEX_NAME_group="215-女";

if 注册时年龄=18 then age_g="0.18岁";
else if 19<=注册时年龄<=25 then age_g="1.19-25岁";
else if 26<=注册时年龄<=30 then age_g="2.26-30岁";
else if 31<=注册时年龄<=36 then age_g="3.31-36岁";
else if 注册时年龄>36  then age_g="4.>36岁";

if MARRIAGE_NAME="未婚" then MARRIAGE_NAME_g="1.未婚";
else if MARRIAGE_NAME="已婚未育" then MARRIAGE_NAME_g="2.已婚未育";
else if MARRIAGE_NAME="已婚已育" then MARRIAGE_NAME_g="3.已婚已育";
else if MARRIAGE_NAME="离异" then MARRIAGE_NAME_g="4.离异";
else if MARRIAGE_NAME="丧偶" then MARRIAGE_NAME_g="5.丧偶";
else if MARRIAGE_NAME="其他" then MARRIAGE_NAME_g="6.其他";

if DEGREE_NAME="硕士及以上" then DEGREE_NAME_g="1.硕士及以上";
else if DEGREE_NAME="本科" then DEGREE_NAME_g="2.本科";
else if DEGREE_NAME="大专" then DEGREE_NAME_g="3.大专";
else if DEGREE_NAME="高中或中专" then DEGREE_NAME_g="4.高中或中专";
else if DEGREE_NAME="初中及以下" then DEGREE_NAME_g="5.初中及以下";

if period=7 then period_g="1.7天";
else if period=14 then period_g="2.14天";
else if period=21 then period_g="3.21天";
else if period=28 then period_g="4.28天";

if CURR_JOB_SENIORITY_NAME="3个月以下" then JOB_g="1.3个月以下";
else if  CURR_JOB_SENIORITY_NAME="3～6个月" then JOB_g="2.3～6个月";
else if  CURR_JOB_SENIORITY_NAME="6个月～1年" then JOB_g="3.6个月～1年";
else if  CURR_JOB_SENIORITY_NAME="1~2年" then JOB_g="4.1~2年";
else if  CURR_JOB_SENIORITY_NAME="2～5年" then JOB_g="5.2～5年";
else if  CURR_JOB_SENIORITY_NAME="5年以上" then JOB_g="6.5年以上";

if RESIDENCE_CONDITION_NAME="红本无抵押房" then home_g="1.红本无抵押房";
else if RESIDENCE_CONDITION_NAME="抵押按揭房" then home_g="2.抵押按揭房";
else if RESIDENCE_CONDITION_NAME="家族房" then home_g="3.家族房";
else if RESIDENCE_CONDITION_NAME="租房" then home_g="4.租房";
else if RESIDENCE_CONDITION_NAME="单位宿舍" then home_g="5.单位宿舍";
else if RESIDENCE_CONDITION_NAME="其他" then home_g="6.其他";

if  JOB_COMPANY_CONDITION_NAME="政府机关事业单位" then company_g="1.政府机关事业单位";
else if JOB_COMPANY_CONDITION_NAME="国有企业" then company_g="2.国有企业";
else if JOB_COMPANY_CONDITION_NAME="上市公司、外资合资企业" then company_g="3.上市公司、外资合资企业";
else if JOB_COMPANY_CONDITION_NAME="民营企业" then company_g="4.民营企业";
else if JOB_COMPANY_CONDITION_NAME="个体" then company_g="5.个体";
else if JOB_COMPANY_CONDITION_NAME="其他" then company_g="6.其他";

if JOB_COMPANY_PROVINCE_NAME="北京市" then company_province_g="110000-北京市";
else if JOB_COMPANY_PROVINCE_NAME="天津市" then company_province_g="120000-天津市";
else if JOB_COMPANY_PROVINCE_NAME="河北省" then company_province_g="130000-河北省";
else if JOB_COMPANY_PROVINCE_NAME="山西省" then company_province_g="140000-山西省";
else if JOB_COMPANY_PROVINCE_NAME="内蒙古自治区" then company_province_g="150000-内蒙古自治区";
else if JOB_COMPANY_PROVINCE_NAME="辽宁省" then company_province_g="210000-辽宁省";
else if JOB_COMPANY_PROVINCE_NAME="吉林省" then company_province_g="220000-吉林省";
else if JOB_COMPANY_PROVINCE_NAME="黑龙江省" then company_province_g="230000-黑龙江省";
else if JOB_COMPANY_PROVINCE_NAME="上海市" then company_province_g="310000-上海市";
else if JOB_COMPANY_PROVINCE_NAME="江苏省" then company_province_g="320000-江苏省";
else if JOB_COMPANY_PROVINCE_NAME="浙江省" then company_province_g="330000-浙江省";
else if JOB_COMPANY_PROVINCE_NAME="安徽省" then company_province_g="340000-安徽省";
else if JOB_COMPANY_PROVINCE_NAME="福建省" then company_province_g="350000-福建省";
else if JOB_COMPANY_PROVINCE_NAME="江西省" then company_province_g="360000-江西省";
else if JOB_COMPANY_PROVINCE_NAME="山东省" then company_province_g="370000-山东省";
else if JOB_COMPANY_PROVINCE_NAME="河南省" then company_province_g="410000-河南省";
else if JOB_COMPANY_PROVINCE_NAME="湖北省" then company_province_g="420000-湖北省";
else if JOB_COMPANY_PROVINCE_NAME="湖南省" then company_province_g="430000-湖南省";
else if JOB_COMPANY_PROVINCE_NAME="广东省" then company_province_g="440000-广东省";
else if JOB_COMPANY_PROVINCE_NAME="广西壮族自治区" then company_province_g="450000-广西壮族自治区";
else if JOB_COMPANY_PROVINCE_NAME="海南省" then company_province_g="460000-海南省";
else if JOB_COMPANY_PROVINCE_NAME="重庆市" then company_province_g="500000-重庆市";
else if JOB_COMPANY_PROVINCE_NAME="四川省" then company_province_g="510000-四川省";
else if JOB_COMPANY_PROVINCE_NAME="贵州省" then company_province_g="520000-贵州省";
else if JOB_COMPANY_PROVINCE_NAME="云南省" then company_province_g="530000-云南省";
else if JOB_COMPANY_PROVINCE_NAME="西藏自治区" then company_province_g="540000-西藏自治区";
else if JOB_COMPANY_PROVINCE_NAME="陕西省" then company_province_g="610000-陕西省";
else if JOB_COMPANY_PROVINCE_NAME="甘肃省" then company_province_g="620000-甘肃省";
else if JOB_COMPANY_PROVINCE_NAME="青海省" then company_province_g="630000-青海省";
else if JOB_COMPANY_PROVINCE_NAME="宁夏回族自治区" then company_province_g="640000-宁夏回族自治区";
else if JOB_COMPANY_PROVINCE_NAME="新疆维吾尔自治区" then company_province_g="650000-新疆维吾尔自治区";

if ja_distance in (.,0) then 单位地址和住址距离区间="z-Missing";
else if 0<=ja_distance<0.1 then 单位地址和住址距离区间="1.(0,0.1)";
else if 0.1<=ja_distance<0.2 then 单位地址和住址距离区间="2.[0.1,0.2)";
else if 0.2<=ja_distance<0.3 then 单位地址和住址距离区间="3.[0.2,0.3)";
else if 0.3<=ja_distance<0.4 then 单位地址和住址距离区间="4.[0.3,0.4)";
else if 0.4<=ja_distance<0.5 then 单位地址和住址距离区间="5.[0.4,0.5)";
else if 0.5<=ja_distance<1 then 单位地址和住址距离区间="6.[0.5,1)";
else if 1<=ja_distance<5 then 单位地址和住址距离区间="7.[1,5)";
else if 5<=ja_distance<10 then 单位地址和住址距离区间="8.[5,10)";
else if 10<=ja_distance<20 then 单位地址和住址距离区间="9.[10,20)";
else if 20<=ja_distance<30 then 单位地址和住址距离区间="9_1.[20,30)";
else if ja_distance>30 then 单位地址和住址距离区间="9_2.[30,6000)";

if ag_distance in (.,0) then 住址与GPS距离区间="z-Missing";
else if 0<=ag_distance<0.1 then 住址与GPS距离区间="1.(0,0.1)";
else if 0.1<=ag_distance<0.2 then 住址与GPS距离区间="2.[0.1,0.2)";
else if 0.2<=ag_distance<0.3 then 住址与GPS距离区间="3.[0.2,0.3)";
else if 0.3<=ag_distance<0.4 then 住址与GPS距离区间="4.[0.3,0.4)";
else if 0.4<=ag_distance<0.5 then 住址与GPS距离区间="5.[0.4,0.5)";
else if 0.5<=ag_distance<1 then 住址与GPS距离区间="6.[0.5,1)";
else if 1<=ag_distance<5 then 住址与GPS距离区间="7.[1,5)";
else if 5<=ag_distance<10 then 住址与GPS距离区间="8.[5,10)";
else if 10<=ag_distance<20 then 住址与GPS距离区间="9.[10,20)";
else if 20<=ag_distance<30 then 住址与GPS距离区间="9_1.[20,30)";
else if ag_distance>30 then 住址与GPS距离区间="9_2.[30,6000)";

if jg_distance in (.,0) then 单位与GPS距离区间="z-Missing";
else if 0<=jg_distance<0.1 then 单位与GPS距离区间="1.(0,0.1)";
else if 0.1<=jg_distance<0.2 then 单位与GPS距离区间="2.[0.1,0.2)";
else if 0.2<=jg_distance<0.3 then 单位与GPS距离区间="3.[0.2,0.3)";
else if 0.3<=jg_distance<0.4 then 单位与GPS距离区间="4.[0.3,0.4)";
else if 0.4<=jg_distance<0.5 then 单位与GPS距离区间="5.[0.4,0.5)";
else if 0.5<=jg_distance<1 then 单位与GPS距离区间="6.[0.5,1)";
else if 1<=jg_distance<5 then 单位与GPS距离区间="7.[1,5)";
else if 5<=jg_distance<10 then 单位与GPS距离区间="8.[5,10)";
else if 10<=jg_distance<20 then 单位与GPS距离区间="9.[10,20)";
else if 20<=jg_distance<30 then 单位与GPS距离区间="9_1.[20,30)";
else if jg_distance>30 then 单位与GPS距离区间="9_2.[30,6000)";

if 住址与收货地距离 in (.,0) then 住址与收货地距离区间="z-Missing";
else if 0<=住址与收货地距离<0.1 then 住址与收货地距离区间="1.(0,0.1)";
else if 0.1<=住址与收货地距离<0.2 then 住址与收货地距离区间="2.[0.1,0.2)";
else if 0.2<=住址与收货地距离<0.3 then 住址与收货地距离区间="3.[0.2,0.3)";
else if 0.3<=住址与收货地距离<0.4 then 住址与收货地距离区间="4.[0.3,0.4)";
else if 0.4<=住址与收货地距离<0.5 then 住址与收货地距离区间="5.[0.4,0.5)";
else if 0.5<=住址与收货地距离<1 then 住址与收货地距离区间="6.[0.5,1)";
else if 1<=住址与收货地距离<5 then 住址与收货地距离区间="7.[1,5)";
else if 5<=住址与收货地距离<10 then 住址与收货地距离区间="8.[5,10)";
else if 10<=住址与收货地距离<20 then 住址与收货地距离区间="9.[10,20)";
else if 20<=住址与收货地距离<30 then 住址与收货地距离区间="9_1.[20,30)";
else if 住址与收货地距离>30 then 住址与收货地距离区间="9_2.[30,6000)";

if 单位与收货地距离 in (.,0) then 单位与收货地距离区间="z-Missing";
else if 0<=单位与收货地距离<0.1 then 单位与收货地距离区间="1.(0,0.1)";
else if 0.1<=单位与收货地距离<0.2 then 单位与收货地距离区间="2.[0.1,0.2)";
else if 0.2<=单位与收货地距离<0.3 then 单位与收货地距离区间="3.[0.2,0.3)";
else if 0.3<=单位与收货地距离<0.4 then 单位与收货地距离区间="4.[0.3,0.4)";
else if 0.4<=单位与收货地距离<0.5 then 单位与收货地距离区间="5.[0.4,0.5)";
else if 0.5<=单位与收货地距离<1 then 单位与收货地距离区间="6.[0.5,1)";
else if 1<=单位与收货地距离<5 then 单位与收货地距离区间="7.[1,5)";
else if 5<=单位与收货地距离 <10 then 单位与收货地距离区间="8.[5,10)";
else if 10<=单位与收货地距离<20 then 单位与收货地距离区间="9.[10,20)";
else if 20<=单位与收货地距离<30 then 单位与收货地距离区间="9_1.[20,30)";
else if 单位与收货地距离>30 then 单位与收货地距离区间="9_2.[30,6000)";

if loc_zmscore in (.,0) then 芝麻分区间="z-Missing";
else if 350<=loc_zmscore<500 then 芝麻分区间="1.[350,500)";
else if 500<=loc_zmscore<550 then 芝麻分区间="2.[500,550)";
else if 550<=loc_zmscore<600 then 芝麻分区间="3.[550,600)";
else if 600<=loc_zmscore<620 then 芝麻分区间="4.[600,620)";
else if 620<=loc_zmscore<650 then 芝麻分区间="5.[620,650)";
else if 650<=loc_zmscore<700 then 芝麻分区间="6.[650,700)";
else if loc_zmscore>=700 then 芝麻分区间="7.[700+]";

if loc_tqscore in (.,0) then 天启分区间="z-Missing";
else if 0<=loc_tqscore<408 then 天启分区间="1.(0,408)";
else if loc_tqscore=408 then 天启分区间="2.408";
else if 408<loc_tqscore<450 then 天启分区间="3.(408,450)";
else if 450<=loc_tqscore<500 then 天启分区间="4.[450,500)";
else if 500<=loc_tqscore<550 then 天启分区间="5.[500,550)";
else if 550<=loc_tqscore<600 then 天启分区间="6.[550,600)";
else if 600<=loc_tqscore<650 then 天启分区间="7.[600,650)";
else if 650<=loc_tqscore<850 then 天启分区间="8.[650,850)";

if loc_bjscore in (.,0) then 冰鉴分区间="z-Missing";
else if loc_bjscore in (-1) then 冰鉴分区间="-1";
else if 0<=loc_bjscore<400 then 冰鉴分区间="1.[0,400)";
else if 400<=loc_bjscore<450 then 冰鉴分区间="2.[400,450)";
else if 450<=loc_bjscore<500 then 冰鉴分区间="3.[450,500)";
else if 500<=loc_bjscore<550 then 冰鉴分区间="4.[500,550)";
else if 550<=loc_bjscore<600 then 冰鉴分区间="5.[550,600)";
else if 600<=loc_bjscore<650 then 冰鉴分区间="6.[600,650)";
else if 650<=loc_bjscore<750 then 冰鉴分区间="7.[650,750)";
else if loc_bjscore>=750 then 冰鉴分区间="8.[750+]";

run;


*gogogoggogogoggogogog;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=var_name dbms=excel replace;
sheet="维度变量";
getnames=yes;
run;
proc import datafile="F:\米粒Demographics\米粒demo配置表.xls"
out=var_name_left dbms=excel replace;
sheet="粘贴模板";
getnames=yes;
run;


**贴上AB的标签;
proc sort data=bjb.apply_flag nodupkey;by apply_code;run;
proc sort data=bjb.ml_Demograph(drop = 首次申请 订单类型 loc_abmoduleflag 渠道标签) nodupkey;by apply_code;run;

data bjb.ml_Demograph;
merge bjb.ml_Demograph(in = a) bjb.apply_flag(in = b);
by apply_code;
if a;
run;
proc sort data = bjb.ml_Demograph nodupkey; by apply_code; run;


data submart.ml_Demograph;
set bjb.ml_Demograph;
run;
