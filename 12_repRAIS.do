********************************************************************************
* DESCRIPTION: Creates and compute statistics of the formal sector replicating RAIS 
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


*** load programs that replicate results based on administrative RAIS data
do "${MAIN_DIR}/progs_repRAIS.do"


*** CS data
	* load data
	use "${DIR_WRITE_PME}/panel.dta", clear

*** 1. Only those who appear 4 times in the calendar year & drop gender error
	sort id year month
	egen id_year = group(id year) // Create variable that identifies individual-year 
	bys id_year: egen gender_mean = mean(gender) // Drop individuals that, for some reason, change gender (very few cases)
	drop if gender_mean > 0 & gender_mean < 1 
	drop gender_mean
	bys id_year: gen nobs = _N // Keep individuals that appear 4 times during a calendar year
	keep if nobs == 4 
			
*** 2. Process of earnings annualization by id (for formal_emp [formal employees] jobs only)
	replace earnings_def = . if formal_emp != 1 // Turn deflationated earnings to missing if not formal
	replace earnings = . if formal_emp != 1 // Turn earnings to missing if not formal
	replace formal_emp = 0 if earnings == . // If earnings are missing, individuals are not formal employed in that obs
	bys id_year: egen mean_earnings = mean(earnings_def) // Average earnings deflacionated in the months working in formal sector
	bys id_year: egen mean_earnings_nominal = mean(earnings) // Average earnings in the months working in formal sector
	by id_year: gen nobs_formal = sum(formal_emp) 
	by id_year: egen formal_months = max(nobs_formal) // Variable that identifies how many months (out of 4) individual worked at formal sector
	drop if formal_months == 0 | formal_months == . // Drop individuals who did not worked at the formal sector in any of the 4 months
	drop nobs_formal

	qui forval i = 1/12 {
	gen month`i' = 0
	replace month`i' = 1 if month == `i' & formal_emp == 1
	} 
	qui forval i = 1/12 {
	by id_year: egen aux`i' = mean(month`i')
	by id_year: replace month`i' = 1 if aux`i' > 0
	drop aux`i'
	} // var month`i': Dummy that identifies which month (Jan, Fev, ..., Dec) individual worked at the formal sector		
	// Note: 12 possible options for individual calendar year observations group:
	// 1. {Jan-Apr} 
	// 2. {Feb-May} 
	// 3. {Mar-Jun}
	// 4. {Apr-Jul}
	// 5. {May-Aug}
	// 6. {Jun-Sep}
	// 7. {Jul-Oct}
	// 8. {Aug-Nov}
	// 9. {Sep-Dec}
	// 10. {Jan; Oct-Dec}
	// 11. {Jan-Fev; Nov-Dec}
	// 12. {Jan-Mar; Dec}
	sort id_year month
	by id_year: gen first_month = month[1] 
	by id_year: gen second_month = month[2]
	by id_year: gen third_month = month[3]
	by id_year: gen last_month = month[4]
	gen season_group = 0 // Variable that identifies which group out of 12 above individual appeared; var name: season_group ("seasonality group")
	replace season_group = 1 if first_month == 1 & last_month == 4 
	replace season_group = 2 if first_month == 2 & last_month == 5
	replace season_group = 3 if first_month == 3 & last_month == 6 
	replace season_group = 4 if first_month == 4 & last_month == 7 
	replace season_group = 5 if first_month == 5 & last_month == 8 
	replace season_group = 6 if first_month == 6 & last_month == 9 
	replace season_group = 7 if first_month == 7 & last_month == 10 
	replace season_group = 8 if first_month == 8 & last_month == 11 
	replace season_group = 9 if first_month == 9 & last_month == 12 
	replace season_group = 10 if first_month == 1 & second_month == 10 & last_month == 12 
	replace season_group = 11 if first_month == 1 & second_month == 2 & third_month == 11 
	replace season_group = 12 if first_month == 1 & third_month == 3 & last_month == 12 
	drop first_month second_month third_month last_month 
	by id_year: egen mean_spell = mean(spell_g)
	gen id_consecutive = 0
	by id_year: replace id_consecutive = 1 if mean_spell == 1 | mean_spell == 2 
	drop mean_spell
		
	** 2.1 Annualize earnings
	drop mw
	merge m:1 year using "${DTA_DIR}/minwage_conv_yearly.dta"
	drop if _merge == 2
	drop _merge
	sort id year month
	gen annual_earnings_nominal = mean_earnings_nominal*formal_months*3 // Annualization of how much in nominal terms the person earned that year
	gen annual_earnings_mw = annual_earnings_nominal/mw // Annualization of how much in MW terms the person earned that year
	keep if annual_earnings_mw >= 1.5 // Minimum threshold			
	gen mean_earnings_mw = mean_earnings_nominal/mw // Average of how much in MW terms the person earned monthly IN THE TOTAL MONTHS WORKING AS FORMAL
	drop if mean_earnings_mw > 120 // Maximum threshold
	drop annual_earnings_mw annual_earnings_nominal
	gen annual_earnings = mean_earnings*formal_months*3  
	drop month
	
*** 3. Collapse information to one individual-year observation
	collapse (mean) age gender mean_earnings_mw annual_earnings formal_months month* id_consecutive season_group exrate weight, by(id year)
	sort year 
		
*** 4. Find residual earnings, controlling for age, season group and run separately by gender & year
	gen ln_annual_earnings = log(annual_earnings)
	replace age = round(age)
	gen researn = .		
	qui forval yr = 2002/2015 {
	reg ln_annual_earnings i.season_group i.age if gender == 1 & year == `yr' [aw=weight]
	predict temp_m if e(sample)== 1, residuals
	reg ln_annual_earnings i.season_group i.age if gender == 0 & year == `yr' [aw=weight]
	predict temp_f if e(sample)== 1, residuals
	replace researn = temp_m if year == `yr' & gender == 1
	replace researn = temp_f if year == `yr' & gender == 0
	drop temp*
	}
	rename ln_annual_earnings logearn_rais
	rename researn researn_rais
	
*** 5. Generate final statistics (Percentiles, Mean, Std; separately by gender and combined)
	mystats_repRAIS "logearn_rais"
	mystats_repRAIS "researn_rais"


*** L data
* load data
use "${DIR_WRITE_PME}/panel.dta", clear

*** 1. Only those who appear 4 times in the calendar year & 8 times during two consecutive years
	sort id year month
	egen id_s = group(id spell_g year)  // Create variable that identifies individual-year-spell 
	bys id_s: gen nobs_s = _N
	keep if nobs_s == 4 // Keep if there are 4 consecutive appearences in calendar year		
	egen id_year = group(id year)  // Create variable that identifies individual-year  
	bys id_year: egen gender_mean = mean(gender)  // Drop individuals that, for some reason, change gender (very few cases)
	drop if gender_mean > 0 & gender_mean < 1 
	drop gender_mean
	bys id_year: gen nobs = _N
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Keep individuals that appear 8 times in two consecutive years
	keep if nobs == 4 // Making sure we are keeping indidviduals that appear 4 times in a calendar year

*** 2. Process of earnings annualization by id (for formal_emp [formal employees] jobs only)
	replace earnings_def = . if formal_emp != 1 // Turn deflationated earnings to missing if not formal
	replace earnings = . if formal_emp != 1 // Turn earnings to missing if not formal
	replace formal_emp = 0 if earnings == . // If earnings are missing, individuals are not formal employed in that obs		
	bys id_year: egen mean_earnings = mean(earnings_def) // Average earnings deflacionated in the months working in formal sector 
	by id_year: egen mean_earnings_nominal = mean(earnings) // Average earnings in the months working in formal sector	
	by id_year: gen nobs_formal = sum(formal_emp) 
	by id_year: egen formal_months = max(nobs_formal) // Variable that identifies how many months (out of 4) individual worked at formal sector
	drop if formal_months == 0 | formal_months == . // Drop individuals who did not worked at the formal sector in any of the 4 months
	drop nobs_formal
	drop nobs_id
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Drop individuals who did not have a positive earnings in WC in any of the two years
	sort id_year month
	qui forval i = 1/12 {
	gen month`i' = 0
	replace month`i' = 1 if month == `i' & formal_emp == 1
	}
	qui forval i = 1/12 {
	bys id_year: egen aux`i' = mean(month`i')
	by id_year: replace month`i' = 1 if aux`i' > 0
	drop aux`i'
	} // var month`i': Dummy that identifies which month (Jan, Fev, ..., Dec) individual worked at the formal sector
	// Note: 9 possible options for individual calendar year observations group:
	// 1. {Jan-Apr} 
	// 2. {Feb-May} 
	// 3. {Mar-Jun}
	// 4. {Apr-Jul}
	// 5. {May-Aug}
	// 6. {Jun-Sep}
	// 7. {Jul-Oct}
	// 8. {Aug-Nov}
	// 9. {Sep-Dec}
	by id_year: gen season_group = month[1]
	by id_year: egen mean_spell = mean(spell_g)
	gen id_consecutive = 0
	by id_year: replace id_consecutive = 1 if mean_spell == 1 | mean_spell == 2 // Dummy if the 4 appearences in the calendar year are consecutive; all should be consecutive
	tab id_consecutive // Checking if all are indeed consecutive
	drop mean_spell
		
	** 2.1 Annualize earnings
	drop mw
	merge m:1 year using "${DTA_DIR}/minwage_conv_yearly.dta"
	drop if _merge == 2
	drop _merge
	sort id year month
	gen annual_earnings_nominal = mean_earnings_nominal*formal_months*3 // Annualization of how much in nominal terms the person earned that year
	gen annual_earnings_mw = annual_earnings_nominal/mw  // Annualization of how much in MW terms the person earned that year		
	keep if annual_earnings_mw >= 1.5 // Minimum threshold
	gen mean_earnings_mw = mean_earnings_nominal/mw  // Average of how much in MW terms the person earned monthly IN THE TOTAL MONTHS WORKING AS FORMAL
	drop if mean_earnings_mw > 120 // Maximum threshold
	drop annual_earnings_*
	gen annual_earnings = mean_earnings*formal_months*3 // Annualization of how much in real terms the person earned in the year
	drop nobs_id
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Drop individuals who did not match the max&min criteria in one of the two years, i.e., keep only those who match in both	
	drop month
	
*** 3. Collapse information to one individual-year observation
	collapse (mean) age gender annual_earnings formal_months month* id_consecutive season_group exrate weight, by(id year)
	sort year 
	
*** 4. Find residual earnings, controlling for age, season group and run separately by gender & year
	gen ln_annual_earnings = log(annual_earnings)
	replace age = round(age)
	gen researn = .			
	qui forval yr = 2002/2015 {
	reg ln_annual_earnings i.season_group i.age if gender == 1 & year == `yr' [aw=weight]
	predict temp_m if e(sample)== 1, residuals
	reg ln_annual_earnings i.season_group i.age if gender == 0 & year == `yr' [aw=weight]
	predict temp_f if e(sample)== 1, residuals
	replace researn = temp_m if year == `yr' & gender == 1
	replace researn = temp_f if year == `yr' & gender == 0
	drop temp*
	}
	rename ln_annual_earnings L_logearn_rais
	rename researn L_researn_rais
		
*** 5. Calculate residuals earnings change 1-year-forward
	sort id year
	by id: gen L_researn_rais_1y = L_researn_rais[_n+1] - L_researn_rais[_n] 
	drop if L_researn_rais_1y == .
	keep id year gender L_logearn_rais L_researn_rais weight L_researn_rais_1y
	drop if year == 2015
		
*** 6. Generate final statistics (Percentiles, Mean, Std; separately by gender and combined	
	mystats_repRAIS "L_researn_rais_1y"


*** FIGURES that replicate results based on administrative RAIS data
* graph settings
graph set window fontface "Times New Roman"

* log earnings
CS_graphs_repRAIS "logearn_rais" 1 "male" "male"  0
CS_graphs_repRAIS "logearn_rais" 0 "fem" "fem" 0
CS_graphs_repRAIS "logearn_rais" . "all" "all" 1 -.2 .1 .4 1.9 .2 2.9 .8 .1 1.5

* residual log earnings
CS_graphs_repRAIS "researn_rais" 1 "male" "male"  0
CS_graphs_repRAIS "researn_rais" 0 "fem" "fem"  0
CS_graphs_repRAIS "researn_rais" . "all" "all"  1 -.2 .1 .4 1.9 .2 2.9 .8 .1 1.5
	
* One-year change in residual log earnings -- Parts Three (3 graphs) and Part Four (2 graphs)
// L_graphs_repRAIS "L_researn_rais_1y" 1 "male" "male" 0
L_graphs_repRAIS "L_researn_rais_1y" 1 "male" "male" 1 -0.2 .1 .2 .8 .2 1.6 .3 .1 .8
// L_graphs_repRAIS "L_researn_rais_1y" 0 "fem" "fem" 0
L_graphs_repRAIS "L_researn_rais_1y" 0 "fem" "fem" 1 -0.2 .1 .2 .8 .2 1.6 .3 .1 .8
L_graphs_repRAIS "L_researn_rais_1y" . "all" "all" 1 -0.2 .1 .2 .8 .2 1.6 .3 .1 .8
