********************************************************************************
* DESCRIPTION: Generate base sample.
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
// This program generates the base sample 
// This version Dec 01, 2020
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off

// PLEASE MAKE THE APPROPRIATE CHANGES BELOW. 
// You should change the below directory. 
// global maindir =".."

do "${maindir}/do/0_Initialize.do"

// Create folder for output and log-file
// global logname = c(current_date)
// if substr("${logname}", 1, 1) == " " global logname = "0" + substr("${logname}", 2, .)
global logname = "09 Feb 2022"
global logname="$logname BaseSample"
cap log close
cap n log using "${maindir}${sep}log${sep}$logname.log", replace

cd "${maindir}${sep}dta${sep}"
*	
if $wide==1 {
	use $personid_var $male_var $yob_var $yod_var $educ_var ${labor_var}* using "${datafile}"
	order ${labor_var}*, alphabetic
	keep $personid_var $male_var $yob_var $yod_var $educ_var ${labor_var}${yrfirst}-${labor_var}${yrlast}
	order $personid_var $male_var $yob_var $yod_var $educ_var ${labor_var}*
	describe
}
else{
	* load RAIS data and save yearly files
	if $sample global sample_prefix = "sample_"
	else global sample_prefix = ""
	forval y = $yrfirst/$yrlast {
		if $pme_munis local muni_var = "${muni_var}"
		else local muni_var = ""
		
		* load data
		use $personid_var $male_var $yob_var $educ_var $year_var $labor_var `muni_var' hire_month sep_month ///
			using "${DATA_DIR}/`y'/${sample_prefix}clean`y'", clear
		
		* keep only nonmissing observations
		if $key_vars_nonmissing keep if !inlist(., ${personid_var}, ${male_var}, ${yob_var}, ${educ_var}, ${year_var}, ${labor_var}, hire_month, sep_month)
		
		* format data: recast income variable from double precision (8 bytes) to float precision (4 bytes)
		recast float $labor_var, force
		
		* format data: recode gender to male dummy
		recode ${male_var} (1=1) (2=0), generate(${male_var}_new) // 0 = female, 1 = male
		drop ${male_var}
		rename ${male_var}_new ${male_var}
		label var ${male_var} "Ind: Male (0 = female, 1 = male)?"
		
		* format data: recode education to 4 categories (so as to match some later code for figures that Sergio&Serdar produced)
		label val $educ_var .
		label drop edu_l
		recode ${educ_var} (1 2 3 4=1) (5 6=2) (7 8=3) (9=4) // 1 = primary school degree or some middle school, 2 = middle school degree or some high school, 3 = high school degree or some college, 4 = at least college degree
		label var ${educ_var} "Education category (1 = primary, 2 = middle, 3 = high school, 4 = college)"
		
		* format data: generate year of death (all missing)
		gen int ${yod_var} = .
		label var ${yod_var} "Year of death"
		
		* format data: keep only observations within 6 municipalities covered by PME survey (if switch ${pme_munis} is = 1)
		if $pme_munis {
			count
			local N_pre_pme_muni_sel = r(N)
			/*
			keep if inlist(${muni_var}, 310500, 310620, 310670, 310900, 311000, 311250, 311787, 311860, 312410, 312600, 312980, 313010, 313220, 313460, 313665, 313760, 314015, 314070, 314110, 314480, 313660, 314930, 315390, 315460, 315480, 315530, 315670, 315780, 316292, 316295, 316553, 316830, 317120) /// municipality codes belonging to the metropolitan region of Belo Horizonte in 2001
				| inlist(${muni_var}, 310500, 310620, 310670, 310900, 311000, 311250, 311787, 311860, 312410, 312600, 312980, 313010, 313220, 313370, 313460, 313665, 313760, 314015, 314070, 314110, 314480, 313660, 314930, 315390, 315460, 315480, 315530, 315670, 315780, 316292, 316295, 316553, 316830, 317120) /// municipality codes belonging to the metropolitan region of Belo Horizonte in 2015
				| inlist(${muni_var}, 430060, 430087, 430110, 430310, 430390, 430460, 430468, 430535, 430640, 430676, 430760, 430770, 430905, 430920, 430930, 431080, 431240, 431306, 431337, 431340, 431405, 431480, 431490, 431760, 431840, 431870, 431990, 432000, 432120, 432200, 432300) /// municipality codes belonging to the metropolitan region of Porto Alegre in 2001
				| inlist(${muni_var}, 430060, 430087, 430110, 430310, 430390, 430460, 430468, 430535, 430640, 430676, 430760, 430770, 430905, 430920, 430930, 431010, 431080, 431240, 431306, 431337, 431340, 431405, 431480, 431490, 431600, 431760, 431840, 431870, 431950, 431990, 432000, 432120, 432200, 432300) /// municipality codes belonging to the metropolitan region of Porto Alegre in 2015
				| inlist(${muni_var}, 260005, 260105, 260290, 260345, 260680, 260720, 260760, 260775, 260790, 260940, 260960, 261070, 261160, 261370) /// municipality codes belonging to the metropolitan region of Recife in 2001
				| inlist(${muni_var}, 260005, 260105, 260290, 260345, 260680, 260760, 260720, 260775, 260790, 260940, 260960, 261070, 261160, 261370) /// municipality codes belonging to the metropolitan region of Recife in 2015
				| inlist(${muni_var}, 330045, 330170, 330185, 330190, 330200, 330227, 330250, 330260, 330270, 330285, 330320, 330330, 330350, 330360, 330414, 330455, 330490, 330510, 330555, 330575) /// municipality codes belonging to the metropolitan region of Rio de Janeiro in 2001
				| inlist(${muni_var}, 330045, 330080, 330170, 330185, 330190, 330200, 330227, 330250, 330270, 330285, 330320, 330330, 330350, 330360, 330414, 330430, 330455, 330490, 330510, 330555, 330575) /// municipality codes belonging to the metropolitan region of Rio de Janeiro in 2015
				| inlist(${muni_var}, 290570, 290650, 291005, 291610, 291920, 291992, 292740, 292920, 293070, 293320) /// municipality codes belonging to the metropolitan region of Salvador in 2001
				| inlist(${muni_var}, 290570, 290650, 291005, 291610, 291920, 291992, 292100, 292520, 292740, 292920, 292950, 293070, 293320) /// municipality codes belonging to the metropolitan region of Salvador in 2015
				| inlist(${muni_var}, 350390, 350570, 350660, 350900, 350920, 351060, 351300, 351380, 351500, 351510, 351570, 351630, 351640, 351830, 351880, 352220, 352250, 352310, 352500, 352620, 352850, 352940, 353060, 353440, 353910, 353980, 354330, 354410, 354500, 354680, 354730, 354780, 354870, 354880, 354995, 355030, 355250, 355280, 355645) /// municipality codes belonging to the metropolitan region of Sao Paulo in 2001
				| inlist(${muni_var}, 350390, 350570, 350660, 350900, 350920, 351060, 351300, 351380, 351500, 351510, 351570, 351630, 351640, 351830, 351880, 352220, 352250, 352310, 352500, 352620, 352850, 352940, 353060, 353440, 353910, 353980, 354330, 354410, 354500, 354680, 354730, 354780, 354870, 354880, 354995, 355030, 355250, 355280, 355645) //  municipality codes belonging to the metropolitan region of Sao Paulo in 2015
			*/
			keep if inlist(${muni_var}, 310500, 311787, 312410, 312980, 313010, 313220, 313460, 313660, 313665, 314015, 314070, 314110, 314480, 314930, 315390, 315460, 315530, 315670, 315780, 316292, 317120, 310620, 310670, 310900, 311000, 311250, 311860, 312600, 313370, 313760, 315480, 316295, 316553, 316830) /// municipality codes belonging to the metropolitan region of Belo Horizonte in 2001 or 2015
				| inlist(${muni_var}, 430060, 430087, 430110, 430310, 430390, 430460, 430468, 430535, 430640, 430676, 430760, 430770, 430905, 430920, 430930, 431010, 431080, 431240, 431306, 431337, 431340, 431405, 431480, 431490, 431600, 431760, 431840, 431870, 431950, 431990, 432000, 432120, 432200, 432300) /// municipality codes belonging to the metropolitan region of Porto Alegre in 2001 or 2015
				| inlist(${muni_var}, 260005, 260105, 260290, 260345, 260680, 260720, 260760, 260775, 260790, 260940, 260960, 261070, 261160, 261370) /// municipality codes belonging to the metropolitan region of Recife in 2001 or 2015
				| inlist(${muni_var}, 330045, 330080, 330170, 330185, 330190, 330200, 330227, 330250, 330260, 330270, 330285, 330320, 330330, 330350, 330360, 330414, 330430, 330455, 330490, 330510, 330555, 330575) /// municipality codes belonging to the metropolitan region of Rio de Janeiro in 2001 or 2015
				| inlist(${muni_var}, 290570, 290650, 291005, 291610, 291920, 291992, 292100, 292520, 292740, 292920, 292950, 293070, 293320) /// municipality codes belonging to the metropolitan region of Salvador in 2001 or 2015
				| inlist(${muni_var}, 350390, 350570, 350660, 350900, 350920, 351060, 351300, 351380, 351500, 351510, 351570, 351630, 351640, 351830, 351880, 352220, 352250, 352310, 352500, 352620, 352850, 352940, 353060, 353440, 353910, 353980, 354330, 354410, 354500, 354680, 354730, 354780, 354870, 354880, 354995, 355030, 355250, 355280, 355645) // municipality codes belonging to the metropolitan region of Sao Paulo in 2001 or 2015
			count
			local N_post_pme_muni_sel = r(N)
			local N_pme_muni_sel = `N_pre_pme_muni_sel' - `N_post_pme_muni_sel'
			local N_perc_pme_muni_sel = 100*`N_pme_muni_sel'/`N_pre_pme_muni_sel'
			local N_perc_pme_muni_sel: disp %4.2f `N_perc_pme_muni_sel'
			disp "--> restriction to PME municipalities deleted `N_pme_muni_sel' obs. (`N_perc_pme_muni_sel'%)."
			drop $muni_var
		}
		
		* format data: generate variable containing total months worked in a job
		gen byte months_worked = .
		replace months_worked = sep_month - hire_month + 1 if sep_month > 0 & hire_month > 0
		replace months_worked = 12 - hire_month + 1 if sep_month == 0 & hire_month > 0
		replace months_worked = sep_month - 1 + 1 if sep_month > 0 & hire_month == 0
		replace months_worked = 12 - 1 + 1 if sep_month == 0 & hire_month == 0
		
		* top trimming: keep only observations with earnings on any given job of up to 120 times the minimum wage
		count
		local N_pre_top_trim = r(N)
		keep if ${labor_var} <= 120
		count
		local N_post_top_trim = r(N)
		local N_top_trim = `N_pre_top_trim' - `N_post_top_trim'
		local N_perc_top_trim = 100*`N_top_trim'/`N_pre_top_trim'
		local N_perc_top_trim: disp %4.2f `N_perc_top_trim'
		disp "--> top trimming deleted `N_top_trim' obs. (`N_perc_top_trim'%)."
		
		* format data: replace average monthly earnings with total yearly earnings in a given job and year
		replace ${labor_var} = ${labor_var}*months_worked
		drop months_worked
		
		* bottom trimming: keep only observations with total annual labor earnings above 1.5 months at minimum wage
