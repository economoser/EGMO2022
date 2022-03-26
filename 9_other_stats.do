********************************************************************************
* DESCRIPTION: Compute other statistics for GIDDP Brazil project.
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

********************************************************************************
* computes other statistics for GIDDP-Brazil
* author: Chris Moser (Columbia and CEPR)
* date: February 9, 2021
********************************************************************************


*** opening housekeeping
* log
cap log close

* create output directory
cap confirm file "${OTHER_DIR}"
if _rc {
	!mkdir "${OTHER_DIR}"
}

* initialize
do "$maindir/do/0_Initialize.do"

* define list of years for which to compute summary statistics
global years_list = "1985 1996 2007 2018"

* based on list of years, automatically create list of variables
global vars_list = ""
foreach y of global years_list {
	global vars_list = "${vars_list} labor`y'"
}


*** basic summary statistics
* load
use male yob educ ${vars_list} using "${TEMP_DIR}${sep}dta${sep}master_sample.dta", clear

* describe variables
desc

* summarize variables
sum, sep(0)

* summarize by year
gen byte age = .
foreach y in $years_list {
	disp _newline(10)
	disp "*** year = `y'"
	gen float ln_labor`y' = ln(labor`y')
	foreach g in 2 1 0 {
		disp _newline(3)
		disp "* male = `g'"
		if inlist(`g', 0, 1) {
			replace age = `y' - yob + 1 if labor`y' < . & male == `g'
			sum age if labor`y' < . & male == `g'
			tab educ if labor`y' < . & male == `g'
			sum labor`y' if male == `g'
			sum ln_labor`y' if male == `g'
			count if labor`y' < . & male == `g'
		}
		else {
			replace age = `y' - yob + 1 if labor`y' < .
			sum age if labor`y' < .
			tab educ if labor`y' < .
			sum labor`y'
			sum ln_labor`y'
			count if labor`y' < .
		}
	}
	drop ln_labor`y'
}
drop age


cap log close

// END OF FILE
