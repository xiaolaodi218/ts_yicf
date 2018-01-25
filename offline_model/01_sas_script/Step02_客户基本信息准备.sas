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


/*------------------------------�����ַ����õ��ͻ�������Ϣ������------------------------------*/

data orig.apply_demo_method3;
set customer_info(keep = 
apply_code  ����ʱ�� approve_��Ʒ BRANCH_NAME
DESIRED_LOAN_LIFE  DESIRED_LOAN_AMOUNT  CHILD_COUNT age �����̶� �Ա� ����״��  
/*��סʡ ��ס�� ��ס�� ����ʡ ������ ������  ����ʡ ������ ������ ��ְʱ�� ��λ���� ְλ*/
/*YEARLY_INCOME*/
��ס��  ������   WORK_YEARS ס������  ְ�� �ⲿ��ծ��
��λ����  �����»� ���ÿ��»� �籣���� ��������� 
IS_HAS_CAR  IS_HAS_HOURSE �Ʋ���Ϣ  �����ܸ�ծ�ܼ�  
���ÿ�ʹ���� ׼���ǿ��»� ������ծ  MONTHLY_SALARY MONTHLY_OTHER_INCOME н�ʷ��ŷ�ʽ
score  group_level risk_level 
);


/*��ס���뻧����ϵ*/;
if ��ס��=������ then �Ƿ񱾵� = "����";
else  �Ƿ񱾵� = "���";

/*����ָ���ַ���λ��ȡ�ַ���,��Ӫҵ������Ϊ������*/
format �������$50.;
	 if index(BRANCH_NAME, "���ͺ����е�һӪҵ��") then ������� = "���ͺ���";
else if index(BRANCH_NAME, "��³ľ���е�һӪҵ��") then ������� = "��³ľ��";
else �������=substr(BRANCH_NAME,1, 4);

/*�����������*/;
if DESIRED_LOAN_LIFE=341  then ������������=6;
else if DESIRED_LOAN_LIFE=342 then ������������=12;
else if DESIRED_LOAN_LIFE=343 then ������������=18;
else if DESIRED_LOAN_LIFE=344 then ������������=24;
else if DESIRED_LOAN_LIFE=345 then ������������=36;
else if ������������=0;

/*�������籣����*/;
if �籣���� >���������  then �籣��������=�籣����;
else �籣��������=���������;

���Ÿ�ծ�� = �ⲿ��ծ��/100;
���ÿ�ʹ���� = ���ÿ�ʹ����/100;

���������� = (MONTHLY_SALARY + MONTHLY_OTHER_INCOME) *12;
���㸺ծ��1 = (���ÿ��»� + ׼���ǿ��»� + �����»�)/(MONTHLY_SALARY + MONTHLY_OTHER_INCOME);
���㸺ծ��2 = (���ÿ��»� + ׼���ǿ��»� + �����»�)/(�籣��������);

rename 
approve_��Ʒ = �����Ʒ      age = ����   
DESIRED_LOAN_AMOUNT = ���������  WORK_YEARS = ��������
CHILD_COUNT = ��Ů����  IS_HAS_CAR = �Ƿ��г�   IS_HAS_HOURSE = �Ƿ��з�
MONTHLY_SALARY = ������  MONTHLY_OTHER_INCOME = ����������
;

drop BRANCH_NAME DESIRED_LOAN_LIFE �籣���� ��������� ��ס��  ������ �ⲿ��ծ��;

run;

ods trace on;
proc contents data=orig.apply_demo_method3;
ods output Variables=need_cus3;
run;
ods trace off;














/*------------------------------��һ�ַ����õ��ͻ�������Ϣ������------------------------------*/

data orig.apply_demo_method2;
set customer_info;

