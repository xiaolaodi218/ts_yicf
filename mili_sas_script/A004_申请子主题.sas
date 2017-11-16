*******************************
		申请子主题
*******************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";


/*申请审批状态*/
data apply_status;
set dpRaw.apply_info(keep = apply_code status last_updated user_code os_type ip_area date_created apply_date loan_amt period service_amt desired_product);
format 申请结果 $20.;
if status = "HUMAN_REFUSE" then 申请结果 = "人工拒绝";
if status = "SYS_REFUSE" then 申请结果 = "系统拒绝";
if status = "HUMAN_AGREE" then 申请结果 = "人工通过";
if status = "SYS_APPROVING" then 申请结果 = "系统审核中";
if status = "REVIEWING" then 申请结果 = "人工复核";
if status = "HUMAN_CANCEL" then 申请结果 = "人工取消";
if status = "SYS_AGREE" then 申请结果 = "系统通过";
if status = "SYS_CANCEL" then 申请结果 = "系统取消";

**众网;
if status = "EXTERNAL_AGREE" then 申请结果 = "众网_审批通过";
if status = "EXTERNAL_REFUSE" then 申请结果 = "众网_审批拒绝";
if status = "EXTERNAL_APPROVING" then 申请结果 = "众网_审批中";

**众网标签;
if status in ("EXTERNAL_AGREE","EXTERNAL_REFUSE","EXTERNAL_APPROVING") then 订单类型2 = "众网客户订单";

rename apply_date = 申请开始时间 date_created = 申请提交时间;
run;
/*apply_info里有重复的几条数据，原因未知，先保留最新的，所以先对last_updated进行了逆序排序*/
proc sort data = apply_status nodupkey; by apply_code descending last_updated; run;
proc sort data = apply_status nodupkey; by apply_code; run;

/*审批下码*/
data handle_code;
set dpRaw.approval_info(keep = apply_code handle_code last_updated);
run;
/*前期策略结果为通过和人工审核的都需进入人工复核，所以有两条审批记录，还有些异常的重复数据，先保留最新的*/
proc sort data = handle_code nodupkey; by apply_code descending last_updated; run;
proc sort data = handle_code(drop = last_updated) nodupkey; by apply_code; run;

/*放款*/
data loan_info;
set lendRaw.loan_info(keep = apply_code loan_date status);
放款日期 = put(loan_date, yymmdd10.);
rename status = 放款状态;
run;
proc sort data = loan_info nodupkey; by apply_code; run;

/*申请-审批-放款*/
data apply_status;
merge apply_status(in = a) handle_code(in = b) loan_info(in = c);
by apply_code;
if a;
run;

proc sort data = apply_status out = apply_status_1 nodupkey; by user_code last_updated; run;
data apply_status_2;
set apply_status_1;
by user_code last_updated;
retain 第几次申请 1;
	 if first.user_code then 第几次申请 = 1;
else 第几次申请 = 第几次申请 + 1;
if first.user_code then 首次申请 = 1;
if last.user_code then 最新申请 = 1;
run;

/*首次放款日期*/
data first_loan_date;
set lendraw.loan_info(keep = apply_code id_card_no loan_date customer_apply_time customer_name status);
if status = "304";
rename loan_date = first_loan_date;
drop status;
run;
proc sort data = first_loan_date nodupkey; by id_card_no first_loan_date; run;
proc sort data = first_loan_date nodupkey; by id_card_no; run;
***拼上user_code;
data apply_user_code;
set dpraw.apply_info(keep = apply_code user_code);
run;
proc sort data = first_loan_date nodupkey; by apply_code; run;
proc sort data = apply_user_code nodupkey; by apply_code; run;
data first_loan_date;
merge first_loan_date(in = a) apply_user_code(in = b);
by apply_code;
if a;
drop apply_code customer_apply_time id_card_no;
run;

proc sort data = apply_status_2; by user_code; run;
proc sort data = first_loan_date nodupkey; by user_code; run;
data apply_status_3;
merge apply_status_2(in = a) first_loan_date(in = b);
by user_code;
if a;
if datepart(申请开始时间) > first_loan_date > 0 then 复贷申请 = 1;
run;

