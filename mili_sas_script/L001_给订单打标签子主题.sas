*********************************
	给订单打标签子主题
*********************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";


*-------------------------订单的标签--------------------------;
***
需要的数据集：submart.loanBQS_loan_submart，dpraw.bqs_main_info，submart.apply_submart
***;

data apply_flag;
set submart.apply_submart(keep = apply_code 申请提交月份 申请提交日期 首次申请 订单类型 订单类型2);
rename 申请提交月份 = 月份 申请提交日期 = 日期;
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

***银策略筛选出的订单;
data silver_apply;
set submart.loanbqs_invi_submart(keep = apply_code);
银策略筛选 = 1;
run;
proc sort data = silver_apply nodupkey; by apply_code; run;

/*冠军挑战者标签*/
proc import out = abmoduleflag datafile = "D:\mili\Datamart\rawdata_csv_py\abmoduleflag\abmoduleflag_req.csv" dbms = csv replace; 
	getnames = yes; 
run;
proc sort data = abmoduleflag nodupkey; by id; run;

data abmoduleflag;
set abmoduleflag;
rename id = data_query_log_id;
run;

data loanevent;
set submart.loanBQS_loan_submart(keep = apply_code main_info_id);
run;
data main_log_id;
set dpraw.bqs_main_info(keep = id data_query_log_id);
rename id = main_info_id;
run;
proc sort data = loanevent nodupkey; by main_info_id; run;
proc sort data = main_log_id nodupkey; by main_info_id;run;
data loanevent;
merge loanevent(in = a) main_log_id(in = b);
by main_info_id;
if a;
run;
proc sort data = loanevent; by data_query_log_id; run;
proc sort data = abmoduleflag nodupkey; by data_query_log_id; run;
data abmoduleflag;
merge loanevent(in = a) abmoduleflag(in = b);
by data_query_log_id;
if a & b;
keep apply_code loc_abmoduleflag;
run;
proc sort data = abmoduleflag nodupkey; by apply_code; run;

**3种渠道标签;
data channel_flag;
set submart.apply_submart(keep = apply_code 来源渠道);
if 来源渠道 in ("appstore","xiaomi","cpsxm1","zhongxin","51kabao") then 渠道标签=1;  **低风险;
else if 来源渠道 in ("yingyongbao","vivo","qihu360") then 渠道标签=2;   **高风险;
else 渠道标签=3;   **中风险;
run;

**拥有客户标签和AB标签的数据集;
data flag;
merge apply_flag(in = a) silver_apply(in = b) abmoduleflag(in=c) channel_flag(in=d);
by apply_code;
if a;
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

data submart.apply_flag;
set flag;
run;


*-----------------------给已有的所有数据集加标签---------------------;

/*给apply_submart加标签*/
proc sort data = submart.apply_submart out = apply_submart nodupkey; by apply_code;run;
data submart.apply_submart;
merge apply_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给approval_submart加标签;
proc sort data = submart.approval_submart out = approval_submart; by apply_code; run;
data submart.approval_submart;
merge approval_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
format 金策略审批结果 $20.;
if 银策略筛选 = 1 and 审批结果 not in ("系统拒绝", "系统审核中") then 金策略审批结果 = "系统拒绝"; else 金策略审批结果 = 审批结果;
run;

