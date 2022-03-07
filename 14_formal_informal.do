********************************************************************************
* DESCRIPTION: Investigates formal-informal transitions in Brazil based on PME
*              microdata.
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


*** settings
* define how to group by earnings
global n_quantiles = 4
global cell_min = 25

* set which surveys to keep for plots
global survey_min = 1 // 1 = PME, 2 = PNAD-Continua
global survey_max = 1 // 1 = PME, 2 = PNAD-Continua

* text size
global text_size = "medlarge" // or "large"

* figure margins
global l_val = 2
global r_val = 2
global b_val = 2
global t_val = 2

* size of legend symbols
global symxsize = .45


*** create directories
cap n mkdir "${FORMAL_INFORMAL_DIR}"


*** clean data
* loop through cross-sectional and longitudinal data
foreach data in CS L {

	* load data
	if "`data'" == "CS" {
		use ///
			id year ///
			season_group ///
			region_pme ///
			gender race edu_degree age hh_size_kids firm_size ind_agg occ_agg tenure total_hours /// hh_condition
			sector ///
			logearn_sec /// researn_sec
			weight ///
			using "${ROOT_DIR}/7_PME/code/dta/processed/CS.dta", clear
		gen byte survey = 1
		label define sur_l 1 "PME" 2 "PNADC", replace
		label val survey sur_l
	}
	if "`data'" == "L" {
		use ///
			id year ///
			survey ///
			season_group ///
			region_pme  ///
			gender race edu_degree age hh_size_kids firm_size ind_agg occ_agg tenure total_hours /// hh_condition
			sector transition ///
			logearn_sec /// researn_sec l_researn_1y_sec
			weight ///
			using "${ROOT_DIR}/7_PME/code/dta/processed/L.dta", clear
	}
	
	* sample selection
	keep if inrange(year, ${year_min}, ${year_max}) & inrange(survey, ${survey_min}, ${survey_max})

	* rename variables
	rename season_group season_pme
	//if "`data'" == "L" rename quarter_ref season_pnad
	if $survey_min == 1 & $survey_max == 1 {
		rename season_pme season
		rename region_pme region
		//if "`data'" == "L" drop season_pnad region_pnad
	}
	else if $survey_min == 2 & $survey_max == 2 {
		rename season_pnad season
		rename region_pnad region
		drop season_pme region_pme
	}
	else if $survey_min == 1 & $survey_max == 2 {
		disp as error "USER WARNING: Using incompatible season and region definitions between PME survey and PNAD-Continua survey!"
		${gtools}egen byte season = rowtotal(season_pme season_pnad)
		label var season "Survey season (4 months in PME, 1 quarter in PNAD-Continua)"
		${gtools}egen byte region = rowtotal(region_pme region_pnad)
		label var region "Survey region (6 metropolitan regions in PME, 27 states in PNAD-Continua)"
		drop season_pme season_pnad region_pme region_pnad
	}
	else {
		disp as error "USER ERROR: Incompatible survey selection (survey_min = `survey_min', survey_max = `survey_max')!"
		error 1
	}
	rename logearn_sec earn
// 	rename researn_sec earn_res
// 	if "`data'" == "L" rename l_researn_1y_sec earn_res_change
	rename edu_degree edu
	rename hh_size_kids kids
	rename total_hours hours
	rename ind_agg ind
	rename occ_agg occ
	
	* label sector
	label var sector "Sector of employment"
	label define sec_l 1 "Formal" 2 "Informal", replace
	label val sector sec_l
	
	* recode gender
	bys id (gender): replace gender = gender[1]
	
	* recode race
	replace race = 1 if race == 0
	bys id (race): replace race = race[1]
	
	* recode edu
	bys id (edu): replace edu = edu[1]

	* recode tenure
	replace tenure = ceil(tenure/30/12)
	label var tenure "Tenure (years)"

	* recode hours
	replace hours = ceil(hours/4)
	label var hours "Weekly hours worked"
	
	* compute residual earnings	
	reghdfe earn [aw=weight], a(i.gender##i.year##(i.season i.age)) resid(earn_res) keepsingletons
	recast float earn_res, force
	label var earn_res "Residual log earnings"
	
	* compute 1-year forward changes in residual earnings
	if "`data'" == "L" {
		xtset id year
		gen float earn_res_change = F.earn_res - earn_res
		label var earn_res_change "1-year forward change in residual log earnings"
	}
	
	* compute earnings quantiles
	if "${gtools}" == "" {
		${gtools}levelsof year
		local years_list = r(levels)
		gen byte earn_q = .
		foreach y of local years_list {
			xtile earn_q_temp = earn [aw=weight] if year == `y', n(${n_quantiles})
			replace earn_q = earn_q_temp if earn_q == . & year == `y'
			drop earn_q_temp
		}
	}
	else gquantiles earn_q = earn [aw=weight], xtile n(${n_quantiles}) by(year)
	label var earn_q "Earnings quantile (1 = lowest, ${n_quantiles} = highest)"
	local eaq_l_str = `" "'
	forval q = 1/$n_quantiles {
		if `q' == 1 local eaq_l_str = `" `eaq_l_str' `q' "Q1 (lowest)" "'
		else if `q' == $n_quantiles local eaq_l_str = `" `eaq_l_str' `q' "Q${n_quantiles} (highest)" "'
		else local eaq_l_str = `" `eaq_l_str' `q' "Q`q'" "'
	}
	label define eaq_l `eaq_l_str', replace
	label val earn_q eaq_l
	
	* generate race groups
	recode race (1=1) (2 3 4 5=2), generate(race_group)
	label var race_group "Race (categories)"
	label define rac_g_l 1 "White" 2 "Black/Yellow/Brown/native", replace
	label val race_group rac_g_l

	* generate education groups
	recode edu (1/2=1) (3/4=2), generate(edu_group)
	label var edu_group "Education (categories)"
	label define edu_g_l 1 "Less than high school" 2 "High school or more", replace
	label val edu_group edu_g_l

	* generate age groups
	recode age (25/34=1) (35/44=2) (45/55=3), generate(age_group)
	label var age_group "Age group"
	label define age_g_l 1 "25-34" 2 "35-44" 3 "45-55", replace
	label val age_group age_g_l

	* generate industry groups
	recode ind (1=1) (2 8 7=2) (3 4 5=3), generate(ind_group)
	label var ind_group "Industry (categories)"
	label define ind_g_l 1 "Manufacturing" 2 "Agriculture/other" 3 "Services", replace
	label val ind_group ind_g_l
	
	* generate occupation groups
	recode occ (0 3 6 7 8=1) (1 2 4 5=2), generate(occ_group)
	label var occ_group "Occupation (categories)"
	label define occ_g_l 1 "Blue collar" 2 "White collar", replace
	label val occ_group occ_g_l

	* generate firm size groups
	recode firm_size (1/5=1) (6/10=2) (11=3), generate(firm_size_group)
	label var firm_size_group "Firm size (categories)"
	label define siz_g_l 1 "1-5 employees" 2 "6-10 employees" 3 ">10 employees", replace
	label val firm_size_group siz_g_l

	* generate kids group
	recode kids (0=1) (1/99=2), generate(kids_group)
	label var kids_group "Ind: Has kids?"
	label define kid_g_l 1 "No kids" 2 "At least one kid", replace
	label val kids_group kid_g_l

	* generate period indicator
	bys id (year): gen byte period = _n
	label var period "Period (1 or 2)"

	* generate sum of weights
	else if "`data'" == "L" {
		if "${gtools}" == "" bys id: egen double weight_sum = total(weight)
		else gegen double weight_sum = total(weight), by(id)
		label var weight_sum "Sum of weights across periods"
	}
	
	* compute first and last year of plots
	sum year, meanonly
	global year_min_loop = r(min)
	global year_max_loop = r(max)
	
	* save cleaned data
	sort id year
	if "`data'" == "CS" {
		local var_transition = ""
		local var_earn_res_change = ""
		local var_weight_sum = ""
	}
	else if "`data'" == "L" {
		local var_transition = "transition"
		local var_earn_res_change = "earn_res_change"
		local var_weight_sum = "weight_sum"
	}
	order ///
		id year period ///
		survey ///
		season ///
		region ///
		gender race race_group edu edu_group age age_group kids kids_group firm_size firm_size_group ind ind_group occ occ_group tenure hours ///
		sector `var_transition' ///
		earn_q earn earn_res `var_earn_res_change' ///
		weight `var_weight_sum'
	compress
	desc, fullnames
	sum [aw=weight], sep(0)
	save "${PME_OUTPUT_DIR}/formal_informal_`data'.dta", replace
}


*** summary statistics
* load data
use "${PME_OUTPUT_DIR}/formal_informal_CS.dta", clear

* create dummies
foreach var of varlist gender race_group edu_group age_group kids_group firm_size_group ind_group occ_group {
	tab `var', gen(`var'_)
}

* generate indicator
gen byte one = 1

* generate "overall" (i.e., both sectors) category
expand 2, gen(duplicate)
replace sector = 0 if duplicate == 1
label define sec_le 0 "Overall" 1 "Formal" 2 "Informal", replace
label val sector sec_le

* compute statistics, overall and sector
${gtools}collapse ///
	(mean) earn_mean=earn ///
	(sd) earn_sd=earn ///
	(mean) gender_1 race_group_2 edu_group_2 age_group_2 age_group_3 kids_group_2 ind_group_1 ind_group_3 occ_group_2 firm_size_group_2 firm_size_group_3 ///
	(mean) tenure_mean=tenure ///
	(sd) tenure_sd=tenure ///
	(mean) hours_mean=hours ///
	(sd) hours_sd=hours ///
	(rawsum) N_w=weight N_unw=one ///
	[aw=weight], by(sector) fast
foreach var of varlist * {
	format %5.3f `var'
}
format %12.0fc N_w N_unw

* save table
export delim using "${PME_OUTPUT_DIR}/summary_stats_formal_informal.csv", replace


*** evolution of informal sector shares
* load data
use "${PME_OUTPUT_DIR}/formal_informal_CS.dta", clear

* generate informal indicator
gen byte informal = (sector == 2) if sector < .

* generate "overall" (i.e., both sectors) category
expand 2, gen(duplicate)
replace earn_q = 0 if duplicate == 1
local eaq_le_str = `" 0 "Overall" "'
forval q = 1/$n_quantiles {
	if `q' == 1 local eaq_le_str = `" `eaq_le_str' `q' "Q1 (lowest)" "'
	else if `q' == $n_quantiles local eaq_le_str = `" `eaq_le_str' `q' "Q${n_quantiles} (highest)" "'
	else local eaq_le_str = `" `eaq_le_str' `q' "Q`q'" "'
}
label define eaq_le `eaq_le_str', replace
label val earn_q eaq_le

* compute informal employment shares, overall and by income quantile
${gtools}collapse ///
	(mean) informal ///
	[aw=weight], by(earn_q year) fast

* plot overall informality share
tw ///
	(connected informal year if earn_q == 0, lcolor(black) lpattern(solid) mcolor(black) msymbol(O)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(0(.1).8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Share of informal employment", size(${text_size})) ///
	legend(off) ///
	name(evolution_informality, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_informality.eps", replace

* plot informality share by earnings quantile
local list_colors = "blue red green orange purple"
local list_symbols = "Dh Th Sh + X"
local list_lines = "longdash shortdash longdash_dot shortdash_dot"
local connected_str = ""
local legend_str = ""
forval q = 1/$n_quantiles {
	local color: word `q' of `list_colors'
	local symbol: word `q' of `list_symbols'
	local line: word `q' of `list_lines'
	local connected_str = "`connected_str' (connected informal year if earn_q == `q', lcolor(`color') lpattern(`line') mcolor(`color') msymbol(`symbol'))"
	if `q' == 1 local legend_str = `" `legend_str' `q' "Q1 (lowest)" "'
	else if `q' == $n_quantiles local legend_str = `" `legend_str' `q' "Q${n_quantiles} (highest)" "'
	else local legend_str = `" `legend_str' `q' "Q`q'" "'
}
tw ///
	`connected_str' ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(0(.1).8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Share of informal employment", size(${text_size})) ///
	legend(order(`legend_str') cols(1) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_informality_by_earn_q, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_informality_by_earn_q.eps", replace
	

*** Mincer regressions
* define list of variables to absorb
local vars_abs = "i.year##i.season##i.region i.gender i.race i.edu i.age i.kids i.ind i.occ"

* load data
use "${PME_OUTPUT_DIR}/formal_informal_CS.dta", clear

* convert continuous variables to logarithms
replace tenure = ln(tenure)
replace hours = ln(hours)

* generate indicator for observations being balanced (i.e., having all nonmissing variables)
gen byte balanced = 1
local vars_balanced = subinstr("id earn sector weight firm_size tenure hours `vars_abs'", "i.", "", .)
local vars_balanced = subinstr("`vars_balanced'", "##", " ", .)
foreach var of varlist `vars_balanced' {
	replace balanced = 0 if `var' == .
}

