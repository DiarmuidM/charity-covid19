# -*- coding: latin-1 -*-
"""
    Project: The impact of COVID-19 on the foundation and dissolution of charitable organisations
    
    Website: https://diarmuidm.github.io/charity-covid-19/
    
    Creator: Diarmuid McDonnell
    
    Collaborators: Alasdair Rutherford
    
    Date: 2020-06-30
    
    File: char-excess-events-collection-2020-06-30.py
    
    Description: This file downloads publicly available charity data relating to foundations and removals.
"""

# Import packages #

from datetime import datetime as dt
from bs4 import BeautifulSoup as soup
from time import sleep
from fimport import import_zip
import requests
import zipfile, io
import os
import argparse
import json
import random
import csv
import re
import pandas as pd


# TO DO #
#
# 1. Execute file_delete() for NI webpages.
# 2. Ensure all downloads go into data-DATE folder. [DONE]
# 3. Fix ew_download() [Possibly an issue with fimport] [DONE]
# 4. NI removals function not working properly. [DONE]
#


# Define functions #

# Test #

def test():
    """
        Function that is used to test whether virtual environment is configured correctly.

        Dependencies:
            - NONE

        Issues:
    """

    print("\r")
    print("Welcome to this data collection script.") 
    print("\r")
    with open("./test.txt", "a") as f:
        f.write("Successfully executed script")


def prelim():
    """
        Get the current date and create a folder to store the download.
    """

    ddate = dt.now().strftime("%Y-%m-%d")
    download = "data/" + ddate
    log = "data/" + ddate + "/log"
    print(download)

    if not os.path.isdir("data"):
        os.mkdir("data")
    else:
        print("Folder already exists")

    if not os.path.isdir(download):
        os.mkdir(download)
    else:
        print("Folder already exists")

    if not os.path.isdir(log):
        os.mkdir(log)
    else:
        print("Folder already exists")    

    return download, log, ddate


# Australia

