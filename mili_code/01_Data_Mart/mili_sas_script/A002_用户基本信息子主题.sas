*******************************
	  �û�������Ϣ������
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

/*�û�������Ϣ*/
data user_base_info;
set lendRaw.user_base_info(drop = ID CREATED_TIME UPDATED_TIME );
if SEX = 0 THEN SEX_NAME = "Ů"; else if SEX = 1 THEN SEX_NAME = "��";
run;

data submart.baseinfo_submart;
set user_base_info;
run;
