from datetime import datetime as dt
import zipfile
import sys
import csv

#######Program#######

ddate = dt.now().strftime("%Y-%m-%d") # get today's date

cc_files = {
    "extract_acct_submit": [
      "regno",
      "submit_date",
      "arno",
      "fyend"
    ],
    "extract_aoo_ref": [
      "aootype",
      "aookey",
      "aooname",
      "aoosort",
      "welsh",
      "master"
    ],
    "extract_ar_submit": [
      "regno",
      "arno",
      "submit_date"
    ],
    "extract_charity": [
      "regno",
      "subno",
      "name",
      "orgtype",
      "gd",
      "aob",
      "aob_defined",
      "nhs",
      "ha_no",
      "corr",
      "add1",
      "add2",
      "add3",
      "add4",
      "add5",
      "postcode",
      "phone",
      "fax",
    ],
    "extract_charity_aoo": [
      "regno",
      "aootype",
      "aookey",
      "welsh",
      "master"
    ],
    "extract_class": [
      "regno",
      "class"
    ],
    "extract_class_ref": [
      "classno",
      "classtext",
    ],
    "extract_financial": [
      "regno",
      "fystart",
      "fyend",
      "income",
      "expend"
    ],
    "extract_main_charity": [
      "regno",
      "coyno",
      "trustees",
      "fyend",
      "welsh",
      "incomedate",
      "income",
      "grouptype",
      "email",
      "web"
    ],
    "extract_name": [
      "regno",
      "subno",
      "nameno",
      "name"
    ],
    "extract_objects": [
      "regno",
      "subno",
      "seqno",
      "object"
    ],
    "extract_partb": [
      "regno",
      "artype",
      "fystart",
      "fyend",
      "inc_leg",
      "inc_end",
      "inc_vol",
      "inc_fr",
      "inc_char",
      "inc_invest",
      "inc_other",
      "inc_total",
      "invest_gain",
      "asset_gain",
      "pension_gain",
      "exp_vol",
      "exp_trade",
      "exp_invest",
      "exp_grant",
      "exp_charble",
      "exp_gov",
      "exp_other",
      "exp_total",
      "exp_support",
      "exp_dep",
      "reserves",
      "asset_open",
      "asset_close",
      "fixed_assets",
      "open_assets",
      "invest_assets",
      "cash_assets",
      "current_assets",
      "credit_1",
      "credit_long",
      "pension_assets",
      "total_assets",
      "funds_end",
      "funds_restrict",
      "funds_unrestrict",
      "funds_total",
      "employees",
      "volunteers",
      "cons_acc",
      "charity_acc"
    ],
    "extract_registration": [
      "regno",
      "subno",
      "regdate",
      "remdate",
      "remcode"
    ],
    "extract_remove_ref": [
      "code",
      "text"
    ],
    "extract_trustee": [
      "regno",
      "trustee"
    ]
}


def to_file(bcpdata, dfolder, csvfilename='converted.csv', col_headers=None):

    csvfilename_path = dfolder + "/" + csvfilename
    with open(csvfilename_path, 'w', encoding='utf-8') as csvfile:
        if(col_headers):
            for c in col_headers:
                c = c
            writer = csv.writer(csvfile, lineterminator='\n')
            writer.writerow(col_headers)
        csvfile.write(bcpdata)


def import_zip(zip_file, dfolder):
    
    zf = zipfile.ZipFile(zip_file, 'r')

    for filename in cc_files:
      try:
          bcp_filename = filename + '.bcp'
          csv_filename = filename + '.csv'

          bcpdata = zf.read(bcp_filename)
          bcpdata = bcpdata.decode('utf-8', errors="replace")
          lineterminator='*@@*'
          delimiter='@**@'
          quote='"'
          newdelimiter=','
          escapechar='\\'
          newline='\n'
          bcpdata = bcpdata.replace(escapechar, escapechar + escapechar)
          bcpdata = bcpdata.replace(quote, escapechar + quote)
          bcpdata = bcpdata.replace(delimiter, quote + newdelimiter + quote)
          bcpdata = bcpdata.replace(lineterminator, quote + newline + quote)
          bcpdata = quote + bcpdata + quote
          
          extractpath = to_file(bcpdata, dfolder, csvfilename=csv_filename, col_headers=cc_files[filename])

          print('Converted: %s' % bcp_filename)
      except KeyError:
          print('ERROR: Did not find %s in zip file' % bcp_filename)