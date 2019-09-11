libname d 'C:\Users\tpmpi\Desktop\SAS';
/*datastep for Compustat*/
data d.a1;
set d.comp(keep= at datadate lpermno
		   rename = (datadate =date lpermno =permno)
		   where= (year(date) in(1970:2016)));
if at gt 0;
lag_at = lag(at);
if permno ne lag(permno) or year(date) ne (lag(year(date)+1)) then lag_at=.;
yr= year(date);
mon=month(date);
ymon = yr*100 + mon;
fperiod= yr+1;
at_growth= (at/lag_at)-1;
run;

proc sort data = d.a1; by ymon; run;
/*Ranking for protfolios*/
proc rank data =d.a1 out=d.a2 group=10;
by ymon;
var at_growth;
ranks decile;
run;

/*Datastep for CRSP*/
data d.a3;
set d.crsp(keep =exchcd shrcd ret permno date 
		   where = (ret gt -1));
if shrcd eq 10 or shrcd eq 11 or shrcd eq 12;
if exchcd eq 1 or exchcd eq 2 or exchcd eq 3;
yr =year(date);
mon = month(date);
ymon= yr*100+mon;
if yr ge 1970;
if mon ge 7 and mon le 12 then fperiod = yr;
if mon ge 1 and mon le 6 then fperiod = yr-1;
run;

proc sort data = d.a2; by permno fperiod;run;
proc sort data= d.a3; by permno fperiod; run;

data d.Merged_Data;
merge d.a2 d.a3;
by permno fperiod;
run;

proc sort data = d.Merged_Data; by decile ymon; run;

proc means data = d.Merged_Data noprint;
	var ret;
	by decile ymon;
	output out = d.mon_ret
	mean(ret) = InvestementByMon_decile;
run;

proc sort data= d.mon_ret; by ymon; run;
/*Proc Transpose Function*/
proc Transpose data= d.mon_ret out=d.mon_retTranspose prefix =p;
 by ymon;
 id decile;
 var InvestementByMon_decile;
run;

data d.regress_data;
set d.mon_retTranspose;
pDiff=p9-p0;
run;

proc transpose data= d.regress_data out=d.regress_result_data name=p;
by ymon;
run;
proc sort data =d.regress_result_data; by p; run;
/*regression for q7*/
proc reg data = d.regress_result_data plots =none outest= Table4 tableout;
model InvestementByMon_decile = /hcc;
by p;
run;
quit;

proc transpose data= Table4 out=Table3 name=p;
by p;
id _TYPE_;
var Intercept;
run;

data Table1;
set Table3;
keep p parms T pvalue;
run;


data d.a4;
set d.ff3;
mon=month(dateff);
yr = year(dateff);
ymon=yr*100+mon;
if mon ne .;
run;

proc sort data= d.a4; by ymon; run;
proc sort data =d.regress_result_data; by ymon; run;

data d.regress;
merge d.a4 d.regress_result_data;
by ymon;
run;

proc sort data=d.regress; by p; run;

data d.regress1;
merge table1 d.regress;
by p;
run;

data d.regress2;
set d.regress;
ex_ret= InvestementByMon_decile-rf;
if p='pDiff' then ex_ret=InvestementByMon_decile;
run;
/*regression for q8*/
proc reg data =d.regress2 outest=Table5 tableout;
model ex_ret = mktrf smb hml /hcc;
by p;
run;
quit;
/*Transpose to keep only the average returns and alphas along with the tsats*/
proc transpose data= Table5 out=Table6 name=p;
by p;
id _TYPE_;
var Intercept;
run;


data Table2;
set Table6;
keep p parms T pvalue;
run;

