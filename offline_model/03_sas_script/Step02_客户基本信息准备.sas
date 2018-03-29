option compress=yes validvarname=any;
libname centre "D:\mili\offline\centre_data\daily";
libname approval "D:\mili\offline\offlinedata\approval";

/*---output libname---*/
libname orig "F:\TS\offline_model\01_Dataset\01_original";

data customer_info;
merge centre.customer_info(in = a) approval.apply_info(in = b) approval.credit_score(in = c);
by apply_code;
if a;
run;


/*------------------------------第三种方法得到客户基本信息的数据------------------------------*/

data orig.apply_demo_method3;
set customer_info(keep = 
apply_code  进件时间 approve_产品 BRANCH_NAME
DESIRED_LOAN_LIFE  DESIRED_LOAN_AMOUNT  CHILD_COUNT age 教育程度 性别 婚姻状况  
/*居住省 居住市 居住区 户籍省 户籍市 户籍区  工作省 工作市 工作区 入职时间 单位名称 职位*/
/*YEARLY_INCOME*/
居住市  户籍市   WORK_YEARS 住房性质  职级 外部负债率
单位性质  贷款月还 信用卡月还 社保基数 公积金基数 
IS_HAS_CAR  IS_HAS_HOURSE 财产信息  简版汇总负债总计  
信用卡使用率 准贷记卡月还 其他负债  MONTHLY_SALARY MONTHLY_OTHER_INCOME 薪资发放方式
score  group_level risk_level 
);


/*居住地与户籍关系*/;
if 居住市=户籍市 then 是否本地 = "本地";
else  是否本地 = "外地";

/*根据指定字符定位截取字符串,将营业部保留为城市名*/
format 申请城市$50.;
	 if index(BRANCH_NAME, "呼和浩特市第一营业部") then 申请城市 = "呼和浩特";
else if index(BRANCH_NAME, "乌鲁木齐市第一营业部") then 申请城市 = "乌鲁木齐";
else 申请城市=substr(BRANCH_NAME,1, 4);

/*申请贷款期数*/;
if DESIRED_LOAN_LIFE=341  then 贷款申请期限=6;
else if DESIRED_LOAN_LIFE=342 then 贷款申请期限=12;
else if DESIRED_LOAN_LIFE=343 then 贷款申请期限=18;
else if DESIRED_LOAN_LIFE=344 then 贷款申请期限=24;
else if DESIRED_LOAN_LIFE=345 then 贷款申请期限=36;
else if 贷款申请期限=0;

/*公积金社保基数*/;
if 社保基数 >公积金基数  then 社保公积基数=社保基数;
else 社保公积基数=公积金基数;

征信负债率 = 外部负债率/100;
信用卡使用率 = 信用卡使用率/100;

计算年收入 = (MONTHLY_SALARY + MONTHLY_OTHER_INCOME) *12;
计算负债率1 = (信用卡月还 + 准贷记卡月还 + 贷款月还)/(MONTHLY_SALARY + MONTHLY_OTHER_INCOME);
计算负债率2 = (信用卡月还 + 准贷记卡月还 + 贷款月还)/(社保公积基数);

rename 
approve_产品 = 申请产品      age = 年龄   
DESIRED_LOAN_AMOUNT = 申请贷款金额  WORK_YEARS = 工作年限
CHILD_COUNT = 子女个数  IS_HAS_CAR = 是否有车   IS_HAS_HOURSE = 是否有房
MONTHLY_SALARY = 月收入  MONTHLY_OTHER_INCOME = 月其他收入
;

drop BRANCH_NAME DESIRED_LOAN_LIFE 社保基数 公积金基数 居住市  户籍市 外部负债率;

run;

ods trace on;
proc contents data=orig.apply_demo_method3;
ods output Variables=need_cus3;
run;
ods trace off;














/*------------------------------第一种方法得到客户基本信息的数据------------------------------*/

data orig.apply_demo_method2;
set customer_info;

