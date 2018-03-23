*********************************
**利用经纬度计算距离
*********************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";

*************************************************************************************************************************；
**计算已有的经纬度之间的距离数据;

**GPS地址;
data dis_GPS;
set dpRaw.apply_info(keep = apply_code user_code gps_address longitude latitude );
rename latitude=GPS_latitude longitude=GPS_longitude;
run;

**住址和公司住址 ;
data address_job;
set lendRaw.user_base_info(keep=user_code residence_address residence_latitude residence_longitude job_company_address job_company_latitude job_company_longitude);
run;

proc sort data = dis_GPS; by user_code; run;
proc sort data = address_job ; by user_code; run;
data distance;
merge address_job(in = a) dis_GPS(in = b);
by user_code;
if a;
run;

**中国经纬度的大致范围;
/*data distance;*/
/*set ss;*/
/*if 0<= residence_latitude <50 and 75<residence_longitude<140 or*/
/*0<= job_company_latitude <50 and 75<job_company_longitude< 140 or*/
/*0<= GPS_latitude <50 and 75 < GPS_longitude< 140;*/
/*if GPS_latitude <90;*/
/*run;*/

proc sort data = distance nodupkey; by apply_code; run;

**单位地址和居住地址距离;
data job_address;
set distance;
lon1 = job_company_longitude *constant('pi')/180;
lat1 = job_company_latitude *constant('pi')/180;
lon2 = residence_longitude *constant('pi')/180;
lat2 = residence_latitude *constant('pi')/180;
 
dlon = lon2 - lon1;   
dlat = lat2 - lat1;   
a = sin(dlat/2)*sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2)*sin(dlon/2);
c = 2 * arsin(sqrt(a)); 
ja_distance = c * 6371;

label ja_distance=单位地址和住址距离(km);
keep apply_code residence_address job_company_address ja_distance;
run;

**住址与GPS距离;
data address_GPS;
set distance;
lon1 = GPS_longitude*constant('pi')/180;
lat1 = GPS_latitude*constant('pi')/180;
lon2 = residence_longitude*constant('pi')/180;
lat2 = residence_latitude*constant('pi')/180;
 
dlon = lon2 - lon1;   
dlat = lat2 - lat1;   
a = sin(dlat/2)*sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2)*sin(dlon/2);
c = 2 * arsin(sqrt(a)); 
ag_distance = c * 6371;

label ag_distance=住址与GPS距离(km);
keep apply_code residence_address gps_address ag_distance;
run;

**单位与GPS距离;
data job_GPS;
set distance;

lon1 = job_company_longitude*constant('pi')/180;
lat1 = job_company_latitude*constant('pi')/180;
lon2 = GPS_longitude*constant('pi')/180;
lat2 = GPS_latitude*constant('pi')/180;
 
dlon = lon2 - lon1;   
dlat = lat2 - lat1;   
a = sin(dlat/2)*sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2)*sin(dlon/2);
c = 2 * arsin(sqrt(a)); 
jg_distance = c * 6371;

label jg_distance=单位与GPS距离(km);
keep apply_code job_company_address gps_address jg_distance ;
run;

proc sort data = job_address nodupkey; by apply_code; run;
proc sort data = address_GPS nodupkey; by apply_code; run;
proc sort data = job_GPS nodupkey; by apply_code; run;

**中国南北和东西最大距离不超过6000km，超过6000km的值都要去掉;
data dis_tance;
merge job_address(in=a) address_GPS(in=b) job_GPS(in=c);
by apply_code;
if a;
if jg_distance>6000 then jg_distance = .; 
if ag_distance>6000 then ag_distance = .; 
if ja_distance>6000 then ja_distance = .;
run;

**********************************************************************************************************;
**解析基本规则里面收货地址数据;

***电商数据**收货地址;
proc sort data=submart.apply_flag nodupkey;by apply_code;run;

data ds_data_jbgz;
set submart.Bqsrule_jbgz_submart submart.Bqsrule_jbgz_b_submart;
run;
proc sort data = ds_data_jbgz; by apply_code; run;

data ds_data;
set ds_data_jbgz(keep = apply_code rule_name_normal memo id main_info_id rule_name 规则命中月份 规则命中日期);
if rule_name_normal="JBAA018_住址与收货地距离小于100M" or 
rule_name_normal="JBAA019_单位与收货地距离小于100M" or 
rule_name_normal="JBAA022_住址与收货地距离小于200M" or
rule_name_normal="JBAA023_住址与收货地距离小于300M" or 
rule_name_normal="JBAA024_住址与收货地距离小于400M" or 
rule_name_normal="JBAA025_住址与收货地距离小于500M" or
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
rule_name_normal="JBAA025_住址与收货地距离小于500M" or
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


proc sort data = dis_tance nodupkey; by apply_code; run;

**拼接两部分数据，并将后者的部分数据填充到前者里面;
data submart.every_distance;
merge dis_tance(in=a) distance_goods(in=b);
by apply_code;
if a;
if ag_distance="." then ag_distance=住址与GPS距离;
if jg_distance="." then jg_distance=单位与GPS距离;
drop rule_name_normal id main_info_id 规则命中月份 规则命中日期 住址与GPS距离 单位与GPS距离;
run;

proc sort data = submart.every_distance nodupkey; by apply_code; run;


filename export "F:\米粒Demographics\csv\distance.csv" encoding='utf-8';
PROC EXPORT DATA= submart.every_distance
			 outfile = export
			 dbms = csv replace;
RUN;
