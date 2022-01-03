const csv = require('csv-parser')
const fs = require('fs')
const testUsers = [];

const usersFileName = process.env.TEST_USERS_FILE_NAME || './test-users-alwaysondev.csv';
const testTimeoutMs = process.env.TEST_TIMEOUT_MS || 120000;

// Load users file
fs.createReadStream(usersFileName)
    .pipe(csv(headers = ['email', 'oid']))
    .on('data', (data) => testUsers.push(data));

/*
* This Durable Activity-triggered function will run the actual playwright userflow tests
* Calls playwright CLI as a child process
*
*/
module.exports = async function (context) {
    try {
        const { exec } = require('child_process');

        var randomUserIndex = Math.floor(Math.random() * testUsers.length);
        var randomTestUserEmail = testUsers[randomUserIndex]['email'];

        context.log(`Starting Playwright tests against target ${process.env.TEST_BASEURL}`);
        context.log(`Picked random test user: ${randomTestUserEmail}`);

        // Path to find playwright binaries
        let cmd = `${process.cwd()}/node_modules/.bin/playwright test --timeout ${testTimeoutMs}`;

        context.log("Launching Playwright cmd:", cmd);

        // We are calling Playwright as an external call instead of using the JavaScript Playwright library directly here inside the Function
        // This way Playwright will execute the test from the *.spec.js files,
        // which are thereby reusable and we can use the tests in other places as well, e.g. as a test in the CI/CD pipeline
        let output = await new Promise((resolve, reject) => {
            const p = exec(
                cmd,
                {
                    env: {
                        'TEST_BASEURL': process.env.TEST_BASEURL,
                        'TEST_USERNAME': randomTestUserEmail,
                        'TEST_USER_PASSWORD': process.env.TEST_USER_PASSWORD, // all test users have the same password
                        ...process.env // Load all env vars from the Function runtime, too
                    }
                },
                (error, stdout, stderr) => {
                    resolve({ error, stdout, stderr });
                });
        });

        let responseMessage = "Playwright Tests finished";
        let status = 200;

        if ((output).error) {
            context.log("ERROR: " + JSON.stringify((output).error));
            status = 500;
            responseMessage += "\r\nError running tests: " + JSON.stringify((output).error, null, 2);
        }

        responseMessage += "\r\nSTDOUT: " + (output).stdout;
        context.log("STDOUT: " + (output).stdout);
        if ((output).stderr) {
            context.log("STDERR: " + (output).stderr);
            responseMessage += "\r\nSTDERR: " + (output).stderr;
        }

        return {
            status: status,
            message: responseMessage
        };
    } catch (ex) {
        context.log("ERROR: Failed to run Playwright tests: " + ex);
        return {
            status: 500,
            message: ex
        };
    }

}