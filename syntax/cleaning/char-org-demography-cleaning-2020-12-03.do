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

global dfiles "C:\Users\mcdonndz-local\Dropbox" // location of data files
global rfiles "C:\Users\mcdonndz-local\Dropbox\projects\charity-covid19" // location of syntax and other project outputs
global gfiles "C:\Users\mcdonndz-local\Dropbox\projects\charity-covid19\docs" // location of graphs
global ccewfiles "C:\Users\mcdonndz-local\Dropbox\esrc-finvul-data\data-raw"
include "$rfiles\syntax\stata-file-paths.doi"


/** 1. Data Cleaning **/
/*
	Take the masterfile of charities provided by DC and produce yearly statistics a la the ONS'
	Business Demography statistics.
	
	Issues:
		- Switch to deflated income figures (for calculating growth rates, initial organisation size)
		- Use a common name for income variable (saves me changing from FH_income to FH_income_def throughout the script)
*/

/** Excess events analysis **/
/*
	Move this section into the other do file in due course.
	
	Think very carefully about what measures are useful (those found or derived from public data); need to decide
	what to do about ICNPO for 2020 (unclassified in master dataset) - speak to CD about work.
*/

use $ccewfiles\ccew-apr2021.dta, clear
desc, f
count

	** Keep relevant variables **
	
	capture rename cceid regno
	duplicates drop regno, force
	
	keep regno isreg reg_year diss_year reg_date diss_date region scale icnpo_ncvo_category FH_income*
	drop *_def*
	
	replace icnpo_ncvo_category="Other" if icnpo_ncvo_category=="Playgroups and nurseries" | icnpo_ncvo_category=="Scout groups and youth clubs" ///
		| icnpo_ncvo_category=="NULL" | icnpo_ncvo_category=="Parent Teacher Associations" | icnpo_ncvo_category=="Village Halls"
	*encode icnpo_ncvo_category, gen(icnpo_ncvo_category_num)
	rename icnpo_ncvo_category icnpo
	
	
	** Initial analyses **
	/*
		- Distributions of new/dissolved charities over time (from two perspectives: annually and categorically).
		- Discontinuities in trends over time.
		- Want to bring in financial data (linked to dissolution)?
		
		If picture is largely one of stability e.g., same types of charities created in 2020 as previous years,
		then where did the variation occur (must be some regions, types of charities that have been drastically impacted)?
	*/
	
	foreach var in icnpo region scale {
		tab `var' reg_year if reg_year > 2014 & reg_year!=., col all
		tab `var' diss_year if diss_year > 2014 & diss_year!=., col all
	}
	

/** Business demography statistics **/