/*/*居住地址*/*/
/*format 居住地址区域 $50.;*/
/*if 居住省 in ("上海市","江苏省","浙江省","安徽省","江西省","山东省","福建省") then 居住地址区域 ="华东地区" ;*/
/*else if 居住省 in ("北京市","天津市","山西省","河北省","内蒙古自治区") then 居住地址区域 ="华北地区" ;*/
/*else if 居住省 in ("河南省","湖北省","湖南省") then 居住地址区域 ="华中地区" ;*/
/*else if 居住省 in ("广东省","广西壮族自治区","海南省") then 居住地址区域 ="华南地区" ;*/
/*else if 居住省 in ("四川省","贵州省","云南省","重庆市","西藏自治区") then 居住地址区域 ="西南地区" ;*/
/*else if 居住省 in ("陕西省","甘肃省","青海省","宁夏回族自治区","新疆维吾尔自治区") then 居住地址区域 ="西北地区" ;*/
/*else if 居住省 in ("黑龙江省","吉林省","辽宁省","内蒙古自治区") then 居住地址区域 ="东北地区" ;*/
/*else 居住地址区域 = "";*/
/**/
/*format 户籍城市类型 $20.;*/
/*if 户籍市 in ("北京市", "上海市", "广州市","深圳市") then 户籍城市类型 = "一线城市";*/
/*else if 户籍城市类型 = "二三线城市";*/
/**/
/*format 居住城市类型 $20.;*/
/*if 居住市 in ("北京市","上海市","广州市","深圳市") then 居住城市类型 = "一线城市";*/
/*else if 居住城市类型 = "二三线城市";*/

/*申请贷款期数*/;
if DESIRED_LOAN_LIFE=341  then apply_loanamt_g=6;
else if DESIRED_LOAN_LIFE=342 then apply_loanamt_g=12;
else if DESIRED_LOAN_LIFE=343 then apply_loanamt_g=18;
else if DESIRED_LOAN_LIFE=344 then apply_loanamt_g=24;
else if DESIRED_LOAN_LIFE=345 then apply_loanamt_g=36;
else if apply_loanamt_g=0;

/*居住地与户籍关系*/;
if 居住市=户籍市 then res_type_g=0;
else  res_type_g=1;

/*公积金基数，社保基数*/
if SOCIAL_SECURITY_RADICES>=PUBLIC_FUNDS_RADICES then SOCIAL_PUBLIC_RADICES=SOCIAL_SECURITY_RADICES;
else SOCIAL_PUBLIC_RADICES=PUBLIC_FUNDS_RADICES;

/*月还*/
if loan_month_return_new >贷款月还 then 贷款月还 = loan_month_return_new;
if card_used_amt_sum_new>信用卡月还 then 信用卡月还 = card_used_amt_sum_new;
if 旧月负债率>负债率   then 负债率=旧月负债率/100;
if 社保基数 >公积金基数  then 基数=社保基数;
else 基数=公积金基数;

/*信用卡总额度*/
rename 信用卡总额 = credit_amt_all;

/*信用卡使用率*/
credit_use_ratio = 信用卡使用率/100;

/*外部负债率*/
external_debt_ratio = 外部负债率/100;

/*负债率*/
debt_ratio = 负债率/100;


rename  简版汇总负债总计=debt_amt_all  基数=social_fund_basenum  
		贷记卡近5年逾期90以上次数 = CARD_60_PASTDUE_M3_FREQUENCY
		贷记卡近5年逾期次数 = CARD_60_PASTDUE_FREQUENCY
		抵押贷款近5年逾期90天以上次数 = LOAN_MORTGAGE_M3_FREQUENCY
		抵押贷款近5年逾期次数 = LOAN_MORTGAGE_60_FREQUENCY
		公积金基数=FUND_MONTH
		近1个月本人查询次数=SELF_QUERY_01_MONTH_FREQUENCY
		近1个月贷款查询次数=LOAN__QUERY_01_MONTH_FREQUENCY
		近1个月信用卡查询次数=CARD_APPLY_01_MONTH_FREQUENCY
		近2年贷款查询次数=LOAN__QUERY_24_MONTH_FREQUENCY
		近2年个人查询次数=SELF_QUERY_24_MONTH_FREQUENCY
		近2年信用卡查询次数=CARD_APPLY_24_MONTH_FREQUENCY
		近3个月本人查询次数=SELF_QUERY_03_MONTH_FREQUENCY
		近3个月贷款查询次数=LOAN__QUERY_03_MONTH_FREQUENCY
		近3个月信用卡查询次数=CARD_APPLY_03_MONTH_FREQUENCY
		其他性质贷款近5年逾期90天以上=LOAN_OTHER__M3_FREQUENCY
		其他性质贷款近5年逾期次数=LOAN_OTHER_60_FREQUENCY
		社保基数	=SOCIAL_SECURITY_MONTH
		无抵押贷款近5年逾期90天以上次数=LOAN_NAMORTGAGE_M3_FREQUENCY
		无抵押贷款近5年逾期次数=LOAN_60_PASTDUE_FREQUENCY;

