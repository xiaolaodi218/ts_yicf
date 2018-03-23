option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";


%include "D:\mili\Datamart\script\S113_CX规则命中子主题.sas";

/*%include "D:\mili\Datamart\script\C001_规则变量子主题.sas";*/
/*%include "D:\mili\Datamart\script\C004_TD多平台申请数子主题.sas";*/
/*%include "D:\mili\Datamart\script\C002_策略入参子主题.sas";*/

%include "D:\mili\Datamart\script\L001_给订单打标签子主题.sas";
/*%include "D:\mili\Datamart\米粒demographic\ML_Demographics.sas";*/

/*策略报表的代码*/
%include "F:\celueji\python_script\Export_data.sas";
