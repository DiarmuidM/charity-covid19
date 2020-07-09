********************************************************************************
********************************************************************************
********************************************************************************
/*
	Project: The impact of COVID-19 on the foundation and dissolution of charitable organisations
	
	Website: https://diarmuidm.github.io/charity-covid-19/
	
	Creator: Diarmuid McDonnell
	
	Collaborators: Alasdair Rutherford
	
	Date: 2020-06-19
	
	File: char-excess-events-cleaning-2020-06-19.do
	
	Description: This file processes publicly available charity data to produce
				 data sets suitable for statistical analysis.
				 
				 See 'FILE_NAME' for the data collection code.
*/


/** 0. Preliminaries **/

** Diarmuid **

global dfiles "C:\Users\t95171dm\Dropbox" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-covid19" // location of syntax and outputs

include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Data Cleaning **/
/*
	For each jurisdiction:
		1.1. Import data sets
		1.2. Convert to time series of monthly statistics
		1.3. Save data for analysis
*/

** USA **

	** Registrations

	import delimited using $path2\irs_businessfiles_07Jun2020.csv, varn(1) clear
	keep ein subsection affiliation classification ruling deductibility activity organization status ntee_cd
	codebook, compact
	/*
		I want to exclude organisations that are not 501(c)(3) orgs.
	*/
	keep if subsection==3


	// Convert to date
	/*
		The assumption is the values of 'ruling' are formatted as follows:
			- 200606 = 2006-JUNE
	*/
	
	tostring ruling, gen(regd_str)
	gen regd = date(regd_str, "YM") 
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm month_reg
	
	
	// Calculate monthly figures
	
	keep if regm >= tm(2015m1) // interested in five-year average
	gen reg = 1
	egen reg_count = sum(reg), by(regm)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub
		sav "$path1\us-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg using "$path1\us-monthly-averages.dta", keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop ein-ntee_cd _merge
	duplicates drop regm, force
	drop if regm==.
	l
		
	
	// Calculate excess events
	
	sort regm
	gen reg_excess = ceil(reg_count - reg_avg)
	gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
	gen reg_excess_cumu = sum(reg_excess)
	gen reg_avg_cumu = sum(reg_avg)
	gen reg_count_cumu = sum(reg_count)
	gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
	
	gen period = regm
	sort period
	format period %tm
	sav "$path1\us-monthly-registrations.dta", replace


	** Revocations

	import delimited using $path2\irs_revoked_exemp_orgs_20Jun2020.csv, varn(1) clear
	keep ein exemption_type revocation_date revocation_posting_date exemption_reinstatement_date
	codebook, compact
	/*
		Interestingly, some nonprofits have had their status reinstated - exclude these from analysis.
		
		I also want to exclude organisations that are not 501(c)(3) orgs.
	*/
	drop if exemption_reinstatement_date!=""
	keep if exemption_type==3 // assuming 3 refers to 501(c)(3)
	

	// Convert to date
	
	gen remd = date(revocation_date, "DMY")
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen month_rem = month(dofm(remm))
	format remq %tq
	format remm %tm
	tab1 remq remm month_rem
	
	
	// Calculate monthly figures
	
	keep if remm >= tm(2015m1) // interested in five-year average
	gen rem = 1
	egen rem_count = sum(rem), by(remm)
	egen rem_avg  = mean(rem_count) if remm < tm(2020m1), by(month_rem)
	egen rem_sd = sd(rem_count) if remm < tm(2020m1), by(month_rem)
	gen rem_lb = rem_avg - rem_sd
	gen rem_ub = rem_avg + rem_sd
	foreach var of varlist rem_count-rem_ub {
		replace `var' = ceil(`var')
	}
	/*
		Try other averages e.g., over three preceding years.
	*/
	
	
	// Convert to time series
	
	preserve
		sort month_rem
		keep if rem_avg!=.
		duplicates drop month_rem, force
		keep month_rem rem_avg-rem_ub
		sav "$path1\us-monthly-removals-averages.dta", replace
	restore
	
	sort month_rem
	drop rem_avg-rem_ub
	merge m:1 month_rem using "$path1\us-monthly-removals-averages.dta", keep(match) keepus(rem_avg-rem_ub)
	keep if remm >= tm(2020m1)
	drop ein-exemption_reinstatement_date _merge
	duplicates drop remm, force
	drop if remm==.
	l
		
	
	// Calculate excess events
	
	sort remm
	gen rem_excess = ceil(rem_count - rem_avg)
	gen rem_excess_per = ceil((rem_excess/rem_avg)*100)
	gen rem_excess_cumu = sum(rem_excess)
	gen rem_avg_cumu = sum(rem_avg)
	gen rem_count_cumu = sum(rem_count)
	gen rem_excess_cumu_per = ceil((rem_excess_cumu/rem_avg_cumu)*100)
	
	gen period = remm
	sort period
	format period %tm
	sav "$path1\us-monthly-removals.dta", replace
	
	
	// Create analysis file
	
	use "$path1\us-monthly-registrations.dta", clear
	merge 1:1 period using "$path1\us-monthly-removals.dta", keep(match master)
	drop _merge
	gen country = "USA"
	sav "$path3\us-monthly-statistics.dta", replace

	
