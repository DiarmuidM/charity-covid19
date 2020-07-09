
import requests

# Canada

def can_download():
    """
        Downloads latest copy of the List of Charities from the Charities Directorate of CRA.

        Dependencies:
            - NONE

        Issues: 
    """  

    print("Downloading Canada List of Charities")
    print("\r")


    # Request download form

    download_button = "https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dwnldZp"
    headers = {'Referer':'https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/bscSrch?q.srchNm=&q.stts=&p=1'}
    response = requests.post(download_button, headers=headers)
    print(response.status_code, response.headers)

    with open('file.txt', 'w') as file:
        file.write(response.text)

can_download() 