***给loan_submart加标签;
proc sort data = submart.loan_submart out = loan_submart; by apply_code; run;
data submart.loan_submart;
merge loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_submart加标签;
proc sort data = submart.loanBQS_submart out = loanBQS_submart; by apply_code; run;
data submart.loanBQS_submart;
merge loanBQS_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanTD_submart加标签;
proc sort data = submart.loanTD_submart out = loanTD_submart; by apply_code; run;
data submart.loanTD_submart;
merge loanTD_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanCX_submart加标签;
proc sort data = submart.loanCX_submart out = loanCX_submart; by apply_code; run;
data submart.loanCX_submart;
merge loanCX_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloan_submart加标签;
proc sort data = submart.reloan_submart out = reloan_submart; by apply_code; run;
data submart.reloan_submart;
merge reloan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloanbqs_submart加标签;
proc sort data = submart.reloanbqs_submart out = reloanbqs_submart; by apply_code; run;
data submart.reloanbqs_submart;
merge reloanbqs_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloansimplebqs_submart加标签;
proc sort data = submart.reloansimplebqs_submart out = reloansimplebqs_submart; by apply_code; run;
data submart.reloansimplebqs_submart;
merge reloansimplebqs_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloantd_submart加标签;
proc sort data = submart.reloantd_submart out = reloantd_submart; by apply_code; run;
data submart.reloantd_submart;
merge reloantd_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_blk_submart加标签;
proc sort data = submart.loanBQS_blk_submart out = loanBQS_blk_submart; by apply_code; run;
data submart.loanBQS_blk_submart;
merge loanBQS_blk_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_loan_submart加标签;
proc sort data = submart.loanBQS_loan_submart out = loanBQS_loan_submart; by apply_code; run;
data submart.loanBQS_loan_submart;
merge loanBQS_loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_decision_submart加标签;
proc sort data = submart.loanBQS_decision_submart out = loanBQS_decision_submart; by apply_code; run;
data submart.loanBQS_decision_submart;
merge loanBQS_decision_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_zw_submart加标签;
proc sort data = submart.Loanbqs_zw_submart out = Loanbqs_zw_submart; by apply_code; run;
data submart.Loanbqs_zw_submart;
merge Loanbqs_zw_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_face_submart加标签;
proc sort data = submart.loanBQS_face_submart out = loanBQS_face_submart; by apply_code; run;
data submart.loanBQS_face_submart;
merge loanBQS_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;
**给Bqsrule_ycsq_submart打标签;
proc sort data = submart.Bqsrule_ycsq_submart out = Bqsrule_ycsq_submart; by apply_code; run;
data submart.Bqsrule_ycsq_submart;
merge Bqsrule_ycsq_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_invi_submart加标签;
proc sort data = submart.loanBQS_invi_submart out = loanBQS_invi_submart; by apply_code; run;
data submart.loanBQS_invi_submart;
merge loanBQS_invi_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanBQS_ivs_submart加标签;
proc sort data = submart.loanBQS_ivs_submart out = loanBQS_ivs_submart; by apply_code; run;
data submart.loanBQS_ivs_submart;
merge loanBQS_ivs_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloanBQS_loan_submart加标签;
proc sort data = submart.reloanBQS_loan_submart out = reloanBQS_loan_submart; by apply_code; run;
data submart.reloanBQS_loan_submart;
merge reloanBQS_loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloansimpleBQS_loan_submart加标签;
proc sort data = submart.reloansimpleBQS_loan_submart out = reloansimpleBQS_loan_submart; by apply_code; run;
data submart.reloansimpleBQS_loan_submart;
merge reloansimpleBQS_loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloanBQS_face_submart加标签;
proc sort data = submart.reloanBQS_face_submart out = reloanBQS_face_submart; by apply_code; run;
data submart.reloanBQS_face_submart;
merge reloanBQS_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloansimpleBQS_face_submart加标签;
proc sort data = submart.reloansimpleBQS_face_submart out = reloansimpleBQS_face_submart; by apply_code; run;
data submart.reloansimpleBQS_face_submart;
merge reloansimpleBQS_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanstrategyset_submart加标签;
proc sort data = submart.loanstrategyset_submart out = loanstrategyset_submart; by apply_code; run;
data submart.loanstrategyset_submart;
merge loanstrategyset_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloanstrategyset_submart加标签;
proc sort data = submart.reloanstrategyset_submart out = reloanstrategyset_submart; by apply_code; run;
data submart.reloanstrategyset_submart;
merge reloanstrategyset_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloansimplestrategyset_submart加标签;
proc sort data = submart.reloansimplestrategyset_submart out = reloansimplestrategyset_submart; by apply_code; run;
data submart.reloansimplestrategyset_submart;
merge reloansimplestrategyset_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loangoldfunnel_submart加标签;
proc sort data = submart.loangoldfunnel_submart out = loangoldfunnel_submart; by apply_code; run;
data submart.loangoldfunnel_submart;
merge loangoldfunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loansilverfunnel_submart加标签;
proc sort data = submart.loansilverfunnel_submart out = loansilverfunnel_submart; by apply_code; run;
data submart.loansilverfunnel_submart;
merge loansilverfunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给loanfunnel_submart加标签;
proc sort data = submart.loanfunnel_submart out = loanfunnel_submart; by apply_code; run;
data submart.loanfunnel_submart;
merge loanfunnel_submart(in = a) submart.apply_flag(in = b);
/*merge loanfunnel_submart(in = a drop=loc_abmoduleflag) apply_flag(in = b);*/
by apply_code;
if a;
run;

