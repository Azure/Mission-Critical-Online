/*
 * This Playwright test definition represents a simple user flow through the application of the reference implementation.
 * It is not intended to be a complete test of the application, but rather test the relevant parts
 * and to generate realistic user load pattern when be executed in larger volume in parallel.
 *
 * To simulate a more real user, there are random wait times between each task.
 * Also, some pages are only visited by some users (randomly).
 *
 */

const { test, expect } = require('@playwright/test');

// If this test file is being used for actual UI testing, set these values both to 1sec
const minTaskWaitSeconds = process.env.TEST_MIN_TASK_WAIT_SECONDS || 3;
const maxTaskWaitSeconds = process.env.TEST_MAX_TASK_WAIT_SECONDS || 6;


test('shoppinguserflow', async ({ page }) => {

    // Header to indicate that posted comments and rating are just for testing and can be deleted again by the app
    page.setExtraHTTPHeaders({'X-TEST-DATA': 'true'});

    const baseUrl = process.env.TEST_BASEURL; // Needs to include protocol, e.g. https://

    // If this test file is being used for actual UI testing, set these variables both to the same value
    const minNumberOfItems = process.env.TEST_MIN_NUMBER_OF_ITEMS || 2;
    const maxNumberOfItems = process.env.TEST_MAX_NUMBER_OF_ITEMS || 5;

    // Go to main page
    await page.goto(baseUrl);

    // Go to the catalog page
    await page.goto(`${baseUrl}/#/catalog`);
    await expect(page).toHaveURL(`${baseUrl}/#/catalog`);
    await page.waitForTimeout(getRandomWaitTimeMs());

    var numberOfItemsToVisit = getRandomInt(minNumberOfItems, maxNumberOfItems);

    // Look at some items
    for (var i = 0; i < numberOfItemsToVisit; i++) {

        // Pick a random item to visit
        var pick = getRandomInt(1, 4);

        await page.click(':nth-match(.catalog-item, ' + pick + ')');
        await page.waitForTimeout(getRandomWaitTimeMs());

        // Randomly do or do not send a rating (in 50% of cases)
        if (Math.random() < 0.5) {
            // Post a rating
            var rating = getRandomInt(1, 5);
            await page.click('id=rating-' + rating);

            await page.waitForTimeout(getRandomWaitTimeMs());
        }

        // Randomly do or do not post a comment (in 30% of cases)
        if (Math.random() < 0.3) {
            // Post a comment
            await page.fill('id=comment-authorName', 'Test User');
            await page.fill('id=comment-text', 'Just a random test comment');

            // Send comment
            await page.click('id=submit-comment');

            await page.waitForTimeout(getRandomWaitTimeMs());
        }

        // Go back to the catalog page
        await page.goto(`${baseUrl}/#/catalog`);
        await expect(page).toHaveURL(`${baseUrl}/#/catalog`);
        await page.waitForTimeout(getRandomWaitTimeMs());
    }

    // Got to the root page before leaving
    await page.goto(`${baseUrl}/#/`);
    await expect(page).toHaveURL(`${baseUrl}/#/`);
    // Wait once more before we finish the test and close the browser
    await page.waitForTimeout(getRandomWaitTimeMs());
});

function getRandomWaitTimeMs() {
    let minMs = minTaskWaitSeconds * 1000;
    let maxMs = maxTaskWaitSeconds * 1000;
    return getRandomInt(minMs, maxMs);
}

// Source: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random#getting_a_random_integer_between_two_values
function getRandomInt(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max) + 1;
    return Math.floor(Math.random() * (max - min) + min); //The maximum and the minimum are inclusive
}
