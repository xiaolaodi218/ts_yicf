*******************************
		���������
*******************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname lendRaw "D:\mili\Datamart\rawdata\applend";*/
/*libname dpRaw "D:\mili\Datamart\rawdata\appdp";*/
/*libname dwdata "D:\mili\Datamart\rawdata\dwdata";*/
/*libname submart "D:\mili\Datamart\data";*/

data approval_info;
set dpRaw.approval_info;
��˴������� = put(datepart(handle_time), yymmdd10.);
��˴����·� = put(datepart(handle_time), yymmn6.);
��˿�ʼ���� = put(datepart(date_created), yymmdd10.);
��˿�ʼ�·� = put(datepart(date_created), yymmn6.);
rename date_created = ��˿�ʼʱ�� last_updated = ��˸���ʱ�� handle_time = ��˴���ʱ�� ;
drop id;
run;
/*ϵͳ�ܾ�*/
data sys_refuse;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "SYSTEM" and handle_result = "REJECT";
run;
proc sort data = sys_refuse nodupkey; by apply_code; run;
/*ϵͳͨ��*/
data sys_agree;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "SYSTEM" and handle_result = "ACCEPT";
run;
proc sort data = sys_agree nodupkey; by apply_code; run;
/*�˹�ͨ��*/
data human_agree;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "HUMAN" and handle_result = "ACCEPT";
run;
proc sort data = human_agree nodupkey; by apply_code; run;
/*�˹��ܾ�*/
data human_refuse;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "HUMAN" and handle_result = "REJECT";
run;
proc sort data =human_refuse nodupkey; by apply_code; run;
/*ϵͳ�����*/
data sys_init;
set approval_info;
if handle_status = "INIT" and handle_type = "SYSTEM";
run;
proc sort data = sys_init nodupkey; by apply_code; run;
/*�˹������*/
data human_init;
set approval_info;
if handle_status = "INIT" and handle_type = "HUMAN";
run;
proc sort data = human_init nodupkey; by apply_code; run;
/*�˹�ȡ��*/
data human_cancel;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "HUMAN" and handle_result = "CANCEL";
run;
proc sort data =human_cancel nodupkey; by apply_code; run;
/*ϵͳȡ��*/
data sys_cancel;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "SYSTEM" and handle_result = "CANCEL";
run;
proc sort data =sys_cancel nodupkey; by apply_code; run;

/*�����ܾ�*/
data zw_refuse;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "EXTERNAL" and handle_result = "REJECT";
run;
proc sort data =zw_refuse nodupkey; by apply_code; run;
/*����ͨ��*/
data zw_agree;
set approval_info;
if handle_status = "COMPLETE" and handle_type = "EXTERNAL" and handle_result = "ACCEPT";
run;
proc sort data =zw_agree nodupkey; by apply_code; run;
/*���������*/
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
proc sort data = approval nodupkey; by apply_code descending ��˸���ʱ��; run; /*��һЩ�쳣�ĵ�����PL148202792530602600007429��ͬʱ��ϵͳ���˹��ܾ��Ľ��*/
proc sort data = approval nodupkey; by apply_code; run;
data submart.approval_submart;
set approval;
length ������� $10;
	 if handle_type = "SYSTEM" and handle_result = "REJECT" then ������� = "ϵͳ�ܾ�";
else if handle_type = "SYSTEM" and handle_result = "ACCEPT" then ������� = "ϵͳͨ��";
else if handle_type = "SYSTEM" and handle_result = "CANCEL" then ������� = "ϵͳȡ��";
else if handle_type = "HUMAN" and handle_result = "REJECT" and handle_code = "" then ������� = "�˹�ͨ��"; /*������ɸѡ�����˹�ͨ���Ķ���*/
else if handle_type = "HUMAN" and handle_result = "REJECT" then ������� = "�˹��ܾ�"; 
else if handle_type = "HUMAN" and handle_result = "ACCEPT" then ������� = "�˹�ͨ��"; 
else if handle_type = "HUMAN" and handle_result = "CANCEL" then ������� = "�˹�ȡ��"; 
else if handle_type = "SYSTEM" then ������� = "ϵͳ�����";
else if handle_type = "HUMAN" then ������� = "�˹�������";

/*else if handle_type = "EXTERNAL" and handle_result = "REJECT" then ������� = "�����ܾ�";*/
/*else if handle_type = "EXTERNAL" and handle_result = "ACCEPT" then ������� = "����ͨ��";*/
/*else if handle_type = "EXTERNAL" then ������� = "���������";*/

else if handle_type = "EXTERNAL" and handle_result = "REJECT" then ������� = "ϵͳ�ܾ�";
else if handle_type = "EXTERNAL" and handle_result = "ACCEPT" then ������� = "ϵͳ�ܾ�";
else if handle_type = "EXTERNAL" then ������� = "ϵͳ�ܾ�";

drop ��˿�ʼʱ�� ��˸���ʱ�� ��˴���ʱ��;
run;


***�޸�������ɸ�����ͻ����������;
/*������ɸ�������˹�ͨ���Ŀͻ�*/
/*data silver_pass_user;*/
/*set lendraw.circular(keep = name user_code CREATED_TIME where = (name = "������Ǯ"));*/
/*run;*/
/*������ɸ�������˹�ͨ���Ķ���*/
/*data silver_pass_apply;*/
/*set dpraw.approval_info(where = (handle_type = "HUMAN" and handle_result = "REJECT" and handle_code = ""));*/
/*keep apply_code;*/
/*run;*/
