********************************************************************************
* DESCRIPTION: Initializes program by creating global macros.
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


* settings
grstyle init
grstyle set plain, horizontal grid dotted

* tools
global gtools = "g" // "" = use Stata-native commands, "g" = use -gtools- package

* selection criteria when creating raw panel
global use_conds_pme = "stratid < . & psu < . & inrange(age,25,55)"
global earnings_pme = "vI4182" // v4182 = usual gross income (== . if not domestic/employee); vI4182 = imputed usual gross income
global earnings_pme_others = "vI4231" // v4231 = usual gross income from main job (== . if domestic/employee); vI4231 = imputed usual gross income from main job; 

* years to loop over
global years_pme = "2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015"
global yrfirst = "2002"
global yrlast = "2015"
