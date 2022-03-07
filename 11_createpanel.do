********************************************************************************
* DESCRIPTION: Clean the raw PME data and create a panel at the level of survey,
*              using Data Zoom routines created by PUC-Rio with support from
*              FINEP.
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
clear all


*** main code
disp "--> make PME data compatible across years and construct panel"
//datazoom_pmenova, years(${years_pme}) original("${DIR_READ_PME_NOVA}") saving("${DTA_DIR}") idrs

disp "--> process compatible PME data panel"
global l_first = "A"
global l_last = "V"
global l_list = ""
forval l_n = 0/9 {
	foreach l in `c(ALPHA)' {
		if `l_n' == 0 & "`l'" == "${l_first}" disp "* reading panels:" /* display "reading panels" */
		if `l_n' == 0 local l_n_str = ""
		else  local l_n_str = "`l_n'"
		disp "   ...`l'`l_n_str'"
		
		* read
		local use_vars = "idind v035 v060 v063 v070 v075 v072 v112 v113 v114 v115 v203 v206 v209 v208 v210 v211 v215 v234 v302 v306 v307 v310 v311 v409 ${earnings_pme} ${earnings_pme}df ${earnings_pme_others} ${earnings_pme_others}df v401 v403 v406 v412 v4121 v4122 v414 v415 v425 v4271 v4272 v4275 v4274 v428 v455 v456 v457 v458 v459 v465 v466 v407A v408A v430 v432 vI4302 vI4302df v438"
		qui use `use_vars' using "${DTA_DIR}/pmenova_painel_`l'`l_n_str'_rs.dta", clear
		rename idind id
		rename v035 region
		label define region_l 26 "Recife" 29 "Salvador" 31 "Belo Horizonte" 33 "Rio de Janeiro" 35 "Sao Paulo" 41 "Curitiba" 43 "Porto Alegre", replace
		label values region region_l
		rename v060 panel // from A-V
		rename v063 rotation_group // from 1-8 
		rename v070 month
		rename v075 year
		rename v072 spell
		rename v112 stratid 
		rename v113 psu
		rename v114 pop
		qui drop if inlist(.,stratid,psu,pop)
		rename v211 weight
		rename v215 weight_proj
		rename v115 mw
		rename v203 gender
		qui recode gender (2 = 0)
		label define gender_l 0 "female" 1 "male", replace
		label values gender gender_l
		rename v206 hh_condition
		label define hh_condition_l 1 "head of the household" 2 "spouse" 3 "son/daughter" 4 "other parent" 5 "aggregate" 6 "pensioner" 7 "domestic employee" 8 "domestic employee parent"
		label values hh_condition hh_condition_l
		rename v209 hh_size
		rename v210 hh_size_10y
		rename v208 race
		label define race_l 1 "white" 2 "black" 3 "yellow" 4 "brown" 5 "native" 
		label values race race_l 
		rename v234 age
		rename v302 in_school
		qui recode in_school (2 = 0) /* all non-missing for age >= 10: tab in_school if age >= 10, m */
		qui gen edu_degree = .
		rename v306 school_prior /* all non-missing for those out of school: tab school_prior if in_school == 0, m */
		rename v307 school_prior_grade /* all non-missing for those previously in school: tab school_prior_grade if school_prior == 1, m */
		rename v311 school_prior_concluded
		qui replace school_prior_concluded = 0 if in_school == 0 & school_prior == 1 & school_prior_concluded == . /* assume that respondent did not complete degree if previously attended but did not report graduation status */
		
		qui gen edu_years = .
		rename v310 school_years
		qui replace edu_years = 0 if school_prior == 2 | school_prior_grade == 8
		qui replace edu_years = 2 if school_prior_grade == 7
		forval school_y = 1/8 {
			qui replace edu_years = min(`school_y',4) if (school_prior_grade == 1 & school_years == `school_y')
			qui replace edu_years = 4 + min(`school_y',4) if (school_prior_grade == 2 & school_years == `school_y')
			qui replace edu_years = `school_y' if (school_prior_grade == 4 & school_years == `school_y')
			qui replace edu_years = 8 + `school_y' if (inlist(school_prior_grade,3,5) & school_years == `school_y')
			qui replace edu_years = 12 + min(`school_y',4) if (school_prior_grade == 6 & school_years == `school_y')
		}
		qui replace edu_years = 16 if school_prior_grade == 9
		qui replace edu_years = 2 if school_prior_grade == 1 & school_years == .
		qui replace edu_years = 6 if school_prior_grade == 2 & school_years == .
		qui replace edu_years = 4 if school_prior_grade == 4 & school_years == .
		qui replace edu_years = 10 if inlist(school_prior_grade,3,5) & school_years == .
		qui replace edu_years = 14 if school_prior_grade == 6 & school_years == .
		qui replace edu_years = 4 if school_prior_grade == 1 & school_prior_concluded == 1
		qui replace edu_years = 8 if school_prior_grade == 2 & school_prior_concluded == 1
		qui replace edu_years = 8 if school_prior_grade == 4 & school_prior_concluded == 1
		qui replace edu_years = 12 if inlist(school_prior_grade,3,5) & school_prior_concluded == 1
		qui replace edu_years = 16 if school_prior_grade == 6 & school_prior_concluded == 1
		qui replace edu_degree = 1 if (school_prior == 2 | inlist(school_prior_grade,7,8) | (inlist(school_prior_grade,1,4) & school_prior_concluded == 2))
		qui replace edu_degree = 2 if ((inlist(school_prior_grade,1,4) & school_prior_concluded == 1) | school_prior_grade == 2 | (inlist(school_prior_grade,3,5) & school_prior_concluded == 2))
		qui replace edu_degree = 3 if ((inlist(school_prior_grade,3,5) & school_prior_concluded == 1) | (school_prior_grade == 6 & school_prior_concluded == 2))
		qui replace edu_degree = 4 if ((school_prior_grade == 6 & school_prior_concluded == 1) | school_prior_grade == 9)
		label define edu_degree_l 1 "< primary school" 2 "primary school" 3 "high school" 4 "college", replace
		label values edu_degree edu_degree_l
		qui gen complt_le = edu_degree == 1 if edu_degree < .
		qui gen complt_pr = edu_degree == 2 if edu_degree < .
		qui gen complt_hs = edu_degree == 3 if edu_degree < .
		qui gen complt_co = edu_degree == 4 if edu_degree < .
		drop school_prior school_prior_grade school_prior_concluded
		rename v409 job_type
		qui recode job_type (6 = 5)
		label define job_type_l 1 "domestic worker" 2 "employee" 3 "self-employed" 4 "employer" 5 "unpaid", replace
		label values job_type job_type_l
		rename ${earnings_pme} earnings 
		rename ${earnings_pme}df earnings_def
		rename ${earnings_pme_others} earnings_others
		rename ${earnings_pme_others}df earnings_others_def
		qui replace earnings = earnings_others if earnings == .
		qui replace earnings_def = earnings_others_def if earnings_def == .
		drop earnings_others earnings_others_def
		qui gen log_earn_d = ln(earnings_def)
		qui gen job = .
		rename v401 job_worked
		rename v403 job_absent
		qui replace job_worked = 2 if job_type == . & (job_worked == 1 | job_absent == 1) /* assume respondent did not work if job type is not reported */
		qui replace job_absent = 2 if job_type == . & (job_worked == 1 | job_absent == 1) /* assume respondent was not absent from work if job type is not reported */
		qui replace job_absent = 2 if job_worked != 1 & job_absent == . & in_school == 0 /* assume respondent was not absent from work if did not work, did not attend school, and job absence is not reported */
		qui replace job = 1 if ((job_worked == 1 | job_absent == 1) & job_type != 5)
		qui replace job = 0 if ((job_worked == 2 & job_absent == 2) | inlist(job_type,4,5)) /* all non-missing for those out of school: tab job if in_school == 0, m */
		drop job_worked job_absent
		rename v412 firm_size_categories /* information only if job_type == 2 (employee) */
		rename v4121 firm_size_2to5
		rename v4122 firm_size_6to10
		gen firm_size = .
		replace firm_size = firm_size_2to5 if firm_size_2to5 != .
		replace firm_size = firm_size_6to10 if firm_size_6to10 != .
		replace firm_size = 11 if firm_size_categories == 3
		drop firm_size_2to5 firm_size_6to10 firm_size_categories
		replace firm_size = 1 if job_type == 3 /* self employed has firm size == 1 */
		label define firm_size_l 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10" 11 "11 or more"
		label values firm_size firm_size_l 
		rename v414 military_public
		rename v415 formal_emp /* has a working card */
		rename v425 contributes_ss /* information only if job_type is self-employed or employer */
		qui recode contributes_ss (2 = 0)
		qui recode formal_emp (2 = 0)
		gen working_card = 0
		qui replace working_card = formal_emp
		qui replace formal_emp = 0 if inlist(job_type,1,3,4,5,.) /* note: working_card question is not done for job_type inlist(,3,4,5) */
		qui replace formal_emp = 1 if military_public == 1
		rename v4271 tenure_days
		rename v4272 tenure_y0_months
		rename v4275 tenure_y1_months
		rename v4274 tenure_years
		qui gen tenure = .
		qui replace tenure = tenure_days if tenure_days < .
		qui replace tenure = round(tenure_y0_months*30.5) if tenure_y0_months < .
		qui replace tenure = 365 + round(tenure_y1_months*30.5) if tenure_y1_months < .
		qui replace tenure = tenure_years*365 if tenure_years < .
		drop tenure_days tenure_y0_months tenure_y1_months tenure_years
		rename v428 hours
		rename v406 second_job
		qui recode second_job (3 = 2)			
		qui recode second_job (1 = 0)
		qui recode second_job (2 = 1) /* 0 no secondary jobs, 1 has secondary job in ref week */
		rename v430 type_second_income
		qui replace second_job = 0 if type_second_income != 1 & second_job != . /* do not have secondary job if other wage is not monetary */
		rename v432 contributes_ss_second
		qui recode contributes_ss_second (2=0)
		rename vI4302df earnings_second_job /* earnings = 0 if not domestic or employee */
		rename v438 hours_second_job
		qui gen searching = .
		rename v455 searching_recent_U
		rename v456 searching_longtime_U
		rename v457 searching_really
		rename v458 took_measure_refweek
		rename v459 took_measure_pastmonth
		qui replace searching = 1 if ((searching_recent_U == 1 | searching_longtime_U == 1) & searching_really != 10 & (took_measure_refweek == 1 | took_measure_pastmonth == 1))
		qui replace searching = 0 if ((searching_recent_U == 2 | searching_longtime_U == 2) | searching_really == 10 | (took_measure_refweek == 2 & took_measure_pastmonth == 2))
		drop searching_really searching_recent_U searching_longtime_U took_measure_refweek took_measure_pastmonth
		rename v465 willing_able_refweek
		rename v466 willing_able_pastmonth
		qui gen willing_able = .
		qui replace willing_able = 1 if (willing_able_refweek == 1 | willing_able_pastmonth == 1)
		qui replace willing_able = 0 if (willing_able_refweek == 2 & willing_able_pastmonth == 2)
		drop willing_able_refweek willing_able_pastmonth
		qui gen in_laborforce = .
		qui replace in_laborforce = 1 if (in_school == 0 & !inlist(job_type,4,5) & ((job == 1 & inlist(job_type,1,2,3)) | (searching == 1 & willing_able == 1)))
		qui replace in_laborforce = 0 if (in_school == 1 | inlist(job_type,4,5) | ((job == 0 | inlist(job_type,4,5)) & (searching == 0 | willing_able == 0))) /* note: all respondents with in_laborforce = 0 & job = 1 are in school */
		drop searching willing_able
		rename v407A occ
		qui recode occ (1/5 11/13 = 1) (20/26 = 2) (30/39 = 3) (41/42 = 4) (51/52 = 5) (61/64 = 6) (71/78 81/87 = 7) (91/99 = 8) (nonmissing = 0), generate(occ_agg)
		label define occ_l 1 "public/military officers" 2 "scientists, artists" 3 "mid-level technical" 4 "administrators" 5 "service/sales workers" 6 "agricultural workers" 7 "production workers" 8 "repair/maintenance workers" 0 "other", replace
		label values occ occ_l
		rename v408A ind
		qui recode ind (10/41 = 1) (45 = 2) (50/53 = 3) (65/74 = 4) (75 80/85 = 5) (95 = 6) (55/64 90/93 = 7) (1/5 99 0 = 8) (nonmissing = 0), generate(ind_agg)
		label define ind_l 1 "manufacturing" 2 "construction" 3 "commerce" 4 "finance/real estate" 5 "public services, education, health" 6 "domestic services" 7 "transport/telecom/urban" 8 "agriculture/intl/other" 0 "other", replace
		label values ind ind_l
		
		* define work status
		/* LEVEL 1: in_laborforce = 0,1 */
		/* LEVEL 2: if in_laborforce = 1, then job = 0,1 --> if job = 0 then unemployed */
		/* LEVEL 3: if job = 1, then formal_emp = 0,1 --> if formal_emp = 1 then formal, else if formal_emp = 0 then informal */
		qui gen status = .
		qui replace status = 1 if in_laborforce == 0
		qui replace status = 2 if in_laborforce == 1 & job == 0
		qui gen unemployed = .
		qui replace unemployed = 1 if in_laborforce == 1 & job == 0
		qui replace unemployed = 0 if in_laborforce == 1 & job == 1
		qui replace status = 3 if in_laborforce == 1 & job == 1 & formal_emp == 0
		qui replace status = 4 if in_laborforce == 1 & job == 1 & formal_emp == 1
		label define status_l 1 "out of labor force" 2 "unemployed" 3 "informal" 4 "formal", replace
		label values status status_l
		
		* label
		label var id "unique individual ID"
		label var panel "panel group in the survey (A-V)"
		label var rotation_group "rotation group in the survey (1-8)"
		label var year "survey year"
		label var month "survey month"
		label var spell "interview spell (1-8)"
		label var region "metropolitan region"
		label var stratid "stratum ID"
		label var psu "primary sampling unit (PSU)"
		label var mw "minimum wage (nominal BRL)"
		label var gender "gender"
		label var age "age"
		label var edu_degree "education degree"
		label var status "work status"
		label var in_laborforce "labor force status"
		label var unemployed "unemployed status"
		label var job "job status"
		label var job_type "job type"
		label var contributes_ss "contributes to social security"
		label var formal_emp "formal employment"
		label var working_card "has a working card"
		label var tenure "tenure (days)"
		label var hours "usual hours worked"
		label var earnings "earnings (nominal BRL)"
		label var second_job "has a secondary job (one or more extra)"
		label var type_second_income "type of secondary income"
		label var contributes_ss_second "contributes to social security in secondary job"
		label var earnings_second_job "earnings in secondary job"
		label var ind "industry (CNAE-Domiciliar)"
		label var ind_agg "industry (aggregated)"
		label var occ "occupation (CBO-Domiciliar)"
		label var occ_agg "occupation (aggregated)"
		label var weight "inverse probability weight (raw)"
		label var weight_proj "inverse probability weight (pop. projection)"
		label var in_school "attend school"
		label var hours_second_job "hours in the second job"
		label var race "race"
		label var hh_condition "household condition"
		label var hh_size "number of inhabitants in the household"
		label var hh_size_10y "number of inhabitants in the household that are >= 10y old"
		label var firm_size "number of people in the firm (incl. employees, employers, unpaid)"
		
		* clean up
		qui keep if ${use_conds_pme}
		sort id year month
		order id year month panel rotation_group spell region stratid psu gender age race hh* edu_degree in_school status in_laborforce job ind ind_agg occ occ_agg job_type firm_size contributes_ss formal_emp tenure hours earnings second_job type_second_income contributes_ss_second earnings_second_job mw weight weight_proj
		
		* save
		qui save "${DIR_WRITE_PME}/pme_panel_`l'`l_n_str'.dta", replace
		global l_list = "${l_list} `l'`l_n_str'"
		
		* loop control
		if "`l'`l_n_str'" == "${l_last}" local breaker = 1
		else local breaker = 0
		if `breaker' continue, break
	}
	if `breaker' continue, break
}

* append panels
local counter_append = 1
foreach l_str of global l_list {
	if `counter_append' == 1 qui use "${DIR_WRITE_PME}/pme_panel_`l_str'.dta", clear
	else qui append using "${DIR_WRITE_PME}/pme_panel_`l_str'.dta"
	local ++counter_append
}

* re-group interview spells
qui recode spell (1/4 = 1) (5/8 = 2), generate(spell_g)
qui egen id_g = group(id spell_g)

* merge in USD dollars
merge m:1 month year using "${DTA_DIR}/exchange_rate_monthly.dta"
drop if _merge == 2
drop _merge

* save
qui save "${DIR_WRITE_PME}/panel.dta", replace

