[![Always On Application](./icon.png "Azure AlwaysOn Application")](./README.md)

## Welcome to Azure AlwaysOn

AlwaysOn is a **design methodology and approach to building highly-reliable cloud-native applications on Microsoft Azure for business-critical and mission-critical workloads**. AlwaysOn extends the [Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework) by providing prescriptive and opinionated guidance for business-critical scenarios where certain application characteristics are implicit, such as maximum reliability.

This repository contains everything required to understand and implement an AlwaysOn application on Azure, and is comprised of the following:

1. **Prescriptive Design Guidelines**: A cloud-native design methodology to guide readers through the architectural process of building a mature business-critical application on Microsoft Azure, articulating key design considerations and requisite design decisions along with associated trade-offs.

2. **Fully Functional Production-Ready Reference Implementation**: An end-to-end reference implementation intended to provide a solution orientated basis to showcase business critical application development on Microsoft Azure, leveraging Azure-native platform capabilities to maximize reliability and operational effectiveness. More specifically, the reference implementation consists of:

    * Design and implementation guidance to help readers understand and use the AlwaysOn design methodology in the context of a particular industry scenario.
    * Production-ready technical artifacts including Infrastructure-as-Code (IaC) resources and Continuous-Integration/Continuous-Deployment (CI/CD) pipelines (GitHub and Azure DevOps) to deploy an AlwaysOn application with mature end-to-end operational wrappers.

## AlwaysOn Repository - Table of Contents

* [Introduction - What is AlwaysOn?](./docs/introduction/README.md) - Detailed introduction into AlwaysOn, the problem it is intended to solve and the value it can provide.
* [Design Guidelines](./docs/design-guidelines/README.md) - Prescriptive guidance aligned to 8 critical design areas guides users to design and build an AlwaysOn application, outlining a recommended decision process.
* [Reference Implementation Solution Guide](./docs/reference-implementation/README.md) - Everything required to understand and build a copy of the reference implementation
* [Reference Implementation Build Artifacts](./src/infra/README.md) - Contains the Infrastructure-as-Code artifacts, CI/CD pipelines, and application code required to deploy the preconfigured reference solution

## Helpful Information

* [Getting Started](./docs/reference-implementation/Getting-Started.md) outlines the process and required steps to deploy AlwaysOn in your environment, including preparing the Azure DevOps pipelines. It should be read in tandem with the [Reference Implementation Guide](./docs/reference-implementation/README.md).
* [Frequently Asked Questions](./docs/reference-implementation/FAQ.md) captures responses to common issues and challenges associated with leveraging AlwaysOn.
* [Full List of Documentation](./docs/README.md) contains a complete breakdown of the AlwaysOn repository to help navigate the contained guidance.

## Contributing

AlwaysOn is a community driven open source project that welcomes contributions as well as suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit the [CLA portal](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g. status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

For more details, please read [how to contribute](./CONTRIBUTE.md).

## Microsoft Sponsorship

The AlwaysOn project was created by the **Microsoft Customer Architecture Team (CAT)** who continue to actively sponsor the sustained evolution of the AlwaysOn project through the creation of additional reference implementations for common industry scenarios.
