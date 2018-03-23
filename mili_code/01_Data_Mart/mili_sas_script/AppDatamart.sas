option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";

/*lend raw data*/
%include "D:\mili\Datamart\script\Aaa_setRawData_applend.sas";

/*dp raw data*/
%include "D:\mili\Datamart\script\Aaa_setRawData_appdp.sas";

/*dw raw data*/
/*%include "D:\mili\Datamart\script\Aaa_SetRawData_dwdata.sas"*/

%include "D:\mili\Datamart\script\A001_ע��������.sas";
%include "D:\mili\Datamart\script\A002_�û�������Ϣ������.sas";
%include "D:\mili\Datamart\script\A003_��֤������.sas";
%include "D:\mili\Datamart\script\A004_����������.sas";
%include "D:\mili\Datamart\script\A005_���������.sas";
%include "D:\mili\Datamart\script\A006_���ٴ���������������.sas";
%include "D:\mili\Datamart\script\A007_�����û���Ŷ�Ӧ������.sas";

%include "D:\mili\Datamart\script\S001_���Ե���ִ��������.sas";
%include "D:\mili\Datamart\script\S002_���Լ����������.sas";

%include "D:\mili\Datamart\script\S101_�ύ��������BQS�����ȶԲ��Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S102_�ύ��������BQS�����¼����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S103_�ύ��������BQS����ʶ����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S104_�ύ��������BQS�����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S105_�ύ��������BQSIVS���Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S106_�����ύ��������BQS�����¼����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S107_����2�ύ��������BQS�����¼����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S108_�����ύ��������BQS����ʶ����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S109_����2�ύ��������BQS����ʶ����Լ��²��Խ��������.sas";
%include "D:\mili\Datamart\script\S110_�ύ��������BQS�����¼����Լ��²��Խ��������.sas";

%include "D:\mili\Datamart\script\S111_BQS��������������.sas";
%include "D:\mili\Datamart\script\S112_TD��������������.sas";
/*����40,47��Ҫpythonȥȡrisk_creditx_resp��abmoduleflag_req���ݸ����Ժ�ſ�����*/
/*%include "D:\mili\Datamart\script\S113_CX��������������.sas";*/

/*%include "D:\mili\Datamart\script\C001_�������������.sas";*/
/*%include "D:\mili\Datamart\script\C004_TD��ƽ̨������������.sas";*/
/*%include "D:\mili\Datamart\script\C002_�������������.sas";*/

/*%include "D:\mili\Datamart\script\L001_���������ǩ������.sas";*/
/*%include "D:\mili\Datamart\����demographic\ML_Demographics.sas";*/

/*���Ա���Ĵ���*/
/*%include "F:\celueji\python_script\Export_data.sas";*/