// 		if "${gtools}" == "" {
			bys ${personid_var} ${year_var}: egen float ${labor_var}_tot_temp = total(${labor_var}), missing
// 		}
// 		else {
// 			bys ${personid_var} ${year_var}: gegen float ${labor_var}_tot_temp = total(${labor_var}), missing
// 		}
		count
		local N_pre_bottom_trim = r(N)
		
		* create indicator for lower income threshold (instead of using matrix rmininc) and keep only observations with total annual earnings >=0.5*monthly minimum wage
		gen byte lower_thresh = 0 if ${labor_var}_tot_temp < . // 0 = has total annual earnings < 0.5*monthly minimum wage
		replace lower_thresh = lower_thresh + 1 if ${labor_var}_tot_temp >= 0.5 & ${labor_var}_tot_temp < . // 1 = has total annual earnings >= 0.5*monthly minimum wage but < 1.5*monthly minimum wage
		replace lower_thresh = lower_thresh + 1 if ${labor_var}_tot_temp >= 1.5 & ${labor_var}_tot_temp < . // 2 = has total annual earnings >= 1.5*monthly minimum wage
		label var lower_thresh "Lower earnings threshold (0: <0.5*MW, 1: >=0.5 but <1.5*MW, 2: >=1.5*MW)"
// 		keep if ${labor_var}_tot_temp >= 1.5 & ${labor_var}_tot_temp < . // more stringent criterion: must have total annual earnings >= 1.5*monthly minimum wage
// 		keep if ${labor_var}_tot_temp >= 0.5 & ${labor_var}_tot_temp < . // less stringent criterion: must have total annual earnings >= 0.5*monthly minimum wage
		keep if lower_thresh == 1 | lower_thresh == 2
		count
		local N_post_bottom_trim = r(N)
		local N_bottom_trim = `N_pre_bottom_trim' - `N_post_bottom_trim'
		local N_perc_bottom_trim = 100*`N_bottom_trim'/`N_pre_bottom_trim'
		local N_perc_bottom_trim: disp %4.2f `N_perc_bottom_trim'
		disp "--> bottom trimming deleted `N_bottom_trim' obs. (`N_perc_bottom_trim'%)."
		drop ${labor_var}_tot_temp
		
		* format data: replace average monthly earnings in multiples of minimum wage with average monthly earnings in nominal BRL
		merge m:1 ${year_var} hire_month sep_month using "${MINWAGE_FILE}", nogen keepusing(mw) keep(master match)
		drop hire_month sep_month
		replace ${labor_var} = ${labor_var}*mw
		drop mw
		
		* format data: generate total yearly earnings in all jobs in a given year
