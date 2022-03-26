********************************************************************************
* DESCRIPTION: Do a shift-share analysis with Brazil sectoral transition data 
*			   based on PME microdata.
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


*** settings
set graphics off
grstyle init
grstyle set plain, horizontal grid dotted


*** load data
use "${FINAL_DIR}/formal_informal_L.dta", clear
drop if year == 2015
qui recode transition (5=3) (6=4)
tab transition, gen (transition_)

** Generate variables to be filled below
qui foreach sec in "ff" "ii" "fi" "if" {
	gen share_`sec' = .
	forval j = 1/4 {
		gen share_`sec'edu`j' = .
	}
}
qui foreach v in "mean" "var" {
	gen `v'_tot = .
	qui forval j = 1/4 {
		gen `v'_totedu`j' = .
	}
	qui foreach sec in "ff" "ii" "fi" "if" {
		gen `v'_`sec' = .
		qui forval j = 1/4 {
			gen `v'_`sec'edu`j' = .	
		}
	}
}


*** Fill variables:
// Shares, total
qui forval yr = 2002/2014 {
forval i = 1/4 {
sum transition_`i' if year == `yr' [aw=weight]
scalar share`yr'sec`i' = r(mean)
}
replace share_ff = share`yr'sec1 if transition == 1 & year == `yr'
replace share_ii = share`yr'sec2 if transition == 2 & year == `yr'
replace share_fi = share`yr'sec3 if transition == 3 & year == `yr'
replace share_if = share`yr'sec4 if transition == 4 & year == `yr'
}

// Std and mean earnings change, total
qui forval yr = 2002/2014 {
forval i = 1/4 {
sum earn_res_change if year == `yr' & transition == `i' [aw=weight]
scalar var`yr'sec`i' = r(Var)
scalar mean`yr'sec`i' = r(mean)
}
sum earn_res_change if year == `yr'
scalar var`yr' = r(Var)
scalar mean`yr' = r(mean)
foreach v in "mean" "var" {
replace `v'_ff = `v'`yr'sec1 if transition == 1 & year == `yr'
replace `v'_ii = `v'`yr'sec2 if transition == 2 & year == `yr' 
replace `v'_fi = `v'`yr'sec3 if transition == 3 & year == `yr' 
replace `v'_if = `v'`yr'sec4 if transition == 4 & year == `yr'
replace `v'_tot = `v'`yr' if year == `yr'
}	
}
qui recode transition (3=5) (4=6)

// Shares, education group
rename edu_group edugroup
tab edu, gen (edu_)
qui forval yr = 2002/2014 {
forval j = 1/4 {
forval i = 1/2 {
sum edu_`j' if year == `yr' & transition == `i' [aw=weight]
scalar share`yr'sec`i'edu`j' = r(mean)
sum earn_res_change if year == `yr' & transition == `i' & edu == `j' [aw=weight]
scalar var`yr'sec`i'edu`j' = r(Var)
scalar mean`yr'sec`i'edu`j' = r(mean)
}
foreach v in "share" "mean" "var" {
replace `v'_ffedu`j' =  `v'`yr'sec1edu`j' if transition == 1 & year == `yr' & edu == `j'
replace `v'_iiedu`j' =  `v'`yr'sec2edu`j' if transition == 2 & year == `yr' & edu == `j'
}
sum earn_res_change if year == `yr' & edu == `j' [aw=weight], detail
scalar var`yr'edu`j' = r(Var)
scalar mean`yr'edu`j' = r(mean)
replace var_totedu`j' = var`yr'edu`j' if year == `yr' & edu == `j'
replace mean_totedu`j' = mean`yr'edu`j' if year == `yr' & edu == `j'
}
}
collapse share* mean* var*, by (year)
drop  share_fie* share_ife* var_fie* var_ife* mean_fie* mean_ife* 

save "${FINAL_DIR}/shift_share.dta", replace 
use "${FINAL_DIR}/shift_share.dta", clear


*** BETWEEN/WITHIN DECOMPOSITION OF TOTAL VARIANCE
foreach var in ff ii if fi {
	gen between`var' = share_`var' * ( mean_`var' - mean_tot )^2
	gen within`var' = share_`var' * var_`var'
}

* sum these up
egen between = rowtotal(between*)
egen within = rowtotal(within*)