************************************************************************************************************


************************************************************************************************************


** Canada **

	** Registrations

	import delimited using $path2\can-all-data-2020-07.txt, varn(1) clear
	keep bnregistrationnumber effectivedateofstatus charitystatus
	/*
		An issue with Canadian data is we only observe status date for current status: for example, we don't know when revoked charities
		were registered, as the date field is populated by their revoked status date.
	*/
	
	keep if charitystatus=="Registered"

	// Convert to date
	
	gen regd = date(effectivedateofstatus, "YMD") 
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm month_reg
	
	
	// Calculate monthly figures
	
	keep if regm >= tm(2015m1) // interested in five-year average
	gen reg = 1
	egen reg_count = sum(reg), by(regm)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub
		sav "$path1\can-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg using "$path1\can-monthly-averages.dta", keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop bnregistrationnumber effectivedateofstatus _merge
	duplicates drop regm, force
	drop if regm==.
	l
		
	
	// Calculate excess events
	
	sort regm
	gen reg_excess = ceil(reg_count - reg_avg)
	gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
	gen reg_excess_cumu = sum(reg_excess)
	gen reg_avg_cumu = sum(reg_avg)
	gen reg_count_cumu = sum(reg_count)
	gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
	
	gen period = regm
	sort period
	format period %tm
	sav "$path1\can-monthly-registrations.dta", replace
	
	
	** Revocations

	import delimited using $path2\can-all-data-2020-07.txt, varn(1) clear
	keep bnregistrationnumber effectivedateofstatus charitystatus
	/*
		An issue with Canadian data is we only observe status date for current status: for example, we don't know when revoked charities
		were registered, as the date field is populated by their revoked status date.
	*/
	
	keep if charitystatus!="Registered"
	
	// Convert to date
	
	gen remd = date(effectivedateofstatus, "YMD") if charitystatus!="Registered"
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen month_rem = month(dofm(remm))
	format remq %tq
	format remm %tm
	tab1 remq remm month_rem
	
	
	// Calculate monthly figures
	
	keep if remm >= tm(2015m1) // interested in five-year average
	gen rem = 1
	egen rem_count = sum(rem), by(remm)
	egen rem_avg  = mean(rem_count) if remm < tm(2020m1), by(month_rem)
	egen rem_sd = sd(rem_count) if remm < tm(2020m1), by(month_rem)
	gen rem_lb = rem_avg - rem_sd
	gen rem_ub = rem_avg + rem_sd
	foreach var of varlist rem_count-rem_ub {
		replace `var' = ceil(`var')
	}
	/*
		Try other averages e.g., over three preceding years.
	*/
	
	
	// Convert to time series
	
	preserve
		sort month_rem
		keep if rem_avg!=.
		duplicates drop month_rem, force
		keep month_rem rem_avg-rem_ub
		sav "$path1\can-monthly-removals-averages.dta", replace
	restore
	
	sort month_rem
	drop rem_avg-rem_ub
	merge m:1 month_rem using "$path1\can-monthly-removals-averages.dta", keep(match) keepus(rem_avg-rem_ub)
	keep if remm >= tm(2020m1)
	drop bnregistrationnumber effectivedateofstatus _merge
	duplicates drop remm, force
	drop if remm==.
	l
		
	
	// Calculate excess events
	
	sort remm
	gen rem_excess = ceil(rem_count - rem_avg)
	gen rem_excess_per = ceil((rem_excess/rem_avg)*100)
	gen rem_excess_cumu = sum(rem_excess)
	gen rem_avg_cumu = sum(rem_avg)
	gen rem_count_cumu = sum(rem_count)
	gen rem_excess_cumu_per = ceil((rem_excess_cumu/rem_avg_cumu)*100)
	
	gen period = remm
	sort period
	format period %tm
	sav "$path1\can-monthly-removals.dta", replace
	
	
	// Create analysis file
	
	use "$path1\can-monthly-registrations.dta", clear
	merge 1:1 period using "$path1\can-monthly-removals.dta", keep(match master)
	drop _merge
	gen country = "Canada"
	sav "$path3\can-monthly-statistics.dta", replace

		
