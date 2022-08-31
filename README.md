![Azure Mission-Critical Application](./icon-light.png#gh-light-mode-only)
![Azure Mission-Critical Application](./icon-dark.png#gh-dark-mode-only)

## Welcome to Azure Mission-Critical Online Reference Implementation

Azure Mission-Critical is an open source project that provides a **prescriptive architectural approach to building highly-reliable cloud-native applications on Microsoft Azure for mission-critical workloads**. This repository contains a **Fully Functional Production-Ready Mission-Critical Reference Implementation**, intended to provide a solution oriented basis to showcase mission-critical application development on Microsoft Azure, leveraging Azure-native platform capabilities to maximize reliability and operational effectiveness. More specifically, the reference implementation consists of:

- Design and implementation guidance to help readers understand and use the Azure Mission-Critical design methodology in the context of a particular industry scenario.
- Production-ready technical artifacts including Infrastructure-as-Code (IaC) resources and Continuous-Integration/Continuous-Deployment (CI/CD) pipelines (GitHub and Azure DevOps) to deploy an Mission-Critical application with mature end-to-end operational wrappers.

This repository contains the technical artifacts and in-depth documentation of the reference implementation for an Mission-Critical "online" scenario, i.e. a workload which does not require direct connectivity to other company resources (such as via a hub-and-spoke model). The pipeline deploys the application Azure Subscription security and compliance guardrails and has no network connectivity requirements. It will be used if the Mission-Critical application is access over a public endpoint without additional dependencies to other company resources.

## Azure Mission-Critical overview

The following articles provide more information about the Azure Mission-Critical design guidelines and design areas:

- [What is Azure Mission-Critical?](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-overview) (➡️ `docs.microsoft.com`) - Detailed introduction into Mission-Critical, the problem it is intended to solve and the value it can provide.
- [Design Methodology](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-design-methodology) (➡️ `docs.microsoft.com`) - The design methodology strives to provide an easy to follow design path to help to produce an optimal target architecture.
- [Design Areas](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-overview#what-are-the-key-design-areas) (➡️ `docs.microsoft.com`) - Prescriptive guidance aligned to 8 critical design areas guides users to design and build an Mission-Critical application, outlining a recommended decision process.

## Reference implementation

- [Mission-critical baseline architecture on Azure](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-intro) (➡️ `docs.microsoft.com`)
- [Getting Started Guide](./docs/reference-implementation/Getting-Started.md) outlines the process and required steps to deploy Azure Mission-Critical in your environment, including preparing the Azure DevOps pipelines.
- [Reference Implementation Documentation](./docs/README.md) contains everything required to understand and build a copy of the reference implementation.
- [Reference Implementation Build Artifacts](./src/infra/README.md) contains the Infrastructure-as-Code artifacts, CI/CD pipelines, and application code required to deploy the reference implementation.

![Architecture overview](/docs/media/mission-critical-architecture-online.svg)

## Helpful Information

- [Frequently Asked Questions](./docs/reference-implementation/FAQ.md) captures responses to common issues and challenges associated with leveraging Mission-Critical.
- [Troubleshooting Guide](./docs/reference-implementation/Troubleshooting.md) contains a list of known issues and problems that can happen in the reference implementation and instructions how to address them.
- [Full List of Documentation](./docs/README.md) contains a complete breakdown of the Mission-Critical repository to help navigate the contained guidance.

## Contributing

Azure Mission-Critical is a community driven open source project that welcomes contributions as well as suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit the [CLA portal](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g. status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

For more details, please read [how to contribute](./CONTRIBUTE.md).

## Microsoft Sponsorship

The Azure Mission-Critical project was created by the **Microsoft Customer Architecture Team (CAT)** who continue to actively sponsor the sustained evolution of the Azure Mission-Critical project through the creation of additional reference implementations for common industry scenarios.
