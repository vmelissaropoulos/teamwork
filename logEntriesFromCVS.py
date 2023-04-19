import csv
import argparse
from time import sleep as sleep

from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys




def addEntries(
    project: str,
    date: str,
    startTime: str,
    duration: str,
    isBillable: bool,
    description: str,
):
    projectDropdown.click()
    sleep(1)
    searchBox.send_keys(project)
    sleep(1)
    searchBox.send_keys(Keys.ENTER)

    dateBox.send_keys(Keys.END + Keys.SHIFT + Keys.HOME + Keys.DELETE)
    dateBox.send_keys(date)
    sleep(1)
    dateBox.send_keys(Keys.TAB)

    startTimeH = startTime.split(":")[0]
    startTimeM = startTime.split(":")[1]
    startTimeBox.send_keys(startTimeH + Keys.TAB + startTimeM)

    durationHours = duration.split(":")[0]
    durationHoursBox.send_keys(Keys.END + Keys.SHIFT + Keys.HOME + Keys.DELETE)
    durationHoursBox.send_keys(durationHours)

    durationMinutes = duration.split(":")[1]
    durationMinutesBox.send_keys(Keys.END + Keys.SHIFT + Keys.HOME + Keys.DELETE)
    durationMinutesBox.send_keys(durationMinutes)

    billable = checkBillableBox.get_attribute("value")
    if isBillable:
        if billable != "on":
            checkBillableBox.click()
    else:
        if billable == "on":
            checkBillableBox.click()

    descriptionBox.send_keys(description)
    addButton.click()
    return True


if __name__ == "__main__":
    argParser = argparse.ArgumentParser(
        description="Logs Time entries to Teamwork using selenium.",
        epilog="Check github page for more info: https://github.com/vmelissaropoulos/teamwork",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    argParser.add_argument(
        "-u", "--username", type=str, help="username for Teamwork", required=True
    )
    argParser.add_argument(
        "-p", "--password", type=str, help="password for Teamwork", required=True
    )
    argParser.add_argument(
        "-f", "--file", type=str, help="the csv file to read entries from", required=True
    )
    argParser.add_argument("-v", "--version", action="version", version="Version 1.0")

    args = argParser.parse_args()
    driver = webdriver.Chrome()
    action = ActionChains(driver)

    driver.get("https://www.teamwork.com/launchpad/login?continue=/launchpad/welcome")
    driver.set_window_size(1528, 812)

    WebDriverWait(driver, timeout=20).until(
        lambda d: d.find_element("id", "loginemail")
    )

    if driver.title.startswith("Log in"):
        login_mail = driver.find_element(By.ID, "loginemail").send_keys(args.username)
        login_pass = driver.find_element(By.ID, "loginpassword").send_keys(
            args.password
        )
        login_button = driver.find_element(By.TAG_NAME, "button").click()

    WebDriverWait(driver, timeout=20).until(
        lambda d: d.find_element(By.CLASS_NAME, "page-welcome")
    )
    if driver.title.startswith("Welcome"):
        driver.get("https://perftech.teamwork.com/app/time/all")
        
    sleep(10)
    driver.switch_to.frame(0)
    driver.find_elements(By.TAG_NAME, "button")[3].click()
    sleep(3)
    # logTime_button.click()

    projectDropdown = driver.find_element(By.XPATH, "//div/span/span/span")

    projectDropdown.click()
    searchBox = driver.find_element(By.CSS_SELECTOR, ".select2-search__field")
    projectDropdown.click()

    dateBox = driver.find_element(By.CSS_SELECTOR, ".w-date-input__input")
    startTimeBox = driver.find_element(
        By.CSS_SELECTOR, ".w-time-input:nth-child(2) > .w-input-with-icons__input"
    )
    durationHoursBox = driver.find_element(
        By.CSS_SELECTOR, ".form-group:nth-child(1) > .form-control"
    )
    durationMinutesBox = driver.find_element(
        By.CSS_SELECTOR, ".form-group:nth-child(2) > .form-control"
    )
    checkBillableBox = driver.find_element(By.ID, "m-all-log-time-billable")
    descriptionBox = driver.find_element(By.CSS_SELECTOR, ".form-control:nth-child(2)")
    addButton = driver.find_element(By.CSS_SELECTOR, ".btn-secondary:nth-child(1)")


with open(args.file, newline="", encoding="UTF-8") as csvfile:
    reader = csv.DictReader(csvfile, delimiter=";", quotechar="|")
    for row in reader:
        addEntries(
            project=row["Project"],
            date=row["Date"],
            startTime=row["StartTime"],
            duration=row["Duration"],
            isBillable=row["Billable"],
            description=row["Description"],
        )

res = input("Check and Submit the entries. When ready press ENTER to continue: ")
driver.quit()
