option compress = yes validvarname = any;
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";
libname bjb "F:\����Demographics\data";
libname repayFin "F:\���������ձ���\data";

/*proc printto log="F:\����Demographics\����Demographics.txt"  new;*/
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
*�������;
data bjb.Cxfeature;
set submart.Cxfeature_na;
*15;
*����ʿ����;
data bjb.event_all;
set submart.event_all;
run;
*16;
*��ǩ;
data bjb.apply_flag;
set submart.apply_flag(keep = �״����� �������� apply_code loc_abmoduleflag ������ǩ);
run;

**********************************************************************************************************;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 1, 13, "same"); else dt = today() - 1;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;
*�����ſ�ͻ�;
data mili;
set bjb.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER 
CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE );
��������=NEXT_REPAY_DATE-LOAN_DATE;
if kindex(PRODUCT_NAME,"����");
if contract_no ^="PL148178693332002600000066";/*�����ɳ�񻪵�*/
if not kindex(contract_no,"PB");
run;
proc sort data=mili;by id_number loan_date;run;
data mili1;
set mili;
by id_number loan_date;
if first.id_number then �ͻ���ǩ=1;
else �ͻ���ǩ+1;
run;

proc sort data=mili1 ;by NEXT_REPAY_DATE;run;
*�����ſ�ͻ��ĺ�ͬ���+��Ϣ;
proc sql;
create table mili_repay_plan as
select a.*,b.CURR_RECEIVE_CAPITAL_AMT,b.CURR_RECEIVE_INTEREST_AMT from mili1 as a
left join bjb.repay_plan as b on a.contract_no=b.contract_no;
quit;
*�����ͻ���bill_main��;
proc sql;
create table mili_bill_main as
select a.*,b.repay_date,b.clear_date,b.bill_status,b.OVERDUE_DAYS,b.curr_receive_amt from mili_repay_plan as a
left join bjb.bill_main as b on a.contract_no=b.contract_no;
quit;
proc sort data=mili_bill_main ;by repay_date;run;

*��ʱ��Ϊbill_main���curr_receive_amt�Ǽ�������õ�bill_fee_dtl���ܺ�;
*��ʱ���������ͻ����Ƕ�˽�ۿ���Բ�����Թ�����ֵ��߼����򵥵�;
proc delete data=payment ;run;
%macro get_payment;
data _null_;
*����;
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
format cut_date yymmdd10. �˻���ǩ $20.;
cut_date=&cut_dt.;
*�ſ�ǰ;
if &cut_dt.<LOAN_DATE then do;
�˻���ǩ="δ�ſ�";
�����ͻ�=0;
end;
*������;
else if LOAN_DATE<=&cut_dt.<REPAY_DATE then do;
acc_interest=(&cut_dt.-loan_date)*CURR_RECEIVE_INTEREST_AMT/��������;
�������=sum(CURR_RECEIVE_CAPITAL_AMT,acc_interest);
�˻���ǩ="������";
�����ͻ�=1;
end;
*������;
else if &cut_dt.=REPAY_DATE then do;
if  CLEAR_DATE=. or &cut_dt.<CLEAR_DATE  then do;
�������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
�˻���ǩ="�ۿ�ʧ��";
�����ͻ�=1;
od_days=&cut_dt.-REPAY_DATE;
end;
else if CLEAR_DATE<=&cut_dt. then do;
�������=0;
�˻���ǩ="�ѻ���";
�����ͻ�=0;
od_days=0;
end;
end;
*������֮��;
else if &cut_dt. > repay_date then do;
if CLEAR_DATE=.  or &cut_dt.<CLEAR_DATE then do;
�������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
�˻���ǩ="����";
�����ͻ�=1;
od_days=&cut_dt.-REPAY_DATE;
end;

else if &cut_dt.>=CLEAR_DATE then do;
�������=0;
�˻���ǩ="�ѻ���";
�����ͻ�=0;
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
format �����ǩ $20.;
if �˻���ǩ^="δ�ſ�";
if REPAY_DATE-cut_date>=1 and REPAY_DATE-cut_date<=3 then �����ǩ="T_3";
else if 1<=od_days<=3 then �����ǩ="1one_three";
else if 4<=od_days<=15 then �����ǩ="2four_fifteen";
else if 16<=od_days<=30 then �����ǩ="3sixteen_thirty";
else if od_days>30 then �����ǩ="4thirty_";
else if od_days>90 then �����ǩ="5ninety_";
ͳ�Ƹ���=1;
�ſ��·�=put(LOAN_DATE,yymmn6.);
������=sum(CURR_RECEIVE_CAPITAL_AMT,CURR_RECEIVE_INTEREST_AMT);
if �˻���ǩ="������" then ������=�������;
/*if contract_no="PL148224156660201400005011" then �����ǩ="T_3";*/
/*if �˻���ǩ in ("������","�ۿ�ʧ��") then �˻���ǩ2="Current";*/
run;
data bjb.milipayment_report_demo;
set bjb.milipayment_report;
run;

*��������һ�¼�������·ݷ���NB-20170217�������°�);
*TTD;

proc sql;
create table ttd_use as
select a.apply_code,a.�����ύ�·�,a.����ͨ��,a.����ܾ�,a.��������,b.RESIDENCE_CITY_NAME,b.JOB_COMPANY_CITY_NAME,
a.������,a.�����ύ����,a.��Դ����,a.period,b.DEGREE_NAME,b.MARRIAGE_NAME,b.SEX_NAME,b.ID_CARD,b.RESIDENCE_PROVINCE_NAME,
b.RESIDENCE_CONDITION_NAME,b.JOB_COMPANY_CONDITION_NAME,b.CURR_JOB_SENIORITY_NAME,b.JOB_COMPANY_PROVINCE_NAME,
b.MONTH_SALARY_NAME,c.��˴����·�,c.��˴�������,c.refuse_name from bjb.apply_submart as a 
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
b.loc_1mcnt_silent,b.loc_1mmaxcnt_silent,b.loc_tqscore,b.loc_CreditxScore,b.ja_distance,b.ag_distance,b.jg_distance,b.סַ���ջ��ؾ���,
b.��λ���ջ��ؾ���,b.loc_bjscore from ttd_use as a left join bjb.event_all as  b on a.apply_code=b.apply_code;
quit;
proc sort data=ttd_use1 nodupkey;by apply_code;run;

**Tdrule;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=list dbms=excel replace;
sheet="Sheet1";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(����));
call symput("gzn_"||compress(_n_),compress(������));
if last then call symput("lpn",compress(_n_));
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use1 as 
select a.*,case when c.rule_decision^="" then "1.��" else "2.��" end as &&gzn_&i
from ttd_use1 as a
left join bjb.Tdrule_submart(where=(rule_name="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use1 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**BQSrule_ycsq �쳣����;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=list dbms=excel replace;
sheet="Sheet2";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(����));
call symput("gzn_"||compress(_n_),compress(������));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use2;
set ttd_use1;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use2 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as &&gzn_&i
from ttd_use2 as a
left join bjb.BQSrule_ycsq_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use2 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**BQSrule_jbgz;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=list dbms=excel replace;
sheet="Sheet3";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(����));
call symput("gzn_"||compress(_n_),compress(������));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use3;
set ttd_use2;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use3 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as &&gzn_&i
from ttd_use3 as a
left join bjb.BQSrule_jbgz_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use3 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**BQSrule_shixin;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=list dbms=excel replace;
sheet="Sheet4";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(����));
call symput("gzn_"||compress(_n_),compress(������));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use4;
set ttd_use3;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use4 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as &&gzn_&i
from ttd_use4 as a
left join bjb.BQSrule_shixin_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

