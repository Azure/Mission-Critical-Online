# Testing Implementation

The Azure Mission-Critical reference implementation contains various kinds of tests used at different stages. These include:

- **Unit tests**. These validate that the business logic of the application works as expected. Azure Mission-Critical contains a [sample suite of C# unit tests](/src/app/AlwaysOn.Tests/README.md) that are automatically executed before every container build.
- **Load tests**. These can help to evaluate the capacity, scalability and potential bottlenecks of a given workload and stack.
- **Smoke tests**. These identify if the infrastructure and workload are available and act as expected. Smoke tests are executed as part of every deployment.
- **UI tests**. These validate that the user interface was deployed and works as expected. Currently Azure Mission-Critical only [captures screenshots](/src/testing/ui-test-playwright/README.md) of several pages after deployment without any actual testing.
- **Failure Injection tests**. These are done in two ways: First, Azure Mission-Critical integrates Azure Chaos Studio for automated testing as part of the deployment pipelines. Secondly, manual failure injection test can be conducted. See below for details.

Additionally, Azure Mission-Critical contains a [user load generator](/src/testing/userload-generator/README.md) to create synthetic load patterns which can be used to simulate real life traffic. This can also be used completely independently of the reference implementation.

## Failure Injection testing and Chaos Engineering

Distributed applications need to be resilient to service and component outages. Failure Injection testing (also known as Fault Injection or Chaos Engineering) is the practice of subjecting applications and services to real-world stresses and failures.

Resilience is a property of an entire system and injecting faults helps to find issues in the application. Addressing these issues helps to validate application resiliency to unreliable conditions, missing dependencies and other errors.

Manual failure injection testing was initially performed across both global and deployment stamp resources. Please consult the [Failure Injection article](/docs/reference-implementation/DeployAndTest-Testing-FailureInjection.md) for details.

Azure Mission-Critical integrates [Azure Chaos Studio](https://aka.ms/chaosstudio) to deploy and run a set of Azure Chaos Studio Experiments to inject various faults at the global and stamp levels.

## Frameworks

The Azure Mission-Critical online reference implementation uses existing testing capabilities and frameworks whenever possible. The subsequent sections contain an overview of the used tools and frameworks.

- [Azure Load Test Service](#azure-load-test-service) for load testing using the Microsoft Azure Load Test service
- [Locust](#locust) for load testing using the open source load testing framework locust
- [Playwright](#playwright) for UI testing
- [Azure Chaos Studio](#azure-chaos-studio) for failure injection testing

### Azure Load Test Service

Microsoft [Azure Load Test](https://docs.microsoft.com/azure/load-testing/overview-what-is-azure-load-testing) Service (MALT) is a managed service to execute [Apache JMeter](https://jmeter.apache.org/) load test definitions. Azure Mission-Critical comes with a load test definition for its sample application that can be leveraged either standalone (infrastructure and test service is deployed via a separate pipeline) or embedded into the e2e pipeline including a baseline definition.

### Locust

Locust is an open source Load Testing framework written in Python. See [locust](./loadtest-locust/README.md) for more details about the implementation and configuration. Locust was used in the Mission-Critical reference implementation before MALT was available and is still available as a [standalone deployment using Azure Container Instances](https://medium.com/microsoftazure/globally-distributed-load-tests-in-azure-with-locust-aeb3a365cd60).

### Playwright

Playwright is an open source Node.js library to automate Chromium, Firefox and WebKit with a single API. See [ui-test-playwright](./ui-test-playwright/README.md) for more details about how UI testing works.

### Azure Chaos Studio

To inject failures for resiliency validation, Azure Mission-Critical uses Azure Chaos Studio as an optional step in the E2E validation pipeline. See [Chaos Testing](./chaos-testing/README.md) for more details about the implementation and configuration.

## User Load Generator

To simulate real user traffic patterns, Azure Mission-Critical implements a [user load generator](./userload-generator/README.md) to generate synthetic traffic. It uses a Playwright test definition and can be also used completely independently of Azure Mission-Critical reference implementations.

---

[Back to documentation root](/docs/README.md)