// 		if "${gtools}" == "" {
			bys ${personid_var} ${year_var}: egen float ${labor_var}_tot = total(${labor_var}), missing
// 		}
// 		else {
// 			bys ${personid_var} ${year_var}: egen float ${labor_var}_tot = total(${labor_var}), missing
// 		}
		drop ${labor_var}
		rename ${labor_var}_tot ${labor_var}
		label var ${labor_var} "Total annual labor earnings from all jobs during the year"
		
		* format data: keep a single observation per individual and year
		bys ${personid_var} ${year_var}: keep if _n == 1
	
		save "${datafile}`y'", replace
	}
	
	* append yearly files
	clear
	forval y = $yrfirst/$yrlast {
		disp "--> appending year `y'"
		append using "${datafile}`y'.dta"
		erase "${datafile}`y'.dta"
	}
	save "${datafile}", replace
	
	* load appended data -- commented out because the above code replaces the following!
// 	use $personid_var $male_var $yob_var $yod_var $educ_var $year_var $labor_var ///
// 		if ${year_var} >= ${yrfirst} & ${year_var} <= ${yrlast} using "${datafile}"
	describe
	tab ${year_var}
	/*  The default STATA reshape commend is slow! 
	timer clear 1
	timer on 1
	sort $personid_var $year_var
	${gtools}reshape wide $labor_var, i($personid_var) j($year_var)
	timer off 1
	timer list 1
	*/
	// The below part reshapes data in long format to wide. Faster than RESHAPE commend. 
	sort $personid_var $year_var
	forvalues yr = $yrfirst/$yrlast{
		preserve
		keep if $year_var ==`yr'
		
		rename $labor_var $labor_var`yr'
		rename lower_thresh lower_thresh`yr'
		
		keep $personid_var ${labor_var}`yr' lower_thresh`yr' $male_var $yob_var $yod_var $educ_var
			// Need to keep all variable. If only keep for first year, we 
			// miss the data for observations that enter in the sample after 
			// the first year. 
		
		sort $personid_var
		save "temp`yr'.dta",replace
		restore
	}
	
	local first=$yrfirst+1
	use "temp$yrfirst.dta", clear
	erase temp${yrfirst}.dta
	forvalues yr=`first'/$yrlast{
		merge 1:1 $personid_var using "temp`yr'.dta", nogen update replace
				// update replace makes sure the variables such as year of birth 
				// are replaced by noin missing values for observations that enter 
				// in the sample after the first year. 
		erase temp`yr'.dta
		sort $personid_var
	}
	
	order $personid_var $male_var $yob_var $yod_var $educ_var ${labor_var}* lower_thresh*

}

rename $personid_var personid
rename $male_var male
rename $yob_var yob
rename $yod_var yod
rename $educ_var educ


// Drop anybody who is too old or too young or too dead. 
// Criteria 1 (Age) in CS Sample
drop if yob==.
drop if $yrfirst-yob+1>$end_age | $yrlast-yob+1<$begin_age 
drop if yod<=$yrfirst & yod~=.
describe

global base_price_index = ${base_price}-${yrfirst}+1	// The base year nominal values are converted to real. 

forvalues yr = $yrfirst/$yrlast{

	rename ${labor_var}`yr' labor`yr'
	
	label var labor`yr' "Real labor earnings in `yr'"

	// Covert to real values
	// Criteria d (Inflation) in CS Sample
	
	local cpi_index = `yr'-${yrfirst}+1
	replace labor`yr'=labor`yr'/cpimat[`cpi_index',1]		//Coverting to real values
	
	// Winsorization
	gen float temp=labor`yr' if `yr'-yob+1>= $begin_age & `yr'- yob+1<= $end_age & `yr'< yod  // yod=. id very big number  
	if "${gtools}" == "" _pctile temp, p($winsor)
	else gquantiles temp, _pctile p($winsor)
	replace labor`yr'= r(r1) if labor`yr'>=r(r1) & labor`yr'!=. 
	drop temp
		
	// Add a small noise
	gen float temp=${noise}*(uniform()-0.5) // = 0 for Brazil
	replace labor`yr'=labor`yr'+labor`yr'*temp 
	drop temp

	if(${miss_earn}==0){
	// Any earnings that are missing inside of $begin_age and $end_age are set to zero.
	replace labor`yr'= 0 if labor`yr'== . &  ///
	   `yr'-yob+1 >= $begin_age & `yr'- yob+1<=$end_age & `yr'< yod
	}
		
	// Assing missing if outside of $begin_age and $end_age
	replace labor`yr'= . if `yr'-yob+1 < $begin_age | `yr'- yob+1>$end_age 
	replace labor`yr'= . if `yr'>= yod & yod~=.  // (yod=. is very big number)
	
}

