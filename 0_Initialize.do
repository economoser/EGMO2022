********************************************************************************
* DESCRIPTION: Initializes program by creating global macros.
*
* AUTHORS:     Niklas Engbom (New York University),
*			   Gustavo Gonzaga (PUC-Rio),
*			   Christian Moser (Columbia University),
*			   Roberta Olivieri (Cornell University).
*
* PLEASE CITE: Engbom, Niklas & Gustavo Gonzaga & Christian Moser & Roberta
*              Olivieri. "Earnings Inequality and Dynamics in the Presence
*              of Informality: The Case of Brazil," Quantitative Economics,
*              2022.
*
* TIME STAMP:  March 26, 2022.
********************************************************************************

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This code specify country-specific variables.  
// This version Jan 26, 2022
//	Halvorsen, Ozkan, Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// PLEASE DO NOT CHANGE VALUES FRM LINE 7 TO 20. IF NEEDS TO BE CHANGED, CONTACT Ozkan/Salgado

set more off
set matsize 500
set linesize 255
version 13  // This program uses Stata version 13. 

global begin_age = 25 		// Starting age
global end_age = 55			// Ending age
global base_price = 2018	// The base year nominal values are converted to real. 
global winsor=99.999999		// The values above this percentile are going to be set to this percentile. 
global noise=0.0			// Noise added to income. See line 112 in 1_Gen_Base_Sample.do


// PLEASE MAKE THE APPROPRIATE CHANGES BELOW. 

global unix=1  // Please change this to 1 if you run stata on Unix or Mac

global wide=0  // Please change this to 1 if your raw data is in wide format; 0 if long.
 
if($unix==1){
	global sep="/"
}
else{
	global sep="\"
}
// If there are missing observations for earnings between $begin_age and $end_age
// set the below global to 1. Otherwise, the code will convert all missing earnings
// observations to zero.
// Note: For Brazil, missing in RAIS means no formal job, which we want to record as 0 (formal-sector) income, so global miss_earn = 0.
// global miss_earn = 0
global miss_earn = 1 // note: we found that global miss_earn = 0 produces too many zeros in summary stats and mobility analysis (and probably elsewhere, too) so we will try global miss_earn = 1 now, as of January 30, 2021 (and again around October 2021)

//Please change the below to the name of the actual data set
// global maindir = "/Users/cm3594/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/3_code"
global datafile="${maindir}${sep}dta${sep}data_long" 

// Define the variable names in your dataset.
global personid_var="persid" // The variable name for person identity number.
global male_var="gender" 	// The variable name for gender: 1 if male, 0 o/w.
global yob_var="yob" 		// The variable name for year of birth.
global yod_var="yod" 		// The variable name for year of death.
global educ_var="edu" 		// The variable name for education.
global labor_var="earn_mean_mw" // The variable name for total annual labor earnings from all jobs during the year. Note: variable "earn_mean_mw" contains earnings in a given job, but we replace it with total annual earnings from all jobs in a given year in code "1_Gen_Base_Sample.do".
global year_var="year" 		// The variable name for year if the data is in long format.
global muni_var="muni" 		// The variable name for municipality.
scalar def educ_typ=2   /*Define the type of variable for education 1=string; 2=numerical*/
global iso = "BRA" 		// Define the 3-letters code of the country. Use ISO codes. For instance 
						// for Italy use ITA, for Spain use ESP, for Norway use NOR and so on
global minnumberobs = 0 // Define the minimum number of observations in a cell. If the min number of obs is not 
						// satisfied, all moments calculated with that subsample are replaced by missing.
						
// Define these variables for your dataset
global yrfirst = ${year_min} 		// First year in the dataset 
global yrlast =  ${year_max} 		// Last year in the dataset

global kyear = 5
	// This controls the years for which the empirical densities will be calculated.
	// The densisity is calculated every mod(year/kyear) == 0. Set to 1 if 
	// every year is needed (If need changes, contact  Ozkan/Salgado)
	
global nquantiles = 40
	// Number of quantiles used in the statistics conditioning on permanent income
	// One additional quintile will be added at the top for a total of 41 (see Guidelines)
		
global nquantilemob = 40
	// Number of quantiles used in the rank-rank mobility measures.
	
global qpercent = 99	
	// Top percentile for which the change in top-share will be calculated. 
	// In this case 99 implies top 1%. 
	// Calculations are made using  Matthieu Gomez's paper
	
global mergecohort = 2
	// Number of cohorts to be merged to prevent too few observations in year/age cells 
	