/*/*��ס��ַ*/*/
/*format ��ס��ַ���� $50.;*/
/*if ��סʡ in ("�Ϻ���","����ʡ","�㽭ʡ","����ʡ","����ʡ","ɽ��ʡ","����ʡ") then ��ס��ַ���� ="��������" ;*/
/*else if ��סʡ in ("������","�����","ɽ��ʡ","�ӱ�ʡ","���ɹ�������") then ��ס��ַ���� ="��������" ;*/
/*else if ��סʡ in ("����ʡ","����ʡ","����ʡ") then ��ס��ַ���� ="���е���" ;*/
/*else if ��סʡ in ("�㶫ʡ","����׳��������","����ʡ") then ��ס��ַ���� ="���ϵ���" ;*/
/*else if ��סʡ in ("�Ĵ�ʡ","����ʡ","����ʡ","������","����������") then ��ס��ַ���� ="���ϵ���" ;*/
/*else if ��סʡ in ("����ʡ","����ʡ","�ຣʡ","���Ļ���������","�½�ά���������") then ��ס��ַ���� ="��������" ;*/
/*else if ��סʡ in ("������ʡ","����ʡ","����ʡ","���ɹ�������") then ��ס��ַ���� ="��������" ;*/
/*else ��ס��ַ���� = "";*/
/**/
/*format ������������ $20.;*/
/*if ������ in ("������", "�Ϻ���", "������","������") then ������������ = "һ�߳���";*/
/*else if ������������ = "�����߳���";*/
/**/
/*format ��ס�������� $20.;*/
/*if ��ס�� in ("������","�Ϻ���","������","������") then ��ס�������� = "һ�߳���";*/
/*else if ��ס�������� = "�����߳���";*/

/*�����������*/;
if DESIRED_LOAN_LIFE=341  then apply_loanamt_g=6;
else if DESIRED_LOAN_LIFE=342 then apply_loanamt_g=12;
else if DESIRED_LOAN_LIFE=343 then apply_loanamt_g=18;
else if DESIRED_LOAN_LIFE=344 then apply_loanamt_g=24;
else if DESIRED_LOAN_LIFE=345 then apply_loanamt_g=36;
else if apply_loanamt_g=0;

/*��ס���뻧����ϵ*/;
if ��ס��=������ then res_type_g=0;
else  res_type_g=1;

/*������������籣����*/
if SOCIAL_SECURITY_RADICES>=PUBLIC_FUNDS_RADICES then SOCIAL_PUBLIC_RADICES=SOCIAL_SECURITY_RADICES;
else SOCIAL_PUBLIC_RADICES=PUBLIC_FUNDS_RADICES;

/*�»�*/
if loan_month_return_new >�����»� then �����»� = loan_month_return_new;
if card_used_amt_sum_new>���ÿ��»� then ���ÿ��»� = card_used_amt_sum_new;
if ���¸�ծ��>��ծ��   then ��ծ��=���¸�ծ��/100;
if �籣���� >���������  then ����=�籣����;
else ����=���������;

/*���ÿ��ܶ��*/
rename ���ÿ��ܶ� = credit_amt_all;

/*���ÿ�ʹ����*/
credit_use_ratio = ���ÿ�ʹ����/100;

/*�ⲿ��ծ��*/
external_debt_ratio = �ⲿ��ծ��/100;

/*��ծ��*/
debt_ratio = ��ծ��/100;


rename  �����ܸ�ծ�ܼ�=debt_amt_all  ����=social_fund_basenum  
		���ǿ���5������90���ϴ��� = CARD_60_PASTDUE_M3_FREQUENCY
		���ǿ���5�����ڴ��� = CARD_60_PASTDUE_FREQUENCY
		��Ѻ�����5������90�����ϴ��� = LOAN_MORTGAGE_M3_FREQUENCY
		��Ѻ�����5�����ڴ��� = LOAN_MORTGAGE_60_FREQUENCY
		���������=FUND_MONTH
		��1���±��˲�ѯ����=SELF_QUERY_01_MONTH_FREQUENCY
		��1���´����ѯ����=LOAN__QUERY_01_MONTH_FREQUENCY
		��1�������ÿ���ѯ����=CARD_APPLY_01_MONTH_FREQUENCY
		��2������ѯ����=LOAN__QUERY_24_MONTH_FREQUENCY
		��2����˲�ѯ����=SELF_QUERY_24_MONTH_FREQUENCY
		��2�����ÿ���ѯ����=CARD_APPLY_24_MONTH_FREQUENCY
		��3���±��˲�ѯ����=SELF_QUERY_03_MONTH_FREQUENCY
		��3���´����ѯ����=LOAN__QUERY_03_MONTH_FREQUENCY
		��3�������ÿ���ѯ����=CARD_APPLY_03_MONTH_FREQUENCY
		�������ʴ����5������90������=LOAN_OTHER__M3_FREQUENCY
		�������ʴ����5�����ڴ���=LOAN_OTHER_60_FREQUENCY
		�籣����	=SOCIAL_SECURITY_MONTH
		�޵�Ѻ�����5������90�����ϴ���=LOAN_NAMORTGAGE_M3_FREQUENCY
		�޵�Ѻ�����5�����ڴ���=LOAN_60_PASTDUE_FREQUENCY;

