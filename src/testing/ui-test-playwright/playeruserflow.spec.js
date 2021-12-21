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


test('playuserflow', async ({ page }) => {

    const baseUrl = process.env.TEST_BASEURL; // Needs to include protocol, e.g. https://
    const username = process.env.TEST_USERNAME; // In our case its the email address
    const password = process.env.TEST_USER_PASSWORD;

    // If this test file is being used for actual UI testing, set these variables both to the same value
    const minNumberOfGames = process.env.TEST_MIN_NUMBER_OF_GAMES || 2;
    const maxNumberOfGames = process.env.TEST_MAX_NUMBER_OF_GAMES || 5;

    // Go to main page
    await page.goto(baseUrl);

    // Login to Azure AD B2C
    const [loginPopup] = await Promise.all([
        page.waitForEvent('popup'),
        page.waitForNavigation(), // Waits for the login popup to be opened. Like { url: 'https://<tenant>.b2clogin.com/<tenant>.onmicrosoft.com/b2c_1_signin/oauth2/v2.0/authorize?client_id=xxxxxx-yyyyyy-zzzz-b284-2f4c41819a93&scope=openid%20offline_access%20profile....' }
        page.click('text=Login')
    ]);

    // Fill Email Address / username
    await loginPopup.fill('[placeholder="Email Address"]', username);
    // Fill password
    await loginPopup.fill('[placeholder="Password"]', password);

    await page.waitForTimeout(500);

    // Press Enter to send login form
    loginPopup.press('[placeholder="Password"]', 'Enter')

    // Closes loginPopup automatically. Wait for a moment
    await page.waitForTimeout(getRandomWaitTimeMs());

    // Go to the play page
    await page.click('button:has-text("Play")');
    await expect(page).toHaveURL(`${baseUrl}/#/play`);

    var numberOfGames = getRandomInt(minNumberOfGames, maxNumberOfGames);

    const gestures = ["🗿Rock", "📜Paper", "✂️Scissors", "🦎Lizard", "🖖Spock"];

    // Play some games
    for (var i = 0; i < numberOfGames; i++) {

        // Pick a random gesture for next play
        var pick = Math.floor(Math.random() * gestures.length);
        await page.click(`text=${gestures[pick]}`);

        // Click text=GO! (Play!)
        await page.click('text=GO!');
        await page.waitForTimeout(getRandomWaitTimeMs());
    }

    // Randomly do or do not visit the my-profile page
    if (Math.random() < 0.5) {
        // Go to my profile page
        await page.goto(`${baseUrl}/#/profile/me`);
        await expect(page).toHaveURL(`${baseUrl}/#/profile/me`);

        await page.waitForTimeout(getRandomWaitTimeMs());
    }

    // Randomly do or do not visit the leaderboard page
    if (Math.random() < 0.5) {
        // Go to leaderboard
        await page.click('text=Leaderboard');
        await expect(page).toHaveURL(`${baseUrl}/#/leaderboard`);

        await page.waitForTimeout(getRandomWaitTimeMs());
    }

    // Logout
    await Promise.all([
        page.waitForNavigation(),
        page.click('text=Logout')
    ]);

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