def aus_download(basefolder, logfolder, ddate):
    """
        Downloads latest copy of the Register of Charities.

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Australian Charity Register")
    print("\r")


    # Create data folder

    dfolder = basefolder + "/aus"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder))  


    # Define output files

    mfile = logfolder + "/aus-roc-metadata-" + ddate + ".json"
    outfile = dfolder + "/aus-roc-" + ddate + ".xlsx" # Charity Register

    
    # Request file
    
    webadd = "https://data.gov.au/data/dataset/b050b242-4487-4306-abf5-07ca073e5594/resource/eb1e6be4-5b13-4feb-b28e-388bf7c26f93/download/datadotgov_main.xlsx"
    response = requests.get(webadd)
    print(response.status_code, response.headers)

    # Write metadata to file

    mdata = dict(response.headers)
    mdata["file"] = "Register of Charities"
    mdata["url"] = str(webadd)

    with open(mfile, "w") as f:
        json.dump(mdata, f)


    # Save files (data and metadata)

    if response.status_code==200: # if the file was successfully requested

        # Data

        if os.path.isfile(outfile): # do not overwrite existing file
            print("File already exists, no need to overwrite")
        else: # file does not currently exist, therefore create
            with open(outfile, "wb") as f:
                f.write(response.content)
        
        print("\r")    
        print("Successfully downloaded Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))

    else: # file was not successfully requested
        print("\r")    
        print("Unable to download Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))

    print("\r")
    print("Charity Register: '{}'".format(outfile))


#############################################################################################################

#############################################################################################################


# New Zealand

def nz_download(basefolder, logfolder, ddate):
    """
        Downloads latest copy of the Register of Charities.

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading New Zealand Charity Register")
    print("\r")


    # Create data folder

    dfolder = basefolder + "/nz"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder))    


    # Define output files

    mfile = logfolder + "/nz-roc-metadata-" + ddate + ".json"
    outfile = dfolder + "/nz-roc-" + ddate + ".csv" # Charity Register

    
    # Request file
    
    webadd = "http://www.odata.charities.govt.nz/vOrganisations?$returnall=true&$format=csv"
    response = requests.get(webadd)
    print(response.status_code, response.headers)

    # Write metadata to file

    mdata = dict(response.headers)
    mdata["file"] = "Register of Charities"
    mdata["url"] = str(webadd)

    with open(mfile, "w") as f:
        json.dump(mdata, f)


    # Save files (data and metadata)

    if response.status_code==200: # if the file was successfully requested

        # Data

        if os.path.isfile(outfile): # do not overwrite existing file
            print("File already exists, no need to overwrite")
        else: # file does not currently exist, therefore create
            with open(outfile, "wb") as f:
                f.write(response.content)
        
        print("\r")    
        print("Successfully downloaded Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))

    else: # file was not successfully requested
        print("\r")    
        print("Unable to download Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))

    print("\r")
    print("Charity Register: '{}'".format(outfile))


#############################################################################################################

#############################################################################################################


# United States of America

def usa_download(basefolder, logfolder, ddate):
    """
        Downloads latest copies of the masterfile of current nonprofits, and the 
        list of organisations that have had their nonprofit status revoked.

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading USA nonprofit data")
    print("\r")


    # Create data folder

    dfolder = basefolder + "/usa"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder))  


    exefile = logfolder + "/usa-exempt-metadata-" + ddate + ".json" # metadata for exempt nonprofits data file
    revfile = logfolder + "/usa-revoked-metadata-" + ddate + ".json"

    
    # Exempt nonprofits #

    busfile1 = 'https://www.irs.gov/pub/irs-soi/eo1.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 1
    busfile2 = 'https://www.irs.gov/pub/irs-soi/eo2.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 2
    busfile3 = 'https://www.irs.gov/pub/irs-soi/eo3.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 3
    busfile4 = 'https://www.irs.gov/pub/irs-soi/eo4.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 4

    # Download data #

    files = [busfile1, busfile2, busfile3, busfile4]
    item = 1

    for file in files:

        response = requests.get(file, allow_redirects=True)

        outfile = dfolder + "/irs_businessfile_" + str(item) + ".csv"
        with open(outfile, 'w') as f:
            f.write(response.text)
        item +=1

    # Append files together to form one dataset #

    masterfile = dfolder + "/irs_businessfile_master_" + ddate + ".csv"
    file1 = dfolder + "/irs_businessfile_1.csv"
    file2 = dfolder + "/irs_businessfile_2.csv"
    file3 = dfolder + "/irs_businessfile_3.csv"
    file4 = dfolder + "/irs_businessfile_4.csv"

    afiles = [file2, file3, file4]


    # Append all of these files together #

    fout=open(masterfile, 'a')

    # Open the first file and write the contents to the output file:
    for line in open(file1):
        fout.write(line)

    # Now the remaining files:
    for file in afiles:
        f = open(file)
        next(f) # skip the first row
        for line in f:
             fout.write(line)
        f.close() # not really needed
    fout.close()


    # Write metadata to file

    mdata = dict(response.headers)
    mdata["file"] = "Exempt Organisations - Business Files"
    mdata["data_link"] = files

    with open(exefile, "w") as f:
        json.dump(mdata, f)

    
    # Revoked nonprofits #    

    revexemp = 'https://apps.irs.gov/pub/epostcard/data-download-revocation.zip' # IRS CURRENT EXEMPT ORGANIZATIONS LIST

    # Download data #

    response = requests.get(revexemp, allow_redirects=True)
    z = zipfile.ZipFile(io.BytesIO(response.content))
    z.extractall(dfolder)

    # Load in .txt file and write to csv #

    inputfile = dfolder + "/data-download-revocation.txt"
    outputfile = dfolder + "/irs_revoked_exemp_orgs_" + ddate + ".csv"
    
    with open(outputfile, 'w', newline='') as outcsv:
        varnames = ["EIN", "Legal_Name", "Doing_Business_As_Name", "Organization_Address", "City", "State", "ZIP_Code", "Country", "Exemption_Type", "Revocation_Date", "Revocation_Posting_Date", "Exemption_Reinstatement_Date"]
        writer = csv.writer(outcsv, varnames)
        writer.writerow(varnames)

        with open(inputfile, 'r') as infile:
            reader = csv.reader(infile, delimiter='|')
            for row in reader:
                writer.writerow(row)


    # Write metadata to file

    mdata = dict(response.headers)
    mdata["file"] = "Revoked Organisations"
    mdata["data_link"] = revexemp

    with open(revfile, "w") as f:
        json.dump(mdata, f)            


#############################################################################################################

#############################################################################################################


# England and Wales

def ew_download(basefolder, logfolder, ddate):
    """
        Downloads latest copy of the data extract from the Charity Commission for England and Wales.

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading England and Wales data extract")
    print("\r")

   
    # Create data folder

    dfolder = basefolder + "/ew"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder)) 


    mfile = logfolder + "/ew-download-metadata-" + ddate + ".json"


    # Request web page containing link to file
    
    webadd = "https://register-of-charities.charitycommission.gov.uk/register/full-register-download"
    response = requests.get(webadd)
    print(response.status_code, response.headers)


    # Search for file on web page

    if response.status_code==200: # if the web page was successfully requested

        webpage = soup(response.text, "html.parser")
        file_id = webpage.select_one("a[href*=Extract]").get("href")
        file_url = "https://register-of-charities.charitycommission.gov.uk" + file_id


        # Request file

        response_file = requests.get(file_url, allow_redirects=True)

        if response_file.status_code==200:

            outfile = dfolder + "/ccew-data-extract-" + ddate + ".zip"
            if os.path.isfile(outfile): # do not overwrite existing file
                print("File already exists, no need to overwrite")
            else: # file does not currently exist, therefore create
                with open(outfile, "wb") as f:
                    f.write(response_file.content)

            # Unzip files and convert from bcp to csv

            import_zip(outfile, dfolder)

        else:
            print("Unable to download data extract from link {}".format(file_url))
            print("Status code {}".format(response_file.status_code))


    # Write metadata to file

    mdata = dict(response_file.headers)
    mdata["file"] = "Data Extract"
    mdata["data_portal_link"] = str(webadd)
    mdata["data_extract_link"] = str(file_url)
    mdata["data_extract_last_modified"] = response_file.headers["Last-Modified"]

    with open(mfile, "w") as f:
        json.dump(mdata, f)
    

    print("\r")    
    print("Successfully downloaded data extract")
    print("Check log file for metadata about the download: {}".format(mfile))


