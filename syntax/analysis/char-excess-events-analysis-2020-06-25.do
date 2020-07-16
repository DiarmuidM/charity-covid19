********************************************************************************
********************************************************************************
********************************************************************************
/*
	Project: The impact of COVID-19 on the foundation and dissolution of charitable organisations
	
	Website: https://diarmuidm.github.io/charity-covid-19/
	
	Creator: Diarmuid McDonnell
	
	Collaborators: Alasdair Rutherford
	
	Date: 2020-06-19
	
	File: char-excess-events-analysis-2020-06-25.do
	
	Description: This file analyses publicly available charity data to produce
				 statistical summaries of the level of foundations and dissolutions
				 in multiple charity jurisdictions.
				 
				 See 'FILE_NAME' for the data collection code.
*/


/** 0. Preliminaries **/

** Diarmuid **

global dfiles "C:\Users\t95171dm\Dropbox" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\t95171dm\projects\charity-covid19\docs" // location of graphs

include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Data Visualisation **/

** Set file and image properties

local isize = 1200
local fdate = "2020-07-13"
local cutoff = tm(2020m7)

** USA

use $path3\us-monthly-statistics-2020-07-12.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period if period < `cutoff', msym(O)) ///
		(scatter reg_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("United States of America") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(2000)10000, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from IRS July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\us-monthly-registrations-`fdate'.png, replace width(`isize')
	
	twoway (rcap rem_lb rem_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter rem_avg period if period < `cutoff', msym(O)) ///
		(scatter rem_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Removals") subtitle("United States of America") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Monthly Removals") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in removals for that month (2015-2019)") ///
		caption("Data from IRS July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\us-monthly-removals-`fdate'.png, replace width(`isize')

	
	// Cumulative events

	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("United States of America") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from IRS July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\us-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')
	
	twoway (line rem_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line rem_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Removals") subtitle("United States of America") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Removals") label(2 "Expected Removals (2015-2019)") rows(1) size(small)) ///
		note("Expected removals: mean number of removals for that month (2015-2019)") ///
		caption("Data from IRS Junly 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\us-monthly-cumulative-removals-`fdate'.png, replace width(`isize')
	
	
	** By NTEE Code
	
	use $path3\us-monthly-registrations-by-ntee.dta, clear
	capture graph drop *
	local isize = 1200
	local fdate = "2020-07-13"
	local cutoff = tm(2020m7)
	
	// Cumulative events - percentage
		
	levelsof ntee_maj, local(codes)
	foreach code of local codes {
		local ntee_lab: label (ntee_maj) `code'
		di "`ntee_lab'"
		twoway (line reg_excess_cumu_per period if ntee_maj==`code' & period < `cutoff', lpatt(dash) lwidth(medthick)) ///
			, title("`ntee_lab'") xtitle("") ytitle("") ///
			legend(off) ///
			scheme(s1mono) ///
			name(ntee`code')
	}
	
	graph combine ntee1 ntee2 ntee3 ntee4 ntee5 ntee6 ntee7 ntee8 ntee9 ntee10 ///
		, title("US Cumulative Registrations") subtitle("By NTEE Code") ///
		l1title("%") b1title("Month") ///
		note("% difference between observed and expected cumulative registrations") ///
		caption("Data from IRS July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\us-monthly-cumulative-registrations-percentage-by-ntee-`fdate'.png, replace width(`isize') 
	
	
	// Cumulative events
	
	levelsof ntee_maj, local(codes)
	foreach code of local codes {
		local ntee_lab: label (ntee_maj) `code'
		di "`ntee_lab'"
		twoway (line reg_count_cumu period if ntee_maj==`code' & period < `cutoff', lpatt(dash) lwidth(medthick)) ///
			(line reg_avg_cumu period if ntee_maj==`code' & period < `cutoff', lpatt(solid)) ///
			, title("`ntee_lab'") xtitle("") ///
			legend(off) ///
			scheme(s1mono) ///
			name(ntee`code')
	}	
	

** Canada

use $path3\can-monthly-statistics-2020-07-13.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period if period < `cutoff', msym(O)) ///
		(scatter reg_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("Canada") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from CRA July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\can-monthly-registrations-`fdate'.png, replace width(`isize')
	
	// Monthly variability
	
	twoway (rcap rem_lb rem_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter rem_avg period if period < `cutoff', msym(O)) ///
		(scatter rem_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Removals") subtitle("Canada") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Monthly Removals") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in removals for that month (2015-2019)") ///
		caption("Data from CRA July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\can-monthly-removals-`fdate'.png, replace width(`isize')
	
	
	// Cumulative events

	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("Canada") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from CRA July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\can-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')
	
	twoway (line rem_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line rem_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Removals") subtitle("Canada") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Removals") label(2 "Expected Removals (2015-2019)") rows(1) size(small)) ///
		note("Expected removals: mean number of removals for that month (2015-2019)") ///
		caption("Data from CRA July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\can-monthly-cumulative-removals-`fdate'.png, replace width(`isize')

	

** New Zealand

use $path3\nz-monthly-statistics-2020-07-13.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period if period < `cutoff', msym(O)) ///
		(scatter reg_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("New Zealand") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(50)250, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from CSNZ July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\nz-monthly-registrations-`fdate'.png, replace width(`isize')
	
	twoway (rcap rem_lb rem_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter rem_avg period if period < `cutoff', msym(O)) ///
		(scatter rem_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Removals") subtitle("New Zealand") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Monthly Removals") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in removals for that month (2015-2019)") ///
		caption("Data from CSNZ July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\nz-monthly-removals-`fdate'.png, replace width(`isize')

	
	// Cumulative events

	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("New Zealand") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from CSNZ July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\nz-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')
	
	twoway (line rem_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line rem_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Removals") subtitle("New Zealand") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Removals") label(2 "Expected Removals (2015-2019)") rows(1) size(small)) ///
		note("Expected removals: mean number of removals for that month (2015-2019)") ///
		caption("Data from CSNZ July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\nz-monthly-cumulative-removals-`fdate'.png, replace width(`isize')

	
** Australia

use $path3\aus-monthly-statistics.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period, msym(O)) ///
		(scatter reg_count period, msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("Australia") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(50)300, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from ACNC July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\aus-monthly-registrations-`fdate'.png, replace width(`isize')

	
	// Cumulative events

	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("Australia") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(200)1200, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from ACNC July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\aus-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')

	
** Northern Ireland

use $path3\ni-monthly-statistics-2020-07-09.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period if period < `cutoff', msym(O)) ///
		(scatter reg_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("Northern Ireland") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(40)260, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from CCNI July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ni-monthly-registrations-`fdate'.png, replace width(`isize')
	
	twoway (rcap rem_lb rem_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter rem_avg period if period < `cutoff', msym(O)) ///
		(scatter rem_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Removals") subtitle("Northern Ireland") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(0(10)40, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Monthly Removals") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in removals for that month (2015-2019)") ///
		caption("Data from CCNI July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ni-monthly-removals-`fdate'.png, replace width(`isize')

	
	// Cumulative events

	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("Northern Ireland") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from CCNI July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ni-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')
	
	twoway (line rem_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line rem_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Removals") subtitle("Northern Ireland") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Removals") label(2 "Expected Removals (2015-2019)") rows(1) size(small)) ///
		note("Expected removals: mean number of removals for that month (2015-2019)") ///
		caption("Data from CCNI July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ni-monthly-cumulative-removals-`fdate'.png, replace width(`isize')


** Scotland

use $path3\scot-monthly-statistics-2020-07-09.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period if period < `cutoff', msym(O)) ///
		(scatter reg_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("Scotland") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(20)120, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from OSCR July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\scot-monthly-registrations-`fdate'.png, replace width(`isize')
		
	twoway (rcap rem_lb rem_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter rem_avg period if period < `cutoff', msym(O)) ///
		(scatter rem_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Removals") subtitle("Scotland") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(0(20)120, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Monthly Removals") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in removals for that month (2015-2019)") ///
		caption("Data from OSCR July 2020 Data Download", size(small)) ///
		scheme(s1mono)	
	graph export $path6\scot-monthly-removals-`fdate'.png, replace width(`isize')

	
	// Cumulative events

	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("Scotland") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from OSCR July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\scot-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')

	twoway (line rem_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line rem_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Removals") subtitle("Scotland") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Removals") label(2 "Expected Removals (2015-2019)") rows(1) size(small)) ///
		note("Expected Removals: mean number of removals for that month (2015-2019)") ///
		caption("Data from OSCR July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\scot-monthly-cumulative-removals-`fdate'.png, replace width(`isize')
	
		
** England and Wales

use $path3\ew-monthly-statistics-2020-07-09.dta, clear

	// Monthly variability
	
	twoway (rcap reg_lb reg_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter reg_avg period if period < `cutoff', msym(O)) ///
		(scatter reg_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Registrations") subtitle("England & Wales") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(0(100)650, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Monthly Registrations") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in registrations for that month (2015-2019)") ///
		caption("Data from CCEW July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ew-monthly-registrations-`fdate'.png, replace width(`isize')
	
	twoway (rcap rem_lb rem_ub period if period < `cutoff', msize(medlarge) lpatt(solid)) (scatter rem_avg period if period < `cutoff', msym(O)) ///
		(scatter rem_count period if period < `cutoff', msym(X) msize(large)) , ///
		title("Charity Removals") subtitle("England & Wales") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(0(150)900, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Monthly Removals") rows(1) size(small)) ///
		note("Intervals represent expected range of variability in removals for that month (2015-2019)") ///
		caption("Data from CCEW July 2020 Data Download", size(small)) ///
		scheme(s1mono)	
	graph export $path6\ew-monthly-removals-`fdate'.png, replace width(`isize')

	
	// Cumulative events
	
	local cutoff = tm(2020m7)
	twoway (line reg_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line reg_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Registrations") subtitle("England & Wales") ///
		ytitle("Count of registrations") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Registrations") label(2 "Expected Registrations (2015-2019)") rows(1) size(small)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from CCEW July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ew-monthly-cumulative-registrations-`fdate'.png, replace width(`isize')

	twoway (line rem_count_cumu period if period < `cutoff', lpatt(dash) lwidth(medthick)) (line rem_avg_cumu period if period < `cutoff', lpatt(solid)) , ///
		title("Cumulative Removals") subtitle("England & Wales") ///
		ytitle("Count of removals") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Observed Removals") label(2 "Expected Removals (2015-2019)") rows(1) size(small)) ///
		note("Expected Removals: mean number of removals for that month (2015-2019)") ///
		caption("Data from CCEW July 2020 Data Download", size(small)) ///
		scheme(s1mono)
	graph export $path6\ew-monthly-cumulative-removals-`fdate'.png, replace width(`isize')
	

/*
	
use $path3\all-jurisdictions-monthly-statistics.dta, clear

// Cumulative events - percentage drop

	twoway (line reg_excess_cumu_per period if country=="Scotland") (line reg_excess_cumu_per period if country=="Australia") ///
		(line reg_excess_cumu_per period if country=="Canada") (line reg_excess_cumu_per period if country=="England and Wales") ///
		(line reg_excess_cumu_per period if country=="New Zealand") (line reg_excess_cumu_per period if country=="USA") ///
		(line reg_excess_cumu_per period if country=="Northern Ireland") ///
		, title("Cumulative Registrations") subtitle("By Country") ///
		ytitle("% deviation from expected") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		legend(label(1 "Scot") label(2 "Aus") label(3 "Can") label(4 "E&W") ///
			label(5 "NZ") label(6 "USA") label(7 "NI") rows(2) size(vsmall)) ///
		note("Expected registrations: mean number of registrations for that month (2015-2019)") ///
		caption("Data from June 2020 Data Download", size(small)) ///
		scheme(s1color)
	*graph export $path6\all-monthly-cumulative-change-registrations.png", replace width(`isize')
*/
