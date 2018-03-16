*********************************
	���������ǩ������
*********************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";


*-------------------------�����ı�ǩ--------------------------;
***
��Ҫ�����ݼ���submart.loanBQS_loan_submart��dpraw.bqs_main_info��submart.apply_submart
***;

data apply_flag;
set submart.apply_submart(keep = apply_code �����ύ�·� �����ύ���� �״����� �������� ��������2);
rename �����ύ�·� = �·� �����ύ���� = ����;
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

***������ɸѡ���Ķ���;
data silver_apply;
set submart.loanbqs_invi_submart(keep = apply_code);
������ɸѡ = 1;
run;
proc sort data = silver_apply nodupkey; by apply_code; run;

/*�ھ���ս�߱�ǩ*/
proc import out = abmoduleflag datafile = "D:\mili\Datamart\rawdata_csv_py\abmoduleflag\abmoduleflag_req.csv" dbms = csv replace; 
	getnames = yes; 
run;

data ab_new ;
set abmoduleflag;
format loc_abmoduleflag1 $20.;
loc_abmoduleflag1 =loc_abmoduleflag;
run;

data abmoduleflag;
set ab_new(drop = loc_abmoduleflag);
rename loc_abmoduleflag1 =loc_abmoduleflag;
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

**3��������ǩ;
data channel_flag;
set submart.apply_submart(keep = apply_code ��Դ����);
if ��Դ���� in ("appstore","xiaomi","cpsxm1","zhongxin","51kabao") then ������ǩ=1;  **�ͷ���;
else if ��Դ���� in ("yingyongbao","vivo","qihu360") then ������ǩ=2;   **�߷���;
else ������ǩ=3;   **�з���;
run;

**ӵ�пͻ���ǩ��AB��ǩ�����ݼ�;
data flag;
merge apply_flag(in = a) silver_apply(in = b) abmoduleflag(in=c) channel_flag(in=d);
by apply_code;
if a;
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

data submart.apply_flag;
set flag;
run;


*-----------------------�����е��������ݼ��ӱ�ǩ---------------------;

/*��apply_submart�ӱ�ǩ*/
proc sort data = submart.apply_submart out = apply_submart nodupkey; by apply_code;run;
data submart.apply_submart;
merge apply_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��approval_submart�ӱ�ǩ;
proc sort data = submart.approval_submart out = approval_submart; by apply_code; run;
data submart.approval_submart;
merge approval_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
format ������������ $20.;
if ������ɸѡ = 1 and ������� not in ("ϵͳ�ܾ�", "ϵͳ�����") then ������������ = "ϵͳ�ܾ�"; else ������������ = �������;
run;

