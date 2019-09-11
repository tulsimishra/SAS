libname d 'C:\Users\tpmpi\Desktop\SAS';

/* Extracting data from CRSP*/
data d.data1;

set d.CRSP(keep = permno date ret siccd
			   	where= (ret le 1));
 m = month(date);
 y = year(date);
 if siccd ne .;
 yrmon = (y*100) + m;
 if yrmon ge 197001 and yrmon le 201612;
 run;

/* Extracting data from FF3*/
data d.data2;
set d.ff3 (where= (year(date) ge 1970 and year(date) le 2016)
		  rename = (dateff = date)
		  			);
m1= month(date);
y1=year(date);
yrmon= (y1*100) +m1;
run;

proc sort data =d.data1;
by siccd yrmon;
run;

/* Calculating means for Industry by SICCD by Month*/
proc means data= d.data1 noprint;
var ret;
by siccd yrmon;
output out = d.meansRet
mean(ret)=RetMeans;
run;

proc sort data =d.data2;
by yrmon;
run;

proc sort data = d.meansRet;
by yrmon;
run;

/*Merging the industry returns woth ff3*/

data d.Merged_Data;
merge d.data2 d.meansRet(in=in2);
by yrmon;
if in2;
ExcessReturns = RetMeans - rf;
run;

/*Breakig data into two parts: Independent*/
data d.Merged_Data1;
set d.Merged_Data;
if y1 ge 1970;
if y1 le 1995;
run;

/*Breakig data into two parts: Dependent*/
data d.Merged_Data2;
set d.Merged_Data (where = (y1 ge 1996 and y1 le 2016));
run;

proc sort data= d.Merged_data1;
by siccd;
run;

proc sort data= d.Merged_data2;
by siccd;
run;

/*Regression to get alphas for year 1970 to 1995*/
proc reg data = d.Merged_Data1 noprint outest= d.Alphas1;
where yrmon ge 197001 and yrmon le 199512; 
by siccd;
Model excessReturns = mktrf;
run;
quit;

/*Regression to get alphas from 1996 to 2016*/
proc reg data = d.Merged_Data2 noprint outest= d.Alphas2;
where yrmon ge 199601 and yrmon le 201612; 
by siccd;
Model excessReturns = mktrf;
run;
quit;

data d.Alphas3;
set d.Alphas1 ( rename= (intercept= alphas1));
run;
 
data d.Alphas4;
set d.Alphas2 ( rename= (intercept= alphas2));
run;

/* merging both alphas*/
data d.mergedAlphas;
merge d.Alphas3(in=in3) d.Alphas4(in=in4);
by siccd;
run;

ods html path = 'C:\Users\tpmpi\Desktop\SAS' file='regAlphas.xls';

data d.mergedAlphas1;
set d.mergedalphas (keep = alphas1 alphas2);
run;

/* Regressing the alpha for the years*/

proc reg data= d.mergedAlphas1 PLOTS= (none);
Model alphas2=alphas1;
where alphas1 ne . and alphas2 ne .;
title "Table 1: Regression of Alphas";
plot alphas2 * alphas1; 
run;
quit;

ods html close;