drop NAME BRANCH_CODE BRANCH_NAME SOURCE_CHANNEL DESIRED_PRODUCT 进件 回退门店时间 回退门店 END_ACT_ID_ ACT_ID_  当前状态	 
auto_reject_time auto_reject ID FIRST_REFUSE_CODE FIRST_REFUSE_DESC SECOND_REFUSE_CODE SECOND_REFUSE_DESC THIRD_REFUSE_CODE 
THIRD_REFUSE_DESC REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 CANCEL_REMARK FACE_SIGN_REMIND check_end 
REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 批核状态 check_date 批核月份 check_week	通过	拒绝	 sales_name  
approve_产品	contract_no	sign_date 签约时间 放款月份 放款日期 created_name_first  updated_time_first 批核产品大类_终审 sales_code  
REFUSE_INFO_NAME_final REFUSE_INFO_NAME_LEVEL1_final REFUSE_INFO_NAME_LEVEL2_final created_name_final  updated_time_final  
缴费方式 CREATED_TIME 批核产品小类_终审 INSURANCE_COMPANY 入职时间 旧银行流水 旧其他收入 旧月负债 旧月负债率 批核期限_终审
批核金额_终审 到手金额 合同金额 服务费 单证费 资金渠道 户籍区 INSURANCE_PAY_METHOD INSURANCE_EFFECTIVE_DATE INSURANCE_PAY_AMT
核实收入 核实代发工资 其他负债 信用卡透支总额 SOCIAL_SECURITY_RADICES PUBLIC_FUNDS_RADICES ;  

run;

proc sort data = orig.apply_demo_method2 nodupkey;by apply_code;run;

ods trace on;
proc contents data=orig.apply_demo_method2;
ods output Variables=need_cus2;
run;
ods trace off;












/*------------------------------第一种方法得到客户基本信息的数据------------------------------*/

data centre.apply_demo;
set customer_info;

/*教育程度分类*/
if 教育程度 in ("硕士及其以上") then education_g=0;
else if 教育程度 in ("大学本科") then education_g=1;
else if 教育程度 in ("专科") then education_g=2;
else if 教育程度 in ("高中","中专") then education_g=3;
else if 教育程度 in ("初中","小学") then education_g=4;
else education_g=5;
/*if 教育程度 in ("硕士及其以上","大学本科") then education_g=1;else education_g=0;*/


/*婚姻状况*/
if 婚姻状况="未婚" then marriage_g=0;  
else if 婚姻状况="已婚" then marriage_g=1;
else if 婚姻状况 in ("丧偶","离异") then marriage_g=2;
else  marriage_g=3;
/*if 婚姻状况 in("离异","未婚") then marriage_g=1;else marriage_g=0;*/

/*性别*/
/*if 性别="男" then gender_g=0 ; */
/*if 性别="女" then gender_g=1 ; */
/*else if 性别="" then gender_g=2 ;*/
if 性别="男" then gender_g=0 ;else gender_g=1;

/*年龄 age*/
if age<18 then age_g=0;
else if age>=18 and age<=25 then age_g=1;
else if age>25 and age<=30 then age_g=2;
else if age>30 and age<=35 then age_g=3;
else if age>35 and age<=40 then age_g=4;
else if age>40 and age<=45 then age_g=5;
else if age>45 and age<=55 then age_g=6;
else if age>55 and age<=60 then age_g=7;
else age_g=8;

/*子女个数 CHILD_COUNT*/
if CHILD_COUNT=0 or CHILD_COUNT=. then child_count_g=0;
else if CHILD_COUNT=1 then child_count_g=1;
else if CHILD_COUNT=2 then child_count_g=2;
else child_count_g=3;