* check which variables vary within person over time
local vars_constant = ""
local vars_vary = ""
foreach var of varlist `vars_balanced' {
	if "${gtools}" == "" bys id: egen min = min(`var')
	else gegen min = min(`var'), by(id)
	if "${gtools}" == "" bys id: egen max = max(`var')
	else gegen max = max(`var'), by(id)
	gen byte varies = (min < max)
	sum varies, meanonly
	if r(max) == 0 local vars_constant = "`vars_constant' `var'"
	else if r(max) == 1 local vars_vary = "`vars_vary' `var'"
	drop min max varies
}
disp "Variables that are constant within person over time:  `vars_constant'"
disp "Variables that vary within person over time:  `vars_vary'"

* number of observations, weighted and unweighted
sum balanced if balanced==1 [aw=weight]

* compute raw informality penalty
disp _newline(3)
disp "*** unbalanced:"
reghdfe earn i.sector [pw=weight], noabsorb keepsingletons vce(cluster id)
disp _newline(3)
disp "*** balanced:"
reghdfe earn i.sector [pw=weight] if balanced == 1, noabsorb keepsingletons vce(cluster id)

* compute conditional informality penalty, not controlling for either firm size or person FEs
disp _newline(3)
disp "*** unbalanced:"
reghdfe earn i.sector c.tenure c.hours [pw=weight], a(`vars_abs') keepsingletons vce(cluster id)
disp _newline(3)
disp "*** balanced:"
reghdfe earn i.sector c.tenure c.hours [pw=weight] if balanced == 1, a(`vars_abs') keepsingletons vce(cluster id)

* compute conditional informality penalty, not controlling for firm size but controlling for person FEs
disp _newline(3)
disp "*** unbalanced:"
reghdfe earn i.sector c.tenure c.hours [pw=weight], a(`vars_abs' i.id) keepsingletons vce(cluster id)
disp _newline(3)
disp "*** balanced:"
reghdfe earn i.sector c.tenure c.hours [pw=weight] if balanced == 1, a(`vars_abs' i.id) keepsingletons vce(cluster id)

* compute conditional informality penalty, controlling for firm size but not for person FEs
disp _newline(3)
disp "*** unbalanced = balanced:"
reghdfe earn i.sector i.firm_size c.tenure c.hours [pw=weight], a(`vars_abs') keepsingletons vce(cluster id)

* compute conditional informality penalty, controlling for both firm size and person FEs
disp _newline(3)
disp "*** unbalanced = balanced:"
reghdfe earn i.sector i.firm_size c.tenure c.hours [pw=weight], a(`vars_abs' i.id) keepsingletons vce(cluster id)


*** cross-sectional plots
* parameters for cross-sectional plots
global earn_min = 6
global earn_step = 2
global earn_max = 14
global earn_res_min = -3
global earn_res_step = 1
global earn_res_max = 4
global earn_dens_min = 0
global earn_dens_step = .2
global earn_dens_max = 1.8
global earn_res_dens_min = 0
global earn_res_dens_step = .2
global earn_res_dens_max = 1.4

* load cross-sectional data
use "${PME_OUTPUT_DIR}/formal_informal_CS.dta", clear

* get levels of key variables
foreach var of varlist gender edu_group age_group {
	${gtools}levelsof `var'
	global `var'_levels = r(levels)
}

* densities of log earnings in formal vs. informal sector
sum sector [aw=weight], meanonly
local formal_share: di %4.1f `= (2 - r(mean))*100'
local informal_share: di %4.1f `= 100 - `formal_share''
tw ///
	(kdensity earn if inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(black) lpattern(solid)) ///
	(kdensity earn if sector == 1 & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(blue) lpattern(longdash)) ///
	(kdensity earn if sector == 2 & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(red) lpattern(shortdash)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(${earn_min}(${earn_step})${earn_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(0(.1).7, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) xtitle("Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
	legend(order(1 "Overall (100.0%)" 2 "Formal (`formal_share'%)" 3 "Informal (`informal_share'%)") cols(1) size(${text_size}) region(color(none)) ring(0) pos(1)) ///
	name(dens_earn_sectors, replace)
graph export "${FORMAL_INFORMAL_DIR}/dens_earn_sectors.eps", replace

// * densities of log earnings in formal vs. informal sector by year
// foreach y in $year_min_loop $year_max_loop {
// 	sum sector [aw=weight] if year == `y', meanonly
// 	local formal_share: di %4.1f `= (2 - r(mean))*100'
// 	local informal_share: di %4.1f `= 100 - `formal_share''
// 	tw ///
// 		(kdensity earn if year == `y' & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(black) lpattern(solid)) ///
// 		(kdensity earn if sector == 1 & year == `y' & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(blue) lpattern(longdash)) ///
// 		(kdensity earn if sector == 2 & year == `y' & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(red) lpattern(shortdash)) ///
// 		, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 		xlabel(${earn_min}(${earn_step})${earn_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_dens_min}(${earn_dens_step})${earn_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 		title("", size(${text_size})) /// title("Informality share = `informal_share'%", size(${text_size}) color(black))
// 		xtitle("Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 		legend(order(1 "Overall (100.0%)" 2 "Formal (`formal_share'%)" 3 "Informal (`informal_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 		name(dens_earn_sectors_y`y', replace)
// 	graph export "${FORMAL_INFORMAL_DIR}/dens_earn_sectors_y`y'.eps", replace
// }

* densities of log earnings in formal vs. informal sector by subgroup
foreach y in $year_min_loop $year_max_loop {
	foreach g of global gender_levels {
		foreach e of global edu_group_levels {
			foreach a of global age_group_levels {
				sum sector [aw=weight] if year == `y' & gender == `g' & edu_group == `e' & age_group == `a', meanonly
				local formal_share: di %4.1f `= (2 - r(mean))*100'
				local informal_share: di %4.1f `= 100 - `formal_share''
				tw ///
					(kdensity earn if year == `y' & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(black) lpattern(solid)) ///
					(kdensity earn if sector == 1 & year == `y' & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(blue) lpattern(longdash)) ///
					(kdensity earn if sector == 2 & year == `y' & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn, ${earn_min}, ${earn_max}) [aw=weight], lcolor(red) lpattern(shortdash)) ///
					, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
					xlabel(${earn_min}(${earn_step})${earn_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_dens_min}(${earn_dens_step})${earn_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
					title("", size(${text_size})) /// title("Informality share = `informal_share'%", color(black))
					xtitle("Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
					legend(order(1 "Overall (100.0%)" 2 "Formal (`formal_share'%)" 3 "Informal (`informal_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
					name(dens_earn_sectors_y`y'_g`g'_e`e'_a`a', replace)
				graph export "${FORMAL_INFORMAL_DIR}/dens_earn_sectors_y`y'_g`g'_e`e'_a`a'.eps", replace
			}
		}
	}
}

* densities of residual log earnings in formal vs. informal sector
sum sector [aw=weight], meanonly
local formal_share: di %4.1f `= (2 - r(mean))*100'
local informal_share: di %4.1f `= 100 - `formal_share''
tw ///
	(kdensity earn_res if inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(black) lpattern(solid)) ///
	(kdensity earn_res if sector == 1 & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(blue) lpattern(longdash)) ///
	(kdensity earn_res if sector == 2 & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(red) lpattern(shortdash)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(${earn_res_min}(${earn_res_step})${earn_res_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(0(.1).7, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) /// title("Informality share = `informal_share'%", color(black))
	xtitle("Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
	legend(order(1 "Overall (100.0%)" 2 "Formal (`formal_share'%)" 3 "Informal (`informal_share'%)") cols(1) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(dens_earn_res_sectors, replace)
graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_sectors.eps", replace

// * densities of residual log earnings in formal vs. informal sector by year
// foreach y in $year_min_loop $year_max_loop {
// 	sum sector [aw=weight] if year == `y', meanonly
// 	local formal_share: di %4.1f `= (2 - r(mean))*100'
// 	local informal_share: di %4.1f `= 100 - `formal_share''
// 	tw ///
// 		(kdensity earn_res if year == `y' & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(black) lpattern(solid)) ///
// 		(kdensity earn_res if sector == 1 & year == `y' & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(blue) lpattern(longdash)) ///
// 		(kdensity earn_res if sector == 2 & year == `y' & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(red) lpattern(shortdash)) ///
// 		, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 		xlabel(${earn_res_min}(${earn_res_step})${earn_res_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_dens_min}(${earn_res_dens_step})${earn_res_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 		title("", size(${text_size})) /// title("Informality share = `informal_share'%", color(black))
// 		xtitle("Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 		legend(order(1 "Overall (100.0%)" 2 "Formal (`formal_share'%)" 3 "Informal (`informal_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 		name(dens_earn_res_sectors_y`y', replace)
// 	graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_sectors_y`y'.eps", replace
// }

* densities of residual log earnings in formal vs. informal sector by subgroup
foreach y in $year_min_loop $year_max_loop {
	foreach g of global gender_levels {
		foreach e of global edu_group_levels {
			foreach a of global age_group_levels {
				sum sector [aw=weight] if year == `y' & gender == `g' & edu_group == `e' & age_group == `a', meanonly
				local formal_share: di %4.1f `= (2 - r(mean))*100'
				local informal_share: di %4.1f `= 100 - `formal_share''
				tw ///
					(kdensity earn_res if year == `y' & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(black) lpattern(solid)) ///
					(kdensity earn_res if sector == 1 & year == `y' & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(blue) lpattern(longdash)) ///
					(kdensity earn_res if sector == 2 & year == `y' & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res, ${earn_res_min}, ${earn_res_max}) [aw=weight], lcolor(red) lpattern(shortdash)) ///
					, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
					xlabel(${earn_res_min}(${earn_res_step})${earn_res_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_dens_min}(${earn_res_dens_step})${earn_res_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
					title("", size(${text_size})) /// title("Informality share = `informal_share'%", color(black))
					xtitle("Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
					legend(order(1 "Overall (100.0%)" 2 "Formal (`formal_share'%)" 3 "Informal (`informal_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
					name(dens_earn_r_s_y`y'_g`g'_e`e'_a`a', replace)
				graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_sectors_y`y'_g`g'_e`e'_a`a'.eps", replace
			}
		}
	}
}

* reload cross-sectional data
use "${PME_OUTPUT_DIR}/formal_informal_CS.dta", clear

* time series plots of cross-sectional statistics
expand 2, gen(duplicate)
replace sector = 0 if duplicate == 1
label define sec_le 0 "Overall" 1 "Formal" 2 "Informal", replace
label val sector sec_le
${gtools}collapse ///
	(mean) earn_mean=earn earn_res_mean=earn_res ///
	(sd) earn_sd=earn earn_res_sd=earn_res ///
	(p10) earn_p10=earn earn_res_p10=earn_res ///
	(p90) earn_p90=earn earn_res_p90=earn_res ///
	[aw=weight], by(sector year) fast
replace earn_sd = 2.56*earn_sd
label var earn_sd "2.56*standard deviation of log earnings"
replace earn_res_sd = 2.56*earn_res_sd
label var earn_res_sd "2.56*standard deviation of residual log earnings"
gen float earn_p90_p10 = earn_p90 - earn_p10
label var earn_p90_p10 "P90-P10 of log earnings"
gen float earn_res_p90_p10 = earn_res_p90 - earn_res_p10
label var earn_res_p90_p10 "P90-P10 of residual log earnings"
foreach var of varlist earn_* {
	format %2.1f `var'
}
tw ///
	(connected earn_mean year if sector == 1, lcolor(blue) lpattern(solid) mcolor(blue) msymbol(D)) ///
	(connected earn_mean year if sector == 2, lcolor(red) lpattern(longdash) mcolor(red) msymbol(T)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(8.6(.4)10.6, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Mean Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal" 2 "Informal") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_mean_sectors, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_mean_sectors.eps", replace
tw ///
	(connected earn_res_mean year if sector == 1, lcolor(blue) lpattern(solid) mcolor(blue) msymbol(D)) ///
	(connected earn_res_mean year if sector == 2, lcolor(red) lpattern(longdash) mcolor(red) msymbol(T)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(-.6(.2).6, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Mean Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal" 2 "Informal") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_res_mean_sectors, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_mean_sectors.eps", replace
tw ///
	(connected earn_sd year if sector == 0, lcolor(black) lpattern(solid) mcolor(black) msymbol(O)) ///
	(connected earn_p90_p10 year if sector == 0, lcolor(black) lpattern(longdash) mcolor(black) msymbol(Oh)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(1.6(.2)2.8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Dispersion of Log Earnings", size(${text_size})) ///
	legend(order(1 "Overall 2.56*{&sigma}" 2 "Overall P90-P10") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_disp, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_disp.eps", replace
tw ///
	(connected earn_res_sd year if sector == 0, lcolor(black) lpattern(solid) mcolor(black) msymbol(O)) ///
	(connected earn_res_p90_p10 year if sector == 0, lcolor(black) lpattern(longdash) mcolor(black) msymbol(Oh)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(1.6(.2)2.8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Dispersion of Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Overall 2.56*{&sigma}" 2 "Overall P90-P10") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_res_disp, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_disp.eps", replace
tw ///
	(connected earn_sd year if sector == 1, lcolor(blue) lpattern(solid) mcolor(blue) msymbol(D)) ///
	(connected earn_p90_p10 year if sector == 1, lcolor(blue) lpattern(longdash) mcolor(blue) msymbol(Dh)) ///
	(connected earn_sd year if sector == 2, lcolor(red) lpattern(solid) mcolor(red) msymbol(T)) ///
	(connected earn_p90_p10 year if sector == 2, lcolor(red) lpattern(longdash) mcolor(red) msymbol(Th)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(1.6(.2)2.8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Dispersion of Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal 2.56*{&sigma}" 2 "Formal P90-P10" 3 "Informal 2.56*{&sigma}" 4 "Informal P90-P10") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_disp_sectors, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_disp_sectors.eps", replace
tw ///
	(connected earn_res_sd year if sector == 1, lcolor(blue) lpattern(solid) mcolor(blue) msymbol(D)) ///
	(connected earn_res_p90_p10 year if sector == 1, lcolor(blue) lpattern(_) mcolor(blue) msymbol(Dh)) ///
	(connected earn_res_sd year if sector == 2, lcolor(red) lpattern(solid) mcolor(red) msymbol(T)) ///
	(connected earn_res_p90_p10 year if sector == 2, lcolor(red) lpattern(_) mcolor(red) msymbol(Th)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(1.6(.2)2.8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Dispersion of Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal 2.56*{&sigma}" 2 "Formal P90-P10" 3 "Informal 2.56*{&sigma}" 4 "Informal P90-P10") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_res_disp_sectors, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_disp_sectors.eps", replace


*** longitudinal plots
* parameters for longitudinal plots
global earn_res_change_min = -3
global earn_res_change_step = 1
global earn_res_change_max = 3
global earn_res_change_dens_min = 0
global earn_res_change_dens_step = .4
global earn_res_change_dens_max = 2.0

* load longitudinal data
use "${PME_OUTPUT_DIR}/formal_informal_L.dta", clear

* keep only first observation of each individual panel
bys id: keep if _n == 1

* get levels of key variables
foreach var of varlist gender edu_group age_group {
	${gtools}levelsof `var'
	global `var'_levels = r(levels)
}

* create transition indicators
qui tab transition, gen(transition_)

* compute first and last year of plots
sum year, meanonly
global year_min_loop = r(min)
global year_max_loop = r(max)

// * densities of changes in residual log earnings for stayers within and switchers across formal vs. informal sectors
// forval t = 1/4 {
// 	sum transition_`t' [aw=weight_sum], meanonly
// 	local transition_`t'_share: di %4.1f `=r(mean)*100'
// }
// tw ///
// 	(kdensity earn_res_change if inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(black) lpattern(solid)) ///
// 	(kdensity earn_res_change if transition == 1 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(blue) lpattern(longdash)) ///
// 	(kdensity earn_res_change if transition == 2 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(red) lpattern(shortdash)) ///
// 	(kdensity earn_res_change if transition == 5 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(green) lpattern(longdash_dot)) ///
// 	(kdensity earn_res_change if transition == 6 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(orange) lpattern(shortdash_dot)) ///
// 	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 	xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 	title("", size(${text_size})) /// title("Formal-Formal share = `transition_1_share'%, Informal-Informal share = `transition_2_share'%," "Formal-Informal share = `transition_3_share'%, Informal-Formal share = `transition_4_share'%", color(black))
// 	xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 	legend(order(1 "Overall (100.0%)" 2 "Formal-Formal (`transition_1_share'%)" 3 "Informal-Informal (`transition_2_share'%)" 4 "Formal-Informal (`transition_3_share'%)" 5 "Informal-Formal (`transition_4_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 	name(dens_earn_res_change_transitions, replace)
// graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_transitions.eps", replace

* densities of changes in residual log earnings for stayers within and switchers across formal vs. informal sectors
forval t = 1/4 {
	sum transition_`t' [aw=weight_sum], meanonly
	local share = r(mean)*100
	if `share' == 100 local transition_`t'_share: di %4.1f `share'
	else if `share' >= 10 & `share' < 100 local transition_`t'_share: di %2.1f `share'
	else if `share' < 10 local transition_`t'_share: di %2.1f `share'
}
tw ///
	(kdensity earn_res_change if inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(black) lpattern(solid)) ///
	(kdensity earn_res_change if transition == 1 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(blue) lpattern(longdash)) ///
	(kdensity earn_res_change if transition == 2 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(red) lpattern(shortdash)) ///
	(kdensity earn_res_change if transition == 5 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(green) lpattern(longdash_dot)) ///
	(kdensity earn_res_change if transition == 6 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(orange) lpattern(shortdash_dot)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) /// title("Formal-Formal share = `transition_1_share'%, Informal-Informal share = `transition_2_share'%," "Formal-Informal share = `transition_3_share'%, Informal-Formal share = `transition_4_share'%", color(black))
	xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
	legend(order(1 "Overall (100.0%)" 2 "Formal-Formal (`transition_1_share'%)" 3 "Informal-Informal (`transition_2_share'%)" 4 "Formal-Informal (`transition_3_share'%)" 5 "Informal-Formal (`transition_4_share'%)") symxsize(*${symxsize}) cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
	name(dens_earn_res_change_transitions, replace)
graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_transitions.eps", replace

* densities of changes in residual log earnings for stayers within and switchers across formal vs. informal sectors by subgroups
foreach y in $year_min_loop $year_max_loop {
	foreach g of global gender_levels {
		foreach e of global edu_group_levels {
			foreach a of global age_group_levels {
				forval t = 1/4 {
					sum transition_`t' [aw=weight_sum] if year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a', meanonly
					local transition_`t'_share: di %4.1f `=r(mean)*100'
				}
				tw ///
					(kdensity earn_res_change if year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(black) lpattern(solid)) ///
					(kdensity earn_res_change if transition == 1 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(blue) lpattern(longdash)) ///
					(kdensity earn_res_change if transition == 2 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(red) lpattern(shortdash)) ///
					(kdensity earn_res_change if transition == 5 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(green) lpattern(longdash_dot)) ///
					(kdensity earn_res_change if transition == 6 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(orange) lpattern(shortdash_dot)) ///
					, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
					xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
					title("", size(${text_size})) /// title("Formal-Formal share = `transition_1_share'%, Informal-Informal share = `transition_2_share'%," "Formal-Informal share = `transition_3_share'%, Informal-Formal share = `transition_4_share'%", color(black))
					xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
					legend(order(1 "Overall" 2 "Formal-Formal (`transition_1_share'%)" 3 "Informal-Informal (`transition_2_share'%)" 4 "Formal-Informal (`transition_3_share'%)" 5 "Informal-Formal (`transition_4_share'%)") symxsize(*${symxsize}) cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
					name(dens_e_r_ch_t_y`y'_g`g'_e`e'_a`a', replace)
				graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_transitions_y`y'_g`g'_e`e'_a`a'.eps", replace
			}
		}
	}
}

// * densities of changes in residual log earnings for stayers within formal vs. informal sectors
// forval t = 1/4 {
// 	sum transition_`t' [aw=weight_sum], meanonly
// 	local transition_`t'_share: di %4.1f `=r(mean)*100'
// }
// tw ///
// 	(kdensity earn_res_change if transition == 1 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(blue) lpattern(longdash)) ///
// 	(kdensity earn_res_change if transition == 2 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(red) lpattern(shortdash)) ///
// 	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 	xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 	title("", size(${text_size})) /// title("Formal-Formal share = `transition_1_share'%, Informal-Informal share = `transition_2_share'%", color(black))
// 	xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 	legend(order(1 "Formal-Formal (`transition_1_share'%)" 2 "Informal-Informal (`transition_2_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 	name(dens_earn_res_change_stayers, replace)
// graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_stayers.eps", replace

// * densities of changes in residual log earnings for stayers within formal vs. informal sectors by subgroups
// foreach y in $year_min_loop $year_max_loop {
// 	foreach g of global gender_levels {
// 		foreach e of global edu_group_levels {
// 			foreach a of global age_group_levels {
// 				forval t = 1/4 {
// 					sum transition_`t' [aw=weight_sum] if year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a', meanonly
// 					local transition_`t'_share: di %4.1f `=r(mean)*100'
// 				}
// 				tw ///
// 					(kdensity earn_res_change if transition == 1 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(blue) lpattern(longdash)) ///
// 					(kdensity earn_res_change if transition == 2 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(red) lpattern(shortdash)) ///
// 					, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 					xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 					title("", size(${text_size})) /// title("Formal-Formal share = `transition_1_share'%, Informal-Informal share = `transition_2_share'%", color(black))
// 					xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 					legend(order(1 "Formal-Formal (`transition_1_share'%)" 2 "Informal-Informal (`transition_2_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 					name(dens_e_r_ch_st_y`y'_g`g'_e`e'_a`a', replace)
// 				graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_stayers_y`y'_g`g'_e`e'_a`a'.eps", replace
// 			}
// 		}
// 	}
// }

// * densities of changes in residual log earnings for switchers across formal vs. informal sectors
// forval t = 1/4 {
// 	sum transition_`t' [aw=weight_sum], meanonly
// 	local transition_`t'_share: di %4.1f `=r(mean)*100'
// }
// tw ///
// 	(kdensity earn_res_change if transition == 5 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(green) lpattern(longdash_dot)) ///
// 	(kdensity earn_res_change if transition == 6 & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(orange) lpattern(shortdash_dot)) ///
// 	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 	xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 	title("", size(${text_size})) /// title("Formal-Informal share = `transition_3_share'%, Informal-Formal share = `transition_4_share'%", color(black))
// 	xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 	legend(order(1 "Formal-Informal (`transition_3_share'%)" 2 "Informal-Formal (`transition_4_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 	name(dens_earn_res_change_switchers, replace)
// graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_switchers.eps", replace

// * densities of changes in residual log earnings for switchers across formal vs. informal sectors by subgroups
// foreach y in $year_min_loop $year_max_loop {
// 	foreach g of global gender_levels {
// 		foreach e of global edu_group_levels {
// 			foreach a of global age_group_levels {
// 				forval t = 1/4 {
// 					sum transition_`t' [aw=weight_sum] if year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a', meanonly
// 					local transition_`t'_share: di %4.1f `=r(mean)*100'
// 				}
// 				tw ///
// 					(kdensity earn_res_change if transition == 5 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(orange) lpattern(longdash_dot)) ///
// 					(kdensity earn_res_change if transition == 6 & year == min(`y', ${year_max_loop} - 1) & gender == `g' & edu_group == `e' & age_group == `a' & inrange(earn_res_change, ${earn_res_change_min}, ${earn_res_change_max}) [aw=weight_sum], lcolor(purple) lpattern(shortdash_dot)) ///
// 					, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
// 					xlabel(${earn_res_change_min}(${earn_res_change_step})${earn_res_change_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(${earn_res_change_dens_min}(${earn_res_change_dens_step})${earn_res_change_dens_max}, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
// 					title("", size(${text_size})) /// title("Formal-Informal share = `transition_3_share'%, Informal-Formal share = `transition_4_share'%", color(black))
// 					xtitle("1-Year Change in Residual Log Earnings", size(${text_size})) ytitle("Density", size(${text_size})) ///
// 					legend(order(1 "Formal-Informal (`transition_3_share'%)" 2 "Informal-Formal (`transition_4_share'%)") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
// 					name(dens_e_r_ch_sw_y`y'_g`g'_e`e'_a`a', replace)
// 				graph export "${FORMAL_INFORMAL_DIR}/dens_earn_res_change_switchers_y`y'_g`g'_e`e'_a`a'.eps", replace
// 			}
// 		}
// 	}
// }

* reload longitudinal data
use "${PME_OUTPUT_DIR}/formal_informal_L.dta", clear

* keep only first observation of each individual panel
bys id: keep if _n == 1

* time series plots of longitudinal statistics
expand 2, gen(duplicate)
replace transition = 0 if duplicate == 1
label define tra_le 0 "Overall" 1 "F-F" 2 "I-I" 5 "F-I" 6 "I-F", replace
label val transition tra_le
${gtools}collapse ///
	(mean) earn_res_change_mean=earn_res_change ///
	(sd) earn_res_change_sd=earn_res_change ///
	(p10) earn_res_change_p10=earn_res_change ///
	(p90) earn_res_change_p90=earn_res_change ///
	[aw=weight], by(transition year) fast
replace earn_res_change_sd = 2.56*earn_res_change_sd
label var earn_res_change_sd "2.56*standard deviation of change in residual log earnings"
gen float earn_res_change_p90_p10 = earn_res_change_p90 - earn_res_change_p10
label var earn_res_change_p90_p10 "P90-P10 of log earnings"
foreach var of varlist earn_* {
	format %2.1f `var'
}
tw ///
	(connected earn_res_change_sd year if transition == 0, lcolor(black) lpattern(solid) mcolor(black) msymbol(O)) ///
	(connected earn_res_change_p90_p10 year if transition == 0, lcolor(black) lpattern(_) mcolor(black) msymbol(Oh)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(.8(.2)1.8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Dispersion of Changes in Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Overall 2.56*{&sigma}" 2 "Overall P90-P10") cols(2) size(${text_size}) ring(0) pos(1) region(color(none))) ///
	name(evolution_earn_res_change_disp, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_change_disp.eps", replace
tw ///
	(connected earn_res_change_mean year if transition == 1, lcolor(blue) lpattern(longdash) mcolor(blue) msymbol(Dh)) ///
	(connected earn_res_change_mean year if transition == 2, lcolor(red) lpattern(shortdash) mcolor(red) msymbol(Th)) ///
	(connected earn_res_change_mean year if transition == 5, lcolor(green) lpattern(longdash_dot) mcolor(green) msymbol(Sh)) ///
	(connected earn_res_change_mean year if transition == 6, lcolor(orange) lpattern(shortdash_dot) mcolor(orange) msymbol(+)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(-.6(.2).8, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Mean Changes in Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal-Formal" 2 "Informal-Informal" 3 "Formal-Informal" 4 "Informal-Formal") cols(2) size(${text_size}) ring(0) pos(12) region(color(none))) ///
	name(evolution_earn_res_change_mean_t, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_change_mean_transitions.eps", replace
tw ///
	(connected earn_res_change_sd year if transition == 1, lcolor(blue) lpattern(longdash) mcolor(blue) msymbol(Dh)) ///
	(connected earn_res_change_sd year if transition == 2, lcolor(red) lpattern(shortdash) mcolor(red) msymbol(Th)) ///
	(connected earn_res_change_sd year if transition == 5, lcolor(green) lpattern(longdash_dot) mcolor(green) msymbol(Sh)) ///
	(connected earn_res_change_sd year if transition == 6, lcolor(orange) lpattern(shortdash_dot) mcolor(orange) msymbol(+)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(.5(.5)3, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("2.56*{&sigma} of Changes in Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal-Formal" 2 "Informal-Informal" 3 "Formal-Informal" 4 "Informal-Formal") cols(2) size(${text_size}) ring(0) pos(12) region(color(none))) ///
	name(evolution_earn_res_change_sd_t, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_change_sd_transitions.eps", replace
tw ///
	(connected earn_res_change_p90_p10 year if transition == 1, lcolor(blue) lpattern(solid) mcolor(blue) msymbol(Dh)) ///
	(connected earn_res_change_p90_p10 year if transition == 2, lcolor(red) lpattern(longdash) mcolor(red) msymbol(Th)) ///
	(connected earn_res_change_p90_p10 year if transition == 5, lcolor(green) lpattern(shortdash) mcolor(green) msymbol(Sh)) ///
	(connected earn_res_change_p90_p10 year if transition == 6, lcolor(orange) lpattern(dash_dot) mcolor(orange) msymbol(+)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(.5(.5)3, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("P90-P10 of Changes in Residual Log Earnings", size(${text_size})) ///
	legend(order(1 "Formal-Formal" 2 "Informal-Informal" 3 "Formal-Informal" 4 "Informal-Formal") cols(2) size(${text_size}) ring(0) pos(12) region(color(none))) ///
	name(evolution_earn_res_ch_p90_p10_t, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_earn_res_change_p90_p10_transitions.eps", replace


*** evolution of sectoral transition rates
* load data
use "${PME_OUTPUT_DIR}/formal_informal_L.dta", clear

* keep only first observation of each individual panel
bys id: keep if _n == 1

* generate indicators for sectoral transitions
tab transition, gen(transition_)

* compute transition rates
${gtools}collapse ///
	(mean) transition_* ///
	[aw=weight_sum], by(year) fast
label var transition_1 "Share F-F"
label var transition_2 "Share I-I"
label var transition_3 "Share F-I"
label var transition_4 "Share I-F"

* plot evolution of sectoral transition rates
tw ///
	(connected transition_1 transition_2 transition_3 transition_4 year, lcolor(blue red green orange) lpattern(longdash shortdash longdash_dot shortdash_dot) mcolor(blue red green orange) msymbol(Dh Th Sh +)) ///
	, graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	xlabel(2002(2)2016, gmin gmax grid gstyle(dot) labsize(${text_size})) ylabel(0(.2)1, gmin gmax grid gstyle(dot) labsize(${text_size})) ///
	title("", size(${text_size})) ///
	xtitle("", size(${text_size})) ytitle("Share of all transitions", size(${text_size})) ///
	legend(order(1 "Formal-Formal" 2 "Informal-Informal" 3 "Formal-Informal" 4 "Informal-Formal") cols(1) size(${text_size}) ring(0) pos(11) region(color(none))) ///
	name(evolution_transitions, replace)
graph export "${FORMAL_INFORMAL_DIR}/evolution_transitions.eps", replace


*** higher-order moments of the distribution of changes in residual log earnings
* load longitudinal data
use "${PME_OUTPUT_DIR}/formal_informal_L.dta", clear

* keep only first observation of each individual panel
bys id: keep if _n == 1

* generate "overall" (i.e., all transitions) category
expand 2, gen(duplicate)
replace transition = 0 if duplicate == 1
label define tra_le 0 "Overall" 1 "F-F" 2 "I-I" 5 "F-I" 6 "I-F", replace
label val transition tra_le

* generate indicator
gen byte one = 1

* collapse to overall / type of transition
if "${gtools}" == "g" {
	${gtools}collapse ///
		(mean) mean=earn_res_change ///
		(sd) sd=earn_res_change ///
		(skew) skew=earn_res_change ///
		(kurt) kurt=earn_res_change ///
		(p2.5) p2_5=earn_res_change ///
		(p10) p10=earn_res_change ///
		(p25) p25=earn_res_change ///
		(p50) p50=earn_res_change ///
		(p75) p75=earn_res_change ///
		(p90) p90=earn_res_change ///
		(p97.5) p97_5=earn_res_change ///
		(rawsum) N_w=weight N_unw=one ///
		[aw=weight], by(transition) fast
}
else {
	disp as error "USER ERROR: Need to install -gtools- package for computing higher-order moments with -gcollapse- command."
	error 1
}
gen float k_skew = ((p90 - p50) - (p50 - p10))/(p90 - p10)
label var k_skew "Kelley skewness"
replace kurt = kurt - 3
label var kurt "Excess kurtosis"
gen float cs_kurt = (p97_5 - p2_5)/(p75 - p25) - 2.91
label var cs_kurt "Excess Crow-Siddiqui Kurtosis"
foreach var of varlist * {
	format %4.3f `var'
}
format %12.0fc N_w N_unw
order transition mean sd skew k_skew kurt cs_kurt p2_5 p10 p25 p50 p75 p90 p97_5 N_w N_unw


*** shift-share analysis of sectoral differences in volatility
* define list of variables to be used in Oaxaca-Blinder decomposition
global vars_ob = "gender edu_group age_group ind_group occ_group"

* create list of dummies based on this variables list
global vars_ob_dummies = ""
foreach var in $vars_ob {
	global vars_ob_dummies = "${vars_ob_dummies} i.`var'"
}

* load data
use ///
	sector year season region ${vars_ob} earn_res_change weight_sum ///
	using "${PME_OUTPUT_DIR}/formal_informal.dta", clear

* keep only observations with nonmissing key variables
count
foreach var of varlist * {
	disp "Variable = `var'"
	keep if `var' < .
}
count

* detect small cells
${gtools}egen int cell = group(sector ${vars_ob})
bys cell: gen int N = _N
forval s = 1/2 {
	sum N if sector == 1, meanonly
	local N_min_s`s' = r(min)
}
drop cell N
assert min(`N_min_s1', `N_min_s2') > ${cell_min}

* take out means in changes by year. An alternative would be to do this in
* levels at earlier stage as we discussed. I think it should be the same as 
* taking out the means of the changes, subject to the possibility that the 
* sample size may change (i.e. some people may have non-missing levels but 
* missing changes). To be safe, I would prefer to take out the mean of the 
* changes
qui reghdfe earn_res_change [aw=weight_sum], a(i.sector##i.year##i.season##i.region i.sector##(${vars_ob_dummies})) resid
qui predict rearn_res_change, r

* weights are the sum of the survey weights
${gtools}collapse ///
	(sd) rearn_res_change ///
	(rawsum) weight_sum ///
	(count) n=rearn_res_change ///
	[aw=weight_sum], by(year sector ${vars_ob}) fast
replace rearn_res_change = rearn_res_change^2

* the year differences are less interesting, so take these out
qui areg rearn_res_change i.sector##(${vars_ob_dummies}) [aw=weight_sum], a(year)
drop rearn_res_change
qui predict xbrearn_res_change, xb
${gtools}collapse ///
	(firstnm) rearn_res_change=xbrearn_res_change ///
	(sum) weight_sum n ///
	, by(sector ${vars_ob}) fast

* normalize the weights within each sector
bys sector: gegen tot = total(weight_sum)
replace weight_sum = weight_sum/tot
drop tot
label var rearn_res_change "Within group variance of residual earnings change"
label var weight_sum "Weight of group (sum of survey weights)"
label var n "Number of observations in group"

* convert to wide format to run Oaxaca-Blinder decomposition
${gtools}reshape wide rearn_res_change weight_sum n, i(${vars_ob}) j(sector)

* minimum, maximum and total observations by sector
forvalues sector = 1/2 {
	sum n`sector', meanonly
	qui gen long obsmin`sector' = `r(min)'
	qui gen long obsmax`sector' = `r(max)'
	qui ${gtools}egen tot = total(n`sector')
	qui sum tot
	qui gen obstot`sector' = `r(mean)'
	drop tot
}
drop n*

* compute baseline Oaxaca-Blinder decomposition shifting all covariates at a time
qui sum rearn_res_change1 [aw=weight_sum1]
local outcome1 = "Variance in formal sector: `r(mean)'"
qui gen formal = `r(mean)'
qui sum rearn_res_change2 [aw=weight_sum2]
local outcome2 = "Variance in informal sector: `r(mean)'"
qui gen informal = `r(mean)'
qui sum rearn_res_change2 [aw=weight_sum1]
local outcome3 = "Counterfactual variance in informal sector if only changing within-group differences to match that in informal sector: `r(mean)'"
qui gen returns = `r(mean)'
qui sum rearn_res_change1 [aw=weight_sum2]
local outcome4 = "Counterfactual variance in informal sector if only changing composition to match that in informal sector: `r(mean)'"
qui gen composition_all = `r(mean)'

* isolate the effect of each individual covariate
local i = 4
local outsheetlist = ""
foreach demo of varlist $vars_ob {
	local ++i
	forvalues sector = 1/2 {
		qui bys `demo': gegen cond_weight_sum`sector' = sum(weight_sum`sector')
	}
	qui gen weight_sum = weight_sum1 // keep weights fixed as in the formal sector...
	qui replace weight_sum = weight_sum / cond_weight_sum1 * cond_weight_sum2 // ...with the exception of the age weights
	qui sum rearn_res_change1 [aw=weight_sum]
	local outcome`i' = "Counterfactual variance in informal sector if only changing `demo' composition to match that in informal sector: `r(mean)'"
	qui gen composition_`demo' = `r(mean)'
	drop weight_sum cond_weight_sum*
	local outsheetlist = "`outsheetlist' composition_`demo'"
}

* display results from Oaxaca-Blinder decomposition
disp _newline(3)
disp "RESULTS FROM BASELINE OAXACA-BLINDER DECOMPOSITION:"
disp "`outcome1'"
disp "`outcome2'"
disp "`outcome3'"
disp "`outcome4'"

* display results from extended Oaxaca-Blinder decomposition
disp _newline(3)
disp "RESULTS FROM EXTENDED OAXACA-BLINDER DECOMPOSITION:"
disp "`outcome1'"
disp "`outcome2'"
disp "`outcome5'"
disp "`outcome6'"
disp "`outcome7'"
disp "`outcome8'"

* outsheet this to matlab to write table
${gtools}collapse ///
	(mean) formal informal obsmin1 obsmin2 obsmax1 obsmax2 obstot1 obstot2 returns composition_all `outsheetlist'
cap n {
	!mkdir "${PME_OUTPUT_DIR}/out/"
	!mkdir "${PME_OUTPUT_DIR}/tex/"
}
outsheet formal informal obsmin1 obsmin2 obsmax1 obsmax2 obstot1 obstot2 returns composition_all `outsheetlist' using "${PME_OUTPUT_DIR}/out/TableXX.out", comma replace nolabel

* print tables in MATLAB
if inlist("`c(os)'", "MacOSX", "Unix") {
	!${FILE_MATLAB} -nosplash -noFigureWindows -nodesktop -nodisplay <"${DO_DIR}/Table_OB.m" // XXX OLD SETTINGS: -nodesktop -nodisplay
}
else if "`c(os)'" == "Windows" {
	!matlab -nosplash -noFigureWindows -batch -wait "run '${DO_DIR}/Table_OB.m'" // OLD: !matlab -nosplash -noFigureWindows -r "run '${DIR_CODE}/FUN_CONNECTED.m'; exit"
}




********************************************************************************
* SHIFT SHARE ANALYSIS (BY ROBERTA)
********************************************************************************

*** load data
use "${PME_OUTPUT_DIR}/formal_informal_L.dta", clear


drop if year == 2015
qui recode transition (5=3) (6=4)
tab transition, gen(transition_)

** Generate variables to be filled below
foreach sec in "ff" "ii" "fi" "if" {
	gen share_`sec' = .
	forval j = 1/4 {
		gen share_`sec'edu`j' = .
	}
}
foreach v in "mean" "var" {
	gen `v'_tot = .
	forval j = 1/4 {
		gen `v'_totedu`j' = .
	}
	foreach sec in "ff" "ii" "fi" "if" {
		gen `v'_`sec' = .
		forval j = 1/4 {
			gen `v'_`sec'edu`j' = .	
		}
	}
}

** Fill variables:
// Shares, total
forval yr = 2002/2014 {
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
forval yr = 2002/2014 {
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
tab edu, gen(edu_)

forval yr = 2002/2014 {
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
drop share_fie* share_ife* var_fie* var_ife* mean_fie* mean_ife* 

save "${PME_DIR}/code/out/stats/shift_share2.dta", replace 


***** 			BETWEEN/WITHIN DECOMPOSITION OF TOTAL VARIANCE 	   		   *****
use "${PME_DIR}/code/out/stats/shift_share2.dta", clear
foreach var in ff ii if fi {
	gen between`var' = share_`var' * ( mean_`var' - mean_tot )^2
	gen within`var' = share_`var' * var_`var'
}
* sum these up
egen between = rowtotal( between* )
egen within = rowtotal( within* )

tw (connected var_tot between within year,  				 /// Plot
		lcolor(blue red green)  ///			Line color
		lpattern(solid longdash dash )  ///			Line pattern
		msymbol(o s +)		/// Marker
		msize("large" "medium" "medium")		/// Marker size
		mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
		mlcolor(blue red green)  ///			Marker  line color
		yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(${text_size}))), /// yaxis optins
		xtitle("", size(${text_size})) ytitle("Variance of residual earnings changes", size(${text_size})) xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
		legend(col(1) size(${text_size}) ring(0) position(11) ///
		order(1 "Total" 2 "Between component" 3 "Within component") ///
		region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
		graphregion(color(white)) ///				Graph region define
		plotregion(lcolor(black)) 
		graph export "${PME_DIR}/code/figs/fig_decomposition.pdf", replace
		
		
***** 		SHIFT-SHARE ANALYSIS ACROSS SECTORS OF WITHIN COMPONENT 	   *****
* focus on the within component since it is the great majority of the total

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
	msize("large" "medium" "medium")		/// Marker size
	mfcolor(green*0.25 black*0.25 black*0.25)  ///	Fill color
	mlcolor(green black black)  ///			Marker  line color
	yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(${text_size}))), /// yaxis optins
	xtitle("", size(${text_size})) ytitle("Variance of residual earnings changes", size(${text_size})) xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
	legend(col(1) size(${text_size}) ring(0) position(11) ///
	order(1 "Within component" 2 "Within component due to returns channel" 3 "Within component due to composition channel") ///
	region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
	graphregion(color(white)) ///				Graph region define
	plotregion(lcolor(black)) 
	graph export "${PME_DIR}/code/figs/fig_shiftshare.pdf", replace

		
***** 	BETWEEN/WITHIN DECOMPOSITION OF WITHIN FF/II VARIANCE ACROSS EDUC  *****
foreach var in ff ii {
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
			msize("medium" "medium" "large")		/// Marker size
			mfcolor(blue*0.25 red*0.25 green*0.25)  ///	Fill color
			mlcolor(blue red green)  ///			Marker  line color
			yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(${text_size}))), /// yaxis optins
			xtitle("", size(${text_size})) ytitle("Variance of residual earnings changes", size(${text_size})) xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
			legend(col(1) size(${text_size}) ring(0) position(1) ///
			order(1 "Total" 2 "Between component" 3 "Within component") ///
			region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
			graphregion(color(white)) ///				Graph region define
			plotregion(lcolor(black)) ///
			name(decompose`var', replace)
			graph export "${PME_DIR}/code/figs/fig_decomposition_sector`var'.pdf", replace
			
}
	
***** 		SHIFT-SHARE ANALYSIS ACROSS SECTORS OF WITHIN COMPONENT ACROSS EDUC	   *****
* focus on the within component since it is the great majority of the total

* initial shares and variances
sort year
foreach var in "ff" "ii" {
	
	if "`var'" == "ff" {
		local position position(11)
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
		msize("large" "medium" "medium")		/// Marker size
		mfcolor(green*0.25 black*0.25 black*0.25)  ///	Fill color
		mlcolor(green black black)  ///			Marker  line color
			yaxis(1) ylabel(0(.2).8, grid gmin gmax labsize(${text_size}))), /// yaxis optins
			xtitle("", size(${text_size})) ytitle("Variance of residual earnings changes", size(${text_size})) xlabel(2002(2)2016, grid gmin gmax labsize(${text_size})) ///		xaxis options
			legend(col(1) size(${text_size}) ring(0) `position' ///
			order(1 "Within component" 2 "Within component due to returns channel" 3 "Within component due to composition channel") ///
			region(lcolor(none) fcolor(none))) graphregion(color(white)) /// Legend options 
			graphregion(color(white)) ///				Graph region define
			plotregion(lcolor(black)) ///
			name(shiftshare`var', replace)
			graph export "${PME_DIR}/code/figs/fig_shiftshare_sector`var'.pdf", replace
}