drop NAME BRANCH_CODE BRANCH_NAME SOURCE_CHANNEL DESIRED_PRODUCT ���� �����ŵ�ʱ�� �����ŵ� END_ACT_ID_ ACT_ID_  ��ǰ״̬	 
auto_reject_time auto_reject ID FIRST_REFUSE_CODE FIRST_REFUSE_DESC SECOND_REFUSE_CODE SECOND_REFUSE_DESC THIRD_REFUSE_CODE 
THIRD_REFUSE_DESC REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 CANCEL_REMARK FACE_SIGN_REMIND check_end 
REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 ����״̬ check_date �����·� check_week	ͨ��	�ܾ�	 sales_name  
approve_��Ʒ	contract_no	sign_date ǩԼʱ�� �ſ��·� �ſ����� created_name_first  updated_time_first ���˲�Ʒ����_���� sales_code  
REFUSE_INFO_NAME_final REFUSE_INFO_NAME_LEVEL1_final REFUSE_INFO_NAME_LEVEL2_final created_name_final  updated_time_final  
�ɷѷ�ʽ CREATED_TIME ���˲�ƷС��_���� INSURANCE_COMPANY ��ְʱ�� ��������ˮ ���������� ���¸�ծ ���¸�ծ�� ��������_����
���˽��_���� ���ֽ�� ��ͬ��� ����� ��֤�� �ʽ����� ������ INSURANCE_PAY_METHOD INSURANCE_EFFECTIVE_DATE INSURANCE_PAY_AMT
��ʵ���� ��ʵ�������� ������ծ ���ÿ�͸֧�ܶ� SOCIAL_SECURITY_RADICES PUBLIC_FUNDS_RADICES ;  

run;

proc sort data = orig.apply_demo_method2 nodupkey;by apply_code;run;

ods trace on;
proc contents data=orig.apply_demo_method2;
ods output Variables=need_cus2;
run;
ods trace off;












/*------------------------------��һ�ַ����õ��ͻ�������Ϣ������------------------------------*/

data centre.apply_demo;
set customer_info;

/*�����̶ȷ���*/
if �����̶� in ("˶ʿ��������") then education_g=0;
else if �����̶� in ("��ѧ����") then education_g=1;
else if �����̶� in ("ר��") then education_g=2;
else if �����̶� in ("����","��ר") then education_g=3;
else if �����̶� in ("����","Сѧ") then education_g=4;
else education_g=5;
/*if �����̶� in ("˶ʿ��������","��ѧ����") then education_g=1;else education_g=0;*/


/*����״��*/
if ����״��="δ��" then marriage_g=0;  
else if ����״��="�ѻ�" then marriage_g=1;
else if ����״�� in ("ɥż","����") then marriage_g=2;
else  marriage_g=3;
/*if ����״�� in("����","δ��") then marriage_g=1;else marriage_g=0;*/

/*�Ա�*/
/*if �Ա�="��" then gender_g=0 ; */
/*if �Ա�="Ů" then gender_g=1 ; */
/*else if �Ա�="" then gender_g=2 ;*/
if �Ա�="��" then gender_g=0 ;else gender_g=1;

