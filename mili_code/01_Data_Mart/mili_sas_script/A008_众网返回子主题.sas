option compress = yes validvarname = any;

libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";

data zw_apply;
set dpraw.zw_apply;
������������ = put(datepart(date_created), yymmdd10.);
run;

data zw_apply;
set zw_apply;
format �������ؽ�� $20.;
if status = "AGREE" then �������ؽ�� = "ͨ��";
if status = "DISAGREE" then �������ؽ�� = "�ܾ�";
if status = "SEND_FAIL" then �������ؽ�� = "����������";
if status = "SEND_SUCCESS" then �������ؽ�� = "�������ɹ�";
if status = "INIT" then �������ؽ�� = "ϵͳ�����";
run;

proc freq data=zw_apply noprint;
table ������������*�������ؽ��/out=cac;
run;

data aaaaaaaa;
set zw_apply;
if status in ("SEND_FAIL","SEND_SUCCESS","INIT","INIT");
run;
