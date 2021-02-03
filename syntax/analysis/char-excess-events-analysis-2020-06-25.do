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
global dfiles "C:\Users\mcdonndz\Dropbox" // location of data files
global rfiles "C:\Users\mcdonndz\DataShare\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\mcdonndz\DataShare\projects\charity-covid19\docs" // location of graphs

include "$rfiles\syntax\stata-file-paths.doi"


** Alasdair **
global dfiles "C:\Users\alasd\Dropbox\" // location of data files
global rfiles "C:\Users\alasd\OneDrive\Documents\codingworkspace\covid19register" // location of syntax and other project outputs
global gfiles "C:\Users\alasd\OneDrive\Documents\codingworkspace\covid19register\docs2" // location of graphs

include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Data Visualisation **/

** Set file and image properties

global isize 1200
global cutoff tm(2021m1)
global fdate "2021-01-28" // date used to name input files
global pdate "2021-01-28" // date used to name visualisation and other analytical outputs

* Graph colours
	global axtcol = "gs5"	// axis colour
	global obscol = "navy"
	global expcol = "cranberry"
	
* Graph settings
	global graphstyle = `"bgcolor(white) plotregion(ilcolor(none) lcolor(none)) graphregion(ilcolor(none) lcolor(none)) graphregion(fcolor(white)) scheme(s1mono)"'

	
local countrylist = "aus us can nz ni scot ew"
local monthyr = "January 2021"

* USA
	local cnameus = "United States of America"		// The subtitle
	local cregulatorus = "IRS"						// The name of the regulator
	local cyhregus = 80000							// Y-axis height for registrations
	local cyhremus = 40000							// Y-axis height for removals

* Canada
	local cnamecan = "Canada"						// The subtitle
	local cregulatorcan = "CRA"						// The name of the regulator
	local cyhregcan =2000							// Y-axis height for registrations
	local cyhremcan = 1100							// Y-axis height for removals	
	
* Country
	local cnamenz = "New Zealand"					// The subtitle
	local cregulatornz = "CSNZ"						// The name of the regulator
	local cyhregnz =1750							// Y-axis height for registrations
	local cyhremnz = 2000							// Y-axis height for removals	
	
* Country
	local cnameaus = "Australia"					// The subtitle
	local cregulatoraus = "ACNC"					// The name of the regulator
	local cyhregaus =2400							// Y-axis height for registrations
	local cyhremaus = 2000							// Y-axis height for removals	
	
* Country
	local cnameni = "Northern Ireland"				// The subtitle
	local cregulatorni = "CCNI"						// The name of the regulator
	local cyhregni = 2000							// Y-axis height for registrations
	local cyhremni = 100							// Y-axis height for removals	
	
* Country
	local cnamescot = "Scotland"					// The subtitle
	local cregulatorscot = "OSCR"					// The name of the regulator
	local cyhregscot = 1000							// Y-axis height for registrations
	local cyhremscot = 800							// Y-axis height for removals	
	
* Country
	local cnameew = "England and Wales"				// The subtitle
	local cregulatorew = "CCEW"						// The name of the regulator
	local cyhregew = 6000							// Y-axis height for registrations
	local cyhremew = 6000							// Y-axis height for removals	
	
* Country
	local cname = ""						// The subtitle
	local cregulator = ""						// The name of the regulator
	local cyhreg =4000							// Y-axis height for registrations
	local cyhrem = 4000							// Y-axis height for removals	
	
foreach c in `countrylist' {
	
	local filename = "$path3\\`c'-monthly-statistics-$fdate.dta"
	di "`filename'"
	use "`filename'", clear

	// Monthly variability
		
		local ytitle = "Count of registrations"
		local xtitle = "Month"
		
		sum reg_ub
		local ymax = r(max) * 1.02
		//local ytick = max(round(`ymax'/5, 10), round(`ymax'/5, 100), round(`ymax'/5, 1000))
		if `ymax'<=250 {
			local ytick = max(round(`ymax'/5, 10), round(`ymax'/5, 50))
			}
		else {
			local ytick = max(round(`ymax'/5, 100), round(`ymax'/5, 1000), round(`ymax'/5, 5000))
		}
		di "Max: `ymax' " "Tick: `ytick'"
		local yumax = round(`ymax', `ytick')
		//di `ytick' " " round(`ymax'/5, 10) " " round(`ymax'/5, 100) " " round(`ymax'/5, 1000)
		/*
		twoway 	(rcap reg_lb reg_ub period if period < $cutoff, msize(small) lpatt(solid) lcolor($expcol*0.5) ) ///
				(scatter reg_avg period if period < $cutoff, msym(O) msize(small) mcolor($expcol)) ///
				(scatter reg_count period if period < $cutoff, msym(D) msize(medlarge) mcolor($obscol)) ///
				, ///
			title("Charity Registrations") subtitle("`cname`c''") ///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`ymax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(1 "Variability") label(2 "Mean Registrations (2015-2019)") label(3 "Observed Registrations") rows(1) size(small)) ///
			note("Intervals represent expected range of variability in registrations for that month (2015-2019)", color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			$graphstyle
		*/	
		twoway 	(rcap reg_lb reg_ub period if period < $cutoff, msize(vtiny) lpatt(solid) lwidth(vvthick) lcolor($expcol*0.5) ) ///
				(scatter reg_count period if period < $cutoff, msym(D) msize(medlarge) mcolor($obscol)) ///
				, ///
			title("Charity Registrations") subtitle("`cname`c''") ///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(range(0 `yumax') lcolor($axtcol))  ylabel(0(`ytick')`ymax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(1 "Variability of Mean Registrations (2015-2019)") label(2 "Observed Registrations") rows(1) size(small)) ///
			note("Intervals represent expected range of variability in registrations for that month (2015-2019)", color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			$graphstyle
			
		graph export $path6\`c'-monthly-registrations-$pdate.png, replace width($isize)
			
		twoway 	(area reg_ub period if period < $cutoff, msize(small) color($expcol*0.2) ) ///
				(area reg_lb period if period < $cutoff, msize(small) color(white) ) ///
				(scatter reg_count period if period < $cutoff, msym(D) msize(medlarge) mcolor($obscol)) ///
				, ///
			title("Charity Registrations") subtitle("`cname`c''") ///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(range(0 `yumax') lcolor($axtcol))  ylabel(0(`ytick')`ymax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(1 "Variability of Mean Registrations (2015-2019)") label(3 "Observed Registrations") order(1 3) rows(1) size(small)) ///
			note("Intervals represent expected range of variability in registrations for that month (2015-2019)", color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			$graphstyle
			
		graph export $path6\`c'-monthly-registrations-range-$pdate.png, replace width($isize)

		
		if "`c'" != "aus" {
		
		local ytitle = "Count of removals"
		local xtitle = "Month"
		sum rem_ub
		local ymax = r(max) * 1.02
		if `ymax'<=250 {
			local ytick = max(round(`ymax'/5, 10), round(`ymax'/5, 50))
			}
		else {
			local ytick = max(round(`ymax'/5, 100), round(`ymax'/5, 1000), round(`ymax'/5, 5000))
		}
		di "Max: `ymax' " "Tick: `ytick'"
		local yumax = round(`ymax', `ytick')	
		/*
		twoway 	(rcap rem_lb rem_ub period if period < $cutoff, msize(small) lpatt(solid)  lcolor($expcol*0.5)) ///
				(scatter rem_avg period if period < $cutoff, msym(O) msize(small) mcolor($expcol)) ///
				(scatter rem_count period if period < $cutoff, msym(D) msize(medlarge) mcolor($obscol)) ///
				, ///
			title("Charity Removals") subtitle("`cname`c''") ///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`ymax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(1 "Variability") label(2 "Mean Removals (2015-2019)") label(3 "Observed Removals") rows(1) size(small)) ///
			note("Intervals represent expected range of variability in removals for that month (2015-2019)", color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			$graphstyle
		*/	
		twoway 	(rcap rem_lb rem_ub period if period < $cutoff, msize(vtiny) lpatt(solid) lwidth(vvthick) lcolor($expcol*0.5)) ///
				(scatter rem_count period if period < $cutoff, msym(D) msize(medlarge) mcolor($obscol)) ///
				, ///
			title("Charity Removals") subtitle("`cname`c''") ///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(range(0 `yumax') lcolor($axtcol))  ylabel(0(`ytick')`ymax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(1 "Variability of Mean Removals (2015-2019)")  label(2 "Observed Removals") rows(1) size(small)) ///
			note("Intervals represent expected range of variability in removals for that month (2015-2019)", color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			$graphstyle
			
		graph export $path6\`c'-monthly-removals-$pdate.png, replace width($isize)

		twoway 	(area rem_ub period if period < $cutoff, msize(small) color($expcol*0.2) ) ///
				(area rem_lb period if period < $cutoff, msize(small) color(white) ) ///
				(scatter rem_count period if period < $cutoff, msym(D) msize(medlarge) mcolor($obscol)) ///
				, ///
			title("Charity Removals") subtitle("`cname`c''") ///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(range(0 `yumax') lcolor($axtcol))  ylabel(0(`ytick')`ymax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(1 "Variability of Mean Removals (2015-2019)") label(3 "Observed Removals") order(1 3) rows(1) size(small)) ///
			note("Intervals represent expected range of variability in removals for that month (2015-2019)", color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			$graphstyle			
			
			
		graph export $path6\`c'-monthly-removals-range-$pdate.png, replace width($isize)
		}
	

		
		// Cumulative events
		
		** Registrations
	
		local ytitle = "Count of registrations"
		local xtitle = "Month"
		local ytick = max(round(`cyhreg`c''/5, 100), round(`cyhreg`c''/5, 1000))

		gen dif=reg_count_cumu - reg_avg_cumu
		sum dif
		if r(mean)>0 {
			local shading = "(area reg_count_cumu period if period < $cutoff, color($expcol*0.2))  (area reg_avg_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		else {
			local shading = "(area reg_avg_cumu period if period < $cutoff, color($expcol*0.2))  (area reg_count_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		drop dif
		
		twoway 	`shading'	///
				(line reg_count_cumu period if period < $cutoff, lpatt(solid) lwidth(thick) lcolor($obscol)) ///
				(line reg_avg_cumu period if period < $cutoff, lpatt(dash) lwidth(thick) lcolor($expcol)) 		///
				,		///
			title("Cumulative Registrations") subtitle("`cname`c''") 		///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`cyhreg`c'', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(3 "Observed Registrations") label(4 "Expected Registrations (2015-2019)") rows(1) size(small) order(3 4)) ///
			note("Expected registrations: mean number of registrations for that month (2015-2019)",  color($axtcol)) ///
			caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
			bgcolor(white) plotregion(ilcolor(none) lcolor(none)) graphregion(ilcolor(none) lcolor(none)) ///
			graphregion(fcolor(white))	scheme(s1mono)	
			
		graph export $path6\`c'-monthly-cumulative-registrations-$pdate.png, replace width($isize)

		
		** Removals
		
		if "`c'" != "aus" {
			local ytitle = "Count of removals"
			local xtitle = "Month"
			local ytick = max(round(`cyhrem`c''/5, 100), round(`cyhrem`c''/5, 1000))

			gen dif=rem_count_cumu - rem_avg_cumu
			sum dif
			if r(mean)>0 {
				local shading = "(area rem_count_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_avg_cumu period if period < $cutoff, color($obscol*0.2))"
				}
			else {
				local shading = "(area rem_avg_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_count_cumu period if period < $cutoff, color($obscol*0.2))"
				}
			drop dif
			
			twoway 	`shading'	///
					(line rem_count_cumu period if period < $cutoff, lpatt(solid) lwidth(thick) lcolor($obscol)) ///
					(line rem_avg_cumu period if period < $cutoff, lpatt(dash) lwidth(thick) lcolor($expcol)) 		///
					,		///
				title("Cumulative Removals") subtitle("`cname`c''") 		///
				ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`cyhrem`c'', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
				xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
				legend(label(3 "Observed Removals") label(4 "Expected Removals (2015-2019)") rows(1) size(small) order(3 4)) ///
				note("Expected removals: mean number of removals for that month (2015-2019)",  color($axtcol)) ///
				caption("Data from `cregulator`c'' `monthyr' Data Download", size(small) color($axtcol)) ///
				bgcolor(white) plotregion(ilcolor(none) lcolor(none)) graphregion(ilcolor(none) lcolor(none)) ///
				graphregion(fcolor(white))	scheme(s1mono)	
				
			graph export $path6\`c'-monthly-cumulative-removals-$pdate.png, replace width($isize)


		}

}


/* Yearly statistics */
/*
	Produce plot of deviation from expected levels of registrations and de-registrations.
*/

use $path3\all-jurisdictions-yearly-statistics-$fdate.dta, clear
encode country, gen(jurisdiction)
drop if regy > 2020
gen y2020 = (regy==2020)
gen yoth = (regy<2020)

	** Registrations **
	
	// Scatterplot of standard deviations

	twoway (scatter jurisdiction reg_deviation if y2020, mcolor(cranberry) msize(medlarge)) (scatter jurisdiction reg_deviation if yoth, mcolor(gs10) msym(O)) ///
		, xline(0, lcolor(gs5)) title("Excess registrations for charity jurisdictions") subtitle(" ") ///
		xlab(-3(1)3, labsize(small)) ylab(1 "Australia" 2 "Canada" 3 "England & Wales" 4 "Northern Ireland" 5 "New Zealand" 6 "Scotland" 7 "USA", labsize(small) angle(0)) ///
		xtitle("Standard deviations above or below average number of registrations (2015-2019)", size(small)) ///
		ytitle(" ") ///
		legend(label(1 "2020") label(2 "2015-2019") size(small)) ///
		$graphstyle
	graph export $path6\all-jurisdictions-yearly-registrations-$pdate.png, replace width($isize)
		
	// Growth index
	
	twoway (line reg_count_index period if jurisdiction==1, lcolor(cranberry)) (line reg_count_index period if jurisdiction==2, lcolor(dknavy)) ///
		(line reg_count_index period if jurisdiction==3, lcolor(dkorange)) (line reg_count_index period if jurisdiction==4, lcolor(sandb)) ///
		(line reg_count_index period if jurisdiction==5, lcolor(eltblue)) (line reg_count_index period if jurisdiction==6, lcolor(orange_red)) ///
		(line reg_count_index period if jurisdiction==7, lcolor(forest_green)) ///
		, yline(100, lcolor(gs5) lpatt(shortdash)) title("Growth/decline in registrations") subtitle(" ") ///
		xlab(, labsize(small)) ylab(, labsize(small)) ///
		xtitle("Registration year", size(small)) ///
		ytitle("Growth index (100 = no. of registrations in 2015)", size(small)) ///
		legend(label(1 "Australia") label(2 "Canada") label(3 "England & Wales") label(4 "Northern Ireland") label(5 "New Zealand") label(6 "Scotland") label(7 "USA") rows(3) size(small)) ///
		$graphstyle
	graph export $path6\all-jurisdictions-yearly-registrations-index-$pdate.png, replace width($isize)
		
		
	** Removals **
	
	// Scatterplot of standard deviations

	twoway (scatter jurisdiction rem_deviation if y2020, mcolor(cranberry) msize(medlarge)) (scatter jurisdiction rem_deviation if yoth, mcolor(gs10) msym(O)) ///
		, xline(0, lcolor(gs5)) title("Excess removals for charity jurisdictions") subtitle(" ") ///
		xlab(-3(1)3, labsize(small)) ylab(2 "Canada" 3 "England & Wales" 4 "Northern Ireland" 5 "New Zealand" 6 "Scotland" 7 "USA", labsize(small) angle(0)) ///
		xtitle("Standard deviations above or below average number of removals (2015-2019)", size(small)) ///
		ytitle(" ") ///
		legend(label(1 "2020") label(2 "2015-2019") size(small)) ///
		$graphstyle
	graph export $path6\all-jurisdictions-yearly-removals-$pdate.png, replace width($isize)
		
	// Growth index
	
	twoway (line rem_count_index period if jurisdiction==1, lcolor(cranberry)) (line rem_count_index period if jurisdiction==2, lcolor(dknavy)) ///
		(line rem_count_index period if jurisdiction==3, lcolor(dkorange)) (line rem_count_index period if jurisdiction==4, lcolor(sandb)) ///
		(line rem_count_index period if jurisdiction==5, lcolor(eltblue)) (line rem_count_index period if jurisdiction==6, lcolor(orange_red)) ///
		(line rem_count_index period if jurisdiction==7, lcolor(forest_green)) ///
		, yline(100, lcolor(gs5) lpatt(shortdash)) title("Growth/decline in removals") subtitle(" ") ///
		xlab(, labsize(small)) ylab(, labsize(small)) ///
		xtitle("Registration year", size(small)) ///
		ytitle("Growth index (100 = no. of removals in 2015)", size(small)) ///
		legend(label(2 "Canada") label(3 "England & Wales") label(4 "Northern Ireland") label(5 "New Zealand") label(6 "Scotland") label(7 "USA") rows(3) size(small)) ///
		$graphstyle
	graph export $path6\all-jurisdictions-yearly-removals-index-$pdate.png, replace width($isize)



		
		
		
		
/* England and Wales - Removal Reason */

use $path3\ew-monthly-removals-by-remcode-$fdate.dta, clear
/*
	Focus on three categories initially:
		- Amalgamated (A)
		- Ceased to exist (CE)
		- Does not operate (NO)
*/

	** Local macros
	
	local ytitle = "Count of removals"
	local xtitle = "Month"
	local cnameew = "England and Wales"				// The subtitle
	local cregulatorew = "CCEW"						// The name of the regulator
	local ceyax = 2000							// Y-axis height for Ceased to exist removals
	local noyax = 1000							// Y-axis height for Does not operate removals
	local ayax = 500							// Y-axis height for Amalgamation removals
	
	
	// Cumulative events
	
	** Ceased to exist (CE)
	
	local ytick = max(round(`ceyax'/5, 100), round(`ceyax'/5, 10))

	preserve
		
		keep if remcode=="CE"
		
		gen dif=rem_count_cumu - rem_avg_cumu
		sum dif
		if r(mean)>0 {
			local shading = "(area rem_count_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_avg_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		else {
			local shading = "(area rem_avg_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_count_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		drop dif
		
		twoway 	`shading'	///
				(line rem_count_cumu period if period < $cutoff, lpatt(solid) lwidth(thick) lcolor($obscol)) ///
				(line rem_avg_cumu period if period < $cutoff, lpatt(dash) lwidth(thick) lcolor($expcol)) 		///
				,		///
			title("Cumulative Removals - Ceased to Exist") subtitle("England and Wales") 		///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`ceyax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(3 "Observed Removals") label(4 "Expected Removals (2015-2019)") rows(1) size(small) order(3 4)) ///
			note("Expected removals: mean number of removals for that month (2015-2019)",  color($axtcol)) ///
			caption("Data from `cregulator`c'' November 2020 Data Download", size(small) color($axtcol)) ///
			bgcolor(white) plotregion(ilcolor(none) lcolor(none)) graphregion(ilcolor(none) lcolor(none)) ///
			graphregion(fcolor(white))	scheme(s1mono)	
			
		graph export $path6\ew-monthly-cumulative-removals-ceased-to-exist-$pdate.png, replace width($isize)
	restore

	
	** Does not operate (NO)
	
	local ytick = max(round(`noyax'/5, 100), round(`noyax'/5, 10))
	
	preserve
		
		keep if remcode=="NO"
		
		gen dif=rem_count_cumu - rem_avg_cumu
		sum dif
		if r(mean)>0 {
			local shading = "(area rem_count_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_avg_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		else {
			local shading = "(area rem_avg_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_count_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		drop dif
		
		twoway 	`shading'	///
				(line rem_count_cumu period if period < $cutoff, lpatt(solid) lwidth(thick) lcolor($obscol)) ///
				(line rem_avg_cumu period if period < $cutoff, lpatt(dash) lwidth(thick) lcolor($expcol)) 		///
				,		///
			title("Cumulative Removals - Does Not Operate") subtitle("England and Wales") 		///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`noyax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(3 "Observed Removals") label(4 "Expected Removals (2015-2019)") rows(1) size(small) order(3 4)) ///
			note("Expected removals: mean number of removals for that month (2015-2019)",  color($axtcol)) ///
			caption("Data from `cregulator`c'' November 2020 Data Download", size(small) color($axtcol)) ///
			bgcolor(white) plotregion(ilcolor(none) lcolor(none)) graphregion(ilcolor(none) lcolor(none)) ///
			graphregion(fcolor(white))	scheme(s1mono)	
			
		graph export $path6\ew-monthly-cumulative-removals-does-not-operate-$pdate.png, replace width($isize)
	restore
	
	
	** Amalgamation (A)
	
	local ytick = max(round(`ayax'/5, 100), round(`ayax'/5, 10))
	
	preserve
		
		keep if remcode=="A"
		
		gen dif=rem_count_cumu - rem_avg_cumu
		sum dif
		if r(mean)>0 {
			local shading = "(area rem_count_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_avg_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		else {
			local shading = "(area rem_avg_cumu period if period < $cutoff, color($expcol*0.2))  (area rem_count_cumu period if period < $cutoff, color($obscol*0.2))"
			}
		drop dif
		
		twoway 	`shading'	///
				(line rem_count_cumu period if period < $cutoff, lpatt(solid) lwidth(thick) lcolor($obscol)) ///
				(line rem_avg_cumu period if period < $cutoff, lpatt(dash) lwidth(thick) lcolor($expcol)) 		///
				,		///
			title("Cumulative Removals - Amalgamation") subtitle("England and Wales") 		///
			ytitle("`ytitle'" " ", color($axtcol) size(small)) yscale(lcolor($axtcol))  ylabel(0(`ytick')`ayax', tlcolor($axtcol) labcolor($axtcol) labsize(small) format(%-12.0gc) nogrid) 		///
			xtitle("`xtitle'", color($axtcol) size(small)) xscale(lcolor($axtcol)) xlabel(, tlcolor($axtcol) labcolor($axtcol) labsize(small)  nogrid)  	///
			legend(label(3 "Observed Removals") label(4 "Expected Removals (2015-2019)") rows(1) size(small) order(3 4)) ///
			note("Expected removals: mean number of removals for that month (2015-2019)",  color($axtcol)) ///
			caption("Data from `cregulator`c'' November 2020 Data Download", size(small) color($axtcol)) ///
			bgcolor(white) plotregion(ilcolor(none) lcolor(none)) graphregion(ilcolor(none) lcolor(none)) ///
			graphregion(fcolor(white))	scheme(s1mono)	
			
		graph export $path6\ew-monthly-cumulative-removals-amalgamation-$pdate.png, replace width($isize)
	restore









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
	*graph export $path6\all-monthly-cumulative-change-registrations.png", replace width($isize)
*/

