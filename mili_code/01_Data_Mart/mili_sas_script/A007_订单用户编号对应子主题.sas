****************************************
	订单号与手机号身份证号等对应子主题
****************************************;
option compress = yes validvarname = any;

/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

***订单编号对应用户编号;
data apply_user_code;
set dpraw.apply_info(keep = apply_code user_code);
run;
***用户编号对应手机号;
data user_phone_no;
set lendraw.user(keep = user_code phone_no);
run;
***用户编号对应姓名身份证号;
data user_id_no;
set lendraw.user_base_info(keep = user_code user_name id_card);
run;

proc sort data = apply_user_code; by user_code; run;
proc sort data = user_phone_no nodupkey; by user_code; run;
proc sort data = user_id_no nodupkey; by user_code; run;
data submart.id_submart;
merge apply_user_code(in = a) user_phone_no(in = b) user_id_no(in = c);
by user_code;
if a;
run;
