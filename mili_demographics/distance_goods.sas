option compress = yes validvarname = any;
libname submart "D:\mili\Datamart\data";

***电商数据**收货地址;
proc sort data=submart.apply_flag nodupkey;by apply_code;run;
proc sort data=submart.ml_Demograph nodupkey;by apply_code;run;

data ds_data_jbgz;
merge submart.Bqsrule_jbgz_submart(in = a) submart.Bqsrule_jbgz_b_submart(in = b);
by apply_code;
if a;
run;
proc sort data = ds_data_jbgz; by apply_code; run;

data ds_data;
set ds_data_jbgz(keep = apply_code rule_name_normal memo id main_info_id rule_name 规则命中月份 规则命中日期);
if rule_name_normal="JBAA018_住址与收货地距离小于100M" or 
rule_name_normal="JBAA019_单位与收货地距离小于100M" or 
rule_name_normal="JBAA022_住址与收货地距离小于200M" or
rule_name_normal="JBAA023_住址与收货地距离小于300M" or 
rule_name_normal="JBAA024_住址与收货地距离小于400M" or 
rule_name_normal="JBAA026_单位与收货地距离小于200M" or
rule_name_normal="JBAA027_单位与收货地距离小于300M" or 
rule_name_normal="JBAA028_单位与收货地距离小于400M" or 
rule_name_normal="JBAA029_单位与收货地距离小于500M" or
rule_name_normal="JBAA030_单位与收货地距离大于500M" or 
rule_name_normal="JBAA031_住址与收货地距离大于500M" or 
rule_name_normal="JBAA032_住址与GPS距离小于500M" or 
rule_name_normal="JBAA033_单位与GPS距离小于500M" or 
rule_name_normal="JBAA034_单位与GPS距离小于400M" or
rule_name_normal="JBAA035_单位与GPS距离小于300M" or
rule_name_normal="JBAA036_单位与GPS距离小于200M" or
rule_name_normal="JBAA037_单位与GPS距离小于100M" or
rule_name_normal="JBAA038_住址与GPS距离小于400M" or
rule_name_normal="JBAA039_住址与GPS距离小于300M" or
rule_name_normal="JBAA040_住址与GPS距离小于200M" or
rule_name_normal="JBAA041_住址与GPS距离小于100M" or
rule_name_normal="JBAA042_住址与GPS距离大于500M" or
rule_name_normal="JBAA043_单位与GPS距离大于500M";
run;

**拆分memo;
data t;set ds_data;
max=length(compress(memo,'#','k'))+1;
run;

data b;
set t;
do idd=1 to max;
memo1=scan(memo,idd,'#');output;
end;
run;

**截取掉距离:;
data rr; 
set b;
memo2=tranwrd(memo1,'距离：','');
run;

**强制类型转换;
data ss;
set rr;
format memo3 best12.;
memo3=strip(memo2);
run;

proc sql;
create table ds_goods as select apply_code,rule_name_normal,id ,main_info_id ,rule_name,规则命中月份, 规则命中日期,memo,min(memo3) as min_memo from 
ss group by apply_code,rule_name_normal,id ,main_info_id ,rule_name,规则命中月份, 规则命中日期,memo;
quit;

**住址与收货地址之间距离;
data address_goods;
set ds_goods;
if rule_name_normal="JBAA018_住址与收货地距离小于100M" or 
rule_name_normal="JBAA022_住址与收货地距离小于200M" or
rule_name_normal="JBAA023_住址与收货地距离小于300M" or 
rule_name_normal="JBAA024_住址与收货地距离小于400M" or 
rule_name_normal="JBAA031_住址与收货地距离大于500M";
rule_name_normal = "住址与收货地距离";
drop rule_name memo;
min_memo =min_memo *0.001;
rename min_memo=住址与收货地距离;
run;

**单位与收货地址之间的距离;
data company_goods;
set ds_goods;
if rule_name_normal="JBAA019_单位与收货地距离小于100M" or 
rule_name_normal="JBAA026_单位与收货地距离小于200M" or
rule_name_normal="JBAA027_单位与收货地距离小于300M" or 
rule_name_normal="JBAA028_单位与收货地距离小于400M" or 
rule_name_normal="JBAA029_单位与收货地距离小于500M" or
rule_name_normal="JBAA030_单位与收货地距离大于500M";
rule_name_normal = "单位与收货地距离";
min_memo =min_memo *0.001;
rename min_memo=单位与收货地距离;
drop rule_name memo;
run;

**住址与GPS之间的距离;
data address_gps;
set ds_goods;
if rule_name_normal="JBAA038_住址与GPS距离小于400M" or
rule_name_normal="JBAA039_住址与GPS距离小于300M" or
rule_name_normal="JBAA040_住址与GPS距离小于200M" or
rule_name_normal="JBAA041_住址与GPS距离小于100M" or
rule_name_normal="JBAA042_住址与GPS距离大于500M" or
rule_name_normal="JBAA032_住址与GPS距离小于500M";
rule_name_normal = "住址与GPS距离";
min_memo =min_memo *0.001;
rename min_memo=住址与GPS距离;
drop rule_name memo;
run;

**单位与GPS之间的距离;
data company_gps;
set ds_goods;
if rule_name_normal="JBAA033_单位与GPS距离小于500M" or 
rule_name_normal="JBAA034_单位与GPS距离小于400M" or
rule_name_normal="JBAA035_单位与GPS距离小于300M" or
rule_name_normal="JBAA036_单位与GPS距离小于200M" or
rule_name_normal="JBAA037_单位与GPS距离小于100M" or
rule_name_normal="JBAA043_单位与GPS距离大于500M";
rule_name_normal = "单位与GPS距离";
min_memo =min_memo *0.001;
rename min_memo=单位与GPS距离;
drop rule_name memo;
run;

proc sort data=address_goods ;by apply_code;run;
proc sort data=company_goods ;by apply_code;run;
proc sort data=address_gps ;by apply_code;run;
proc sort data=company_gps ;by apply_code;run;

data distance_goods;
merge address_goods(in=a) company_goods(in=b) address_gps(in=c) company_gps(in=d);
by apply_code;
if a;
run;

proc sort data=distance_goods nodupkey ;by apply_code;run;