/*有无房产*/
if IS_HAS_HOURSE="y" then is_has_hourse_g=1;
else if IS_HAS_HOURSE="n" then is_has_hourse_g=0;
else is_has_hourse_g=2;

/*有无汽车*/
if IS_HAS_CAR="y" then is_has_car_g=1;
else if IS_HAS_CAR="n" then is_has_car_g=0;
else is_has_car_g=2;

/*是否与父母一起居住*/
if IS_LIVE_WITH_PARENTS="y"  then is_live_parents_g=1;
else if IS_LIVE_WITH_PARENTS="n" then is_live_parents_g=0;
else is_live_parents_g=2;

/*是否有保单,针对E保通和E保通-自雇*/
if IS_HAS_INSURANCE_POLICY="y" then is_has_insurance_g=1;
else is_has_insurance_g=0;

/*居住地址*/
format 居住地址区域 $50.;
if 居住省 in ("上海市","江苏省","浙江省","安徽省","江西省","山东省","福建省") then 居住地址区域 ="华东地区" ;
else if 居住省 in ("北京市","天津市","山西省","河北省","内蒙古自治区") then 居住地址区域 ="华北地区" ;
else if 居住省 in ("河南省","湖北省","湖南省") then 居住地址区域 ="华中地区" ;
else if 居住省 in ("广东省","广西壮族自治区","海南省") then 居住地址区域 ="华南地区" ;
else if 居住省 in ("四川省","贵州省","云南省","重庆市","西藏自治区") then 居住地址区域 ="西南地区" ;
else if 居住省 in ("陕西省","甘肃省","青海省","宁夏回族自治区","新疆维吾尔自治区") then 居住地址区域 ="西北地区" ;
else if 居住省 in ("黑龙江省","吉林省","辽宁省","内蒙古自治区") then 居住地址区域 ="东北地区" ;
else 居住地址区域 = "";

if 居住地址区域 in ("华东地区","华南地区","华北地区") then live_province_g = 0;
else live_province_g = 1;

/*住房性质*/
if 住房性质 = "无按揭购房" then hourse_lodg_g = 0;
else if 住房性质 = "公积金按揭购房" then hourse_lodg_g = 1;
else if 住房性质 = "商业按揭房" then hourse_lodg_g =2; 
else if 住房性质 = "亲属住房" then hourse_lodg_g = 3;
else if 住房性质 = "自建房" then hourse_lodg_g = 4;
else if 住房性质 = "租用" then hourse_lodg_g = 5;
else hourse_lodg_g = 7;
/*else if 住房性质 in("其他","") then hourse_lodg_g = 6;*/


/*本市生活时长 LOCAL_RES_YEARS*/
if LOCAL_RES_YEARS>=0 and LOCAL_RES_YEARS<1 then local_res_years_g=0;
else if LOCAL_RES_YEARS>=1 and LOCAL_RES_YEARS<3 then local_res_years_g=1;
else if LOCAL_RES_YEARS>=3 and LOCAL_RES_YEARS<5 then local_res_years_g=2;
else if LOCAL_RES_YEARS>=5 and LOCAL_RES_YEARS<10 then local_res_years_g=3;
else if LOCAL_RES_YEARS>=10 and LOCAL_RES_YEARS<20 then local_res_years_g=4;
else if LOCAL_RES_YEARS>=20 then local_res_years_g=5;


/*工作变动次数 WORK_CHANGE_TIMES*/
if WORK_CHANGE_TIMES=0 then work_change_times_g=0;
else if WORK_CHANGE_TIMES=1 then work_change_times_g=1;
else if WORK_CHANGE_TIMES=2 then work_change_times_g=2;
else if WORK_CHANGE_TIMES>=3 then work_change_times_g=3;
else work_change_times_g = 4;

/*工作年限 work_years*/
if work_years=0  then work_years_g=0;
else if work_years<1 then work_years_g=1;
else if work_years<3 then work_years_g=2;
else if work_years<5 then work_years_g=3;
else if work_years<10 then work_years_g=4;
else if work_years<20 then work_years_g=5;
else if work_years>=20 then work_years_g=6;
else work_years_g=7;

