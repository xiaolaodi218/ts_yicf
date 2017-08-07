*******************************
	极速贷邀请名单子主题
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

data submart.jsdinvite_submart;
set lendRaw.circular(drop = ID URI_PATH REMARK DEADLINE STATUS UPDATED_TIME TYPE where = (NAME = "马上拿钱"));
极速贷邀请月份 = put(datepart(CREATED_TIME), yymmn6.);
极速贷邀请日期 = put(datepart(CREATED_TIME), yymmdd10.);
rename CREATED_TIME = 极速贷邀请时间;
drop NAME;
run;

