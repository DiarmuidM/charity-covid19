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

global dfiles "C:\Users\t95171dm\Dropbox" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\t95171dm\projects\charity-covid19\docs" // location of graphs

include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Sample description **/

use $path3\chardemo-statistics.dta, clear
count
desc, f

	
	** Birth and death rates
	
	twoway (line birth_rate year if year > 1994. , lpatt(solid)) (line death_rate year if year > 1994, lpatt(longdash)) ///
		, xtitle("Year") ytitle("%") ///
		scheme(s1mono)
		
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
	
	
