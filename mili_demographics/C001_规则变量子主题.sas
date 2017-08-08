*****************************************
	规则变量子主题
*****************************************;
option compress = yes validvarname = any;
/**/
libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";
/*注册时间*/
data reg_time;
set lendRaw.user(keep = user_code PHONE_NO CREATED_TIME);
rename CREATED_TIME = 用户注册时间;
run;
/*申请提交时间、gps地址*/
data apply_time;
set dpRaw.apply_info(keep = apply_code date_created gps_address);
	 if index(gps_address, "新疆维吾尔自治区") then GPS省份 = "新疆维吾尔自治区";
else if index(gps_address, "广西壮族自治区") then GPS省份 = "广西壮族自治区";
else if index(gps_address, "内蒙古自治区") then GPS省份 = "内蒙古自治区"; 
else if index(gps_address, "西藏自治区") then GPS省份 = "西藏自治区"; 
else if index(gps_address, "宁夏回族自治区") then GPS省份 = "宁夏回族自治区"; 
else if index(gps_address, "澳门特别行政区") then GPS省份 = "澳门特别行政区"; 
else GPS省份 = ksubstr(gps_address, 1, 3);
rename date_created = 申请提交时间;
run;
/*基本信息*/
data baseinfo;
set submart.baseinfo_submart;
drop USER_NAME SEX DEGREE PERMANENT_ADDRESS MARRIAGE RESIDENCE_CONDITION RESIDENCE_PROVINCE RESIDENCE_CITY RESIDENCE_REGION RESIDENCE_ADDRESS 
	JOB_COMPANY_NAME JOB_COMPANY_PROVINCE JOB_COMPANY_CITY JOB_COMPANY_REGION JOB_COMPANY_ADDRESS JOB_COMPANY_CONDITION JOB_COMPANY_PHONE 
	MONTH_SALARY CURR_JOB_SENIORITY;
run;
/*氪信分*/;
data creditx_score;
set dpraw.creditx_score(keep = apply_code score);
format grp_cx_score $20.;
	 if score < 550 then grp_cx_score = "0. (0, 550)";
else if score < 600 then grp_cx_score = "1. [550, 600)";
else if score < 620 then grp_cx_score = "2. [600, 620)";
else if score < 650 then grp_cx_score = "3. [620, 650)";
else if score < 700 then grp_cx_score = "4. [650, 700)";
else grp_cx_score = "5. [700, 850)";
rename score = cx_score;
run;
/*申请其他标记*/
data apply;
set submart.apply_submart;
keep apply_code user_code loan_amt period 首次申请 最新申请 复贷申请 申请提交月份 申请提交日期 有效申请 申请结果 订单类型;
run;

proc sort data = apply nodupkey; by apply_code; run;
proc sort data = apply_time nodupkey; by apply_code; run;
proc sort data = creditx_score nodupkey; by apply_code; run;
data apply_info;
merge apply(in = a) apply_time(in = b) creditx_score(in = c);
by apply_code;
if a;
run;

proc sort data = apply_info; by user_code; run;
proc sort data = reg_time nodupkey; by user_code; run;
proc sort data = baseinfo nodupkey; by user_code; run;
data apply_var;
merge apply_info(in = a) reg_time(in = b) baseinfo(in = c);
by user_code;
if a;
申请距注册间隔 = intck("minute", 用户注册时间, 申请提交时间);
申请提交时点 = hour(申请提交时间);
if substr(id_card, 7, 2) = "19" then 年龄 =  year(datepart(申请提交时间)) - substr(ID_CARD, 7, 4)*1;
drop 申请提交时间 用户注册时间;
run;

/*聚信立黑名单方面变量*/;
data jxl_var_1;
set dpRaw.ex_jxl_user_info_check(keep = token contacts_class1blacklist_cnt contacts_class2blacklist_cnt contacts_router_ratio phone_gray_score
										register_org_cnt searched_org_cnt);
run;
data jxl_basic;
set dpRaw.ex_jxl_basic(keep = token cell_phone);
rename cell_phone = phone_no;
run;
proc sort data = jxl_var_1 nodupkey; by token; run;
proc sort data = jxl_basic nodupkey; by token; run;
data jxl_var;
merge jxl_var_1(in = a) jxl_basic(in = b);
by token;
if a;
run;

/*提交申请的用户规则变量*/
proc sort data = apply_var; by phone_no; run;
proc sort data = jxl_var nodupkey; by phone_no; run;
data submart.applyVar_submart;
merge apply_var(in = a) jxl_var(in = e drop = token);
by phone_no;
if a;
format grp_年龄 grp_申请距注册 grp_聚信立机构查询数 $20.;
	 if 0 < 年龄 < 20 then grp_年龄 = "0. < 20";
else if 20 <= 年龄 <= 25 then grp_年龄 = "1. 20 - 25";
else if 26 <= 年龄 <= 30 then grp_年龄 = "2. 26 - 30";
else if 31 <= 年龄 <= 35 then grp_年龄 = "3. 31 - 35";
else if 年龄 > 35 then grp_年龄 = "4. > 35";
	 if 0 < 申请距注册间隔 < 5 then grp_申请距注册 = "0. < 5分钟";
else if 5 <= 申请距注册间隔 < 15 then grp_申请距注册 = "1. 5 - <15分钟";
else if 15 <= 申请距注册间隔 < 30 then grp_申请距注册 = "2. 15 - <30分钟";
else if 30 <= 申请距注册间隔 < 60 then grp_申请距注册 = "3. 30 - <60分钟";
else if 60 <= 申请距注册间隔 < 1440 then grp_申请距注册 = "4. 1天内";
else if 1440 <= 申请距注册间隔 < 2880 then grp_申请距注册 = "5. 2天内";
else if 1440 <= 申请距注册间隔 < 10080 then grp_申请距注册 = "6. 1周内";
else if 申请距注册间隔 >= 10080 then grp_申请距注册 = "7. 1周后";
	 if 0 < searched_org_cnt <= 5 then grp_聚信立机构查询数 = "0. <= 5";
else if 5 < searched_org_cnt <= 10 then grp_聚信立机构查询数 = "1. 6 - 10";
else if 10 < searched_org_cnt <= 15 then grp_聚信立机构查询数 = "2. 11 - 15";
else if 15 < searched_org_cnt <= 20 then grp_聚信立机构查询数 = "3. 16 - 20";
else if searched_org_cnt > 20 then grp_聚信立机构查询数 = "4. > 20";

drop PHONE_NO ID_CARD;
run;

proc sort data = submart.applyVar_submart; by apply_code; run;
