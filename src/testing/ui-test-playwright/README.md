# UI testing with Playwright

[Playwright](https://playwright.dev/) enables reliable end-to-end testing for modern web apps. It's an [open-source](https://github.com/microsoft/playwright) Node.js library to automate Chromium, Firefox and WebKit browsers.

Playwright UI tests can be written as JavaScript code and then executed directly with `node index.js`, with [Playwright Test Runner](https://playwright.dev/docs/test-intro/) or using a 3rd party test runner (i.e. [Mocha](https://playwright.dev/docs/test-runners#mocha)).

# In-pipeline smoke tests

Since UI is not the main focus of AlwaysOn, basic smoke tests using only PowerShell and use the Playwright CLI are implemented to capture screenshots of three pages in the application (home page, play page and list games page):

```powershell
# install Playwright dependencies - required for Ubuntu
npx playwright install-deps chromium

echo "Taking a screenshot of the UI root - https://$frontDoorFqdn/"
npx playwright screenshot --wait-for-timeout=1000 --full-page --browser=chromium "https://$frontDoorFqdn/" screenshots/root.png

echo "Taking screenshot of the catalog page - https://$frontDoorFqdn/#/catalog"
npx playwright screenshot --wait-for-timeout=1000 --full-page --browser=chromium "https://$frontDoorFqdn/#/catalog" screenshots/catalog.png

```

Keep in mind that this test **doesn't fail** when the application wasn't deployed properly and the Front Door endpoint shows the default or "Not Found" error page. It would fail only in case the requested URL is not available. Captured screenshots can still be used to inspect what went wrong.

# User flow test definition

For more complex tests, a Playwright UI test definition representing a typical user flow is written in a separate file [playeruserflow.spec.js](./playeruserflow.spec.js). And executed using Playwright Test Runner. Currently this is only being used by the Load Generator, but in future it might be used in the CI/CD pipeline as well to replace the basic smoke tests.

---

[Back to documentation root](/docs/README.md)
