********************************************************************************
* DESCRIPTION: Creates and computes statistics at the year-individual level 
*              in Brazil based on PME microdata.
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


*** housekeeping (open)
set more off
timer clear 1
timer on 1
set seed 1
set rmsg on
postutil clear
cap log close
global text_size = "medlarge"

* macros
global CS = 1
global L = 1
global L_transition = 1
global CS_secondjob = 1

* load programs that produce figures
do "${MAIN_DIR}/progs_figs.do"


*** cross-sectional
if $CS == 1 {
	
	* load data
	use "${DIR_WRITE_PME}/panel.dta", clear

*** 1. Create variable that indicates that you are in CS data
	gen data = 1

*** 2. Only those who appear 4 times in the calendar year 
	sort id year month
	${gtools}egen id_year = group(id year) // Create variable that identifies individual-year 	
	bys id_year: gen nobs = _N // Keep individuals that appear 4 times during a calendar year
	keep if nobs == 4	
	bys id_year: egen gender_mean = mean(gender) // Drop individuals that, for some reason, change gender (very few cases)
	drop if gender_mean > 0 & gender_mean < 1 
	drop gender_mean
		
*** 3. Find work sectors and months worked in each sector
	replace earnings = . if job_type == 4 // Desconsidering employers (job_type == 4)
	replace earnings_def = . if job_type == 4
	replace earnings = . if job_type == 1 // Desconsidering domestics (job_type == 1)
	replace earnings_def = . if job_type == 1
	replace earnings = . if job_type == 3 & contributes_ss == 1 // Desconsidering self_employees who contribute to social security
	replace earnings_def = . if job_type == 3 & contributes_ss == 1
	bys id_year: egen mean_earnings = mean(earnings_def) 
	by id_year: egen mean_earnings_nominal = mean(earnings)
	by id_year: drop if mean_earnings == .
		
*** 4. Generate variable that identifies the sector worked and number of months working at each sector
	gen work_sector = 0
	replace work_sector = 1 if formal_emp == 1 // Formal employees workers (without domestics), with a working card and military & public
	replace work_sector = 2 if job_type == 2 & working_card == 0 // Informal: employees with no working card (without domestics)
	replace work_sector = 2 if job_type == 3 & contributes_ss == 0 // Informal: self employed & no ss contribution
	replace work_sector = . if work_sector == 0		
	tab work_sector, gen (work_sector_)
	forval i = 1/2 {
	bys id_year: gen nobs_sector_`i' = sum(work_sector_`i')
	by id_year: egen months`i' = max(nobs_sector_`i') // Total months worked at each sector `i'
	drop nobs_sector_`i'
	} // 
	${gtools}egen total_months = rowtotal(months*) // Total months worked at one of the two sectors
		
*** 5. Process of earnings annualization by id 
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
	// 11. {Jan-Feb; Nov-Dec}
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
	by id_year: replace id_consecutive = 1 if mean_spell == 1 | mean_spell == 2 // Dummy if the 4 appearences in the calendar year are consecutive (1-9 option from note)
	drop mean_spell 
	
	** 5.1 Average earnings from each sector
	forval i = 1/2 {
	bys id_year: egen mean_earnings_`i' = mean(earnings_def) if work_sector == `i'
	}
	** 5.2 Annualize earnings
	drop mw
	merge m:1 year using "${DTA_DIR}/minwage_conv_yearly.dta"
	drop if _merge == 2
	drop _merge
	sort id year month
	gen annual_earnings_nominal = mean_earnings_nominal*total_months*3 // Annualization of how much in nominal terms the person earned that year
	gen annual_earnings_mw = annual_earnings_nominal/mw // Annualization of how much in MW terms the person earned that year
	gen mean_earnings_mw = mean_earnings_nominal/mw // Average of how much in MW terms the person earned monthly in the months working
	gen annual_earnings = mean_earnings*total_months*3 // Annualization of how much in real terms the person earned in the year
	forval i = 1/2 {
	gen annual_earnings_`i' = mean_earnings_`i'*months`i'*3 // Annualization of how much in real terms the person earned in the year for each sector `i'
	}
	
*** 6. Thresholds
	keep if annual_earnings_mw >= 1.5 // Minimum threshold
	drop if mean_earnings_mw > 120 // Maximum threshold
		
*** 7. Adjusting some variables that may vary within year
	sort id year month
	order id
	drop status
	replace ind = . if earnings_def == .
	replace ind_agg = . if earnings_def == .
	replace hours = . if earnings_def == .
	replace tenure = . if earnings_def == .
	replace hh_size = . if earnings_def == . /* 15% missing for work_sector == 2 | work_sector == 1*/
	replace hh_condition = . if earnings_def == .
	replace firm_size = . if earnings_def == .
	gen hh_size_kids = hh_size - hh_size_10y
	replace hh_size_kids = 0 if hh_size_kids < 0
	bys id_year: egen total_hours = total(hours)
	replace ind_agg = 99 if ind_agg == . & inlist(work_sector, 1, 2) & earnings_def != .
	replace firm_size = 99 if firm_size == . & inlist(work_sector, 1, 2) & earnings_def != .
	replace hh_condition = 99 if hh_condition == . & inlist(work_sector, 1, 2) & earnings_def != .
	replace tenure = 0 if tenure == . & inlist(work_sector, 1, 2) & earnings_def != .
	foreach y in "ind_agg" "occ_agg" "hh_condition" "tenure" "firm_size" { 
	bys id_year `y': egen sum_earnings`y' = total(earnings_def)
	bys id_year: egen max_earnings`y' = max(sum_earnings`y')
	gen `y'_max = .
	gen index_max`y' = 0
	replace index_max`y' = 1 if max_earnings`y' == sum_earnings`y'
	replace `y'_max = `y' if index_max`y' == 1
	drop max_earnings`y' index_max`y' sum_earnings`y'
	replace `y' = `y'_max
	drop `y'_max
	}
	replace firm_size = . if firm_size == 99	
	drop annual_earnings_mw
	
*** 8. Collapsing and create dta at individual-year level
	${gtools}collapse (mean) gender annual_earnings* work_sector total_months months* season_group exrate weight data region total_hours tenure (firstnm) age hh_size_kids edu_degree race ind_agg hh_condition occ_agg firm_size, by(id year) fast
	
*** 9. Keeping individuals with only one type of sector within year
	gen aux = 0
	forval i = 1/2 {
	replace aux = 1 if annual_earnings == annual_earnings_`i'
	}
	drop if aux != 1
	drop aux	
	
*** 10. Deflating earnings with 2018 as base year
	gen deflated_earnings = annual_earnings_nominal
	gen cpi = 0
	replace cpi= 0.52623022 if year == 2002
	replace cpi= 0.60366458 if year == 2003
	replace cpi= 0.64348945 if year == 2004
	replace cpi= 0.6876942 if year == 2005
	replace cpi= 0.71646435 if year == 2006
	replace cpi= 0.74255277 if year == 2007
	replace cpi= 0.78471933 if year == 2008
	replace cpi= 0.82307668 if year == 2009
	replace cpi= 0.86454927 if year == 2010
	replace cpi= 0.92192465 if year == 2011
	replace cpi= 0.97174084 if year == 2012
	replace cpi= 1.0320307 if year == 2013
	replace cpi= 1.0973483 if year == 2014
	replace cpi= 1.1964378 if year == 2015
	global cpi2018 = 1.3951561
	replace cpi = cpi/${cpi2018}
	replace deflated_earnings = deflated_earnings/cpi
	drop annual_earnings
	rename deflated_earnings annual_earnings	
	gen logearn_sec = log(annual_earnings)
	
*** 11. Adjusting and labeling variables to finish CS dta 
	drop months* data exrate annual_earnings_1 annual_earnings_2 
	label var total_months "months worked in the job during the 4months"
	rename region metarea_PME
	gen survey = 1
	label define survey_l 1 "PME" 2 "PNADC", replace
	label values survey survey_l
	label define gender_l 0 "female" 1 "male", replace
	label values gender gender_l 
	label define work_sector_l 1 "F" 2 "I", replace
	label values work_sector work_sector_l
	rename work_sector sector
	label define edu_degree_l 1 "< primary school" 2 "primary school" 3 "high school" 4 "college", replace
	label values edu_degree edu_degree_l
	label define metarea_PME_l 26 "Recife" 29 "Salvador" 31 "Belo Horizonte" 33 "Rio de Janeiro" 35 "Sao Paulo" 41 "Curitiba" 43 "Porto Alegre", replace
	label values metarea_PME metarea_PME_l
	label define season_group_l 1 "Jan-Apr" 2 "Feb-May" 3 "Mar-Jun" 4 "Apr-Jul" 5 "May-Aug" 6 "Jun-Sep" 7 "Jul-Oct" 8 "Aug-Nov" 9 "Sep-Dec", replace
	label values season_group season_group_l
	label var ind_agg "industry (aggregated)"
	label define ind_l 1 "manufacturing" 2 "construction" 3 "commerce" 4 "finance/real estate" 5 "public services" 6 "domestic services" 7 "transport/telecom/urban" 8 "agriculture/intl/other" 0 "other", replace
	label values ind_agg ind_l
	label define hh_condition_l 1 "head of the household" 2 "spouse" 3 "son/daughter" 4 "other parent" 5 "aggregate" 6 "pensioner" 7 "domestic employee" 8 "domestic employee parent", replace
	label values hh_condition hh_condition_l
	label define race_l 1 "white" 2 "black" 3 "yellow" 4 "brown" 5 "native", replace
	label values race race_l 
	label var hh_size_kids "number of inhabitants in the household that are <= 10y old"
	label var total_hours "total hours worked in the 4-month obs"
	label var tenure "tenure (days)"
	label var occ_agg "occupation (aggregated)"
	label define occ_l 1 "public/military officers" 2 "scientists, artists" 3 "mid-level technical" 4 "administrators" 5 "service/sales workers" 6 "agricultural workers" 7 "production workers" 8 "repair/maintenance workers" 0 "other", replace
	label values occ_agg occ_l
	label define firm_size_l 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11 or more", replace
	label values firm_size firm_size_l 
	${gtools}egen id2 = group(survey id)
	drop id
	rename id2 id
	order id year survey metarea_PME gender age season_group sector annual_earnings annual_earnings_nominal edu_degree total_months	
	rename metarea_PME region_pme
	label var survey "survey used; PME: 2002-14, PNADC: 2012-19"
	label var annual_earnings "real earnings annualized"
	label var annual_earnings_nominal "nominal earnings annualized in BRL"
	label var total_months "months worked as an employee in the 4-month year PME survey"
	label var logearn_sec "log real annualized earnings"
	label var sector "sector the individual works"
	label var season_group "4-month interval from PME-survey"
	label var firm_size "number of people in the firm (incl. employees, employers, unpaid)"
	label var hh_condition "household condition"
	compress 
	save  "${DIR_WRITE_PME}/CS.dta", replace
}	