// Base sample creation completed.
order personid male yob yod educ labor* lower_thresh*
compress
save "${TEMP_DIR}${sep}dta${sep}base_sample.dta", replace


// Creating residuals of log-earnings and saving the coefficients

cd "${maindir}${sep}dta${sep}"

forvalues yr = $yrfirst/$yrlast{	
	use personid male yob educ labor`yr' lower_thresh`yr' using ///
	"${TEMP_DIR}${sep}dta${sep}base_sample.dta" if labor`yr'!=. , clear   
	
	// Create year
	gen int year=`yr'
	
	// Create age 
	gen byte age = `yr'-yob+1
	drop if age<${begin_age} | age>${end_age}
	
	// Create log earn if earnings above the min treshold
	// Criteria c (Trimming) in CS Sample
	// Notice we do not drop the observations but log-earnings are generated for those with
	// income below 1/3*min threshold. Variable logearn`yr'c is used for growth rates conditional
	// on permanent income only
	
// 	gen float logearn`yr' = log(labor`yr') if labor`yr'>=rmininc[`yr'-${yrfirst}+1,1] & labor`yr'!=. 
	gen float logearn`yr' = log(labor`yr') if (lower_thresh`yr' == 2) & labor`yr'!=. 
// 	gen float logearnc`yr' = log(labor`yr') if labor`yr'>=(1/3)*rmininc[`yr'-${yrfirst}+1,1] & labor`yr'!=.
	gen float logearnc`yr' = log(labor`yr') if (lower_thresh`yr' == 1 | lower_thresh`yr' == 2) & labor`yr'!=.
	drop lower_thresh`yr'
	drop if logearnc`yr' == . & logearn`yr' == .
	
	// Create dummies for age and education groups
	tab age, gen(agedum)
	drop agedum1
	tab educ, gen(educdum)
	drop educdum1

	// Regression for residuals earnigs
	statsby _b,  by(year) saving(age_yr`yr'_m,replace):  ///
	regress logearn`yr' agedum* if male==1
	
	predict temp_m if e(sample)==1, resid
	
	statsby _b,  by(year) saving(age_yr`yr'_f,replace):  ///
	regress logearn`yr' agedum* if male==0
	
	predict temp_f if e(sample)==1, resid
	
	// Regressions for residuals earnings with income above 1/3*minincome
	regress logearnc`yr' agedum* if male==1
	predict temp_m_c if e(sample)==1, resid
	
	regress logearnc`yr' agedum* if male==0
	predict temp_f_c if e(sample)==1, resid
	
	// Regressions for profiles with education
	statsby _b,  by(year) saving(age_educ_yr`yr'_m,replace):  ///
	regress logearn`yr' educdum* agedum* if male==1	
	predict temp_m_e if e(sample)==1, resid
	
	statsby _b,  by(year) saving(age_educ_yr`yr'_f,replace):  ///
	regress logearn`yr' educdum* agedum* if male==0	
	predict temp_f_e if e(sample)==1, resid
		
	// Generate the residuals by year and save a database for later append.
	gen float researn`yr'= temp_m
	replace researn`yr'= temp_f if male==0
	
	gen float researnc`yr'= temp_m_c
	replace researnc`yr'= temp_f_c if male==0 
	
	gen researne`yr'= temp_m_e
	replace researne`yr'= temp_f_e if male==0 	
	
	
	// Save data set for later append
	label var researn`yr' "Residual of real log-labor earnings of year `yr' with total annual earnings >= 1.5*monthly MW"
	label var logearn`yr' "Real log-labor earnings of year `yr' with total annual earnings >= 1.5*monthly MW"
	label var researnc`yr' "Residual of real log-labor earnings of year `yr' with total annual earnings >= 0.5*monthly MW"
	label var logearnc`yr' "Real log-labor earnings of year `yr' with total annual earnings >= 0.5*monthly MW"
	label var researne`yr' "Residual of real log-labor earnings of year `yr' (Age and Education)"
	
	preserve
		keep personid researn`yr' researnc`yr' logearn`yr' logearnc`yr' labor`yr' male yob
		sort personid
		save "researn`yr'.dta", replace
	restore 
	
	keep personid researne`yr' male
	sort personid
	save "researne`yr'.dta", replace

}

forvalues yr = $yrfirst/$yrlast{
	if (`yr' == $yrfirst){
		use researn`yr'.dta, clear
		erase researn`yr'.dta
	}
	else{
		merge 1:1 personid using researn`yr'.dta, nogen
		erase researn`yr'.dta
	}
	sort personid
}
save "researn.dta", replace 

forvalues yr = $yrfirst/$yrlast{
	if (`yr' == $yrfirst){
		use researne`yr'.dta, clear
		erase researne`yr'.dta
	}
	else{
		merge 1:1 personid using researne`yr'.dta, nogen
		erase researne`yr'.dta
	}
	sort personid
}
save "researne.dta", replace 
// END: Residuals calculation complete

// Appending coefficients of agen and education for gender groups 
clear
forvalues yr = $yrfirst/$yrlast{
	append using age_educ_yr`yr'_m.dta
	cap: gen byte male = 1 
	cap: replace male = 1 if male == . 
	erase age_educ_yr`yr'_m.dta
	append using age_educ_yr`yr'_f.dta
	cap: replace male = 0 if male == . 
	erase age_educ_yr`yr'_f.dta	
}
order year male 
save "age_educ_dums.dta", replace 

// Appending coefficients of age for gender groups 
clear
forvalues yr = $yrfirst/$yrlast{
	append using age_yr`yr'_m.dta
	cap: gen male = 1 
	cap: replace male = 1 if male == .
	erase age_yr`yr'_m.dta
	append using age_yr`yr'_f.dta
	cap: replace male = 0 if male == . 
	erase age_yr`yr'_f.dta	
}
order year male 
save "age_dums.dta", replace 
// END: coefficients appending complete

// Calculate growth of (residual) earnings (Section 2.e and 2.f)
clear
foreach k in 1 5{

	// Given the jump k, calculate the growth rate for each worker in each year

	local lastyr=$yrlast-`k'
	forvalues yr = $yrfirst/`lastyr'{
	
		local yrnext=`yr'+`k'

		use personid male yob researn`yr' researnc`yrnext' labor`yrnext' labor`yr' using "researn.dta", clear
		
		gen age = `yr'-yob+1
		
// 		if "${gtools}" == "" {
			bys male age: egen float avelabor`yrnext' = mean(labor`yrnext')
			bys male age: egen float avelabor`yr' = mean(labor`yr')
// 		}
// 		else {
// 			bys male age: gegen float avelabor`yrnext' = mean(labor`yrnext')
// 			bys male age: gegen float avelabor`yr' = mean(labor`yr')
// 		}
		
		gen float researn`k'F`yr'= researnc`yrnext'-researn`yr'		// Growth with earnings above mininc in t and 1/3*mininc in t+k
		gen float arcearn`k'F`yr'= (labor`yrnext'/avelabor`yrnext' - labor`yr'/avelabor`yr')/(0.5*(labor`yrnext'/avelabor`yrnext' + labor`yr'/avelabor`yr'))
		
		label var researn`k'F`yr'  "Residual earnings growth between `yrnext' and `yr'"
		label var arcearn`k'F`yr'  "Arc-percent earnings growth between `yrnext' and `yr'"

		keep personid researn`k'F`yr' arcearn`k'F`yr'
		save researn`k'F`yr'.dta, replace
		
	}
	
	// Merge data across all years
	forvalues yr = $yrfirst/`lastyr'{
	
		if (`yr' == $yrfirst){
		use researn`k'F`yr'.dta, clear
		erase researn`k'F`yr'.dta
		}
		else{
			merge 1:1 personid using researn`k'F`yr'.dta, nogen
			erase researn`k'F`yr'.dta
		}
		sort personid
	}
	
	compress 
	save "researn`k'F.dta", replace 
	
}
// END calculate growth rates

// Calculate permanent income
clear
local firstyr=$yrfirst+2
forvalues yr = `firstyr'/$yrlast{
	local yrL1=`yr'-1
	local yrL2=`yr'-2	

	use ///
		personid male yob educ labor`yrL2' labor`yrL1' labor`yr' lower_thresh`yrL2' lower_thresh`yrL1' lower_thresh`yr' ///
		using "${TEMP_DIR}${sep}dta${sep}base_sample.dta" if labor`yr'!=. , clear  
	
	// Create year
	gen int year=`yr'
	
	// Create age 
	gen byte age = `yr'-yob+1
	drop if age<${begin_age} | age>${end_age}
	
	// Create average income for those with at least 2 years of income above 
	// the treshold income between t-1 and t-3
	gen float totearn=0
	gen byte numobs=0
	
	*replace numobs = -5 if labor`yr' < rmininc[`yr'-${yrfirst}+1,1]
	// This ensures that permanent income is only constructed for those 
	// with income above the threshold in t-1
		
	
	forvalues yrp=`yrL2'/`yr'{
		replace totearn=totearn+labor`yrp' if labor`yrp'!=.
// 		replace numobs=numobs+1 if labor`yrp'>=rmininc[`yrp'-${yrfirst}+1,1] & labor`yrp'!=.		
		replace numobs=numobs+1 if lower_thresh`yrp'==2 & labor`yrp'!=.
		drop lower_thresh`yrp'
		// Notice earnings below the min threshold are still used to get totearn
	}
		
	replace totearn=totearn/numobs if numobs>=2			// Average income
	drop	if numobs<2									// Drop if less than 2 obs
	
	// Create log earn
	replace totearn = log(totearn) 
	drop if totearn==.
	
	// Gen dummies for regressions
	tab age, gen(agedum)
	drop agedum1
	
	// Regression to get residuals permanent income
	regress totearn agedum* if male==1
	predict temp_m if e(sample)==1, resid
	
	qui regress totearn agedum* if male==0
	predict temp_f if e(sample)==1, resid
	
	gen float permearn`yr'= temp_m
	replace permearn`yr'= temp_f if male==0

	// Save 
	keep personid permearn`yr'
	label var permearn`yr' "Residual permanent income between `yr' and `yrL2'"
	
	compress 
	sort personid
	save "permearn`yr'.dta", replace
	
}

