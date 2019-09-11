libname d 'C:\Users\tpmpi\Desktop\SAS';

data d.a2;
/* Cleaning the data to keep the required variables and satisfy criteria*/
	set d.comp( keep = lpermno capx at che ib revt dltt dlc dvc datadate sic fic
				rename =(lpermno=permno datadate=date)
				where=(year(date) ge 1975 and year(date) le 2016)
				);
	if sic not in (6000:6999);
	if fic ='USA';
	if at >0 and revt >0;
/*Calculating lagged assets*/
	lagat = lag(at);
	if permno ne lag(permno) or
		year(date) ne (lag(year(date))+1) then lagat =.;
/*Calculating the diffrent variables required for analysis*/
	Investments = capx/lagat;
	Profitability = ib/revt;
	Liquidity = che/at;
	Leverage = (dltt+dlc)/at;
	Dividends = dvc/lagat;
	yr = year(date);
	run;

/*Sorting the data by year*/
	proc sort data = d.a2 out=sortedData;
	by yr;
	run;
ods html path="C:\Users\tpmpi\Desktop\SAS" file="summary.xls";

/* Generating the summary statisticsand saving it in summary.xls*/
	proc means data = sortedData mean std p5 p25 p50 p75 p95;
	var Investments Profitability Liquidity Leverage Dividends;
	title "Table 1: Summary Statistics";
	run;
ODS html CLOSE;
/*Calculating the annual average of the variables*/
	proc means data = sortedData noprint;
	var Investments Profitability Liquidity Leverage Dividends yr;
	by yr;
	output out = d.annual_leverage_means_file
			mean(Investments) = InvestementByYear
			mean(Profitability) = ProfitabilityByYear
			mean(Liquidity) = LiquidityByYear
			mean(Leverage) = LeverageByYear
			mean(Dividends) = DividendsByYear;
		run;

/*Calculating the annual medians of variables*/
	proc means data = sortedData noprint;
	var Investments Profitability Liquidity Leverage Dividends yr;
	by yr;
	output out = d.annual_leverage_medians_file
			median(Investments) = InvestementByYear
			median(Profitability) = ProfitabilityByYear
			median(Liquidity) = LiquidityByYear
			median(Leverage) = LeverageByYear
			median(Dividends) = DividendsByYear;
		run;
	/* For the mean plots*/		
ODS rtf file = "C:\Users\tpmpi\Desktop\SAS\Graphs.rtf";
	proc sgplot data = d.annual_leverage_means_file;
	series x=yr y=InvestementByYear /markers;
	title "Graph 1: Mean of Investments";
	yaxis label = "Mean Investments" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	
	proc sgplot data = d.annual_leverage_means_file;
	series x=yr y=ProfitabilityByYear /markers;
	title "Graph 2:Mean of Profitability";
	yaxis label = "Mean Profitability" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	proc sgplot data = d.annual_leverage_means_file;
	series x=yr y=LeverageByYear /markers;
	title "Graph 3:Mean of Leverage";
	yaxis label = "Mean Leverage" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	proc sgplot data = d.annual_leverage_means_file;
	series x=yr y=LiquidityByYear /markers;
	title "Graph 4:Mean of Liquidity";
	yaxis label = "Mean Liquidity" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	proc sgplot data = d.annual_leverage_means_file;
	series x=yr y=DividendsByYear /markers;
	title "Graph 5:Mean of Dividends";
	yaxis label = "Mean Dividends" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	/* For the medians plots*/		
	proc sgplot data = d.annual_leverage_medians_file;
	series x=yr y=InvestementByYear /markers;
	title "Graph 6:Median of Investments";
	yaxis label = "Median Investment" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	
	proc sgplot data = d.annual_leverage_medians_file;
	series x=yr y=ProfitabilityByYear /markers;
	title "Graph 7:Median of Profitability";
	yaxis label = "Median Profitability" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	proc sgplot data = d.annual_leverage_medians_file;
	series x=yr y=LeverageByYear /markers;
	title "Graph 8:Median of Leverage";
	yaxis label = "Median Leverage" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	proc sgplot data = d.annual_leverage_medians_file;
	series x=yr y=LiquidityByYear /markers;
	title "Graph 9:Median of Liquidity";
	yaxis label = "Median Liquidity" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	proc sgplot data = d.annual_leverage_medians_file;
	series x=yr y=DividendsByYear /markers;
	title "Graph 10:Median of Dividends";
	yaxis label = "Median Dividends" grid;
	xaxis label = "Year" Values =(1970 to 2015 by 5);
	run; quit;

	ODS rtf close;
	
