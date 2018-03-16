option compress = yes validvarname = any;
********************
app数据
********************;
/*libname lend odbc datasrc=mili_applend;*/
libname lend odbc datasrc=Prod_applend;

libname lendRaw "D:\mili\Datamart\rawdata\applend";

/*proc copy in = lend out = lendRaw; run;*/

/*限制时间为近7天*/
data _null_;
format dt yymmdd10.;
dt= today() - 3;
call symput("dt", dhms(dt,0,0,0));
run;

data _null_;
a = time();
call symput('start', a);
run;

**************************************** user ****************************************;
data lendRaw.user;
set lend.user(drop = HAND_PASSWORD CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION REMARK);
run;
/*data user_temp;*/
/*set lend.user(drop = HAND_PASSWORD CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION REMARK*/
/*             where = (UPDATED_TIME >= &dt.));*/
/*run;*/
/*data user_all;*/
/*set lendRaw.user  user_temp;*/
/*run;*/
/*/*proc sort data = user_all nodupkey out = user_old;by id;run;*/*/
/*/*排序*/*/
/*proc sort data = user_all out = user_a1;
/*by id;*/
/*run;*/
/*/*去重;*/*/
/*data user_new; */
/*if _n_=1 then do;*/
/*  declare hash c();*/
/*  c.definekey("id");*/
/*  c.definedata("id");*/
/*  c.definedone();*/
/*end;*/
/*   set user_a1 end=done;  */
/*   if c.find() ^= 0 then do;      */
/*      c.add(); */
/*  output; */
/*   end;  */
/*run; */

**************************************** loan_info ****************************************;
/*直接更新*/
data lendRaw.loan_info;
set lend.loan_info(drop = contract_no loan_sn card_no card_name bank_code capital_channel_code interest_amount customer_apply_time 
last_submit_updated arrival_time annual_interest_rate interest_amount suspended loan_list_num serial_num documentation_fee user_current_age);
run;

**************************************** user_base_info ****************************************;
data lendRaw.user_base_info;
set lend.user_base_info(drop = PERMANENT_ADDRESS MARRIAGE RESIDENCE_CONDITION RESIDENCE_PROVINCE RESIDENCE_CITY RESIDENCE_REGION REMARK 
CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION CURR_JOB_SENIORITY MONTH_SALARY JOB_COMPANY_CONDITION 
JOB_COMPANY_CITY JOB_COMPANY_PROVINCE JOB_COMPANY_REGION DEGREE residence_address_name job_company_address_name residence_apartment_number 
job_company_apartment_number);
run;
/*data user_base_info_temp;*/
/*set lend.user_base_info(drop = PERMANENT_ADDRESS MARRIAGE RESIDENCE_CONDITION RESIDENCE_PROVINCE RESIDENCE_CITY RESIDENCE_REGION REMARK */
/*CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION CURR_JOB_SENIORITY MONTH_SALARY JOB_COMPANY_CONDITION */
/*JOB_COMPANY_CITY JOB_COMPANY_PROVINCE JOB_COMPANY_REGION DEGREE residence_address_name job_company_address_name residence_apartment_number */
/*job_company_apartment_number where = (UPDATED_TIME >= &dt.));*/
/*run;*/
/*data user_base_info_all;*/
/*set lendRaw.user_base_info  user_base_info_temp;*/
/*run;*/
/*/*proc sort data = user_base_info_all nodupkey out = user_base_info_old;by id;run;*/*/
/*/*排序*/*/
/*proc sort data = user_base_info_all out = user_base_info_a1;
/*by id;*/
/*run;*/
/*/*去重;*/*/
/*data user_base_info_new; */
/*if _n_=1 then do;*/
/*  declare hash c();*/
/*  c.definekey("id");*/
/*  c.definedata("id");*/
/*  c.definedone();*/
/*end;*/
/*   set user_base_info_a1 end=done;  */
/*   if c.find() ^= 0 then do;      */
/*      c.add(); */
/*  output; */
/*   end;  */
/*run; */

**************************************** id_verification ****************************************;
data lendRaw.id_verification;
set lend.id_verification(drop = ID_VERIFY_CODE USER_NAME CREATED_USER_NAME UPDATED_USER_NAME CREATED_USER_ID UPDATED_USER_ID VERSION REMARK PERMANENT_ADDRESS ID_CARD);
run;

**************************************** user_relation_his ****************************************;
data lendRaw.user_relation_his;
set lend.user_relation_his(drop = REMARK CREATED_USER_NAME CREATED_USER_ID VERSION);
run;

**************************************** user_relation ****************************************;
data lendRaw.user_relation;
set lend.user_relation(drop = VERSION UPDATED_USER_NAME CREATED_USER_NAME CREATED_USER_ID UPDATED_USER_ID REMARK RELATION_TYPE);
run;

**************************************** operator_verification ****************************************;
libname lend odbc datasrc=Prod_applend;
data lendRaw.operator_verification;
set lend.operator_verification(drop = OPERATOR_VERIFY_CODE SERVICE_PASSWORD REMARK CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION);
run;

**************************************** user_verification_info ****************************************;
data lendRaw.user_verification_info;
set lend.user_verification_info(drop = VERIFICATION_SN REFERENCE_NO USER_NAME REMARK CREATED_USER_ID CREATED_USER_NAME UPDATED_USER_ID UPDATED_USER_NAME VERSION);
run;

**************************************** circular ****************************************;
/*data lendRaw.circular;*/
/*set lend.circular;*/
/*run;*/

data _null_;
a = time();
b = a - &start.;
put b time.;
run;
