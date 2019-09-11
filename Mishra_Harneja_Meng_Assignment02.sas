	libname d 'C:\Users\tpmpi\Desktop\SAS';

	data d.CRSPData;
	set d.CRSP (keep = permno date ret siccd 
				where = (ret le 1));
	y = year(date);
	m = month(date);
	numeric_date = 100*y +m;
	run;

	%global f;
	%global g;
	run;


	proc import datafile= 'C:\Users\tpmpi\Desktop\SAS\CRSP_SIC_FF12'
	dbms = xlsx out = d.CRSPFIC
	replace;
	run;

	proc import datafile= 'C:\Users\tpmpi\Desktop\SAS\NBER_Recession_Indicator'
	dbms = xlsx out = d.NBERIndicator replace;
	run;

	proc sort data =d.CRSPData;
	by numeric_date;
	run;

	proc sort data = d.NBERIndicator;
	by numeric_date;
	run;

	proc sort data = d.CRSPFIC; 
	by siccd;
	run;

	data d.newdset;
	merge d.CRSPData(in=in_crsp) d.NBERIndicator;
	by numeric_date;
	if in_crsp =1;
	run;

	proc sort data=d.newdset;
	by siccd;
	run;

	data d.newdset1;
	merge d.newdset (in=in1) d.CRSPFIC;
	by siccd;
	if in1;
	run;
/* to separate data during expansion*/
	data d.recZero;
	set d.newdset1 ( where= (recession eq 0));
	run;

/* to separate data during recession*/
	data d.recOne;
	set d.newdset1(where =(recession eq 1));
	run;

/* Sorting the above data*/

	proc sort data =d.recZero;
	by ret;
	run;

	proc sort data= d.recOne;
	by ret;
	run;
/*ods html path="C:\Users\tpmpi\Desktop\SAS" file="results.xls";*/
/* to check whther returns in recession is less than zero*/
	proc ttest data= d.recZero;
	var ret;
	title "Returns during recession";
	run;

/* to check whther returns in expansion is greater than one*/
	proc ttest data =d.recOne;
	var ret;
	title "returns during expansion";
	run;

/* Q2. Two sample t-test of difference in mean returns */
    proc sort data =d.newdset1;
    by recession;
    run;

		
   proc means data= d.newdset1 mean;
   by recession;
   var ret;
   run;

  
   proc ttest data = d.newdset1 
			  H0=0 
			  alpha=0.01
              plots= (none);
   class recession;
   var ret; 
   title "comparison of returns during recession and expansion";
   run;
	/*Q3. Difference of average returns of the fama french sectors having the maximum and minimum returns are significantly 
		different from zero*/
    proc sort data =d.newdset1;
    by fama_french_sector;
    run;

	proc means data= d.newdset1 noprint;
	var ret;
	by fama_french_sector;
	output out = d.ffmeans
	mean(ret)=ffretmean;
	run;

	/*to get data during recession*/
	data d.recdset;
	set d.newdset1 (where = ((recession eq 1) and (fama_french_sector^=.)));
	run;

	proc sort data =d.recdset;
    by fama_french_sector;
    run;

	/* Calculating the average returns by sector*/
	proc means data= d.recdset noprint;
	var ret;
	by fama_french_sector;
	output out = d.sortrecdmeans
	mean(ret)=ffretmean;
	run;

	/*Sort the aboive averages to get the sector with maximum and minimum average returns*/
	proc sort data = d.sortrecdmeans;
	by ffretmean;
	run;
	
	/*Dataset for Average returns for the sector with maximum average returns*/
	data d.maxFF;
	set d.recdset(where=(fama_french_sector=4));
	rename ret=retMaxFF;
	rename fama_french_sector=ffmax;
	run;

	/*Dataset for average returns for the sector with minimum average */
	data d.minFF;
	set d.recdset(where=(fama_french_sector=8));
	rename ret=retMinFF;
	rename fama_french_sector=ffmin;
	run;

	proc sort data =d.maxFF;
	by date;
	run;

	proc sort data = d.minFF;
	by date;
	run;
	
	/*Merge the data for sectors with maximum and minimum average returns*/
	data d.mergeFF;
	merge d.maxFF(in=in1) d.minFF(in=in2);
	by date;
	if in1^=. and in2^=.;
	diff_ret = retMaxFF-retMinFF;
	run;

	data d.mergeFF1;
	set d.mergeFF(where= (retMaxFF ne . or retMinFF ne .));
	run;
 
	/*Paired ttest*/
	proc ttest data = d.mergeFF1 alpha=0.01 plots=(none);
	 paired retMaxFF*retMinFF;
	 title"Comparison of sectors with maximum and minimum returns during recession";
	run;

	
/*Q4. Difference of average returns of the fama french sectors during expansion having the maximum and minimum returns are significantly 
		different from zero*/
    proc sort data =d.newdset1;
    by fama_french_sector;
    run;

	proc means data= d.newdset1 noprint;
	var ret;
	by fama_french_sector;
	output out = d.ffmeans1
	mean(ret)=ffretmean;
	run;

	/*to get data during expansion*/
	data d.recdset1;
	set d.newdset1 (where = ((recession eq 0) and (fama_french_sector^=.)));
	run;

	proc sort data =d.recdset1;
    by fama_french_sector;
    run;

	/* Calculating the average returns by sector*/
	proc means data= d.recdset1 noprint;
	var ret;
	by fama_french_sector;
	output out = d.sortrecdmeans1
	mean(ret)=ffretmean;
	run;

	/*Sort the aboive averages to get the sector with maximum and minimum average returns*/
	proc sort data = d.sortrecdmeans1;
	by ffretmean;
	run;
	
	/*Dataset for Average returns for the sector with maximum average returns*/
	data d.maxFF1;
	set d.recdset1(where=(fama_french_sector=3));
	rename ret=retMaxFF;
	rename fama_french_sector=ffmax;
	run;

	/*Dataset for average returns for the sector with minimum average */
	data d.minFF1;
	set d.recdset1(where=(fama_french_sector=10));
	rename ret=retMinFF;
	rename fama_french_sector=ffmin;
	run;

	proc sort data =d.maxFF1;
	by date;
	run;

	proc sort data = d.minFF1;
	by date;
	run;
	
	/*Merge the data for sectors with maximum and minimum average returns*/
	data d.mergeFF2;
	merge d.maxFF1(in=in1) d.minFF1(in=in2);
	by date;
	if in1^=. and in2^=.;
	diff_ret = retMaxFF-retMinFF;
	run;

	data d.mergeFF3;
	set d.mergeFF2(where= (retMaxFF ne . or retMinFF ne .));
	run;
 
	/*Paired ttest*/
	proc ttest data = d.mergeFF3 alpha=0.01 plots=(none);
	 paired retMaxFF*retMinFF;
	 title"Comparison of sectors with maximum and minimum returns during expansion";
	run;
 /*ods html close;*/
