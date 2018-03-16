*****************************************
	�������������
*****************************************;
option compress = yes validvarname = any;
/**/
libname lendRaw "D:\mili\Datamart\rawdata\applend";
libname dpRaw "D:\mili\Datamart\rawdata\appdp";
libname submart "D:\mili\Datamart\data";
/*ע��ʱ��*/
data reg_time;
set lendRaw.user(keep = user_code PHONE_NO CREATED_TIME);
rename CREATED_TIME = �û�ע��ʱ��;
run;
/*�����ύʱ�䡢gps��ַ*/
data apply_time;
set dpRaw.apply_info(keep = apply_code date_created gps_address);
	 if index(gps_address, "�½�ά���������") then GPSʡ�� = "�½�ά���������";
else if index(gps_address, "����׳��������") then GPSʡ�� = "����׳��������";
else if index(gps_address, "���ɹ�������") then GPSʡ�� = "���ɹ�������"; 
else if index(gps_address, "����������") then GPSʡ�� = "����������"; 
else if index(gps_address, "���Ļ���������") then GPSʡ�� = "���Ļ���������"; 
else if index(gps_address, "�����ر�������") then GPSʡ�� = "�����ر�������"; 
else GPSʡ�� = ksubstr(gps_address, 1, 3);
rename date_created = �����ύʱ��;
run;
/*������Ϣ*/
data baseinfo;
set submart.baseinfo_submart;
drop USER_NAME SEX DEGREE PERMANENT_ADDRESS MARRIAGE RESIDENCE_CONDITION RESIDENCE_PROVINCE RESIDENCE_CITY RESIDENCE_REGION RESIDENCE_ADDRESS 
	JOB_COMPANY_NAME JOB_COMPANY_PROVINCE JOB_COMPANY_CITY JOB_COMPANY_REGION JOB_COMPANY_ADDRESS JOB_COMPANY_CONDITION JOB_COMPANY_PHONE 
	MONTH_SALARY CURR_JOB_SENIORITY;
run;
/*��ŷ�*/;
data creditx_score;
set dpraw.creditx_score(keep = apply_code score);
format grp_cx_score $20.;
	 if score < 550 then grp_cx_score = "0. (0, 550)";
else if score < 600 then grp_cx_score = "1. [550, 600)";
else if score < 620 then grp_cx_score = "2. [600, 620)";
else if score < 650 then grp_cx_score = "3. [620, 650)";
else if score < 700 then grp_cx_score = "4. [650, 700)";
else grp_cx_score = "5. [700, 850)";
rename score = cx_score;
run;
/*�����������*/
data apply;
set submart.apply_submart;
keep apply_code user_code loan_amt period �״����� �������� �������� �����ύ�·� �����ύ���� ��Ч���� ������ ��������;
run;

proc sort data = apply nodupkey; by apply_code; run;
proc sort data = apply_time nodupkey; by apply_code; run;
proc sort data = creditx_score nodupkey; by apply_code; run;
data apply_info;
merge apply(in = a) apply_time(in = b) creditx_score(in = c);
by apply_code;
if a;
run;

proc sort data = apply_info; by user_code; run;
proc sort data = reg_time nodupkey; by user_code; run;
proc sort data = baseinfo nodupkey; by user_code; run;
data apply_var;
merge apply_info(in = a) reg_time(in = b) baseinfo(in = c);
by user_code;
if a;
�����ע���� = intck("minute", �û�ע��ʱ��, �����ύʱ��);
�����ύʱ�� = hour(�����ύʱ��);
if substr(id_card, 7, 2) = "19" then ���� =  year(datepart(�����ύʱ��)) - substr(ID_CARD, 7, 4)*1;
drop �����ύʱ�� �û�ע��ʱ��;
run;

/*�������������������*/;
data jxl_var_1;
set dpRaw.ex_jxl_user_info_check(keep = token contacts_class1blacklist_cnt contacts_class2blacklist_cnt contacts_router_ratio phone_gray_score
										register_org_cnt searched_org_cnt);
run;
data jxl_basic;
set dpRaw.ex_jxl_basic(keep = token cell_phone);
rename cell_phone = phone_no;
run;
proc sort data = jxl_var_1 nodupkey; by token; run;
proc sort data = jxl_basic nodupkey; by token; run;
data jxl_var;
merge jxl_var_1(in = a) jxl_basic(in = b);
by token;
if a;
run;

/*�ύ������û��������*/
proc sort data = apply_var; by phone_no; run;
proc sort data = jxl_var nodupkey; by phone_no; run;
data submart.applyVar_submart;
merge apply_var(in = a) jxl_var(in = e drop = token);
by phone_no;
if a;
format grp_���� grp_�����ע�� grp_������������ѯ�� $20.;
	 if 0 < ���� < 20 then grp_���� = "0. < 20";
else if 20 <= ���� <= 25 then grp_���� = "1. 20 - 25";
else if 26 <= ���� <= 30 then grp_���� = "2. 26 - 30";
else if 31 <= ���� <= 35 then grp_���� = "3. 31 - 35";
else if ���� > 35 then grp_���� = "4. > 35";
	 if 0 < �����ע���� < 5 then grp_�����ע�� = "0. < 5����";
else if 5 <= �����ע���� < 15 then grp_�����ע�� = "1. 5 - <15����";
else if 15 <= �����ע���� < 30 then grp_�����ע�� = "2. 15 - <30����";
else if 30 <= �����ע���� < 60 then grp_�����ע�� = "3. 30 - <60����";
else if 60 <= �����ע���� < 1440 then grp_�����ע�� = "4. 1����";
else if 1440 <= �����ע���� < 2880 then grp_�����ע�� = "5. 2����";
else if 1440 <= �����ע���� < 10080 then grp_�����ע�� = "6. 1����";
else if �����ע���� >= 10080 then grp_�����ע�� = "7. 1�ܺ�";
	 if 0 < searched_org_cnt <= 5 then grp_������������ѯ�� = "0. <= 5";
else if 5 < searched_org_cnt <= 10 then grp_������������ѯ�� = "1. 6 - 10";
else if 10 < searched_org_cnt <= 15 then grp_������������ѯ�� = "2. 11 - 15";
else if 15 < searched_org_cnt <= 20 then grp_������������ѯ�� = "3. 16 - 20";
else if searched_org_cnt > 20 then grp_������������ѯ�� = "4. > 20";

drop PHONE_NO ID_CARD;
run;

proc sort data = submart.applyVar_submart; by apply_code; run;