**Bqsrule_fsds;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=list dbms=excel replace;
sheet="Sheet5";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(����));
call symput("gzn_"||compress(_n_),compress(������));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use5;
set ttd_use4;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table ttd_use5 as 
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as &&gzn_&i
from ttd_use5 as a
left join bjb.Bqsrule_fsds_submart(where=(rule_name_normal="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use5 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();

*ʹ��bjb.loanBQS_face_submart�������ϸ���˵Ӧ�û���������Ϊbjb.loanBQS_face_submart�����µĴ洢�ط������ǣ���������æ����-20170228;
proc sql;
create table ttd_use4_1 as
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as JBAA009
from ttd_use5 as a
left join bjb.Bqsrule_face_submart(where=(rule_name_normal="JBAA009_��Ƭ�ȶԽ����Ҫ�˹����")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4_1 nodupkey;by apply_code;run;

proc sql;
create table ttd_use4_2 as
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as JBAA012
from ttd_use4_1 as a
left join bjb.Bqsrule_face_submart(where=(rule_name_normal="JBAA012_δ��ȡ��������")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4_2 nodupkey;by apply_code;run;
proc sql;
create table ttd_use4_3 as
select a.*,case when c.rule_decision^="" or c.rule_score>0 then "1.��" else "2.��" end as FSSJ005
from ttd_use4_2 as a
left join bjb.Bqsrule_fsyys_submart(where=(rule_name="FSSJ005_�ֻ��Ź��������ס�������ؾ���һ��" and event_name="loan")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=ttd_use4_3 nodupkey;by apply_code;run;
proc sql;
create table ttd_use5 as
select a.*,b.grp_�����ע��,b.grp_cx_score,c.user_code,c.date_created as �����ύʱ��,d.apply_cnt_in7d,d.apply_cnt_in1m,d.apply_cnt_in3m,e.last_record_time,e.date_created
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
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=list dbms=excel replace;
sheet="Sheet6";
getnames=yes;
run;
data _null_;
set list  end=last;
call symput("gz_"||compress(_n_),compress(����));
call symput("gzn_"||compress(_n_),compress(������));
if last then call symput("lpn",compress(_n_));
run;
data ttd_use7;
set ttd_use6;
run;
%macro Average_TAT();
%do i =1 %to &lpn.;
proc sql;
create table bjb.ttd_use7 as 
select a.*,case when c.ruleType^="" then "1.��" else "2.��" end as &&gzn_&i
from ttd_use7 as a
left join bjb.risk_creditx_resp(where=(riskDesc="&&gz_&i")) as c on a.apply_code=c.apply_code;
quit;
proc sort data=bjb.ttd_use7 nodupkey;by apply_code;run;
%end;
%mend;
%Average_TAT();
 
data bjb.ml_Demograph;
set bjb.ttd_use7(drop=һ�¶�̨ ���¶�̨ �����̨);
input_complete=1;
*��ϵ��ͨѶ¼����:0-û��,999-����ûͨ����,ȱʧ-֮ǰû�������;

loc_addresscnt1 = input(loc_addresscnt,best12.);

/*format loc_register_date best32.;*/
format �����ύ��  ��˴�����   
��ͨ�绰����  ��ȥ��1���±���ʱ�� ��ȥ��2���±���ʱ�� ��ȥ��1��������ʱ�� ��ȥ��2��������ʱ�� ��ȥ��3���±���ʱ�� �¾����ѽ�� 8.;
��ͨ�绰����=loc_phonenum;
�¾����ѽ��=loc_ava_exp;
��ȥ��1���±���ʱ��=loc_inpast1st_calledtime;
��ȥ��2���±���ʱ��=loc_inpast2nd_calledtime;
��ȥ��3���±���ʱ��=loc_inpast3rd_calledtime;
��ȥ3���±���ʱ��=sum(��ȥ��1���±���ʱ��,��ȥ��2���±���ʱ��,��ȥ��3���±���ʱ��);
��ȥ��1��������ʱ��=loc_inpast1st_calltime;
��ȥ��2��������ʱ��=loc_inpast2nd_calltime;
��ȥ��3��������ʱ��=loc_inpast3rd_calltime;
��ȥ3��������ʱ��=sum(��ȥ��1��������ʱ��,��ȥ��2��������ʱ��,��ȥ��3��������ʱ��);

��ȥ��1����������ʱ��=sum(��ȥ��1��������ʱ��,��ȥ��1���±���ʱ��);
��ȥ��2����������ʱ��=sum(��ȥ��2��������ʱ��,��ȥ��2���±���ʱ��);
��ȥ��3����������ʱ��=sum(��ȥ��3��������ʱ��,��ȥ��3���±���ʱ��);

��ȥ3����������ʱ��=sum(��ȥ��1����������ʱ��,��ȥ��2����������ʱ��,��ȥ��3����������ʱ��);

��˴�����=mdy(ksubstr(��˴�������,6,2),ksubstr(��˴�������,9,2),ksubstr(��˴�������,1,4));
�����ύ��=datepart(�����ύʱ��);

ע��ʱ����=ksubstr(�����ύ����,1,4)-ksubstr(ID_CARD,7,4);

if JBAA012="1.��" then δ������="1.��";
if JBAA009="1.��" then ������="1.��";
�����ύ��=hour(�����ύʱ��);

format  ����ʱ�� ��ͨ�绰�������� 
��ȥ��1���±������� ��ȥ��1������������ ��ȥ��2���±������� ��ȥ��2������������ 
��ȥ��3���±������� ��ȥ��3������������ ��ȥ3���±������� ��ȥ3������������ 
��ȥ��1�������������� ��ȥ��2�������������� ��ȥ��3�������������� ��ȥ3�������������� �¾����ѽ������
��ż���� ��ĸ���� ��Ů���� �ֵ����� �������� �������� ͬ������ ͬѧ���� �������� �������� �ջ���ַ����
SEX_NAME_group age_g MARRIAGE_NAME_g DEGREE_NAME_g period_g JOB_g home_g company_g 
salary_g loc_appsl_g loc_txlsl_g  �����ύ��_g �����̨ һ�¶�̨ ���¶�̨ ֥������� ͨ�������������� �����Ĭ���� 
������Ĭ���� ��һ�Ĭ���� ��һ��Ĭ���� app�������� app�������� ����ռ�� ��һͨ�� ����ͨ�� ��һ���б� ��һ��ͨ�� ��һ������ 
������ͨ�� ���������� ��һ��ͨ�� ������ͨ�� ��һ��ͨ�� ������ͨ�� ��һ����ͨ�� ��������ͨ�� ��һ���ߴ� �������ߴ� ��һ�������  
����������� ��λ��ַ��סַ�������� סַ��GPS�������� ��λ��GPS�������� סַ���ջ��ؾ������� ��λ���ջ��ؾ������� ���������� ���������� $20.;

length company_province_g $100.;
format company_province_g $100.;

**��������ʱ��;
format ����ʱ�� yymmdd10.;
����ʱ��=mdy(substr(loc_register_date,6,2),substr(loc_register_date,9,2),substr(loc_register_date,1,4));
�����·�=intck("month",����ʱ��,�����ύ��);

format ���ͨ��ʱ�� datetime20.;
���ͨ��ʱ��=dhms(mdy(ksubstr(last_record_time,6,2),ksubstr(last_record_time,9,2),ksubstr(last_record_time,1,4)),ksubstr(last_record_time,12,2),ksubstr(last_record_time,15,2),ksubstr(last_record_time,18,2));
ͨ����������=sum(�����ύʱ��,-���ͨ��ʱ��)/(24*60*60);
if ͨ����������<0 or last_record_time="" then ͨ����������=.;

if last3m_callcnt_agg_spc_in =. then �����������="z-Missing";
else if last3m_callcnt_agg_spc_in=0 then �����������="1.[0]";
else if last3m_callcnt_agg_spc_in=1 then �����������="2.[1]";
else if last3m_callcnt_agg_spc_in=2 then �����������="3.[2]";
else if last3m_callcnt_agg_spc_in=3 then �����������="4.[3]";
else if last3m_callcnt_agg_spc_in=4 then �����������="5.[4]";
else if last3m_callcnt_agg_spc_in=5 then �����������="6.[5]";
else if last3m_callcnt_agg_spc_in=6 then �����������="7.[6]";
else if last3m_callcnt_agg_spc_in=7 then �����������="8.[7]";
else if last3m_callcnt_agg_spc_in<=9 then �����������="9.[8,9]";
else if last3m_callcnt_agg_spc_in>9 then �����������="9_1.[10+]";


if last1m_callcnt_agg_spc_in =. then ��һ�������="z-Missing";
else if last1m_callcnt_agg_spc_in=0 then ��һ�������="1.[0]";
else if last1m_callcnt_agg_spc_in=1 then ��һ�������="2.[1]";
else if last1m_callcnt_agg_spc_in=2 then ��һ�������="3.[2]";
else if last1m_callcnt_agg_spc_in=3 then ��һ�������="4.[3]";
else if last1m_callcnt_agg_spc_in=4 then ��һ�������="5.[4]";
else if last1m_callcnt_agg_spc_in<=6 then ��һ�������="6.[5,6]";
else if last1m_callcnt_agg_spc_in>6 then ��һ�������="7.[7+]";


if last3m_callcnt_agg_coll_in =. then �������ߴ�="z-Missing";
else if last3m_callcnt_agg_coll_in=0 then �������ߴ�="1.[0]";
else if last3m_callcnt_agg_coll_in=1 then �������ߴ�="2.[1]";
else if last3m_callcnt_agg_coll_in=2 then �������ߴ�="3.[2]";
else if last3m_callcnt_agg_coll_in=3 then �������ߴ�="4.[3]";
else if last3m_callcnt_agg_coll_in<=5 then �������ߴ�="5.[4,5]";
else if last3m_callcnt_agg_coll_in>5 then �������ߴ�="6.[6+]";


if last1m_callcnt_agg_coll_in =. then ��һ���ߴ�="z-Missing";
else if last1m_callcnt_agg_coll_in=0 then ��һ���ߴ�="1.[0]";
else if last1m_callcnt_agg_coll_in=1 then ��һ���ߴ�="2.[1]";
else if last1m_callcnt_agg_coll_in=2 then ��һ���ߴ�="3.[2]";
else if last1m_callcnt_agg_coll_in=3 then ��һ���ߴ�="4.[3]";
else if last1m_callcnt_agg_coll_in>3 then ��һ���ߴ�="5.[4+]";


if last3m_callplc_below_tier3cnt =. then ��������ͨ��="z-Missing";
else if last3m_callplc_below_tier3cnt=0 then ��������ͨ��="1.[0]";
else if last3m_callplc_below_tier3cnt<=10 then ��������ͨ��="2.[1,10]";
else if last3m_callplc_below_tier3cnt<=45 then ��������ͨ��="3.[11,45]";
else if last3m_callplc_below_tier3cnt<=120 then ��������ͨ��="4.[46,120]";
else if last3m_callplc_below_tier3cnt<=250 then ��������ͨ��="5.[121,250]";
else if last3m_callplc_below_tier3cnt<=400 then ��������ͨ��="6.[251,400]";
else if last3m_callplc_below_tier3cnt<=550 then ��������ͨ��="7.[401,550]";
else if last3m_callplc_below_tier3cnt<=750 then ��������ͨ��="8.[551,750]";
else if last3m_callplc_below_tier3cnt<=1000 then ��������ͨ��="9.[751,1000]";
else if last3m_callplc_below_tier3cnt<=1400 then ��������ͨ��="9_1.[1001,1400]";
else if last3m_callplc_below_tier3cnt>1400 then ��������ͨ��="9_2.[1401+]";

if last1m_callplc_below_tier3cnt =. then ��һ����ͨ��="z-Missing";
else if last1m_callplc_below_tier3cnt=0 then ��һ����ͨ��="1.[0]";
else if last1m_callplc_below_tier3cnt<=30 then ��һ����ͨ��="2.[1,30]";
else if last1m_callplc_below_tier3cnt<=80 then ��һ����ͨ��="3.[31,80]";
else if last1m_callplc_below_tier3cnt<=160 then ��һ����ͨ��="4.[81,160]";
else if last1m_callplc_below_tier3cnt<=250 then ��һ����ͨ��="5.[161,250]";
else if last1m_callplc_below_tier3cnt<=360 then ��һ����ͨ��="6.[251,360]";
else if last1m_callplc_below_tier3cnt<=470 then ��һ����ͨ��="7.[361,470]";
else if last1m_callplc_below_tier3cnt<=620 then ��һ����ͨ��="8.[471,620]";
else if last1m_callplc_below_tier3cnt<=830 then ��һ����ͨ��="9.[621,830]";
else if last1m_callplc_below_tier3cnt<=1200 then ��һ����ͨ��="9_1.[831,1200]";
else if last1m_callplc_below_tier3cnt>1200 then ��һ����ͨ��="9_2.[1201+]";

if last3m_callcnt_homeplace =. then ������ͨ��="z-Missing";
else if last3m_callcnt_homeplace=0 then ������ͨ��="1.[0]";
else if last3m_callcnt_homeplace<=30 then ������ͨ��="2.[1,30]";
else if last3m_callcnt_homeplace<=90 then ������ͨ��="3.[31,90]";
else if last3m_callcnt_homeplace<=170 then ������ͨ��="4.[91,170]";
else if last3m_callcnt_homeplace<=255 then ������ͨ��="5.[171,255]";
else if last3m_callcnt_homeplace<=370 then ������ͨ��="6.[256,370]";
else if last3m_callcnt_homeplace<=480 then ������ͨ��="7.[371,480]";
else if last3m_callcnt_homeplace<=630 then ������ͨ��="8.[481,630]";
else if last3m_callcnt_homeplace<=830 then ������ͨ��="9.[631,830]";
else if last3m_callcnt_homeplace<=1200 then ������ͨ��="9_1.[831,1200]";
else if last3m_callcnt_homeplace>1200 then ������ͨ��="9_2.[1201+]";

if last1m_callcnt_homeplace =. then ��һ��ͨ��="z-Missing";
else if last1m_callcnt_homeplace=0 then ��һ��ͨ��="1.[0]";
else if last1m_callcnt_homeplace<=10 then ��һ��ͨ��="2.[1,10]";
else if last1m_callcnt_homeplace<=30 then ��һ��ͨ��="3.[11,30]";
else if last1m_callcnt_homeplace<=50 then ��һ��ͨ��="4.[31,50]";
else if last1m_callcnt_homeplace<=85 then ��һ��ͨ��="5.[51,85]";
else if last1m_callcnt_homeplace<=120 then ��һ��ͨ��="6.[86,120]";
else if last1m_callcnt_homeplace<=160 then ��һ��ͨ��="7.[121,160]";
else if last1m_callcnt_homeplace<=215 then ��һ��ͨ��="8.[161,215]";
else if last1m_callcnt_homeplace<=290 then ��һ��ͨ��="9.[216,290]";
else if last1m_callcnt_homeplace<=400 then ��һ��ͨ��="9_1.[291,400]";
else if last1m_callcnt_homeplace>400 then ��һ��ͨ��="9_2.[401+]";


if last3m_callcnt_agg_shrt_out =. then ������ͨ��="z-Missing";
else if last3m_callcnt_agg_shrt_out=0 then ������ͨ��="1.[0]";
else if last3m_callcnt_agg_shrt_out<=10 then ������ͨ��="2.[1,10]";
else if last3m_callcnt_agg_shrt_out<=20 then ������ͨ��="3.[11,20]";
else if last3m_callcnt_agg_shrt_out<=35 then ������ͨ��="4.[21,35]";
else if last3m_callcnt_agg_shrt_out<=50 then ������ͨ��="5.[36,50]";
else if last3m_callcnt_agg_shrt_out<=70 then ������ͨ��="6.[51,70]";
else if last3m_callcnt_agg_shrt_out<=95 then ������ͨ��="7.[71,95]";
else if last3m_callcnt_agg_shrt_out<=130 then ������ͨ��="8.[96,130]";
else if last3m_callcnt_agg_shrt_out<=180 then ������ͨ��="9.[131,180]";
else if last3m_callcnt_agg_shrt_out<=270 then ������ͨ��="9_1.[181,270]";
else if last3m_callcnt_agg_shrt_out>270 then ������ͨ��="9_2.[271+]";


if last1m_callcnt_with_emergency =. then ��һ��ͨ��="z-Missing";
else if last1m_callcnt_with_emergency=0 then ��һ��ͨ��="1.[0]";
else if last1m_callcnt_with_emergency<=3 then ��һ��ͨ��="2.[1,3]";
else if last1m_callcnt_with_emergency<=8 then ��һ��ͨ��="3.[4,8]";
else if last1m_callcnt_with_emergency<=14 then ��һ��ͨ��="4.[9,14]";
else if last1m_callcnt_with_emergency<=21 then ��һ��ͨ��="5.[15,21]";
else if last1m_callcnt_with_emergency<=31 then ��һ��ͨ��="6.[22,31]";
else if last1m_callcnt_with_emergency<=46 then ��һ��ͨ��="7.[32,46]";
else if last1m_callcnt_with_emergency<=68 then ��һ��ͨ��="8.[47,68]";
else if last1m_callcnt_with_emergency<=117 then ��һ��ͨ��="9.[69,117]";
else if last1m_callcnt_with_emergency>117 then ��һ��ͨ��="9_1.[118+]";


if last3m_callcnt_agg_shrt_out =. then ����������="z-Missing";
else if last3m_callcnt_agg_shrt_out=0 then ����������="1.[0]";
else if last3m_callcnt_agg_shrt_out<=5 then ����������="2.[1,5]";
else if last3m_callcnt_agg_shrt_out<=9 then ����������="3.[6,9]";
else if last3m_callcnt_agg_shrt_out<=12 then ����������="4.[10,12]";
else if last3m_callcnt_agg_shrt_out<=16 then ����������="5.[13,16]";
else if last3m_callcnt_agg_shrt_out<=20 then ����������="6.[17,20]";
else if last3m_callcnt_agg_shrt_out<=26 then ����������="7.[21,26]";
else if last3m_callcnt_agg_shrt_out<=33 then ����������="8.[27,33]";
else if last3m_callcnt_agg_shrt_out<=44 then ����������="9.[34,44]";
else if last3m_callcnt_agg_shrt_out<=65 then ����������="9_1.[45,65]";
else if last3m_callcnt_agg_shrt_out>65 then ����������="9_2.[66+]";

if last3m_callcnt_agg_shrt =. then ������ͨ��="z-Missing";
else if last3m_callcnt_agg_shrt=0 then ������ͨ��="1.[0]";
else if last3m_callcnt_agg_shrt<=14 then ������ͨ��="2.[1,14]";
else if last3m_callcnt_agg_shrt<=23 then ������ͨ��="3.[15,23]";
else if last3m_callcnt_agg_shrt<=30 then ������ͨ��="4.[24,30]";
else if last3m_callcnt_agg_shrt<=40 then ������ͨ��="5.[31,40]";
else if last3m_callcnt_agg_shrt<=50 then ������ͨ��="6.[41,50]";
else if last3m_callcnt_agg_shrt<=60 then ������ͨ��="7.[51,60]";
else if last3m_callcnt_agg_shrt<=70 then ������ͨ��="8.[61,70]";
else if last3m_callcnt_agg_shrt<=95 then ������ͨ��="9.[71,95]";
else if last3m_callcnt_agg_shrt<=130 then ������ͨ��="9_1.[96,130]";
else if last3m_callcnt_agg_shrt>130 then ������ͨ��="9_2.[131+]";


if last1m_callcnt_agg_shrt_out =. then ��һ������="z-Missing";
else if last1m_callcnt_agg_shrt_out=0 then ��һ������="1.[0]";
else if last1m_callcnt_agg_shrt_out<=2 then ��һ������="2.[1,2]";
else if last1m_callcnt_agg_shrt_out<=4 then ��һ������="3.[3,4]";
else if last1m_callcnt_agg_shrt_out<=6 then ��һ������="4.[5,6]";
else if last1m_callcnt_agg_shrt_out<=8 then ��һ������="5.[7,8]";
else if last1m_callcnt_agg_shrt_out<=10 then ��һ������="6.[9,10]";
else if last1m_callcnt_agg_shrt_out<=14 then ��һ������="7.[11,14]";
else if last1m_callcnt_agg_shrt_out<=19 then ��һ������="8.[15,19]";
else if last1m_callcnt_agg_shrt_out<=35 then ��һ������="9.[20,35]";
else if last1m_callcnt_agg_shrt_out>35 then ��һ������="9_1.[36+]";


if last1m_callcnt_agg_shrt =. then ��һ��ͨ��="z-Missing";
else if last1m_callcnt_agg_shrt=0 then ��һ��ͨ��="1.[0]";
else if last1m_callcnt_agg_shrt<=4 then ��һ��ͨ��="2.[1,4]";
else if last1m_callcnt_agg_shrt<=7 then ��һ��ͨ��="3.[5,7]";
else if last1m_callcnt_agg_shrt<=10 then ��һ��ͨ��="4.[8,10]";
else if last1m_callcnt_agg_shrt<=13 then ��һ��ͨ��="5.[11,13]";
else if last1m_callcnt_agg_shrt<=17 then ��һ��ͨ��="6.[14,17]";
else if last1m_callcnt_agg_shrt<=21 then ��һ��ͨ��="7.[18,21]";
else if last1m_callcnt_agg_shrt<=26 then ��һ��ͨ��="8.[22,26]";
else if last1m_callcnt_agg_shrt<=34 then ��һ��ͨ��="9.[27,34]";
else if last1m_callcnt_agg_shrt<=50 then ��һ��ͨ��="9_1.[35,50]";
else if last1m_callcnt_agg_shrt>50 then ��һ��ͨ��="9_2.[51+]";


if app_type_cnt =. then app��������="z-Missing";
else if app_type_cnt=0 then app��������="1.[0]";
else if app_type_cnt<=4 then app��������="2.[1,4]";
else if app_type_cnt=5 then app��������="3.[5]";
else if app_type_cnt=6 then app��������="4.[6]";
else if app_type_cnt=7 then app��������="5.[7]";
else if app_type_cnt<=15 then app��������="6.[8,15]";
else if app_type_cnt>=16 then app��������="7.[16+]";

if app_total_cnt =. then app��������="z-Missing";
else if app_total_cnt=0 then app��������="1.[0]";
else if app_total_cnt<=5 then app��������="2.[1,5]";
else if app_total_cnt<=9 then app��������="3.[6,9]";
else if app_total_cnt<=14 then app��������="4.[10,14]";
else if app_total_cnt<=18 then app��������="5.[15,18]";
else if app_total_cnt<=33 then app��������="6.[19,33]";
else if app_total_cnt<=47 then app��������="7.[34,47]";
else if app_total_cnt<=60 then app��������="8.[48,60]";
else if app_total_cnt<=75 then app��������="9.[61,75]";
else if app_total_cnt<=100 then app��������="9_1.[76,100]";
else if app_total_cnt>=101 then app��������="9_2.[101+]";


if recent_device_available_capacity =. then ����ռ��="z-Missing";
else if recent_device_available_capacity=0 then ����ռ��="1.[0]";
else if recent_device_available_capacity<=0.04 then ����ռ��="2.[1%,4%]";
else if recent_device_available_capacity<=0.08 then ����ռ��="3.[5%,8%]";
else if recent_device_available_capacity<=0.14 then ����ռ��="4.[9%,14%]";
else if recent_device_available_capacity<=0.23 then ����ռ��="5.[15%,23%]";
else if recent_device_available_capacity<=0.35 then ����ռ��="6.[24%,35%]";
else if recent_device_available_capacity<=0.50 then ����ռ��="7.[36%,50%]";
else if recent_device_available_capacity<=0.65 then ����ռ��="8.[51%,65%]";
else if recent_device_available_capacity<=0.80 then ����ռ��="9.[66%,80%]";
else if recent_device_available_capacity<=0.90 then ����ռ��="9_1.[81%,90%]";
else if recent_device_available_capacity<=1 then ����ռ��="9_2.[91%+]";

if last1m_callcnt_agg =. then ��һͨ��="z-Missing";
else if last1m_callcnt_agg=0 then ��һͨ��="1.[0]";
else if last1m_callcnt_agg<=50 then ��һͨ��="2.[1,50]";
else if last1m_callcnt_agg<=100 then ��һͨ��="3.[51,100]";
else if last1m_callcnt_agg<=150 then ��һͨ��="4.[101,150]";
else if last1m_callcnt_agg<=175 then ��һͨ��="5.[151,175]";
else if last1m_callcnt_agg<=200 then ��һͨ��="6.[176,200]";
else if last1m_callcnt_agg<=250 then ��һͨ��="7.[201,250]";
else if last1m_callcnt_agg<=300 then ��һͨ��="8.[251,300]";
else if last1m_callcnt_agg<=400 then ��һͨ��="9.[301,400]";
else if last1m_callcnt_agg<=550 then ��һͨ��="9_1.[401,550]";
else if last1m_callcnt_agg>550 then ��һͨ��="9_2.[551+]";

if last3m_callcnt_agg =. then ����ͨ��="z-Missing";
else if last3m_callcnt_agg=0 then ����ͨ��="1.[0]";
else if last3m_callcnt_agg<=120 then ����ͨ��="2.[1,120]";
else if last3m_callcnt_agg<=250 then ����ͨ��="3.[121,250]";
else if last3m_callcnt_agg<=350 then ����ͨ��="4.[251,350]";
else if last3m_callcnt_agg<=450 then ����ͨ��="5.[351,450]";
else if last3m_callcnt_agg<=550 then ����ͨ��="6.[451,550]";
else if last3m_callcnt_agg<=650 then ����ͨ��="7.[551,650]";
else if last3m_callcnt_agg<=800 then ����ͨ��="8.[651,800]";
else if last3m_callcnt_agg<=950 then ����ͨ��="9.[801,950]";
else if last3m_callcnt_agg<=1200 then ����ͨ��="9_1.[951,1200]";
else if last3m_callcnt_agg<=1600 then ����ͨ��="9_2.[1201,1600]";
else if last3m_callcnt_agg>1600 then ����ͨ��="9_3.[1601+]";

if last1m_callcnt_rate_in =. then ��һ���б�="z-Missing";
else if last1m_callcnt_rate_in=0 then ��һ���б�="1.[0]";
else if last1m_callcnt_rate_in<=0.3 then ��һ���б�="2.[1%,30%]";
else if last1m_callcnt_rate_in<=0.4 then ��һ���б�="3.[31%,40%]";
else if last1m_callcnt_rate_in<=0.45 then ��һ���б�="4.[41%,45%]";
else if last1m_callcnt_rate_in<=0.5 then ��һ���б�="5.[46%,50%]";
else if last1m_callcnt_rate_in<=0.55 then ��һ���б�="6.[51%,55%]";
else if last1m_callcnt_rate_in<=0.6 then ��һ���б�="7.[56%,60%]";
else if last1m_callcnt_rate_in<=0.65 then ��һ���б�="8.[61%,65%]";
else if last1m_callcnt_rate_in<=0.7 then ��һ���б�="9.[66%,70%]";
else if last1m_callcnt_rate_in>0.7 then ��һ���б�="9_1.[71%+]";

if ͨ����������=. then ͨ��������������="z-Missing";
else if 0<ͨ����������<=5 then ͨ��������������="1.[1,5]";
else if 5<ͨ����������<=15 then ͨ��������������="2.[5,15]";
else if 15<ͨ����������<=30 then ͨ��������������="3.[15,30]";
else if ͨ����������>30 then ͨ��������������="4.[30+]";

if loc_3mmaxcnt_silent=. then �����Ĭ����="z-Missing";
else if loc_3mmaxcnt_silent=0 then �����Ĭ����="1.[0]";
else if 0<loc_3mmaxcnt_silent<=5 then �����Ĭ����="2.[1,5]";
else if 5<loc_3mmaxcnt_silent<=15 then �����Ĭ����="3.[5,15]";
else if 15<loc_3mmaxcnt_silent<=30 then �����Ĭ����="4.[15,30]";
else if loc_3mmaxcnt_silent>30 then �����Ĭ����="5.[30+]";

if loc_3mcnt_silent=. then ������Ĭ����="z-Missing";
else if loc_3mcnt_silent=0 then ������Ĭ����="1.[0]";
else if 0<loc_3mcnt_silent<=5 then ������Ĭ����="2.[1,5]";
else if 5<loc_3mcnt_silent<=15 then ������Ĭ����="3.[5,15]";
else if 15<loc_3mcnt_silent<=30 then ������Ĭ����="4.[15,30]";
else if loc_3mcnt_silent>30 then ������Ĭ����="5.[30+]";

if loc_1mmaxcnt_silent=. then ��һ�Ĭ����="z-Missing";
else if loc_1mmaxcnt_silent=0 then ��һ�Ĭ����="1.[0]";
else if 0<loc_1mmaxcnt_silent<=5 then ��һ�Ĭ����="2.[1,5]";
else if 5<loc_1mmaxcnt_silent<=15 then ��һ�Ĭ����="3.[5,15]";
else if 15<loc_1mmaxcnt_silent<=30 then ��һ�Ĭ����="4.[15,30]";
else if loc_1mmaxcnt_silent>30 then ��һ�Ĭ����="5.[30+]";

if loc_1mcnt_silent=. then ��һ��Ĭ����="z-Missing";
else if loc_1mcnt_silent=0 then ��һ��Ĭ����="1.[0]";
else if 0<loc_1mcnt_silent<=5 then ��һ��Ĭ����="2.[1,5]";
else if 5<loc_1mcnt_silent<=15 then ��һ��Ĭ����="3.[5,15]";
else if 15<loc_1mcnt_silent<=30 then ��һ��Ĭ����="4.[15,30]";
else if loc_1mcnt_silent>30 then ��һ��Ĭ����="5.[30+]";


if loc_tel_qt_rank=0 then ��������="1.û��";
else if 1<=loc_tel_qt_rank<=5 then ��������="2.1-5��";
else if 5<loc_tel_qt_rank<=10 then ��������="3.5-10��";
else if loc_tel_qt_rank>10 then ��������="4.10������";
else if loc_tel_qt_rank=999 then ��������="5.����û��";
else if loc_tel_qt_rank=. then ��������="6.��";

if loc_tel_py_rank=0 then ��������="1.û��";
else if 1<=loc_tel_py_rank<=5 then ��������="2.1-5��";
else if 5<loc_tel_py_rank<=10 then ��������="3.5-10��";
else if loc_tel_py_rank>10 then ��������="4.10������";
else if loc_tel_py_rank=999 then ��������="5.����û��";
else if loc_tel_py_rank=. then ��������="6.��";

if loc_tel_tx_rank=0 then ͬѧ����="1.û��";
else if 1<=loc_tel_tx_rank<=5 then ͬѧ����="2.1-5��";
else if 5<loc_tel_tx_rank<=10 then ͬѧ����="3.5-10��";
else if loc_tel_tx_rank>10 then ͬѧ����="4.10������";
else if loc_tel_tx_rank=999 then ͬѧ����="5.����û��";
else if loc_tel_tx_rank=. then ͬѧ����="6.��";

if loc_tel_ts_rank=0 then ͬ������="1.û��";
else if 1<=loc_tel_ts_rank<=5 then ͬ������="2.1-5��";
else if 5<loc_tel_ts_rank<=10 then ͬ������="3.5-10��";
else if loc_tel_ts_rank>10 then ͬ������="4.10������";
else if loc_tel_ts_rank=999 then ͬ������="5.����û��";
else if loc_tel_ts_rank=. then ͬ������="6.��";

if loc_tel_qs_rank=0 then ��������="1.û��";
else if 1<=loc_tel_qs_rank<=5 then ��������="2.1-5��";
else if 5<loc_tel_qs_rank<=10 then ��������="3.5-10��";
else if loc_tel_qs_rank>10 then ��������="4.10������";
else if loc_tel_qs_rank=999 then ��������="5.����û��";
else if loc_tel_qs_rank=. then ��������="6.��";

if loc_tel_jm_rank=0 then ��������="1.û��";
else if 1<=loc_tel_jm_rank<=5 then ��������="2.1-5��";
else if 5<loc_tel_jm_rank<=10 then ��������="3.5-10��";
else if loc_tel_jm_rank>10 then ��������="4.10������";
else if loc_tel_jm_rank=999 then ��������="5.����û��";
else if loc_tel_jm_rank=. then ��������="6.��";

if loc_tel_xd_rank=0 then �ֵ�����="1.û��";
else if 1<=loc_tel_xd_rank<=5 then �ֵ�����="2.1-5��";
else if 5<loc_tel_xd_rank<=10 then �ֵ�����="3.5-10��";
else if loc_tel_xd_rank>10 then �ֵ�����="4.10������";
else if loc_tel_xd_rank=999 then �ֵ�����="5.����û��";
else if loc_tel_xd_rank=. then �ֵ�����="6.��";

if loc_tel_zn_rank=0 then ��Ů����="1.û��";
else if 1<=loc_tel_zn_rank<=5 then ��Ů����="2.1-5��";
else if 5<loc_tel_zn_rank<=10 then ��Ů����="3.5-10��";
else if loc_tel_zn_rank>10 then ��Ů����="4.10������";
else if loc_tel_zn_rank=999 then ��Ů����="5.����û��";
else if loc_tel_zn_rank=. then ��Ů����="6.��";

if loc_tel_fm_rank=0 then ��ĸ����="1.û��";
else if 1<=loc_tel_fm_rank<=5 then ��ĸ����="2.1-5��";
else if 5<loc_tel_fm_rank<=10 then ��ĸ����="3.5-10��";
else if 10<loc_tel_fm_rank<=20 then ��ĸ����="4.10-20��";
else if 20<loc_tel_fm_rank<=30 then ��ĸ����="5.20-30��";
else if 30<loc_tel_fm_rank<=40 then ��ĸ����="6.30-40��";
else if 40<loc_tel_fm_rank<=50 then ��ĸ����="7.40-50��";
else if loc_tel_fm_rank>50 then ��ĸ����="8.50������";
else if loc_tel_fm_rank=999 then ��ĸ����="9.����û��";
else if loc_tel_fm_rank=. then ��ĸ����="9_1.��";

if loc_tel_po_rank=0 then ��ż����="1.û��";
else if 1<=loc_tel_po_rank<=5 then ��ż����="2.1-5��";
else if 5<=loc_tel_po_rank<=10 then ��ż����="3.5-10��";
else if loc_tel_po_rank>10 then ��ż����="4.10������";
else if loc_tel_po_rank=999 then ��ż����="5.����û��";
else if loc_tel_po_rank=. then ��ż����="6.��";

if �¾����ѽ��=0 then �¾����ѽ������="1.0Ԫ";
else if  0<�¾����ѽ��<=20000 then �¾����ѽ������="2.0-200Ԫ";
else if  20000<�¾����ѽ��<=50000 then �¾����ѽ������="3.200-500Ԫ";
else if        �¾����ѽ��>50000 then �¾����ѽ������="4.500Ԫ+";
else if �¾����ѽ��=. then �¾����ѽ������="5.��";

if loc_addresscnt1=0 then �ջ���ַ����="1.0��";
else if  0<loc_addresscnt1<=4 then �ջ���ַ����="2.1-4��";
else if  loc_addresscnt1>4 then �ջ���ַ����="3.4��+";
else if loc_addresscnt1=. then �ջ���ַ����="4.��";

if 0<=��ȥ3����������ʱ��<=27000 then ��ȥ3��������������="1.0-450����";
else if  27000<��ȥ3����������ʱ��<=45000 then ��ȥ3��������������="2.450-750����";
else if  ��ȥ3����������ʱ��>45000 then ��ȥ3��������������="3.750����+";
else if ��ȥ3����������ʱ��=. then ��ȥ3��������������="4.��";

if 0<=��ȥ��3����������ʱ��<=10200 then ��ȥ��3��������������="1.0-170����";
else if  10200<��ȥ��3����������ʱ��<=18000 then ��ȥ��3��������������="2.170-300����";
else if  ��ȥ��3����������ʱ��>18000 then ��ȥ��3��������������="3.300����+";
else if ��ȥ��3����������ʱ��=. then ��ȥ��3��������������="4.��";

if 0<=��ȥ��2����������ʱ��<=10200 then ��ȥ��2��������������="1.0-170����";
else if  10200<��ȥ��2����������ʱ��<=18000 then ��ȥ��2��������������="2.170-300����";
else if  ��ȥ��2����������ʱ��>18000 then ��ȥ��2��������������="3.300����+";
else if ��ȥ��2����������ʱ��=. then ��ȥ��2��������������="4.��";

if 0<=��ȥ��1����������ʱ��<=3000 then ��ȥ��1��������������="1.0-50����";
else if  3000<��ȥ��1����������ʱ��<=7800 then ��ȥ��1��������������="2.50-130����";
else if  ��ȥ��1����������ʱ��>7800 then ��ȥ��1��������������="3.130����+";
else if ��ȥ��1����������ʱ��=. then ��ȥ��1��������������="4.��";

if 0<=��ȥ3��������ʱ��<=12000 then ��ȥ3������������="1.0-200����";
else if  12000<��ȥ3��������ʱ��<=21000 then ��ȥ3������������="2.200-350����";
else if  ��ȥ3��������ʱ��>21000 then ��ȥ3������������="3.350����+";
else if ��ȥ3��������ʱ��=. then ��ȥ3������������="4.��";

if 0<=��ȥ3���±���ʱ��<=12000 then ��ȥ3���±�������="1.0-200����";
else if  12000<��ȥ3���±���ʱ��<=21000 then ��ȥ3���±�������="2.200-350����";
else if  ��ȥ3���±���ʱ��>21000 then ��ȥ3���±�������="3.350����+";
else if ��ȥ3���±���ʱ��=. then ��ȥ3���±�������="4.��";

if 0<=��ȥ��3��������ʱ��<=4800 then ��ȥ��3������������="1.0-80����";
else if  4800<��ȥ��3��������ʱ��<=9000 then ��ȥ��3������������="2.80-150����";
else if  ��ȥ��3��������ʱ��>9000 then ��ȥ��3������������="3.150����+";
else if ��ȥ��3��������ʱ��=. then ��ȥ��3������������="4.��";

if 0<=��ȥ��3���±���ʱ��<=4800 then ��ȥ��3���±�������="1.0-80����";
else if  4800<��ȥ��3���±���ʱ��<=9000 then ��ȥ��3���±�������="2.80-150����";
else if  ��ȥ��3���±���ʱ��>9000 then ��ȥ��3���±�������="3.150����+";
else if ��ȥ��3���±���ʱ��=. then ��ȥ��3���±�������="4.��";

if 0<=��ȥ��2��������ʱ��<=4800 then ��ȥ��2������������="1.0-80����";
else if  4800<��ȥ��2��������ʱ��<=9000 then ��ȥ��2������������="2.80-150����";
else if  ��ȥ��2��������ʱ��>9000 then ��ȥ��2������������="3.150����+";
else if ��ȥ��2��������ʱ��=. then ��ȥ��2������������="4.��";

if 0<=��ȥ��2���±���ʱ��<=4800 then ��ȥ��2���±�������="1.0-80����";
else if  4800<��ȥ��2���±���ʱ��<=9000 then ��ȥ��2���±�������="2.80-150����";
else if  ��ȥ��2���±���ʱ��>9000 then ��ȥ��2���±�������="3.150����+";
else if ��ȥ��2���±���ʱ��=. then ��ȥ��2���±�������="4.��";


if 0<=��ȥ��1��������ʱ��<=1200 then ��ȥ��1������������="1.0-20����";
else if  1200<��ȥ��1��������ʱ��<=4200 then ��ȥ��1������������="2.20-70����";
else if  ��ȥ��1��������ʱ��>4200 then ��ȥ��1������������="3.70����+";
else if ��ȥ��1��������ʱ��=. then ��ȥ��1������������="4.��";

if 0<=��ȥ��1���±���ʱ��<=1200 then ��ȥ��1���±�������="1.0-20����";
else if  1200<��ȥ��1���±���ʱ��<=4200 then ��ȥ��1���±�������="2.20-70����";
else if  ��ȥ��1���±���ʱ��>4200 then ��ȥ��1���±�������="3.70����+";
else if ��ȥ��1���±���ʱ��=. then ��ȥ��1���±�������="4.��";

if 0<=�����·�<=12 then ����ʱ��="1.0-1��";
else if 12<�����·�<=24 then  ����ʱ��="2.1-2��";
else if 24<�����·�<=36 then  ����ʱ��="3.2-3��";
else if 36<�����·�<=48 then  ����ʱ��="4.3-4��";
else if 48<�����·�<=60 then  ����ʱ��="5.4-5��";
else if 60<�����·�<=96 then  ����ʱ��="6.5-8��";
else if    �����·�>96 then  ����ʱ��="7.8��+";
else if �����·�=. then ����ʱ��="8.��";

if 0<=��ͨ�绰����<=30 then ��ͨ�绰��������="1.0-30��";
else if  30<��ͨ�绰����<=50 then ��ͨ�绰��������="2.30-50��";
else if  ��ͨ�绰����>50 then ��ͨ�绰��������="3.50��+";
else if ��ͨ�绰����=. then ��ͨ�绰��������="4.��";


if 0<=apply_cnt_in7d<=2 then �����̨="1.0-2��";
else if 2<apply_cnt_in7d<=3 then �����̨="2.3��";
else if 3<apply_cnt_in7d<=4 then �����̨="3.4��";
else if 4<apply_cnt_in7d<=5 then �����̨="4.5��";
else if 5<apply_cnt_in7d<=6 then �����̨="5.6��";
else if 6<apply_cnt_in7d<=10 then �����̨="6.7-10��";
else if apply_cnt_in7d>10 then �����̨="7.11������";
if apply_cnt_in7d=. then �����̨="8.��";

if 0<=apply_cnt_in1m<=2 then һ�¶�̨="1.0-2��";
else if 2<apply_cnt_in1m<=5 then һ�¶�̨="2.3-5��";
else if 5<apply_cnt_in1m<=8 then һ�¶�̨="3.6-8��";
else if apply_cnt_in1m>8 then һ�¶�̨="4.9������";
if apply_cnt_in1m=. then һ�¶�̨="5.��";

if 0<=apply_cnt_in3m<=5 then ���¶�̨="1.0-5��";
else if 5<apply_cnt_in3m<=10 then ���¶�̨="2.6-10��";
else if 10<apply_cnt_in3m<=14 then ���¶�̨="3.11-14��";
else if 14<apply_cnt_in3m<=15 then ���¶�̨="4.15��";
else if apply_cnt_in3m>15 then ���¶�̨="5.16������";
if apply_cnt_in3m=. then ���¶�̨="6.��";

if 1<=�����ύ��<=5 then �����ύ��_g="1.1-5��";
else if 6<=�����ύ��<=10 then �����ύ��_g="2.6-10��";
else if 11<=�����ύ��<=15 then �����ύ��_g="3.11-15��";
else if 16<=�����ύ��<=20 then �����ύ��_g="4.16-20��";
else if �����ύ��>=21 or �����ύ��=0 then �����ύ��_g="5.21-24��";


if 0<=loc_txlsl<10 then loc_txlsl_g="1. 0-9��";
else if 10<=loc_txlsl<20 then loc_txlsl_g="2. 10-19��";
else if 20<=loc_txlsl<30 then loc_txlsl_g="3. 20-29��";
else if 30<=loc_txlsl<50 then loc_txlsl_g="4. 30-49��";
else if 50<=loc_txlsl<100 then loc_txlsl_g="5. 50-99��";
else if loc_txlsl>=100 then loc_txlsl_g="6. 100������";


if loc_appsl=0 then loc_appsl_g="1. 0��";
else if loc_appsl=1 then loc_appsl_g="2. 1��";
else if loc_appsl=2 then loc_appsl_g="3. 2��";
else if loc_appsl=3 then loc_appsl_g="4. 3��";
else if loc_appsl=4 then loc_appsl_g="5. 4��";
else if loc_appsl=5 then loc_appsl_g="6. 5��";
else if 5<loc_appsl<=10 then loc_appsl_g="7. 6-10��";
else if 10<loc_appsl<=15 then loc_appsl_g="8. 11-15��";
else if loc_appsl>15 then loc_appsl_g="9. 16������";

if ������="�˹�ͨ��" then check_final=1;else check_final=0;

if  MONTH_SALARY_NAME="2000����" then salary_g="1.2000����";
else if MONTH_SALARY_NAME="2000-2999" then salary_g="2.2000-2999";
else if MONTH_SALARY_NAME="3000-4999" then salary_g="3.3000-4999";
else if MONTH_SALARY_NAME="5000-7999" then salary_g="4.5000-7999";
else if MONTH_SALARY_NAME="8000-11999" then salary_g="5.8000-11999";
else if MONTH_SALARY_NAME="12000������" then salary_g="6.12000������";

if SEX_NAME="��" then SEX_NAME_group="214-��";
else if SEX_NAME="Ů" then SEX_NAME_group="215-Ů";

if ע��ʱ����=18 then age_g="0.18��";
else if 19<=ע��ʱ����<=25 then age_g="1.19-25��";
else if 26<=ע��ʱ����<=30 then age_g="2.26-30��";
else if 31<=ע��ʱ����<=36 then age_g="3.31-36��";
else if ע��ʱ����>36  then age_g="4.>36��";

if MARRIAGE_NAME="δ��" then MARRIAGE_NAME_g="1.δ��";
else if MARRIAGE_NAME="�ѻ�δ��" then MARRIAGE_NAME_g="2.�ѻ�δ��";
else if MARRIAGE_NAME="�ѻ�����" then MARRIAGE_NAME_g="3.�ѻ�����";
else if MARRIAGE_NAME="����" then MARRIAGE_NAME_g="4.����";
else if MARRIAGE_NAME="ɥż" then MARRIAGE_NAME_g="5.ɥż";
else if MARRIAGE_NAME="����" then MARRIAGE_NAME_g="6.����";

if DEGREE_NAME="˶ʿ������" then DEGREE_NAME_g="1.˶ʿ������";
else if DEGREE_NAME="����" then DEGREE_NAME_g="2.����";
else if DEGREE_NAME="��ר" then DEGREE_NAME_g="3.��ר";
else if DEGREE_NAME="���л���ר" then DEGREE_NAME_g="4.���л���ר";
else if DEGREE_NAME="���м�����" then DEGREE_NAME_g="5.���м�����";

if period=7 then period_g="1.7��";
else if period=14 then period_g="2.14��";
else if period=21 then period_g="3.21��";
else if period=28 then period_g="4.28��";

if CURR_JOB_SENIORITY_NAME="3��������" then JOB_g="1.3��������";
else if  CURR_JOB_SENIORITY_NAME="3��6����" then JOB_g="2.3��6����";
else if  CURR_JOB_SENIORITY_NAME="6���¡�1��" then JOB_g="3.6���¡�1��";
else if  CURR_JOB_SENIORITY_NAME="1~2��" then JOB_g="4.1~2��";
else if  CURR_JOB_SENIORITY_NAME="2��5��" then JOB_g="5.2��5��";
else if  CURR_JOB_SENIORITY_NAME="5������" then JOB_g="6.5������";

if RESIDENCE_CONDITION_NAME="�챾�޵�Ѻ��" then home_g="1.�챾�޵�Ѻ��";
else if RESIDENCE_CONDITION_NAME="��Ѻ���ҷ�" then home_g="2.��Ѻ���ҷ�";
else if RESIDENCE_CONDITION_NAME="���巿" then home_g="3.���巿";
else if RESIDENCE_CONDITION_NAME="�ⷿ" then home_g="4.�ⷿ";
else if RESIDENCE_CONDITION_NAME="��λ����" then home_g="5.��λ����";
else if RESIDENCE_CONDITION_NAME="����" then home_g="6.����";

if  JOB_COMPANY_CONDITION_NAME="����������ҵ��λ" then company_g="1.����������ҵ��λ";
else if JOB_COMPANY_CONDITION_NAME="������ҵ" then company_g="2.������ҵ";
else if JOB_COMPANY_CONDITION_NAME="���й�˾�����ʺ�����ҵ" then company_g="3.���й�˾�����ʺ�����ҵ";
else if JOB_COMPANY_CONDITION_NAME="��Ӫ��ҵ" then company_g="4.��Ӫ��ҵ";
else if JOB_COMPANY_CONDITION_NAME="����" then company_g="5.����";
else if JOB_COMPANY_CONDITION_NAME="����" then company_g="6.����";

if JOB_COMPANY_PROVINCE_NAME="������" then company_province_g="110000-������";
else if JOB_COMPANY_PROVINCE_NAME="�����" then company_province_g="120000-�����";
else if JOB_COMPANY_PROVINCE_NAME="�ӱ�ʡ" then company_province_g="130000-�ӱ�ʡ";
else if JOB_COMPANY_PROVINCE_NAME="ɽ��ʡ" then company_province_g="140000-ɽ��ʡ";
else if JOB_COMPANY_PROVINCE_NAME="���ɹ�������" then company_province_g="150000-���ɹ�������";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="210000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="220000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="������ʡ" then company_province_g="230000-������ʡ";
else if JOB_COMPANY_PROVINCE_NAME="�Ϻ���" then company_province_g="310000-�Ϻ���";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="320000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="�㽭ʡ" then company_province_g="330000-�㽭ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="340000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="350000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="360000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="ɽ��ʡ" then company_province_g="370000-ɽ��ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="410000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="420000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="430000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="�㶫ʡ" then company_province_g="440000-�㶫ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����׳��������" then company_province_g="450000-����׳��������";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="460000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="������" then company_province_g="500000-������";
else if JOB_COMPANY_PROVINCE_NAME="�Ĵ�ʡ" then company_province_g="510000-�Ĵ�ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="520000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="530000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����������" then company_province_g="540000-����������";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="610000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="����ʡ" then company_province_g="620000-����ʡ";
else if JOB_COMPANY_PROVINCE_NAME="�ຣʡ" then company_province_g="630000-�ຣʡ";
else if JOB_COMPANY_PROVINCE_NAME="���Ļ���������" then company_province_g="640000-���Ļ���������";
else if JOB_COMPANY_PROVINCE_NAME="�½�ά���������" then company_province_g="650000-�½�ά���������";

if ja_distance in (.,0) then ��λ��ַ��סַ��������="z-Missing";
else if 0<=ja_distance<0.1 then ��λ��ַ��סַ��������="1.(0,0.1)";
else if 0.1<=ja_distance<0.2 then ��λ��ַ��סַ��������="2.[0.1,0.2)";
else if 0.2<=ja_distance<0.3 then ��λ��ַ��סַ��������="3.[0.2,0.3)";
else if 0.3<=ja_distance<0.4 then ��λ��ַ��סַ��������="4.[0.3,0.4)";
else if 0.4<=ja_distance<0.5 then ��λ��ַ��סַ��������="5.[0.4,0.5)";
else if 0.5<=ja_distance<1 then ��λ��ַ��סַ��������="6.[0.5,1)";
else if 1<=ja_distance<5 then ��λ��ַ��סַ��������="7.[1,5)";
else if 5<=ja_distance<10 then ��λ��ַ��סַ��������="8.[5,10)";
else if 10<=ja_distance<20 then ��λ��ַ��סַ��������="9.[10,20)";
else if 20<=ja_distance<30 then ��λ��ַ��סַ��������="9_1.[20,30)";
else if ja_distance>30 then ��λ��ַ��סַ��������="9_2.[30,6000)";

if ag_distance in (.,0) then סַ��GPS��������="z-Missing";
else if 0<=ag_distance<0.1 then סַ��GPS��������="1.(0,0.1)";
else if 0.1<=ag_distance<0.2 then סַ��GPS��������="2.[0.1,0.2)";
else if 0.2<=ag_distance<0.3 then סַ��GPS��������="3.[0.2,0.3)";
else if 0.3<=ag_distance<0.4 then סַ��GPS��������="4.[0.3,0.4)";
else if 0.4<=ag_distance<0.5 then סַ��GPS��������="5.[0.4,0.5)";
else if 0.5<=ag_distance<1 then סַ��GPS��������="6.[0.5,1)";
else if 1<=ag_distance<5 then סַ��GPS��������="7.[1,5)";
else if 5<=ag_distance<10 then סַ��GPS��������="8.[5,10)";
else if 10<=ag_distance<20 then סַ��GPS��������="9.[10,20)";
else if 20<=ag_distance<30 then סַ��GPS��������="9_1.[20,30)";
else if ag_distance>30 then סַ��GPS��������="9_2.[30,6000)";

if jg_distance in (.,0) then ��λ��GPS��������="z-Missing";
else if 0<=jg_distance<0.1 then ��λ��GPS��������="1.(0,0.1)";
else if 0.1<=jg_distance<0.2 then ��λ��GPS��������="2.[0.1,0.2)";
else if 0.2<=jg_distance<0.3 then ��λ��GPS��������="3.[0.2,0.3)";
else if 0.3<=jg_distance<0.4 then ��λ��GPS��������="4.[0.3,0.4)";
else if 0.4<=jg_distance<0.5 then ��λ��GPS��������="5.[0.4,0.5)";
else if 0.5<=jg_distance<1 then ��λ��GPS��������="6.[0.5,1)";
else if 1<=jg_distance<5 then ��λ��GPS��������="7.[1,5)";
else if 5<=jg_distance<10 then ��λ��GPS��������="8.[5,10)";
else if 10<=jg_distance<20 then ��λ��GPS��������="9.[10,20)";
else if 20<=jg_distance<30 then ��λ��GPS��������="9_1.[20,30)";
else if jg_distance>30 then ��λ��GPS��������="9_2.[30,6000)";

if סַ���ջ��ؾ��� in (.,0) then סַ���ջ��ؾ�������="z-Missing";
else if 0<=סַ���ջ��ؾ���<0.1 then סַ���ջ��ؾ�������="1.(0,0.1)";
else if 0.1<=סַ���ջ��ؾ���<0.2 then סַ���ջ��ؾ�������="2.[0.1,0.2)";
else if 0.2<=סַ���ջ��ؾ���<0.3 then סַ���ջ��ؾ�������="3.[0.2,0.3)";
else if 0.3<=סַ���ջ��ؾ���<0.4 then סַ���ջ��ؾ�������="4.[0.3,0.4)";
else if 0.4<=סַ���ջ��ؾ���<0.5 then סַ���ջ��ؾ�������="5.[0.4,0.5)";
else if 0.5<=סַ���ջ��ؾ���<1 then סַ���ջ��ؾ�������="6.[0.5,1)";
else if 1<=סַ���ջ��ؾ���<5 then סַ���ջ��ؾ�������="7.[1,5)";
else if 5<=סַ���ջ��ؾ���<10 then סַ���ջ��ؾ�������="8.[5,10)";
else if 10<=סַ���ջ��ؾ���<20 then סַ���ջ��ؾ�������="9.[10,20)";
else if 20<=סַ���ջ��ؾ���<30 then סַ���ջ��ؾ�������="9_1.[20,30)";
else if סַ���ջ��ؾ���>30 then סַ���ջ��ؾ�������="9_2.[30,6000)";

if ��λ���ջ��ؾ��� in (.,0) then ��λ���ջ��ؾ�������="z-Missing";
else if 0<=��λ���ջ��ؾ���<0.1 then ��λ���ջ��ؾ�������="1.(0,0.1)";
else if 0.1<=��λ���ջ��ؾ���<0.2 then ��λ���ջ��ؾ�������="2.[0.1,0.2)";
else if 0.2<=��λ���ջ��ؾ���<0.3 then ��λ���ջ��ؾ�������="3.[0.2,0.3)";
else if 0.3<=��λ���ջ��ؾ���<0.4 then ��λ���ջ��ؾ�������="4.[0.3,0.4)";
else if 0.4<=��λ���ջ��ؾ���<0.5 then ��λ���ջ��ؾ�������="5.[0.4,0.5)";
else if 0.5<=��λ���ջ��ؾ���<1 then ��λ���ջ��ؾ�������="6.[0.5,1)";
else if 1<=��λ���ջ��ؾ���<5 then ��λ���ջ��ؾ�������="7.[1,5)";
else if 5<=��λ���ջ��ؾ��� <10 then ��λ���ջ��ؾ�������="8.[5,10)";
else if 10<=��λ���ջ��ؾ���<20 then ��λ���ջ��ؾ�������="9.[10,20)";
else if 20<=��λ���ջ��ؾ���<30 then ��λ���ջ��ؾ�������="9_1.[20,30)";
else if ��λ���ջ��ؾ���>30 then ��λ���ջ��ؾ�������="9_2.[30,6000)";

if loc_zmscore in (.,0) then ֥�������="z-Missing";
else if 350<=loc_zmscore<500 then ֥�������="1.[350,500)";
else if 500<=loc_zmscore<550 then ֥�������="2.[500,550)";
else if 550<=loc_zmscore<600 then ֥�������="3.[550,600)";
else if 600<=loc_zmscore<620 then ֥�������="4.[600,620)";
else if 620<=loc_zmscore<650 then ֥�������="5.[620,650)";
else if 650<=loc_zmscore<700 then ֥�������="6.[650,700)";
else if loc_zmscore>=700 then ֥�������="7.[700+]";

if loc_tqscore in (.,0) then ����������="z-Missing";
else if 0<=loc_tqscore<408 then ����������="1.(0,408)";
else if loc_tqscore=408 then ����������="2.408";
else if 408<loc_tqscore<450 then ����������="3.(408,450)";
else if 450<=loc_tqscore<500 then ����������="4.[450,500)";
else if 500<=loc_tqscore<550 then ����������="5.[500,550)";
else if 550<=loc_tqscore<600 then ����������="6.[550,600)";
else if 600<=loc_tqscore<650 then ����������="7.[600,650)";
else if 650<=loc_tqscore<850 then ����������="8.[650,850)";

if loc_bjscore in (.,0) then ����������="z-Missing";
else if loc_bjscore in (-1) then ����������="-1";
else if 0<=loc_bjscore<400 then ����������="1.[0,400)";
else if 400<=loc_bjscore<450 then ����������="2.[400,450)";
else if 450<=loc_bjscore<500 then ����������="3.[450,500)";
else if 500<=loc_bjscore<550 then ����������="4.[500,550)";
else if 550<=loc_bjscore<600 then ����������="5.[550,600)";
else if 600<=loc_bjscore<650 then ����������="6.[600,650)";
else if 650<=loc_bjscore<750 then ����������="7.[650,750)";
else if loc_bjscore>=750 then ����������="8.[750+]";

run;


*gogogoggogogoggogogog;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=var_name dbms=excel replace;
sheet="ά�ȱ���";
getnames=yes;
run;
proc import datafile="F:\����Demographics\����demo���ñ�.xls"
out=var_name_left dbms=excel replace;
sheet="ճ��ģ��";
getnames=yes;
run;


**����AB�ı�ǩ;
proc sort data=bjb.apply_flag nodupkey;by apply_code;run;
proc sort data=bjb.ml_Demograph(drop = �״����� �������� loc_abmoduleflag ������ǩ) nodupkey;by apply_code;run;

data bjb.ml_Demograph;
merge bjb.ml_Demograph(in = a) bjb.apply_flag(in = b);
by apply_code;
if a;
run;
proc sort data = bjb.ml_Demograph nodupkey; by apply_code; run;


data submart.ml_Demograph;
set bjb.ml_Demograph;
run;