************************************************************************************************************


************************************************************************************************************


** New Zealand (CSNZ) */

** Create master file

import delimited using $path2\nz-removals-2020-06.txt, varn(1) clear
gen remdata = 1
sav $path1\nz-removals-2020-06.dta, replace

import delimited using $path2\nz-roc-2020-06.txt, varn(1) clear
gen regdata = 1
sav $path1\nz-roc-2020-06.dta, replace

append using $path1\nz-removals-2020-06.dta, force
keep charityregistrationnumber deregistrationdate dateregistered *data
gen removed = (remdata)
sav $path1\nz-all-data-2020-06.dta, replace


** De-registrations

use $path1\nz-all-data-2020-06.dta, clear
keep if removed==1

	// Convert to date
	
	gen remd = date(deregistrationdate, "DMY")
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen month_rem = month(dofm(remm))
	format remq %tq
	format remm %tm
	tab1 remq remm month_rem
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if remm >= tm(2015m1) // interested in five-year average
	gen rem = 1
	egen rem_count = sum(rem), by(remm)
	egen rem_avg  = mean(rem_count) if remm < tm(2020m1), by(month_rem)
	egen rem_sd = sd(rem_count) if remm < tm(2020m1), by(month_rem)
	gen rem_lb = rem_avg - rem_sd
	gen rem_ub = rem_avg + rem_sd
	foreach var of varlist rem_count-rem_ub {
		replace `var' = ceil(`var')
	}
	/*
		Try other averages e.g., over three preceding years.
	*/
	
	
	// Convert to time series
	
	preserve
		sort month_rem
		keep if rem_avg!=.
		duplicates drop month_rem, force
		keep month_rem rem_avg-rem_ub
		sav "$path1\csnz-monthly-removals-averages.dta", replace
	restore
	
	sort month_rem
	drop rem_avg-rem_ub
	merge m:1 month_rem using "$path1\csnz-monthly-removals-averages.dta", keep(match) keepus(rem_avg-rem_ub)
	keep if remm >= tm(2020m1)
	drop charityregistrationnumber deregistrationdate _merge
	duplicates drop remm, force
	drop if remm==.
	l
		
	
	// Calculate excess events
	
	sort remm
	gen rem_excess = ceil(rem_count - rem_avg)
	gen rem_excess_per = ceil((rem_excess/rem_avg)*100)
	gen rem_excess_cumu = sum(rem_excess)
	gen rem_avg_cumu = sum(rem_avg)
	gen rem_count_cumu = sum(rem_count)
	gen rem_excess_cumu_per = ceil((rem_excess_cumu/rem_avg_cumu)*100)
	
	gen period = remm
	sort period
	format period %tm
	sav "$path1\nz-monthly-removals.dta", replace

		
	** Registrations

	use $path1\nz-all-data-2020-06.dta, clear

	// Convert to date
	
	gen regd = date(dateregistered, "DMY")
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm month_reg
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if regm >= tm(2015m1) // interested in five-year average
	gen reg = 1
	egen reg_count = sum(reg), by(regm)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub
		sav "$path1\csnz-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg using "$path1\csnz-monthly-averages.dta", keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop charityregistrationnumber dateregistered _merge
	duplicates drop regm, force
	drop if regm==.
	l
		
	
	// Calculate excess events
	
	sort regm
	gen reg_excess = ceil(reg_count - reg_avg)
	gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
	gen reg_excess_cumu = sum(reg_excess)
	gen reg_avg_cumu = sum(reg_avg)
	gen reg_count_cumu = sum(reg_count)
	gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)

	gen period = regm
	sort period
	format period %tm
	sav "$path1\nz-monthly-registrations.dta", replace
	
	
	// Create analysis file
	
	use "$path1\nz-monthly-registrations.dta", clear
	merge 1:1 period using "$path1\nz-monthly-removals.dta", keep(match)
	drop _merge
	gen country = "New Zealand"
	sav "$path3\nz-monthly-statistics.dta", replace

	
