*****************************************
	Demographics������
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***loan�¼��������;
data loanevent_in;
set submart.loanevent_in;
format grp_appsl grp_txlsl $20.;
	 if loc_appsl = . then grp_appsl = "0. Missing";
else if loc_appsl < 5 then grp_appsl = "1. [0, 5)";
else if loc_appsl < 10 then grp_appsl = "2. [5, 10)";
else if loc_appsl < 15 then grp_appsl = "3. [10, 15)";
else if loc_appsl >= 15 then grp_appsl = "4. [15, )";
	 if loc_txlsl = . then grp_txlsl = "0. Missing";
else if loc_txlsl < 10 then grp_txlsl = "1. [0, 10)";
else if loc_txlsl < 20 then grp_txlsl = "2. [10, 20)";
else if loc_txlsl < 30 then grp_txlsl = "3. [20, 30)";
else if loc_txlsl < 50 then grp_txlsl = "4. [30, 50)";
else if loc_txlsl < 100 then grp_txlsl = "5. [50, 100)";
else if loc_txlsl >= 100 then grp_txlsl = "6. [100, )";
run;
proc sort data = loanevent_in nodupkey; by apply_code descending data_query_log_id; run;
proc sort data = loanevent_in nodupkey; by apply_code; run;

***��������;
data apply_var;
set submart.applyvar_submart(keep = apply_code period �����ύʱ�� SEX_NAME ���� MARRIAGE_NAME grp_�����ע�� GPSʡ��);
run;
proc sort data = apply_var nodupkey; by apply_code; run;

***ͬ�ܶ�ƽ̨������;
data apply_cnt_td;
set submart.apply_cnt_td(keep = apply_code ���������·� ������������ apply_cnt_in7d apply_cnt_in1m apply_cnt_in3m);
run;
proc sort data = apply_cnt_td nodupkey; by apply_code; run;

data loan_in;
merge loanevent_in(in = a) apply_var(in = b) apply_cnt_td(in = c);
by apply_code;
if a;
run;
proc sort data = loan_in nodupkey; by apply_code; run;

***TTD;
data apply_submart;
set submart.apply_submart;
run;
proc sort data = apply_submart nodupkey; by apply_code; run;
data submart.ttd_demographics;
merge apply_submart(in = a) loan_in(in = b);
by apply_code;
if a;
run;


***ActiveLoan;
data dt;
set submart.mili_bill_main(keep = contract_no overdue_days bill_status CH_NAME where = (bill_status ^= "0001"));
format �������� �����ǩ1 �����ǩ2 $20.;
	 if bill_status = "0002" and overdue_days > 5 then �������� = "��ǰ����5+"; 
else if overdue_days > 5 then �������� = "��������5+";
else �������� = "����";
	 if overdue_days > 15 then �����ǩ1 = "��������15+";
else if overdue_days > 0 and bill_status = "0000" then �����ǩ1 = "���������ѽ���";
else if overdue_days > 0 then �����ǩ1 = "��ǰ����";
else �����ǩ1 = "��������";
	 if overdue_days > 5 then �����ǩ2 = "��������5+";
else if overdue_days > 0 and bill_status = "0000" then �����ǩ2 = "���������ѽ���";
else if overdue_days > 0 then �����ǩ2 = "��ǰ����";
else �����ǩ2 = "��������";
rename contract_no = apply_code;
run;
proc sort data = dt nodupkey; by apply_code; run;

***���붩����������ǩ�����Ƿ񸴴�;
data apply_flag;
set submart.apply_submart(keep = apply_code �������� �״�����);
run;
proc sort data = apply_flag nodupkey; by apply_code; run;

data submart.activeloan_demographics;
merge dt(in = a) loan_in(in = b) apply_flag(in = c);
by apply_code;
if a;
run;
