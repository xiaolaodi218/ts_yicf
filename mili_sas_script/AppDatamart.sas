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

%include "D:\mili\Datamart\script\A001_注册子主题.sas";
%include "D:\mili\Datamart\script\A002_用户基本信息子主题.sas";
%include "D:\mili\Datamart\script\A003_认证子主题.sas";
%include "D:\mili\Datamart\script\A004_申请子主题.sas";
%include "D:\mili\Datamart\script\A005_审核子主题.sas";
%include "D:\mili\Datamart\script\A006_极速贷邀请名单子主题.sas";
%include "D:\mili\Datamart\script\A007_订单用户编号对应子主题.sas";

%include "D:\mili\Datamart\script\S001_策略调用执行子主题.sas";
%include "D:\mili\Datamart\script\S002_策略集结果子主题.sas";

%include "D:\mili\Datamart\script\S101_提交借款申请后BQS名单比对策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S102_提交借款申请后BQS贷款事件策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S103_提交借款申请后BQS人脸识别策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S104_提交借款申请后BQS银策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S105_提交借款申请后BQSIVS策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S106_复贷提交借款申请后BQS复贷事件策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S107_复贷2提交借款申请后BQS复贷事件策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S108_复贷提交借款申请后BQS人脸识别策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S109_复贷2提交借款申请后BQS人脸识别策略集下策略结果子主题.sas";
%include "D:\mili\Datamart\script\S110_提交借款申请后BQS决策事件策略集下策略结果子主题.sas";

%include "D:\mili\Datamart\script\S111_BQS规则命中子主题.sas";
%include "D:\mili\Datamart\script\S112_TD规则命中子主题.sas";
/*代码40,47需要python去取risk_creditx_resp和abmoduleflag_req数据更新以后才可以跑*/
/*%include "D:\mili\Datamart\script\S113_CX规则命中子主题.sas";*/

/*%include "D:\mili\Datamart\script\C001_规则变量子主题.sas";*/
/*%include "D:\mili\Datamart\script\C004_TD多平台申请数子主题.sas";*/
/*%include "D:\mili\Datamart\script\C002_策略入参子主题.sas";*/

/*%include "D:\mili\Datamart\script\L001_给订单打标签子主题.sas";*/
/*%include "D:\mili\Datamart\米粒demographic\ML_Demographics.sas";*/

/*策略报表的代码*/
/*%include "F:\celueji\python_script\Export_data.sas";*/
