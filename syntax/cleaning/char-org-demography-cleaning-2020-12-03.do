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
	
	keep regno isreg reg_year diss_year reg_date diss_date region scale icnpo_ncvo_category FH_income_def*
	rename icnpo_ncvo_category icnpo
	gen reg = (isreg=="R")
	gen dereg = (isreg=="RM")
	gen freq = 1
	
	
	** Create summary datasets **
	
	** Births
	
	preserve
		collapse (count) freq, by(reg_year)
		sort reg_year
		rename freq births
		rename reg_year year
		sav $path1\chardemo-registrations.dta, replace
	restore
	
		// By region
		
		preserve
			drop if region > 10
			collapse (count) freq, by(reg_year region)
			sort reg_year region
			rename freq births
			rename reg_year year
			sav $path1\chardemo-registrations-region.dta, replace
		restore
		
		// By ICNPO
		
		preserve
			collapse (count) freq, by(reg_year icnpo)
			sort reg_year icnpo
			rename freq births
			rename reg_year year
			sav $path1\chardemo-registrations-icnpo.dta, replace
		restore
		
	
	** Active
	/*
		Number of charities filing a non-zero annual return at time t.
	*/
	
	forvalues yr = 1995/2019 {
		gen active`yr' = (FH_income_def`yr'!=. & FH_income_def`yr' > 0)
	}
	
	preserve
		keep regno active*
		reshape long active , i(regno) j(year)
		collapse (sum) active*, by(year)
		sort year
		sav $path1\chardemo-active.dta, replace
	restore
	
		// By region
		
		preserve
			keep regno region active*
			reshape long active , i(regno) j(year)
			collapse (sum) active*, by(year region)
			sort year region
			sav $path1\chardemo-active-region.dta, replace
		restore
		
		// By ICNPO
		
		preserve
			keep regno icnpo active*
			reshape long active , i(regno) j(year)
			collapse (sum) active*, by(year icnpo)
			sort year icnpo
			sav $path1\chardemo-active-icnpo.dta, replace
		restore
	
	
	** Deaths
	
	preserve
		collapse (count) freq, by(diss_year)
		sort diss_year
		rename freq deaths
		rename diss_year year
		sav $path1\chardemo-deregistrations.dta, replace
	restore
	
		// By region
		
		preserve
			drop if region > 10
			collapse (count) freq, by(diss_year region)
			sort diss_year region
			rename freq deaths
			rename diss_year year
			sav $path1\chardemo-deregistrations-region.dta, replace
		restore
		
		// By ICNPO
		
		preserve
			collapse (count) freq, by(diss_year icnpo)
			sort diss_year icnpo
			rename freq deaths
			rename diss_year year
			sav $path1\chardemo-deregistrations-icnpo.dta, replace
		restore
	
	
	** Survival 
	
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
	
		// By region
		
		preserve
			collapse (sum) survived*, by(reg_year region)
			sort reg_year region
			rename reg_year year
			sav $path1\chardemo-survivals-region.dta, replace
		restore
	
		// By ICNPO
	
		preserve
			collapse (sum) survived*, by(reg_year icnpo)
			sort reg_year icnpo
			rename reg_year year
			sav $path1\chardemo-survivals-icnpo.dta, replace
		restore
	
	
	** High-growth organisations
	/*
		All enterprises with average annualised growth greater than 20% per annum, over a three year period (ONS definition).
		
		Can only calculate this measure for organisations established as recently as 2016.
		
		[NB] Alternative Operationalisation: number of charities (all, not just new) in a given year that experienced high growth
		e.g., 2019 figures would include charities active that year that grew more than 20% on average between 2016-2019.
	*/

	preserve
		keep regno FH_income_def*
		reshape long FH_income_def, i(regno) j(year)
		drop if FH_income_def==.
		tsset regno year

		capture drop *_apg
		bys regno: gen inc_apg = (((FH_income_def + 1) - (FH_income_def[_n-1])) / (FH_income_def[_n-1])) * 100 if FH_income_def[_n-1] >= 1000
		drop if inc_apg==.
		bys regno: gen inc_apg_mean = (inc_apg + inc_apg[_n-1] + inc_apg[_n-2]) / 3

		gen hgorg = (inc_apg_mean > 20 & inc_apg_mean!=.)
		keep regno hgorg year
		*duplicates drop regno, force
		
		collapse (sum) hgorg, by(year)
		sort year
		sav $path1\chardemo-hgorg.dta, replace
	restore
	
		/*
		// By region
		
		preserve
			collapse (sum) hgorg, by(reg_year region)
			sort reg_year region
			rename reg_year year
			sav $path1\chardemo-hgorg-region.dta, replace
		restore
		
		// By ICNPO
		
		preserve
			collapse (sum) hgorg, by(reg_year icnpo)
			sort reg_year icnpo
			rename reg_year year
			sav $path1\chardemo-hgorg-icnpo.dta, replace
		restore
		*/
	
	
	** Income dominance
	/*
		% of total income accounted for by top 100 or 1% of charities.
	*/

	// Base datasets
	
	keep regno scale region icnpo FH_income_def*
	gen freq = 1
	drop if icnpo=="Grant-making foundations"
	reshape long FH_income_def, i(regno) j(year)
	drop if FH_income_def==. | FH_income_def <= 0
	
	bys year: egen inc_rank = rank(FH_income_def), field
	gen top100 = 0
	bys year: replace top100 = 1 if inc_rank <= 100
	
	bys year: egen inc_pctile = pctile(FH_income_def), p(99)
	gen top1pc = 0
	bys year: replace top1pc = 1 if FH_income_def >= inc_pctile
	
	foreach var in region icnpo scale {
		bys year `var': egen inc_rank_`var' = rank(FH_income_def), field
		gen top100_`var' = 0
		bys year `var': replace top100_`var' = 1 if inc_rank_`var' <= 100
		
		bys year `var': egen inc_pctile_`var' = pctile(FH_income_def), p(99)
		gen top1pc_`var' = 0
		bys year `var': replace top1pc_`var' = 1 if FH_income_def >= inc_pctile_`var'
	}
	
	sav $path1\topinc-base.dta, replace
	
	// Total sector income per year
	
	collapse (count) freq (sum) FH_income_def , by(year) // calculate total income per year
	sort year
	rename freq orgs
	rename FH_income_def inc_total
	sav $path1\chardemo-total-income.dta, replace
	
		// By covariates
		
		foreach var in region icnpo scale {
			use $path1\topinc-base.dta, clear
			collapse (count) freq (sum) FH_income_def , by(year `var') // calculate total income per year
			sort year
			rename freq orgs
			rename FH_income_def inc_total_`var'
			sav $path1\chardemo-total-income-`var'.dta, replace
		}

	
		// Top 100 and 1%
			
		use $path1\topinc-base.dta
			
		collapse (count) freq (sum) FH_income_def, by(year top100)
		sort year
		drop if top100==0
		rename FH_income_def inc_top100
		rename freq orgs
		sav $path1\chardemo-top100.dta, replace		
			
		use $path1\topinc-base.dta, clear
		collapse (count) freq (sum) FH_income_def, by(year top1pc)
		sort year
		drop if top1pc==0
		rename FH_income_def inc_top1pc
		rename freq orgs
		sav $path1\chardemo-top1pc.dta, replace	
		
		foreach var in region icnpo scale {
			use $path1\topinc-base.dta, clear
			collapse (count) freq (sum) FH_income_def, by(year `var' top1pc_`var')
			sort year `var'
			drop if top1pc_`var'==0 | missing(`var')
			rename FH_income_def inc_top1pc_`var'
			rename freq orgs
			sav $path1\chardemo-top1pc_`var'.dta, replace	
		}
		
		foreach var in region icnpo scale {
			use $path1\topinc-base.dta, clear
			collapse (count) freq (sum) FH_income_def, by(year `var' top100_`var')
			sort year
			drop if top100_`var'==0 | missing(`var')
			rename FH_income_def inc_top100_`var'
			rename freq orgs
			sav $path1\chardemo-top100_`var'.dta, replace	
		}
		
		
	// Merge datasets
	
	use $path1\chardemo-total-income.dta, clear
	merge 1:1 year using $path1\chardemo-top100.dta, keep(match master) keepus(inc_top100)
	drop _merge
	merge 1:1 year using $path1\chardemo-top1pc.dta, keep(match master) keepus(inc_top1pc)
	drop _merge

	gen top100_share = (inc_top100 / inc_total)*100
	gen top1pc_share = (inc_top1pc / inc_total)*100
	
	sort year
	sav $path1\chardemo-total-inc-shares.dta, replace
		

	** Merge summary datasets **
	
	use $path1\chardemo-registrations.dta, clear
	merge 1:1 year using $path1\chardemo-deregistrations.dta, keep(match master)
	drop _merge
	merge 1:1 year using $path1\chardemo-survivals.dta, keep(match master)
	drop _merge
	merge 1:1 year using $path1\chardemo-active.dta, keep(match master)
	drop _merge
	merge 1:1 year using $path1\chardemo-hgorg.dta, keep(match master)
	drop _merge
	merge 1:1 year using $path1\chardemo-total-inc-shares.dta, keep(match master)
	drop _merge
	
	
	** Create derived variables **
	/*
		Need to make a decision about the use of `active` charities as the demoninator.
		
		For example, a death means a charity was removed from the Register, not that it
		did not submit a non-zero return that year.
		
		SOLUTION: use `population` instead for now.
	*/
	
	** Population
	/*
		All charities listed on Register at end of particular year.
	*/
	
	gen constant = 1
	gen net_births = births - deaths
	bysort constant (year) : gen population = sum(net_births)
	
	
	** Churn
	/*
		births + deaths / population[_n-1]
	*/
	
	gen churn = ((births + deaths) / population[_n-1]) * 100
	
	
	** Birth and death rates
	/*
		Proportion of births/deaths to populatoin.
		
		Should it be active charities in the previous year? YES
	*/
	
	gen birth_rate = (births / population[_n-1]) * 100
	gen death_rate = (deaths / population[_n-1]) * 100
	
	
	** High growth rate
	/*
		Use `active` as the baseline.
	*/
	
	gen hg_rate = (hgorg / active) * 100
	
	
	** Survival rate
	
	forvalues i = 1/60 {
		gen survived_`i'_rate = (survived_`i' / births)
	}
	
	
	** Final tasks **
	
	drop if year==.
	drop constant
	
	
compress
datasignature set, reset
sav $path3\chardemo-statistics.dta, replace
export delimited using $path3\chardemo-statistics.csv, replace


		// Regional and field breakdowns
		
		foreach var in region icnpo {
		
			** Merge summary datasets **
		
			use $path1\chardemo-registrations-`var'.dta, clear
			merge 1:1 year `var' using $path1\chardemo-deregistrations-`var'.dta, keep(match master)
			drop _merge
			merge 1:1 year `var' using $path1\chardemo-survivals-`var'.dta, keep(match master)
			drop _merge
			merge 1:1 year `var' using $path1\chardemo-active-`var'.dta, keep(match master)
			drop _merge
			merge 1:1 year `var' using $path1\chardemo-hgorg-`var'.dta, keep(match master)
			drop _merge
			
			
			** Create derived variables **
			
			// Population
			
			sort `var' year
			gen net_births = births - deaths
			bys `var' : gen population = sum(net_births)
			
			
			// Churn
			/*
				births + deaths / population[_n-1]
			*/
			
			gen churn = (births + deaths) / population[_n-1]
			
			
			// Birth and death rates - proportion of births/deaths to active charities
	
			gen birth_rate = (births / population) * 100
			gen death_rate = (deaths / population) * 100
			
			
			// Survival rate
			
			forvalues i = 1/60 {
				gen survived_`i'_rate = (survived_`i' / births)
			}
			
			
			** Final tasks **
			
			drop if year==. | missing(`var')			
			
			compress
			datasignature set, reset
			sav $path3\chardemo-statistics-`var'.dta, replace
			export delimited using $path3\chardemo-statistics-`var'.csv, replace
		}
		

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
