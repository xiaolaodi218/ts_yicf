*****************************************
	策略集（事件）结果子主题
*****************************************;
/*option compress = yes validvarname = any;*/
/**/
/*libname dpRaw "C:\Users\lenovo\Document\TS\Datamart\appdp\rawdata";*/
/*libname submart "C:\Users\lenovo\Document\TS\Datamart\AppDatamart\data";*/

***白骑士策略集结果;

/*名单比对策略集（名单比对事件）*/
data loanbqs_blk;
set submart.loanbqs_submart(keep = invoke_record_id apply_code os_type invoke状态 invoke日期 invoke月份 event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "blacklist"));
rename execut状态 = execut状态_blk execut结果 = execut结果_blk execut日期 = execut日期_blk execut月份 = execut月份_blk;
drop event_name;
run;
proc sort data = loanbqs_blk nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_blk nodupkey; by apply_code; run;
/*贷款事件策略集（贷款事件）*/
data loanbqs_loan;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "loan"));
rename execut状态 = execut状态_loan execut结果 = execut结果_loan execut日期 = execut日期_loan execut月份 = execut月份_loan;
drop event_name;
run;
proc sort data = loanbqs_loan nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_loan nodupkey; by apply_code; run;
/*决策事件策略集（决策事件）*/
data loanbqs_decision;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "custdecision"));
rename execut状态 = execut状态_decision execut结果 = execut结果_decision execut日期 = execut日期_decision execut月份 = execut月份_decision;
drop event_name;
run;
proc sort data = loanbqs_decision nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_decision nodupkey; by apply_code; run;
/*银策略集（邀请事件）*/
data loanbqs_invitation;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "invitation"));
rename execut状态 = execut状态_invitation execut结果 = execut结果_invitation execut日期 = execut日期_invitation execut月份 = execut月份_invitation;
drop event_name;
run;
proc sort data = loanbqs_invitation nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_invitation nodupkey; by apply_code; run;
/*人脸识别策略集（人脸识别事件）*/
data loanbqs_faceRecognition;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "faceRecognition"));
rename execut状态 = execut状态_faceRecognition execut结果 = execut结果_faceRecognition execut日期 = execut日期_faceRecognition execut月份 = execut月份_faceRecognition;
drop event_name;
run;
proc sort data = loanbqs_faceRecognition nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_faceRecognition nodupkey; by apply_code; run;

/*白骑士众网策略集（众网事件）*/
data loanbqs_zhongwang;
set submart.loanbqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "custzhongwang"));
rename execut状态 = execut状态_zhongwang execut结果 = execut结果_zhongwang execut日期 = execut日期_zhongwang execut月份 = execut月份_zhongwang;
drop event_name;
run;
proc sort data = loanbqs_zhongwang nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loanbqs_zhongwang nodupkey; by apply_code; run;


/*极速贷策略集（小额打款事件）*/
data paybqs;
set submart.paybqs_submart(keep = invoke_record_id apply_code os_type 引擎结果 invoke状态 invoke日期 invoke月份);
run;
proc sort data = paybqs nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = paybqs nodupkey; by apply_code; run;

***同盾结果;
data loantd;
set submart.loantd_submart(keep = invoke_record_id apply_code execut状态 execut结果 execut日期 execut月份);
rename execut状态 = execut状态_td execut结果 = execut结果_td execut日期 = execut日期_td execut月份 = execut月份_td;
run;
proc sort data = loantd nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loantd nodupkey; by apply_code; run;

