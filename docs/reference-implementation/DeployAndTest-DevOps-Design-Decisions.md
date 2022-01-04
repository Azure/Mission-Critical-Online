# DevOps Design Decisions

# Source Code Repository

**GitHub** was the clear choice for the AlwaysOn reference implementation as it is the leading code sharing platform in terms of Git repositories.

## CI/CD pipelines

**Azure Pipelines**. This is part of the Azure DevOps (ADO) service, is being used by AlwaysOn for all build, test and release tasks. It is a well proven and feature rich tool set that is used in many organizations, both when targeting Azure and even when not targeting Azure as the deployment environment.

GitHub Actions was considered instead of ADO and for build-related tasks (CI) it would have worked equally well - with the added benefit that source code and pipeline would have lived in the same place. However, owing to Azure Pipelines richer Continuous Deployment (CD) capabilities, this was chosen. It is expected that GitHub Actions will reach parity with ADO in the future, but for now, ADO is the best choice.

**Build Agents**. The foundational reference implementation of AlwaysOn uses Microsoft Hosted build agents as this removes any management burden on the developers to maintain and update the build agent whilst also making start up times for build jobs quicker. The exception is when using [private mode](https://github.com/Azure/AlwaysOn-foundational-private) of the Reference Implementation, which does require the use of self-hosted Build Agents.

See [DevOps Pipelines](/.ado/pipelines/README.md) for more details about the concrete pipeline implementation.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)
