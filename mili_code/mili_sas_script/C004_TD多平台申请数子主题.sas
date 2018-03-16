*****************************************
	同盾多平台申请
*****************************************;

/*option compress = yes validvarname = any;*/

/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

data apply_td;
set submart.tdrule_submart(keep = apply_code os_type 复贷申请 规则命中月份 规则命中日期 policy_set_name);
run;
proc sort data = apply_td nodupkey; by apply_code; run;


/*7天内的借款平台数*/
data apply_cnt_in7d;
set submart.tdrule_submart(keep = apply_code rule_name rule_score 规则命中月份 规则命中日期);
if index(rule_name, "7天内申请人在多个平台申请借款");
	 if 规则命中月份 = "201612" then apply_cnt_in7d = rule_score / 5;
else apply_cnt_in7d = rule_score / 2; 
if 规则命中日期 in ("2016-12-28","2016-12-29","2016-12-30","2016-12-31") then apply_cnt_in7d = rule_score / 2;;
keep apply_code apply_cnt_in7d;
run;
proc sort data = apply_cnt_in7d nodupkey; by apply_code; run;

data apply_cnt_in1m;
set submart.tdrule_submart(keep = apply_code rule_name rule_score 规则命中月份 规则命中日期);
if index(rule_name, "1个月内申请人在多个平台申请借款");
	 if 规则命中月份 = "201612" then apply_cnt_in1m = rule_score / 3;
else apply_cnt_in1m_exc = rule_score / 2; 
if 规则命中日期 in ("2016-12-28","2016-12-29","2016-12-30","2016-12-31") then apply_cnt_in1m = rule_score / 2;;
keep apply_code apply_cnt_in1m_exc;
run;
proc sort data = apply_cnt_in1m nodupkey; by apply_code; run;

data apply_cnt_in3m;
set submart.tdrule_submart(keep = apply_code rule_name rule_score 规则命中月份 规则命中日期);
if index(rule_name, "3个月内申请人在多个平台申请借款");
apply_cnt_in3m_exc = rule_score / 2; 
keep apply_code apply_cnt_in3m_exc;
run;
proc sort data = apply_cnt_in3m nodupkey; by apply_code; run;

data submart.apply_cnt_td;
merge apply_td(in = a) apply_cnt_in7d(in = b) apply_cnt_in1m(in = c) apply_cnt_in3m(in = d);
by apply_code;
if a;
apply_cnt_in1m = apply_cnt_in1m_exc + apply_cnt_in7d;
apply_cnt_in3m = apply_cnt_in1m_exc + apply_cnt_in3m_exc + apply_cnt_in7d;
drop apply_cnt_in1m_exc apply_cnt_in3m_exc;
run;
