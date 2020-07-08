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
import requests
import os
import argparse
import json
import random
import csv
import re
import pandas as pd


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
    print("To see the list of functions you can call, run the following command: python char-excess-events-collection-2020-06-30.py -h")
   

# Australia

def aus_download():
    """
        Downloads latest copy of the Register of Charities.

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Australian Charity Register")
    print("\r")


    # Create folders

    directories = ["aus", "logs"]

    for directory in directories:
        if not os.path.isdir(directory):
            os.mkdir(directory)
        else:
            #print("{} already exists".format(directory))
            continue   


    # Define output files

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    mfile = "./logs/aus-roc-metadata-" + ddate + ".json"
    outfile = "./aus/aus-roc-" + ddate + ".xlsx" # Charity Register

    
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

 
# Northern Ireland

def ni_roc():
    """
        Downloads latest copy of the Register of Charities

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Northern Ireland Charity Register")
    print("\r")


    # Create folders

    directories = ["ni", "logs"]

    for directory in directories:
        if not os.path.isdir(directory):
            os.mkdir(directory)
        else:
            print("{} already exists".format(directory))
            continue   


    # Define output files

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    mfile = "./logs/ni-roc-metadata-" + ddate + ".json"
    outfile = "./ni/ni-roc-" + ddate + ".csv" # Charity Register


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

    return outfile


def ni_webpage(regid):
    """
        Downloads a charity's web page from the CCNI website, which can be parsed at a later date.

        Takes one mandatory argumnent:
            - Registered Charity Number of a charity

        Dependencies:
            - roc_download (for source of charity numbers)

        Issues: 
    """  

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date
    
    
    # Request web page

    session = requests.Session()

    webadd = "https://www.charitycommissionni.org.uk/charity-details/?regid=" + str(regid) + "&subid=0"
    response = session.get(webadd)

    
    # Capture metadata

    mdata = dict(response.headers)
    mdata["registered_charity_number"] = str(regid)
    mdata["url"] = str(webadd)
    mfile = "./logs/ni-webpages-metadata-" + str(regid) + "-" + ddate + ".json"

    with open(mfile, "w") as f:
        json.dump(mdata, f)
    
    
    # Save web page

    if response.status_code==200:

        outfile = "./ni/webpages/ni-charity-" + str(regid)  + "-" + ddate + ".txt"

        with open(outfile, "w") as f:
            f.write(response.text) 

        print("Downloaded web page of charity: {}".format(regid))    
        print("\r")
        print("Web page file is here: '{}'".format(outfile))

    else:
        print("\r")
        print("Could not download web page of charity: {}".format(regid))



def ni_webpage_from_file(infile):
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

    # Create folders

    directories = ["ni/webpages", "logs"]

    for directory in directories:
        if not os.path.isdir(directory):
            os.mkdir(directory)
        else:
            print("{} already exists".format(directory))
            continue 

            
    # Read in data

    df = pd.read_csv(infile, encoding="ISO-8859-1", index_col=False) # import file
    regid_list = df["Reg charity number"].tolist()

    # Request web pages

    for regid in regid_list:
        ni_webpage(regid)

    print("\r")
    print("Finished downloading web pages for charities in file: {}".format(infile))
    print("Check log files for metadata about the download")



def ni_removed(source):
    """
        Takes a charity's webpage (.txt file) downloaded from the CCNI website and
        extracts the removal date of deregistered organisations.

        Takes one mandatory argument:
            - A directory with .txt files containing HTML code of a charity's CCNI web page

        Dependencies:
            - webpage_download | webpage_download_from_file 

        Issues:       
    """

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date
    

    # Define output file

    rfile = "./ni/ni-removals-" + ddate + ".csv"    
    rvarnames = ["regid", "removed", "removed_date"]


    # Write headers to the output files

    with open(rfile, "w", newline="") as f:
        writer = csv.writer(f, rvarnames)
        writer.writerow(rvarnames)

    
    # Get list of removed organisations

    infile = "./ni/ni-roc-" + ddate + ".csv" # Register of Charities
    roc = pd.read_csv(infile, encoding = "ISO-8859-1", index_col=False)
    removed = roc.loc[roc["Status"]=="Removed"]
    removed_set = set(removed["Reg charity number"])


    # Read data

    for file in os.listdir(source):
        if file.endswith(".txt"):
            regid = file[11:17]
            if int(regid) in removed_set:
                f = os.path.join(source, file)
                with open(f, "r") as f:
                    data = f.read()
                    soup_org = soup(data, "html.parser") # Parse the text as a BS object.
            
                # Locate and extract annual report information
                
                removed = 1
                removed_date_sentence = soup_org.find("div", class_="pcg-charity-details__purpose pcg-charity-details__purpose--removed pcg-contrast__color-main").text
                removed_date_str = re.split(r"\s(?=on)", removed_date_sentence)[1][3:].strip()
                removed_date = dt.strptime(removed_date_str, "%d %b %Y").date()
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

    print("\r")
    print("Finished extracting removal data from charity web pages found in: {}".format(source))


def ni_download():
    register = ni_roc()
    ni_webpage_from_file(register)
    ni_removed("./ni/webpages/")



# Republic of Ireland

def roi_download(**args):
    """
        Downloads latest copy of the Register of Charities and Annual Returns

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Rep. of Ireland Charity Register")
    print("\r")


    # Create folders

    directories = ["roi", "masterfiles", "logs"]

    for directory in directories:
        if not os.path.isdir(directory):
            os.mkdir(directory)
        else:
            print("{} already exists".format(directory))
            continue   


    # Define output files

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    mfile = "./logs/roi-roc-metadata-" + ddate + ".json"
    outfile = "./roi/roi-roc-" + ddate + ".xlsx" # Charity Register


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
    print("Charity Register: '{}'; and master file: '{}'".format(outfile))



# Scotland

def sco_download(**args):
    """
        Downloads latest copy of the Register of Charities and Removed Organisations

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Scotland Charity Register and Removed Organisations")
    print("\r")


    # Create folders

    directories = ["sco", "logs"]

    for directory in directories:
        if not os.path.isdir(directory):
            os.mkdir(directory)
        else:
            print("{} already exists".format(directory))
            continue   


    # Define output files

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    regmfile = "./logs/sco-roc-metadata-" + ddate + ".json" # Charity Register metadata
    remmfile = "./logs/sco-rem-metadata-" + ddate + ".json" # Removed Organisations metadata
    regfile = "./sco/sco-roc-" + ddate + ".zip" # Charity Register
    remfile = "./sco/sco-rem-" + ddate + ".zip" # Removed Organisations


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

def file_delete(source, ext, **args):
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

def main():
    print("Executing data download")
    #sco_download()



# Main program #

main()