***给reloanfunnel_submart加标签;
proc sort data = submart.reloanfunnel_submart out = reloanfunnel_submart; by apply_code; run;
data submart.reloanfunnel_submart;
merge reloanfunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给reloansimplefunnel_submart加标签;
proc sort data = submart.reloansimplefunnel_submart out = reloansimplefunnel_submart; by apply_code; run;
data submart.reloansimplefunnel_submart;
merge reloansimplefunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_jbgz_submart加标签;
proc sort data = submart.BQSrule_jbgz_submart out = BQSrule_jbgz_submart; by apply_code; run;
data submart.BQSrule_jbgz_submart;
merge BQSrule_jbgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_jbgz_b_submart加标签;
proc sort data = submart.BQSrule_jbgz_b_submart out = BQSrule_jbgz_b_submart; by apply_code; run;
data submart.BQSrule_jbgz_b_submart;
merge BQSrule_jbgz_b_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_jbgz_base_submart加标签;
proc sort data = submart.BQSrule_jbgz_base_submart out = BQSrule_jbgz_base_submart; by apply_code; run;
data submart.BQSrule_jbgz_base_submart;
merge BQSrule_jbgz_base_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_jbgz_aaa_submart加标签;
proc sort data = submart.BQSrule_jbgz_aaa_submart out = BQSrule_jbgz_aaa_submart; by apply_code; run;
data submart.BQSrule_jbgz_aaa_submart;
merge BQSrule_jbgz_aaa_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_jbgz_bbb_submart加标签;
proc sort data = submart.BQSrule_jbgz_bbb_submart out = BQSrule_jbgz_bbb_submart; by apply_code; run;
data submart.BQSrule_jbgz_bbb_submart;
merge BQSrule_jbgz_bbb_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_fsyys_submart加标签;
proc sort data = submart.BQSrule_fsyys_submart out = BQSrule_fsyys_submart; by apply_code; run;
data submart.BQSrule_fsyys_submart;
merge BQSrule_fsyys_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给bqsrule_fsyys_b_submart加标签;
proc sort data = submart.BQSrule_fsyys_b_submart out = BQSrule_fsyys_b_submart; by apply_code; run;
data submart.BQSrule_fsyys_b_submart;
merge BQSrule_fsyys_b_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给bqsrule_fsyys_base_submart加标签;
proc sort data = submart.BQSrule_fsyys_base_submart out = BQSrule_fsyys_base_submart; by apply_code; run;
data submart.BQSrule_fsyys_base_submart;
merge BQSrule_fsyys_base_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给bqsrule_fsyys_aaa_submart加标签;
proc sort data = submart.BQSrule_fsyys_aaa_submart out = BQSrule_fsyys_aaa_submart; by apply_code; run;
data submart.BQSrule_fsyys_aaa_submart;
merge BQSrule_fsyys_aaa_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给bqsrule_fsyys_bbb_submart加标签;
proc sort data = submart.BQSrule_fsyys_bbb_submart out = BQSrule_fsyys_bbb_submart; by apply_code; run;
data submart.BQSrule_fsyys_bbb_submart;
merge BQSrule_fsyys_bbb_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给bqsrule_fsyys_ccc_submart加标签;
proc sort data = submart.BQSrule_fsyys_ccc_submart out = BQSrule_fsyys_ccc_submart; by apply_code; run;
data submart.BQSrule_fsyys_ccc_submart;
merge BQSrule_fsyys_ccc_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_fsds_submart加标签;
proc sort data = submart.BQSrule_fsds_submart out = BQSrule_fsds_submart; by apply_code; run;
data submart.BQSrule_fsds_submart;
merge BQSrule_fsds_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_glgz_submart加标签;
proc sort data = submart.BQSrule_glgz_submart out = BQSrule_glgz_submart; by apply_code; run;
data submart.BQSrule_glgz_submart;
merge BQSrule_glgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_mddh_submart加标签;
proc sort data = submart.BQSrule_mddh_submart out = BQSrule_mddh_submart; by apply_code; run;
data submart.BQSrule_mddh_submart;
merge BQSrule_mddh_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给CXrule_submart加标签;
proc sort data = submart.CXrule_submart out = CXrule_submart; by apply_code; run;
data submart.CXrule_submart;
merge CXrule_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_fdjbgz_submart加标签;
proc sort data = submart.BQSrule_fdjbgz_submart out = BQSrule_fdjbgz_submart; by apply_code; run;
data submart.BQSrule_fdjbgz_submart;
merge BQSrule_fdjbgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_fdzr_submart加标签;
proc sort data = submart.BQSrule_fdzr_submart out = BQSrule_fdzr_submart; by apply_code; run;
data submart.BQSrule_fdzr_submart;
merge BQSrule_fdzr_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
if index(rule_name_normal, "FD001") then do; rule_code = "FDZR001"; rule_name_normal = "FDZR001_复贷准入"; end;
run;

***给BQSrule_fdjbgz_submart加标签;
proc sort data = submart.BQSrule_fdjbgz_submart out = BQSrule_fdjbgz_submart; by apply_code; run;
data submart.BQSrule_fdjbgz_submart;
merge BQSrule_fdjbgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_br_submart加标签;
proc sort data = submart.BQSrule_br_submart out = BQSrule_br_submart; by apply_code; run;
data submart.BQSrule_br_submart;
merge BQSrule_br_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_shixin_submart加标签;
proc sort data = submart.BQSrule_shixin_submart out = BQSrule_shixin_submart; by apply_code; run;
data submart.BQSrule_shixin_submart;
merge BQSrule_shixin_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_eysq_submart加标签;
proc sort data = submart.BQSrule_eysq_submart out = BQSrule_eysq_submart; by apply_code; run;
data submart.BQSrule_eysq_submart;
merge BQSrule_eysq_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给BQSrule_face_submart加标签;
proc sort data = submart.BQSrule_face_submart out = BQSrule_face_submart; by apply_code; run;
data submart.BQSrule_face_submart;
merge BQSrule_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给TDrule_submart加标签;
proc sort data = submart.TDrule_submart out = TDrule_submart; by apply_code; run;
data submart.TDrule_submart;
merge TDrule_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***给cx_anti_fraud加标签;
proc sort data = submart.cx_anti_fraud out = cx_anti_fraud; by apply_code; run;
data submart.cx_anti_fraud;
merge cx_anti_fraud(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;