/*���� age*/
if age<18 then age_g=0;
else if age>=18 and age<=25 then age_g=1;
else if age>25 and age<=30 then age_g=2;
else if age>30 and age<=35 then age_g=3;
else if age>35 and age<=40 then age_g=4;
else if age>40 and age<=45 then age_g=5;
else if age>45 and age<=55 then age_g=6;
else if age>55 and age<=60 then age_g=7;
else age_g=8;

/*��Ů���� CHILD_COUNT*/
if CHILD_COUNT=0 or CHILD_COUNT=. then child_count_g=0;
else if CHILD_COUNT=1 then child_count_g=1;
else if CHILD_COUNT=2 then child_count_g=2;
else child_count_g=3;


/*���޷���*/
if IS_HAS_HOURSE="y" then is_has_hourse_g=1;
else if IS_HAS_HOURSE="n" then is_has_hourse_g=0;
else is_has_hourse_g=2;

/*��������*/
if IS_HAS_CAR="y" then is_has_car_g=1;
else if IS_HAS_CAR="n" then is_has_car_g=0;
else is_has_car_g=2;

/*�Ƿ��븸ĸһ���ס*/
if IS_LIVE_WITH_PARENTS="y"  then is_live_parents_g=1;
else if IS_LIVE_WITH_PARENTS="n" then is_live_parents_g=0;
else is_live_parents_g=2;

/*�Ƿ��б���,���E��ͨ��E��ͨ-�Թ�*/
if IS_HAS_INSURANCE_POLICY="y" then is_has_insurance_g=1;
else is_has_insurance_g=0;

/*��ס��ַ*/
format ��ס��ַ���� $50.;
if ��סʡ in ("�Ϻ���","����ʡ","�㽭ʡ","����ʡ","����ʡ","ɽ��ʡ","����ʡ") then ��ס��ַ���� ="��������" ;
else if ��סʡ in ("������","�����","ɽ��ʡ","�ӱ�ʡ","���ɹ�������") then ��ס��ַ���� ="��������" ;
else if ��סʡ in ("����ʡ","����ʡ","����ʡ") then ��ס��ַ���� ="���е���" ;
else if ��סʡ in ("�㶫ʡ","����׳��������","����ʡ") then ��ס��ַ���� ="���ϵ���" ;
else if ��סʡ in ("�Ĵ�ʡ","����ʡ","����ʡ","������","����������") then ��ס��ַ���� ="���ϵ���" ;
else if ��סʡ in ("����ʡ","����ʡ","�ຣʡ","���Ļ���������","�½�ά���������") then ��ס��ַ���� ="��������" ;
else if ��סʡ in ("������ʡ","����ʡ","����ʡ","���ɹ�������") then ��ס��ַ���� ="��������" ;
else ��ס��ַ���� = "";

if ��ס��ַ���� in ("��������","���ϵ���","��������") then live_province_g = 0;
else live_province_g = 1;

/*ס������*/
if ס������ = "�ް��ҹ���" then hourse_lodg_g = 0;
else if ס������ = "�����𰴽ҹ���" then hourse_lodg_g = 1;
else if ס������ = "��ҵ���ҷ�" then hourse_lodg_g =2; 
else if ס������ = "����ס��" then hourse_lodg_g = 3;
else if ס������ = "�Խ���" then hourse_lodg_g = 4;
else if ס������ = "����" then hourse_lodg_g = 5;
else hourse_lodg_g = 7;
/*else if ס������ in("����","") then hourse_lodg_g = 6;*/


/*��������ʱ�� LOCAL_RES_YEARS*/
if LOCAL_RES_YEARS>=0 and LOCAL_RES_YEARS<1 then local_res_years_g=0;
else if LOCAL_RES_YEARS>=1 and LOCAL_RES_YEARS<3 then local_res_years_g=1;
else if LOCAL_RES_YEARS>=3 and LOCAL_RES_YEARS<5 then local_res_years_g=2;
else if LOCAL_RES_YEARS>=5 and LOCAL_RES_YEARS<10 then local_res_years_g=3;
else if LOCAL_RES_YEARS>=10 and LOCAL_RES_YEARS<20 then local_res_years_g=4;
else if LOCAL_RES_YEARS>=20 then local_res_years_g=5;


