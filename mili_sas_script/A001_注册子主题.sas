*******************************
		注册子主题
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

/*注册时间、来源渠道等*/
data user;
set lendRaw.user(drop = ID HAND_PASSWORD CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION REMARK);
用户注册月份 = put(datepart(CREATED_TIME), yymmn6.);
用户注册日期 = put(datepart(CREATED_TIME), yymmdd10.);
用户注册时间段 = hour(CREATED_TIME);
用户更新日期 = put(datepart(UPDATED_TIME), yymmdd10.);
rename CREATED_TIME = 用户注册时间 UPDATED_TIME = 用户更新时间 SOURCE_CHANNEL = 来源渠道;
run;
***注册透视表数据源;
data submart.register_submart;
set user(keep = USER_CODE 来源渠道 用户注册月份 用户注册日期 用户注册时间段);
run;