***��loan_submart�ӱ�ǩ;
proc sort data = submart.loan_submart out = loan_submart; by apply_code; run;
data submart.loan_submart;
merge loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_submart out = loanBQS_submart; by apply_code; run;
data submart.loanBQS_submart;
merge loanBQS_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanTD_submart�ӱ�ǩ;
proc sort data = submart.loanTD_submart out = loanTD_submart; by apply_code; run;
data submart.loanTD_submart;
merge loanTD_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanCX_submart�ӱ�ǩ;
proc sort data = submart.loanCX_submart out = loanCX_submart; by apply_code; run;
data submart.loanCX_submart;
merge loanCX_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloan_submart�ӱ�ǩ;
proc sort data = submart.reloan_submart out = reloan_submart; by apply_code; run;
data submart.reloan_submart;
merge reloan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloanbqs_submart�ӱ�ǩ;
proc sort data = submart.reloanbqs_submart out = reloanbqs_submart; by apply_code; run;
data submart.reloanbqs_submart;
merge reloanbqs_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloansimplebqs_submart�ӱ�ǩ;
proc sort data = submart.reloansimplebqs_submart out = reloansimplebqs_submart; by apply_code; run;
data submart.reloansimplebqs_submart;
merge reloansimplebqs_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloantd_submart�ӱ�ǩ;
proc sort data = submart.reloantd_submart out = reloantd_submart; by apply_code; run;
data submart.reloantd_submart;
merge reloantd_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_blk_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_blk_submart out = loanBQS_blk_submart; by apply_code; run;
data submart.loanBQS_blk_submart;
merge loanBQS_blk_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_loan_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_loan_submart out = loanBQS_loan_submart; by apply_code; run;
data submart.loanBQS_loan_submart;
merge loanBQS_loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_decision_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_decision_submart out = loanBQS_decision_submart; by apply_code; run;
data submart.loanBQS_decision_submart;
merge loanBQS_decision_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_zw_submart�ӱ�ǩ;
proc sort data = submart.Loanbqs_zw_submart out = Loanbqs_zw_submart; by apply_code; run;
data submart.Loanbqs_zw_submart;
merge Loanbqs_zw_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_face_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_face_submart out = loanBQS_face_submart; by apply_code; run;
data submart.loanBQS_face_submart;
merge loanBQS_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;
**��Bqsrule_ycsq_submart���ǩ;
proc sort data = submart.Bqsrule_ycsq_submart out = Bqsrule_ycsq_submart; by apply_code; run;
data submart.Bqsrule_ycsq_submart;
merge Bqsrule_ycsq_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_invi_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_invi_submart out = loanBQS_invi_submart; by apply_code; run;
data submart.loanBQS_invi_submart;
merge loanBQS_invi_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanBQS_ivs_submart�ӱ�ǩ;
proc sort data = submart.loanBQS_ivs_submart out = loanBQS_ivs_submart; by apply_code; run;
data submart.loanBQS_ivs_submart;
merge loanBQS_ivs_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloanBQS_loan_submart�ӱ�ǩ;
proc sort data = submart.reloanBQS_loan_submart out = reloanBQS_loan_submart; by apply_code; run;
data submart.reloanBQS_loan_submart;
merge reloanBQS_loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloansimpleBQS_loan_submart�ӱ�ǩ;
proc sort data = submart.reloansimpleBQS_loan_submart out = reloansimpleBQS_loan_submart; by apply_code; run;
data submart.reloansimpleBQS_loan_submart;
merge reloansimpleBQS_loan_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloanBQS_face_submart�ӱ�ǩ;
proc sort data = submart.reloanBQS_face_submart out = reloanBQS_face_submart; by apply_code; run;
data submart.reloanBQS_face_submart;
merge reloanBQS_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloansimpleBQS_face_submart�ӱ�ǩ;
proc sort data = submart.reloansimpleBQS_face_submart out = reloansimpleBQS_face_submart; by apply_code; run;
data submart.reloansimpleBQS_face_submart;
merge reloansimpleBQS_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanstrategyset_submart�ӱ�ǩ;
proc sort data = submart.loanstrategyset_submart out = loanstrategyset_submart; by apply_code; run;
data submart.loanstrategyset_submart;
merge loanstrategyset_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloanstrategyset_submart�ӱ�ǩ;
proc sort data = submart.reloanstrategyset_submart out = reloanstrategyset_submart; by apply_code; run;
data submart.reloanstrategyset_submart;
merge reloanstrategyset_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloansimplestrategyset_submart�ӱ�ǩ;
proc sort data = submart.reloansimplestrategyset_submart out = reloansimplestrategyset_submart; by apply_code; run;
data submart.reloansimplestrategyset_submart;
merge reloansimplestrategyset_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loangoldfunnel_submart�ӱ�ǩ;
proc sort data = submart.loangoldfunnel_submart out = loangoldfunnel_submart; by apply_code; run;
data submart.loangoldfunnel_submart;
merge loangoldfunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loansilverfunnel_submart�ӱ�ǩ;
proc sort data = submart.loansilverfunnel_submart out = loansilverfunnel_submart; by apply_code; run;
data submart.loansilverfunnel_submart;
merge loansilverfunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��loanfunnel_submart�ӱ�ǩ;
proc sort data = submart.loanfunnel_submart out = loanfunnel_submart; by apply_code; run;
data submart.loanfunnel_submart;
merge loanfunnel_submart(in = a) submart.apply_flag(in = b);
/*merge loanfunnel_submart(in = a drop=loc_abmoduleflag) apply_flag(in = b);*/
by apply_code;
if a;
run;

