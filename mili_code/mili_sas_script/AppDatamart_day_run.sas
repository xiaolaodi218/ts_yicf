option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";


%include "D:\mili\Datamart\script\S113_CX��������������.sas";

/*%include "D:\mili\Datamart\script\C001_�������������.sas";*/
/*%include "D:\mili\Datamart\script\C004_TD��ƽ̨������������.sas";*/
/*%include "D:\mili\Datamart\script\C002_�������������.sas";*/

%include "D:\mili\Datamart\script\L001_���������ǩ������.sas";
/*%include "D:\mili\Datamart\����demographic\ML_Demographics.sas";*/

/*���Ա���Ĵ���*/
%include "F:\celueji\python_script\Export_data.sas";
