option compress = yes validvarname = any;
libname submart "D:\mili\Datamart\data";

**Loanevent_in;
proc import datafile="D:\mili\Datamart\pyscript\submart\bqsreq.xlsx"
out=bqsreq dbms=excel replace;
getnames=yes;
run;
data submart.bqsreq;
set bqsreq;
run;


**Cxfeature_na;
proc import datafile="D:\mili\Datamart\pyscript\submart\cxreq.xlsx"
out=cxreq dbms=excel replace;
getnames=yes;
run;
data submart.Cxfeature_na;
set cxreq;
run;
