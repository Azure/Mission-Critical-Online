# Azure Mission-Critical - Reference Implementation - Solution Guide

As outlined in the [Azure Mission-Critical introduction](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-overview) (➡️ `docs.microsoft.com`), Azure Mission-Critical has been developed to help customers with business critical systems to design and build a best practice Azure based solution that maximizes reliability. Azure Mission-Critical does this by giving customers prescriptive and opinionated guidance on how to build this best practice system as well as providing production ready technical artifacts for customers to quickly build that best practice system in their own environment.

Where the Azure Mission-Critical [Design Principles](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-design-principles) (➡️ `docs.microsoft.com`) provide the thought and justification behind the Azure Mission-Critical architecture and product choices, this part of the repository tells you how to build your own production-ready Azure Mission-Critical solution using the technical artifacts provided within this repository i.e. Infrastructure-As-Code templates and CI/CD pipelines (via GitHub and Azure DevOps).

As with the Azure Mission-Critical Design Guidelines, the Reference Implementation section is divided into eight Design Areas, each giving clear instructions on how the solution is configured.  When you are ready to start, the [Getting Started](./reference-implementation/Getting-Started.md) guide outlines the process and required steps to deploy Azure Mission-Critical in your environment, including preparing Azure DevOps pipelines.

## Design Areas

- [Application Design](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-app-design)
- [Application Platform](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-app-platform)
- [Networking anc connectivity](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-networking)
- [Data Platform](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-data-platform)
- [Deployment and testing](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-deploy-test#deployment-devops)
- [Health Modeling](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-health-modeling)

### Additional content

- [Business Continuity / Disaster Recovery](./reference-implementation/AppDesign-BCDR-Global.md)
- [SLO and Availability](./reference-implementation/AppDesign-SLO-Availability.md)
- [Operational Procedures](./reference-implementation/OpProcedures-Operational-Procedures.md)
  - [Key and Secret Rotation](./reference-implementation/OpProcedures-KeyRotation.md)
- [Networking Custom Domains](./reference-implementation/Networking-Custom-Domains.md)
- [Adding API Management](./reference-implementation/Api-Management.md)
- [ESLZ Alignment](./reference-implementation/ESLZ-Alignment.md)

## Source Code Documentation

- [Infrastructure](/src/infra/README.md)
  - [Terraform-based IaC](/src/infra/workload/README.md)
  - [Grafana](/src/infra/monitoring/grafana/README.md)
- [Application](/src/app/README.md)
  - [Catalog Service](/src/app/AlwaysOn.CatalogService/README.md)
  - [Health Service](/src/app/AlwaysOn.HealthService/README.md)
  - [Background Processor](/src/app/AlwaysOn.BackgroundProcessor/README.md)
  - [UI Application](/src/app/AlwaysOn.UI/README.md)
  - [Unit Tests](/src/app/AlwaysOn.Tests/README.md)
  - [Unit Tests](/src/app/AlwaysOn.Tests/README.md)
- [Deployment Pipelines](/.ado/pipelines/README.md)
- [Configuration](/src/infra/README.md)
- [Testing](/src/testing/README.md)

## Helpful Information

- [Getting started](./reference-implementation/Getting-Started.md) (or using [CLI](./reference-implementation/Getting-Started-CLI.md)) outlines the process and required steps to deploy Azure Mission-Critical in your environment, including preparing Azure DevOps pipelines. It should be read in tandem with the Reference Implementation guidance.
- [SLO and Availability](./reference-implementation/AppDesign-SLO-Availability.md) outlines the SLO for Azure Mission-Critical (99.95%) and how this figure was calculated.
- [Troubleshooting](./reference-implementation/Troubleshooting.md) collects solutions to known issues during development and deployment.

## Helpful Information

- [Getting started](./reference-implementation/Getting-Started.md) (or using [CLI](./reference-implementation/Getting-Started-CLI.md)) outlines the process and required steps to deploy Azure Mission-Critical in your environment, including preparing Azure DevOps pipelines. It should be read in tandem with the Reference Implementation guidance.
- [SLO and Availability](./reference-implementation/AppDesign-SLO-Availability.md) outlines the SLO for Azure Mission-Critical (99.95%) and how this figure was calculated.
- [Troubleshooting](./reference-implementation/Troubleshooting.md) collects solutions to known issues during development and deployment.

## Documentation Conventions

- Overarching topics concerning the Azure Mission-Critical architecture, design principles, design decisions, and cross-component integration are documented as separate markdown documents within the `/docs/` folder.

- Each source code component for the reference implementation has it's own `README.md` file which explains how that particular component works, how it is supposed to be used, and how it may interact with other aspects of the Azure Mission-Critical solution.
  - Within the `main` branch, each `README.md` file must accurately represent the state of the associated component which will serve as a core aspect of PR reviews. Any modifications to source components must therefore be reflected in the documentation as well.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