global hetgroup = `" male age educ "male age" "male educ" "age educ" "male educ age" "' 
	// Define heterogenous groups for which time series stats will be calculated 

// Price index for converting nominal values to real, e.g., the PCE for the US.  
// IMPORTANT: Please set the LOCAL CPI starting from year ${yrfirst} and ending in ${yrlast}.

local cpi1985= 0.0000000002796
local cpi1986= 0.000000000691
local cpi1987= 0.000000002269
local cpi1988= 0.00000001654
local cpi1989= 0.0000002532
local cpi1990= 0.000007718
local cpi1991= 0.00004112
local cpi1992= 0.00043256
local cpi1993= 0.00876972
local cpi1994= 0.19081938
local cpi1995= 0.31677358
local cpi1996= 0.36668971
local cpi1997= 0.39208925
local cpi1998= 0.4046168
local cpi1999= 0.42427489
local cpi2000= 0.45416142
local cpi2001= 0.48522769
local cpi2002= 0.52623022
local cpi2003= 0.60366458
local cpi2004= 0.64348945
local cpi2005= 0.6876942
local cpi2006= 0.71646435
local cpi2007= 0.74255277
local cpi2008= 0.78471933
local cpi2009= 0.82307668
local cpi2010= 0.86454927
local cpi2011= 0.92192465
local cpi2012= 0.97174084
local cpi2013= 1.0320307
local cpi2014= 1.0973483
local cpi2015= 1.1964378
local cpi2016= 1.3009962
local cpi2017= 1.3458334
local cpi2018= 1.3951561
global cpi2018 = `cpi2018' // Set the value of the CPI in 2018.
forval y = $yrfirst/$yrlast {
	if `y' == $yrfirst local cpi_list = "`cpi`y''"
	else local cpi_list = "`cpi_list', `cpi`y''"
}
matrix cpimat = (`cpi_list')' // CPI between ${yrfirst}  and ${yrlast}

matrix cpimat = cpimat/${cpi2018}

global exrate2018 = 1.3951561

local exrate1985= 0.0000000002796
local exrate1986= 0.000000000691
local exrate1987= 0.000000002269
local exrate1988= 0.00000001654
local exrate1989= 0.0000002532
local exrate1990= 0.000007718
local exrate1991= 0.00004112
local exrate1992= 0.00043256
local exrate1993= 0.00876972
local exrate1994= 0.19081938
local exrate1995= 0.31677358
local exrate1996= 0.36668971
local exrate1997= 0.39208925
local exrate1998= 0.4046168
local exrate1999= 0.42427489
local exrate2000= 0.45416142
local exrate2001= 0.48522769
local exrate2002= 0.52623022
local exrate2003= 0.60366458
local exrate2004= 0.64348945
local exrate2005= 0.6876942
local exrate2006= 0.71646435
local exrate2007= 0.74255277
local exrate2008= 0.78471933
local exrate2009= 0.82307668
local exrate2010= 0.86454927
local exrate2011= 0.92192465
local exrate2012= 0.97174084
local exrate2013= 1.0320307
local exrate2014= 1.0973483
local exrate2015= 1.1964378
local exrate2016= 1.3009962
local exrate2017= 1.3458334
local exrate2018= 1.3951561
forval y = $yrfirst/$yrlast {
	if `y' == $yrfirst local exrate_list = "`exrate`y''"
	else local exrate_list = "`exrate_list', `exrate`y''"
}
matrix exrate = (`exrate_list')' // Nominal average exchange rate from FRED between ${yrfirst}  and ${yrlast} (LC per dollar)


// Define years for recession bars/ These will be used to generate a variable called rece used in the plots
global receyears = "1987,1988,1989,1990,1991,1992,1995,1998,1999,2001,2003,2008,2009,2014,2015,2016"

// NOTE: manual classification based on two sources:
// 1985-1995 from FRED: https://fred.stlouisfed.org/series/RGDPNABRA666NRUG
// 1996-2017 from FRED: https://fred.stlouisfed.org/series/BRAREC

// 	gen rece = 0.00
// 	replace rece = 0.00 if year == 1985
// 	replace rece = 0.00 if year == 1986
// 	replace rece = 0.50 if year == 1987
// 	replace rece = 1.00 if year == 1988
// 	replace rece = 0.50 if year == 1989
// 	replace rece = 1.00 if year == 1990
// 	replace rece = 1.00 if year == 1991
// 	replace rece = 0.25 if year == 1992
// 	replace rece = 0.00 if year == 1993
// 	replace rece = 0.00 if year == 1994
// 	replace rece = 0.50 if year == 1995
// 	replace rece = 0.00 if year == 1996
// 	replace rece = 0.00 if year == 1997
// 	replace rece = 1.00 if year == 1998
// 	replace rece = 0.25 if year == 1999
// 	replace rece = 0.00 if year == 2000
// 	replace rece = 0.75 if year == 2001
// 	replace rece = 0.00 if year == 2002
// 	replace rece = 0.50 if year == 2003
// 	replace rece = 0.00 if year == 2004
// 	replace rece = 0.00 if year == 2005
// 	replace rece = 0.00 if year == 2006
// 	replace rece = 0.00 if year == 2007
// 	replace rece = 0.25 if year == 2008
// 	replace rece = 0.25 if year == 2009
// 	replace rece = 0.00 if year == 2010
// 	replace rece = 0.00 if year == 2011
// 	replace rece = 0.00 if year == 2012
// 	replace rece = 0.00 if year == 2013
// 	replace rece = 0.75 if year == 2014
// 	replace rece = 1.00 if year == 2015
// 	replace rece = 1.00 if year == 2016
// 	replace rece = 0.00 if year == 2017


// Define the year that will be use for normalization. 
global normyear = ${year_norm}


/*DO NOT CHANGE THIS SECTION**********************************************
THIS SECTION DEFINES THE REAL EXCHANGE CHANGE USING THE LOCAL AND US CPI
*/
global cpi2018us = 108.231		// DO NOT CHANGE. This is the US PCE  
								// Annual average from https://fred.stlouisfed.org/series/PCEPI#0
matrix cpimatus = /*  PCE between 1970  and 2018
*/ (20.951, 21.841, 22.586, 23.802, 26.280, 28.470, 30.032, 31.986, 34.211, 37.250,  /*
*/ 41.262, 44.959, 47.456, 49.475, 51.343, 53.134, 54.290, 55.964, 58.150, 60.690,  /*
*/ 63.355, 65.473, 67.218, 68.892, 70.330, 71.811, 73.346, 74.623, 75.216, 76.338, /*
*/ 78.235, 79.738, 80.789, 82.358, 84.411, 86.813, 89.174, 91.438, 94.180, 94.094,  /*
*/ 95.705, 98.130, 100.000, 101.347, 102.868, 103.126, 104.235, 106.073, 108.231 )'

matrix cpimatus = cpimatus/${cpi2018us}

forvalues yr =  $yrfirst/$yrlast{
	local ee = `yr' - ${yrfirst} + 1
	local ii = `yr' - 1970 + 1
	matrix exrate[`ee',1] = exrate[`ee',1]*(cpimatus[`ii',1]/cpimat[`ee',1])
			// Coverting nominal exchange rate to real exchange rate
}
**********************************************

*** MINIMIN INCOME THRESHOLDS

global set_rmininc = 3 // Note: For Brazil, set = 3 because we manually drop total annual earnings < 1.5*monthly minimum wage in line 115 of 1_Gen_Base_Sample.do!

// Set to 1: 
// If you want to use US min wages to create the minimum income threshold. 
// If your country does not have a minimum wage, and you want to use the US specific threshold
// then set set_rmininc = 1

// Set to 2:
// If your country has a minimum wage 

// Set to 3:
// If you want to use a percentage criterion or a particular custom value, then you need to specify those rmininc values below.



if ${set_rmininc} == 1{
	
	// CREATING MINIMUM INCOME THRESHOLD USING US MINIMUM WAGE  
	matrix minwgus = /* Nominal minimum wage 1959-2018 in the US
	*/ (1.00,1.00,1.00,1.15,1.15,1.25,1.25,1.25,1.25,1.40,1.60,1.60,1.60,1.60,/*
	*/  1.60,1.60,2.00,2.10,2.10,2.30,2.65,2.90,3.10,3.35,3.35,3.35,3.35,3.35,/*
	*/  3.35,3.35,3.35,3.35,3.80,4.25,4.25,4.25,4.25,4.25,4.75,5.15,5.15,5.15,/*
	*/  5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.85,6.55,7.25,7.25,7.25,7.25,7.25,/*
	*/  7.25,7.25,7.25)'

	local yinic = ${yrfirst} - 1959 + 1						
	local yend = ${yrlast} - 1959 + 1

	matrix minincus = 260*minwgus[`yinic'..`yend',1]		// Nominal min income in the US
															// This uses the factor of 260 given in the Guidelines
	matrix rmininc = J(${yrlast}-${yrfirst}+1,1,0)
	local tnum = ${yrlast}-${yrfirst}+1

	forvalues i = 1(1)`tnum'{
		local ii = `i' + ${yrfirst} - 1970
		matrix rmininc[`i',1] = minincus[`i',1]*${exrate2018}/cpimatus[`ii',1]				
						// real min income threshold in local currency 
	}
	
}
else if ${set_rmininc} == 2{
	
	// CREATING MINIMUM INCOME THRESHOLD USING COUNTRY SPECIFIC MINIMUM WAGE  
	
	matrix minwg_C = /* Nominal minimum wage 1959-2018 in YOUR COUNTRY
	*/ (1.00,1.00,1.00,1.15,1.15,1.25,1.25,1.25,1.25,1.40,1.60,1.60,1.60,1.60,/*
	*/  1.60,1.60,2.00,2.10,2.10,2.30,2.65,2.90,3.10,3.35,3.35,3.35,3.35,3.35,/*
	*/  3.35,3.35,3.35,3.35,3.80,4.25,4.25,4.25,4.25,4.25,4.75,5.15,5.15,5.15,/*
	*/  5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.85,6.55,7.25,7.25,7.25,7.25,7.25,/*
	*/  7.25,7.25,7.25)'

	// Change 1959 to the first year in your minwg_C matrix
	local yinic = ${yrfirst} - 1959 + 1	
	local yend = ${yrlast} - 1959 + 1

	matrix mininc_C = 260*minwg_C[`yinic'..`yend',1]		// Nominal min income in the US
															// This uses the factor of 260 given in the Guidelines
	matrix rmininc = J(${yrlast}-${yrfirst}+1,1,0)
	local i = 1
	local tnum = ${yrlast}-${yrfirst}+1
	forvalues pp = 1(1)`tnum'{
		matrix rmininc[`i',1] = 100*mininc_C[`i',1]/cpimat[`i',1]					
						// real min income threshold in local currency 
		local i = `i' + 1
	}
}	
else if ${set_rmininc} == 3{
	// CREATING MINIMUM INCOME THRESHOLD USING CUSTOM VALUES 
	// (E.G., the bottom 23% of the gender, combined earnings distribution, etc.)  
	
	// NOTE: All values above are = 0 because we manually drop total annual earnings < 1.5*monthly minimum wage in line 115 of 1_Gen_Base_Sample.do!
	
	matrix rmininc = /* REAL MINIMUM INCOME THRESHOLD ${yrfirst}-${yrlast} in YOUR COUNTRY -- BRAZIL 1985-2018
	*/ (0,0,0,0,0,0,/*
	*/  0,0,0,0,0,0,0,0,0,0,/*
	*/  0,0,0,0,0,0,0,0,0,0,/*
	*/  0,0,0,0,0,0,0,0)'
}

// PLEASE DO NOT CHANGE THIS PART. IF NEEDS TO BE CHANGED, CONTACT Ozkan/Salgado


*global yrlist = ///
*	"${yrfirst} 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ${yrlast}"
*	// Define the years for which the inequality and concetration measures are calculated

global  yrlist = ""
forvalues yr = $yrfirst(1)$yrlast{
	global yrlist = "${yrlist} `yr'"
}		
	
*global d1yrlist = ///
*	"1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012"
	// Define years for which one-year log-changes measures are calculated

global d1yrlist = ""
local tempyr = $yrlast-1
forvalues yr = $yrfirst(1)`tempyr'{
	global d1yrlist = "${d1yrlist} `yr'"
}
	
*global d5yrlist = ///
*	"1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008"
	// Define years t for which five-years log-changes between t+5 and t are calculated
	
global d5yrlist = "$yrfirst"
local tempyrb = $yrfirst+1
local tempyr = $yrlast-5
forvalues yr = `tempyrb'(1)`tempyr'{
	local tmp = ",`yr'"
	global d5yrlist = "${d5yrlist}`tmp'"
}	
	
*global perm3yrlist = /// 
*	"1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,${yrlast}"
	// Define the ending years (t) to construct permanent income between t-2 and t 
	
local tempyrb = $yrfirst+2	
global perm3yrlist = "`tempyrb'"
local tempyrb = $yrfirst+3	
local tempyre = $yrlast
forvalues yr = `tempyrb'(1)`tempyre'{
	local tmp = ",`yr'"
	global perm3yrlist = "${perm3yrlist}`tmp'"
}	

