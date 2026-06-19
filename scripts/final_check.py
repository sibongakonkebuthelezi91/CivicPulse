import time
from playwright.sync_api import sync_playwright

URL = "http://localhost:5051"
errors = []


def on_console(msg):
    if msg.type == "error":
        errors.append(f"[console] {msg.text}")


def on_pageerror(exc):
    errors.append(f"[pageerror] {exc}")


with sync_playwright() as p:
    browser = p.chromium.launch(
        executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        headless=False,
    )
    page = browser.new_page(viewport={"width": 1280, "height": 900})
    page.on("console", on_console)
    page.on("pageerror", on_pageerror)

    page.goto(URL, wait_until="load")
    time.sleep(8)

    page.mouse.click(561, 365)  # Sign up tab
    time.sleep(1)
    page.mouse.click(792, 360)  # Use test profile
    time.sleep(1)
    page.mouse.wheel(0, 400)
    time.sleep(1)
    page.mouse.click(640, 791)  # Create Safe Hub Profile
    time.sleep(3)
    page.screenshot(path="scripts/final_signup.png")

    browser.close()

with sync_playwright() as p:
    browser = p.chromium.launch(
        executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        headless=False,
    )
    page = browser.new_page(viewport={"width": 1280, "height": 900})
    page.on("console", on_console)
    page.on("pageerror", on_pageerror)

    page.goto(URL, wait_until="load")
    time.sleep(8)
    page.mouse.click(640, 548)
    page.keyboard.type("9001010000080")
    time.sleep(0.5)
    page.mouse.click(640, 655)
    time.sleep(3)
    page.screenshot(path="scripts/final_signin.png")

    browser.close()

print("\n---ERRORS---")
for e in errors:
    print(e)
print("(none)" if not errors else "")
