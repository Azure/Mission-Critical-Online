# Azure Mission-Critical - Reference Implementation - Solution Guide

As outlined in the [Azure Mission-Critical introduction](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-overview) (➡️ `Azure/Mission-Critical`), Azure Mission-Critical has been developed to help customers with business critical systems to design and build a best practice Azure based solution that maximizes reliability. Azure Mission-Critical does this by giving customers prescriptive and opinionated guidance on how to build this best practice system as well as providing production ready technical artifacts for customers to quickly build that best practice system in their own environment.

Where the Azure Mission-Critical [Design Principles](https://docs.microsoft.com/azure/architecture/framework/mission-critical/mission-critical-design-principles) (➡️ `Azure/Mission-Critical`) provide the thought and justification behind the Azure Mission-Critical architecture and product choices, this part of the repository tells you how to build your own production-ready Azure Mission-Critical solution using the technical artifacts provided within this repository i.e. Infrastructure-As-Code templates and CI/CD pipelines (via GitHub and Azure DevOps).

As with the Azure Mission-Critical Design Guidelines, the Reference Implementation section is divided into 8 Critical Design Areas, each giving clear instructions on how the solution is configured.  When you are ready to start, the [Getting Started](./Getting-Started.md) guide outlines the process and required steps to deploy Azure Mission-Critical in your environment, including preparing Azure DevOps pipelines.

## Critical Design Areas

### Application Design

- [Application Design](./AppDesign-Application-Design.md)
- [Business Continuity/ Disaster Recovery](./AppDesign-BCDR-Global.md)
- [SLO and Availability](./AppDesign-SLO-Availability.md)

### Application Platform

- [Application Platform Design Decisions](/src/infra/README.md)

### Data Platform

- [Data Platform Design Decisions](./DataPlatform-Design-Decisions.md)

### Health Modelling

- [Application Health Service](/src/app/AlwaysOn.HealthService/README.md)
- [Monitoring](./Health-Monitoring.md)
- [Alerting](./Health-Alerting.md)
- [Failure Analysis](./Health-Failure-Analysis.md)

### Deployment and Testing

- [Deployment - DevOps Design Decisions](./DeployAndTest-DevOps-Design-Decisions.md)
- [Deployment - Zero Downtime Update Strategy](./DeployAndTest-DevOps-Zero-Downtime-Update-Strategy.md)
- [Testing - Failure Injection](./DeployAndTest-Testing-FailureInjection.md)

### Networking and Connectivity

- [Networking Design Decisions](./Networking-Design-Decisions.md)
- [Networking Custom Domains](./Networking-Custom-Domains.md)

### Operational Procedures

- [Operational Procedures](OpProcedures-Operational-Procedures.md)
- [Key and Secret Rotation](OpProcedures-KeyRotation.md)

## Source Code Documentation

- [Infrastructure](/src/infra/README.md)
  - [Terraform-based IaC](/src/infra/workload/README.md)
  - [Grafana](/src/infra/monitoring/grafana/README.md)
- [Application](/src/app/README.md)
  - [Catalog Service](/src/app/AlwaysOn.CatalogService/README.md)
  - [Health Service](/src/app/AlwaysOn.HealthService/README.md)
  - [Background Processor](/src/app/AlwaysOn.BackgroundProcessor/README.md)
  - [UI Application](/src/app/AlwaysOn.UI/README.md)
- [Deployment Pipelines](/.ado/pipelines/README.md)
- [Configuration](/src/infra/README.md)
- [Testing](/src/testing/README.md)

## Helpful Information

- [Getting started](Getting-Started.md) outlines the process and required steps to deploy Azure Mission-Critical in your environment, including preparing Azure DevOps pipelines. It should be read in tandem with the Reference Implementation guidance.
  - [Getting started using CLI](Getting-Started-CLI.md) - same as the guide above but contains instructions on how to create the setup using CLI instead of the ADO portal experience.
- [SLO and Availability](AppDesign-SLO-Availability.md) outlines the SLO for Azure Mission-Critical (99.95%) and how this figure was calculated.
- [ESLZ Alignment](ESLZ-Alignment.md) outlines how Azure Mission-Critical aligns with and compliments the Enterprise Scale Landing Zones.
- [Troubleshooting](Troubleshooting.md) collects solutions to known issues during development and deployment.

## Optional Additions

- [Adding API Management](Api-Management.md)

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
