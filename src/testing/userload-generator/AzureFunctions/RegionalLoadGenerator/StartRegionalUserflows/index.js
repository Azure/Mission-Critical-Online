const df = require("durable-functions");

const orchestratorFunctionName = "RegionalDurableOrchestrator";

/*
 * This HTTP-triggered function will kick off the orchestrator
 *
 */
module.exports = async function (context, req) {
    const client = df.getClient(context);

    const input = req.query.numberofusers || 10;
    const numberOfUsers = parseInt(input);

    if (isNaN(numberOfUsers)) {
        return {
            status: 400,
            body: "Pass a valid number as 'numberofusers' query parameter"
        };
    }

    // Query existing orchestrator instances
    const instances = await client.getStatusAll();

    let existingInstanceId = "";

    // Check is there is another instance of the orchestrator already running
    // If so, and if the input is different, terminate the old instance before we start a new one with the new input
    instances.forEach((instance) => {
        if (instance.name == orchestratorFunctionName
            && instance.runtimeStatus == df.OrchestrationRuntimeStatus.Running) {
            if (instance.input != numberOfUsers) {
                context.log(`Number of users has changed. Terminating existing orchestrator instanceId=${instance.instanceId}`);
                client.terminate(instance.instanceId, "Number of users has changed. Terminating existing orchestrator.");
            } else {
                context.log("Orchestrator with the same number of users is already running. Not starting a new instance");
                existingInstanceId = instance.instanceId;
            }
        }
    });

    if (existingInstanceId != "") {
        return client.createCheckStatusResponse(context.bindingData.req, existingInstanceId);
    }

    if (numberOfUsers == 0) {
        context.log("Number of users set to 0. Not starting a new orchestrator");
        return {
            body: "Number of users set to 0. Not starting a new orchestrator",
            status: 200
        };
    }

    const instanceId = await client.startNew(orchestratorFunctionName, undefined, numberOfUsers);

    context.log(`Started new orchestration with ${numberOfUsers} users with ID = '${instanceId}'.`);

    return client.createCheckStatusResponse(context.bindingData.req, instanceId);
}