/*�����䶯���� WORK_CHANGE_TIMES*/
if WORK_CHANGE_TIMES=0 then work_change_times_g=0;
else if WORK_CHANGE_TIMES=1 then work_change_times_g=1;
else if WORK_CHANGE_TIMES=2 then work_change_times_g=2;
else if WORK_CHANGE_TIMES>=3 then work_change_times_g=3;
else work_change_times_g = 4;

/*�������� work_years*/
if work_years=0  then work_years_g=0;
else if work_years<1 then work_years_g=1;
else if work_years<3 then work_years_g=2;
else if work_years<5 then work_years_g=3;
else if work_years<10 then work_years_g=4;
else if work_years<20 then work_years_g=5;
else if work_years>=20 then work_years_g=6;
else work_years_g=7;

/*���������*/
/*if 10000<DESIRED_LOAN_AMOUNT<=40000  then apply_loanamt_g=5;*/
/*else if 40000<DESIRED_LOAN_AMOUNT<=60000 then apply_loanamt_g=4;*/
/*else if 60000<DESIRED_LOAN_AMOUNT<=80000 then apply_loanamt_g=3;*/
/*else if 80000<DESIRED_LOAN_AMOUNT<=100000 then apply_loanamt_g=2;*/
/*else if 100000<DESIRED_LOAN_AMOUNT<=150000 then apply_loanamt_g=1;*/
/*else if DESIRED_LOAN_AMOUNT>150000 then apply_loanamt_g=0;*/
/*else if apply_loanamt_g=6;*/

/*�����������*/
if DESIRED_LOAN_LIFE=341  then apply_loanamt_g=6;
else if DESIRED_LOAN_LIFE=342 then apply_loanamt_g=12;
else if DESIRED_LOAN_LIFE=343 then apply_loanamt_g=18;
else if DESIRED_LOAN_LIFE=344 then apply_loanamt_g=24;
else if DESIRED_LOAN_LIFE=345 then apply_loanamt_g=36;
else if apply_loanamt_g=0;


/*���ÿ��ܶ��*/
rename ���ÿ��ܶ� = credit_amt;
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


/*���ÿ�ʹ����*/
credit_use_ratio = ���ÿ�ʹ����/100;
/*if 0<credit_use_ratio<=0.12  then credit_use_g=0;*/
/*else if 0.12<credit_use_ratio<=0.36 then credit_use_g=1;*/
/*else if 0.36<credit_use_ratio<=0.5 then credit_use_g=2;*/
/*else if 0.5<credit_use_ratio<=0.6 then credit_use_g=3;*/
/*else if 0.6<credit_use_ratio<=0.75 then credit_use_g=4;*/
/*else if 0.75<credit_use_ratio<=0.9 then credit_use_g=5;*/
/*else if 0.9<credit_use_ratio<=1.0 then credit_use_g=6;*/
/*else if credit_use_ratio>1 then credit_use_g=7;*/
/*else if credit_use_g=8;*/

/*/*������*/*/
/*if 0<=YEARLY_INCOME<10000 then yearly_income_g = 7; */
/*else if 10000<=YEARLY_INCOME<30000 then yearly_income_g = 6; */
/*else if 30000<=YEARLY_INCOME<60000 then yearly_income_g = 5; */
/*else if 60000<=YEARLY_INCOME<100000 then yearly_income_g = 4; */
/*else if 100000<=YEARLY_INCOME<150000 then yearly_income_g = 3; */
/*else if 150000<=YEARLY_INCOME<300000 then yearly_income_g = 2; */
/*else if 300000<=YEARLY_INCOME<1000000 then yearly_income_g = 1; */
/*else if YEARLY_INCOME>=1000000 then yearly_income_g = 0; */
/*else if yearly_income_g = 8; */


/*�������� HOURSE_COUNT*/
/*���ڿ�ֵ*/;
if HOURSE_COUNT=0 then hourse_count_g=0;
else if HOURSE_COUNT=1 then hourse_count_g=1;
else if HOURSE_COUNT=2 then hourse_count_g=2;
else if HOURSE_COUNT>=3 then hourse_count_g=3;
else hourse_count_g=4;

