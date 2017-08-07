*******************************
	  认证子主题
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

/*完成身份认证时间*/
/*data id_verify;*/
/*set lendRaw.id_verification(keep = USER_CODE CREATED_TIME UPDATED_TIME);*/
/*身份认证日期 = put(datepart(CREATED_TIME),yymmdd10.);*/
/*身份认证更新日期 = put(datepart(UPDATED_TIME),yymmdd10.);*/
/*rename CREATED_TIME = 身份认证时间 UPDATED_TIME = 身份认证更新时间;*/
/*run;*/

/*完成联系人导入时间*/
/*proc sort data = lendRaw.user_relation_his out = relation_first(keep = user_code CREATED_TIME) nodupkey; by user_code CREATED_TIME; run;*/
/*proc sort data = relation_first(rename = (created_time = 首次导入联系人时间)) nodupkey; by user_code; run;*/
/*proc sort data = lendRaw.user_relation_his out = relation_last(keep = user_code CREATED_TIME) nodupkey; by user_code descending CREATED_TIME; run;*/
/*proc sort data = relation_last(rename = (created_time = 最新导入联系人时间)) nodupkey; by user_code; run;*/
/*data relation_verify;*/
/*merge relation_first(in = a) relation_last(in = b);*/
/*by user_code;*/
/*if a;*/
/*首次导入联系人日期 = put(datepart(首次导入联系人时间), yymmdd10.);*/
/*最新导入联系人日期 = put(datepart(最新导入联系人时间), yymmdd10.);*/
/*run;*/

/*完成运营商认证时间*/
/*data operator_verify;*/
/*set lendRaw.operator_verification(keep = user_code CREATED_TIME UPDATED_TIME);*/
/*运营商认证日期 = put(datepart(CREATED_TIME),yymmdd10.);*/
/*运营商认证月份 = put(datepart(CREATED_TIME), yymmn6.);*/
/*运营商更新日期 = put(datepart(UPDATED_TIME),yymmdd10.);*/
/*rename CREATED_TIME = 运营商认证时间 UPDATED_TIME = 运营商认证更新时间;*/
/*run;*/

/*来源渠道*/
/*data source_channel;*/
/*set submart.register_submart(keep = USER_CODE 来源渠道);*/
/*run;*/
/**/
/*proc sort data = id_verify nodupkey; by USER_CODE; run;*/
/*proc sort data = relation_verify nodupkey; by USER_CODE; run;*/
/*proc sort data = operator_verify nodupkey; by USER_CODE; run;*/
/*proc sort data = source_channel nodupkey; by USER_CODE; run;*/
/**/
/*data verify;*/
/*merge id_verify(in = c) relation_verify(in = d) operator_verify(in = e) source_channel(in = f);*/
/*by user_code;*/
/*if c;*/
/*run;*/


***运营商认证透视表数据源;
/*data submart.operverify_submart;*/
/*set verify(where = (运营商认证日期 ^= "") keep = USER_CODE 来源渠道 运营商认证月份 运营商认证日期);*/
/*run;*/


*******************************
	  认证子主题——逻辑二
*******************************;
/*来源渠道*/
data source_channel;
set submart.register_submart(keep = USER_CODE 来源渠道);
run;
proc sort data = source_channel nodupkey; by USER_CODE; run;

data user_verify;
set lendRaw.user_verification_info(keep = user_code verify_type UPDATED_TIME);
认证日期 = put(datepart(UPDATED_TIME),yymmdd10.);
认证月份 = put(datepart(UPDATED_TIME), yymmn6.);
drop UPDATED_TIME;
run;

/*完成运营商认证时间*/
data operator_verify;
set user_verify;
if verify_type = 3;
rename 认证日期 = 运营商认证日期 认证月份 = 运营商认证月份;
drop verify_type;
run;
proc sort data = operator_verify nodupkey; by USER_CODE; run;
data submart.operverify_submart;
merge operator_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;

/*完成淘宝认证时间*/
data taobao_verify;
set user_verify;
if verify_type = 5;
rename 认证日期 = 淘宝认证日期 认证月份 = 淘宝认证月份;
drop verify_type;
run;
proc sort data = taobao_verify nodupkey; by USER_CODE; run;
data submart.tbverify_submart;
merge taobao_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;

/*完成京东认证时间*/
data jingdong_verify;
set user_verify;
if verify_type = 6;
rename 认证日期 = 京东认证日期 认证月份 = 京东认证月份;
drop verify_type;
run;
proc sort data = jingdong_verify nodupkey; by USER_CODE; run;
data submart.jdverify_submart;
merge jingdong_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;

/*完成电商认证*/
data ebusiness_verify;
merge taobao_verify(in = a) jingdong_verify(in = b);
by USER_CODE;
run;
proc sort data = ebusiness_verify nodupkey; by USER_CODE; run;
data submart.ebusiverify_submart;
merge ebusiness_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;