************************************************************************************************************


************************************************************************************************************


** Australia (ACNC) **
/*
	Some serious discrepencies between Register of Charities and the list of newly registered charities listed
	here: https://www.acnc.gov.au/charity/charity/recently-registered-charities
	
	For example, the following charities were claimed to be registered in June 2020 but appear under different dates
	in the Register:
		- l if ABN=="11407494755" [May 2020]
		- l if ABN=="11527622696" [2012]
		- l if ABN=="35276763984" [2019]
*/

	import excel using $path2\aus-roc-2020-07.xlsx, firstrow clear
	keep ABN Registration_Date Date_Organisation_Established Charity_Legal_Name

	// Convert to date
	
	gen regd = date(Registration_Date, "DMY")
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm month_reg
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if regm >= tm(2015m1) // interested in five-year average
	gen reg = 1
	egen reg_count = sum(reg), by(regm)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub
		sav "$path1\aus-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg using "$path1\aus-monthly-averages.dta", keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop ABN Registration_Date _merge
	duplicates drop regm, force
	drop if regm==.
	l
		
	
	// Calculate excess events
	
	sort regm
	gen reg_excess = ceil(reg_count - reg_avg)
	gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
	gen reg_excess_cumu = sum(reg_excess)
	gen reg_avg_cumu = sum(reg_avg)
	gen reg_count_cumu = sum(reg_count)
	gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
	
	gen period = regm
	sort period
	format period %tm
	gen country = "Australia"
	sav "$path3\aus-monthly-statistics.dta", replace

		
************************************************************************************************************


************************************************************************************************************


** Northern Ireland **

