*****************************************
	命中某些规则的申请订单子主题
*****************************************;
option compress = yes validvarname = any;

/*libname lendRaw "C:\Users\lenovo\Document\TS\Datamart\applend\rawdata";*/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
libname submart "D:\mili\Datamart\data";

proc sort data = submart.id_submart out = id_submart(keep = apply_code phone_no) nodupkey; by apply_code; run;

***申请订单结果;
data apply_result;
set submart.apply_submart(keep = apply_code user_code 申请结果 申请提交日期 申请提交月份);
run;

proc sort data = apply_result nodupkey; by apply_code; run;

***审批结果;
data approval_result;
set submart.approval_submart(keep = apply_code 审批结果 审核开始月份 审核开始日期 订单类型);
run;

proc sort data = approval_result nodupkey; by apply_code; run;

***基本规则（JBGZ）命中规则;
data jbgz_rule;
/*set submart.BQSrule_jbgz_submart(keep = apply_code rule_code event_name where = (event_name = "loan"));*/
set submart.BQSrule_jbgz_submart(keep = apply_code rule_code rule_name_normal strategy_name rule_name 规则命中日期 event_name  where = (event_name = "loan"));
/*if rule_code = "JBAA008";*/
if rule_code = "JBAA044";
run;

proc sort data = jbgz_rule nodupkey; by apply_code; run;
data jbgz_rule_apply;
merge jbgz_rule(in = a) apply_result(in = b) id_submart(in = c) approval_result(in = d);
by apply_code;
if a;
run;

***聚信立（JXL）命中规则（聚立信是一个大数据公司）;
data jxl_rule;
set submart.BQSrule_jxl_submart(keep = apply_code rule_code event_name where = (event_name = "loan"));
if rule_code = "JXL0016";
run;
proc sort data = jxl_rule nodupkey; by apply_code; run;
data jxl_rule_apply;
merge jxl_rule(in = a) apply_result(in = b);
by apply_code;
if a;
run;

***富数运营商（FSYYS）命中规则;
data fsyys_rule;
set submart.BQSrule_fsyys_submart(keep = apply_code rule_code event_name where = (event_name = "loan"));
if rule_code = "FSSJ012";
run;
proc sort data = fsyys_rule nodupkey; by apply_code; run;
data fsyys_rule_apply;
merge fsyys_rule(in = a) apply_result(in = b);
by apply_code;
if a;
run;

***富数电商（FSDS）命中规则;
data fsds_rule;
set submart.BQSrule_fsds_submart(keep = apply_code rule_code event_name where = (event_name = "loan"));
if rule_code = "FSDS001";
run;
proc sort data = fsds_rule nodupkey; by apply_code; run;
data fsds_rule_apply;
merge fsds_rule(in = a) apply_result(in = b);
by apply_code;
if a;
run;

***关联规则（GLGZ）命中规则;
data glgz_rule;
set submart.BQSrule_glgz_submart(keep = apply_code rule_code event_name where = (event_name = "loan"));
if rule_code = "GLGZ007";
run;
proc sort data = glgz_rule nodupkey; by apply_code; run;
data glgz_rule_apply;
merge glgz_rule(in = a) apply_result(in = b);
by apply_code;
if a;
run;