***氪信结果;
/*氪信反欺诈*/
data loancx_fraud;
set submart.loancx_submart(keep = invoke_record_id apply_code execut状态 execut结果 execut日期 execut月份 event_name where = (event_name = "anti_fraud"));
rename execut状态 = execut状态_cxfraud execut结果 = execut结果_cxfraud execut日期 = execut日期_cxfraud execut月份 = execut月份_cxfraud;
drop event_name;
run;
proc sort data = loancx_fraud nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loancx_fraud nodupkey; by apply_code; run;
/*氪信评分*/
data loancx_score;
set submart.loancx_submart(keep = invoke_record_id apply_code execut状态 execut结果 execut日期 execut月份 event_name where = (event_name ^= "anti_fraud"));
rename execut状态 = execut状态_cxscore execut结果 = execut结果_cxscore execut日期 = execut日期_cxscore execut月份 = execut月份_cxscore;
drop event_name;
run;
proc sort data = loancx_score nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = loancx_score nodupkey; by apply_code; run;

***申请订单;
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
if execut结果_invitation = "" then execut结果_invitation = execut结果_loan; 

if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" then BQS贷拒 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_cxfraud = "REJECT" then BQS贷CX拒 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_decision = "REJECT" or execut结果_cxfraud = "REJECT" then BQS贷CX决拒 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_decision = "REJECT" or execut结果_cxfraud = "REJECT" or execut结果_td = "REJECT" then BQS贷CX决TD拒 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_decision = "REJECT" or execut结果_cxfraud = "REJECT" 
	or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" then BQS贷CX决TD脸拒 = 1;

if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" then BQS金拒绝 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_cxfraud = "REJECT" then BQS金CX拒绝 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_cxfraud = "REJECT" or execut结果_td = "REJECT" then BQS金CXTD拒绝 = 1;
if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_cxfraud = "REJECT" 
	or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" then BQS金CXTD人脸拒绝 = 1;

if execut结果_blk = "REJECT" or execut结果_invitation = "REJECT" then BQS银拒绝 = 1;
if execut结果_blk = "REJECT" or execut结果_invitation = "REJECT" or execut结果_cxfraud = "REJECT" then BQS银CX拒绝 = 1;
if execut结果_blk = "REJECT" or execut结果_invitation = "REJECT" or execut结果_cxfraud = "REJECT" or execut结果_td = "REJECT" then BQS银CXTD拒绝 = 1;
if execut结果_blk = "REJECT" or execut结果_invitation = "REJECT" or execut结果_cxfraud = "REJECT" 
	or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" then BQS银CXTD人脸拒绝 = 1;

	 if execut结果_blk = "REJECT" or execut结果_loan = "REJECT" or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" 
		 or execut结果_cxfraud = "REJECT" or execut结果_cxscore = "REJECT" then 金策略结果 = "REJECT";
else if execut结果_blk = "REVIEW" or execut结果_loan = "REVIEW" or execut结果_td = "REVIEW" or execut结果_faceRecognition = "REVIEW" 
		 or execut结果_cxfraud = "REVIEW" or execut结果_cxscore = "REVIEW" then 金策略结果 = "REVIEW";
else 金策略结果 = "ACCEPT";
	 if execut结果_blk = "REJECT" or execut结果_invitation = "REJECT" or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" 
		 or execut结果_cxfraud = "REJECT" or execut结果_cxscore = "REJECT" then 银策略结果 = "REJECT";
else if execut结果_blk = "REVIEW" or execut结果_invitation = "REVIEW" or execut结果_td = "REVIEW" or execut结果_faceRecognition = "REVIEW" 
		 or execut结果_cxfraud = "REVIEW" or execut结果_cxscore = "REVIEW" then 银策略结果 = "REVIEW";
else 银策略结果 = "ACCEPT";
if invoke状态 = "ERROR" then do; 金策略结果 = "ERROR"; 银策略结果 = "ERROR"; end;
run;


*-------------------复贷1策略--------------------*;
***白骑士策略集结果;

/*复贷策略集(复贷事件)*/
data reloanbqs_loan;
set submart.reloanbqs_submart(keep = invoke_record_id apply_code os_type invoke状态 invoke日期 invoke月份 event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "custreloan"));
rename execut状态 = execut状态_loan execut结果 = execut结果_loan execut日期 = execut日期_loan execut月份 = execut月份_loan;
drop event_name;
run;
proc sort data = reloanbqs_loan nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloanbqs_loan nodupkey; by apply_code; run;