/*申请贷款金额*/
/*if 10000<DESIRED_LOAN_AMOUNT<=40000  then apply_loanamt_g=5;*/
/*else if 40000<DESIRED_LOAN_AMOUNT<=60000 then apply_loanamt_g=4;*/
/*else if 60000<DESIRED_LOAN_AMOUNT<=80000 then apply_loanamt_g=3;*/
/*else if 80000<DESIRED_LOAN_AMOUNT<=100000 then apply_loanamt_g=2;*/
/*else if 100000<DESIRED_LOAN_AMOUNT<=150000 then apply_loanamt_g=1;*/
/*else if DESIRED_LOAN_AMOUNT>150000 then apply_loanamt_g=0;*/
/*else if apply_loanamt_g=6;*/

/*申请贷款期数*/
if DESIRED_LOAN_LIFE=341  then apply_loanamt_g=6;
else if DESIRED_LOAN_LIFE=342 then apply_loanamt_g=12;
else if DESIRED_LOAN_LIFE=343 then apply_loanamt_g=18;
else if DESIRED_LOAN_LIFE=344 then apply_loanamt_g=24;
else if DESIRED_LOAN_LIFE=345 then apply_loanamt_g=36;
else if apply_loanamt_g=0;


/*信用卡总额度*/
rename 信用卡总额 = credit_amt;
/*if credit_amt=0  then credit_amt_g=0;*/
/*if 0<credit_amt<=25000  then credit_amt_g=1;*/
/*else if 25000<credit_amt<=35000 then credit_amt_g=2;*/
/*else if 35000<credit_amt<=50000 then credit_amt_g=3;*/
/*else if 50000<credit_amt<=75000 then credit_amt_g=4;*/
/*else if 75000<credit_amt<=100000 then credit_amt_g=5;*/
/*else if 100000<credit_amt<=150000 then credit_amt_g=6;*/
/*else if 150000<credit_amt<=200000 then credit_amt_g=7;*/
/*else if 200000<credit_amt<=400000 then credit_amt_g=8;*/
/*else if credit_amt>400000 then credit_amt_g=9;*/


/*信用卡使用率*/
credit_use_ratio = 信用卡使用率/100;
/*if 0<credit_use_ratio<=0.12  then credit_use_g=0;*/
/*else if 0.12<credit_use_ratio<=0.36 then credit_use_g=1;*/
/*else if 0.36<credit_use_ratio<=0.5 then credit_use_g=2;*/
/*else if 0.5<credit_use_ratio<=0.6 then credit_use_g=3;*/
/*else if 0.6<credit_use_ratio<=0.75 then credit_use_g=4;*/
/*else if 0.75<credit_use_ratio<=0.9 then credit_use_g=5;*/
/*else if 0.9<credit_use_ratio<=1.0 then credit_use_g=6;*/
/*else if credit_use_ratio>1 then credit_use_g=7;*/
/*else if credit_use_g=8;*/

/*/*年收入*/*/
/*if 0<=YEARLY_INCOME<10000 then yearly_income_g = 7; */
/*else if 10000<=YEARLY_INCOME<30000 then yearly_income_g = 6; */
/*else if 30000<=YEARLY_INCOME<60000 then yearly_income_g = 5; */
/*else if 60000<=YEARLY_INCOME<100000 then yearly_income_g = 4; */
/*else if 100000<=YEARLY_INCOME<150000 then yearly_income_g = 3; */
/*else if 150000<=YEARLY_INCOME<300000 then yearly_income_g = 2; */
/*else if 300000<=YEARLY_INCOME<1000000 then yearly_income_g = 1; */
/*else if YEARLY_INCOME>=1000000 then yearly_income_g = 0; */
/*else if yearly_income_g = 8; */


/*房产套数 HOURSE_COUNT*/
/*存在空值*/;
if HOURSE_COUNT=0 then hourse_count_g=0;
else if HOURSE_COUNT=1 then hourse_count_g=1;
else if HOURSE_COUNT=2 then hourse_count_g=2;
else if HOURSE_COUNT>=3 then hourse_count_g=3;
else hourse_count_g=4;

