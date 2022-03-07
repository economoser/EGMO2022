********************************************************************************
* DESCRIPTION: Compute descriptive statistics.
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
* TIME STAMP:  March 5, 2022.
********************************************************************************

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the descriptive statistics 
// This version July 17, 2020
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
// You should change the below directory. 
// global maindir ="..."

// Do not make change from here on. Contact Ozkan/Salgado if changes are needed. 
do "${maindir}/do/0_Initialize.do"

// Create folder for output and log-file
// global outfolder = c(current_date)
// if substr("${outfolder}", 1, 1) == " " global outfolder = "0" + substr("${outfolder}", 2, .)
global outfolder = "09 Feb 2022"
global outfolder="$outfolder Descriptive_Stat"
capture noisily mkdir "${maindir}${sep}out${sep}$outfolder"
cap log close
cap n log using "${maindir}${sep}log${sep}$outfolder.log", replace

// Cd to the output file, create the program for moments, and load base sample.
cd "${maindir}${sep}out${sep}$outfolder"
do "${maindir}${sep}do${sep}myprogs.do"		

timer clear 1
timer on 1

// Loop over samples
foreach spl in CS LX H{

// Loop over the years
if "`spl'" == "CS" {
	local fsrtyr = $yrfirst
	local lastyr = $yrlast
}
else if "`spl'" == "LX" {
	local fsrtyr = $yrfirst
	local lastyr = $yrlast - 5		// So 5 year changes are present in the sample
}
else if "`spl'" == "H" {
	local fsrtyr = $yrfirst + 3		// So perm   income is present in the sample
	local lastyr = $yrlast - 5		// So 5 year change is present in the sample
}

forvalues yr = `fsrtyr'/`lastyr'{
*foreach yr of numlist $yrlist{

	disp("Working in year `yr' for Sample `spl'")
	if "`spl'" == "CS" {
		use  male yob educ labor`yr' using ///
			"${TEMP_DIR}${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear  	
	}
	else if "`spl'" == "LX" {
		use  male yob educ labor`yr' researn1F`yr' researn5F`yr' using ///
			"${TEMP_DIR}${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear  	
	}
	else if "`spl'" == "H" {
		local yrp = `yr'-1
		use  male yob educ labor`yr' researn1F`yr' researn5F`yr' permearn`yrp' using ///
			"${TEMP_DIR}${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear  	
	}
	
	// Create year
	gen year=`yr'
	
	// Create age (This applies to all samples)
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}
	
	// Select CS sample (Individual has earnings above min treshold)
	if "`spl'" == "CS"{
		qui: keep if labor`yr'>=rmininc[`yr'-${yrfirst}+1,1] & labor`yr'!=. 
	}
	
	// Select LX sample (Individual has 1 and 5 yr residual earnings change)
	if "`spl'" == "LX"{
		qui: keep if researn1F`yr'!=. & researn5F`yr'!= . 
	}
	
	// Select H sample (Individual has permanent income measure)
	if "`spl'" == "H"{
		qui: keep if researn1F`yr'!=. & researn5F`yr'!= . 
		qui: keep if permearn`yrp' != . 
	}
	
	// Transform to US dollars
	local er_index = `yr'-${yrfirst}+1
	qui: replace labor`yr' = labor`yr'/${exrate2018}
	
	// Calculate cross sectional moments for year `yr'
	rename labor`yr' labor 	
	
	bymysum "labor" "L_" "_`yr'" "year"
	bymysum "labor" "L_" "_male`yr'" "year male"
	
	bymyPCT "labor" "L_" "_`yr'" "year"
	bymyPCT "labor" "L_" "_male`yr'" "year male"
	
	${gtools}collapse (count) numobs = labor, by(year male educ age) fast
	order year male educ age numobs
	qui: save "numobs`yr'.dta", replace
	
} // END of loop over years

* Collects number of observations data across years (for what did we need this?)
clear
forvalues yr = `fsrtyr'/`lastyr'{
	append using "numobs`yr'.dta"
	erase "numobs`yr'.dta"	
}
outsheet using "${maindir}${sep}out${sep}$outfolder/`spl'_cross_tabulation.csv", replace comma


// Collects descriptive statistics across years

clear
forvalues yr = `fsrtyr'/`lastyr'{
	use "S_L_labor_`yr'.dta"
	merge 1:1 year using "PC_L_labor_`yr'.dta",  nogenerate 
	
	erase "S_L_labor_`yr'.dta"
	erase "PC_L_labor_`yr'.dta"
	save "L_labor_`yr'.dta", replace 
	
	use "S_L_labor_male`yr'.dta"
	merge 1:1 year male using "PC_L_labor_male`yr'.dta", nogenerate 
	
	erase "S_L_labor_male`yr'.dta"
	erase "PC_L_labor_male`yr'.dta"
	save "L_labor_male`yr'.dta", replace 
}

clear 
forvalues yr = `fsrtyr'/`lastyr'{
	append using "L_labor_`yr'.dta"
	erase "L_labor_`yr'.dta"
}
outsheet using "${maindir}${sep}out${sep}$outfolder/L_`spl'_labor_yr_sum_stats.csv", replace comma

clear 
forvalues yr = `fsrtyr'/`lastyr'{
	append using "L_labor_male`yr'.dta"
	erase "L_labor_male`yr'.dta"
}
outsheet using "${maindir}${sep}out${sep}$outfolder/L_`spl'_labor_yrgender_sum_stats.csv", replace comma
	
} // END of loop over samples 