/*人脸识别策略集（人脸识别事件）*/
data reloanbqs_faceRecognition;
set submart.reloanbqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "faceRecognition"));
rename execut状态 = execut状态_faceRecognition execut结果 = execut结果_faceRecognition execut日期 = execut日期_faceRecognition execut月份 = execut月份_faceRecognition;
drop event_name;
run;
proc sort data = reloanbqs_faceRecognition nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloanbqs_faceRecognition nodupkey; by apply_code; run;

***同盾结果;
data reloantd;
set submart.reloantd_submart(keep = invoke_record_id apply_code execut状态 execut结果 execut日期 execut月份);
rename execut状态 = execut状态_td execut结果 = execut结果_td execut日期 = execut日期_td execut月份 = execut月份_td;
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
if execut结果_loan = "REJECT" then BQS拒绝 = 1;
if execut结果_loan = "REJECT" or execut结果_td = "REJECT" then BQSTD拒绝 = 1;
if execut结果_loan = "REJECT" or execut结果_td = "REJECT" or execut结果_faceRecognition = "REJECT" then BQSTD人脸拒绝 = 1;

run;

*-------------------复贷2策略--------------------*;
***白骑士策略集结果;

/*复贷策略集(复贷事件)*/
data reloansimplebqs_loan;
set submart.reloansimplebqs_submart(keep = invoke_record_id apply_code os_type invoke状态 invoke日期 invoke月份 event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "custreloan"));
rename execut状态 = execut状态_loan execut结果 = execut结果_loan execut日期 = execut日期_loan execut月份 = execut月份_loan;
drop event_name;
run;
proc sort data = reloansimplebqs_loan nodupkey; by apply_code descending invoke_record_id; run;
proc sort data = reloansimplebqs_loan nodupkey; by apply_code; run;

/*人脸识别策略集（人脸识别事件）*/
data reloansimplebqs_faceRecognition;
set submart.reloansimplebqs_submart(keep = invoke_record_id apply_code event_name execut状态 execut结果 execut日期 execut月份 
						   where = (event_name = "faceRecognition"));
rename execut状态 = execut状态_faceRecognition execut结果 = execut结果_faceRecognition execut日期 = execut日期_faceRecognition execut月份 = execut月份_faceRecognition;
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
if execut结果_loan = "REJECT" then BQS拒绝 = 1;
if execut结果_loan = "REJECT" or execut结果_faceRecognition = "REJECT" then BQS人脸拒绝 = 1;

run;

***********************
	策略漏斗
***********************;
***LOAN策略漏斗;
data Apply;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份);
漏斗节点 = "1.申请";
run;
data BQSl;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS贷拒 where = (BQS贷拒 = 1));
漏斗节点 = "2.BQS贷拒";
drop BQS贷拒;
run;
data BQSlCX;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS贷CX拒 where = (BQS贷CX拒 = 1));
漏斗节点 = "3.BQS贷CX拒";
drop BQS贷CX拒;
run;
data BQSlCXd;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS贷CX决拒 where = (BQS贷CX决拒 = 1));
漏斗节点 = "4.BQS贷CX决拒";
drop BQS贷CX决拒;
run;
data BQSlCXdTD;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS贷CX决TD拒 where = (BQS贷CX决TD拒 = 1));
漏斗节点 = "5.BQS贷CX决TD拒";
drop BQS贷CX决TD拒;
run;
data BQSlCXdTDYT;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS贷CX决TD脸拒 where = (BQS贷CX决TD脸拒 = 1));
漏斗节点 = "6.BQS贷CX决TD脸拒";
drop BQS贷CX决TD脸拒;
run;
data submart.LOANFunnel_submart;
length 漏斗节点 $20;
set Apply BQSl BQSlCX BQSlCXd BQSlCXdTD BQSlCXdTDYT;
run;

