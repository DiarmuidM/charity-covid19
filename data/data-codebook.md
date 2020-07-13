# Codebook

The following is a codebook for the data contained in the *monthly statistics* CSV data sets.

Variable | Type | Description
--- | --- | ---
country | string | Country or jurisdiction figures refer to
period | date | Month and year figures refer to
reg_count | integer | Number of registrations recorded for that period
reg_count_cumu | integer | Running total of `reg_count`
reg_avg | integer | Mean number of registrations recorded for that period between 2015-2019
reg_avg_cumu | integer | Running total of `reg_avg`
reg_excess | integer | Difference between observed and expected number of registrations (`reg_count - reg_avg`)
reg_excess_per | integer | Difference between observed and expected number of registrations, expressed as a percentage of expected registrations
reg_excess_cumu | integer | Running total of `reg_excess`
reg_excess_cumu_per | integer | Difference between total number of observed and expected registrations, expressed as a percentage of total expected registrations
rem_count | integer | Number of de-registrations recorded for that period
rem_count_cumu | integer | Running total of `rem_count`
rem_avg | integer | Mean number of de-registrations recorded for that period between 2015-2019
rem_avg_cumu | integer | Running total of `rem_avg`
rem_excess | integer | Difference between observed and expected number of de-registrations (`rem_count - rem_avg`)
rem_excess_per | integer | Difference between observed and expected number of de-registrations, expressed as a percentage of expected de-registrations
rem_excess_cumu | integer | Running total of `rem_excess`
rem_excess_cumu_per | integer | Difference between total number of observed and expected de-registrations, expressed as a percentage of total expected de-registrations