/*�������� CAR_COUNT*/
/*���ڿ�ֵ*/
if CAR_COUNT=0 then car_count_g=0;
else if CAR_COUNT=1 then car_count_g=1;
else if CAR_COUNT>=2 then car_count_g=2;
else if CAR_COUNT=. then car_count_g=3;

/*/*��ʵ����*/*/
/*if ��ʵ����<=0 or ��ʵ����=. then verify_income_g=0;*/
/*else if ��ʵ����<3000 then verify_income_g=1;*/
/*else if ��ʵ����<5000 then verify_income_g=2;*/
/*else if ��ʵ����<8000 then verify_income_g=3;*/
/*else if ��ʵ����<10000 then verify_income_g=4;*/
/*else if ��ʵ����<20000 then verify_income_g=5;*/
/*else if ��ʵ����<30000 then verify_income_g=6;*/
/*else if ��ʵ����<50000 then verify_income_g=7;*/
/*else if ��ʵ����<100000 then verify_income_g=8;*/
/*else if ��ʵ����>=100000 then verify_income_g=9;*/

/*��ס���뻧����ϵ*/;
if ��ס��=������ then res_type_g=0;
else  res_type_g=1;

/*��������*/
if ��������="���س���" then do; permanent_type_g=0;;end;
if ��������="����ũ��"  then do; permanent_type_g=1;;end;
if ��������="��س���" then do; permanent_type_g=2;;end;
if ��������="���ũ��" then do; permanent_type_g=3;;end;

/*���ʷ���·��*/
if н�ʷ��ŷ�ʽ="�ֽ�" then salary_pay_way_g=0;
if н�ʷ��ŷ�ʽ="��" then salary_pay_way_g=1;
if н�ʷ��ŷ�ʽ="���д���" then salary_pay_way_g=2;
if н�ʷ��ŷ�ʽ="����" then salary_pay_way_g=3;
if н�ʷ��ŷ�ʽ="����" then salary_pay_way_g=4;

/*��������*/
if ��������="�����𰴽ҹ���"  then local_rescondition_g =0;
else if ��������="��˾����"  then local_rescondition_g =1;
else if ��������="����ס��"  then local_rescondition_g =2;
else if ��������="��ҵ���ҷ�"  then local_rescondition_g =3;
else if ��������="�ް��ҹ���"  then local_rescondition_g =4;
else if ��������="�Խ���"  then local_rescondition_g =5;
else if ��������="����"  then local_rescondition_g =6;
else if ��������="����"  then local_rescondition_g =7;

/*ְ��*/
if ְ��= "����ʽԱ��" then position_g =0;
else if ְ��= "������" then position_g =1;
else if ְ��= "�߼�������Ա" then position_g =2;
else if ְ��= "��ǲԱ��" then position_g =3;
else if ְ��= "һ�������Ա" then position_g =4;
else if ְ��= "һ����ʽԱ��" then position_g =5;
else if ְ��= "�м�������Ա" then position_g =6;

/*��λ����*/
if ��λ���� ="������ҵ��λ" then comp_type_g=0;
else if ��λ���� ="���йɷ�" then comp_type_g=1;
else if ��λ���� in ("������ҵ","������ҵ") then comp_type_g=2;
else if ��λ���� in ("��Ӫ��ҵ","˽Ӫ��ҵ") then comp_type_g=3;
else if ��λ���� ="�������" then comp_type_g=4;
else if ��λ���� ="����" then comp_type_g=5;
else comp_type_g = 6;

/*��ر�ǩ*/
if ��ر�ǩ="����"  then  nonlocal_g=0; else nonlocal_g = 1;

/*�Ʋ���Ϣ*/
if �Ʋ���Ϣ = "�з��г�" then asset_info_g = 0;
else if �Ʋ���Ϣ = "�з��޳�" then asset_info_g =1;
else if �Ʋ���Ϣ = "�޷��г�" then asset_info_g = 2;
else if �Ʋ���Ϣ = "�޷��޳�" then asset_info_g = 3;

