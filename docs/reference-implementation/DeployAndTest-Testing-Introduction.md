# Testing

The AlwaysOn reference implementation contains various kinds of tests used at different stages. These include:

- **Unit tests**. These validate that the business logic of the application works as expected. AlwaysOn contains a [sample suite of C# unit tests](/src/app/AlwaysOn.Tests/README.md) that are automatically executed before every container build.
- **Load tests**. These can help to evaluate the capacity, scalability and potential bottlenecks of a given workload and stack.
- **Smoke tests**. These identify if the infrastructure and workload are available and act as expected. Smoke tests are executed as part of every deployment.
- **UI tests**. These validate that the user interface was deployed and works as expected. Currently AlwaysOn only [captures screenshots](/src/testing/ui-test-playwright/README.md) of several pages after deployment without any actual testing.
- **Failure Injection tests**. These are done in two ways: First, AlwaysOn integrates Azure Chaos Studio for automated testing as part of the deployment pipelines. Secondly, manual failure injection test can be conducted. See below for details.

Additionally, AlwaysOn contains a [user load generator](/src/testing/userload-generator/README.md) to create synthetic load patterns which can be used to simulate real life traffic. This can also be used completely independently of the reference implementation.

> For the infrastructure, configuration and workload layer, of the aforementioned tests, see the [Testing section](/src/testing/README.md) in the reference implementation.

## Load Testing, Sizing and Scalability Checklist

To guide the load testing, the following checklist was compiled. It lists various known scale points and/or raises attention to aspects which tend to be overlooked.

- Global
  - Is Azure Front Door (or Traffic Manager) configured with multiple backends?

- Per-Stamp / Regional Deployments
  - How many requests can a single regional (stamp) deployment handle?
  - Ingress
    - Is the Ingress controller configured to scale out?
    - Is the Ingress controller properly sized and monitored?
  - Frontend
    - Is the capacity of a single instance well-understood?
      - How many requests can a single instance handle?
      - How much CPU/memory does it consume?
      - Are proper requests and limits configured?
    - Is the frontend process able to scale out?
    - Is EventHub capable and properly sized to cope with the expected no. of events?
  - Backend
    - Is the queue size properly monitored?
    - Can the backend worker scaled based on items in a queue?
    - Is the capacity of a worker instance (items/s) defined and understood?
    - Is the database SKU properly selected to cope with DB write/read operations?
  - Infrastructure
    - Can the underlying node pool scale out automatically?
    *- Is the node pool properly sized to make good use of mem/CPU available?
    - Is the ratio of pods per nodes understood and defined?
    - Are proper quotas in place to allow the infrastructure to scale out?
    - Is the used subnet sized properly to provide enough IP addresses?

## Failure Injection testing and Chaos Engineering

Distributed applications need to be resilient to service and component outages. Failure Injection testing (also known as Fault Injection or Chaos Engineering) is the practice of subjecting applications and services to real-world stresses and failures.

Resilience is a property of an entire system and injecting faults helps to find issues in the application. Addressing these issues helps to validate application resiliency to unreliable conditions, missing dependencies and other errors.

Manual failure injection testing was initially performed across both global and deployment stamp resources. Please consult the [Failure Injection article](./DeployAndTest-Testing-FailureInjection.md) for details.

AlwaysOn integrates [Azure Chaos Studio](https://aka.ms/chaosstudio) to deploy and run a set of Azure Chaos Studio Experiments to inject various faults at the global and stamp levels. Please consult the [Chaos Engineering article](./DeployAndTest-Testing-ChaosEngineering.md) for details.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