*Save the age education dummies for residual log earnings
use "${maindir}${sep}dta${sep}age_educ_dums.dta", clear
outsheet using "${maindir}${sep}out${sep}$outfolder/age_educ_dums.csv", replace comma

*Save the age education dummies for residual log earnings
use "${maindir}${sep}dta${sep}age_dums.dta", clear
outsheet using "${maindir}${sep}out${sep}$outfolder/age_dums.csv", replace comma


*** additional summary statistics for RAIS
* define list of years for which to compute summary statistics
local sum_stats_year_list = "1985 1996 2007 2018"

* create list of variables to load
local var_earn_list = ""
local cond_list = "INITIATE"
foreach y of local sum_stats_year_list {
	local var_earn_list = "`var_earn_list' labor`y' logearn`y'"
	local cond_list = "`cond_list' | logearn`y' < ."
}
local cond_list = subinstr("`cond_list'", "INITIATE | ", "", .)

* load data
use ///
	male yob educ `var_earn_list' ///
	if `cond_list' ///
	using "${TEMP_DIR}${sep}dta${sep}master_sample.dta", clear

* rename variables
foreach y of local sum_stats_year_list {
	rename labor`y' earn_`y'
	rename logearn`y' earn_log_`y'
}
	
* set level earnings to missing when log earnings do not satisfy selection criteria
foreach y of local sum_stats_year_list {
	replace earn_`y' = . if earn_log_`y' == .
}

* generate male indicator
foreach y of local sum_stats_year_list {
	gen byte male_`y' = male if earn_log_`y' < .
	label var male_`y' "Ind: Male in `y'?"
}
drop male

* generate female indicator
foreach y of local sum_stats_year_list {
	gen byte female_`y' = 1 - male_`y'
	label var female_`y' "Ind: Female in `y'?"
}

* create label
local m0 = " for women"
local m1 = " for men"

* generate age
foreach m in 0 1 {
	foreach y of local sum_stats_year_list {
		gen byte age_`y'_`m' = `y' - yob + 1 if earn_log_`y' < . & male_`y' == `m'
		if `m' == 0 label var age_`y'_`m' "Age in `y'`m`m''"
		else if `m' == 1 label var age_`y'_`m' "Age in `y'`m`m''"
	}
}
drop yob

* generate education indicators
foreach m in 0 1 {
	forval e = 2/4 {
		foreach y of local sum_stats_year_list {
			gen byte educ_`e'_`y'_`m' = (educ == `e') if educ < . & earn_log_`y' < . & male_`y' == `m'
			if `e' == 2 label var educ_2_`y'_`m' "Ind: Middle school in `y'`m`m''?"
			else if `e' == 3 label var educ_3_`y'_`m' "Ind: High school in `y'`m`m''?"
			else if `e' == 4 label var educ_4_`y'_`m' "Ind: College in `y'`m`m''?"
		}
	}
}
drop educ

* create gender-specific earnings
foreach y of local sum_stats_year_list {
	foreach m in 0 1 {
		gen float earn_`y'_`m' = earn_`y' if male_`y' == `m'
		label var earn_`y'_`m' "Earnings in year `y'`m`m''"
	}
	drop earn_`y'
}

* create gender-specific log earnings
foreach y of local sum_stats_year_list {
	foreach m in 0 1 {
		gen float earn_log_`y'_`m' = earn_log_`y' if male_`y' == `m'
		label var earn_log_`y'_`m' "Log earnings in year `y'`m`m''"
	}
	drop earn_log_`y'
}

* compress, describe, and summarize
compress
desc
sum, sep(0)

* collapse to form means
local collapse_str = ""
foreach y of local sum_stats_year_list {
	local collapse_str = "`collapse_str' (mean) male_share_`y'=male_`y' female_share_`y'=female_`y'"
	local collapse_str = "`collapse_str' (mean) age_`y'_male_mean=age_`y'_1 age_`y'_female_mean=age_`y'_0 (sd) age_`y'_male_sd=age_`y'_1 age_`y'_female_sd=age_`y'_0"
	local collapse_str = "`collapse_str' (mean) educ_2_`y'_male_share=educ_2_`y'_1 educ_2_`y'_female_share=educ_2_`y'_0 educ_3_`y'_male_share=educ_3_`y'_1 educ_3_`y'_female_share=educ_3_`y'_0 educ_4_`y'_male_share=educ_4_`y'_1 educ_4_`y'_female_share=educ_4_`y'_0 "
	local collapse_str = "`collapse_str' (mean) earn_`y'_male_mean=earn_`y'_1 earn_`y'_female_mean=earn_`y'_0 (sd) earn_`y'_male_sd=earn_`y'_1 earn_`y'_female_sd=earn_`y'_0"
	local collapse_str = "`collapse_str' (mean) earn_log_`y'_male_mean=earn_log_`y'_1 earn_log_`y'_female_mean=earn_log_`y'_0 (sd) earn_log_`y'_male_sd=earn_log_`y'_1 earn_log_`y'_female_sd=earn_log_`y'_0"
	local collapse_str = "`collapse_str' (count) N_`y'_male=earn_`y'_1 N_`y'_female=earn_`y'_0"
}
${gtools}collapse `collapse_str', fast

* convert number of observations to millions
foreach var of varlist N_* {
	replace `var' = `var'/10^6
}

* save summary statistics table for RAIS data
outsheet using "${maindir}${sep}out${sep}$outfolder/summary_stats_RAIS.csv", replace comma


cap log close

// END OF THE CODE 
