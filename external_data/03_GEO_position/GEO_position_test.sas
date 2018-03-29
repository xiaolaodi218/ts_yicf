option compress=yes validvarname=any;
option missing = 0;

libname daily "D:\mili\offline\daily";
libname cred "D:\mili\offline\offlinedata\credit";
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*本次先取得500条左右的数据用来测试;
时间维度为2017/12/20 - 2017/12/31*/
************************************
Bad   —— 申请之后自动拒绝的客户
Good  —— 已经放款的客户
Indet —— 其他
************************************;

/*自动拒绝的客户*/
data _null_;
format dt_start yymmdd10.;
format dt_end yymmdd10.;
dt_start=mdy(12,21,2017);
dt_end=mdy(12,31,2017);
call symput("dt_start", dhms(dt_start,0,0,0));
call symput("dt_end",   dhms(dt_end,0,0,0));
run;

data auto_reject_bad;
set daily.auto_reject(keep = apply_code auto_reject_time auto_reject);
if auto_reject_time >= &dt_start.;	***取2017年12月21日份开始的放款***;
if auto_reject_time <= &dt_end.;	***取2017年12月31日份结束的放款***;
run;


/*已经放款的客户*/
data make_loan_good;
set daily.daily_acquisition(keep = APPLY_CODE 放款状态 放款日期 ID_CARD_NO);
if 放款状态 = "已放款";
if 放款日期 >= '21DEC2017'd;
if 放款日期 <= '31DEC2017'd;
run;

/*住址和公司住址信息*/
data com_res_info;
set centre.customer_info(keep = apply_code NAME PHONE1  居住省 居住市 居住区  RESIDENCE_ADDRESS 工作省 工作市 工作区 COMP_ADDRESS);
居住地址 = cats(居住省, 居住市, 居住区, RESIDENCE_ADDRESS);
工作地址 = cats(工作省, 工作市, 工作区, COMP_ADDRESS);
run;
proc sort data= com_res_info nodupkey ;by apply_code;run;


data test;
set auto_reject_bad  make_loan_good;
run;
proc sort data= test nodupkey ;by apply_code;run;


data apply_base;
set approval.apply_base(keep = apply_code ID_CARD_NO);
run;
proc sort data= apply_base nodupkey ;by apply_code;run;


data test_bb;
merge test(in = a) com_res_info(in = b) apply_base(in = c);
by apply_code;
if a ;
run;

/*32位MD5加密*/
data test_bba;
set test_bb;
rename  NAME = 姓名  PHONE1=手机号  ID_CARD_NO = 身份证号;
/*手机号 = put(md5(PHONE1), $hex32.);*/
/*身份证号 = put(md5(ID_CARD_NO), $hex32.);*/
if auto_reject = 1 then y = 1;
else y = 0;
run;

data test_B18;
set test_bba(keep = 姓名 手机号 身份证号 工作地址);
run;

data test_B19;
set test_bba(keep = 姓名 手机号 身份证号 居住地址);
run;

filename export "F:\TS\external_data_test\百度金融\data\test_B18.csv" encoding='utf-8';
PROC EXPORT DATA= test_B18 
			 outfile = export
			 dbms = csv replace;
RUN;

filename export "F:\TS\external_data_test\百度金融\data\test_B19.csv" encoding='utf-8';
PROC EXPORT DATA= test_B19 
			 outfile = export
			 dbms = csv replace;
RUN;
