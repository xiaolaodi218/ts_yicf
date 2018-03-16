*************************************************************************************************************************
***TTD;

data bjb.ml_Demograph1_all  ;
set bjb.ml_Demograph;
/*if ��������^=1;*/
/*if ��������=1;*/
if �����ύ��<=&dt.;
run;
**�õ��������¿ͻ������ݼ�;
data  bjb.ml_Demograph1_xz bjb.ml_Demograph1_fd  ;
set bjb.ml_Demograph;
if ��������^=1 then output bjb.ml_Demograph1_xz;
else if ��������=1 then output bjb.ml_Demograph1_fd;
if �����ύ��<=&dt.;
run;
*�õ��ھ������ݼ�;
data  bjb.ml_Demograph1_A; 
set bjb.ml_Demograph;
if loc_abmoduleflag = "A";
if �����ύ��<=&dt.;
run;
*�õ���ս�ߵ����ݼ�;
data bjb.ml_Demograph1_B;
set bjb.ml_Demograph;
if loc_abmoduleflag = "B";
if �����ύ��<=&dt.;
run;


%macro demo_0(use_database,class_g,i);
%do n=1 %to &i.;

data var;
set var_name;
where id=&n.;
format var_name $45.;
call symput("var_name ",var_name);
run;
%put &var_name.;

data use0;
set &use_database.;
format &var_name. $45.;
if strip(&var_name.)="" then &var_name.="z-Missing";
run;

proc tabulate data=use0 out=demo_res_&n.(drop=_TYPE_ _PAGE_ _TABLE_ );
class &class_g. &var_name. /missing;
var input_complete;
table &var_name.
all,&class_g.*input_complete*(N);
run;
proc sort data=demo_res_&n.;by &var_name. &class_g.;run;
proc transpose data=demo_res_&n. out=demo_&n. prefix=a_;
/*where &var_name.  ne "";*/
by &var_name. ;
id &class_g.;
var input_complete_N;
run;

data demo_&n.;
set demo_&n.;
format Group $45.;
format variable $45.;
variable="&var_name.";
if &var_name.="" then group="С��";
else group=&var_name.;
drop _NAME_ &var_name.;
run;

%if &n=1 %then %do;
	data demo_res;
	set demo_&n.;
	run;
	%end;
%else %do;
	data demo_res;
	set demo_res demo_&n.;
	format variable $45.;
	run;
%end;
%end;
%mend;

x "F:\����Demographics\Monthly_Demographics(����_total).xlsx";

**����demo_res_ttd_all_auto;
%demo_0(use_database=bjb.ml_Demograph1_all,class_g=�����ύ�·�,i=122);
data demo_res_ttd_all;set demo_res;run;
proc sql;
create table demo_res_ttd_all_auto as
select a.*,b.a_201707 from var_name_left as a
left join demo_res_ttd_all as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_all_auto ;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_total).xlsx]TTD!r5c21:r1000c21';
data _null_;
set Work.demo_res_ttd_all_auto;
file DD;
put a_201707;
run;

x "F:\����Demographics\Monthly_Demographics(����_�¿ͻ�).xlsx";

**demo_res_ttd_xz_auto;
%demo_0(use_database=bjb.ml_Demograph1_xz,class_g=�����ύ�·�,i=122);
data demo_res_ttd_xz;set demo_res;run;
proc sql;
create table demo_res_ttd_xz_auto as
select a.*,b.a_201707 from var_name_left as a
left join demo_res_ttd_xz as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_xz_auto ;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_�¿ͻ�).xlsx]TTD!r5c21:r1000c21';
data _null_;
set Work.demo_res_ttd_xz_auto;
file DD;
put a_201707;
run;

x "F:\����Demographics\Monthly_Demographics(����_����).xlsx";

**demo_res_ttd_fd_auto;
%demo_0(use_database=bjb.ml_Demograph1_fd,class_g=�����ύ�·�,i=122);
data demo_res_ttd_fd;set demo_res;run;
proc sql;
create table demo_res_ttd_fd_auto as
select a.*,b.a_201707 from var_name_left as a
left join demo_res_ttd_fd as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_fd_auto ;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_����).xlsx]TTD!r5c21:r1000c21';
data _null_;
set Work.demo_res_ttd_fd_auto;
file DD;
put a_201707;
run;


x "F:\����Demographics\Monthly_Demographics(����_�ھ�).xlsx";

**demo_res_ttd_A_auto;
%demo_0(use_database=bjb.ml_Demograph1_A,class_g=�����ύ�·�,i=122);
data demo_res_ttd_A;set demo_res;run;
proc sql;
create table demo_res_ttd_A_auto as
select a.*,b.a_201707 from var_name_left as a
left join demo_res_ttd_A as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_A_auto ;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_�ھ�).xlsx]TTD!r5c5:r1000c5';
data _null_;
set Work.demo_res_ttd_A_auto;
file DD;
put a_201707;
run;


x "F:\����Demographics\Monthly_Demographics(����_��ս��).xlsx";

**demo_res_ttd_B_auto;
%demo_0(use_database=bjb.ml_Demograph1_B,class_g=�����ύ�·�,i=122);
data demo_res_ttd_B;set demo_res;run;
proc sql;
create table demo_res_ttd_B_auto as
select a.*,b.a_201707 from var_name_left as a
left join demo_res_ttd_B as b on a.group=b.group and a.variable=b.variable;
quit;
proc sort data=demo_res_ttd_B_auto ;by id;run;

filename DD DDE 'EXCEL|[Monthly_Demographics(����_��ս��).xlsx]TTD!r5c5:r1000c5';
data _null_;
set Work.demo_res_ttd_B_auto;
file DD;
put a_201707;
run;
