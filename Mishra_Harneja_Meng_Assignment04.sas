libname d 'C:\Users\tpmpi\Desktop\SAS';
options mprint mautosource sasautos = 'C:\Users\tpmpi\Desktop\SAS\Code';

/* Extracting data from Compustat*/
data d.data1;
set d.comp( keep =lpermno ib dp  fic prcc_f csho  seq pstkrv txditc dvc capx sic at datadate
			rename =(datadate=date lpermno=permno)
			where= (at>0));
	if fic ='USA';
	yr=year(date);
	lag_at = lag(at);
	if permno ne lag(permno) or yr ne lag(yr)+1 then lag_at=.;
	if txditc = . then txditc =0;
/*Calculating Specified Variables*/
if dvc > 0 then Dividend_Dummy =1;
else Dividend_Dummy =0;
Investments = capx/lag_at;
Cashflows = (ib+dp)/lag_at;
MarketEquity = prcc_f * csho;
BookEquity = seq - pstkrv + txditc;
TobinQ = (at + MarketEquity - BookEquity)/at;
lag_Cashflows = lag(Cashflows);
lag_TobinQ = lag(TobinQ);
interaction2 = Dividend_Dummy * Cashflows;
lag_interaction2 = lag(interaction2);
if permno ne lag(permno) or yr ne lag(yr)+1 then do;
lag_Cashflows =.;
lag_TobinQ=.;
lag_interaction2=.;
end;
lag_Dividend_Dummy = lag(Dividend_Dummy);
if permno ne lag(permno) or yr ne lag(yr)+1 then lag_Dividend_Dummy =.;
run;

proc sort data = d.data1; 
by yr;
run;

/*Calculating percentile*/
proc means data = d.data1 noprint;
var MarketEquity;
by yr; 
output out = d.MarketCapdata
p75(MarketEquity)= percentile;
run;

proc sort data = d.MarketCapdata; 
by yr; run;

data d.data2;
merge d.data1(in=in1) d.MarketCapdata(in=in2);
by yr;
if in1 and in2;
run;

proc sort data=d.data2;
by permno yr;
run;
/*Creating proxy for size and interaction for the same*/
data d.dataa2;
set d.data2;
if marketEquity >= percentile then Size_Dummy =1; 
else Size_Dummy =0;
lag_Size_Dummy = lag(Size_Dummy);
interaction1 = Size_Dummy * Cashflows;
lag_interaction1 = lag(interaction1);
if permno ne lag(permno) or yr ne lag(yr)+1 then do;
lag_Size_Dummy=.;
lag_interaction1 =.;
end;
run;

/*Removing outliers using winsorize*/
%winsor (dsetin= d.dataa2,
		 dsetout= d.data3,
		 byvar =none,
		 vars = ib dp  prcc_f csho  seq pstkrv txditc dvc capx  at Investments lag_Cashflows MarketEquity BookEquity lag_TobinQ lag_interaction2 lag_interaction1,
		 type = winsor
		  pctl= 1 99);

proc sort data = d.data3; 
by sic;
run;


proc means data = d.data3 noprint;
by sic;
var lag_TobinQ lag_Cashflows lag_interaction1 lag_interaction2 Size_Dummy Dividend_Dummy;
output out = d.demean_means
mean(lag_TobinQ lag_Cashflows lag_interaction1 lag_interaction2 Size_Dummy Dividend_Dummy Investments)= 
	mean_lag_TobinQ mean_lag_Cashflow mean_lag_interaction1 mean_lag_interaction2 mean_Size_Dummy mean_Dividend_Dummy mean_Investments;
run;

/*Normalizing the data using demean process*/
data d.data4;
merge d.data3(in=in3) d.demean_means(in=in4);
by sic;
if in3 and in4;
demean_Investments = Investments - mean_Investments;
demean_lag_TobinQ = lag_TobinQ - mean_lag_TobinQ;
demean_lag_Cashflow= lag_Cashflows - mean_lag_Cashflow;
demean_lag_interaction1= lag_interaction1 - mean_lag_interaction1;
demean_lag_interaction2= lag_interaction2 - mean_lag_interaction2;
run;

proc sort data= d.data4; by permno yr; run;

/*Regression for Question 1*/
%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data4,
		   output =d.reg1);

/*Regression for Question 2*/
%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow lag_Size_Dummy demean_lag_interaction1,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data4,
		   output =d.reg2);

/*Regression for Question 3*/
%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow lag_Dividend_Dummy demean_lag_interaction2,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data4,
		   output =d.reg3);

/*Splitting the data for into two parts*/

data d.data5;
set d.data4 (where=(yr in(1970:1995)));
run;

data d.data6;
set d.data4 (where=(yr in(1996:2016)));
run;

proc sort data= d.data5; by permno yr; run;
proc sort data= d.data6; by permno yr; run;

/*Regression for Q4*/
%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data5,
		   output =d.reg4a);

%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data6,
		   output =d.reg4b);

/*Regression for Question 5*/

%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow lag_Size_Dummy demean_lag_interaction1,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data5,
		   output =d.reg5a);

%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow lag_Size_Dummy demean_lag_interaction1,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data6,
		   output =d.reg5b);

/*Regression for Question 6*/

%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow lag_Dividend_Dummy demean_lag_interaction2,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data5,
		   output =d.reg6a);

%REG2DSE (y=demean_Investments,
		   x =demean_lag_TobinQ demean_lag_Cashflow lag_Dividend_Dummy demean_lag_interaction2,
		   firm=permno,
		   time= yr,
		   multi=0,
		   dataset=d.data6,
		   output =d.reg6b);


/*Exporting data to excel*/

	proc export data = d.reg1 dbms=xlsx
            outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q1";

	proc export data = d.reg2 dbms=xlsx
            outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q2";

	proc export data = d.reg3 dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q3";

	proc export data = d.reg4a dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q4a";

	proc export data = d.reg4b dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q4b";

	proc export data = d.reg5a dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q5a";

	proc export data = d.reg5b dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q5b";

	proc export data = d.reg6a dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q6a";

	proc export data = d.reg6b dbms=xlsx
	        outfile = 'C:\Users\tpmpi\Desktop\SAS\regression.xlsx' replace;
			sheet="Q6b";









