********************************************************************************
********************************************************************************
********************************************************************************
/*
	Project: The impact of COVID-19 on the foundation and dissolution of charitable organisations
	
	Website: https://diarmuidm.github.io/charity-covid-19/
	
	Creator: Diarmuid McDonnell
	
	Collaborators: Alasdair Rutherford
	
	Date: 2020-06-19
	
	File: char-org-demography-cleaning-2020-12-03.do
	
	Description: This file processes publicly available and other charity data to produce
				 organisation demography statistics.
*/


/** 0. Preliminaries **/

** Diarmuid **

global dfiles "C:\Users\t95171dm\Dropbox" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\t95171dm\projects\charity-covid19\docs" // location of graphs

include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Data Cleaning **/
/*
	Take the masterfile of charities provided by DC and produce yearly statistics a la the ONS'
	Business Demography statistics.
*/

/* Masterfile of registered/de-registered charities */

use $path2\CCdata_Sept2020.dta, clear // DC reserves paper version
desc, f
count

	** Keep relevant variables **
	
	rename cceid regno
	duplicates drop regno, force
	
	keep regno isreg reg_year diss_year reg_date diss_date region
	gen reg = (isreg=="R")
	gen dereg = (isreg=="RM")
	gen freq = 1
	
	
	** Create summary datasets **
	
	// Births
	
	preserve
		collapse (count) freq, by(reg_year)
		sort reg_year
		rename freq births
		rename reg_year year
		sav $path1\chardemo-registrations.dta, replace
	restore
	
	// Deaths
	
	preserve
		collapse (count) freq, by(diss_year)
		sort diss_year
		rename freq deaths
		rename diss_year year
		sav $path1\chardemo-deregistrations.dta, replace
	restore
	
	// Survival 
	
	gen orgage = cond(diss_year==., 2020 - reg_year, diss_year - reg_year)
	forvalues i = 1/60 {
		gen survived_`i' = (orgage>=`i' & orgage!=.)
	}
	
		l regno reg_year diss_year survived_5 if reg_year==2012
		/*
			The above code looks to have worked.
		*/
	
	preserve
		collapse (sum) survived*, by(reg_year)
		sort reg_year
		rename reg_year year
		sav $path1\chardemo-survivals.dta, replace
	restore
	
	
	** Merge summary datasets **
	
	use $path1\chardemo-registrations.dta, clear
	merge 1:1 year using $path1\chardemo-deregistrations.dta, keep(match master)
	drop _merge
	merge 1:1 year using $path1\chardemo-survivals.dta, keep(match master)
	drop _merge
	
	
	** Create derived variables **
	
	// Population
	
	gen constant = 1
	gen net_births = births - deaths
	bysort constant (year) : gen population = sum(net_births)
	
	
	// Churn
	/*
		births + deaths / population[_n-1]
	*/
	
	gen churn = (births + deaths) / population[_n-1]
	
	
	// Survival rate
	
	forvalues i = 1/60 {
		gen survived_`i'_rate = (survived_`i' / births)
	}
	
	
	** Final tasks **
	
	drop if year==.
	drop constant
	


************************************************************************************************************


************************************************************************************************************
	
	
/** Empty working data folder **/
	

pwd

local workdir $path1
cd `workdir'

local datafiles: dir "`workdir'" files "*.dta"

foreach datafile of local datafiles {
	rm `datafile'
}
