*******************************
		��������������
*******************************;
option compress = yes validvarname = any;

libname account "D:\mili\Datamart\rawdata\account";
libname submart "D:\mili\Datamart\data";


*�����ſ�ͻ�;
data mili;
/*set account.account_info(keep=ACCOUNT_TYPE contract_no FUND_CHANNEL_CODE PRODUCT_NAME ID_NUMBER */
/*CH_NAME ACCOUNT_STATUS PERIOD LOAN_DATE NEXT_REPAY_DATE LAST_REPAY_DATE BORROWER_TEL_ONE CLEAR_DATE);*/
set account.account_info;
��������=NEXT_REPAY_DATE-LOAN_DATE;
if kindex(PRODUCT_NAME,"����");
if contract_no ^="PL148178693332002600000066";/*�����ɳ�񻪵�*/
keep contract_no �������� CH_NAME LOAN_DATE CONTRACT_AMOUNT;
run;

proc sql;
create table submart.mili_bill_main as
select a.*, b.repay_date, b.overdue_days, b.bill_status, b.clear_date, b.CURR_RECEIVE_AMT, b.CURR_RECEIPT_AMT
from mili as a 
left join account.bill_main as b on a.contract_no = b.contract_no
;
quit;