**use C:\Users\t95171dm\Dropbox\brawdata\clients\oscr\data_clean\ocsr_scr_20190227_clean.dta, clear

	** Registrations
	
	import delimited using $path2\ni-roc-2020-07-09.csv, varn(1) clear
	keep regcharitynumber dateregistered status
	tab status
	keep if status!="Removed"
	desc, f

	// Convert to date
	
	gen regd = date(dateregistered, "DMY")
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm month_reg
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if regm >= tm(2015m1) // interested in five-year average
	gen reg = 1
	egen reg_count = sum(reg), by(regm)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub
		sav "$path1\ni-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg using "$path1\ni-monthly-averages.dta", keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop regcharitynumber dateregistered status _merge
	duplicates drop regm, force
	drop if regm==.
	l
		
	
	// Calculate excess events
	
	sort regm
	gen reg_excess = ceil(reg_count - reg_avg)
	gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
	gen reg_excess_cumu = sum(reg_excess)
	gen reg_avg_cumu = sum(reg_avg)
	gen reg_count_cumu = sum(reg_count)
	gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
	
	gen period = regm
	sort period
	format period %tm
	sav "$path1\ni-monthly-registrations.dta", replace
	
	
	** Removals
		
	import delimited using $path2\ni-removals-2020-07-09.csv, varn(1) clear
	keep if removed==1
	desc, f

	// Convert to date
	
	gen remd = date(removed_date, "YMD")
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen month_rem = month(dofm(remm))
	format remq %tq
	format remm %tm
	tab1 remq remm month_rem
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if remm >= tm(2015m1) // interested in five-year average
	gen rem = 1
	egen rem_count = sum(rem), by(remm)
	egen rem_avg  = mean(rem_count) if remm < tm(2020m1), by(month_rem)
	egen rem_sd = sd(rem_count) if remm < tm(2020m1), by(month_rem)
	gen rem_lb = rem_avg - rem_sd
	gen rem_ub = rem_avg + rem_sd
	foreach var of varlist rem_count-rem_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_rem
		keep if rem_avg!=.
		duplicates drop month_rem, force
		keep month_rem rem_avg-rem_ub
		sav "$path1\ni-monthly-removals-averages.dta", replace
	restore
	
	sort month_rem
	drop rem_avg-rem_ub
	merge m:1 month_rem using "$path1\ni-monthly-removals-averages.dta", keep(match) keepus(rem_avg-rem_ub)
	keep if remm >= tm(2020m1)
	drop regid removed removed_date _merge
	duplicates drop remm, force
	drop if remm==.
	l
		
	
	// Calculate excess events
	
	sort remm
	gen rem_excess = ceil(rem_count - rem_avg)
	gen rem_excess_per = ceil((rem_excess/rem_avg)*100)
	gen rem_excess_cumu = sum(rem_excess)
	gen rem_avg_cumu = sum(rem_avg)
	gen rem_count_cumu = sum(rem_count)
	gen rem_excess_cumu_per = ceil((rem_excess_cumu/rem_avg_cumu)*100)
	
	gen period = remm
	sort period
	format period %tm
	sav "$path1\ni-monthly-removals.dta", replace
	
	
	// Create analysis file
	
	use "$path1\ni-monthly-registrations.dta", clear
	merge 1:1 period using "$path1\ni-monthly-removals.dta", keep(match)
	drop _merge
	gen country = "Northern Ireland"
	sav "$path3\ni-monthly-statistics.dta", replace

	
************************************************************************************************************


************************************************************************************************************


** England and Wales **

import delimited using $path2\extract_registration.csv, varn(1) clear
keep regno regdate remdate
duplicates drop regno, force
sort regno
desc, f
sav $path1\ccew-reg-dates.csv, replace


