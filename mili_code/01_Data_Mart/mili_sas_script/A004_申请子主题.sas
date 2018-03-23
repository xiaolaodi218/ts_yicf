*******************************
		����������
*******************************;
option compress = yes validvarname = any;

libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname dwdata "D:\mili\Datamart\rawdata\dwdata";
libname submart "D:\mili\Datamart\data";


/*��������״̬*/
data apply_status;
set dpRaw.apply_info(keep = apply_code status last_updated user_code date_created apply_date loan_amt period service_amt desired_product);
format ������ $20.;
if status = "HUMAN_REFUSE" then ������ = "�˹��ܾ�";
if status = "SYS_REFUSE" then ������ = "ϵͳ�ܾ�";
if status = "HUMAN_AGREE" then ������ = "�˹�ͨ��";
if status = "SYS_APPROVING" then ������ = "ϵͳ�����";
if status = "REVIEWING" then ������ = "�˹�����";
if status = "HUMAN_CANCEL" then ������ = "�˹�ȡ��";
if status = "SYS_AGREE" then ������ = "ϵͳͨ��";
if status = "SYS_CANCEL" then ������ = "ϵͳȡ��";

**����;
if status = "EXTERNAL_AGREE" then ������ = "����_����ͨ��";
if status = "EXTERNAL_REFUSE" then ������ = "����_�����ܾ�";
if status = "EXTERNAL_APPROVING" then ������ = "����_������";

**������ǩ;
if status in ("EXTERNAL_AGREE","EXTERNAL_REFUSE","EXTERNAL_APPROVING") then ��������2 = "�����ͻ�����";

rename apply_date = ���뿪ʼʱ�� date_created = �����ύʱ��;
run;
/*apply_info�����ظ��ļ������ݣ�ԭ��δ֪���ȱ������µģ������ȶ�last_updated��������������*/
proc sort data = apply_status nodupkey; by apply_code descending last_updated; run;
proc sort data = apply_status nodupkey; by apply_code; run;

/*��������*/
data handle_code;
set dpRaw.approval_info(keep = apply_code handle_code last_updated);
run;
/*ǰ�ڲ��Խ��Ϊͨ�����˹���˵Ķ�������˹����ˣ�����������������¼������Щ�쳣���ظ����ݣ��ȱ������µ�*/
proc sort data = handle_code nodupkey; by apply_code descending last_updated; run;
proc sort data = handle_code(drop = last_updated) nodupkey; by apply_code; run;

/*�ſ�*/
data loan_info;
set lendRaw.loan_info(keep = apply_code loan_date status);
�ſ����� = put(loan_date, yymmdd10.);
rename status = �ſ�״̬;
run;
proc sort data = loan_info nodupkey; by apply_code; run;

/*����-����-�ſ�*/
data apply_status;
merge apply_status(in = a) handle_code(in = b) loan_info(in = c);
by apply_code;
if a;
run;

proc sort data = apply_status out = apply_status_1 nodupkey; by user_code last_updated; run;
data apply_status_2;
set apply_status_1;
by user_code last_updated;
retain �ڼ������� 1;
	 if first.user_code then �ڼ������� = 1;
else �ڼ������� = �ڼ������� + 1;
if first.user_code then �״����� = 1;
if last.user_code then �������� = 1;
run;

/*�״ηſ�����*/
data first_loan_date;
set lendraw.loan_info(keep = apply_code id_card_no loan_date customer_name status);
if status = "304";
rename loan_date = first_loan_date;
drop status;
run;
proc sort data = first_loan_date nodupkey; by id_card_no first_loan_date; run;
proc sort data = first_loan_date nodupkey; by id_card_no; run;
***ƴ��user_code;
data apply_user_code;
set dpraw.apply_info(keep = apply_code user_code);
run;
proc sort data = first_loan_date nodupkey; by apply_code; run;
proc sort data = apply_user_code nodupkey; by apply_code; run;
data first_loan_date;
merge first_loan_date(in = a) apply_user_code(in = b);
by apply_code;
if a;
drop apply_code id_card_no;
run;

proc sort data = apply_status_2; by user_code; run;
proc sort data = first_loan_date nodupkey; by user_code; run;
data apply_status_3;
merge apply_status_2(in = a) first_loan_date(in = b);
by user_code;
if a;
if datepart(���뿪ʼʱ��) > first_loan_date > 0 then �������� = 1;
run;

proc sql;
create table apply_sum as
select user_code, min(�����ύʱ��) as �״������ύʱ�� format datetime20., max(�����ύʱ��) as ���������ύʱ�� format datetime20., count(*) as �������
from apply_status
group by user_code
;
quit;

/*��Դ����*/
data source_channel;
set submart.register_submart(keep = USER_CODE ��Դ����);
run;

proc sort data = apply_status_3; by user_code; run;
proc sort data = apply_sum nodupkey; by user_code; run;
proc sort data = source_channel nodupkey; by USER_CODE; run;