***LOAN金策略漏斗;
data Apply;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份);
漏斗节点 = "1.申请";
run;
data BQSg;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS金拒绝 where = (BQS金拒绝 = 1));
漏斗节点 = "2.BQS金拒绝";
drop BQS金拒绝;
run;
data BQSgCX;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS金CX拒绝 where = (BQS金CX拒绝 = 1));
漏斗节点 = "3.BQS金CX拒绝";
drop BQS金CX拒绝;
run;
data BQSgCXTD;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS金CXTD拒绝 where = (BQS金CXTD拒绝 = 1));
漏斗节点 = "4.BQS金CXTD拒绝";
drop BQS金CXTD拒绝;
run;
data BQSgCXTDYT;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS金CXTD人脸拒绝 where = (BQS金CXTD人脸拒绝 = 1));
漏斗节点 = "5.BQS金CXTD人脸拒绝";
drop BQS金CXTD人脸拒绝;
run;
data submart.LOANGoldFunnel_submart;
length 漏斗节点 $20;
set Apply BQSg BQSgCX BQSgCXTD BQSgCXTDYT;
run;

***LOAN银策略漏斗;
data BQSs;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS银拒绝 where = (BQS银拒绝 = 1));
漏斗节点 = "2.BQS银拒绝";
drop BQS银拒绝;
run;
data BQSsCX;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS银CX拒绝 where = (BQS银CX拒绝 = 1));
漏斗节点 = "3.BQS银CX拒绝";
drop BQS银CX拒绝;
run;
data BQSsCXTD;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS银CXTD拒绝 where = (BQS银CXTD拒绝 = 1));
漏斗节点 = "4.BQS银CXTD拒绝";
drop BQS银CXTD拒绝;
run;
data BQSsCXTDYT;
set submart.loanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS银CXTD人脸拒绝 where = (BQS银CXTD人脸拒绝 = 1));
漏斗节点 = "5.BQS银CXTD人脸拒绝";
drop BQS银CXTD人脸拒绝;
run;
data submart.LOANSilverFunnel_submart;
length 漏斗节点 $20;
set Apply BQSs BQSsCX BQSsCXTD BQSsCXTDYT;
run;


***RELOAN策略漏斗;
data Apply;
set submart.reloanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份);
漏斗节点 = "1.申请";
run;
data BQS;
set submart.reloanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS拒绝 where = (BQS拒绝 = 1));
漏斗节点 = "2.BQS拒绝";
drop BQS拒绝;
run;
data BQSTD;
set submart.reloanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQSTD拒绝 where = (BQSTD拒绝 = 1));
漏斗节点 = "3.BQSTD拒绝";
drop BQSTD拒绝;
run;
data BQSTDYT;
set submart.reloanstrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQSTD人脸拒绝 where = (BQSTD人脸拒绝 = 1));
漏斗节点 = "4.BQSTD人脸拒绝";
drop BQSTD人脸拒绝;
run;
data submart.RELOANFunnel_submart;
length 漏斗节点 $20;
set Apply BQS BQSTD BQSTDYT;
run;

***RELOAN_SIMPLE策略漏斗;
data Apply;
set submart.reloansimplestrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份);
漏斗节点 = "1.申请";
run;
data BQS;
set submart.reloansimplestrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS拒绝 where = (BQS拒绝 = 1));
漏斗节点 = "2.BQS拒绝";
drop BQS拒绝;
run;
data BQSYT;
set submart.reloansimplestrategySet_submart(keep = apply_code invoke状态 invoke日期 invoke月份 BQS人脸拒绝 where = (BQS人脸拒绝 = 1));
漏斗节点 = "3.BQS人脸拒绝";
drop BQS人脸拒绝;
run;
data submart.RELOANSIMPLEFunnel_submart;
length 漏斗节点 $20;
set Apply BQS BQSYT;
run;
