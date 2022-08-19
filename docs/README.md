# Azure Mission-Critical - Full List of Documentation

## Azure Mission-Critical Landing Page

- [Landing Page](../README.md)

## Introduction to Azure Mission-Critical

- [Introduction](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-overview) (➡️ `docs.microsoft.com`)

## Azure Mission-Critical Reference Implementation Guide

- [Overview](./reference-implementation/README.md)
  - [Getting started](./reference-implementation/Getting-Started.md) ([using CLI](./reference-implementation/Getting-Started-CLI.md))
  - [Troubleshooting](./reference-implementation/Troubleshooting.md)
  - [Frequently Asked Questions (FAQs)](./reference-implementation/FAQ.md)
- Design Areas (➡️ `docs.microsoft.com`)
  - [Application Design](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-app-design)
  - [Application platform](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-app-platform)
  - [Networking and connectivity](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-networking)
  - [Data platform](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-data-platform)
  - [Deployment and Testing](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-deploy-test)
  - [Health Modeling](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-health-modeling)
- Additional content
  - [Business Continuity / Disaster Recovery](./reference-implementation/AppDesign-BCDR-Global.md)
  - [SLO and Availability](./reference-implementation/AppDesign-SLO-Availability.md)
  - [Custom Domains](./reference-implementation/Networking-Custom-Domains.md)
  - [Operational Procedures](./reference-implementation/OpProcedures-Operational-Procedures.md)
  - [Key and Secret Rotation](./reference-implementation/OpProcedures-KeyRotation.md)
  - [ESLZ Alignment](./reference-implementation/ESLZ-Alignment.md)

## Source Code README Files

- [Infrastructure](/src/infra/README.md)
  - [Terraform-based IaC](/src/infra/workload/README.md)
  - [Grafana](/src/infra/monitoring/grafanapanel/README.md)
- [Application](/src/app/README.md)
  - [Catalog Service](/src/app/AlwaysOn.CatalogService/README.md)
  - [Health Service](/src/app/AlwaysOn.HealthService/README.md)
  - [Background Processor](/src/app/AlwaysOn.BackgroundProcessor/README.md)
  - [Unit Tests](/src/app/AlwaysOn.Tests/README.md)
  - [UI Application](/src/app/AlwaysOn.UI/README.md)
- [Deployment Pipelines](/.ado/pipelines/README.md)
- [Configuration](/src/infra/README.md)
- [Testing](/src/testing/README.md)

---

## Documentation Conventions

- Overarching topics concerning the Azure Mission-Critical architecture, design principles, design decisions, and cross-component integration are documented as separate markdown documents within the `/docs/` folder.

- Each source code component for the reference implementation has it's own `README.md` file which explains how that particular component works, how it is supposed to be used, and how it may interact with other aspects of the Azure Mission-Critical solution.
  - Within the `main` branch, each `README.md` file must accurately represent the state of the associated component which will serve as a core aspect of PR reviews. Any modifications to source components must therefore be reflected in the documentation as well.
