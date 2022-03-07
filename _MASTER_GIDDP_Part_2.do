********************************************************************************
* DESCRIPTION: Master file for Part 2 of Global Income Dynamics Database
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
ssc install grstyle, replace
ssc install palettes, replace
ssc install colrspace, replace
grstyle init
grstyle set plain, horizontal grid dotted

********************************************************************************
* DEFINE WHICH SECTIONS TO RUN
********************************************************************************
if "`10'" == "" { // use manually set arguments
	macro drop _all
	global GIDDP_11 = 0 // 11_createpanel.do
	global GIDDP_12 = 0 // 12_repRAIS.do
	global GIDDP_13 = 0 // 13_computepanel.do
	global GIDDP_14 = 0 // 14_formal_informal.do
	global GIDDP_15 = 0 // 15_shift_share.do	
	
}
else { // use passed arguments
	forval i = 1/5 {
		scalar GIDDP_`i'_stored = ``i''
	}
	macro drop _all
	forval i = 1/5 {
		global GIDDP_`i' = GIDDP_`i'_stored
		macro drop GIDDP_`i'_stored
	}
}


********************************************************************************
* Directories
********************************************************************************

if "`c(username)'" == "Roberta" {
	global MAIN_DIR = "C:/Users/Roberta/Dropbox/Global Income Dynamics Database Project (GIDDP)/Brazil/9_submissions/2021_02_24_QE_submissions/2022_03_05_replication_materials/part_2"
}
else if "`c(username)'" == "roberta.olivieri" {
	global MAIN_DIR =  "C:/Users/roberta.olivieri/Dropbox/Global Income Dynamics Database Project (GIDDP)/Brazil/9_submissions/2021_02_24_QE_submissions/2022_03_05_replication_materials/part_2"
}
else if "`c(username)'" == "cm3594" {
	global MAIN_DIR =  "/Users/cm3594/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/9_submissions/2021_02_24_QE_submissions/2022_03_05_replication_materials/part_2"
}
else if "`c(username)'" == "cmoser" {
	global MAIN_DIR =  "/Users/cmoser/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/9_submissions/2021_02_24_QE_submissions/2022_03_05_replication_materials/part_2"
}
else if "`c(username)'" == "rober" {
	global MAIN_DIR "C:/Users/rober/Dropbox/Global Income Dynamics Database Project (GIDDP)/Brazil/9_submissions/2021_02_24_QE_submissions/2022_03_05_replication_materials/part_2"
}

global DTA_DIR = "${MAIN_DIR}/files/dta"
global LOG_DIR = "${MAIN_DIR}/files/log"
global FIG_DIR = "${MAIN_DIR}/files/figs"
global FINAL_DIR = "${MAIN_DIR}/files/out"
global TEMP_DIR = "${MAIN_DIR}/files/temp"
global DIR_WRITE_PME = "${MAIN_DIR}/files/dta/processed"
global DIR_READ_PME_NOVA = "${MAIN_DIR}/files/dta/raw"


********************************************************************************
* EXECUTE CODE
********************************************************************************

do "${MAIN_DIR}/10_initiliaze_PME.do"

disp _newline(3)
disp "*** SECTION 11: Create PME Panel at Survey Level"
if ${GIDDP_11} do "${DO_DIR}/11_createpanel.do"

disp _newline(3)
disp "*** SECTION 12: Compute and replicate RAIS data with PME"
if ${GIDDP_12} do "${DO_DIR}/12_repRAIS.do"

disp _newline(3)
disp "*** SECTION 13: Computes statistics at the Year-Id level"
if ${GIDDP_12} do "${DO_DIR}/13_computepanel.do"

disp _newline(3)
disp "*** SECTION 14: Formal-Informal transitions"
if ${GIDDP_12} do "${DO_DIR}/14_formal_informal.do"

disp _newline(3)
disp "*** SECTION 15: Shift-Share Analysis"
if ${GIDDP_12} do "${DO_DIR}/15_shift_share.do"


********************************************************************************
* FINAL HOUSEKEEPING
********************************************************************************
timer off 1
timer list 1
disp "FINISHED ON ${S_DATE} AT ${S_TIME} IN A TOTAL OF `=r(t1)' SECONDS."
cap log close
