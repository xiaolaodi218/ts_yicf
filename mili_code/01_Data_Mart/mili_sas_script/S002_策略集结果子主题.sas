*****************************************
	���Լ����¼������������
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***����ʿ���Լ����;

/*�����ȶԲ��Լ��������ȶ��¼���*/
data loanbqs_blk;
set submart.loanbqs_submart(keep = invoke_record_id apply_code os_type invoke״̬ invoke���� invoke�·� event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "blacklist"));
rename execut״̬ = execut״̬_blk execut��� = execut���_blk execut���� = execut����_blk execut�·� = execut�·�_blk;
drop event_name;
run;
proc sort data = loanbqs_blk nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_blk nodupkey; by apply_code; run;
/*�����¼����Լ��������¼���*/
data loanbqs_loan;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "loan"));
rename execut״̬ = execut״̬_loan execut��� = execut���_loan execut���� = execut����_loan execut�·� = execut�·�_loan;
drop event_name;
run;
proc sort data = loanbqs_loan nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_loan nodupkey; by apply_code; run;
/*�����¼����Լ��������¼���*/
data loanbqs_decision;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "custdecision"));
rename execut״̬ = execut״̬_decision execut��� = execut���_decision execut���� = execut����_decision execut�·� = execut�·�_decision;
drop event_name;
run;
proc sort data = loanbqs_decision nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_decision nodupkey; by apply_code; run;
/*�����Լ��������¼���*/
data loanbqs_invitation;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "invitation"));
rename execut״̬ = execut״̬_invitation execut��� = execut���_invitation execut���� = execut����_invitation execut�·� = execut�·�_invitation;
drop event_name;
run;
proc sort data = loanbqs_invitation nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_invitation nodupkey; by apply_code; run;
/*����ʶ����Լ�������ʶ���¼���*/
data loanbqs_faceRecognition;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "faceRecognition"));
rename execut״̬ = execut״̬_faceRecognition execut��� = execut���_faceRecognition execut���� = execut����_faceRecognition execut�·� = execut�·�_faceRecognition;
drop event_name;
run;
proc sort data = loanbqs_faceRecognition nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_faceRecognition nodupkey; by apply_code; run;

/*����ʿ�������Լ��������¼���*/
data loanbqs_zhongwang;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "custzhongwang"));
rename execut״̬ = execut״̬_zhongwang execut��� = execut���_zhongwang execut���� = execut����_zhongwang execut�·� = execut�·�_zhongwang;
drop event_name;
run;
proc sort data = loanbqs_zhongwang nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_zhongwang nodupkey; by apply_code; run;


/*���ٴ����Լ���С�����¼���*/
data paybqs;
set submart.paybqs_submart(keep = invoke_record_id apply_code os_type ������ invoke״̬ invoke���� invoke�·�);
run;
proc sort data = paybqs nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = paybqs nodupkey; by apply_code; run;

***ͬ�ܽ��;
data loantd;
set submart.loantd_submart(keep = invoke_record_id apply_code execut״̬ execut��� execut���� execut�·�);
rename execut״̬ = execut״̬_td execut��� = execut���_td execut���� = execut����_td execut�·� = execut�·�_td;
run;
proc sort data = loantd nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loantd nodupkey; by apply_code; run;

***��Ž��;
/*��ŷ���թ*/
data loancx_fraud;
set submart.loancx_submart(keep = invoke_record_id apply_code execut״̬ execut��� execut���� execut�·� event_name where = (event_name = "anti_fraud"));
rename execut״̬ = execut״̬_cxfraud execut��� = execut���_cxfraud execut���� = execut����_cxfraud execut�·� = execut�·�_cxfraud;
drop event_name;
run;
proc sort data = loancx_fraud nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loancx_fraud nodupkey; by apply_code; run;
/*�������*/
data loancx_score;
set submart.loancx_submart(keep = invoke_record_id apply_code execut״̬ execut��� execut���� execut�·� event_name where = (event_name ^= "anti_fraud"));
rename execut״̬ = execut״̬_cxscore execut��� = execut���_cxscore execut���� = execut����_cxscore execut�·� = execut�·�_cxscore;
drop event_name;
run;
proc sort data = loancx_score nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loancx_score nodupkey; by apply_code; run;