import delimited using $path2\extract_charity.csv, varn(1) clear
keep regno
sort regno
replace regno = "" if missing(real(regno)) // Set nonnumeric instances of regno as missing
destring regno, replace
duplicates drop regno, force
desc, f

	// Merge date information
	
	merge 1:1 regno using $path1\ccew-reg-dates.csv, keep(match)
	drop _merge
	

	// Convert to date
	
	gen regd_str = substr(regdate, 1, 10)
	gen regd = date(regd_str, "YMD")
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm
	
	
	gen remd_str = substr(remdate, 1, 10)
	gen remd = date(remd_str, "YMD")
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen month_rem = month(dofm(remm))
	format remq %tq
	format remm %tm
	tab1 remq remm


	// Calculate monthly figures
	
	preserve
		keep if regm >= tm(2015m1) // interested in five-year average
		gen freq = 1
		egen reg_count = sum(freq), by(regm)
		egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
		egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
		gen reg_lb = reg_avg - reg_sd
		gen reg_ub = reg_avg + reg_sd
		foreach var of varlist reg_count-reg_ub {
			replace `var' = ceil(`var')
		}
		gen mdate = regm
		sort mdate
		duplicates drop mdate, force
		sav $path1\ccew-reg.dta, replace
	restore
	/*
		What's going on with February standard deviation? Looks correct actually.
	*/
	
	preserve
		keep if remm >= tm(2015m1) // interested in five-year average
		gen freq = 1
		egen rem_count = sum(freq), by(remm)
		egen rem_avg  = mean(rem_count) if remm < tm(2020m1), by(month_rem)
		egen rem_sd = sd(rem_count) if remm < tm(2020m1), by(month_rem)
		gen rem_lb = rem_avg - rem_sd
		gen rem_ub = rem_avg + rem_sd
		foreach var of varlist rem_count-rem_ub {
			replace `var' = ceil(`var')
		}
		gen mdate = remm
		sort mdate
		duplicates drop mdate, force
		sav $path1\ccew-rem.dta, replace
	restore

	use $path1\ccew-reg.dta, clear
	merge 1:1 mdate using $path1\ccew-rem.dta, keep(match) keepus(rem_*)
	drop _merge
	l
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub rem_avg-rem_ub
		sav "$path1\ccew-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub rem_avg-rem_ub
	merge m:1 month_reg using "$path1\ccew-monthly-averages.dta", keep(match)
	drop _merge
		
	keep if regm >= tm(2020m1)
	capture drop regno regd_str regdate remdate mdate month* _merge
	capture duplicates drop regm, force
	drop if regm==.
	l

	
	// Calculate excess events
	
	sort regm
	foreach var in reg rem {
		gen `var'_excess = ceil(`var'_count - `var'_avg)
		gen `var'_excess_per = ceil((`var'_excess/`var'_avg)*100)
		gen `var'_excess_cumu = sum(`var'_excess)
		gen `var'_avg_cumu = sum(`var'_avg)
		gen `var'_count_cumu = sum(`var'_count)
		gen `var'_excess_cumu_per = ceil((`var'_excess_cumu/`var'_avg_cumu)*100)
	}
	
	
	// Create analysis file
	
	gen period = regm
	format period %tm
	sort period
	gen country = "England and Wales"
	sav "$path3\ew-monthly-statistics.dta", replace



***************************************************************************************************************

***************************************************************************************************************


** Scotland **

** Create master file

import delimited using $path2\CharityExport-09-Jul-2020.csv, varn(1) clear
gen regdata = 1
sav $path1\scot-roc-2020-07.dta, replace

import delimited using $path2\CharityExport-Removed-09-Jul-2020.csv, varn(1) clear
gen remdata = 1
sav $path1\scot-removals-2020-07.dta, replace

append using $path1\scot-roc-2020-07.dta, force
*keep charityregistrationnumber deregistrationdate dateregistered *data
gen removed = (remdata)
sav $path1\scot-all-data-2020-07.dta, replace


** De-registrations

use $path1\scot-all-data-2020-07.dta, clear
keep if removed==1

	// Convert to date
	
	gen remd_str = substr(ceaseddate, 1, 10)
	gen remd = date(remd_str, "DMY")
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen month_rem = month(dofm(remm))
	format remq %tq
	format remm %tm
	tab1 remq remm month_rem
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if remm >= tm(2015m1) // interested in five-year average
	gen rem = 1
	egen rem_count = sum(rem), by(remm)
	egen rem_avg  = mean(rem_count) if remm < tm(2020m1), by(month_rem)
	egen rem_sd = sd(rem_count) if remm < tm(2020m1), by(month_rem)
	gen rem_lb = rem_avg - rem_sd
	gen rem_ub = rem_avg + rem_sd
	foreach var of varlist rem_count-rem_ub {
		replace `var' = ceil(`var')
	}
	/*
		Try other averages e.g., over three preceding years.
	*/
	
	
	// Convert to time series
	
	preserve
		sort month_rem
		keep if rem_avg!=.
		duplicates drop month_rem, force
		keep month_rem rem_avg-rem_ub
		sav "$path1\scot-monthly-removals-averages.dta", replace
	restore
	
	sort month_rem
	drop rem_avg-rem_ub
	merge m:1 month_rem using "$path1\scot-monthly-removals-averages.dta", keep(match) keepus(rem_avg-rem_ub)
	keep if remm >= tm(2020m1)
	drop charitynumber-regulatorytype _merge
	duplicates drop remm, force
	drop if remm==.
	l
		
	
	// Calculate excess events
	
	sort remm
	gen rem_excess = ceil(rem_count - rem_avg)
	gen rem_excess_per = ceil((rem_excess/rem_avg)*100)
	gen rem_excess_cumu = sum(rem_excess)
	gen rem_avg_cumu = sum(rem_avg)
	gen rem_count_cumu = sum(rem_count)
	gen rem_excess_cumu_per = ceil((rem_excess_cumu/rem_avg_cumu)*100)
	
	gen period = remm
	sort period
	format period %tm
	sav "$path1\scot-monthly-removals.dta", replace

	