clear
local firstyr=$yrfirst+2
forvalues yr = `firstyr'/$yrlast{

	if (`yr' == `firstyr'){
		use permearn`yr'.dta, clear
		erase permearn`yr'.dta
	}
	else{
		merge 1:1 personid using permearn`yr'.dta, nogen
		erase permearn`yr'.dta
	}
	sort personid
}
save "permearn.dta", replace 
***
*/
/* Calculate modified permanent income
   Relative to the previos version, here we consider all individuals 
   even thouse with low earnimgs. See section "Key Statisitcs 4: Mobilitity"
*/
clear
local firstyr=$yrfirst+2
forvalues yr = `firstyr'/$yrlast{
	local yrL1=`yr'-1
	local yrL2=`yr'-2			

	use ///
		personid male yob educ labor`yrL1' labor`yrL2' labor`yr' lower_thresh`yr' lower_thresh`yrL1' lower_thresh`yrL2' ///
		using "${TEMP_DIR}${sep}dta${sep}base_sample.dta" if labor`yr'!=. , clear  
	
	// Create year
	gen int year=`yr'
	
	// Create age 
	gen byte age = `yr'-yob+1
	drop if age<${begin_age} + 2 | age>${end_age}			// This makes the min age 26 and max age 54
	
	// Create average income for those with at least 2 years of income 
	gen float totearn=0
	gen byte numobs=0
	gen numobspos=0
	
	forvalues yrp=`yrL2'/`yr'{
		replace totearn=totearn+labor`yrp' if labor`yrp'~=.
		replace numobs=numobs+1 if labor`yrp'~=.
// 		replace numobspos=numobspos+1 if labor`yrp'>= rmininc[`yrp'-${yrfirst}+1,1] & labor`yrp'~=.	
		replace numobspos=numobspos+1 if (lower_thresh`yrp' == 1 | lower_thresh`yrp' == 2) & labor`yrp'~=.
		drop lower_thresh`yrp'
			// Notice earnings below the min threshold are still used to get totearn
			// This ensure we do not consider income of individuals when they were 24 yrs old or less
	}
	replace totearn=totearn/numobs if numobs==3			// Average income	
	drop if numobs<3			// Drop if less than 2 obs
	drop if numobspos < 1 		// Drop if less than 1 obs above min income 
	drop if totearn==.	
	gen float permearnalt`yr' = totearn
		
	// Save 
	keep personid permearnalt`yr'
	label var permearnalt`yr' "Altenative residual permanent income between `yr' and `yrL2'"
	

	compress 
	sort personid
	save "permearnalt`yr'.dta", replace
	
}
***

clear
local firstyr=$yrfirst + 2
forvalues yr = `firstyr'/$yrlast{

	if (`yr' == `firstyr'){
		use permearnalt`yr'.dta, clear
		erase permearnalt`yr'.dta
	}
	else{
		merge 1:1 personid using permearnalt`yr'.dta, nogen
		erase permearnalt`yr'.dta
	}
	sort personid
}
save "permearnalt.dta", replace 

// END of calculation of alternative permanent income

// Merge all data sets to a master code

use "${TEMP_DIR}${sep}dta${sep}base_sample.dta", clear 
merge 1:1 personid using "permearn.dta", nogen 			
merge 1:1 personid using "permearnalt.dta", nogen 			
merge 1:1 personid using "researn.dta", nogen 
merge 1:1 personid using "researn1F.dta", nogen 
merge 1:1 personid using "researn5F.dta", nogen 
compress
desc
order personid male yob yod educ labor* logearn* permearn* researn* arcearn*
save "${TEMP_DIR}${sep}dta${sep}master_sample.dta", replace 


cap log close

// END OF DO-FILE
//////////////////////////////////////////////
