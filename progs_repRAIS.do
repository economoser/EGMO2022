********************************************************************************
* DESCRIPTION: Contains user-written programs for 12_repRAIS.do.
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


*** macros
global time_sleep = 1000


*** programs
cap program drop mystats_repRAIS
program mystats_repRAIS
	cd "${FINAL_DIR}"
	preserve
	local varM "`1'"
	local by_1 `" "gender year" "'
	local by_2 year
	local save_file `varM'
	global statlist ="mean_`varM'=r(mean) std_`varM'=r(sd) skew_`varM'=r(skewness) kurt_`varM'=r(kurtosis)" 
	qui statsby $statlist, by(`by_1') saving(`varM'_meanstd,replace): ///
	summarize `varM' [aw=weight], detail 		
	clear
	restore
	preserve			
	global statlist ="mean_`varM'=r(mean) std_`varM'=r(sd) skew_`varM'=r(skewness) kurt_`varM'=r(kurtosis)" 
	qui statsby $statlist, by(`by_2') saving(`varM'_all_meanstd,replace): ///
	summarize `varM' [aw=weight], detail  
	use `varM'_all_meanstd.dta, clear
	gen gender = .
	append using `varM'_meanstd.dta
	save `varM'_meanstd.dta, replace	
	clear
	restore
	preserve	
	global statlist1 ="p1`varM'=r(r1) p2_5`varM'=r(r2) p5`varM'=r(r3) p10`varM'=r(r4) p12_5`varM'=r(r5)"
	global statlist2 ="p25`varM'=r(r6) p37_5`varM'=r(r7) p50`varM'=r(r8) p62_5`varM'=r(r9)"
	global statlist3 ="p75`varM'=r(r10) p87_5`varM'=r(r11) p90`varM'=r(r12) p95`varM'=r(r13)" 
	global statlist4 ="p97_5`varM'=r(r14) p99`varM'=r(r15) p99_9`varM'=r(r16) p99_99`varM'=r(r17)" 
	qui statsby $statlist1 $statlist2 $statlist3 $statlist4, by(`by_1') saving(`save_file',replace): ///
	_pctile `varM' [aw=weight],p(1,2.5,5,10,12.5,25,37.5,50,62.5,75,87.5,90,95,97.5,99,99.9,99.99) 
	clear
	restore
	preserve
	global statlist1 ="p1`varM'=r(r1) p2_5`varM'=r(r2) p5`varM'=r(r3) p10`varM'=r(r4) p12_5`varM'=r(r5)"
	global statlist2 ="p25`varM'=r(r6) p37_5`varM'=r(r7) p50`varM'=r(r8) p62_5`varM'=r(r9)"
	global statlist3 ="p75`varM'=r(r10) p87_5`varM'=r(r11) p90`varM'=r(r12) p95`varM'=r(r13)" 
	global statlist4 ="p97_5`varM'=r(r14) p99`varM'=r(r15) p99_9`varM'=r(r16) p99_99`varM'=r(r17)" 
	qui statsby $statlist1 $statlist2 $statlist3 $statlist4, by(`by_2') saving(`varM'_all,replace): ///
	_pctile `varM' [aw=weight],p(1,2.5,5,10,12.5,25,37.5,50,62.5,75,87.5,90,95,97.5,99,99.9,99.99) 
	use `varM'_all.dta, clear
	gen gender = .
	append using `save_file'.dta
	merge m:m gender year using `varM'_meanstd.dta
	drop _merge
	order gender year
	save `save_file'.dta, replace
	sleep ${time_sleep}
	erase `varM'_all.dta
	erase `varM'_meanstd.dta
	erase `varM'_all_meanstd.dta
	restore 
end

cap program drop CS_graphs_repRAIS
program CS_graphs_repRAIS
	set more off
	set graphics off
	global text_size = "large" 
	global marksize = "medium"
	local titlesize "vlarge"
	local ytitlesize = "large"
	local subtitlesize = "medium"
	global vari = "`1'" 
	local subsample `2'
	local subtitle "`3'"
	local name_subsample "`4'"
	if `5' == 1 {
	local ylabel_1 ylabel(`6'(`7')`8', axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_2 ylabel(`9'(`10')`11', axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_3 ylabel(`12'(`13')`14', axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	}
	else if `5' == 0 { 
	local ylabel_1 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_2 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_3 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical)) 
	}
	* Check which variable
	if substr("`1'", 1, 7) == "researn" {
	local symbol "{&epsilon}{sub:it}"
	local name_var "Residual Log"
	}
	else if substr("`1'", 1, 7) == "logearn" {
	local symbol "log y{sub:it}"
	local name_var "Log"
	}
	global variN "n${vari}"
	* Automatically define folder name
	local folder "rais"
	use "${FINAL_DIR}/${vari}", clear
	keep if gender == `subsample'
	* Create scaled and normalized variables
	gen var${vari} = std_${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}	
	foreach vv in std_$vari var$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
	p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
	p97_5$vari p99$vari p99_9$vari p99_99$vari p9010$vari p9050${vari} p5010${vari} ksk${vari}{
	sum  `vv' if year == 2002, meanonly
	gen n`vv' = `vv' - r(mean)	
	}
	* Figure 1 (Normalized; Non-Normalized)
	* Normalized
	local varilist np90$vari np75$vari np50$vari np25$vari np10$vari
	tw  (connected `varilist'  year, 				 /// Plot
	lcolor(blue green red navy black maroon forest_green)  ///			Line color
	lpattern(solid longdash dash dash_dot solid longdash )  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 green*0.25 red*0.25 navy*0.25 black*0.25 maroon*0.25 forest_green*0.25)  ///	Fill color
	mlcolor(blue green red navy black maroon forest_green)  ///			Marker  line color
	yaxis(1) ytitle("Percentiles Relative to 2002", axis(1) size(`ytitlesize')) `ylabel_1') , /// yaxis optins
	xtitle("",) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "P90" 2 "P75" 3 "P50" 4 "P25" 5 "P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))  			
	cap n graph export "${FIG_DIR}/`folder'/fig1_${variN}_`name_subsample'.pdf",replace
	* Non Normalized
	local varilist p90$vari p75$vari p50$vari p25$vari p10$vari
	tw  (connected `varilist'  year, 				 /// Plot
	lcolor(blue green red navy black maroon forest_green)  ///			Line color
	lpattern(solid longdash dash dash_dot solid longdash )  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 green*0.25 red*0.25 navy*0.25 black*0.25 maroon*0.25 forest_green*0.25)  ///	Fill color
	mlcolor(blue green red navy black maroon forest_green)  ///			Marker  line color	
	yaxis(1) ytitle("Percentiles", axis(1) size(`ytitlesize')) ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))), /// yaxis optins
	xtitle("",) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "P90" 2 "P75" 3 "P50" 4 "P25" 5 "P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))
	cap n graph export "${FIG_DIR}/`folder'/fig1_${vari}_`name_subsample'.pdf", replace 	
	* Figure 2
	replace std_$vari = 2.56*std_$vari
	* 2a
	* Normalized
	tw  (connected nstd_$vari np9010$vari year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Dispersion of `name_var' Earnings", axis(1) size(`ytitlesize'))) , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size}) angle(vertical)) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(1) ///
	order(1 "2.56*{&sigma}" 2 "P90-P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/`folder'/fig2a_${variN}_`name_subsample'.pdf", replace 
	* Non-Normalized
	tw  (connected std_$vari p9010$vari year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Dispersion of `name_var' Earnings", axis(1) size(`ytitlesize')) `ylabel_2') , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(1) ///
	order(1 "2.56*{&sigma}" 2 "P90-P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig2a_${vari}_`name_subsample'.pdf", replace 	
	* 2b
	* Normalized
	tw  (connected np9050$vari np5010$vari year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Dispersion of `name_var' Earnings", axis(1) size(`ytitlesize'))) , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "P90-P50" 2 "P50-P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	cap n graph export "${FIG_DIR}/`folder'/fig2b_${variN}_`name_subsample'.pdf", replace 
	* Non-Normalized
	tw  (connected p9050$vari p5010$vari year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Dispersion of `name_var' Earnings", axis(1) size(`ytitlesize')) `ylabel_3') , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "P90-P50" 2 "P50-P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig2b_${vari}_`name_subsample'.pdf", replace 
end


cap program drop L_graphs_repRAIS
program L_graphs_repRAIS
	set more off
	set graphics off
	global text_size = "large" 
	global marksize = "medium"
	local titlesize "vlarge"
	local ytitlesize =   "large"
	local subtitlesize = "medium" 
	global vari = "`1'" 
	local subsample `2'
	local subtitle `3'
	local name_subsample "`4'"
	if `5' == 1 {
	local ylabel_1 ylabel(`6'(`7')`8', axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_2 ylabel(`9'(`10')`11', axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_3 ylabel(`12'(`13')`14', axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_1N ylabel(, axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_2N ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	}
	else if `5' == 0 { 
	local ylabel_1 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_1N ylabel(, axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_2 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_2N ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_3 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_4 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_5 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	local ylabel_6 ylabel(,axis(1) grid gmin gmax labsize(${text_size}) angle(vertical))
	}
	local symbol "g{sup:1}{sub:it}"
	local folder "rais"
	global variN "L_nresearn_rais_1y"
	use "${FINAL_DIR}/${vari}", clear
	keep if gender == `subsample'
	* Create scaled and normalized variables
	gen var${vari} = std_${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen p7525${vari} = p75${vari} - p25${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}
	gen cku${vari} = (p97_5${vari} - p2_5${vari})/p7525${vari} // Kurtosis (not standardized)
	foreach vv in std_$vari var$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
	p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
	p97_5$vari p99$vari p99_9$vari p99_99$vari p9010$vari p9050${vari} p5010${vari} ksk${vari}{
	sum  `vv' if year == 2002, meanonly
	gen n`vv' = `vv' - r(mean)	
	}	
	replace std_$vari = 2.56*std_$vari
	local varilist p5$vari p10$vari p25$vari p50$vari p75$vari p90$vari p95$vari
	* Figures 4
	* Normalized
	local varilist np95$vari np90$vari np75$vari np50$vari np25$vari np10$vari	
	tw  (connected `varilist'  year, 				 /// Plot
	lcolor(blue green red navy black maroon forest_green)  ///			Line color
	lpattern(solid longdash dash dash_dot solid longdash )  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 green*0.25 red*0.25 navy*0.25 black*0.25 maroon*0.25 forest_green*0.25)  ///	Fill color
	mlcolor(blue green red navy black maroon forest_green)  ///			Marker  line color
	yaxis(1) ytitle("Percentiles Relative to 2002", axis(1) size(`ytitlesize')) `ylabel_1') , /// yaxis optins
	xtitle("",) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "P90" 2 "P75" 3 "P50" 4 "P25" 5 "P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig4_${variN}_`name_subsample'.pdf", replace 
	* Non-Normalized
	local varilist p95$vari p90$vari p75$vari p50$vari p25$vari p10$vari
	tw  (connected `varilist'  year, 				 /// Plot
	lcolor(blue green red navy black maroon forest_green)  ///			Line color
	lpattern(solid longdash dash dash_dot solid longdash )  ///			Line pattern
	msymbol(o + s x d)		/// Marker
	msize("`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 green*0.25 red*0.25 navy*0.25 black*0.25 maroon*0.25 forest_green*0.25)  ///	Fill color
	mlcolor(blue green red navy black maroon forest_green)  ///			Marker  line color	
	yaxis(1) ytitle("Percentiles", axis(1) size(`ytitlesize')) ylabel(,axis(1) grid gmin gmax labsize(${text_size}))) , /// yaxis optins
	xtitle("",) xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) symxsize(*.45) ring(0) position(11) ///
	order(1 "P90" 2 "P75" 3 "P50" 4 "P25" 5 "P10") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))
	cap n graph export "${FIG_DIR}/`folder'/fig4_${vari}_`name_subsample'.pdf", replace 
	* Figures 5
	* 5a
	* Non Normalized
	tw  (connected std_$vari p9010$vari year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Dispersion of `symbol'", axis(1) size(`ytitlesize')) `ylabel_2') , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) symxsize(*.45) size(${text_size}) ring(0) position(11) ///
	order(1 "2.56*{&sigma}" 2 "P90-P10") ///
	region(lcolor(none) fcolor(none))) ////
	graphregion(color(white)) /// Legend options 
	graphregion(color(white)  ) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig5a_${vari}_`name_subsample'.pdf", replace 	
	* 5b
	* Non Normalized
	tw  (connected p9050 p5010$vari year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Dispersion of `symbol'", axis(1) size(`ytitlesize')) `ylabel_3') , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) symxsize(*.45) size(${text_size}) ring(0) position(11) ///
	order(1 "P90-P50" 2 "P50-P10") ///
	region(lcolor(none) fcolor(none))) //// 
	graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig5b_${vari}_`name_subsample'.pdf", replace 			
	*Skewness (Kelley only)
	tw  (connected ksk${vari} year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Skewness of `symbol'", axis(1) size(`ytitlesize'))) , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig6_${vari}_`name_subsample'.pdf", replace  
	*Kurtosis (Crow-Siddiqi only)
	tw  (connected cku${vari} year, 				 /// Plot
	lcolor(blue red)  ///			Line color
	lpattern(solid longdash)  ///			Line pattern
	msymbol(o s)		/// Marker
	msize("`marksize'" "`marksize'")		/// Marker size
	mfcolor(blue*0.25 red*0.25)  ///	Fill color
	mlcolor(blue red)  ///			Marker  line color
	yaxis(1) ytitle("Kurtosis of `symbol'", axis(1) size(`ytitlesize'))) , /// yaxis optins
	xtitle("") xlabel(2002(2)2016,grid gmin gmax labsize(${text_size})) ///		xaxis options
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black))  
	cap n graph export "${FIG_DIR}/`folder'/fig7_${vari}_`name_subsample'.pdf", replace 
end
