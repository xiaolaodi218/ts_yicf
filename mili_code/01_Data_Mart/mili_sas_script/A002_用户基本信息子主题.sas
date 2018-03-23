*******************************
	  用户基本信息子主题
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

/*用户基本信息*/
data user_base_info;
set lendRaw.user_base_info(drop = ID CREATED_TIME UPDATED_TIME );
if SEX = 0 THEN SEX_NAME = "女"; else if SEX = 1 THEN SEX_NAME = "男";
run;

data submart.baseinfo_submart;
set user_base_info;
run;