proc sql;
create table apply_sum as
select user_code, min(申请提交时间) as 首次申请提交时间 format datetime20., max(申请提交时间) as 最新申请提交时间 format datetime20., count(*) as 申请次数
from apply_status
group by user_code
;
quit;

/*来源渠道*/
data source_channel;
set submart.register_submart(keep = USER_CODE 来源渠道);
run;

proc sort data = apply_status_3; by user_code; run;
proc sort data = apply_sum nodupkey; by user_code; run;
proc sort data = source_channel nodupkey; by USER_CODE; run;


data submart.apply_submart;
merge apply_status_3(in = b) apply_sum(in = c) source_channel(in = d);
by user_code;
if b;
申请提交月份 = put(datepart(申请提交时间), yymmn6.);
申请提交日期 = put(datepart(申请提交时间), yymmdd10.);
首次申请提交月份 = put(datepart(首次申请提交时间), yymmn6.);
首次申请提交日期 = put(datepart(首次申请提交时间), yymmdd10.);
最新申请提交日期 = put(datepart(最新申请提交时间), yymmdd10.);
if customer_name in ("沙振华", "沈正喆") then delete;
/*25号之前拒绝后再申请的标记为无效申请*/
if 申请结果 in ("人工通过", "系统通过", "众网_审批通过") then 申请通过 = 1;
if 申请结果 in ("系统拒绝", "人工拒绝", "众网_审批拒绝") then 申请拒绝 = 1;

放款月份 = put(loan_date,yymmn6.);
if datepart(申请提交时间) > mdy(12,25,2016) or 最新申请 = 1 or 放款日期 ^= "" then 有效申请 = 1;

***上笔订单状态;
format 上笔订单状态 $20.;
if 放款状态 =  "304" then 上笔订单状态 = "放款";
if 放款状态 ^= "304" then 上笔订单状态 = "未放款";

drop 申请提交时间 last_updated 申请开始时间 ip_area first_loan_date 首次申请提交时间 最新申请提交时间 首次申请提交日期 最新申请提交日期
	 status os_type service_amt loan_date;
run;


/*第几次放款*/
data loan_times;
set submart.apply_submart(keep = apply_code user_code 放款状态 第几次申请 where = (放款状态 = "304"));
run;
proc sort data = loan_times nodupkey; by user_code 第几次申请; run;
data loan_times;
set loan_times;
by user_code 第几次申请;
retain 第几次放款 1;
	 if first.user_code then 第几次放款 = 1;
else 第几次放款 = 第几次放款 + 1;
keep apply_code 第几次放款;
run;

proc sort data = submart.apply_submart out = apply_submart nodupkey; by apply_code; run;
proc sort data = loan_times nodupkey; by apply_code; run;

data submart.apply_submart;
merge apply_submart(in = a) loan_times(in = b);
by apply_code;
if a;
format 订单类型 $20.;
if 首次申请 = 1 then 订单类型 = "新客户订单";
else if 复贷申请 = 1 then 订单类型 = "复贷客户订单";
else if desired_product = "MPD10"  then 订单类型 = "极速贷订单";
else 订单类型 = "拒绝客户订单";
run;



/*data apply_submart1234;*/
/*merge apply_submart(in = a) loan_times(in = b);*/
/*by apply_code;*/
/*if a;*/
/*format 订单类型 $20. 订单类型1 $20.;*/
/*if desired_product = "MPD10"  then 订单类型1 = "极速贷订单";*/
/**/
/*if 首次申请 = 1 then 订单类型 = "新客户订单";*/
/*else if 第几次申请>1 or 上笔订单状态 = "放款" then 订单类型 = "正常复贷客户订单";*/
/*else if 第几次申请>1 or 上笔订单状态 = "未放款" then 订单类型 = "拒绝后复贷客户订单";*/
/*else 订单类型 = "拒绝客户订单";*/
/*run;*/
/**/
/*run;proc freq data=apply_submart1234 noprint;*/
/*table 订单类型/out=cac1234;*/
/*run;*/
/**/
/*proc freq data=submart.apply_submart noprint;*/
/*table 申请结果/out=cac;*/