/*汽车数量 CAR_COUNT*/
/*存在空值*/
if CAR_COUNT=0 then car_count_g=0;
else if CAR_COUNT=1 then car_count_g=1;
else if CAR_COUNT>=2 then car_count_g=2;
else if CAR_COUNT=. then car_count_g=3;

/*/*核实收入*/*/
/*if 核实收入<=0 or 核实收入=. then verify_income_g=0;*/
/*else if 核实收入<3000 then verify_income_g=1;*/
/*else if 核实收入<5000 then verify_income_g=2;*/
/*else if 核实收入<8000 then verify_income_g=3;*/
/*else if 核实收入<10000 then verify_income_g=4;*/
/*else if 核实收入<20000 then verify_income_g=5;*/
/*else if 核实收入<30000 then verify_income_g=6;*/
/*else if 核实收入<50000 then verify_income_g=7;*/
/*else if 核实收入<100000 then verify_income_g=8;*/
/*else if 核实收入>=100000 then verify_income_g=9;*/

/*居住地与户籍关系*/;
if 居住市=户籍市 then res_type_g=0;
else  res_type_g=1;

/*户口类型*/
if 户口性质="本地城镇" then do; permanent_type_g=0;;end;
if 户口性质="本地农村"  then do; permanent_type_g=1;;end;
if 户口性质="外地城镇" then do; permanent_type_g=2;;end;
if 户口性质="外地农村" then do; permanent_type_g=3;;end;

/*工资发放路径*/
if 薪资发放方式="现金" then salary_pay_way_g=0;
if 薪资发放方式="打卡" then salary_pay_way_g=1;
if 薪资发放方式="银行代发" then salary_pay_way_g=2;
if 薪资发放方式="其他" then salary_pay_way_g=3;
if 薪资发放方式="均有" then salary_pay_way_g=4;

/*房产性质*/
if 房产性质="公积金按揭购房"  then local_rescondition_g =0;
else if 房产性质="公司宿舍"  then local_rescondition_g =1;
else if 房产性质="亲属住房"  then local_rescondition_g =2;
else if 房产性质="商业按揭房"  then local_rescondition_g =3;
else if 房产性质="无按揭购房"  then local_rescondition_g =4;
else if 房产性质="自建房"  then local_rescondition_g =5;
else if 房产性质="租用"  then local_rescondition_g =6;
else if 房产性质="其他"  then local_rescondition_g =7;

/*职级*/
if 职级= "非正式员工" then position_g =0;
else if 职级= "负责人" then position_g =1;
else if 职级= "高级管理人员" then position_g =2;
else if 职级= "派遣员工" then position_g =3;
else if 职级= "一般管理人员" then position_g =4;
else if 职级= "一般正式员工" then position_g =5;
else if 职级= "中级管理人员" then position_g =6;

/*单位性质*/
if 单位性质 ="机关事业单位" then comp_type_g=0;
else if 单位性质 ="国有股份" then comp_type_g=1;
else if 单位性质 in ("合资企业","外资企业") then comp_type_g=2;
else if 单位性质 in ("民营企业","私营企业") then comp_type_g=3;
else if 单位性质 ="社会团体" then comp_type_g=4;
else if 单位性质 ="个体" then comp_type_g=5;
else comp_type_g = 6;

/*外地标签*/
if 外地标签="本地"  then  nonlocal_g=0; else nonlocal_g = 1;

/*财产信息*/
if 财产信息 = "有房有车" then asset_info_g = 0;
else if 财产信息 = "有房无车" then asset_info_g =1;
else if 财产信息 = "无房有车" then asset_info_g = 2;
else if 财产信息 = "无房无车" then asset_info_g = 3;

/*公积金基数，社保基数*/
if SOCIAL_SECURITY_RADICES>=PUBLIC_FUNDS_RADICES then SOCIAL_PUBLIC_RADICES=SOCIAL_SECURITY_RADICES;
else SOCIAL_PUBLIC_RADICES=PUBLIC_FUNDS_RADICES;

/*月还*/
if loan_month_return_new >贷款月还 then 贷款月还 = loan_month_return_new;
if card_used_amt_sum_new>信用卡月还 then 信用卡月还 = card_used_amt_sum_new;
if 旧月负债率>负债率   then 负债率=旧月负债率/100;
if 社保基数 >公积金基数  then 基数=社保基数;
else 基数=公积金基数;