/*������������籣����*/
if SOCIAL_SECURITY_RADICES>=PUBLIC_FUNDS_RADICES then SOCIAL_PUBLIC_RADICES=SOCIAL_SECURITY_RADICES;
else SOCIAL_PUBLIC_RADICES=PUBLIC_FUNDS_RADICES;

/*�»�*/
if loan_month_return_new >�����»� then �����»� = loan_month_return_new;
if card_used_amt_sum_new>���ÿ��»� then ���ÿ��»� = card_used_amt_sum_new;
if ���¸�ծ��>��ծ��   then ��ծ��=���¸�ծ��/100;
if �籣���� >���������  then ����=�籣����;
else ����=���������;


/*��ծ�� RATIO*/
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


/*�ܱ��� INSURANCE_INSURED_PRICE*/
/*format insurance_insured_price_g $20.;*/
/*if INSURANCE_INSURED_PRICE=0 or INSURANCE_INSURED_PRICE=. then insurance_insured_price_g=0;*/
/*else if INSURANCE_INSURED_PRICE<=50000 then insurance_insured_price_g="1.�ܱ���1-5��";*/
/*else if INSURANCE_INSURED_PRICE<=100000 then insurance_insured_price_g="2.�ܱ���6-10��";*/
/*else if INSURANCE_INSURED_PRICE<=500000 then insurance_insured_price_g="3.�ܱ���11-50��";*/
/*else if INSURANCE_INSURED_PRICE<=1000000 then insurance_insured_price_g="4.�ܱ���51-100��";*/
/*else if INSURANCE_INSURED_PRICE<=2000000 then insurance_insured_price_g="5.�ܱ���101-200��";*/
/*else if INSURANCE_INSURED_PRICE<=5000000 then insurance_insured_price_g="6.�ܱ���201-500��";*/
/*else if INSURANCE_INSURED_PRICE>5000000 then insurance_insured_price_g="7.�ܱ���>500��";*/
/*���� VERIFY_INCOME*/

rename  �����ܸ�ծ�ܼ�=all  ����=basenumber APPLY_CODE=apply_code 
		���ǿ���5������90���ϴ��� = CARD_60_PASTDUE_M3_FREQUENCY
		���ǿ���5�����ڴ��� = CARD_60_PASTDUE_FREQUENCY
		��Ѻ�����5������90�����ϴ��� = LOAN_MORTGAGE_M3_FREQUENCY
		��Ѻ�����5�����ڴ��� = LOAN_MORTGAGE_60_FREQUENCY
		���������=FUND_MONTH
		��1���±��˲�ѯ����=SELF_QUERY_01_MONTH_FREQUENCY
		��1���´����ѯ����=LOAN__QUERY_01_MONTH_FREQUENCY
		��1�������ÿ���ѯ����=CARD_APPLY_01_MONTH_FREQUENCY
		��2������ѯ����=LOAN__QUERY_24_MONTH_FREQUENCY
		��2����˲�ѯ����=SELF_QUERY_24_MONTH_FREQUENCY
		��2�����ÿ���ѯ����=CARD_APPLY_24_MONTH_FREQUENCY
		��3���±��˲�ѯ����=SELF_QUERY_03_MONTH_FREQUENCY
		��3���´����ѯ����=LOAN__QUERY_03_MONTH_FREQUENCY
		��3�������ÿ���ѯ����=CARD_APPLY_03_MONTH_FREQUENCY
		�������ʴ����5������90������=LOAN_OTHER__M3_FREQUENCY
		�������ʴ����5�����ڴ���=LOAN_OTHER_60_FREQUENCY
		�籣����	=SOCIAL_SECURITY_MONTH
		�޵�Ѻ�����5������90�����ϴ���=LOAN_NAMORTGAGE_M3_FREQUENCY
		�޵�Ѻ�����5�����ڴ���=LOAN_60_PASTDUE_FREQUENCY;
/*       ����=od;*/

