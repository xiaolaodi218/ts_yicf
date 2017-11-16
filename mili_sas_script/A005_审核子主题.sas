*******************************
		审核子主题
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

data approval_info;
set dpRaw.approval_info;
审核处理日期 = put(datepart(handle_time), yymmdd10.);
审核处理月份 = put(datepart(handle_time), yymmn6.);
审核开始日期 = put(datepart(date_created), yymmdd10.);
审核开始月份 = put(datepart(date_created), yymmn6.);
rename date_created = 审核开始时间 last_updated = 审核更新时间 handle_time = 审核处理时间 remark = 审核备注;
drop id handler_id;
run;
/*系统拒绝*/
data sys_refuse;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "SYSTEM" and handle_result = "REJECT";
run;
proc sort data = sys_refuse nodupkey; by apply_code; run;
/*系统通过*/
data sys_agree;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "SYSTEM" and handle_result = "ACCEPT";
run;
proc sort data = sys_agree nodupkey; by apply_code; run;
/*人工通过*/
data human_agree;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "HUMAN" and handle_result = "ACCEPT";
run;
proc sort data = human_agree nodupkey; by apply_code; run;
/*人工拒绝*/
data human_refuse;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "HUMAN" and handle_result = "REJECT";
run;
proc sort data =human_refuse nodupkey; by apply_code; run;
/*系统审核中*/
data sys_init;
set approval_info;
if handle_status = "INIT" and handle_type = "SYSTEM";
run;
proc sort data = sys_init nodupkey; by apply_code; run;
/*人工审核中*/
data human_init;
set approval_info;
if handle_status = "INIT" and handle_type = "HUMAN";
run;
proc sort data = human_init nodupkey; by apply_code; run;
/*人工取消*/
data human_cancel;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "HUMAN" and handle_result = "CANCEL";
run;
proc sort data =human_cancel nodupkey; by apply_code; run;
/*系统取消*/
data sys_cancel;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "SYSTEM" and handle_result = "CANCEL";
run;
proc sort data =sys_cancel nodupkey; by apply_code; run;

/*众网拒绝*/
data zw_refuse;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "EXTERNAL" and handle_result = "REJECT";
run;
proc sort data =zw_refuse nodupkey; by apply_code; run;
/*众网通过*/
data zw_agree;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "EXTERNAL" and handle_result = "ACCEPT";
run;
proc sort data =zw_agree nodupkey; by apply_code; run;
/*众网审核中*/
data zw_init;
set approval_info;
if handle_status = "INIT" and handle_type = "EXTERNAL";
run;
proc sort data =zw_init nodupkey; by apply_code; run;

data approval;
set sys_refuse sys_agree human_agree human_refuse sys_init human_init human_cancel sys_cancel zw_refuse zw_agree zw_init;
run;
proc sql;
create table approval as
select a.*, b.refuse_name
from approval as a 
left join submart.refuse_map as b on a.handle_code = b.refuse_code
;
quit;
proc sort data = approval nodupkey; by apply_code descending 审核更新时间; run; /*有一些异常的单子如PL148202792530602600007429，同时有系统和人工拒绝的结果*/
proc sort data = approval nodupkey; by apply_code; run;
data submart.approval_submart;
set approval;
length 审批结果 $10;
	 if handle_type = "SYSTEM" and handle_result = "REJECT" then 审批结果 = "系统拒绝";
else if handle_type = "SYSTEM" and handle_result = "ACCEPT" then 审批结果 = "系统通过";
else if handle_type = "SYSTEM" and handle_result = "CANCEL" then 审批结果 = "系统取消";
else if handle_type = "HUMAN" and handle_result = "REJECT" and handle_code = "" then 审批结果 = "人工通过"; /*银策略筛选出来人工通过的订单*/
else if handle_type = "HUMAN" and handle_result = "REJECT" then 审批结果 = "人工拒绝"; 
else if handle_type = "HUMAN" and handle_result = "ACCEPT" then 审批结果 = "人工通过"; 
else if handle_type = "HUMAN" and handle_result = "CANCEL" then 审批结果 = "人工取消"; 
else if handle_type = "SYSTEM" then 审批结果 = "系统审核中";
else if handle_type = "HUMAN" then 审批结果 = "人工复核中";

/*else if handle_type = "EXTERNAL" and handle_result = "REJECT" then 审批结果 = "众网拒绝";*/
/*else if handle_type = "EXTERNAL" and handle_result = "ACCEPT" then 审批结果 = "众网通过";*/
/*else if handle_type = "EXTERNAL" then 审批结果 = "众网审核中";*/

else if handle_type = "EXTERNAL" and handle_result = "REJECT" then 审批结果 = "系统拒绝";
else if handle_type = "EXTERNAL" and handle_result = "ACCEPT" then 审批结果 = "系统拒绝";
else if handle_type = "EXTERNAL" then 审批结果 = "系统拒绝";

drop 审核开始时间 审核更新时间 审核处理时间 审核备注;
run;


***修改银策略筛出来客户的审批结果;
/*银策略筛出来被人工通过的客户*/
/*data silver_pass_user;*/
/*set lendraw.circular(keep = name user_code CREATED_TIME where = (name = "马上拿钱"));*/
/*run;*/
/*银策略筛出来被人工通过的订单*/
/*data silver_pass_apply;*/
/*set dpraw.approval_info(where = (handle_type = "HUMAN" and handle_result = "REJECT" and handle_code = ""));*/
/*keep apply_code;*/
/*run;*/
