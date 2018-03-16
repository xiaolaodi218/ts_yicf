*****************************************
	Demographics子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***loan事件策略入参;
data loanevent_in;
set submart.loanevent_in;
format grp_appsl grp_txlsl $20.;
	 if loc_appsl = . then grp_appsl = "0. Missing";
else if loc_appsl < 5 then grp_appsl = "1. [0, 5)";
else if loc_appsl < 10 then grp_appsl = "2. [5, 10)";
else if loc_appsl < 15 then grp_appsl = "3. [10, 15)";
else if loc_appsl >= 15 then grp_appsl = "4. [15, )";
	 if loc_txlsl = . then grp_txlsl = "0. Missing";
else if loc_txlsl < 10 then grp_txlsl = "1. [0, 10)";
else if loc_txlsl < 20 then grp_txlsl = "2. [10, 20)";
else if loc_txlsl < 30 then grp_txlsl = "3. [20, 30)";
else if loc_txlsl < 50 then grp_txlsl = "4. [30, 50)";
else if loc_txlsl < 100 then grp_txlsl = "5. [50, 100)";
else if loc_txlsl >= 100 then grp_txlsl = "6. [100, )";
run;
proc sort data = loanevent_in nodupkey; by apply_code descending data_query_log_id; run;
proc sort data = loanevent_in nodupkey; by apply_code; run;

***其他变量;
data apply_var;
set submart.applyvar_submart(keep = apply_code period 申请提交时点 SEX_NAME 年龄 MARRIAGE_NAME grp_申请距注册 GPS省份);
run;
proc sort data = apply_var nodupkey; by apply_code; run;

***同盾多平台申请数;
data apply_cnt_td;
set submart.apply_cnt_td(keep = apply_code 规则命中月份 规则命中日期 apply_cnt_in7d apply_cnt_in1m apply_cnt_in3m);
run;
proc sort data = apply_cnt_td nodupkey; by apply_code; run;

data loan_in;
merge loanevent_in(in = a) apply_var(in = b) apply_cnt_td(in = c);
by apply_code;
if a;
run;
proc sort data = loan_in nodupkey; by apply_code; run;

***TTD;
data apply_submart;
set submart.apply_submart;
run;
proc sort data = apply_submart nodupkey; by apply_code; run;
data submart.ttd_demographics;
merge apply_submart(in = a) loan_in(in = b);
by apply_code;
if a;
run;


***ActiveLoan;
data dt;
set submart.mili_bill_main(keep = contract_no overdue_days bill_status CH_NAME where = (bill_status ^= "0001"));
format 逾期类型 还款标签1 还款标签2 $20.;
	 if bill_status = "0002" and overdue_days > 5 then 逾期类型 = "当前逾期5+"; 
else if overdue_days > 5 then 逾期类型 = "曾经逾期5+";
else 逾期类型 = "其他";
	 if overdue_days > 15 then 还款标签1 = "曾经逾期15+";
else if overdue_days > 0 and bill_status = "0000" then 还款标签1 = "曾经逾期已结清";
else if overdue_days > 0 then 还款标签1 = "当前逾期";
else 还款标签1 = "正常结清";
	 if overdue_days > 5 then 还款标签2 = "曾经逾期5+";
else if overdue_days > 0 and bill_status = "0000" then 还款标签2 = "曾经逾期已结清";
else if overdue_days > 0 then 还款标签2 = "当前逾期";
else 还款标签2 = "正常结清";
rename contract_no = apply_code;
run;
proc sort data = dt nodupkey; by apply_code; run;

***申请订单的其他标签，如是否复贷;
data apply_flag;
set submart.apply_submart(keep = apply_code 复贷申请 首次申请);
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

data submart.activeloan_demographics;
merge dt(in = a) loan_in(in = b) apply_flag(in = c);
by apply_code;
if a;
run;
