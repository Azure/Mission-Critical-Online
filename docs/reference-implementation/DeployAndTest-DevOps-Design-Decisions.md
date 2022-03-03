# DevOps Design Decisions

## Source Code Repository

**GitHub** was the clear choice for the Azure Mission-Critical reference implementations as it is the leading code sharing platform in terms of Git repositories.

## CI/CD pipelines

**Azure Pipelines**. This part of the Azure DevOps (ADO) service is being used by Azure Mission-Critical for all build, test and release tasks. It is a well proven and feature rich tool set that is used in many organizations, both when targeting Azure and even when not targeting Azure as the deployment environment.

GitHub Actions was considered instead of ADO and for build-related tasks (CI) it would have worked equally well - with the added benefit that source code and pipeline would have lived in the same place. However, Azure Pipelines were chosen because of richer Continuous Deployment (CD) capabilities. It is expected that GitHub Actions will reach parity with ADO in the future, but for now, ADO is the best choice.

**Build Agents**. The online reference implementation of Azure Mission-Critical uses Microsoft Hosted build agents as this removes any management burden on the developers to maintain and update the build agent whilst also making start up times for build jobs quicker. The exception is when using the [connected](https://github.com/Azure/Mission-Critical-Connected) version of the Azure Mission-Critical reference implementation, which does require the use of self-hosted Build Agents.

See [DevOps Pipelines](/.ado/pipelines/README.md) for more details about the concrete pipeline implementation.

---
[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
