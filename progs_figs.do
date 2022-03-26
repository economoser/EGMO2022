********************************************************************************
* DESCRIPTION: Contains user-written programs for 13_computepanel.do.
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


*** programs
cap program drop transitions_graphs
program transitions_graphs
	tw (connected mean_ii mean_if mean_iout year,  	 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash)  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Informal-Informal" 2 "Informal-Formal" 3 "Informal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_informal.pdf", replace
	
	tw (connected mean_if mean_iout year,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash)  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.1).3, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(11) ///
	order(1 "Informal-Formal" 2 "Informal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_informal2.pdf", replace
	
	tw (connected mean_ff mean_fi mean_fout year,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Formal-Formal" 2 "Formal-Informal" 3 "Formal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_formal.pdf", replace
	
	tw (connected  mean_fi mean_fout year,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.025).1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(11) ///
	order(1 "Formal-Informal" 2 "Formal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_formal2.pdf", replace
end

cap program drop transitions_graphs_pctyear
program transitions_graphs_pctyear
	tw (connected mean_ii_year mean_if_year mean_iout_year pct_ind if year == 2003,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash)  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Informal-Informal" 2 "Informal-Formal" 3 "Informal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_informal_20_2003.pdf", replace
		
	tw (connected mean_ii_year mean_if_year mean_iout_year pct_ind if year == 2014,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash)  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Informal-Informal" 2 "Informal-Formal" 3 "Informal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_informal_20_2014.pdf", replace
		
	tw (connected mean_ff_year mean_fi_year mean_fout_year pct_ind if year == 2003,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Formal-Formal" 2 "Formal-Informal" 3 "Formal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_formal_20_2003.pdf", replace
		
	tw (connected mean_ff_year mean_fi_year mean_fout_year pct_ind if year == 2014,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Formal-Formal" 2 "Formal-Informal" 3 "Formal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_formal_20_2014.pdf", replace
end

cap program drop transitions_graphs_pct
program transitions_graphs_pct
	tw (connected mean_ii mean_if mean_iout pct_ind,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash)  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Informal-Informal" 2 "Informal-Formal" 3 "Informal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_informal_20.pdf", replace
		
	tw (connected mean_if mean_iout pct_ind,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.1).3, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(11) ///
	order(1 "Informal-Formal" 2 "Informal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_ifiout_20.pdf", replace

	tw (connected mean_ff mean_fi mean_fout pct_ind,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.2)1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(3) ///
	order(1 "Formal-Formal" 2 "Formal-Informal" 3 "Formal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_formal_20.pdf", replace
		
	tw (connected mean_fout mean_fi pct_ind,  				 /// Plot
	lcolor(blue red green)  ///			Line color
	lpattern(solid longdash dash )  ///			Line pattern
	msymbol(o s +)		/// Marker
	msize("medium" "medium" "medium")		/// Marker size
	mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
	mlcolor(blue red green)  ///			Marker  line color
	ytitle("Transition probability", size(${text_size})) yaxis(1) ylabel(0(.02).1, grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("Earnings percentiles", size(${text_size})) xlabel(0(20)100, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(1) ///
	order(1 "Formal-Informal" 2 "Formal-Nonemployed") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${FIG_DIR}/fig_transition_fifout_20.pdf", replace
end

cap program drop sector_age_analysis
program sector_age_analysis
	set more off
	global text_size = "large" // or "large"
	global marksize = "medium"
	local titlesize "vlarge"
	local ytitlesize =   "large"
	local subtitlesize = "medium" 	
	local subtitle all
	use if year < 2015 using "${FINAL_DIR}/L_researn_age.dta", clear
	reshape wide share_sec_age L_researn_1y_sec_mean L_researn_1y_sec_sd, i(year work_sector) j(age_group)
	sort work_sector year	
	order year work* share* L_researn_1y_sec_mean* L_researn_1y_sec_sd*
	tw (connected share* year if work_sector == 1,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 maroon*0.25)  ///	Fill color
	mlcolor(red blue green maroon)  ///			Marker  line color
	yaxis(1) ylabel(0(.1).6, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") ytitle("Shares", size(${text_size})) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "Ages 25-34" 2 "Ages 35-44" 3 "Ages 45-55") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))
	cap n graph export "${FIG_DIR}/fig_age_L_shareFF.pdf", replace

	tw (connected share* year if work_sector == 2,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(0(.1).6, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") ytitle("Shares", size(${text_size})) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "Ages 25-34" 2 "Ages 35-44" 3 "Ages 45-55") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_age_L_shareII.pdf", replace
	
	tw (connected L_researn_1y_sec_sd* year if work_sector == 1,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "25-34" 2 "35-44" 3 "45-55") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_age_L_researn_1y_sd_FF.pdf", replace

	tw (connected L_researn_1y_sec_sd* year if work_sector == 2,  				 /// Plot
	color(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "25-34" 2 "35-44" 3 "45-55") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_age_L_researn_1y_sd_II.pdf", replace
	
	tw (connected L_researn_1y_sec_mean* year if work_sector == 1,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "25-34" 2 "35-44" 3 "45-55") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_age_L_researn_1y_FF.pdf", replace
	
	tw (connected L_researn_1y_sec_mean* year if work_sector == 2,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "25-34" 2 "35-44" 3 "45-55") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_age_L_researn_1y_II.pdf", replace
end
	
cap program drop sector_edu_analysis
program sector_edu_analysis
	set more off
	global text_size = "large" // or "large"
	global marksize = "medium"
	local titlesize "vlarge"
	local ytitlesize =   "large"
	local subtitlesize = "medium" 
	local subtitle all	
	use ///
	work_sector edu_degree year share_sec_edu L_researn_1y_sec_mean L_researn_1y_sec_sd ///
	if year < 2015 ///
	using "${FINAL_DIR}/L_researn_educ.dta", clear
	// 			
	preserve
	keep if work_sector == 1 // F-F
	reshape wide share_sec_edu L_researn_1y_sec_mean L_researn_1y_sec_sd, i(work_sector year) j(edu_degree)
	sort work_sector year
	order year work* share* L_researn_1y_sec_mean* L_researn_1y_sec_sd*
	
	tw (connected share* year if work_sector == 1,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(.0(.1).6, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") ytitle("Shares", size(${text_size})) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "Less than primary school" 2 "Primary school" 3 "High school" 4 "College") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))  
	graph export "${FIG_DIR}/fig_edu_L_shareFF.pdf", replace
	
	tw (connected L_researn_1y_sec_mean* year if work_sector == 1,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "< primary school" 2 "primary school" 3 "high school" 4 "college") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_edu_L_researn_FF.pdf", replace
	
	tw (connected L_researn_1y_sec_sd* year if work_sector == 1,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") ytitle("Shares", size(${text_size})) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "< primary school" 2 "primary school" 3 "high school" 4 "college") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))
	cap n graph export "${FIG_DIR}/fig_edu_L_researn_sd_FF.pdf", replace
		
	restore
	preserve
	keep if work_sector == 2 // I-I
	reshape wide share_sec_edu L_researn_1y_sec_mean L_researn_1y_sec_sd, i(work_sector year) j(edu_degree)
	sort work_sector year
	
	tw (connected share* year if work_sector == 2,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(.05(.1).6, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") ytitle("Shares", size(${text_size})) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "Less than primary school" 2 "Primary school" 3 "High school" 4 "College") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_edu_L_shareII.pdf", replace
	
	tw (connected L_researn_1y_sec_sd* year if work_sector == 2,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "< primary school" 2 "primary school" 3 "high school" 4 "college") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/fig_edu_L_researn_sd_II.pdf", replace

	tw (connected L_researn_1y_sec_mean* year if work_sector == 2,  				 /// Plot
	lcolor(red blue green navy)  ///			Line color
	lpattern(solid longdash dash dash_dot)  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(red*0.25 blue*0.25 green*0.25 navy*0.25)  ///	Fill color
	mlcolor(red blue green navy)  ///			Marker  line color
	yaxis(1) ylabel(, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(3) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "< primary school" 2 "primary school" 3 "high school" 4 "college") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/fig_edu_L_researn_II.pdf", replace
end