data submart.apply_submart;
merge apply_status_3(in = b) apply_sum(in = c) source_channel(in = d);
by user_code;
if b;
�����ύ�·� = put(datepart(�����ύʱ��), yymmn6.);
�����ύ���� = put(datepart(�����ύʱ��), yymmdd10.);
�״������ύ�·� = put(datepart(�״������ύʱ��), yymmn6.);
�״������ύ���� = put(datepart(�״������ύʱ��), yymmdd10.);
���������ύ���� = put(datepart(���������ύʱ��), yymmdd10.);
if customer_name in ("ɳ��", "������") then delete;
/*25��֮ǰ�ܾ���������ı��Ϊ��Ч����*/
if ������ in ("�˹�ͨ��", "ϵͳͨ��", "����_����ͨ��") then ����ͨ�� = 1;
if ������ in ("ϵͳ�ܾ�", "�˹��ܾ�", "����_�����ܾ�") then ����ܾ� = 1;

�ſ��·� = put(loan_date,yymmn6.);
if datepart(�����ύʱ��) > mdy(12,25,2016) or �������� = 1 or �ſ����� ^= "" then ��Ч���� = 1;

/****�ϱʶ���״̬;*/
/*format �ϱʶ���״̬ $20.;*/
/*if �ſ�״̬ =  "304" then �ϱʶ���״̬ = "�ſ�";*/
/*if �ſ�״̬ ^= "304" then �ϱʶ���״̬ = "δ�ſ�";*/

drop �����ύʱ�� last_updated ���뿪ʼʱ��  first_loan_date �״������ύʱ�� ���������ύʱ�� �״������ύ���� ���������ύ����
	 status service_amt loan_date;
run;


/*�ڼ��ηſ�*/
data loan_times;
set submart.apply_submart(keep = apply_code user_code �ſ�״̬ �ڼ������� where = (�ſ�״̬ = "304"));
run;
proc sort data = loan_times nodupkey; by user_code �ڼ�������; run;
data loan_times;
set loan_times;
by user_code �ڼ�������;
retain �ڼ��ηſ� 1;
	 if first.user_code then �ڼ��ηſ� = 1;
else �ڼ��ηſ� = �ڼ��ηſ� + 1;
keep apply_code �ڼ��ηſ�;
run;

proc sort data = submart.apply_submart out = apply_submart nodupkey; by apply_code; run;
proc sort data = loan_times nodupkey; by apply_code; run;

data submart.apply_submart;
merge apply_submart(in = a) loan_times(in = b);
by apply_code;
if a;
format �������� $20.;
if �״����� = 1 then �������� = "�¿ͻ�����";
else if �������� = 1 then �������� = "�����ͻ�����";
else if desired_product = "MPD10"  then �������� = "���ٴ�����";
else �������� = "�ܾ��ͻ�����";
run;




/*/****���������ſ���;*/*/
/*data apply_status;*/
/*set submart.apply_submart(keep = user_code ������ �ſ�״̬ �ڼ������� �����ύ���� �ڼ��ηſ� �ſ�����);*/
/*run;*/
/*/*ƴ���ϱ�������Ϣ*/*/
/*proc sql;*/
/*create table analysis_data as */
/*select a.*,*/
/*           b.������ as �ϱʶ���������,*/
/*		   b.�ſ�״̬ as �ϱ�����ſ�״̬,*/
/*		   b.�����ύ���� as �ϱ������ύ����*/
/*from analysisi_data as a*/
/*left join apply_status as b*/
/*on a.user_code  = b.user_code and a.�ڼ������� = b.�ڼ������� + 1*/
/*;*/
/*quit;*/;

/*ƴ���ϱʷſ���Ϣ;*/
/*proc sql;*/
/*create table analysis_data as*/
/*select a.*,*/
/*          b.�ڼ������� as �ϱʷſ������������,*/
/*		  b.�ſ����� as �ϱʷſ�����*/
/*from analysis_data as a*/
/*left join apply_status as b*/
/*on a.user_code = b.user_code and a.�ڼ��ηſ� = b.�ڼ��ηſ�+1*/
/*;*/
/*quit;*/



/*data apply_submart1234;*/
/*merge apply_submart(in = a) loan_times(in = b);*/
/*by apply_code;*/
/*if a;*/
/*format �������� $20. ��������1 $20.;*/
/*if desired_product = "MPD10"  then ��������1 = "���ٴ�����";*/
/**/
/*if �״����� = 1 then �������� = "�¿ͻ�����";*/
/*else if �ڼ�������>1 or �ϱʶ���״̬ = "�ſ�" then �������� = "���������ͻ�����";*/
/*else if �ڼ�������>1 or �ϱʶ���״̬ = "δ�ſ�" then �������� = "�ܾ��󸴴��ͻ�����";*/
/*else �������� = "�ܾ��ͻ�����";*/
/*run;*/
/**/
/*run;proc freq data=apply_submart1234 noprint;*/
/*table ��������/out=cac1234;*/
/*run;*/
/**/
/*proc freq data=submart.apply_submart noprint;*/
/*table ������/out=cac;*/