***���붩��;
data apply;
set submart.apply_submart(keep = apply_code );
run;
proc sort data = apply nodupkey; by apply_code; run;

data submart.loanstrategySet_submart;
merge apply(in = t)
	loanbqs_blk(in = a) 
	loanbqs_loan(in = b) 
	loanbqs_invitation(in = c) 
	loanbqs_faceRecognition(in = d) 
	loantd(in = e)
	loancx_fraud(in = f)
	loancx_score(in = g)
	loanbqs_decision(in = h);
/*	loanbqs_zhongwang(in = i)*/
by apply_code;
if t & a;
if execut���_invitation = "" then execut���_invitation = execut���_loan; 

if execut���_blk = "REJECT" or execut���_loan = "REJECT" then BQS���� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_cxfraud = "REJECT" then BQS��CX�� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_decision = "REJECT" or execut���_cxfraud = "REJECT" then BQS��CX���� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_decision = "REJECT" or execut���_cxfraud = "REJECT" or execut���_td = "REJECT" then BQS��CX��TD�� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_decision = "REJECT" or execut���_cxfraud = "REJECT" 
	or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" then BQS��CX��TD���� = 1;

if execut���_blk = "REJECT" or execut���_loan = "REJECT" then BQS��ܾ� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_cxfraud = "REJECT" then BQS��CX�ܾ� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_cxfraud = "REJECT" or execut���_td = "REJECT" then BQS��CXTD�ܾ� = 1;
if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_cxfraud = "REJECT" 
	or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" then BQS��CXTD�����ܾ� = 1;

if execut���_blk = "REJECT" or execut���_invitation = "REJECT" then BQS���ܾ� = 1;
if execut���_blk = "REJECT" or execut���_invitation = "REJECT" or execut���_cxfraud = "REJECT" then BQS��CX�ܾ� = 1;
if execut���_blk = "REJECT" or execut���_invitation = "REJECT" or execut���_cxfraud = "REJECT" or execut���_td = "REJECT" then BQS��CXTD�ܾ� = 1;
if execut���_blk = "REJECT" or execut���_invitation = "REJECT" or execut���_cxfraud = "REJECT" 
	or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" then BQS��CXTD�����ܾ� = 1;

	 if execut���_blk = "REJECT" or execut���_loan = "REJECT" or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" 
		 or execut���_cxfraud = "REJECT" or execut���_cxscore = "REJECT" then ����Խ�� = "REJECT";
else if execut���_blk = "REVIEW" or execut���_loan = "REVIEW" or execut���_td = "REVIEW" or execut���_faceRecognition = "REVIEW" 
		 or execut���_cxfraud = "REVIEW" or execut���_cxscore = "REVIEW" then ����Խ�� = "REVIEW";
else ����Խ�� = "ACCEPT";
	 if execut���_blk = "REJECT" or execut���_invitation = "REJECT" or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" 
		 or execut���_cxfraud = "REJECT" or execut���_cxscore = "REJECT" then �����Խ�� = "REJECT";
else if execut���_blk = "REVIEW" or execut���_invitation = "REVIEW" or execut���_td = "REVIEW" or execut���_faceRecognition = "REVIEW" 
		 or execut���_cxfraud = "REVIEW" or execut���_cxscore = "REVIEW" then �����Խ�� = "REVIEW";
else �����Խ�� = "ACCEPT";
if invoke״̬ = "ERROR" then do; ����Խ�� = "ERROR"; �����Խ�� = "ERROR"; end;
run;


*-------------------����1����--------------------*;
***����ʿ���Լ����;

/*�������Լ�(�����¼�)*/
data reloanbqs_loan;
set submart.reloanbqs_submart(keep = invoke_record_id apply_code os_type invoke״̬ invoke���� invoke�·� event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "custreloan"));
rename execut״̬ = execut״̬_loan execut��� = execut���_loan execut���� = execut����_loan execut�·� = execut�·�_loan;
drop event_name;
run;
proc sort data = reloanbqs_loan nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloanbqs_loan nodupkey; by apply_code; run;

