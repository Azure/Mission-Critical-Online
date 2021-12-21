# Testing Implementation

## Frameworks

The AlwaysOn reference implementation uses existing testing capabilities and frameworks whenever possible. The subsequent sections contain an overview of the used tools and frameworks.

- [Locust](#locust) for load testing
- [Playwright](#playwright) for UI testing
- [Azure Chaos Studio](#azure-chaos-studio) for failure injection testing

### Locust

Locust is an open source Load Testing framework. See [locust](./loadtest-locust/README.md) for more details about the implementation and configuration.

### Playwright

Playwright is an open source Node.js library to automate Chromium, Firefox and WebKit with a single API. See [ui-test-playwright](./ui-test-playwright/README.md) for more details about how UI testing works.

### Azure Chaos Studio

To inject failures for resiliency validation, AlwaysOn uses Azure Chaos Studio as an optional step in the E2E validation pipeline. See [Chaos Testing](./chaos-testing/README.md) for more details about the implementation and configuration.

## User Load Generator

To simulate real user traffic patterns, AlwaysOn implements a [user load generator](./userload-generator/README.md) to generate synthetic traffic. It uses a Playwright test definition and can be also used completely independently of AlwaysOn.

---

[Back to documentation root](/docs/README.md)
