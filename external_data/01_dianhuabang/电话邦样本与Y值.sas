option compress = yes validvarname = any;
libname repayFin "D:\mili\offline\centre_data\repayAnalysis";

data payment;
set repayFin.payment;
run;

%let month = '201802';

data target;
set payment(where = (month = &month. and mob > 5)
			keep = apply_code BORROWER_TEL_ONE 资金渠道 产品小类  营业部 产品大类 od_days od_days_ever 
                   month mob 放款月份 es_date es settled LOAN_DATE cut_date);
if LOAN_DATE >= '01JUL2017'd;	***取2017年7月份开始的放款***;
if 产品大类 = "续贷" then delete;	***剔除续贷产品***;	
/*if cut_date - loan_date - od_days_ever <= 90 then delete;	  ***剔除用天数来推出的前3期就开始逾期且不还的合同，可能是欺诈***;*/
/*if 营业部 in ("怀化市第一营业部","赤峰市第一营业部","呼和浩特市第一营业部") then delete;    ***剔除怀化，赤峰，呼和浩特营业部数据;*/
if es = 1 then perf_period = intck("month",loan_date,es_date); else perf_period = mob;	***还款表现期，跟真实的还款期数有一定区别***;

if not kindex(产品小类 ,"米粒");

************************************
Bad   —— 曾经逾期30天以上
Good  —— 还款表现期大于5（提前结清的是大于5，正常在还的是大于7）且 当前未逾期 且 曾经逾期天数小于8（门店端催回）
Indet —— 其他
************************************;
format target_label $10.;
	 if od_days_ever > 30 then do; target = 1; target_label = "Bad"; end;
else if perf_period > 5 & od_days = 0 & od_days_ever < 8 then do; target = 0; target_label = "Good"; end;
else do; target = 2; target_label = "Indet"; end;
sample = 1;
run;

data tt;
set target;
if target = 0 then Good=1;
if target = 1 then Bad=1;
if target = 2 then Indet=1;
run;

proc sql;
create table gbi as
select 放款月份,sum(Bad) as 坏客户, sum(Good) as 好客户, sum(Indet) as 中间客户  from tt group by 放款月份;
run;

data target_g;
set target(keep = apply_code BORROWER_TEL_ONE target);
rename target = y;
format tel_phone $11.;
tel_phone = "***"||substr(BORROWER_TEL_ONE, 3, 8);
drop BORROWER_TEL_ONE;
run;

filename export "F:\TS\external_data_test\电话邦\通善_测试结果\data\target_g.csv" encoding='utf-8';
proc export data = target_g
			 outfile = export
			 dbms = csv replace;
run;
