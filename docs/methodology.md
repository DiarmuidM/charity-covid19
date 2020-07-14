---
layout: default
title: "Methodology"
permalink: /methodology/
---

<p style="text-align:center;"><a href="https://diarmuidm.github.io/charity-covid19">Home</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://diarmuidm.github.io/charity-covid19/data">Data</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://diarmuidm.github.io/charity-covid19/methodology">Methodology</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://diarmuidm.github.io/charity-covid19/blog">Blog</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://diarmuidm.github.io/charity-covid19/contact">Contact</a></p>

# Methodology

## Data Collection

This project uses publicly available data on charity registrations (foundations) and de-registrations (dissolutions) from seven charity jurisdictions. We use a programming script, written in the popular [Python](https://www.python.org/) language, to collect data for each jurisdiction. The exception is Canada, where the data are manually downloaded using the public search facility here: [ [LINK] ](https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyBscSrch?request_locale=en).

More information on our data sources can be found here: [ [LINK] ]({{site.url}}/data)

The data collection script can be found here: [ [LINK] ](https://github.com/DiarmuidM/charity-covid19/tree/master/syntax/collection)

## Data Cleaning

Each data set is loaded into the statistical software package Stata, where the following general processes are implemented:
1. Collapse the data down to monthly observations i.e., each row in the data represents a month.
2. For each month, calculate the number of charities:
	* registered
	* de-registered
3. Create additional measures, such as:
	* average number of registrations/de-registrations per month
	* excess number of registrations/de-registrations per month, etc
4. Save and export to CSV for sharing

## Data Analysis

The analysis is based on an “excess events” analytical approach, comparing the numbers of registrations and de-registrations in 2020 to what we would expect based on the trends from previous years. For example, let's say there were 50 new charities registered in Scotland in January 2020 - is that number large or small, expected or unexpected based on previous figures for January? 

Month | Number of new charities
--- | --- | ---
January 2015 | 60
January 2016 | 55
January 2017 | 82
January 2018 | 65
January 2019 | 75

The average number of new charities in January between 2015-2019 is: (60 + 55 + 82 + 65 + 75) / 5 = 67. So there are 17 fewer new charities in January 2020 compared to the average for 2015-2019. Of course, the figures for January vary each year, and thus we need to know if the figure for January 2020 falls outside the **range** of expected registrations for that month. Therefore we calculate the standard deviation of the average, which is 10, and use this to construct the range: 57 to 77 (i.e., 67 +- 10). So there are fewer new charities in January 2020 than we would expect.