*******************************
		ע��������
*******************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";

/*ע��ʱ�䡢��Դ������*/
data user;
set lendRaw.user(drop = ID);
/*set lendRaw.user(drop = ID HAND_PASSWORD CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION REMARK);*/
�û�ע���·� = put(datepart(CREATED_TIME), yymmn6.);
�û�ע������ = put(datepart(CREATED_TIME), yymmdd10.);
�û�ע��ʱ��� = hour(CREATED_TIME);
�û��������� = put(datepart(UPDATED_TIME), yymmdd10.);
rename CREATED_TIME = �û�ע��ʱ�� UPDATED_TIME = �û�����ʱ�� SOURCE_CHANNEL = ��Դ����;
run;
***ע��͸�ӱ�����Դ;
data submart.register_submart;
set user(keep = USER_CODE ��Դ���� �û�ע���·� �û�ע������ �û�ע��ʱ���);
run;
