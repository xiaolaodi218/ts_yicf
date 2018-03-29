/*---output libname---*/
option compress=yes validvarname=any;
libname orig "F:\TS\offline_model\01_Dataset\01_original";
libname approval "D:\mili\offline\offlinedata\approval";
libname cred "D:\mili\offline\offlinedata\credit";

/*01---第一次处理*/
/*data baseline_model_data;*/
/*merge orig.target(in = a) orig.customer_demo(in = b) orig.credit_query_alldata(in = c); */
/*by apply_code;*/
/*if a;*/
/*run;*/

data baseline_model_data;
merge orig.target(in = a) orig.customer_demo(in = b); 
by apply_code;
if a;
run;

proc sort data = baseline_model_data nodupkey;by apply_code;run;

data orig.baseline_model_data;
set baseline_model_data;
drop 资金渠道 放款月份 apply_code LOAN_DATE es_date  产品小类 营业部 产品大类 es settled es_date od_days od_days_ever month cut_date target_label  
     REPORT_NUMBER ID_CARD   mob perf_period sample;
/*     征信获取时间  银行微众 银行消金 REAL_NAME;*/
if target ^= 2;
run; 
/*查看数据的列名*/
ods trace on;
proc contents data=orig.baseline_model_data;
ods output Variables=need_all;
run;
ods trace off;


filename export "F:\TS\offline_model\01_Dataset\02_Interim\baseline_model_data.csv" encoding='utf-8';
proc export DATA= orig.baseline_model_data
			 outfile = export
			 dbms = csv replace;
run;





/*02---第二次处理*/
/*未经过处理的数据*/
data orig_data;
merge orig.target(in = a) orig.apply_demo_method2(in = b) orig.credit_query_alldata2(in = c) approval.credit_score(in = d); 
by apply_code;
if a;
run;

proc sort data = orig_data nodupkey;by apply_code;run;

data orig.orig_data_2;
set orig_data;
drop 资金渠道 放款月份 LOAN_DATE es_date  产品小类 营业部 产品大类 es settled es_date od_days od_days_ever month cut_date target_label  
     REPORT_NUMBER ID_CARD   mob perf_period sample 进件时间 id_card_no residence_address permanent_address phone1 单位名称 comp_address
     工作省 工作市 工作区 industry_name cc_name oc_name 信用卡使用率 居住区 职位 CURRENT_INDUSTRY DESIRED_LOAN_LIFE 户籍市 ;
/*     征信获取时间  银行微众 银行消金 REAL_NAME 居住市 户籍省 ;*/
if target ^= 2;
run; 
/*查看数据的列名*/
ods trace on;
proc contents data=orig.orig_data_2;
ods output Variables=need_all_2;
run;
ods trace off;


filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_2.csv" encoding='utf-8';
proc export DATA= orig.orig_data_2
			 outfile = export
			 dbms = csv replace;
run;



/*03---第三次处理*/
/*本次只收集征信部分数据，删除缺失值，多重共线等*/
data target3;
set orig.target(keep = apply_code target);
if target ^= 2;
run;
proc sort data = target3 nodupkey;by apply_code;run;
/*proc sort data = cred.query_in3m nodupkey;by apply_code;run;*/

proc sort data = orig.credit_query_alldata nodupkey;by apply_code;run;

data orig_data3;
/*merge target3(in = a) cred.query_in3m(in = b);*/
merge target3(in = a)  orig.credit_query_alldata(in = b);
by apply_code;
if a;
run;

proc sort data = orig_data3 nodupkey;by apply_code;run;

/*查看数据的列名*/
ods trace on;
proc contents data=orig_data3;
ods output Variables=need_3;
run;
ods trace off;


filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_3.csv" encoding='utf-8';
proc export DATA= orig_data3
			 outfile = export
			 dbms = csv replace;
run;


/*04---第四次处理*/
/*本次只收集征信部分数据（刘垚数据），删除缺失值，多重共线等*/
data target4;
set orig.target;
if target ^= 2;
run;
proc sort data = target4 nodupkey;by apply_code;run;
proc sort data = cred.query_in3m nodupkey;by apply_code;run;

data orig_data4;
merge target4(in = a) cred.query_in3m(in = b);
by apply_code;
if a;
run;

proc sort data = orig_data4 nodupkey;by apply_code;run;

data orig_data_develop;
set orig_data4;
if 放款月份 in ("201606","201607","201608","201609","201610","201611","201612","201701","201702","201703","201704","201705","201706");
run;

data orig_data_validate ;
set orig_data4;
if 放款月份 in ("201707","201708");
run;

filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_develop.csv" encoding='utf-8';
proc export DATA= orig_data_develop
			 outfile = export
			 dbms = csv replace;
run;

filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_validate.csv" encoding='utf-8';
proc export DATA= orig_data_validate
			 outfile = export
			 dbms = csv replace;
run;

/*06---第6次处理*/
/*客户基本信息的数据*/
data target;
set orig.target(keep = apply_code target);
if target ^= 2;
run;

data orig_data;
merge target(in = a) orig.apply_demo_method3(in = b); 
by apply_code;
if a;
run;

proc sort data = orig_data out =orig.orig_data_6 nodupkey;by apply_code;run;


/*查看数据的列名*/
ods trace on;
proc contents data=orig.orig_data_6;
ods output Variables=need_all_6;
run;
ods trace off;


filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_6.csv" encoding='utf-8';
proc export DATA= orig.orig_data_6
			 outfile = export
			 dbms = csv replace;
run;










/*20170316数据收集全部变量*/

/*客户基本信息的数据*/
/*本次收集的征信部分数据（刘垚数据），删除缺失值等*/

data target;
set orig.target(keep = apply_code 放款月份 target);
if target ^= 2;
run;

proc sort data = cred.query_in3m nodupkey;by apply_code;run;
proc sort data = orig.apply_demo_method3 nodupkey;by apply_code;run;

data orig_data_all;
merge target(in = a) orig.apply_demo_method3(in = b) cred.query_in3m(in = c); 
by apply_code;
if a;
run;

proc sort data = orig_data_all nodupkey;by apply_code;run;

data orig_data_develop;
set orig_data_all;
if 放款月份 in ("201606","201607","201608","201609","201610","201611","201612","201701","201702","201703","201704","201705");
run;

data orig_data_validate ;
set orig_data_all;
if 放款月份 in ("201706","201707");
run;

filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_develop.csv" encoding='utf-8';
proc export DATA= orig_data_develop
			 outfile = export
			 dbms = csv replace;
run;

filename export "F:\TS\offline_model\01_Dataset\02_Interim\orig_data_validate.csv" encoding='utf-8';
proc export DATA= orig_data_validate
			 outfile = export
			 dbms = csv replace;
run;