drop �����̶� ����״�� н�ʷ��ŷ�ʽ �Ա�  age IS_HAS_HOURSE IS_LIVE_WITH_PARENTS IS_HAS_INSURANCE_POLICY IS_HAS_CAR ��ر�ǩ 
     ��λ���� ְ�� �������� н�ʷ��ŷ�ʽ ��������  ����ʱ�� ID_CARD_NO RESIDENCE_ADDRESS PERMANENT_ADDRESS PHONE1 ��סʡ 
     ��ס�� ��ס�� ����ʡ ������ �����̶� ��λ����  ְλ COMP_ADDRESS  CURRENT_INDUSTRY ����ʡ ������ ס������ WORK_YEARS
     ������ INDUSTRY_NAME cc_name oc_name WORK_CHANGE_TIMES ��������  ��ծ�� �����»� ���ÿ��»� HOURSE_COUNT 
     CAR_COUNT CHILD_COUNT 	׼���ǿ��»�  ���ÿ�ʹ���� DESIRED_LOAN_LIFE  
     �ⲿ��ծ�� MONTHLY_EXPENSE MONTHLY_SALARY MONTHLY_OTHER_INCOME 
      ;
	 
/*     YEARLY_INCOME DESIRED_LOAN_AMOUNT ���ÿ��ܶ� LOCAL_RES_YEARS;*/

/*	   ���ǿ���5������90���ϴ��� ���ǿ���5������90���ϴ��� ���ǿ���5�����ڴ��� ��Ѻ�����5������90�����ϴ��� */
/*     ��Ѻ�����5�����ڴ��� ��1���±��˲�ѯ���� ��1���´����ѯ���� ��1�������ÿ���ѯ���� ��2������ѯ���� ��2����˲�ѯ���� */
/*     ��2�����ÿ���ѯ���� ��3���±��˲�ѯ���� ��3���´����ѯ���� ��3�������ÿ���ѯ���� �������ʴ����5������90������ */
/*     �������ʴ����5�����ڴ��� �޵�Ѻ�����5������90�����ϴ��� �޵�Ѻ�����5�����ڴ��� */

run;


data orig.customer_demo;
set centre.apply_demo;
drop NAME BRANCH_CODE BRANCH_NAME SOURCE_CHANNEL DESIRED_PRODUCT ���� �����ŵ�ʱ�� �����ŵ� END_ACT_ID_ ACT_ID_  ��ǰ״̬	 
auto_reject_time auto_reject ID FIRST_REFUSE_CODE FIRST_REFUSE_DESC SECOND_REFUSE_CODE SECOND_REFUSE_DESC THIRD_REFUSE_CODE 
THIRD_REFUSE_DESC REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 CANCEL_REMARK FACE_SIGN_REMIND check_end 
REFUSE_INFO_NAME REFUSE_INFO_NAME_LEVEL1 REFUSE_INFO_NAME_LEVEL2 ����״̬ check_date �����·� check_week	ͨ��	�ܾ�	 sales_name  
approve_��Ʒ	contract_no	sign_date ǩԼʱ�� �ſ��·� �ſ����� created_name_first  updated_time_first ���˲�Ʒ����_���� sales_code  
REFUSE_INFO_NAME_final REFUSE_INFO_NAME_LEVEL1_final REFUSE_INFO_NAME_LEVEL2_final created_name_final  updated_time_final  
�ɷѷ�ʽ CREATED_TIME ���˲�ƷС��_���� INSURANCE_COMPANY �Ʋ���Ϣ ��ְʱ�� ��������ˮ ���������� ���¸�ծ ���¸�ծ�� ��������_����
���˽��_���� ���ֽ�� ��ͬ��� ����� ��֤�� �ʽ����� ������ INSURANCE_PAY_METHOD INSURANCE_EFFECTIVE_DATE INSURANCE_PAY_AMT
��ʵ���� ��ʵ�������� ������ծ ���ÿ�͸֧�ܶ� all ��ס��ַ���� basenumber; 

run;

proc sort data = orig.customer_demo nodupkey;by apply_code;run;


/*�鿴���ݵ�����*/
ods trace on;
proc contents data=orig.customer_demo;
ods output Variables=need_cus;
run;
ods trace off;







/*�ͻ����ֵȼ�������*/