tw (connected var_tot between within year,  				 /// Plot
lcolor(blue red green)  ///			Line color
lpattern(solid longdash dash )  ///			Line pattern
msymbol(o s +)		/// Marker
msize("`marksize'" "`marksize'" "`marksize'")		/// Marker size
mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
mlcolor(blue red green)  ///			Marker  line color
yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(large) angle(vertical))), /// yaxis optins
xtitle("") xlabel(2002(2)2015, grid gmin gmax labsize(large)) ///		xaxis options
legend(col(1) size(large) ring(0) position(11) ///
order(1 "Total" 2 "Between" 3 "Within") ///
region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
graphregion(color(white)) ///				Graph region define
plotregion(lcolor(black)) 
cap noisily: graph export "${FIG_DIR}/fig_decomposition.pdf", replace


*** SHIFT-SHARE ANALYSIS ACROSS SECTORS OF WITHIN COMPONENT -- Note: focus on the within component since it is the great majority of the total
* initial shares and variances
sort year
foreach var in ff ii if fi {
	gen share_`var'_init = share_`var'[1]
	gen var_`var'_init = var_`var'[1]
}

* compute components
foreach var in ff ii if fi {
	gen within_fixed_composition`var' = share_`var'_init * var_`var'
	gen within_fixed_inequality`var' = share_`var' * var_`var'_init
}
egen within_fixed_composition = rowtotal( within_fixed_composition* )
egen within_fixed_inequality = rowtotal( within_fixed_inequality* )

tw (connected within within_fixed_composition within_fixed_inequality year,  				 /// Plot
lcolor(green black black)  ///			Line color
lpattern(dash solid longdash)  ///			Line pattern
msymbol(+ o s)		/// Marker
msize("`marksize'" "`marksize'" "`marksize'")		/// Marker size
mfcolor(green*0.25 black*0.25 black*0.25)  ///	Fill color
mlcolor(green black black)  ///			Marker  line color
yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(large) angle(vertical))), /// yaxis optins
xtitle("") xlabel(2002(2)2015, grid gmin gmax labsize(large)) ///		xaxis options
legend(col(1) size(large) ring(0) position(11) ///
order(1 "Total within" 2 "Return channel" 3 "Composition channel") ///
region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
graphregion(color(white)) ///				Graph region define
plotregion(lcolor(black)) 
cap noisily: graph export "${FIG_DIR}/fig_shiftshare.pdf", replace

		
*** BETWEEN/WITHIN DECOMPOSITION OF WITHIN FF/II VARIANCE ACROSS EDUC
* loop over transition types
foreach var in ff ii {
	
	* loop over education
	forvalues educ = 1/4 {
		gen between`var'_edu`educ' = share_`var'edu`educ' * ( mean_`var'edu`educ' - mean_`var' )^2
		gen within`var'_edu`educ' = share_`var'edu`educ' * var_`var'edu`educ'
	}
	
	* sum these up
	egen between`var'_edu = rowtotal( between`var'_edu* )
	egen within`var'_edu = rowtotal( within`var'_edu* )

	tw (connected var_`var' between`var'_edu within`var'_edu year,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(large) angle(vertical))), /// yaxis optins
	xtitle("") xlabel(2002(2)2015, grid gmin gmax labsize(large)) ///		xaxis options
	legend(col(1) size(large) ring(0) position(1) ///
	order(1 "Total" 2 "Between" 3 "Within") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) ///
	name(decompose`var', replace)
	cap noisily: graph export "${FIG_DIR}/fig_decomposition_sector`var'.pdf", replace			
}


*** SHIFT-SHARE ANALYSIS ACROSS SECTORS OF WITHIN COMPONENT ACROSS EDUC -- Note: focus on the within component since it is the great majority of the total
* initial shares and variances
sort year
foreach var in "ff" "ii" {
		
	if "`var'" == "ff" {
		local position position(2)
	}
	else if "`var'" == "ii" {
		local position position(7)
	}

	forvalues educ = 1/4 {
		gen share_`var'edu`educ'_init = share_`var'edu`educ'[1]
		gen var_`var'edu`educ'_init = var_`var'edu`educ'[1]
	}

	* compute components
	forvalues educ = 1/4 {
		gen within_fixed_composition`var'_edu`educ' = share_`var'edu`educ'_init * var_`var'edu`educ'
		gen within_fixed_inequality`var'_edu`educ' = share_`var'edu`educ' * var_`var'edu`educ'_init
	}
	egen within_fixed_composition`var'_edu = rowtotal( within_fixed_composition`var'_edu* )
	egen within_fixed_inequality`var'_edu = rowtotal( within_fixed_inequality`var'_edu* )

	tw (connected within`var'_edu within_fixed_composition`var'_edu within_fixed_inequality`var'_edu year,  				 /// Plot
		lcolor(green black black)  ///			Line color
		lpattern(dash solid longdash)  ///			Line pattern
		msymbol(+ o s )		/// Marker
		msize("`marksize'" "`marksize'" "`marksize'")		/// Marker size
		mfcolor(green*0.25 black*0.25 black*0.25)  ///	Fill color
		mlcolor(green black black)  ///			Marker  line color
		yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(large) angle(vertical))), /// yaxis optins
		xtitle("") xlabel(2002(2)2015, grid gmin gmax labsize(large)) ///		xaxis options
		legend(col(1) size(large) ring(0) `position' ///
		order(1 "Total within" 2 "Return channel" 3 "Composition channel") ///
		region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
		graphregion(color(white)) ///				Graph region define
		plotregion(lcolor(black)) ///
		name(shiftshare`var', replace)
		cap noisily: graph export "${FIG_DIR}/fig_shiftshare_sector`var'.pdf", replace
}
