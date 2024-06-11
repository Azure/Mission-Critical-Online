const df = require("durable-functions");

const activityFunctionName = process.env.TEST_ACTIVITY_FUNCTION_NAME || "PlayerUserflowExecActivity";

/*
 * This Durable Orchestrator function will kick off the activity Functions which run the actual userflows
 *
 */
module.exports = df.orchestrator(function* (context) {
    const numberOfUsers = parseInt(context.df.getInput());

    if (!context.df.isReplaying)
        context.log.info(`Starting orchestrator for ${numberOfUsers} users`);

    const tasks = [];
    for (var i = 0; i < numberOfUsers; i++) {
        if (!context.df.isReplaying) context.log.info(`[${i + 1}/${numberOfUsers}] Starting task`)
        tasks.push(context.df.callActivity(activityFunctionName, null));
    }

    // Wait for all tasks to finish
    const results = yield context.df.Task.all(tasks);

    if (!context.df.isReplaying)
        context.log.info(`All ${numberOfUsers} tasks have been finished!`);

    let success = 0;
    let failed = 0;

    for (const r of results) {
        if (!context.df.isReplaying) {
            context.log.info("Result status: " + r.status);
            context.log.info("Result message: " + r.message);
        }

        if (r.status == 200) {
            success++;
        }
        else {
            failed++;
        }
    }

    if (!context.df.isReplaying)
        context.log.info(`Successful: ${success}/${numberOfUsers} - Failed: ${failed}/${numberOfUsers}`);

    context.df.setCustomStatus(`Last run result - Successful: ${success}/${numberOfUsers} - Failed: ${failed}/${numberOfUsers}`);

    // Start a new instance of this orchestrator ("eternal orchestrator")
    if (!context.df.isReplaying)
        context.log.info("Restarting new orchestrator instance");

    yield context.df.continueAsNew(numberOfUsers);
});