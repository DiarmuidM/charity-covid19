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
global rfiles "C:\Users\t95171dm\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\t95171dm\projects\charity-covid19\docs" // location of graphs
global foldate "2020-09-17" // name of folder containing latest data
global fdate "2020-09-17" // date used to name output files

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
	
	import delimited using $path2\$foldate\usa\irs_businessfile_master_$fdate.csv, varn(1) clear
	keep ein subsection affiliation classification ruling deductibility activity organization status ntee_cd
	*codebook, compact
	/*
		I want to exclude organisations that are not 501(c)(3) orgs.
	*/
	keep if subsection=="03"

	
	// Convert to date
	/*
		The assumption is the values of 'ruling' are formatted as follows:
			- 200606 = 2006-JUNE
	*/
	
	gen regd = date(ruling, "YM") 
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
		sav $path1\us-monthly-averages.dta, replace
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
	sav $path1\us-monthly-registrations-$fdate.dta, replace
	
	
	** Registrations, by NTEE
	
	import delimited using $path2\$foldate\usa\irs_businessfile_master_$fdate.csv, varn(1) clear
	keep ein subsection affiliation classification ruling deductibility activity organization status ntee_cd
	codebook, compact
	/*
		I want to exclude organisations that are not 501(c)(3) orgs.
	*/
	keep if subsection=="03"
	
	
	// Clean NTEE Code variable
	/*
		Apply groupings a la "https://nccs.urban.org/project/national-taxonomy-exempt-entities-ntee-codes"
	*/

	gen ntee_maj = .
	replace ntee_maj = 1 if strpos(ntee_cd, "A")
	replace ntee_maj = 2 if strpos(ntee_cd, "B") 
	replace ntee_maj = 3 if strpos(ntee_cd, "C") | strpos(ntee_cd, "D")
	replace ntee_maj = 4 if strpos(ntee_cd, "E") | strpos(ntee_cd, "F") | strpos(ntee_cd, "G") | strpos(ntee_cd, "H")
	replace ntee_maj = 5 if strpos(ntee_cd, "I") | strpos(ntee_cd, "J") | strpos(ntee_cd, "K") | strpos(ntee_cd, "L") ///
		| strpos(ntee_cd, "M") | strpos(ntee_cd, "N") | strpos(ntee_cd, "O") | strpos(ntee_cd, "P")
	replace ntee_maj = 6 if strpos(ntee_cd, "Q")
	replace ntee_maj = 7 if strpos(ntee_cd, "R") | strpos(ntee_cd, "S") | strpos(ntee_cd, "T") | strpos(ntee_cd, "U") ///
		| strpos(ntee_cd, "W")
	replace ntee_maj = 8 if strpos(ntee_cd, "X")
	replace ntee_maj = 9 if strpos(ntee_cd, "Y")
	replace ntee_maj = 10 if strpos(ntee_cd, "Z")
	
	label define ntee_maj_lab 1 "Arts, Culture, and Humanities" 2 "Education" 3 "Environment and Animals" 4 "Health" 5 "Human Services" ///
		6 "International, Foreign Affairs" 7 "Public, Societal Benefit" 8 "Religion Related" 9 "Mutual/Membership Benefit" 10 "Unknown, Unclassified"
	label values ntee_maj ntee_maj_lab
	
		
		// Keep a version for merging with revocations data
		
		preserve
			keep ein ntee_maj
			duplicates drop ein, force
			sort ein
			sav $path1\ein-ntee-lookup-$fdate.dta, replace
		restore

	
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
	egen reg_count = sum(reg), by(regm ntee_maj)
	egen reg_avg  = mean(reg_count) if regm < tm(2020m1), by(month_reg ntee_maj)
	egen reg_sd = sd(reg_count) if regm < tm(2020m1), by(month_reg ntee_maj)
	gen reg_lb = reg_avg - reg_sd
	gen reg_ub = reg_avg + reg_sd
	foreach var of varlist reg_count-reg_ub {
		replace `var' = ceil(`var')
	}
		
	
	// Convert to time series
	
	preserve
		sort month_reg ntee_maj
		keep if reg_avg!=.
		duplicates drop month_reg ntee_maj, force
		keep month_reg ntee_maj reg_avg-reg_ub
		sav $path1\us-monthly-averages-by-ntee.dta, replace
	restore
	
	sort month_reg
	drop reg_avg-reg_ub
	merge m:1 month_reg ntee_maj using $path1\us-monthly-averages-by-ntee.dta, keep(match) keepus(reg_avg-reg_ub)
	keep if regm >= tm(2020m1)
	drop ein-ntee_cd _merge
	duplicates drop regm ntee_maj, force
	drop if regm==.
	l
	sav $path1\us-monthly-registrations-by-ntee-$fdate.dta, replace
		
	
	// Calculate excess events, by NTEE Code
	
	use $path1\us-monthly-registrations-by-ntee-$fdate.dta, clear
	levelsof ntee_maj, local(codes)
	
	foreach code of local codes {
		use $path1\us-monthly-registrations-by-ntee-$fdate.dta, clear
		keep if ntee_maj==`code'
		sort ntee_maj regm
		
		gen reg_excess = ceil(reg_count - reg_avg)
		gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
		gen reg_excess_cumu = sum(reg_excess)
		gen reg_avg_cumu = sum(reg_avg)
		gen reg_count_cumu = sum(reg_count)
		gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
		
		sav $path1\ntee-code-`code'.dta, replace
	}
	
	use $path1\ntee-code-1.dta, clear
	forvalues i = 2/10 {
		append using $path1\ntee-code-`i'.dta, force
	}
	
	gen period = regm
	sort period
	format period %tm
	drop month_reg reg regd regy regq
	sav $path3\us-monthly-registrations-by-ntee-$fdate.dta, replace


	** Revocations

	import delimited using $path2\$foldate\usa\irs_revoked_exemp_orgs_$fdate.csv, varn(1) clear
	keep ein exemption_type revocation_date revocation_posting_date exemption_reinstatement_date
	codebook, compact
	/*
		Interestingly, some nonprofits have had their status reinstated - exclude these from analysis.
		
		I also want to exclude organisations that are not 501(c)(3) orgs.
	*/
	drop if exemption_reinstatement_date!=""
	keep if exemption_type==3 // assuming 3 refers to 501(c)(3)
	
		
		// Merge with NTEE Code lookup
		/*
		duplicates drop ein, force
		sort ein
		merge 1:1 ein using $path1\ein-ntee-lookup-$fdate.dta, keep(match master)
		*/
	

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
	sav $path1\us-monthly-removals-$fdate.dta, replace
	
	
	// Create analysis file
	
	use $path1\us-monthly-registrations-$fdate.dta, clear
	merge 1:1 period using $path1\us-monthly-removals-$fdate.dta, keep(match master)
	drop _merge
	gen country = "USA"
	sav $path3\us-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\us-monthly-statistics-$fdate.csv, replace

	
************************************************************************************************************


************************************************************************************************************


** Canada **


	** Registrations

	import delimited using $path2\$foldate\can\Charities_results_2020-09-03-06-07-33.txt, varn(1) clear
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

	import delimited using $path2\$foldate\can\Charities_results_2020-09-03-06-07-33.txt, varn(1) clear
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
	keep period country *_avg* *_count* *_excess* rem_* reg_*
	sav $path3\can-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\can-monthly-statistics-$fdate.csv, replace

		
************************************************************************************************************


************************************************************************************************************


** New Zealand (CSNZ) */

import delimited using $path2\$foldate\nz\nz-roc-$fdate.csv, varn(1) clear

** De-registrations

keep if deregistrationdate!=""

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

	import delimited using $path2\$foldate\nz\nz-roc-$fdate.csv, varn(1) clear

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
	keep period country *_avg* *_count* *_excess* rem_* reg_*
	drop postaladdress_country streetaddress_country
	sav $path3\nz-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\nz-monthly-statistics-$fdate.csv, replace

	
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

	import excel using $path2\$foldate\aus\aus-roc-$fdate.xlsx, firstrow clear
	
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
	keep period country *_avg* *_count* *_excess* reg_*
	sav $path3\aus-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\aus-monthly-statistics-$fdate.csv, replace

		
************************************************************************************************************


************************************************************************************************************


** Northern Ireland **

	** Registrations
	
	import delimited using $path2\$foldate\ni\ni-roc-$fdate.csv, varn(1) clear
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
		
	import delimited using $path2\$foldate\ni\ni-removals-$fdate.csv, varn(1) clear
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
	keep period country *_avg* *_count* *_excess* rem_* reg_*
	sav $path3\ni-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\ni-monthly-statistics-$fdate.csv, replace

	
************************************************************************************************************


************************************************************************************************************


** England and Wales **

import delimited using $path2\$foldate\ew\extract_registration.csv, varn(1) clear
keep regno regdate remdate
duplicates drop regno, force
sort regno
desc, f
sav $path1\ccew-reg-dates.csv, replace


import delimited using $path2\$foldate\ew\extract_charity.csv, varn(1) clear
sort regno
replace regno = "" if missing(real(regno)) // Set nonnumeric instances of regno as missing
destring regno, replace
duplicates drop regno, force
desc, f

	// Merge date information
	
	merge 1:1 regno using $path1\ccew-reg-dates.csv, keep(match)
	drop _merge
	
	
		// Postcode lookup version
		
		sort postcode
		sav $path1\ccew-roc-postcode.dta, replace
	

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
	
	sav $path1\ew-roc-v1.dta, replace


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
	keep period country *_avg* *_count* *_excess* rem_* reg_*
	sav $path3\ew-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\ew-monthly-statistics-$fdate.csv, replace
	
	/*
	** Time series of cumulative number of charities
	
	use $path1\ew-roc-v1.dta, clear
	
	// Calculate net number of charities
	
	gen freq = 1
	egen reg_count = sum(freq), by(regm)
	egen rem_count = sum(freq), by(remm)
	
	preserve
		duplicates drop regm, force
		rename regm period
		sort period
		keep period reg_count
		sav $path1\ew-reg-ts.dta, replace
	restore
	
	preserve
		duplicates drop remm, force
		rename remm period
		sort period
		keep period rem_count
		sav $path1\ew-rem-ts.dta, replace
	restore
	
	use $path1\ew-reg-ts.dta, clear
	merge 1:1 period using $path1\ew-rem-ts.dta, keep(match master)
	drop _merge
	
	replace rem_count = 0 if rem_count==.
	gen netreg = reg_count - rem_count
	gen cumu = netreg[1]
	replace cumu = netreg + cumu[_n-1] if _n > 1
	hist netreg, freq norm scheme(s1mono)
	/*
		Perform a check that these figures are correct.
	*/
	
	keep if period >= tm(2015m1)
	drop if period==.
	sav $path3\ew-monthly-statistics-cumu-$fdate.dta, replace
	/*
		Think of merging this with the original monthly statistics dataset.
	*/
	
	
	** Geographic disaggregation
	/*
		*SEE CHARITY DENSITY PAPER FOR CODE AND IDEAS*
		
		Registrations and de-registrations by geographic unit e.g., LA, MSOA.
		
		Geographic data from:
			- https://github.com/drkane/geo-lookups
			- https://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-may-2020
	*/
	
	// Import local authority data
	
	import delimited "https://github.com/drkane/geo-lookups/raw/master/la_all_codes.csv", clear varn(1)
	rename ladcd la_code
	rename ladnm la_name
	rename lad20cd la_2020_code
	sort la_code
	keep la_code la_name la_2020_code
	gen la_code_diff = (la_code!=la_2020_code)
	sav $path1\uk_la_codes-$fdate.dta, replace
	
	
	// Import MSOA data
	
	import delimited "https://github.com/drkane/geo-lookups/raw/master/msoa_la.csv", clear varn(1)
	rename msoa11cd msoa_code
	rename msoa11nm msoa_name
	rename lad20cd la_2020_code
	rename lad20nm la_2020_name
	sort la_2020_code
	keep msoa_code msoa_name la_2020_*
	sav $path1\uk_msoa_codes-$fdate.dta, replace


	// Import postcode lookup data
	
	import delimited using $path2\NSPL_MAY_2020_UK.csv, varn(1) clear
	keep pcd laua
	rename pcd postcode
	rename laua la_code
	sort postcode
	
	replace postcode = lower(postcode)
	replace postcode = trim(postcode)
	replace postcode = subinstr(postcode, " ", "", .)
	
	sav $path2\uk-postcode-la-lookup-2020-05.dta, replace
	
	
	// Link postcode lookup to charity data
	
	use $path1\ccew-roc-postcode.dta, clear
	
	replace postcode = lower(postcode)
	replace postcode = trim(postcode)
	replace postcode = subinstr(postcode, " ", "", .)
	
	merge m:1 postcode using $path2\uk-postcode-la-lookup-2020-05.dta, keep(match master)
	rename _merge postcode_merge
	mdesc postcode // managed to match all bar c. 300 non-missing postcodes
	
	
	// Link local authority lookup to charity data
	
	sort la_code
	tab la_code, sort
	merge m:1 la_code using $path1\uk_la_codes-$fdate.dta, keep(match master)
	rename _merge la_merge
	tab *_merge
	
	
	// Link MSOA lookup to charity data
	
	
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
	
	
	// Calculate yearly figures and ranks
	
	keep if regy >= 2015 // interested in five-year average
	gen reg_count = 1
	*gen compy = (regy < 2020)
	collapse (count) reg_count, by(regy la_code)
	bys regy: egen reg_count_rank = rank(reg_count), field 
	sort la_code
	merge m:1 la_code using $path1\uk_la_codes-$fdate.dta, keep(match master) keepus(la_name)
		
	
	// Convert to time series
	
	tsset la_code period, delta(1)
	
	preserve
		sort regy la_code
		keep if reg_avg!=.
		duplicates drop regy la_code, force
		keep regy la_code reg_avg-reg_ub
		sav $path1\ew-yearly-averages-by-la.dta, replace
	restore
	
	sort regy
	drop reg_avg-reg_ub
	merge m:1 regy la_code using $path1\ew-yearly-averages-by-la.dta, keep(match) keepus(reg_avg-reg_ub)
	keep if regy >= 2020
	drop regno-remdate _merge
	capture duplicates drop regy la_code, force
	drop if regy==.
	l
	sav $path1\ew-yearly-registrations-by-la-$fdate.dta, replace
		
	
	// Calculate excess events, by local authority
	
	use $path1\ew-yearly-registrations-by-la-$fdate.dta, clear
	levelsof la_code, local(codes)
	
	foreach code of local codes {
		use $path1\ew-yearly-registrations-by-la-$fdate.dta, clear
		keep if la_code==`code'
		sort la_code regy
		
		gen reg_excess = ceil(reg_count - reg_avg)
		gen reg_excess_per = ceil((reg_excess/reg_avg)*100)
		gen reg_excess_cumu = sum(reg_excess)
		gen reg_avg_cumu = sum(reg_avg)
		gen reg_count_cumu = sum(reg_count)
		gen reg_excess_cumu_per = ceil((reg_excess_cumu/reg_avg_cumu)*100)
		
		sav $path1\la-code-`code'.dta, replace
	}
	
	use $path1\la-code-1.dta, clear
	forvalues i = 2/10 {
		append using $path1\la-code-`i'.dta, force
	}
	
	gen period = regm
	sort period
	format period %tm
	drop month_reg reg regd regy regq
	sav $path3\us-monthly-registrations-by-ntee-$fdate.dta, replace
	*/
	
	
	
	/*
	** Register of Mergers
	/*
		Information in this file helps us determine which charities lost their status due to merging
		with another organisation.
	*/
	
	import delimited using $path2\ew-register-of-mergers-2020-07-15.csv, varn(1) clear
	drop v6 datevestingdeclarationmade datepropertytransferred
	
	
		// Rename variables
		
		rename nameoftransferringcharitytransfe name_tra
		rename nameofreceivingcharitytransferee name_rec
		rename datemergerregistered merd_str
		
		
		// Clean date variable
		
		gen merd = date(merd_str, "DMY")
		format merd %td
		
		
		// Drop unnecessary observations
		
		drop if merd < date("01/01/2015", "DMY")
		drop if merd == .
		
		
		// Extract charity numbers
		
		foreach var in tra rec {
			gen regno_`var' = substr(name_`var', strpos(name_`var', "("), strpos(name_`var', ")"))
			replace regno_`var' = subinstr(regno_`var', "(", "", .)
			replace regno_`var' = subinstr(regno_`var', ")", "", .)
			l if strmatch(regno_`var', "-") == 1
		}
		/*
			Remaining issues:
				- deal with other regno formats e.g., NAME: REGNO; NAME (REGNO
				- deal with missing values for regno_`var'
				- deal with instances where more than one transferring charity.
		*/
		*/
		



***************************************************************************************************************

***************************************************************************************************************


** Scotland **

** Create master file

import delimited using $path2\$foldate\sco\CharityExport-03-Sep-2020.csv, varn(1) clear
gen regdata = 1
sav $path1\scot-roc-2020-08.dta, replace

import delimited using $path2\$foldate\sco\CharityExport-Removed-03-Sep-2020.csv, varn(1) clear
gen remdata = 1
sav $path1\scot-removals-2020-08.dta, replace

append using $path1\scot-roc-2020-08.dta, force
*keep charityregistrationnumber deregistrationdate dateregistered *data
gen removed = (remdata)
sav $path1\scot-all-data-2020-08.dta, replace


** De-registrations

use $path1\scot-all-data-2020-08.dta, clear
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
	
	sav $path1\scot-rem-data.dta, replace

	
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

use $path1\scot-all-data-2020-08.dta, clear

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
	
	sav $path1\scot-reg-data.dta, replace

	
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
	keep period country *_avg* *_count* *_excess* rem_* reg_*
	sav $path3\scot-monthly-statistics-$fdate.dta, replace
	export delimited using $path3\scot-monthly-statistics-$fdate.csv, replace
	
	/*
	** Time series of cumulative number of charities
	
	foreach var in reg rem {
		
		use $path1\scot-`var'-data.dta, clear
	
		// Calculate net number of charities
		
		gen freq = 1
		egen `var'_count = sum(freq), by(`var'm)

		duplicates drop `var'm, force
		rename `var'm period
		sort period
		keep period `var'_count
		sav $path1\scot-`var'-ts.dta, replace
	}
	
	
	use $path1\scot-reg-ts.dta, clear
	merge 1:1 period using $path1\scot-rem-ts.dta, keep(match master)
	drop _merge
	
	replace rem_count = 0 if rem_count==.
	gen netreg = reg_count - rem_count
	gen cumu = netreg[1]
	replace cumu = netreg + cumu[_n-1] if _n > 1
	hist netreg, freq norm scheme(s1mono)
	/*
		Perform a check that these figures are correct.
	*/
	
	keep if period >= tm(2015m1)
	drop if period==.
	sav $path3\scot-monthly-statistics-cumu-$fdate.dta, replace
	*/

		
************************************************************************************************************


************************************************************************************************************

/*
	
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
*/

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
