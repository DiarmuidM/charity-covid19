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
	
	Description: This file analyses publicly available and other charity data to produce
				 organisation demography statistics.
*/


/** 0. Preliminaries **/

** Diarmuid **

global dfiles "C:\Users\mcdonndz-local\Dropbox" // location of data files
global rfiles "C:\Users\mcdonndz-local\Dropbox\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\mcdonndz-local\Dropbox\projects\charity-covid19\docs" // location of graphs

include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Sample description **/

use $path3\chardemo-statistics.dta, clear
count
desc, f
drop if year < 2000 | year > 2020

	
	** Birth and death rates
	
	twoway (line death_rate_alt year , lpatt(solid)) ///
		, title("Dissolution Rate of England and Wales Charities") subtitle("") xtitle("Year") ytitle("%") ///
		caption("Dissolution rate = de-registrations / non-zero annual return filers [_n-1]", size(small))
		
	twoway (line birth_rate_alt year , lpatt(solid)) ///
		, title("Formation Rate of England and Wales Charities") subtitle("") xtitle("Year") ytitle("%") ///
		caption("Formation rate = registrations / non-zero annual return filers [_n-1]", size(small))
	/*
		Common y scale, same graph etc, average as y line etc.
	*/
	
		// By covariates
		
		use $path3\chardemo-statistics-period.dta, clear
		drop if year < 2000 | year > 2020

		lgraph death_rate_alt year period ///
			, title("Dissolution Rate of England and Wales Charities") subtitle("By foundation period") xtitle("Year") ytitle("%") ///
			caption("Dissolution rate = de-registrations / non-zero annual return filers [_n-1]", size(small))
		
		use $path3\chardemo-statistics-orgsize.dta, clear
		drop if year < 2000 | year > 2020

		lgraph death_rate_alt year orgsize ///
			, title("Dissolution Rate of England and Wales Charities") subtitle("By organisation size") xtitle("Year") ytitle("%") ///
			caption("Dissolution rate = de-registrations / non-zero annual return filers [_n-1]", size(small))

		
		use $path3\chardemo-statistics-icnpo.dta, clear
		drop if year < 2000 | year > 2020

		twoway (line death_rate_alt year if icnpo=="Culture and recreation", lpatt(solid)) ///
			(line death_rate_alt year if icnpo=="Health", lpatt(longdash)) ///
			(line death_rate_alt year if icnpo=="Social Services", lpatt(shortdash)) ///
			, title("Dissolution Rate of England and Wales Charities") subtitle("By field of activity") xtitle("Year") ytitle("%") ///
			legend(label(1 "Culture and recreation") label(2 "Health") label(3 "Social services") rows(1) position(6) size(small)) ///
			caption("Dissolution rate = de-registrations / non-zero annual return filers [_n-1]", size(small))
			
		use $path3\chardemo-statistics-region.dta, clear
		drop if year < 2000 | year > 2020

		lgraph death_rate_alt year region if region < 10 ///
			, title("Dissolution Rate of England and Wales Charities") subtitle("By region") xtitle("Year") ytitle("%") ///
			caption("Dissolution rate = de-registrations / non-zero annual return filers [_n-1]", size(small))

		
		
	** Churn rate
	
	line churn year if churn!=. & year > 1994 ///
		, lpatt(solid) ///
		xtitle("Year") ytitle("%") ///
		scheme(s1mono)
		
	** High growth organisations and rate
	
	line hg_rate year if hg_rate!=. & year > 1999 ///
		, lpatt(solid) ///
		xtitle("Year") ytitle("%") ///
		ylab(0(5)30, labsize(small)) ///
		scheme(s1mono)
	
	
	
	********
		** See VSSN paper from Leverhulme project for some graphs and inspiration. 
	********
	
	
