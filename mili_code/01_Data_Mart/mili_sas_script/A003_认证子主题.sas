*******************************
	  ��֤�����⡪���߼���
*******************************;
/*��Դ����*/
data source_channel;
set submart.register_submart(keep = USER_CODE ��Դ����);
run;
proc sort data = source_channel nodupkey; by USER_CODE; run;

data user_verify;
set lendRaw.user_verification_info(keep = user_code verify_type UPDATED_TIME);
��֤���� = put(datepart(UPDATED_TIME),yymmdd10.);
��֤�·� = put(datepart(UPDATED_TIME), yymmn6.);
drop UPDATED_TIME;
run;

/*�����Ӫ����֤ʱ��*/
data operator_verify;
set user_verify;
if verify_type = 3;
rename ��֤���� = ��Ӫ����֤���� ��֤�·� = ��Ӫ����֤�·�;
drop verify_type;
run;
proc sort data = operator_verify nodupkey; by USER_CODE; run;
data submart.operverify_submart;
merge operator_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;

/*����Ա���֤ʱ��*/
data taobao_verify;
set user_verify;
if verify_type = 5;
rename ��֤���� = �Ա���֤���� ��֤�·� = �Ա���֤�·�;
drop verify_type;
run;
proc sort data = taobao_verify nodupkey; by USER_CODE; run;
data submart.tbverify_submart;
merge taobao_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;

/*��ɾ�����֤ʱ��*/
data jingdong_verify;
set user_verify;
if verify_type = 6;
rename ��֤���� = ������֤���� ��֤�·� = ������֤�·�;
drop verify_type;
run;
proc sort data = jingdong_verify nodupkey; by USER_CODE; run;
data submart.jdverify_submart;
merge jingdong_verify(in = e) source_channel(in = f);
by user_code;
if e;
run;

/*��ɵ�����֤*/
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



*******************************
	  ��֤������
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

/*��������֤ʱ��*/
/*data id_verify;*/
/*set lendRaw.id_verification(keep = USER_CODE CREATED_TIME UPDATED_TIME);*/
/*�����֤���� = put(datepart(CREATED_TIME),yymmdd10.);*/
/*�����֤�������� = put(datepart(UPDATED_TIME),yymmdd10.);*/
/*rename CREATED_TIME = �����֤ʱ�� UPDATED_TIME = �����֤����ʱ��;*/
/*run;*/

/*�����ϵ�˵���ʱ��*/
/*proc sort data = lendRaw.user_relation_his out = relation_first(keep = user_code CREATED_TIME) nodupkey; by user_code CREATED_TIME; run;*/
/*proc sort data = relation_first(rename = (created_time = �״ε�����ϵ��ʱ��)) nodupkey; by user_code; run;*/
/*proc sort data = lendRaw.user_relation_his out = relation_last(keep = user_code CREATED_TIME) nodupkey; by user_code descending CREATED_TIME; run;*/
/*proc sort data = relation_last(rename = (created_time = ���µ�����ϵ��ʱ��)) nodupkey; by user_code; run;*/
/*data relation_verify;*/
/*merge relation_first(in = a) relation_last(in = b);*/
/*by user_code;*/
/*if a;*/
/*�״ε�����ϵ������ = put(datepart(�״ε�����ϵ��ʱ��), yymmdd10.);*/
/*���µ�����ϵ������ = put(datepart(���µ�����ϵ��ʱ��), yymmdd10.);*/
/*run;*/

/*�����Ӫ����֤ʱ��*/
/*data operator_verify;*/
/*set lendRaw.operator_verification(keep = user_code CREATED_TIME UPDATED_TIME);*/
/*��Ӫ����֤���� = put(datepart(CREATED_TIME),yymmdd10.);*/
/*��Ӫ����֤�·� = put(datepart(CREATED_TIME), yymmn6.);*/
/*��Ӫ�̸������� = put(datepart(UPDATED_TIME),yymmdd10.);*/
/*rename CREATED_TIME = ��Ӫ����֤ʱ�� UPDATED_TIME = ��Ӫ����֤����ʱ��;*/
/*run;*/

/*��Դ����*/
/*data source_channel;*/
/*set submart.register_submart(keep = USER_CODE ��Դ����);*/
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


***��Ӫ����֤͸�ӱ�����Դ;
/*data submart.operverify_submart;*/
/*set verify(where = (��Ӫ����֤���� ^= "") keep = USER_CODE ��Դ���� ��Ӫ����֤�·� ��Ӫ����֤����);*/
/*run;*/


