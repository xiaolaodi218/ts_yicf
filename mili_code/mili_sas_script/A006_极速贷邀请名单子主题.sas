*******************************
	���ٴ���������������
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

data submart.jsdinvite_submart;
set lendRaw.circular(drop = ID URI_PATH REMARK DEADLINE STATUS UPDATED_TIME TYPE where = (NAME = "������Ǯ"));
���ٴ������·� = put(datepart(CREATED_TIME), yymmn6.);
���ٴ��������� = put(datepart(CREATED_TIME), yymmdd10.);
rename CREATED_TIME = ���ٴ�����ʱ��;
drop NAME;
run;

