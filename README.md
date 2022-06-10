![Azure Mission-Critical Application](./icon-light.png#gh-light-mode-only)
![Azure Mission-Critical Application](./icon-dark.png#gh-dark-mode-only)

## Welcome to Azure Mission-Critical Online Reference Implementation

Azure Mission-Critical is an open source project that provides a **prescriptive architectural approach to building highly-reliable cloud-native applications on Microsoft Azure for mission-critical workloads**. This repository contains a **Fully Functional Production-Ready Mission-Critical Reference Implementation**, intended to provide a solution oriented basis to showcase mission-critical application development on Microsoft Azure, leveraging Azure-native platform capabilities to maximize reliability and operational effectiveness. More specifically, the reference implementation consists of:

- Design and implementation guidance to help readers understand and use the Azure Mission-Critical design methodology in the context of a particular industry scenario.
- Production-ready technical artifacts including Infrastructure-as-Code (IaC) resources and Continuous-Integration/Continuous-Deployment (CI/CD) pipelines (GitHub and Azure DevOps) to deploy an Mission-Critical application with mature end-to-end operational wrappers.

This repository contains the reference implementation for an Mission-Critical "online" scenario, i.e. a workload which does not require direct connectivity to other company resources (such as via a hub-and-spoke model). The pipeline deploys the application Azure Subscription security and compliance guardrails and has no network connectivity requirements. It will be used if the Mission-Critical application is access over a public endpoint without additional dependencies to other company resources.

## Reference implementation - Table of Contents

- [Reference Implementation Solution Guide](./docs/reference-implementation/README.md) - Everything required to understand and build a copy of the reference implementation
- [Reference Implementation Build Artifacts](./src/infra/README.md) - Contains the Infrastructure-as-Code artifacts, CI/CD pipelines, and application code required to deploy the pre-configured reference solution

![Architecture overview](/docs/media/mission-critical-architecture-online.svg)

## Azure Mission-Critical overview and design guidelines

The following articles provides more information about Azure Mission-Critical design guidelines and design areas located in the [Azure Mission-Critical GitHub](https://github.com/Azure/Mission-Critical) repo:

- [Introduction - What is Azure Mission-Critical?](https://github.com/Azure/Mission-Critical/blob/main/docs/Introduction.md) (➡️ `Azure/Mission-Critical`) - Detailed introduction into Mission-Critical, the problem it is intended to solve and the value it can provide.
- [Design Areas](https://github.com/Azure/Mission-Critical/blob/main/docs/Design-Areas.md) (➡️ `Azure/Mission-Critical`) - Prescriptive guidance aligned to 8 critical design areas guides users to design and build an Mission-Critical application, outlining a recommended decision process.

## Helpful Information

- [Getting Started](./docs/reference-implementation/Getting-Started.md) outlines the process and required steps to deploy Mission-Critical in your environment, including preparing the Azure DevOps pipelines. It should be read in tandem with the [Reference Implementation Guide](./docs/reference-implementation/README.md).
- [Frequently Asked Questions](./docs/reference-implementation/FAQ.md) captures responses to common issues and challenges associated with leveraging Mission-Critical.
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
