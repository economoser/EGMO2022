********************************************************************************
* DESCRIPTION: Master file for Part 1 of Global Income Dynamics Database
*              Project: Brazil.
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


********************************************************************************
* INITIAL HOUSEKEEPING
********************************************************************************
set more off
clear all
cap log close _all
timer on 1
pause on
set type double
set excelxlsxlargefile on
set graphics off
set varabbrev on
set rmsg on
set matsize 11000
set linesize 90
set maxvar 120000
set seed 1
cap log close


********************************************************************************
* DEFINE WHICH SECTIONS TO RUN
********************************************************************************
if "`9'" == "" { // use manually set arguments
	macro drop _all
	global GIDDP_1 = 0 // 1_Gen_Base_Sample.do
	global GIDDP_2 = 0 // 2_DescriptiveStats.do
	global GIDDP_3 = 0 // 3_Inequality.do
	global GIDDP_4 = 0 // 4_Volatility.do
	global GIDDP_5 = 0 // 5_Mobility.do
	global GIDDP_6 = 1 // 6_Insheeting_datasets.do
	global GIDDP_7 = 0 // 7_Paper_Figs.do
	global GIDDP_8 = 0 // 8_background_figures.do
	global GIDDP_9 = 0 // 9_other_stats.do
}
else { // use passed arguments
	forval i = 1/9 {
		scalar GIDDP_`i'_stored = ``i''
	}
	macro drop _all
	forval i = 1/9 {
		global GIDDP_`i' = GIDDP_`i'_stored
		macro drop GIDDP_`i'_stored
	}
}


********************************************************************************
* DEFINE SWITCHES
********************************************************************************
global sample = 0 // 0 = run on full data; 1 = run on sample (50k obs. per year), 2 = run on mini-sample (5k obs. per year)
global key_vars_nonmissing = 0 // 0 = allow key variables to be missing; 1 = restrict to observations with nonmissing key variables. Key variables: ${personid_var}, ${male_var}, ${yob_var}, ${educ_var}, ${year_var}, ${labor_var}, hire_month, sep_month.
global pme_munis = 0 // 0 = run on full population; 1 = restrict to 6 municipalities covered by PME
global gtools = "g" // "" = use Stata-native commands; "g" = use gtools package


********************************************************************************
* DEFINE PARAMETERS
********************************************************************************
* macros for data analysis
global year_min = 1985 // first year of data used for analysis
global year_max = 2018 // last year of data used for analysis

* macros for plots
global year_norm = 1995 // year used to normalize time series plots
global year_min_plot = 1985 // first year to plot
global year_min_trunc_plot = 1996 // first year to plot for truncated plots
global year_max_plot = 2018 // last year to plot



********************************************************************************
* SET DIRECTORIES
********************************************************************************
foreach user in "cm3594" "cmoser" "economoser" "niklasengbom" "rober" {
	cap confirm file "/Users/`user'"
	if !_rc global user = "`user'"
}
global user "`c(username)'"
if "${user}" == "niklasengbom" global dropbox = "Dropbox"
if "${user}" == "rober" global dropbox = "Dropbox"
else if inlist("${user}", "economoser", "cm3594", "cmoser") global dropbox = "Dropbox (CBS)"
if "`c(os)'" == "Unix" { // if run on server
	global ROOT_DIR = "/shared/share_cmoser/13_Global_Income_Dynamics_Brazil"
	global maindir = "${ROOT_DIR}/3_code"
	global DO_DIR = "${maindir}/do"
	global TEMP_DIR = "/scratch/cm3594/GIDDP_BRA"
	global DATA_DIR = "/shared/share_cmoser/1_data/RAIS/3_processed"
	global MINWAGE_FILE = "/shared/share_cmoser/1_data/RAIS/6_conversion/min_wage/minwage_conv.dta"
}
else if inlist("`c(os)'", "MacOSX", "Windows") { // if run on local machine
	global ROOT_DIR = "/Users/${user}/${dropbox}/Global Income Dynamics Database Project (GIDDP)/Brazil"
	global maindir = "${ROOT_DIR}/3_code"
	global DO_DIR = "${maindir}/do"
	global TEMP_DIR = "/Users/${user}/Data/RAIS/2_temp/_GIDDP_BRA/temp"
	global DATA_DIR = "/Users/${user}/Data/RAIS/3_processed"
	global MINWAGE_FILE = "/Users/${user}/${dropbox}/Brazil/4 Data/6_conversion/min_wage/minwage_conv.dta"
}
global PME_DIR = "${ROOT_DIR}/7_PME"
global PME_OUTPUT_DIR = "${PME_DIR}/output"
global BACKGROUND_DIR = "${maindir}/figs/background"
global OTHER_DIR = "${maindir}/figs/other"
foreach f in ///
	"/Applications/MATLAB_R2019b.app/bin/matlab" ///
	"/Applications/MATLAB_R2020a.app/bin/matlab" ///
	"/Applications/MATLAB_R2020b.app/bin/matlab" ///
	"/apps/MATLAB/R2021a/bin/matlab" ///
	{
	cap confirm file "`f'"
	if !_rc global FILE_MATLAB = "`f'"
}

********************************************************************************
* AUTOMATIC SWITCHES -- DO NOT CHANGE!
********************************************************************************
* set normalization year equal to first PME survey year (= 2002) if data sample is restricted to 6 PME survey municipalities
if $pme_munis {
	global year_min = 2002
	global year_max = 2015
	global year_norm = 2002
}

* compile list of years divisible by 5 within selected time period
global years_list = "" // list of years used in various plots
forval y = $year_min/$year_max {
	if mod(`y', 5) == 0 global years_list = "${years_list} `y'" // adds all years that are divisible by 5
}


********************************************************************************
* EXECUTE CODE
********************************************************************************
disp _newline(3)
disp "*** SECTION 1: Generate Base Sample"
if ${GIDDP_1} do "${DO_DIR}/1_Gen_Base_Sample.do"

disp _newline(3)
disp "*** SECTION 2: Descriptive Statistics"
if ${GIDDP_2} do "${DO_DIR}/2_DescriptiveStats.do"

disp _newline(3)
disp "*** SECTION 3: Inequality Statistics"
if ${GIDDP_3} do "${DO_DIR}/3_Inequality.do"

disp _newline(3)
disp "*** SECTION 4: Volatility Statistics"
if ${GIDDP_4} do "${DO_DIR}/4_Volatility.do"

disp _newline(3)
disp "*** SECTION 5: Mobility Statistics"
if ${GIDDP_5} do "${DO_DIR}/5_Mobility.do"

disp _newline(3)
disp "*** SECTION 6: Preparing Datasets for Publication on GIDP Website"
if ${GIDDP_6} do "${DO_DIR}/6_Insheeting_datasets.do"

disp _newline(3)
disp "*** SECTION 7: Paper Figures"
if ${GIDDP_7} do "${DO_DIR}/7_Paper_Figs.do"

disp _newline(3)
disp "*** SECTION 8: Background (Section 2) Figures"
if ${GIDDP_8} do "${DO_DIR}/8_background_figures.do"

disp _newline(3)
disp "*** SECTION 9: Other statistics"
if ${GIDDP_9} do "${DO_DIR}/9_other_stats.do"


********************************************************************************
* FINAL HOUSEKEEPING
********************************************************************************
timer off 1
timer list 1
disp "FINISHED ON ${S_DATE} AT ${S_TIME} IN A TOTAL OF `=r(t1)' SECONDS."
cap log close