#############################################################################################################

#############################################################################################################


# Northern Ireland

def ni_roc(basefolder, logfolder, ddate):
    """
        Downloads latest copy of the Register of Charities

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Northern Ireland Charity Register")
    print("\r")


    # Create data folder

    dfolder = basefolder + "/ni"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder)) 


    # Define output files

    mfile = logfolder + "/ni-roc-metadata-" + ddate + ".json"
    outfile = dfolder + "/ni-roc-" + ddate + ".csv" # Charity Register


    # Request file from API
    
    webadd = "https://www.charitycommissionni.org.uk/umbraco/api/charityApi/ExportSearchResultsToCsv/?include=Removed"
    response = requests.get(webadd)
    print(response.status_code, response.headers)


    # Write metadata to file

    mdata = dict(response.headers)
    mdata["file"] = "Register of Charities"
    mdata["url"] = str(webadd)

    with open(mfile, "w") as f:
        json.dump(mdata, f)


    # Save data file

    if response.status_code==200: # if the web page was successfully requested

        if os.path.isfile(outfile): # do not overwrite existing file
            print("File already exists, no need to overwrite")
        else: # file does not currently exist, therefore create
            with open(outfile, "wb") as f:
                f.write(response.content)
        
        print("\r")    
        print("Successfully downloaded Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))

    else: # file was not successfully requested
        print("\r")    
        print("Unable to download Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))


    print("\r")
    print("Charity Register: '{}'".format(outfile))

    return outfile, dfolder


def ni_webpage(regid, webpagefolder, logfolder, ddate):
    """
        Downloads a charity's web page from the CCNI website, which can be parsed at a later date.

        Takes one mandatory argumnent:
            - Registered Charity Number of a charity

        Dependencies:
            - roc_download (for source of charity numbers)

        Issues: 
    """  
    
    
    # Request web page

    session = requests.Session()

    webadd = "https://www.charitycommissionni.org.uk/charity-details/?regId=" + str(regid) + "&subId=0"
    response = session.get(webadd)

    
    # Capture metadata

    mdata = dict(response.headers)
    mdata["registered_charity_number"] = str(regid)
    mdata["url"] = str(webadd)
    mfile = logfolder + "/ni-webpages-metadata-" + str(regid) + "-" + ddate + ".json"

    with open(mfile, "w") as f:
        json.dump(mdata, f)
    
    
    # Save web page

    if response.status_code==200:

        outfile = webpagefolder + "/ni-charity-" + str(regid)  + "-" + ddate + ".txt"

        with open(outfile, "w") as f:
            f.write(response.text) 

        print("Downloaded web page of charity: {}".format(regid))    
        print("\r")
        print("Web page file is here: '{}'".format(outfile))

    else:
        print("\r")
        print("Could not download web page of charity: {}".format(regid))



def ni_webpage_from_file(infile, dfolder, logfolder, ddate):
    """
        Takes a file containing Registered Charity Numbers (RCN) for Northern Irish charities and
        downloads a charity's web page from the regulator's website.

        Takes one mandatory and one optional argument:
            - CSV file containing a list of rcns for Northern Irish charities [mandatory]
            - Proportion of charities to download details for; default is all (1.0) [optional]

        Dependencies:
            - webpage_download

        Issues:
            - 
    """

    # Create data folder

    webpagefolder = dfolder + "/webpages"
    if not os.path.isdir(webpagefolder):
        os.mkdir(webpagefolder)
    else:
        print("{} already exists".format(dfolder)) 

            
    # Read in data

    df = pd.read_csv(infile, encoding="ISO-8859-1", index_col=False) # import file
    regid_list = df["Reg charity number"].tolist()

    # Request web pages

    for regid in regid_list:
        ni_webpage(regid, webpagefolder, logfolder, ddate)

    print("\r")
    print("Finished downloading web pages for charities in file: {}".format(infile))
    print("Check log files for metadata about the download")

    return webpagefolder


def ni_removed(register, dfolder, webpagefolder, ddate):
    """
        Takes a charity's webpage (.txt file) downloaded from the CCNI website and
        extracts the removal date of deregistered organisations.

        Takes one mandatory argument:
            - A directory with .txt files containing HTML code of a charity's CCNI web page

        Dependencies:
            - webpage_download | webpage_download_from_file 

        Issues:       
    """    

    # Define output file

    rfile = dfolder + "/ni-removals-" + ddate + ".csv"    
    rvarnames = ["regid", "removed", "removed_date"]


    # Write headers to the output files

    with open(rfile, "w", newline="") as f:
        writer = csv.writer(f, rvarnames)
        writer.writerow(rvarnames)

    
    # Get list of removed organisations

    roc = pd.read_csv(register, encoding = "ISO-8859-1", index_col=False)
    removed = roc.loc[roc["Status"]=="Removed"]
    removed_set = set(removed["Reg charity number"])


    # Read data

    for file in os.listdir(webpagefolder):
        if file.endswith(".txt"):
            regid = file[11:17]
            if int(regid) in removed_set:
                f = os.path.join(webpagefolder, file)
                print(regid, f)
                with open(f, "r", encoding = "ISO-8859-1") as f:
                    data = f.read()
                    soup_org = soup(data, "html.parser") # Parse the text as a BS object.
            
                # Locate and extract annual report information
                
                removed = 1
                removed_date_sentence = soup_org.find("div", class_="pcg-charity-details__purpose pcg-charity-details__purpose--removed pcg-contrast__color-main").text
                removed_date_str = removed_date_sentence.replace(" ", "")[-10:].strip()
                #if removed_date_str[0].isalpha():
                #    removed_date_str = "0" + removed_date_str[1:]
                try:
                    removed_date = dt.strptime(removed_date_str, "%d%b%Y").date()
                except:
                    removed_date = ""
                row = regid, removed, removed_date
                with open(rfile, "a", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerow(row)
                

            else: # charity is not removed from register
                removed = 0
                removed_date = ""
                row = regid, removed, removed_date
                with open(rfile, "a", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerow(row)    

    print("/r")
    print("Finished extracting removal data from charity web pages found in: {}".format(webpagefolder))


def ni_download(basefolder, logfolder, ddate):
    register, dfolder = ni_roc(basefolder, logfolder, ddate)
    print("Finished downloading Register of Charities")

    webpagefolder = ni_webpage_from_file(register, dfolder, logfolder, ddate)
    print("Finished downloading webpages")

    ni_removed(register, dfolder, webpagefolder, ddate)
    print("Finished extracting information for removed charities")



# Republic of Ireland

def roi_download(basefolder, logfolder, ddate):
    """
        Downloads latest copy of the Register of Charities and Annual Returns

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Rep. of Ireland Charity Register")
    print("\r")


    # Create data folder

    dfolder = basefolder + "/roi"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder))    


    # Define output files

    mfile = logfolder + "/roi-roc-metadata-" + ddate + ".json"
    outfile = dfolder + "/roi-roc-" + ddate + ".xlsx" # Charity Register


    # Request web page containing link to file
    
    webadd = "https://www.charitiesregulator.ie/en/information-for-the-public/search-the-register-of-charities"
    response = requests.get(webadd)
    print(response.status_code, response.headers)


    # Write metadata to file

    mdata = dict(response.headers)
    mdata["file"] = "Register of Charities"
    mdata["url"] = str(webadd)

    with open(mfile, "w") as f:
        json.dump(mdata, f)


    # Search for file on web page

    if response.status_code==200: # if the web page was successfully requested

        webpage = soup(response.text, "html.parser")

        file_url = webpage.select_one("a[href*=public-register]").get("href")
        print(file_url)

        base_url = "http://www.charitiesregulator.ie" # Create initial part of the link
        file_webadd = base_url + file_url # Build full link to file
        file_webadd.replace(" ", "%20")

        # Request file

        response_file = requests.get(file_webadd)

        # Save files (data and metadata)

        # Data

        if os.path.isfile(outfile): # do not overwrite existing file
            print("File already exists, no need to overwrite")
        else: # file does not currently exist, therefore create
            with open(outfile, "wb") as f:
                f.write(response_file.content)
        
        print("\r")    
        print("Successfully downloaded Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))

    else: # file was not successfully requested
        print("\r")    
        print("Unable to download Charity Register")
        print("Check log file for metadata about the download: {}".format(mfile))



    print("\r")
    print("Charity Register: '{}'".format(outfile))



# Scotland

def sco_download(basefolder, logfolder, ddate):
    """
        Downloads latest copy of the Register of Charities and Removed Organisations

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Scotland Charity Register and Removed Organisations")
    print("\r")


    # Create data folder

    dfolder = basefolder + "/sco"
    if not os.path.isdir(dfolder):
        os.mkdir(dfolder)
    else:
        print("{} already exists".format(dfolder)) 


    # Define output files

    regmfile = logfolder + "/sco-roc-metadata-" + ddate + ".json" # Charity Register metadata
    remmfile = logfolder + "/sco-rem-metadata-" + ddate + ".json" # Removed Organisations metadata
    regfile = dfolder + "/sco-roc-" + ddate + ".zip" # Charity Register
    remfile = dfolder + "/sco-rem-" + ddate + ".zip" # Removed Organisations


    # Download Charity Register
    
    reglink = "https://www.oscr.org.uk/umbraco/Surface/FormsSurface/CharityRegDownload"
    response = requests.get(reglink)

    
    # Write metadata to file

    regmdata = dict(response.headers)
    regmdata["file"] = "Register of Charities"
    regmdata["url"] = str(reglink)

    with open(regmfile, "w") as f:
        json.dump(regmdata, f)

    with open(regfile, "wb") as f:
        f.write(response.content)
        
    print("\r")    
    print("Successfully downloaded Charity Register")
    print("Check log file for metadata about the download: {}".format(regmfile))


    # Download Removed Organisations
    
    remlink = "https://www.oscr.org.uk/umbraco/Surface/FormsSurface/CharityFormerRegDownload"
    response = requests.get(remlink)

    
    # Write metadata to file

    remmdata = dict(response.headers)
    remmdata["file"] = "Removed Organisations"
    remmdata["url"] = str(remlink)

    with open(remmfile, "w") as f:
        json.dump(remmdata, f)

    with open(remfile, "wb") as f:
        f.write(response.content)
        
    print("\r")    
    print("Successfully downloaded Charity Register")
    print("Check log file for metadata about the download: {}".format(remmfile))




# Delete files #

def file_delete(source, ext):
    """
        Deletes files in a given folder. After you have finished extracting the information you want
        from the downloaded web pages, it is good practice to delete the .txt files containing the
        web pages.

        Takes one mandatory and one optional argument:
            - A list of directories containing files [mandatory]
            - A file type to delete (e.g., .txt), else all files deleted [optional]

        Dependencies:
            - NONE

        Issues:       
    """

    for directory in source:
        for file in os.listdir(directory):
            if file.lower().endswith(str(ext)):
                f = os.path.join(directory, file)
                os.remove(f)
        print("Finished deleting files in {}".format(directory))
    
    print("\r")         
    print("Finished deleting files in all directories supplied")



# Define main() function for executing other functions when script is exectuted
#
# Add a logfile to capture which functions were not executed.
#

def main():

    print("Executing data download")
    
    download, log, ddate = prelim()
    try:
        print("Beginning Scotland download")
        sco_download(download, log, ddate)
    except:
        print("Could not execute Scotland download")
    
    try:
        print("Beginning Australia download")
        aus_download(download, log, ddate)
    except:
        print("Could not execute Australia download")
    try:
        print("Beginning England and Wales download")
        ew_download(download, log, ddate)
    except:
        print("Could not execute England and Wales download")
    try:
        print("Beginning Rep. of Ireland download")
        roi_download(download, log, ddate)
    except:
        print("Could not execute Republic of Ireland download")
    try:
        print("Beginning Northern Ireland download")
        ni_download(download, log, ddate)
    except:
        print("Could not execute Northern Ireland download")
    try:
        print("Beginning USA download")
        usa_download(download, log, ddate)
    except:
        print("Could not execute USA download")

    try:
        print("Beginning New Zealand download")
        nz_download(download, log, ddate)
    except:
        print("Could not execute New Zealand download")


# Main program #

main()