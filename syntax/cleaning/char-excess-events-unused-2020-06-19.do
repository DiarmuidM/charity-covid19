

global dfiles "C:\Users\t95171dm\Dropbox" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-covid19" // location of syntax and outputs

include "$rfiles\syntax\stata-file-paths.doi"

	
	
	
	

/* Produce cleaned Register */

use $path1\scot-all-data-2020-06.dta, clear
desc, f
codebook, compact

	
	** Data cleaning
	
	// Charitable purposes
	
	codebook purposes // 101 charities with no values for this variable.
	tab purposes, sort
	split purposes, p(',)

		// Now for some tidying up before I do a count of each charitable purpose mentioned:
		
		local counter = 1
		foreach var of varlist purposes1-purposes16 {
			gen charitablepurposes`counter' = subinstr(`var'," ","",.)
			replace charitablepurposes`counter' = subinstr(charitablepurposes`counter',"'","",.)
			replace charitablepurposes`counter' = subinstr(charitablepurposes`counter',",","",.)
			replace charitablepurposes`counter' = strlower(charitablepurposes`counter')
			drop `var'
			local counter = `counter' + 1
		}	
		
		local charpurplist = "AdvancementOfAnimalWelfare AdvancementOfCitizenshipOrCommunityDevelopment AdvancementOfEducation AdvancementOfEnvironmentalProtectionOrImprovement AdvancementOfHealth AdvancementOfHumanRightsConflictResolution AdvancementOfPublicParticipationInSport AdvancementOfReligion AdvancementOfTheArtsHeritageCultureOrScience Other PreventionOfPoverty PromotionOfEqualityAndDiversity PromotionOfReligiousOrRacialHarmony ProvisionOfRecreationalFacilities ReliefOfThoseInNeed SavingOfLives"
		forvalues cpvarcounter = 1(1)16 {
			local counter=1
			gen cpresponse`cpvarcounter'=0
			foreach cpitem in `charpurplist' {
				replace cpresponse`cpvarcounter'=`counter' if charitablepurposes`cpvarcounter'=="`cpitem'"
				local counter = `counter' + 1
			 }
		}

		forvalues i = 1(1)16 {
			egen charpurp`i' = count(cpresponse1-cpresponse16) if cpresponse1==`i' | cpresponse2==`i' | cpresponse3==`i' | cpresponse4==`i' | cpresponse5==`i' | cpresponse6==`i' | cpresponse7==`i' | cpresponse8==`i' | cpresponse9==`i' | cpresponse10==`i' | cpresponse11==`i' | cpresponse12==`i' | cpresponse13==`i' | cpresponse14==`i' | cpresponse15==`i' | cpresponse16==`i'
			tab charpurp`i'
		}
		
		sum charpurp*
		
		// Create a dummy variable indicating the presence of each purpose:
		
		foreach var of varlist charpurp1-charpurp16 {
			quietly levelsof `var'
			local num = r(N)
			recode `var' `num'=1 *=0 if CharitablePurposes!=""
			tab `var'
		}


	
	/* Cases in the dataset that should be excluded */
	
	list if charitynumber=="SC000036" | charitynumber=="SC000107" // These are dummy charities created by OSCR; no longer in dataset.
	
	
	/* Variables in the dataset that should be excluded */
			
	codebook principaloffice* // Contains confidential information relating to the principal contact (including postcode) - drop all.
	drop principaloffice*
	
	codebook knownas // Same as LegalName, no need for it - drop.
	drop knownas
	
	codebook website // No need for this variable.
	drop website
	desc, f

	codebook objectives // Qualitative information - drop.
	drop objectives
	
	
	/* Check for duplicates */

	duplicates report charitynumber
	duplicates list charitynumber // some duplicates for charity number
	duplicates tag charitynumber, gen(duptag)
	replace charitynumber="" if duptag==1
			
		
	/* Check for missing values */
	
	codebook, compact
	mdesc
	/*
		Nothing worth worrying about: most variables have a valid reason for having with lots of missing values.
	*/
	
	
	/* Impossible, invalid or otherwise incorrect values for variables */

	
	// Create a numeric version of charity number
	gen charnumber = substr(charitynumber, 3, .) // Create a numeric variable from charity number i.e. remove the "SC" at the beginning of each number. This is necessary in order to work with the data in a panel format.
	list charnumber in 1/100
	codebook charnumber
	replace charnumber = "" if missing(real(charnumber)) // Set nonnumeric instances of regno as missing
	destring charnumber, replace

	
	codebook charitystatus
	tab charitystatus
	encode charitystatus, generate(status)
	tab status, nolab
	drop if status < 43
	recode status 43=1 44=2 45=3 46=4
	numlabel _all, add
	label define status_label 1 "Active" 2 "Not Monitored" 3 "Not Submitted" 4 "Removed"
	label values status status_label
	tab status
	drop charitystatus
	
	
	// Convert to date
	
	gen regd_str = substr(registereddate, 1, 10)
	gen regd = date(regd_str, "DMY")
	format regd %td
	gen regy = year(regd)
	gen regq = qofd(regd)
	gen regm = mofd(regd)
	gen newreg = (regm >= tm(2020m3)) if status==1
	format regq %tq
	format regm %tm
	tab1 regq regm newreg
	
	gen remd_str = substr(ceaseddate, 1, 10)
	gen remd = date(remd_str, "DMY")
	format remd %td
	gen remy = year(remd)
	gen remq = qofd(remd)
	gen remm = mofd(remd)
	gen newrem = (remm >= tm(2020m3)) if status==4
	format remq %tq
	format remm %tm
	tab1 remq remm newrem
	

	// Constitutional form
	
	encode constitutionalform, generate(conform)
	tab constitutionalform conform
	numlabel conform, add
	label define conform_lab 1 "CIO" 2 "Community Benefit Society" 3 "Company" 4 "Education Endowment" 5 "Other" ///
	6 "Registered Society" 7 "SCIO" 8 "Statutory Corporation" 9 "Trust" 10 "Unincorporated Association"
	label values conform conform_lab
	tab conform, miss // Quite a lot of missing data for this variable. Explore in more depth:
		list charnumber status remd if conform==.
		tab status if conform==. 
		tab remd if conform==., sort 
		/* 
			All of these charities have been removed and on the default removed date. They represent charities OSCR removed when they took over the Charity Index - drop.
			
			TASK: Confirm the above statement is correct with LM.
			RESPONSE: Correct, these are charities for which OSCR has no data.
		*/
		drop if conform==.
	drop constitutionalform
	
		// Create SCIO identifier
		
		gen scio = (conform==7)
		tab scio

	
	encode mainoperatinglocation, gen(mainoplocation)
	numlabel _all, add
	tab mainoplocation
	drop mainoperatinglocation
	
		// Not Scotland identifier
		
		gen outwith = (mainoplocation==23)
		tab outwith
	

				
	// Do the same for beneficiary groups:
		
	codebook BeneficiaryGroups
	split BeneficiaryGroups, p(",")

	local counter = 1
	foreach var of varlist BeneficiaryGroups1-BeneficiaryGroups7 {
		gen beneficiarygroups`counter'=subinstr(`var'," ","",.)
		drop `var'
		local counter = `counter' + 1
	}	

	local bengrouplist = "ChildrenAndYoungPeople NoSpecificGroup OlderPeople OtherCharitiesAndVoluntaryBodies OtherDefinedGroups PeopleOfParticularEthnicOrRacialOrigin PeopleWithDisabilitiesOrHealthProblems"

		forvalues bgvarcounter = 1(1)7 {
			local counter=1
			gen bgresponse`bgvarcounter'=0
			foreach bgitem in `bengrouplist' {
				di "`bgitem' response`bgvarcounter' `counter'"
				di "replace response`bgvarcounter'=`counter' if beneficiarygroups`bgvarcounter'==`bgitem'"
				replace bgresponse`bgvarcounter'=`counter' if beneficiarygroups`bgvarcounter'=="`bgitem'"
				local counter = `counter' + 1
			 }
	  }

		 forvalues i = 1(1)7 {
			egen bengroup`i' = count(bgresponse1-bgresponse7) if bgresponse1==`i' | bgresponse2==`i' | bgresponse3==`i' | bgresponse4==`i' | bgresponse5==`i' | bgresponse6==`i' | bgresponse7==`i'
			tab bengroup`i'
		}
			  
		sum bengroup*
				
		// Create a dummy variable indicating the presence of each group:
		
		foreach var of varlist bengroup1-bengroup7 {
			quietly levelsof `var'
			local num = r(N)
			recode `var' `num'=1 *=0 if BeneficiaryGroups!=""
			tab `var'
		}

	
	// Types of activities
	
	codebook TypesOfActivities
	tab TypesOfActivities
	split TypesOfActivities, p(",")
	
	foreach var of varlist TypesOfActivities1-TypesOfActivities4 {
		levelsof `var'
	}
	
	local actlist = "CarriesOutActivitiesOrServicesItself MakesGrantsToIndividuals MakesGrantsToOrganisations NoneOfThese"

	forvalues actcounter = 1(1)4 {
		local counter=1
		gen actresponse`actcounter'=0
		foreach actitem in `actlist' {
			di "`actitem' response`actcounter' `counter'"
			di "replace actresponse`actcounter'=`counter' if TypesOfActivities`actcounter'==`actitem'"
			replace actresponse`actcounter'=`counter' if TypesOfActivities`actcounter'=="`actitem'"
			local counter = `counter' + 1
			}
	}

		forvalues i = 1(1)4 {
			egen charact`i' = count(actresponse1-actresponse4) if actresponse1==`i' | actresponse2==`i' | actresponse3==`i' | actresponse4==`i'
			tab charact`i'
		}
		  
		sum charact*
				
		// Create a dummy variable indicating the presence of each group:
		
		foreach var of varlist charact1-charact4 {
			quietly levelsof `var'
			local num = r(N)
			recode `var' `num'=1 *=0 if TypesOfActivities!=""
			tab `var'
		}
		
		// Delete the unneccesary 'placeholder' and original variables for purposes, beneficiary groups and activities:
	drop bg* charitablepurposes* beneficiarygroups* Types* CharitablePurposes BeneficiaryGroups cp* act*	


/* OSCR Performance Indicators */

import delimited using $path2\oscr-performance-indicators.csv, varn(1) clear
sort event month
codebook

	rename event event_str
	encode event_str, gen(event)
	

	// Convert to date
	
	gen eventd = date(month, "YM")
	format eventd %td
	gen eventy = year(eventd)
	gen eventq = qofd(eventd)
	gen eventm = mofd(eventd)
	gen calendarm = month(eventd)
	format eventq %tq
	format eventm %tm
	tab1 eventq eventm
	
	
	// Calculate monthly figures
	
	gen rem = 1
	egen rem_count = sum(rem), by(remm)
	egen rem_avg  = mean(rem_count), by(month)
	egen rem_sd = sd(rem_count), by(month)
	gen rem_lb = rem_avg - rem_sd
	gen rem_ub = rem_avg + rem_sd
	foreach var of varlist rem_count-rem_ub {
		replace `var' = ceil(`var')
	}
	
	// Set as time series
	
	tsset event eventm
	tssmooth ma n_smooth = n, window(1 1)
	replace n_smooth = ceil(n_smooth)

	
	// Graphs
	
	local xmarker = tm(2020m3)
	
	twoway (line n eventm if event==1, lpatt(solid)) (line n eventm if event==2, lpatt(dash)) (line n eventm if event==3, lpatt(shortdash)) ///
		(line n_smooth eventm if event==1) , ///
		title("Event Trends") subtitle("By Event Type") ///
		ytitle("No. of applications") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		xline(`xmarker') ///
		legend(label(1 "Consents") label(2 "Registrations") label(3 "Reorganisation") label(4 "") rows(1) size(vsmall)) ///
		scheme(s1mono)
	
	twoway (line n_smooth eventm if event==1, lpatt(solid)) (line n_smooth eventm if event==2, lpatt(dash)) (line n_smooth eventm if event==3, lpatt(shortdash)) ///
		(line n_smooth eventm if event==1) , ///
		title("Event Trends") subtitle("By Event Type") ///
		ytitle("No. of applications (moving average)") xtitle("Month") ///
		ylab(, labsize(small)) xlab(, labsize(small)) ///
		xline(`xmarker') ///
		legend(label(1 "Consents") label(2 "Registrations") label(3 "Reorganisation") label(4 "") rows(1) size(vsmall)) ///
		scheme(s1mono)
	/*
		Not much good as it doesn't account for seasonality.
	*/
	
	
	// Modelling
	
	gen march = (calendarm==3)
	gen march2020 = (eventm==tm(2020m3))
	
	regress n eventm march if event==2
	regress n eventm march2020 if event==2
	regress n eventm march march2020 if event==2
	collin eventm march march2020 if event==2
*/