***��reloanfunnel_submart�ӱ�ǩ;
proc sort data = submart.reloanfunnel_submart out = reloanfunnel_submart; by apply_code; run;
data submart.reloanfunnel_submart;
merge reloanfunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��reloansimplefunnel_submart�ӱ�ǩ;
proc sort data = submart.reloansimplefunnel_submart out = reloansimplefunnel_submart; by apply_code; run;
data submart.reloansimplefunnel_submart;
merge reloansimplefunnel_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_jbgz_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_jbgz_submart out = BQSrule_jbgz_submart; by apply_code; run;
data submart.BQSrule_jbgz_submart;
merge BQSrule_jbgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_jbgz_b_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_jbgz_b_submart out = BQSrule_jbgz_b_submart; by apply_code; run;
data submart.BQSrule_jbgz_b_submart;
merge BQSrule_jbgz_b_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_jbgz_base_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_jbgz_base_submart out = BQSrule_jbgz_base_submart; by apply_code; run;
data submart.BQSrule_jbgz_base_submart;
merge BQSrule_jbgz_base_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_jbgz_aaa_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_jbgz_aaa_submart out = BQSrule_jbgz_aaa_submart; by apply_code; run;
data submart.BQSrule_jbgz_aaa_submart;
merge BQSrule_jbgz_aaa_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_jbgz_bbb_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_jbgz_bbb_submart out = BQSrule_jbgz_bbb_submart; by apply_code; run;
data submart.BQSrule_jbgz_bbb_submart;
merge BQSrule_jbgz_bbb_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_fsyys_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsyys_submart out = BQSrule_fsyys_submart; by apply_code; run;
data submart.BQSrule_fsyys_submart;
merge BQSrule_fsyys_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��bqsrule_fsyys_b_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsyys_b_submart out = BQSrule_fsyys_b_submart; by apply_code; run;
data submart.BQSrule_fsyys_b_submart;
merge BQSrule_fsyys_b_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��bqsrule_fsyys_base_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsyys_base_submart out = BQSrule_fsyys_base_submart; by apply_code; run;
data submart.BQSrule_fsyys_base_submart;
merge BQSrule_fsyys_base_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��bqsrule_fsyys_aaa_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsyys_aaa_submart out = BQSrule_fsyys_aaa_submart; by apply_code; run;
data submart.BQSrule_fsyys_aaa_submart;
merge BQSrule_fsyys_aaa_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��bqsrule_fsyys_bbb_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsyys_bbb_submart out = BQSrule_fsyys_bbb_submart; by apply_code; run;
data submart.BQSrule_fsyys_bbb_submart;
merge BQSrule_fsyys_bbb_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��bqsrule_fsyys_ccc_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsyys_ccc_submart out = BQSrule_fsyys_ccc_submart; by apply_code; run;
data submart.BQSrule_fsyys_ccc_submart;
merge BQSrule_fsyys_ccc_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_fsds_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fsds_submart out = BQSrule_fsds_submart; by apply_code; run;
data submart.BQSrule_fsds_submart;
merge BQSrule_fsds_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_glgz_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_glgz_submart out = BQSrule_glgz_submart; by apply_code; run;
data submart.BQSrule_glgz_submart;
merge BQSrule_glgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_mddh_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_mddh_submart out = BQSrule_mddh_submart; by apply_code; run;
data submart.BQSrule_mddh_submart;
merge BQSrule_mddh_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��CXrule_submart�ӱ�ǩ;
proc sort data = submart.CXrule_submart out = CXrule_submart; by apply_code; run;
data submart.CXrule_submart;
merge CXrule_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_fdjbgz_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fdjbgz_submart out = BQSrule_fdjbgz_submart; by apply_code; run;
data submart.BQSrule_fdjbgz_submart;
merge BQSrule_fdjbgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_fdzr_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fdzr_submart out = BQSrule_fdzr_submart; by apply_code; run;
data submart.BQSrule_fdzr_submart;
merge BQSrule_fdzr_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
if index(rule_name_normal, "FD001") then do; rule_code = "FDZR001"; rule_name_normal = "FDZR001_����׼��"; end;
run;

***��BQSrule_fdjbgz_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_fdjbgz_submart out = BQSrule_fdjbgz_submart; by apply_code; run;
data submart.BQSrule_fdjbgz_submart;
merge BQSrule_fdjbgz_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_br_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_br_submart out = BQSrule_br_submart; by apply_code; run;
data submart.BQSrule_br_submart;
merge BQSrule_br_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_shixin_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_shixin_submart out = BQSrule_shixin_submart; by apply_code; run;
data submart.BQSrule_shixin_submart;
merge BQSrule_shixin_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_eysq_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_eysq_submart out = BQSrule_eysq_submart; by apply_code; run;
data submart.BQSrule_eysq_submart;
merge BQSrule_eysq_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��BQSrule_face_submart�ӱ�ǩ;
proc sort data = submart.BQSrule_face_submart out = BQSrule_face_submart; by apply_code; run;
data submart.BQSrule_face_submart;
merge BQSrule_face_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��TDrule_submart�ӱ�ǩ;
proc sort data = submart.TDrule_submart out = TDrule_submart; by apply_code; run;
data submart.TDrule_submart;
merge TDrule_submart(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;

***��cx_anti_fraud�ӱ�ǩ;
proc sort data = submart.cx_anti_fraud out = cx_anti_fraud; by apply_code; run;
data submart.cx_anti_fraud;
merge cx_anti_fraud(in = a) submart.apply_flag(in = b);
by apply_code;
if a;
run;