use $ccewfiles\ccew-apr2021.dta, clear
desc, f
count

	** Keep relevant variables **
	
	capture rename cceid regno
	duplicates drop regno, force
	
	keep regno isreg reg_year diss_year reg_date diss_date region scale icnpo_ncvo_category FH_income*
	drop *_def*
	
	replace icnpo_ncvo_category="Other" if icnpo_ncvo_category=="Playgroups and nurseries" | icnpo_ncvo_category=="Scout groups and youth clubs" ///
		| icnpo_ncvo_category=="NULL" | icnpo_ncvo_category=="Parent Teacher Associations" | icnpo_ncvo_category=="Village Halls"
	*encode icnpo_ncvo_category, gen(icnpo_ncvo_category_num)
	rename icnpo_ncvo_category icnpo

	
	// Period
	
	gen period = reg_year
	recode period min/1944=1 1945/1965=2 1966/1978=3 1979/1992=4 1993/max=5 *=.
	label define period_label 1 "Pre-1945" 2 "1945-1965" 3 "1966-1978" 4 "1979-1992" 5 "Post-1993"
	label values period period_label
	tab period, miss

	
	// Organisation age
	
	/*
	gen orgage = cond(diss_year==., 2021 - reg_year, diss_year - reg_year)
	egen orgage_cat = cut(orgage), at(0 10 25 50 100)
	sum orgage
	label define orgage_lab 0 "0-10 Years" 10 "10-25 Years" 25 "25-50 Years" 50 "More than 50 Years"
	label values orgage_cat orgage_lab
	tab orgage_cat
	*/
	
	forvalues yr = 1995/2020 {
		gen orgage`yr' = cond(diss_year==., `yr' - reg_year, ///
			cond(diss_year==`yr', diss_year - reg_year, ///
				cond(diss_year > `yr', `yr' - reg_year, .)))
		*label values orgage`yr' orgage_lab
	}
	/*
		Tackle issue of age bands (currently using raw age).
	*/
	
	
	// Organisation size
	
	label define orgsize_lab 1 "Under £10k" 2 "£10k-£100k" 3 "£100k-£500k" 4 "£500k-£1m" 5 "£1m-£10m" 6 "£10m-£100m" 7 "Over £100m" 

	forvalues yr = 1995/2020 {
		gen orgsize`yr' = FH_income`yr'
		recode orgsize`yr' min/9999=1 10000/99999=2 100000/499999=3 500000/999999=4 1000000/9999999=5 10000000/99999999=6 100000000/max=7 *=.
		label values orgsize`yr' orgsize_lab
		tab orgsize`yr'
	}
	
	
	// Indicators 
	
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
	
		// By covariates - orgsize and orgage not sensible when speaking about births
		
		foreach var in icnpo region scale period {
			preserve
				collapse (count) freq, by(reg_year `var')
				sort reg_year `var'
				rename freq births
				rename reg_year year
				sav $path1\chardemo-registrations-`var'.dta, replace
			restore
		}
		
		
	** Active
	/*
		Number of charities filing a non-zero annual return at time t.
	*/
	
	forvalues yr = 1995/2020 {
		gen active`yr' = (FH_income`yr'!=. & FH_income`yr' > 0)
	}
	
	sav $path1\tmp-data.dta, replace
	
	preserve
		keep regno active*
		reshape long active , i(regno) j(year)
		collapse (sum) active, by(year)
		sort year
		sav $path1\chardemo-active.dta, replace
	restore
	
		// By covariates
		
		foreach var in icnpo region scale period {
			preserve
				keep regno `var' active*
				reshape long active , i(regno) j(year)
				collapse (sum) active, by(year `var')
				sort year `var'
				sav $path1\chardemo-active-`var'.dta, replace
			restore
		}
	
		foreach var in orgsize orgage {
			preserve
				keep regno `var'* active*
				reshape long active `var' , i(regno) j(year)
				collapse (sum) active, by(year `var')
				sort year `var'
				sav $path1\chardemo-active-`var'.dta, replace
			restore
		}
	
	** Deaths
	
	preserve
		collapse (count) freq, by(diss_year)
		sort diss_year
		rename freq deaths
		rename diss_year year
		sav $path1\chardemo-deregistrations.dta, replace
	restore
	
		// By covariates
		
		foreach var in icnpo region scale period {
			preserve
				collapse (count) freq, by(diss_year `var')
				sort diss_year `var'
				rename freq deaths
				rename diss_year year
				sav $path1\chardemo-deregistrations-`var'.dta, replace
			restore
		}
			
		forvalues yr = 1996/2020 {
			foreach var in orgsize orgage {
				preserve
					keep if diss_year==`yr'
					local prevyr = `yr' - 1
					di "`var'`prevyr'"
					collapse (count) freq, by(diss_year `var'`prevyr')
					sort diss_year `var'`prevyr'
					rename freq deaths
					rename diss_year year
					rename `var'`prevyr' `var'
					drop if `var'==.
					sav $path1\chardemo-deregistrations-`var'-`yr'.dta, replace
				restore
			}
		}
		/*
			Looks correct but need to apply some formal checks and tests (e.g., use 'pres' variables).
		*/
	
	** Survival
	
	gen orgage = cond(diss_year==., 2021 - reg_year, diss_year - reg_year)
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
	
		// By covariates
		
		foreach var in icnpo region scale period {
			preserve
				collapse (sum) survived*, by(reg_year `var')
				sort reg_year `var'
				rename reg_year year
				sav $path1\chardemo-survivals-`var'.dta, replace
			restore
		}
	
		/*
		foreach var in orgsize orgage {
			preserve
				keep regno `var'* survived*
				reshape long survived `var' , i(regno) j(year)
				collapse (sum) survived, by(year `var')
				sort year `var'
				sav $path1\chardemo-survivals-`var'.dta, replace
			restore
		}
		*/
	
	** High-growth organisations
	/*
		All enterprises with average annualised growth greater than 20% per annum, over a three year period (ONS definition).
		
		Can only calculate this measure for organisations established as recently as 2016.
		
		[NB] Alternative operationalisation: number of charities (all, not just new) in a given year that experienced high growth
		e.g., 2019 figures would include charities active that year that grew more than 20% on average between 2016-2019.
	*/

	preserve
		keep regno FH_income*
		reshape long FH_income, i(regno) j(year)
		drop if FH_income==.
		tsset regno year

		capture drop *_apg
		bys regno: gen inc_apg = (((FH_income + 1) - (FH_income[_n-1])) / (FH_income[_n-1])) * 100 if FH_income[_n-1] >= 1000
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

	// Base datasets - add orgage and orgsize
	
	keep regno scale region icnpo period FH_income*
	gen freq = 1
	drop if icnpo=="Grant-making foundations"
	reshape long FH_income, i(regno) j(year)
	drop if FH_income==. | FH_income <= 0
	
	bys year: egen inc_rank = rank(FH_income), field
	gen top100 = 0
	bys year: replace top100 = 1 if inc_rank <= 100
	
	bys year: egen inc_pctile = pctile(FH_income), p(99)
	gen top1pc = 0
	bys year: replace top1pc = 1 if FH_income >= inc_pctile
	
	foreach var in icnpo region scale period {
		bys year `var': egen inc_rank_`var' = rank(FH_income), field
		gen top100_`var' = 0
		bys year `var': replace top100_`var' = 1 if inc_rank_`var' <= 100
		
		bys year `var': egen inc_pctile_`var' = pctile(FH_income), p(99)
		gen top1pc_`var' = 0
		bys year `var': replace top1pc_`var' = 1 if FH_income >= inc_pctile_`var'
	}
	
	sav $path1\topinc-base.dta, replace
	
	// Total sector income per year
	
	collapse (count) freq (sum) FH_income , by(year) // calculate total income per year
	sort year
	rename freq orgs
	rename FH_income inc_total
	sav $path1\chardemo-total-income.dta, replace
	
		// By covariates
		
		foreach var in icnpo region scale period {
			use $path1\topinc-base.dta, clear
			collapse (count) freq (sum) FH_income , by(year `var') // calculate total income per year
			sort year
			rename freq orgs
			rename FH_income inc_total_`var'
			sav $path1\chardemo-total-income-`var'.dta, replace
		}

	
		// Top 100 and 1%
			
		use $path1\topinc-base.dta
			
		collapse (count) freq (sum) FH_income, by(year top100)
		sort year
		drop if top100==0
		rename FH_income inc_top100
		rename freq orgs
		sav $path1\chardemo-top100.dta, replace		
			
		use $path1\topinc-base.dta, clear
		collapse (count) freq (sum) FH_income, by(year top1pc)
		sort year
		drop if top1pc==0
		rename FH_income inc_top1pc
		rename freq orgs
		sav $path1\chardemo-top1pc.dta, replace	
		
		foreach var in icnpo region scale period {
			use $path1\topinc-base.dta, clear
			collapse (count) freq (sum) FH_income, by(year `var' top1pc_`var')
			sort year `var'
			drop if top1pc_`var'==0 | missing(`var')
			rename FH_income inc_top1pc_`var'
			rename freq orgs
			sav $path1\chardemo-top1pc_`var'.dta, replace	
		}
		
		foreach var in icnpo region scale period {
			use $path1\topinc-base.dta, clear
			collapse (count) freq (sum) FH_income, by(year `var' top100_`var')
			sort year
			drop if top100_`var'==0 | missing(`var')
			rename FH_income inc_top100_`var'
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
		
		SOLUTION: use `population` instead for now. Create alternative measure as well.
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
	gen churn_alt = ((births + deaths) / active[_n-1]) * 100
	
	
	** Birth and death rates
	/*
		Proportion of births/deaths to population.
		
		Should it be active charities in the previous year? YES
	*/
	
	gen birth_rate = (births / population[_n-1]) * 100
	gen death_rate = (deaths / population[_n-1]) * 100
	gen birth_rate_alt = (births / active[_n-1]) * 100
	gen death_rate_alt = (deaths / active[_n-1]) * 100
	
	
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


		** Covariate breakdowns **
		
		// Size and age
		
		foreach var in orgsize orgage {
			clear
			set obs 0
			forvalues yr = 1996/2020 {
				append using $path1\chardemo-deregistrations-`var'-`yr'.dta, force 
			}
			merge 1:1 year `var' using $path1\chardemo-active-`var'.dta, keep(match master)
			drop _merge
			sort `var' year
			
			// Death rates
			
			gen death_rate_alt = (deaths / active[_n-1]) * 100
				
			sav $path3\chardemo-statistics-`var'.dta, replace
			export delimited using $path3\chardemo-statistics-`var'.csv, replace
		}
		
		// Period
		
		use $path1\chardemo-deregistrations-period.dta, clear
		merge 1:1 year period using $path1\chardemo-active-period.dta, keep(match master)
		drop _merge
		sort period year
					
		gen death_rate_alt = (deaths / active[_n-1]) * 100
			
		sav $path3\chardemo-statistics-period.dta, replace
		export delimited using $path3\chardemo-statistics-period.csv, replace
		
		
		// Field of activity, region and scale of operation
		
		foreach var in icnpo region scale {
		
			** Merge summary datasets **
		
			use $path1\chardemo-registrations-`var'.dta, clear
			merge 1:1 year `var' using $path1\chardemo-deregistrations-`var'.dta, keep(match master)
			drop _merge
			merge 1:1 year `var' using $path1\chardemo-survivals-`var'.dta, keep(match master)
			drop _merge
			merge 1:1 year `var' using $path1\chardemo-active-`var'.dta, keep(match master)
			drop _merge
			*merge 1:1 year `var' using $path1\chardemo-hgorg-`var'.dta, keep(match master)
			*drop _merge
			
			
			** Create derived variables **
			
			// Population
			
			sort `var' year
			gen net_births = births - deaths
			bys `var' : gen population = sum(net_births)
			
			
			// Churn
			/*
				births + deaths / population[_n-1]
			*/
			
			gen churn = ((births + deaths) / population[_n-1]) * 100
			gen churn_alt = ((births + deaths) / active[_n-1]) * 100
			
			
			// Birth and death rates
			/*
				Proportion of births/deaths to population.
				
				Should it be active charities in the previous year? YES
			*/
			
			gen birth_rate = (births / population[_n-1]) * 100
			gen death_rate = (deaths / population[_n-1]) * 100
			gen birth_rate_alt = (births / active[_n-1]) * 100
			gen death_rate_alt = (deaths / active[_n-1]) * 100
			
			
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
