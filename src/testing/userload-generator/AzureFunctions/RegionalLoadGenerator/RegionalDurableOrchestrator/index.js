const df = require("durable-functions");

const activityFunctionName = process.env.TEST_ACTIVITY_FUNCTION_NAME || "PlayerUserflowExecActivity";

/*
 * This Durable Orchestrator function will kick off the activity Functions which run the actual userflows
 *
 */
df.app.orchestration('RegionalDurableOrchestrator', function* (context) {
    const numberOfUsers = parseInt(context.df.getInput());

    if (!context.df.isReplaying)
        context.log(`Starting orchestrator for ${numberOfUsers} users`);

    const tasks = [];
    for (var i = 0; i < numberOfUsers; i++) {
        if (!context.df.isReplaying) {
            context.log(`[${i + 1}/${numberOfUsers}] Starting task`)
        }
        tasks.push(context.df.callActivity(activityFunctionName, null));
    }

    // Wait for all tasks to finish
    const results = yield context.df.Task.all(tasks);

    if (!context.df.isReplaying)
        context.log(`All ${numberOfUsers} tasks have been finished!`);

    let success = 0;
    let failed = 0;

    for (const r of results) {
        if (!context.df.isReplaying) {
            context.log("Result status: " + r.status);
            context.log("Result message: " + r.message);
        }

        if (r.status == 200) {
            success++;
        }
        else {
            failed++;
        }
    }

    if (!context.df.isReplaying)
        context.log(`Successful: ${success}/${numberOfUsers} - Failed: ${failed}/${numberOfUsers}`);

    context.df.setCustomStatus(`Last run result - Successful: ${success}/${numberOfUsers} - Failed: ${failed}/${numberOfUsers}`);

    // Start a new instance of this orchestrator ("eternal orchestrator")
    if (!context.df.isReplaying)
        context.log("Restarting new orchestrator instance");

    context.df.continueAsNew(numberOfUsers);
});