*** longitudinal
if $L == 1 {
	* load data
	use "${DIR_WRITE_PME}/panel.dta", clear
	
*** 1. Create variable that indicates that you are in L data
	gen data = 0
	label var data "data; 1 means CS data, 0 means L data"
	
*** 2. Only those who appear 4 times in the calendar year & 8 times during two consecutive years
	sort id year month
	${gtools}egen id2 = group(id) // Create variable that identifies id (in order to switch from string to numerical var)
	drop id
	rename id2 id
	${gtools}egen id_s = group(id spell_g year) // Create variable that identifies individual-year-spell 
	bys id_s: gen nobs_s = _N
	keep if nobs_s == 4 // Keep if there are 4 consecutive appearences in calendar year in a same spell
	${gtools}egen id_year = group(id year) // Create variable that identifies individual-year  
	bys id_year: egen gender_mean = mean(gender) // Drop individuals that, for some reason, change gender (very few cases)
	drop if gender_mean > 0 & gender_mean < 1 
	drop gender_mean
	bys id_year: gen nobs = _N
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Keep individuals that appear 8 times in two consecutive years
	keep if nobs == 4 // Making sure we are keeping indidviduals that appear 4 times in a calendar year

*** 3. Desconsidering individuals that are employers, domestic and self-employed who contributes to SS
	replace earnings = . if job_type == 4 // Desconsidering employers (job_type == 4)
	replace earnings_def = . if job_type == 4
	replace earnings = . if job_type == 1 // Desconsidering domestics (job_type == 1)
	replace earnings_def = . if job_type == 1
	replace earnings = . if job_type == 3 & contributes_ss == 1 // Desconsidering self_employees who contribute to social security
	replace earnings_def = . if job_type == 3 & contributes_ss == 1
	
*** 4. Keeping those who had some earnings either from formal or informal in the year
	bys id_year: egen mean_earnings = mean(earnings_def) 
	by id_year: egen mean_earnings_nominal = mean(earnings)
	by id_year: drop if mean_earnings == .
	
*** 5. Generate variable that identifies the sector worked and number of months working at each sector
	gen work_sector = 0
	replace work_sector = 1 if formal_emp == 1 // Formal employees workers (without domestics)
	replace work_sector = 2 if job_type == 2 & working_card == 0 // Informal: employees with no working card (without domestics)
	replace work_sector = 2 if job_type == 3 & contributes_ss == 0 // Informal: self employed & no ss contribution
	replace work_sector = . if work_sector == 0
	tab work_sector, gen (work_sector_)
	forval i = 1/2 {
	bys id_year: gen nobs_sector_`i' = sum(work_sector_`i')
	by id_year: egen months`i' = max(nobs_sector_`i')
	drop nobs_sector_`i'
	}
	${gtools}egen total_months = rowtotal(months*)
		
*** 6. Process of earnings annualization by id 
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
	sort id_year month
	bys id_year: gen season_group = month[1]
	** 6.1 Average earnings from each sector
	forval i = 1/2 {
	bys id_year: egen mean_earnings_`i' = mean(earnings_def) if work_sector == `i'
	}
	** 6.2 Annualize earnings
	drop mw
	merge m:1 year using "${DTA_DIR}/minwage_conv_yearly.dta"
	drop if _merge == 2
	drop _merge
	sort id year month
	gen annual_earnings_nominal = mean_earnings_nominal*total_months*3 // Annualization of how much in nominal terms the person earned that year
	gen annual_earnings_mw = annual_earnings_nominal/mw // Annualization of how much in MW terms the person earned that year
	gen mean_earnings_mw = mean_earnings_nominal/mw // Average of how much in MW terms the person earned monthly in the months working
	gen annual_earnings = mean_earnings*total_months*3 // Annualization of how much in real terms the person earned in the year
	forval i = 1/2 {
	gen annual_earnings_`i' = mean_earnings_`i'*months`i'*3 // Annualization of how much in real terms the person earned in the year for each sector `i'
	}
	keep if annual_earnings_mw >= 1.5 // Minimum threshold
	drop if mean_earnings_mw > 120 // Maximum threshold
	drop nobs_id
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Drop individuals who did not match the max&min criteria in one of the two years, i.e., keep only those who match in both
		
*** 7. Collapse information to one individual-year observation 
	sort id year month
	order id
	drop status
	replace ind = . if earnings_def == .
	replace ind_agg = . if earnings_def == .
	replace hours = . if earnings_def == .
	replace tenure = . if earnings_def == .
	replace hh_size = . if earnings_def == . /* 15% missing for work_sector == 2 | work_sector == 1*/
	replace hh_condition = . if earnings_def == .
	replace firm_size = . if earnings_def == .
	gen hh_size_kids = hh_size - hh_size_10y
	replace hh_size_kids = 0 if hh_size_kids < 0
	bys id_year: egen total_hours = total(hours)
	replace ind_agg = 99 if ind_agg == . & inlist(work_sector, 1, 2) & earnings_def != .
	replace firm_size = 99 if firm_size == . & inlist(work_sector, 1, 2) & earnings_def != .
	replace hh_condition = 99 if hh_condition == . & inlist(work_sector, 1, 2) & earnings_def != .
	replace tenure = 0 if tenure == . & inlist(work_sector, 1, 2) & earnings_def != .
	foreach y in "ind_agg" "occ_agg" "hh_condition" "tenure" "firm_size" { 
	bys id_year `y': egen sum_earnings`y' = total(earnings_def)
	bys id_year: egen max_earnings`y' = max(sum_earnings`y')
	gen `y'_max = .
	gen index_max`y' = 0
	replace index_max`y' = 1 if max_earnings`y' == sum_earnings`y'
	replace `y'_max = `y' if index_max`y' == 1
	drop max_earnings`y' index_max`y' sum_earnings`y'
	replace `y' = `y'_max
	drop `y'_max
	}		
	replace firm_size = . if firm_size == 99
	${gtools}collapse (mean) gender annual_earnings* work_sector total_months months* season_group exrate weight data region total_hours tenure (firstnm) age hh_size_kids edu_degree race ind_agg hh_condition occ_agg firm_size, by(id year) fast
	
*** 8. Calculating residuals for age and educ analysis
	gen sec = 1
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

*** 9. Only one same type of job in both years, year 1 and year 2
	gen aux = 0
	forval i = 1/2 {
	replace aux = 1 if annual_earnings == annual_earnings_`i'
	}
	drop if aux != 1 // ~10% of sample dropped
	bys id: gen nobs_id = _N
	keep if nobs_id == 2 // ~8% of sample dropped

*** 10. Identify the sector transition of each individual. 4 possible options:
	// Formal -> Formal
	// Informal -> Informal
	// Formal -> Informal
	// Informal -> Formal
	drop aux
	gen aux2 = 0
	bys id: replace aux2 = 1 if work_sector[_n] == work_sector[_n+1]
	bys id: egen mean_aux2 = mean(aux2)		
	gen f_to_inf = 0
	gen inf_to_f = 0
	sort id year
	by id: replace f_to_inf = 1 if work_sector[_n] == 1 & work_sector[_n+1] == 2 // Formal to Informal
	by id: replace inf_to_f = 1 if work_sector[_n] == 2 & work_sector[_n+1] == 1 // Informal to Formal
	by id: egen mean_f_to_inf = mean(f_to_inf)
	by id: egen mean_inf_to_f = mean(inf_to_f)
	replace work_sector = 5 if mean_f_to_inf == 0.5
	replace work_sector = 6 if mean_inf_to_f == 0.5
	drop aux2 mean_aux2 f_to_inf inf_to_f mean_f_to_inf mean_inf_to_f
	label var work_sector "Sector transition: '1' F-F, '2' I-I, '5' F-I, '6' I-F"
	tab work_sector
		
*** 11. Calculate residuals earnings change 1-year-forward
	rename researn L_researn_sec
	sort id year
	by id: gen L_researn_1y_sec = L_researn_sec[_n+1] - L_researn_sec[_n] 
	save "${DIR_WRITE_PME}/L_year_sector.dta", replace
	
*** 12. Constructing the id-year panel
	use "${DIR_WRITE_PME}/L_year_sector.dta", clear
	preserve
	drop nobs_id months* data sec exrate annual_earnings_1 annual_earnings_2
	label var total_months "months worked in the job during the 4months"
	gen survey = 1
	rename region metarea_PME
	drop annual_earnings
	gen deflated_earnings = annual_earnings_nominal
	gen cpi = 0
	replace cpi= 0.52623022 if year == 2002
	replace cpi= 0.60366458 if year == 2003
	replace cpi= 0.64348945 if year == 2004
	replace cpi= 0.6876942 if year == 2005
	replace cpi= 0.71646435 if year == 2006
	replace cpi= 0.74255277 if year == 2007
	replace cpi= 0.78471933 if year == 2008
	replace cpi= 0.82307668 if year == 2009
	replace cpi= 0.86454927 if year == 2010
	replace cpi= 0.92192465 if year == 2011
	replace cpi= 0.97174084 if year == 2012
	replace cpi= 1.0320307 if year == 2013
	replace cpi= 1.0973483 if year == 2014
	replace cpi= 1.1964378 if year == 2015
	global cpi2018 = 1.3951561
	replace cpi = cpi/${cpi2018}
	replace deflated_earnings = deflated_earnings/cpi
	rename deflated_earnings annual_earnings	
	
	** 16.1 Dropping and labeling variables
	replace ln_annual_earnings = log(annual_earnings)
	label define survey_l 1 "PME" 2 "PNADC", replace
	label values survey survey_l
	label define gender_l 0 "female" 1 "male", replace
	label values gender gender_l 
	label define work_sector_l 1 "F-F" 2 "I-I" 5 "F-I" 6 "I-F", replace
	label values work_sector work_sector_l
	label define edu_degree_l 1 "< primary school" 2 "primary school" 3 "high school" 4 "college", replace
	label values edu_degree edu_degree_l
	label define metarea_PME_l 26 "Recife" 29 "Salvador" 31 "Belo Horizonte" 33 "Rio de Janeiro" 35 "Sao Paulo" 41 "Curitiba" 43 "Porto Alegre", replace
	label values metarea_PME metarea_PME_l
	label define season_group_l 1 "Jan-Apr" 2 "Feb-May" 3 "Mar-Jun" 4 "Apr-Jul" 5 "May-Aug" 6 "Jun-Sep" 7 "Jul-Oct" 8 "Aug-Nov" 9 "Sep-Dec", replace
	label values season_group season_group_l
	label var ind_agg "industry (aggregated)"
	label define ind_l 1 "manufacturing" 2 "construction" 3 "commerce" 4 "finance/real estate" 5 "public services" 6 "domestic services" 7 "transport/telecom/urban" 8 "agriculture/intl/other" 0 "other", replace
	label values ind_agg ind_l
	label define hh_condition_l 1 "head of the household" 2 "spouse" 3 "son/daughter" 4 "other parent" 5 "aggregate" 6 "pensioner" 7 "domestic employee" 8 "domestic employee parent", replace
	label values hh_condition hh_condition_l
	label define race_l 1 "white" 2 "black" 3 "yellow" 4 "brown" 5 "native", replace
	label values race race_l 
	label var hh_size_kids "number of inhabitants in the household that are <= 10y old"
	label var total_hours "total hours worked in the 4-month obs"
	label var tenure "tenure (days)"
	label var occ_agg "occupation (aggregated)"
	label define occ_l 1 "public/military officers" 2 "scientists, artists" 3 "mid-level technical" 4 "administrators" 5 "service/sales workers" 6 "agricultural workers" 7 "production workers" 8 "repair/maintenance workers" 0 "other", replace
	label values occ_agg occ_l
	label define firm_size_l 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11 or more", replace
	label values firm_size firm_size_l 
	${gtools}egen id2 = group(survey id)
	drop id
	rename id2 id
	gen sector = .
	sort id year
	bys id: gen number = _n
	replace sector = 1 if work_sector == 1 | (work_sector == 5 & number == 1) | (work_sector == 6 & number == 2)
	replace sector = 2 if work_sector == 2 | (work_sector == 5 & number == 2) | (work_sector == 6 & number == 1)
	drop number
	label define sector_l 1 "formal" 2 "informal", replace
	label values sector sector_l
	order id year survey metarea_PME gender age season_group sector work_sector annual_earnings annual_earnings_mw annual_earnings_nominal edu_degree total_months ln_annual_earnings
	rename metarea_PME region_pme
	rename ln_annual_earnings logearn_sec
	drop L_researn_1y_sec L_researn_sec 
	label var survey "survey used; PME: 2002-14, PNADC: 2012-19"
	label var annual_earnings "real earnings annualized"
	label var annual_earnings_mw "earnings annualized in multiples of current minimum wage"
	label var annual_earnings_nominal "nominal earnings annualized in BRL"
	label var total_months "months worked as an employee in the 4-month year PME survey"
	label var logearn_sec "log real annualized earnings"
	label var sector "sector the individual works"
	label var season_group "4-month interval from PME-survey"
	label var firm_size "number of people in the firm (incl. employees, employers, unpaid)"
	label var hh_condition "household condition"
	compress 
	save "${DIR_WRITE_PME}/L.dta", replace
	
*** 17. Analysis by age_group
	restore
	preserve
	gen age_group = .
	replace age_group = 1 if age >= 25 & age < 35
	replace age_group = 2 if age >= 35 & age < 45
	replace age_group = 3 if age >= 45 & age < 56
	${gtools}egen work_sector_age = group(work_sector age_group)
	label var work_sector_age "1-3FF, 4-6II,7-9FI,10-12IF,1/4/7/10 25-34, 2/5/8/11 35-44, 3/6/9/12 45-55"
	tab age_group, gen (age_group_)
	qui forval yr = 2002/2014 {
	forval j = 1/3 {
	qui sum age_group_`j' if year == `yr' & work_sector == 1 [aw=weight], detail
	scalar s`yr'sec1age`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 1 & age_group == `j' [aw=weight], detail
	scalar std`yr'sec1age`j' = r(sd)
	scalar mean`yr'sec1age`j' = r(mean)
	qui sum age_group_`j' if year == `yr' & work_sector == 2 [aw=weight], detail
	scalar s`yr'sec2age`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 2 & age_group == `j' [aw=weight], detail
	scalar std`yr'sec2age`j' = r(sd)
	scalar mean`yr'sec2age`j' = r(mean)
	qui sum age_group_`j' if year == `yr' & work_sector == 5 [aw=weight], detail
	scalar s`yr'sec5age`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 5 & age_group == `j' [aw=weight], detail
	scalar std`yr'sec5age`j' = r(sd)
	scalar mean`yr'sec5age`j' = r(mean)			
	qui sum age_group_`j' if year == `yr' & work_sector == 6 [aw=weight], detail
	scalar s`yr'sec6age`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 6 & age_group == `j' [aw=weight], detail
	scalar std`yr'sec6age`j' = r(sd)
	scalar mean`yr'sec6age`j' = r(mean)
	}
	}
	gen share_sec_age = 0
	gen L_researn_1y_sec_mean = 0
	gen L_researn_1y_sec_sd = 0
	forval yr = 2002/2014 {
	forval j = 1/3 {
	replace share_sec_age = s`yr'sec1age`j' if year == `yr' & work_sector == 1 & age_group == `j'
	replace share_sec_age = s`yr'sec2age`j' if year == `yr' & work_sector == 2 & age_group == `j'
	replace share_sec_age = s`yr'sec5age`j' if year == `yr' & work_sector == 5 & age_group == `j'
	replace share_sec_age = s`yr'sec6age`j' if year == `yr' & work_sector == 6 & age_group == `j'			
	replace L_researn_1y_sec_mean = mean`yr'sec1age`j' if year == `yr' & work_sector == 1 & age_group == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec2age`j' if year == `yr' & work_sector == 2 & age_group == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec5age`j' if year == `yr' & work_sector == 5 & age_group == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec6age`j' if year == `yr' & work_sector == 6 & age_group == `j'
	replace L_researn_1y_sec_sd = std`yr'sec1age`j' if year == `yr' & work_sector == 1 & age_group == `j'
	replace L_researn_1y_sec_sd = std`yr'sec2age`j' if year == `yr' & work_sector == 2 & age_group == `j'
	replace L_researn_1y_sec_sd = std`yr'sec5age`j' if year == `yr' & work_sector == 5 & age_group == `j'
	replace L_researn_1y_sec_sd = std`yr'sec6age`j' if year == `yr' & work_sector == 6 & age_group == `j'
	}
	}
	${gtools}collapse (mean) share_sec_age L_researn_1y_sec_mean L_researn_1y_sec_sd, by(work_sector age_group year) fast
	save "${FINAL_DIR}/L_researn_age.dta", replace	
	** 17.1 Figures 	
	sector_age_analysis
	
*** 18. Analysis by education group
	restore
	drop if edu_degree != 1 & edu_degree != 2 & edu_degree != 3 & edu_degree != 4
	${gtools}egen work_sector_educ = group(work_sector edu_degree)
	tab edu_degree, gen (edu_degree_)
	qui forval yr = 2002/2014 {
	forval j = 1/4 {
	qui sum edu_degree_`j' if year == `yr' & work_sector == 1 [aw=weight], detail
	scalar s`yr'sec1edu`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 1 & edu_degree == `j' [aw=weight], detail
	scalar std`yr'sec1edu`j' = r(sd)
	scalar mean`yr'sec1edu`j' = r(mean)
	qui sum edu_degree_`j' if year == `yr' & work_sector == 2 [aw=weight], detail
	scalar s`yr'sec2edu`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 2 & edu_degree == `j' [aw=weight], detail
	scalar std`yr'sec2edu`j' = r(sd)
	scalar mean`yr'sec2edu`j' = r(mean)			
	qui sum edu_degree_`j' if year == `yr' & work_sector == 5 [aw=weight], detail
	scalar s`yr'sec5edu`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 5 & edu_degree == `j' [aw=weight], detail
	scalar std`yr'sec5edu`j' = r(sd)
	scalar mean`yr'sec5edu`j' = r(mean)			
	qui sum edu_degree_`j' if year == `yr' & work_sector == 6 [aw=weight], detail
	scalar s`yr'sec6edu`j' = r(mean)
	qui sum L_researn_1y_sec if year == `yr' & work_sector == 6 & edu_degree == `j' [aw=weight], detail
	scalar std`yr'sec6edu`j' = r(sd)
	scalar mean`yr'sec6edu`j' = r(mean)			
	qui sum L_researn_1y_sec if year == `yr' & edu_degree == `j' [aw=weight], detail
	scalar std`yr'edu`j' = r(sd)
	scalar mean`yr'edu`j' = r(mean)
	}
	}
	gen share_sec_edu = 0
	gen L_researn_1y_sec_mean = 0
	gen L_researn_1y_sec_sd = 0	
	gen L_researn_1y_mean = 0
	gen L_researn_1y_sd = 0
	qui forval yr = 2002/2014 {
	forval j = 1/4 {
	replace share_sec_edu = s`yr'sec1edu`j' if year == `yr' & work_sector == 1 & edu_degree == `j'
	replace share_sec_edu = s`yr'sec2edu`j' if year == `yr' & work_sector == 2 & edu_degree == `j'
	replace share_sec_edu = s`yr'sec5edu`j' if year == `yr' & work_sector == 5 & edu_degree == `j'
	replace share_sec_edu = s`yr'sec6edu`j' if year == `yr' & work_sector == 6 & edu_degree == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec1edu`j' if year == `yr' & work_sector == 1 & edu_degree == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec2edu`j' if year == `yr' & work_sector == 2 & edu_degree == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec5edu`j' if year == `yr' & work_sector == 5 & edu_degree == `j'
	replace L_researn_1y_sec_mean = mean`yr'sec6edu`j' if year == `yr' & work_sector == 6 & edu_degree == `j'			
	replace L_researn_1y_sec_sd = std`yr'sec1edu`j' if year == `yr' & work_sector == 1 & edu_degree == `j'
	replace L_researn_1y_sec_sd = std`yr'sec2edu`j' if year == `yr' & work_sector == 2 & edu_degree == `j'
	replace L_researn_1y_sec_sd = std`yr'sec5edu`j' if year == `yr' & work_sector == 5 & edu_degree == `j'
	replace L_researn_1y_sec_sd = std`yr'sec6edu`j' if year == `yr' & work_sector == 6 & edu_degree == `j'			
	replace L_researn_1y_sd = std`yr'edu`j' if year == `yr' & edu_degree == `j'
	replace L_researn_1y_mean = mean`yr'edu`j' if year == `yr' & edu_degree == `j'
	}
	}
	${gtools}collapse (mean) share_sec_edu L_researn_1y_sec_mean L_researn_1y_sec_sd L_researn_1y_sd L_researn_1y_mean, by(work_sector edu_degree year) fast
	save "${FINAL_DIR}/L_researn_educ.dta", replace	
		
	** 18.1 Figures
	sector_edu_analysis	
	erase "${DIR_WRITE_PME}/L_year_sector.dta"	
}


*** transitions
if $L_transition == 1 {
	* load data
	use "${DIR_WRITE_PME}/panel.dta", clear
	
	* L (1-year-forward)
*** 1. Create variable that indicates that you are in L data
	gen data = 0
	label var data "data; 1 means CS data, 0 means L data"
	
*** 2. Only those who appear 4 times in the calendar year & 8 times during two consecutive years
	sort id year month
	${gtools}egen id_s = group(id spell_g year) // Create variable that identifies individual-year-spell 
	bys id_s: gen nobs_s = _N
	keep if nobs_s == 4 // Keep if there are 4 consecutive appearences in calendar year in a same spell
	${gtools}egen id_year = group(id year) // Create variable that identifies individual-year  
	bys id_year: egen gender_mean = mean(gender) // Drop individuals that, for some reason, change gender (very few cases)
	drop if gender_mean > 0 & gender_mean < 1 
	drop gender_mean
	bys id_year: gen nobs = _N
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Keep individuals that appear 8 times in two consecutive years
	keep if nobs == 4 // Making sure we are keeping indidviduals that appear 4 times in a calendar year
	
*** 3. Find work sectors and months worked in each sector
	replace earnings = . if job_type == 4 // Desconsidering employers (job_type == 4)
	replace earnings_def = . if job_type == 4
	replace earnings = . if job_type == 1 // Desconsidering domestics (job_type == 1)
	replace earnings_def = . if job_type == 1
	replace earnings = . if job_type == 3 & contributes_ss == 1 // Desconsidering self_employees who contribute to social security
	replace earnings_def = . if job_type == 3 & contributes_ss == 1
	bys id_year: egen mean_earnings = mean(earnings_def) 
	by id_year: egen mean_earnings_nominal = mean(earnings)
	gen first_year = 0
	replace first_year = 1 if spell < 5
	gen mean_earnings_first_year = first_year*mean_earnings
	replace mean_earnings_first_year = 0 if first_year == 0
	drop if mean_earnings_first_year == .
	drop nobs_id
	bys id: gen nobs_id = _N
	keep if nobs_id == 8
		
*** 4. Generate variable that identifies the sector worked and number of months working at each sector
	gen work_sector = 0
	replace work_sector = 1 if formal_emp == 1 // Formal employees workers (without domestics)
	replace work_sector = 2 if job_type == 2 & working_card == 0 // Informal: employees with no working card (without domestics)
	replace work_sector = 2 if job_type == 3 & contributes_ss == 0 // Informal: self employed & no ss contribution
	replace work_sector = 3 if work_sector == 0 // "non-employed"
	tab work_sector, gen (work_sector_)
	forval i = 1/3 {
	bys id_year: gen nobs_sector_`i' = sum(work_sector_`i')
	by id_year: egen months`i' = max(nobs_sector_`i')
	drop nobs_sector_`i'
	}
	${gtools}egen total_months = rowtotal(months*)
		
*** 5. Process of earnings annualization by id 
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
	sort id_year month
	bys id_year: gen season_group = month[1]
	** 5.1 Average earnings from each sector
	forval i = 1/2 {
	bys id_year: egen mean_earnings_`i' = mean(earnings_def) if work_sector == `i'
	}
	** 5.2 Annualize earnings
	drop mw
	merge m:1 year using "${DTA_DIR}/minwage_conv_yearly.dta"
	drop if _merge == 2
	drop _merge
	sort id year month
	gen annual_earnings_nominal = mean_earnings_nominal*total_months*3 // Annualization of how much in nominal terms the person earned that year
	gen annual_earnings_mw = annual_earnings_nominal/mw // Annualization of how much in MW terms the person earned that year
	gen mean_earnings_mw = mean_earnings_nominal/mw // Average of how much in MW terms the person earned monthly in the months working
	gen annual_earnings = mean_earnings*total_months*3 // Annualization of how much in real terms the person earned in the year
	forval i = 1/2 {
	gen annual_earnings_`i' = mean_earnings_`i'*months`i'*3 // Annualization of how much in real terms the person earned in the year for each sector `i'
	}
	gen annual_earnings_mw_first = 0
	gen mean_earnings_mw_first = 0
	
*** 6. Thresholds
	replace annual_earnings_mw_first = annual_earnings_mw*first_year
	replace mean_earnings_mw_first = mean_earnings_mw*first_year		
	replace annual_earnings_mw_first = 1.5 if first_year == 0
	replace mean_earnings_mw_first = 120 if first_year == 0		
	keep if annual_earnings_mw_first >= 1.5 // Minimum threshold
	drop if mean_earnings_mw_first > 120  // Maximum threshold		
	replace annual_earnings_mw_first = 0 if first_year == 0
	replace mean_earnings_mw_first = 0 if first_year == 0
	drop mean_earnings_mw_first annual_earnings_mw_first
	drop nobs_id
	bys id: gen nobs_id = _N
	keep if nobs_id == 8 // Drop individuals who did not match the max&min criteria in one of the two years, i.e., keep only those who match in both
	${gtools}collapse (mean) age gender annual_earnings* work_sector total_months months* season_group exrate weight data first_year, by(id year) fast

*** 7. // Find residual earnings, controlling for age, season group and run separately by gender & year
	// By construction, we do not impose that residuals are zero within sector
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
	rename ln_annual_earnings logearn
	drop if year == 2016

*** 8. Only one same type of job in both years, year 1 and year 2
	gen aux = 0
	forval i = 1/2 {
	replace aux = 1 if annual_earnings == annual_earnings_`i'
	}
	drop if aux != 1 
	bys id: gen nobs_id = _N
	keep if nobs_id == 2 
	replace work_sector = 3 if annual_earnings == .
	drop aux
	gen aux2 = 0
	bys id: replace aux2 = 1 if work_sector[_n] == work_sector[_n+1]
	bys id: egen mean_aux2 = mean(aux2)		
	gen f_to_inf = 0
	gen inf_to_f = 0
	sort id year
	by id: replace f_to_inf = 1 if work_sector[_n] == 1 & work_sector[_n+1] == 2 // Formal to Informal
	by id: replace inf_to_f = 1 if work_sector[_n] == 2 & work_sector[_n+1] == 1 // Informal to Formal
	by id: egen mean_f_to_inf = mean(f_to_inf)
	by id: egen mean_inf_to_f = mean(inf_to_f)
	replace work_sector = 5 if mean_f_to_inf == 0.5
	replace work_sector = 6 if mean_inf_to_f == 0.5
	drop aux2 mean_aux2 f_to_inf inf_to_f mean_f_to_inf mean_inf_to_f
	gen f_to_out = 0
	gen i_to_out = 0
	by id: replace f_to_out = 1 if work_sector[_n] == 1 & work_sector[_n+1] == 3
	by id: replace i_to_out = 1 if work_sector[_n] == 2 & work_sector[_n+1] == 3
	by id: egen mean_f_to_out = mean(f_to_out)
	by id: egen mean_i_to_out = mean(i_to_out)
	replace work_sector = 7 if mean_f_to_out == 0.5
	replace work_sector = 8 if mean_i_to_out == 0.5
	label var work_sector "Sector transition: '1' F-F, '2' I-I, '5' F-I, '6' I-F, '7' F-OUT, '8' I-OUT"
	tab work_sector
	
*** 9. Finding mean transitions in each sector at first year
	keep id year age gender researn logearn weight work_sector data first_year
	keep if first_year == 1
	preserve 
	tab work_sector, gen (work_sector_)	
	gen informal_1 = work_sector_2 + work_sector_4 + work_sector_6
	gen formal_1 = work_sector_1 + work_sector_3  + work_sector_5	
	gen mean_if = .
	gen mean_fi = .
	gen mean_iout = .
	gen mean_fout = .
	qui forval y = 2002/2014 {
	sum work_sector_4 if informal_1 == 1 & year == `y' [aw=weight]
	scalar meanif_`y' = r(mean)
	replace mean_if = meanif_`y' if year == `y' & informal_1 == 1	
	sum work_sector_3 if formal_1 == 1 & year == `y' [aw=weight]
	scalar meanfi_`y' = r(mean)
	replace mean_fi = meanfi_`y' if year == `y' & formal_1 == 1
	sum work_sector_5 if formal_1 == 1 & year == `y' [aw=weight]
	scalar meanfout_`y' = r(mean)
	replace mean_fout = meanfout_`y' if year == `y' & formal_1 == 1
	sum work_sector_6 if informal_1 == 1 & year == `y' [aw=weight]
	scalar meaniout_`y' = r(mean)
	replace mean_iout = meaniout_`y' if year == `y' & informal_1 == 1
	}
	${gtools}collapse (mean) mean_if mean_fi mean_fout mean_iout, by (year) fast
	gen mean_ii = 1 - mean_iout - mean_if
	gen mean_ff = 1 - mean_fi - mean_fout
	transitions_graphs
		
*** 11. Finding mean transitions in each sector at first year by percentile and year
	restore
	global percentiles = 20
	qui forval i = 2002/2014 {
	preserve
	keep if year == `i' 
	pctile pct = researn [aw=weight], nq(20)
	keep year pct 
	keep if pct != .
	gen order = _n
	save "${TEMP_DIR}/pct_`i'.dta", replace
	restore
	}		
	preserve
	use "${TEMP_DIR}/pct_2002.dta", clear
	qui forval i = 2003/2014 {
	append using "${MAIN_DIR}/temp/pct_`i'.dta"
	}
	${gtools}reshape wide pct, i(year) j(order)
	save "${TEMP_DIR}/pct.dta", replace
	qui forval i = 2002/2014 {
	erase "${TEMP_DIR}/pct_`i'.dta"
	sleep 100
	}
	restore	
	merge m:1 year using "${TEMP_DIR}/pct.dta"
	drop _merge 
	gen pct_ind = 0	
	qui forval i=1/19 {
	replace pct_ind = `i' if researn >= pct`i'
	}		
	replace pct_ind = pct_ind + 1
	tab work_sector, gen (work_sector_)
	gen informal_1 = work_sector_2 + work_sector_4 + work_sector_6
	gen formal_1 = work_sector_1 + work_sector_3  + work_sector_5
	gen mean_if = .
	gen mean_fi = .
	gen mean_iout = .
	gen mean_fout = .	
	qui forval i = 1/20 {
	sum work_sector_4 if informal_1 == 1 & pct_ind == `i' [aw=weight]
	scalar meanif_`i' = r(mean)
	replace mean_if = meanif_`i' if pct_ind == `i' & informal_1 == 1
	sum work_sector_3 if formal_1 == 1 & pct_ind == `i' [aw=weight]
	scalar meanfi_`i' = r(mean)
	replace mean_fi = meanfi_`i' if pct_ind == `i' & formal_1 == 1
	sum work_sector_5 if formal_1 == 1 & pct_ind == `i' [aw=weight]
	scalar meanfout_`i' = r(mean)
	replace mean_fout = meanfout_`i' if pct_ind == `i' & formal_1 == 1	
	sum work_sector_6 if informal_1 == 1 & pct_ind == `i' [aw=weight]
	scalar meaniout_`i' = r(mean)
	replace mean_iout = meaniout_`i' if pct_ind == `i' & informal_1 == 1
	}
	gen mean_if_year = .
	gen mean_fi_year = .
	gen mean_iout_year = .
	gen mean_fout_year = .	
	qui forval y = 2002/2014 {
	qui forval i = 1/20 {
	sum work_sector_4 if informal_1 == 1 & pct_ind == `i' & year == `y' [aw=weight]
	scalar meanif_`i'_`y' = r(mean)
	replace mean_if_year = meanif_`i'_`y' if pct_ind == `i' & informal_1 == 1 & year == `y' 
	sum work_sector_3 if formal_1 == 1 & pct_ind == `i' [aw=weight]
	scalar meanfi_`i'_`y' = r(mean)
	replace mean_fi_year = meanfi_`i'_`y' if pct_ind == `i' & formal_1 == 1 & year == `y' 		
	sum work_sector_5 if formal_1 == 1 & pct_ind == `i' & year == `y' [aw=weight]
	scalar meanfout_`i'_`y' = r(mean)
	replace mean_fout_year = meanfout_`i'_`y' if pct_ind == `i' & formal_1 == 1 & year == `y' 		
	sum work_sector_6 if informal_1 == 1 & pct_ind == `i' & year == `y'  [aw=weight]
	scalar meaniout_`i'_`y' = r(mean)
	replace mean_iout_year = meaniout_`i'_`y' if pct_ind == `i' & informal_1 == 1 & year == `y' 
	}
	}	
	${gtools}collapse (mean) mean_if mean_fi mean_fout mean_iout mean_if_year mean_fi_year mean_fout_year mean_iout_year, by (pct_ind year) fast
	replace pct_ind = pct_ind*100/$percentiles - 100/(20/2)
	replace pct_ind = pct_ind + 7.5
	gen mean_ii_year = 1 - mean_iout_year - mean_if_year
	gen mean_ff_year = 1 - mean_fi_year - mean_fout_year
	** 11.1 Graphs program
	transitions_graphs_pctyear
		
*** 12. Finding mean transitions in each sector at first year by percentile (pooled years)
	${gtools}collapse (mean) mean_if mean_ff mean_fout mean_iout, by (pct_ind) fast
	gen mean_ii = 1 - mean_iout - mean_if
	gen mean_fi = 1 - mean_ff - mean_fout
	** 12.1 Graphs program
	transitions_graphs_pct
}


*** second jobs
if $CS_secondjob == 1 {
*** count first & second job individuals (for APPENDIX)
	use "${DIR_WRITE_PME}/panel.dta", clear
	*** 1. Only those who appear 4 times in the calendar year 
	sort id year month
	${gtools}egen id_year = group(id year) // Create variable that identifies individual-year 
	bys id_year: gen nobs = _N // Keep individuals that appear 4 times during a calendar year
	keep if nobs == 4
	bys id_year: egen gender_mean = mean(gender) // Drop individuals that, for some reason, change gender (very few cases)
	drop if gender_mean > 0 & gender_mean < 1 
	drop gender_mean
			
*** FIRST JOB
*** 2. Find work sectors and months worked in each sector
	replace earnings = . if job_type == 4 // Desconsidering employers (job_type == 4)
	replace earnings_def = . if job_type == 4
	replace earnings = . if job_type == 1 // Desconsidering domestics (job_type == 1)
	replace earnings_def = . if job_type == 1
	replace earnings = . if job_type == 3 & contributes_ss == 1 // Desconsidering self_employees who contribute to social security
	replace earnings_def = . if job_type == 3 & contributes_ss == 1
	bys id_year: egen mean_earnings = mean(earnings_def) 
	by id_year: egen mean_earnings_nominal = mean(earnings)
	by id_year: drop if mean_earnings == .

*** 3. Generate variable that identifies the sector worked and number of months working at each sector
	gen work_sector = 0
	replace work_sector = 1 if formal_emp == 1 // Formal employees workers (without domestics), with a working card and military & public
	replace work_sector = 2 if job_type == 2 & working_card == 0 // Informal: employees with no working card (without domestics)
	replace work_sector = 2 if job_type == 3 & contributes_ss == 0 // Informal: self employed & no ss contribution
	replace work_sector = . if work_sector == 0
	tab work_sector, gen (work_sector_)
	forval i = 1/2 {
	bys id_year: gen nobs_sector_`i' = sum(work_sector_`i')
	by id_year: egen months`i' = max(nobs_sector_`i') // Total months worked at each sector `i'
	drop nobs_sector_`i'
	} // 
	${gtools}egen total_months = rowtotal(months*) // Total months worked at one of the two sectors		
			
	** 3.2 Annualize earnings	
	forval i = 1/2 {
	bys id_year: egen mean_earnings_`i' = mean(earnings_def) if work_sector == `i'
	}
	drop mw
	merge m:1 year using "${DTA_DIR}/minwage_conv_yearly.dta"
	drop if _merge == 2
	drop _merge
	sort id year month
	gen annual_earnings_nominal = mean_earnings_nominal*total_months*3 // Annualization of how much in nominal terms the person earned that year
	gen annual_earnings_mw = annual_earnings_nominal/mw // Annualization of how much in MW terms the person earned that year
	gen mean_earnings_mw = mean_earnings_nominal/mw // Average of how much in MW terms the person earned monthly in the months working
	gen annual_earnings = mean_earnings*total_months*3 // Annualization of how much in real terms the person earned in the year
	forval i = 1/2 {
	gen annual_earnings_`i' = mean_earnings_`i'*months`i'*3 // Annualization of how much in real terms the person earned in the year for each sector `i'
	}
	keep if annual_earnings_mw >= 1.5 // Minimum threshold	
			
*** Sectors: full formal within year, full informal within year, switcher within year
	gen year_sector = 0
	gen aux = 0
	bys id_year: egen mean_earnings_1_aux = mean(mean_earnings_1)
	drop mean_earnings_1
	rename mean_earnings_1_aux mean_earnings_1
	bys id_year: egen mean_earnings_2_aux = mean(mean_earnings_2)
	drop mean_earnings_2
	rename mean_earnings_2_aux mean_earnings_2
	forval i = 1/2 {
	replace aux = 1 if mean_earnings == mean_earnings_`i'
	}
	replace year_sector = 1 if aux == 1 & mean_earnings == mean_earnings_1
	replace year_sector = 2 if aux == 1 & mean_earnings == mean_earnings_2
	replace year_sector = 3 if aux == 0
			
*** SECOND JOB & INTENSIVE MARGIN ANALYSIS
	replace second_job = 0 if second_job == .
	gen laborforce = 0
	replace laborforce = 1 if work_sector != .
	replace second_job = . if laborforce == 0
	bys year work_sector: egen share_second_job = wtmean(second_job), weight(weight)
	bys year work_sector: egen mean_hours = wtmean(hours), weight(weight)
	bys year work_sector: egen mean_hours_second = wtmean(hours_second_job), weight(weight)
	bys id_year: egen has_second_job = mean(second_job)
	preserve
	${gtools}collapse (mean) has_second_job share_second_job mean_hours mean_hours_second, by (work_sector year) fast
	save "${FINAL_DIR}/secondjob_analysis.dta", replace
	restore
	drop if work_sector == .
	sort year work_sector
	keep if has_second_job > 0
	replace contributes_ss_second = . if second_job == 0
	bys year work_sector: egen mean_contributes_ss_second = wtmean(contributes_ss_second), weight(weight)
	${gtools}collapse (mean) mean_contributes_ss_second, by (work_sector year) fast
	sort year work_sector
	drop if work_sector == .
}