/*����ʶ����Լ�������ʶ���¼���*/
data reloanbqs_faceRecognition;
set submart.reloanbqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "faceRecognition"));
rename execut״̬ = execut״̬_faceRecognition execut��� = execut���_faceRecognition execut���� = execut����_faceRecognition execut�·� = execut�·�_faceRecognition;
drop event_name;
run;
proc sort data = reloanbqs_faceRecognition nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloanbqs_faceRecognition nodupkey; by apply_code; run;

***ͬ�ܽ��;
data reloantd;
set submart.reloantd_submart(keep = invoke_record_id apply_code execut״̬ execut��� execut���� execut�·�);
rename execut״̬ = execut״̬_td execut��� = execut���_td execut���� = execut����_td execut�·� = execut�·�_td;
run;
proc sort data = reloantd nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloantd nodupkey; by apply_code; run;

data submart.reloanstrategySet_submart;
merge apply(in = t)
	reloanbqs_loan(in = b) 
	reloanbqs_faceRecognition(in = d) 
	reloantd(in = e);
by apply_code;
if t & b;
if execut���_loan = "REJECT" then BQS�ܾ� = 1;
if execut���_loan = "REJECT" or execut���_td = "REJECT" then BQSTD�ܾ� = 1;
if execut���_loan = "REJECT" or execut���_td = "REJECT" or execut���_faceRecognition = "REJECT" then BQSTD�����ܾ� = 1;

run;

*-------------------����2����--------------------*;
***����ʿ���Լ����;

/*�������Լ�(�����¼�)*/
data reloansimplebqs_loan;
set submart.reloansimplebqs_submart(keep = invoke_record_id apply_code os_type invoke״̬ invoke���� invoke�·� event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "custreloan"));
rename execut״̬ = execut״̬_loan execut��� = execut���_loan execut���� = execut����_loan execut�·� = execut�·�_loan;
drop event_name;
run;
proc sort data = reloansimplebqs_loan nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloansimplebqs_loan nodupkey; by apply_code; run;

/*����ʶ����Լ�������ʶ���¼���*/
data reloansimplebqs_faceRecognition;
set submart.reloansimplebqs_submart(keep = invoke_record_id apply_code event_name execut״̬ execut��� execut���� execut�·� 
						   where = (event_name = "faceRecognition"));
rename execut״̬ = execut״̬_faceRecognition execut��� = execut���_faceRecognition execut���� = execut����_faceRecognition execut�·� = execut�·�_faceRecognition;
drop event_name;
run;
proc sort data = reloansimplebqs_faceRecognition nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloansimplebqs_faceRecognition nodupkey; by apply_code; run;

data submart.reloansimplestrategySet_submart;
merge apply(in = t)
	reloansimplebqs_loan(in = b) 
	reloansimplebqs_faceRecognition(in = d); 
by apply_code;
if t & b;
if execut���_loan = "REJECT" then BQS�ܾ� = 1;
if execut���_loan = "REJECT" or execut���_faceRecognition = "REJECT" then BQS�����ܾ� = 1;

run;

***********************
	����©��
***********************;
***LOAN����©��;
data Apply;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·�);
©���ڵ� = "1.����";
run;
data BQSl;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS���� where = (BQS���� = 1));
©���ڵ� = "2.BQS����";
drop BQS����;
run;
data BQSlCX;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CX�� where = (BQS��CX�� = 1));
©���ڵ� = "3.BQS��CX��";
drop BQS��CX��;
run;
data BQSlCXd;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CX���� where = (BQS��CX���� = 1));
©���ڵ� = "4.BQS��CX����";
drop BQS��CX����;
run;
data BQSlCXdTD;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CX��TD�� where = (BQS��CX��TD�� = 1));
©���ڵ� = "5.BQS��CX��TD��";
drop BQS��CX��TD��;
run;
data BQSlCXdTDYT;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CX��TD���� where = (BQS��CX��TD���� = 1));
©���ڵ� = "6.BQS��CX��TD����";
drop BQS��CX��TD����;
run;
data submart.LOANFunnel_submart;
length ©���ڵ� $20;
set Apply BQSl BQSlCX BQSlCXd BQSlCXdTD BQSlCXdTDYT;
run;

