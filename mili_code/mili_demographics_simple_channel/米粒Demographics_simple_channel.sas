option compress = yes validvarname = any;
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";
libname bjb "F:\����Demographics\data";
libname benzi "F:\����demographics_simple_channel\data";
libname repayFin "F:\���������ձ���\data";

proc import datafile="F:\����Demographics���\����demo���ñ�_simple.xls"
out=var_name dbms=excel replace;
sheet="ά�ȱ���";
getnames=yes;
run;
proc import datafile="F:\����Demographics���\����demo���ñ�_simple.xls"
out=var_name_left dbms=excel replace;
sheet="ճ��ģ��";
getnames=yes;
run;

data _null_;
format dt yymmdd10.;
if year(today()) = 2004 then dt = intnx("year", today() - 3, 13, "same"); else dt = today() - 3;
call symput("dt", dt);
nt=intnx("day",dt,1);
call symput("nt", nt);
run;

data bjb.ml_Demograph_simple;
set bjb.ml_Demograph(keep=
apply_code
������
����ܾ�
�����ύ��
�����ύ��_g
�����ύ��
�����ύ����
�����ύ�·�
����ͨ��
��˴�����
��˴�������
��˴����·�
��������
refuse_name
SEX_NAME
SEX_NAME_group
DEGREE_NAME
DEGREE_NAME_g
JOB_COMPANY_CITY_NAME
JOB_COMPANY_PROVINCE_NAME
JOB_g
MARRIAGE_NAME_g
MONTH_SALARY_NAME
RESIDENCE_CITY_NAME
RESIDENCE_PROVINCE_NAME
app_total_cnt
app_type_cnt
check_final
company_g
company_province_g
input_complete
loc_1mcnt_silent
loc_1mmaxcnt_silent
loc_3mcnt_silent
loc_3mmaxcnt_silent
loc_appsl
loc_appsl_g
loc_ava_exp
loc_register_date
loc_tel_fm_rank
loc_tel_po_rank
loc_tel_py_rank
loc_tel_qs_rank
loc_tqscore
loc_txlsl
loc_txlsl_g
loc_zmscore
salary_g
��ĸ����
��ż����
��������
����ʱ��
����ʱ��
�����·�
����ʱ��
�¾����ѽ��
app��������
app��������
�¾����ѽ������
grp_cx_score
����������
֥�������
����������
�����Ĭ����
������Ĭ����
��һ�Ĭ����
��һ��Ĭ����
�״����� 
�������� 
loc_abmoduleflag
��Դ����
������ǩ
);
run;