/*负债率 RATIO*/
/*format debt_ratio_g $20.;*/
/*if RATIO=. THEN RATIO=debt_ratio/100;*/
/*if RATIO=0 then debt_ratio_g="DSR=0";*/
/*else if RATIO<0.1 then debt_ratio_g="DSR 0-<10%";*/
/*else if RATIO<0.3 then debt_ratio_g="DSR 10-<30%";*/
/*else if RATIO<0.5 then debt_ratio_g="DSR 30-<50%";*/
/*else if RATIO<0.6 then debt_ratio_g="DSR 50-<60%";*/
/*else if RATIO<0.7 then debt_ratio_g="DSR 60-<70%";*/
/*else if RATIO<0.8 then debt_ratio_g="DSR 70-<80%";*/
/*else if RATIO<0.9 then debt_ratio_g="DSR 80-<90%";*/
/*else if RATIO<1 then debt_ratio_g="DSR 90-<100%";*/
/*else if RATIO<2 then debt_ratio_g="DSR 100-<200%";*/
/*else if RATIO<3 then debt_ratio_g="DSR 200-<300%";*/
/*else if RATIO<4 then debt_ratio_g="DSR 300-<400%";*/
/*else if RATIO<5 then debt_ratio_g="DSR 400-<500%";*/
/*else if RATIO>=5 then debt_ratio_g="DSR >=500%";*/


/*总保额 INSURANCE_INSURED_PRICE*/
/*format insurance_insured_price_g $20.;*/
/*if INSURANCE_INSURED_PRICE=0 or INSURANCE_INSURED_PRICE=. then insurance_insured_price_g=0;*/
/*else if INSURANCE_INSURED_PRICE<=50000 then insurance_insured_price_g="1.总保额1-5万";*/
/*else if INSURANCE_INSURED_PRICE<=100000 then insurance_insured_price_g="2.总保额6-10万";*/
/*else if INSURANCE_INSURED_PRICE<=500000 then insurance_insured_price_g="3.总保额11-50万";*/
/*else if INSURANCE_INSURED_PRICE<=1000000 then insurance_insured_price_g="4.总保额51-100万";*/
/*else if INSURANCE_INSURED_PRICE<=2000000 then insurance_insured_price_g="5.总保额101-200万";*/
/*else if INSURANCE_INSURED_PRICE<=5000000 then insurance_insured_price_g="6.总保额201-500万";*/
/*else if INSURANCE_INSURED_PRICE>5000000 then insurance_insured_price_g="7.总保额>500万";*/
/*收入 VERIFY_INCOME*/

rename  简版汇总负债总计=all  基数=basenumber APPLY_CODE=apply_code 
		贷记卡近5年逾期90以上次数 = CARD_60_PASTDUE_M3_FREQUENCY
		贷记卡近5年逾期次数 = CARD_60_PASTDUE_FREQUENCY
		抵押贷款近5年逾期90天以上次数 = LOAN_MORTGAGE_M3_FREQUENCY
		抵押贷款近5年逾期次数 = LOAN_MORTGAGE_60_FREQUENCY
		公积金基数=FUND_MONTH
		近1个月本人查询次数=SELF_QUERY_01_MONTH_FREQUENCY
		近1个月贷款查询次数=LOAN__QUERY_01_MONTH_FREQUENCY
		近1个月信用卡查询次数=CARD_APPLY_01_MONTH_FREQUENCY
		近2年贷款查询次数=LOAN__QUERY_24_MONTH_FREQUENCY
		近2年个人查询次数=SELF_QUERY_24_MONTH_FREQUENCY
		近2年信用卡查询次数=CARD_APPLY_24_MONTH_FREQUENCY
		近3个月本人查询次数=SELF_QUERY_03_MONTH_FREQUENCY
		近3个月贷款查询次数=LOAN__QUERY_03_MONTH_FREQUENCY
		近3个月信用卡查询次数=CARD_APPLY_03_MONTH_FREQUENCY
		其他性质贷款近5年逾期90天以上=LOAN_OTHER__M3_FREQUENCY
		其他性质贷款近5年逾期次数=LOAN_OTHER_60_FREQUENCY
		社保基数	=SOCIAL_SECURITY_MONTH
		无抵押贷款近5年逾期90天以上次数=LOAN_NAMORTGAGE_M3_FREQUENCY
		无抵押贷款近5年逾期次数=LOAN_60_PASTDUE_FREQUENCY;
