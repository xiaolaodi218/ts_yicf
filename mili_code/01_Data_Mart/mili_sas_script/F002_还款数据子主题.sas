option compress = yes validvarname = any;

libname submart "D:\mili\Datamart\data";
libname mart "C:\Users\lenovo\Document\TS\Datamart\Ã×Á£°×Ìõ";

data payment;
set mart.paymentmart;
rename contract_no = apply_code;
run;
proc sort data = payment; by apply_code; run;

data fudai_flag;
set submart.apply_submart(keep = apply_code ¸´´ûÉêÇë where = (¸´´ûÉêÇë = 1));
run;

proc sort data = fudai_flag nodupkey; by apply_code; run;
data submart.payment;
merge payment(in = a) fudai_flag(in = b);
by apply_code;
if a;
run;
