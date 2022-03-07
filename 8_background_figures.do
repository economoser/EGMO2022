********************************************************************************
* DESCRIPTION: Produce figures specific to Part B (formal vs. informal earnings
*              inequality and dynamics) of the GIDP project for Brazil.
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
* Creates graphs for background section of GIDP-BRA
*
* AUTHORS:     Niklas Engbom (NYU),
*			   Gustavo Gonzaga (PUC-Rio),
*			   Christian Moser (Columbia and FRB Minneapolis),
*			   Roberta Olivieri (Cornell).
*
* TIME STAMP:  Januar 12, 2022.
********************************************************************************


*** opening housekeeping
* log
cap log close

* create output directory
cap confirm file "${BACKGROUND_DIR}"
if _rc {
	!mkdir "${BACKGROUND_DIR}"
}

* create plot limits
global year_min_plot_adj = floor(${year_min_plot}/5)*5
global year_max_plot_adj = ceil(${year_max_plot}/5)*5

* text size
global text_size = "medlarge" // or "large"

* figure margins
global l_val = 1
global r_val = 1
global b_val = 1
global t_val = 1

* length of legend symbols
global symxsize = .45 // .66


*** GDP and GDP per capita growth from World Bank
* load GDP in constant LCU (https://data.worldbank.org/indicator/NY.GDP.MKTP.KN?locations=BR)
import excel using ///
	"${ROOT_DIR}/5_inputs/API_NY.GDP.MKTP.KN_DS2_en_excel_v2_3159053_processed.xls" ///
	, firstrow case(lower) clear
tempfile gdp
save `gdp'

 * load GDP per capita growth in constant 2010 US dollars (https://data.worldbank.org/indicator/NY.GDP.PCAP.KD.ZG?locations=BR)
import excel using ///
	"${ROOT_DIR}/5_inputs/API_NY.GDP.PCAP.KD.ZG_DS2_en_excel_v2_3159264_processed.xls" ///
	, firstrow case(lower) clear
merge 1:1 year using `gdp', nogen keepusing(gdp) keep(master match using)
	
* rename, format, and label
label var year "Year"
replace gdp = gdp/10^12
label var gdp "GDP (trillion constant BRL)"
label var gdp_pc_growth "Annual GDP per capita growth rate (%, constant BRL)"

* plots
tw ///
	(connected gdp year if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("GDP (trillion constant BRL)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(1)5, labsize(${text_size}) format(%2.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(gdp, replace)
graph export "${BACKGROUND_DIR}/gdp.pdf", replace
tw ///
	(connected gdp_pc_growth year if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Annual GDP per capita growth rate (%, constant BRL)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(-8(4)8, labsize(${text_size}) format(%2.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(gdp_pc_growth_alt, replace)
graph export "${BACKGROUND_DIR}/gdp_pc_growth_alt.pdf", replace


*** sectoral (agricultural, industrial, and services) composition of GDP from IPEA
* load sectoral GDP values in current BRL (http://www.ipeadata.gov.br/exibeserie.aspx?serid=1184389728 and http://www.ipeadata.gov.br/exibeserie.aspx?serid=1184389729 and http://www.ipeadata.gov.br/exibeserie.aspx?serid=1184389734)
import excel using ///
	"${ROOT_DIR}/5_inputs/ipeadata(30-01-2021-06-24)_gdp_shares.xls" ///
	, firstrow case(lower) clear
	
* rename, format, and label
label var year "Year"
foreach var of varlist gdp_share_* {
	replace `var' = `var'*100
}
label var gdp_share_agricultural "Agriculture share (%)"
label var gdp_share_industrial "Industrial share (%)"
label var gdp_share_service "Service share (%)"

* plots
tw ///
	(connected gdp_share_agricultural gdp_share_industrial gdp_share_service year if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue red green) mcolor(blue red green) msymbol(O D T) msize(vsmall vsmall vsmall) lwidth(medthick medthick medthick) lpattern(solid _ -)) ///
	, title("") legend(order(1 "Agricultural" 2 "Industrial" 3 "Service") size(${text_size}) region(color(none)) cols(3) ring(0) pos(11)) xtitle("") ytitle("Sectoral share of GDP (%)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(20)80, labsize(${text_size}) format(%3.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(structural_change, replace)
graph export "${BACKGROUND_DIR}/structural_change.pdf", replace


*** unemployment rate from IPEA
* load and prepare PME data from 1985-2016 (http://www.ipeadata.gov.br/exibeserie.aspx?serid=36465 and http://www.ipeadata.gov.br/exibeserie.aspx?serid=40326)
import excel using ///
	"${ROOT_DIR}/5_inputs/ipeadata(30-01-2021-05-08)_unemployment_pme.xls" ///
	, firstrow case(lower) clear
tempfile unemployment_pme
save `unemployment_pme'

* load and prepare PNAD data from 1992-2014 (http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=486696880)
import excel using ///
	"${ROOT_DIR}/5_inputs/ipeadata(30-01-2021-05-33)_unemployment_pnad.xls" ///
	, firstrow case(lower) clear
rename u_rate u_rate_pnad
qui count
set obs `=r(N) + 1'
replace year = 2015 if _n == _N
replace u_rate_pnad = 9.6 if _n == _N
generate byte month = 9
tempfile unemployment_pnad
save `unemployment_pnad'

* load and prepare PNAD-Continua data from 2012-2021 (https://www.ibge.gov.br/estatisticas/sociais/habitacao/17270-pnad-continua.html?=&t=series-historicas)
import excel using ///
	"${ROOT_DIR}/5_inputs/unemployment_rate_PNAD_Continua_processed.xlsx" ///
	, firstrow case(lower) clear
rename unemploymentrate u_rate_pnad_c

* merge with other unemployment data
merge 1:1 year month using `unemployment_pme', nogen keepusing(u_rate_pme_old u_rate_pme_new) keep(master match using)
merge 1:1 year month using `unemployment_pnad', nogen keepusing(u_rate_pnad) keep(master match using)
order year month u_rate_pme_old u_rate_pme_new u_rate_pnad u_rate_pnad_c
sort year month

* label
label var year "Year"
label var month "Month"
label var u_rate_pme_old "Unemployment rate (%, PME Antiga)"
label var u_rate_pme_new "Unemployment rate (%, PME)"
label var u_rate_pnad "Unemployment rate (%,PNAD)"
label var u_rate_pnad_c "Unemployment rate (%,PNAD-Continua)"

* create date variable in Stata date format
gen int date = ym(year,month)
format date %tm
label var date "Date (year-month combination)"

* create numeric date variable
gen float date_num = year + (month - 1)/12
label var date_num "Date (numeric)"

* plot
tw ///
	(connected u_rate_pme_old date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	(connected u_rate_pme_new date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(red) mcolor(red) msymbol(D) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	(connected u_rate_pnad date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(green) mcolor(green) msymbol(T) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	(connected u_rate_pnad_c date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(orange) mcolor(orange) msymbol(S) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Unemployment rate (%)", size(${text_size})) ///
	legend(order(1 "PME-Antiga" 2 "PME-Nova" 3 "PNAD" 4 "PNAD-Cont{c i'}nua") size(${text_size}) region(color(none)) cols(4) ring(0) pos(6) symxsize(*${symxsize})) ///
	xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(2)14, labsize(${text_size}) format(%2.0f) grid gstyle(dot) gmin gmax) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(u_rate_combined, replace)
graph export "${BACKGROUND_DIR}/u_rate_combined.pdf", replace


*** price index and inflation from IPEA -- for a description of different price indices in Brazil, see https://www.bcb.gov.br/en/monetarypolicy/priceindex
* load IPCA price index (http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=36482)
import excel using ///
	"${ROOT_DIR}/5_inputs/ipeadata(28-01-2021-10-45)_ipca.xls" ///
	, firstrow case(lower) clear

* rename and label
rename ipcadec1993100 ipca_index
label var ipca_index "Price index (Dec. 1993 = 100)"

* compute month-on-month inflation rate
sort year month
gen float ipca_inflation_m = 100*(ipca_index[_n] - ipca_index[_n - 1])/ipca_index[_n - 1]
label var ipca_inflation_m "Month-on-month inflation (%)"

* compute year-on-year inflation rate
sort year month
gen float ipca_inflation_y = 100*(ipca_index[_n] - ipca_index[_n - 12])/ipca_index[_n - 12]
label var ipca_inflation_y "Year-on-year inflation (%)"

* create date variable in Stata date format
gen int date = ym(year,month)
format date %tm
label var date "Date (year-month combination)"

* create numeric date variable
gen float date_num = year + (month - 1)/12
label var date_num "Date (numeric)"

* plots
tw ///
	(connected ipca_index date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Price index (Dec. 1993 = 100)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(1000)5000, labsize(${text_size}) format(%4.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_index, replace)
graph export "${BACKGROUND_DIR}/ipca_index.pdf", replace
tw ///
	(connected ipca_index date_num if inrange(year, ${year_min_trunc_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Price index (Dec. 1993 = 100)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(1000)5000, labsize(${text_size}) format(%4.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_index_truncated, replace)
graph export "${BACKGROUND_DIR}/ipca_index_truncated.pdf", replace
tw ///
	(connected ipca_inflation_m date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Month-on-month inflation rate (%)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(20)100, labsize(${text_size}) format(%3.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_m, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_m.pdf", replace
tw ///
	(connected ipca_inflation_m date_num if inrange(year, ${year_min_trunc_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Month-on-month inflation rate (%)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(-1(1)4, labsize(${text_size}) format(%1.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_m_truncated, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_m_truncated.pdf", replace
tw ///
	(connected ipca_inflation_m date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	(connected ipca_inflation_m date_num if inrange(year, ${year_min_trunc_plot}, ${year_max_plot}), yaxis(2) lcolor(red) mcolor(red) msymbol(D) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") legend(off) xtitle("") ytitle("Month-on-month inflation rate (%), ${year_min_plot}-${year_max_plot}", size(${text_size}) color(blue) axis(1)) ytitle("Month-on-month inflation rate (%), ${year_min_trunc_plot}-${year_max_plot}", size(${text_size}) color(red) axis(2)) yscale(lcolor(blue) axis(1)) yscale(lcolor(red) axis(2)) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(20)100, labsize(${text_size}) format(%3.0f) grid gstyle(dot) gmin gmax labcolor(blue) tlcolor(blue) axis(1)) ylabel(-1(1)4, format(%1.0f) nogrid labcolor(red) tlcolor(red) axis(2)) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_m_both, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_m_both.pdf", replace
tw ///
	(connected ipca_inflation_y date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Year-on-year inflation rate (%)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(1000)7000, labsize(${text_size}) format(%4.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_y, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_y.pdf", replace
tw ///
	(connected ipca_inflation_y date_num if inrange(year, ${year_min_trunc_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Year-on-year inflation rate (%)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(4)28, labsize(${text_size}) format(%2.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_y_trunc, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_y_trunc.pdf", replace
tw ///
	(connected ipca_inflation_y date_num if inrange(year, ${year_min_plot}, ${year_min_trunc_plot} - 1), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	(connected ipca_inflation_y date_num if inrange(year, ${year_min_trunc_plot}, ${year_max_plot}), yaxis(2) lcolor(red) mcolor(red) msymbol(D) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") legend(off) xtitle("") ytitle("Year-on-year inflation rate (%), ${year_min_plot}-${year_max_plot}", size(${text_size}) color(blue) axis(1)) ytitle("Year-on-year inflation rate (%), ${year_min_trunc_plot}-${year_max_plot}", size(${text_size}) color(red) axis(2)) yscale(lcolor(blue) axis(1)) yscale(lcolor(red) axis(2)) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(1000)7000, labsize(${text_size}) format(%4.0f) grid gstyle(dot) gmin gmax labcolor(blue) tlcolor(blue) axis(1)) ylabel(0(4)28, format(%2.0f) nogrid labcolor(red) tlcolor(red) axis(2)) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_y_both, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_y_both.pdf", replace
tw ///
	(connected ipca_inflation_y date_num if inrange(year, ${year_min_plot}, ${year_max_plot} - 1), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") legend(off) xtitle("") ytitle("Year-on-year inflation rate (%), ${year_min_plot}-${year_max_plot}", size(${text_size})) yscale(log) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(1 "1" 10 "10" 100 "100" 1000 "1,000" 10000 "10,000", labsize(${text_size}) format(%4.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(ipca_inflation_y_both_log, replace)
graph export "${BACKGROUND_DIR}/ipca_inflation_y_both_log.pdf", replace


*** nominal and real minimum wage from IPEA
* load minimum wage data (http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=1739471028 and http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=37667)
import excel using ///
	"${ROOT_DIR}/5_inputs/ipeadata(28-01-2021-10-04)_mw.xls" ///
	, firstrow case(lower) clear

* rename and label
rename minimumwagerministériod mw_nominal
label var mw_nominal "Nominal minimum wage (current BRL)"
rename realminimumwagerdoúltimo mw_real
label var mw_real "Real minimum wage (constant Dec. 2020 BRL)"
gen float defl = mw_real/mw_nominal
sum defl if year == 2018 & month == 12, meanonly
replace mw_real = mw_real/r(mean)
label var mw_real "Real minimum wage (constant Dec. 2018 BRL)"

* create date variable in Stata date format
gen int date = ym(year,month)
format date %tm
label var date "Date (year-month combination)"

* create numeric date variable
gen float date_num = year + (month - 1)/12
label var date_num "Date (numeric)"

* plots
tw ///
	(connected mw_nominal date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Nominal minimum wage (current BRL)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(200)1000, labsize(${text_size}) format(%4.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(mw_nominal, replace)
graph export "${BACKGROUND_DIR}/mw_nominal.pdf", replace
tw ///
	(connected mw_real date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Real minimum wage (constant Dec. 2018 BRL)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(200)1000, labsize(${text_size}) format(%5.0fc) angle(0) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) /// 0 "0" 200 "200" 400 "400" 600 "600" 800 "800" 1000 "1,000"
	name(mw_real, replace)
graph export "${BACKGROUND_DIR}/mw_real.pdf", replace


*** nominal exchange rate from FRED
* load nominal exchange rate data (https://fred.stlouisfed.org/series/CCUSSP02BRM650N)
import excel using ///
	"${ROOT_DIR}/5_inputs/FRED_fx_processed.xls" ///
	, firstrow case(lower) clear

* label
label var year "Year"
label var month "Month"
label var fx "Nominal exchange rate (current BRL/USD)"

* create date variable in Stata date format
gen int date = ym(year,month)
format date %tm
label var date "Date (year-month combination)"

* create numeric date variable
gen float date_num = year + (month - 1)/12
label var date_num "Date (numeric)"

* plots
tw ///
	(connected fx date_num if inrange(year, ${year_min_plot}, ${year_max_plot}), lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Nominal exchange rate (current BRL/USD)", size(${text_size})) xlabel(${year_min_plot_adj}(5)${year_max_plot_adj}, labsize(${text_size}) grid gstyle(dot) gmin gmax) ylabel(0(1)5, labsize(${text_size}) format(%1.0f) grid gstyle(dot) gmin gmax) graphregion(color(white)) plotregion(lcolor(black) margin(l=${l_val} r=${r_val} b=${b_val} t=${t_val})) ///
	name(fx, replace)
graph export "${BACKGROUND_DIR}/fx.pdf", replace


cap log close

// END OF FILE