/*       逾期=od;*/

drop 教育程度 婚姻状况 薪资发放方式 性别  age IS_HAS_HOURSE IS_LIVE_WITH_PARENTS IS_HAS_INSURANCE_POLICY IS_HAS_CAR 外地标签 
     单位性质 职级 房产性质 薪资发放方式 房产性质  进件时间 ID_CARD_NO RESIDENCE_ADDRESS PERMANENT_ADDRESS PHONE1 居住省 
     居住市 居住区 户籍省 户籍市 教育程度 单位名称  职位 COMP_ADDRESS  CURRENT_INDUSTRY 工作省 工作市 住房性质 WORK_YEARS
     工作区 INDUSTRY_NAME cc_name oc_name WORK_CHANGE_TIMES 户口性质  负债率 贷款月还 信用卡月还 HOURSE_COUNT 
     CAR_COUNT CHILD_COUNT 	准贷记卡月还  信用卡使用率 DESIRED_LOAN_LIFE  
     外部负债率 MONTHLY_EXPENSE MONTHLY_SALARY MONTHLY_OTHER_INCOME 
      ;
	 
/*     YEARLY_INCOME DESIRED_LOAN_AMOUNT 信用卡总额 LOCAL_RES_YEARS;*/

/*	   贷记卡近5年逾期90以上次数 贷记卡近5年逾期90以上次数 贷记卡近5年逾期次数 抵押贷款近5年逾期90天以上次数 */
/*     抵押贷款近5年逾期次数 近1个月本人查询次数 近1个月贷款查询次数 近1个月信用卡查询次数 近2年贷款查询次数 近2年个人查询次数 */
/*     近2年信用卡查询次数 近3个月本人查询次数 近3个月贷款查询次数 近3个月信用卡查询次数 其他性质贷款近5年逾期90天以上 */
/*     其他性质贷款近5年逾期次数 无抵押贷款近5年逾期90天以上次数 无抵押贷款近5年逾期次数 */

run;


data orig.customer_demo;
set centre.apply_demo;
drop NAME BRANCH_CODE BRANCH_NAME SOURCE_CHANNEL DESIRED_PRODUCT 进件 回退门店时间 回退门店 END_ACT_ID_ ACT_ID_  当前状态	 
auto_reject_time auto_reject ID FIRST_REFUSE_CODE FIRST_REFUSE_DESC SECOND_REFUSE_CODE SECOND_REFUSE_DESC THIRD_REFUSE_CODE 
THIRD_REFUSE_DESC REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 CANCEL_REMARK FACE_SIGN_REMIND check_end 
REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 批核状态 check_date 批核月份 check_week	通过	拒绝	 sales_name  
approve_产品	contract_no	sign_date 签约时间 放款月份 放款日期 created_name_first  updated_time_first 批核产品大类_终审 sales_code  
REFUSE_INFO_NAME_final REFUSE_INFO_NAME_LEVEL1_final REFUSE_INFO_NAME_LEVEL2_final created_name_final  updated_time_final  
缴费方式 CREATED_TIME 批核产品小类_终审 INSURANCE_COMPANY 财产信息 入职时间 旧银行流水 旧其他收入 旧月负债 旧月负债率 批核期限_终审
批核金额_终审 到手金额 合同金额 服务费 单证费 资金渠道 户籍区 INSURANCE_PAY_METHOD INSURANCE_EFFECTIVE_DATE INSURANCE_PAY_AMT
核实收入 核实代发工资 其他负债 信用卡透支总额 all 居住地址区域 basenumber; 

run;

proc sort data = orig.customer_demo nodupkey;by apply_code;run;


/*查看数据的列名*/
ods trace on;
proc contents data=orig.customer_demo;
ods output Variables=need_cus;
run;
ods trace off;







/*客户评分等级和评分*/

