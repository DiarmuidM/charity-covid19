
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
                if removed_date_str[0].isalpha():
                	removed_date_str = "0" + removed_date_str[1:]
                removed_date = dt.strptime(removed_date_str, "%d%b%Y").date()
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

ddate = "2020-09-03"
register = "C:/Users/t95171dm/Dropbox/charity-covid19/data_raw/2020-09-03/ni/ni-roc-2020-09-03.csv"
dfolder = "C:/Users/t95171dm/Dropbox/charity-covid19/data_raw/2020-09-03/ni"
webpagefolder = "C:/Users/t95171dm/Dropbox/charity-covid19/data_raw/2020-09-03/ni/webpages"

ni_removed(register, dfolder, webpagefolder, ddate)