***LOAN�����©��;
data Apply;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·�);
©���ڵ� = "1.����";
run;
data BQSg;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��ܾ� where = (BQS��ܾ� = 1));
©���ڵ� = "2.BQS��ܾ�";
drop BQS��ܾ�;
run;
data BQSgCX;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CX�ܾ� where = (BQS��CX�ܾ� = 1));
©���ڵ� = "3.BQS��CX�ܾ�";
drop BQS��CX�ܾ�;
run;
data BQSgCXTD;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CXTD�ܾ� where = (BQS��CXTD�ܾ� = 1));
©���ڵ� = "4.BQS��CXTD�ܾ�";
drop BQS��CXTD�ܾ�;
run;
data BQSgCXTDYT;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CXTD�����ܾ� where = (BQS��CXTD�����ܾ� = 1));
©���ڵ� = "5.BQS��CXTD�����ܾ�";
drop BQS��CXTD�����ܾ�;
run;
data submart.LOANGoldFunnel_submart;
length ©���ڵ� $20;
set Apply BQSg BQSgCX BQSgCXTD BQSgCXTDYT;
run;

***LOAN������©��;
data BQSs;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS���ܾ� where = (BQS���ܾ� = 1));
©���ڵ� = "2.BQS���ܾ�";
drop BQS���ܾ�;
run;
data BQSsCX;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CX�ܾ� where = (BQS��CX�ܾ� = 1));
©���ڵ� = "3.BQS��CX�ܾ�";
drop BQS��CX�ܾ�;
run;
data BQSsCXTD;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CXTD�ܾ� where = (BQS��CXTD�ܾ� = 1));
©���ڵ� = "4.BQS��CXTD�ܾ�";
drop BQS��CXTD�ܾ�;
run;
data BQSsCXTDYT;
set submart.loanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS��CXTD�����ܾ� where = (BQS��CXTD�����ܾ� = 1));
©���ڵ� = "5.BQS��CXTD�����ܾ�";
drop BQS��CXTD�����ܾ�;
run;
data submart.LOANSilverFunnel_submart;
length ©���ڵ� $20;
set Apply BQSs BQSsCX BQSsCXTD BQSsCXTDYT;
run;


***RELOAN����©��;
data Apply;
set submart.reloanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·�);
©���ڵ� = "1.����";
run;
data BQS;
set submart.reloanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS�ܾ� where = (BQS�ܾ� = 1));
©���ڵ� = "2.BQS�ܾ�";
drop BQS�ܾ�;
run;
data BQSTD;
set submart.reloanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQSTD�ܾ� where = (BQSTD�ܾ� = 1));
©���ڵ� = "3.BQSTD�ܾ�";
drop BQSTD�ܾ�;
run;
data BQSTDYT;
set submart.reloanstrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQSTD�����ܾ� where = (BQSTD�����ܾ� = 1));
©���ڵ� = "4.BQSTD�����ܾ�";
drop BQSTD�����ܾ�;
run;
data submart.RELOANFunnel_submart;
length ©���ڵ� $20;
set Apply BQS BQSTD BQSTDYT;
run;

***RELOAN_SIMPLE����©��;
data Apply;
set submart.reloansimplestrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·�);
©���ڵ� = "1.����";
run;
data BQS;
set submart.reloansimplestrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS�ܾ� where = (BQS�ܾ� = 1));
©���ڵ� = "2.BQS�ܾ�";
drop BQS�ܾ�;
run;
data BQSYT;
set submart.reloansimplestrategySet_submart(keep = apply_code invoke״̬ invoke���� invoke�·� BQS�����ܾ� where = (BQS�����ܾ� = 1));
©���ڵ� = "3.BQS�����ܾ�";
drop BQS�����ܾ�;
run;
data submart.RELOANSIMPLEFunnel_submart;
length ©���ڵ� $20;
set Apply BQS BQSYT;
run;
