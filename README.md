# teamwork
Selenium/Python script to log entries to Teamwork.com from csv

- requires:
  - [Google Chrome](https://www.google.com/chrome/)
  - [Python >=3.11](https://www.python.org/downloads/)
  - [Selenium >=4.8](https://www.selenium.dev/documentation/webdriver/)

- usage:  
  `python logEntriesFromCVS.py [-h] -u USERNAME -p PASSWORD -f FILE [-v]`

- Description  
  Logs Time Entries to Teamwork using selenium.

- options:    
    | Param         | Long Param | Description                            |
    |---------------|------------|----------------------------------------|
    | -h            | --help     | show this help message and exit        |
    | -u USERNAME * | --username | username for Teamwork                  |
    | -p PASSWORD * | --password | password for Teamwork                  |
    | -f CSV_FILE * | --file     | the csv file to read entries from      |
    | -v            | --version  | show program's version number and exit |

- CSV File scheme  
  - Columns:
    Project;Date;StartTime;EndTime;Duration;Billable;Description;Task  

  - Considerations:  
    - [x] Must have the above **exact** columns.  
    - [x] Dates format must be: `dd/mm/yyyy`.  
    - [x] Times format must be: `HH:MM`.  
    - [x] Billable takes `0=False` and `1=True`.  
    - [x] CSV should be **`UTF-8`** encoded.  