** Registrations

use $path1\scot-all-data-2020-07.dta, clear

	// Convert to date
	
	gen regd_str = substr(registereddate, 1, 10)
	gen regd = date(regd_str, "DMY")
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen month_reg = month(dofm(regm))
	format regq %tq
	format regm %tm
	tab1 regq regm month_reg
	/*
		Consider monthly or bimonthly measures also
	*/

	
	// Calculate monthly figures
	
	keep if regm >= tm(2015m1) // interested in five-year average
	gen reg = 1
	egen reg_count = sum(reg), by(regm)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
	
	
	// Convert to time series
	
	preserve
		sort month_reg
		keep if reg_avg!=.
		duplicates drop month_reg, force
		keep month_reg reg_avg-reg_ub
		sav "$path1\scot-monthly-averages.dta", replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg using "$path1\scot-monthly-averages.dta", keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop charitynumber-regulatorytype _merge
	duplicates drop regm, force
	drop if regm==.
	l
		
	
	// Calculate excess events
	
	sort regm
	gen reg_excess = ceil(reg_count - reg_avg)
	gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
	gen reg_excess_cumu = sum(reg_excess)
	gen reg_avg_cumu = sum(reg_avg)
	gen reg_count_cumu = sum(reg_count)
	gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
	
	gen period = regm
	sort period
	format period %tm
	sav "$path1\scot-monthly-registrations.dta", replace
	
	
	// Create analysis file
	
	use "$path1\scot-monthly-registrations.dta", clear
	merge 1:1 period using "$path1\scot-monthly-removals.dta", keep(match)
	drop _merge
	gen country = "Scotland"
	sav "$path3\scot-monthly-statistics.dta", replace


		
************************************************************************************************************


************************************************************************************************************

	
/* Create master analysis file */

clear
local cleandir $path3
cd `cleandir'

local datafiles: dir "`cleandir'" files "*.dta"

foreach datafile of local datafiles {
	append using `datafile', force
}

desc, f

	** Final data management **
	
	sort country period
	
	** Drop and label variables
	
	drop month_reg charitystatus month_rem regno regdate remdate regd_str remd_str freq mdate ///
		deregistrationdate regdata remdata removed dateregistered notes
	
	
compress
sav $path3\all-jurisdictions-monthly-statistics.dta, replace


************************************************************************************************************


************************************************************************************************************
	
/** Create CSV versions of each data set **//

local cleandir $path3
cd `cleandir'

local datafiles: dir "`workdir'" files "*.dta"

foreach datafile of local datafiles {
	use `datafile', clear
	sort period
	order country, first
	order period, after(country)
	keep period country *_avg* *_count* *_excess*
	
	export delimited using `datafile'.csv, replace
}
	
	
/** Empty working data folder **/
	

pwd

local workdir $path1
cd `workdir'

local datafiles: dir "`workdir'" files "*.dta"

foreach datafile of local datafiles {
	rm `datafile'
}
