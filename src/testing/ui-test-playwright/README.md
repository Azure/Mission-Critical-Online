# UI testing with Playwright

[Playwright](https://playwright.dev/) enables reliable end-to-end testing for modern web apps. It's an [open-source](https://github.com/microsoft/playwright) Node.js library to automate Chromium, Firefox and WebKit browsers.

Playwright UI tests can be written as JavaScript code and then executed directly with `node index.js`, with [Playwright Test Runner](https://playwright.dev/docs/test-intro/) or using a 3rd party test runner (i.e. [Mocha](https://playwright.dev/docs/test-runners#mocha)).

# User flow test definition

A Playwright UI test definition representing a typical user flow is written in a separate file [cataloguserflow.spec.js](./cataloguserflow.spec.js). And executed using Playwright Test Runner. This is being used by the smoke test in the deployment pipeline as well as by the optional Load Generator.

# In-pipeline smoke tests

The Playwright test definition is executed against the Front Door endpoint of the stamp as part of the smoke testing stage during the deployment pipeline. It will catch errors in the UI as well as capture screenshots for manual inspection and stores them as pipeline artifacts.

```powershell
echo "Installing Playwright dependencies..."
npm install playwright-chromium @playwright/test -y

$env:TEST_BASEURL = "https://$frontDoorFqdn"
$env:SCREENSHOT_PATH = "$pwd/screenshots"

$playwrightTestPath = "src/testing/ui-test-playwright"

echo "*** Running PlayWright tests from $playwrightTestPath against https://$frontDoorFqdn"

npx playwright test -c $playwrightTestPath

```

---

[Back to documentation root](/docs/README.md)
