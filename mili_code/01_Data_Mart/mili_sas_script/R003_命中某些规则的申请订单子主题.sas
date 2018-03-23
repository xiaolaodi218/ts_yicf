*****************************************
	����ĳЩ��������붩��������
*****************************************;
option compress = yes validvarname = any;

/*libname lendRaw "C:\Users\lenovo\Document\TS\Datamart\applend\rawdata";*/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
libname submart "D:\mili\Datamart\data";

proc sort data = submart.id_submart out = id_submart(keep = apply_code phone_no) nodupkey; by apply_code; run;

***���붩�����;
data apply_result;
set submart.apply_submart(keep = apply_code user_code ������ �����ύ���� �����ύ�·�);
run;

proc sort data = apply_result nodupkey; by apply_code; run;

***�������;
data approval_result;
set submart.approval_submart(keep = apply_code ������� ��˿�ʼ�·� ��˿�ʼ���� ��������);
run;

proc sort data = approval_result nodupkey; by apply_code; run;

***��������JBGZ�����й���;
data jbgz_rule;
/*set submart.BQSrule_jbgz_submart(keep = apply_code rule_code event_name where = (event_name = "loan"));*/
set submart.BQSrule_jbgz_submart(keep = apply_code rule_code rule_name_normal strategy_name rule_name ������������ event_name  where = (event_name = "loan"));
/*if rule_code = "JBAA008";*/
if rule_code = "JBAA044";
run;

proc sort data = jbgz_rule nodupkey; by apply_code; run;
data jbgz_rule_apply;
merge jbgz_rule(in = a) apply_result(in = b) id_submart(in = c) approval_result(in = d);
by apply_code;
if a;
run;

***��������JXL�����й��򣨾�������һ�������ݹ�˾��;
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

***������Ӫ�̣�FSYYS�����й���;
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

***�������̣�FSDS�����й���;
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

***��������GLGZ�����й���;
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
