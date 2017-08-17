option compress = yes validvarname = any;
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";
libname bjb "F:\米粒Demographics\data";
libname benzi "F:\米粒demographics_simple_channel\data";
libname repayFin "F:\米粒逾期日报表\data";

proc import datafile="F:\米粒Demographics简版\米粒demo配置表_simple.xls"
out=var_name dbms=excel replace;
sheet="维度变量";
getnames=yes;
run;
proc import datafile="F:\米粒Demographics简版\米粒demo配置表_simple.xls"
out=var_name_left dbms=excel replace;
sheet="粘贴模板";
getnames=yes;
run;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 6, 13, "same"); else dt = today() - 6;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

data bjb.ml_Demograph_simple;
set bjb.ml_Demograph(keep=
apply_code
申请结果
申请拒绝
申请提交点
申请提交点_g
申请提交日
申请提交日期
申请提交时间
申请提交月份
申请通过
审核处理日
审核处理日期
审核处理月份
复贷申请
refuse_name
DEGREE_NAME
DEGREE_NAME_g
ID_CARD
JOB_COMPANY_CITY_NAME
JOB_COMPANY_PROVINCE_NAME
JOB_g
MARRIAGE_NAME_g
MONTH_SALARY_NAME
RESIDENCE_CITY_NAME
RESIDENCE_CONDITION_NAME
RESIDENCE_PROVINCE_NAME
SEX_NAME
SEX_NAME_group
app_total_cnt
app_type_cnt
apply_cnt_in1m
apply_cnt_in3m
apply_cnt_in7d
app个数区间
app种类区间
check_final
company_g
company_province_g
date_created
grp_cx_score
input_complete
last1m_callcnt_rate_in
last1m_callcnt_with_emergency
last1m_callplc_mostFreq
last3m_callcnt_with_emergency
last3m_callplc_mostFreq
last_record_time
loc_1mcnt_silent
loc_1mmaxcnt_silent
loc_3mcnt_silent
loc_3mmaxcnt_silent
loc_addresscnt
loc_addresscnt1
loc_appsl
loc_appsl_g
loc_ava_exp
loc_callcount
loc_calledcount
loc_inpast1st_calledtime
loc_inpast1st_calltime
loc_inpast2nd_calledtime
loc_inpast2nd_calltime
loc_inpast3rd_calledtime
loc_inpast3rd_calltime
loc_register_date
loc_tel_fm_rank
loc_tel_jm_rank
loc_tel_po_rank
loc_tel_py_rank
loc_tel_qs_rank
loc_tel_qt_rank
loc_tel_ts_rank
loc_tel_tx_rank
loc_tel_xd_rank
loc_tel_zn_rank
loc_tqscore
loc_txlsl
loc_txlsl_g
loc_zmscore
salary_g
user_code
父母排名
来源渠道
配偶排名
朋友排名
其他排名
亲属排名
入网时间
天启分区间
入网时间
网龄月份
网龄时长
月均消费金额
月均消费金额区间
芝麻分区间
近三最静默区间
近三静默区间
近一最静默区间
近一静默区间
loc_abmoduleflag
);
run;

**打上渠道标签;
data bjb.ml_Demograph_simple_channel;
set bjb.ml_Demograph_simple;
if 来源渠道 in ("appstore","xiaomi") then 渠道标签=1;
else if 来源渠道 in ("oppo","yingyongbao","vivo","qihu360") then 渠道标签=2;
else if 来源渠道 in ("51kabao","taoqianbao","kuaiqiandai","mijisu","meizu","rongyijie") then 渠道标签=3;
else 渠道标签=4;
run;

