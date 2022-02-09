# AlwaysOn - Full List of Documentation

## AlwaysOn Landing Page

* [Landing Page](../README.md)

## Introduction to AlwaysOn

* [Introduction](https://github.com/Azure/AlwaysOn/blob/main/docs/introduction/README.md) (➡️ `Azure/AlwaysOn`)

## AlwaysOn Reference Implementation Guide

* [Overview](./reference-implementation/README.md)
* [Getting Started](./reference-implementation/Getting-Started.md)
* [Frequently Asked Questions (FAQs)](./reference-implementation/FAQ.md)
* [Critical Design Areas](./reference-implementation/README.md#Critical-Design-Areas)
  * Application Design
    * [Application Design](./reference-implementation/AppDesign-Application-Design.md)
    * [Business Continuity / Disaster Recovery](./reference-implementation/AppDesign-BCDR-Global.md)
    * [SLO and Availability](./reference-implementation/AppDesign-SLO-Availability.md)
  * Data Platform
    * [Data Platform Design Decisions](./reference-implementation/DataPlatform-Design-Decisions.md)
  * Health Modelling
    * [Monitoring](./reference-implementation/Health-Monitoring.md)
    * [Alerting](./reference-implementation/Health-Alerting.md)
    * [Failure Analysis](./reference-implementation/Health-Failure-Analysis.md)
  * Deployment and Testing
    * [Deployment - DevOps Design Decisions](./reference-implementation/DeployAndTest-DevOps-Design-Decisions.md)
    * [Deployment - Zero Downtime Update Strategy](./reference-implementation/DeployAndTest-DevOps-Zero-Downtime-Update-Strategy.md)
    * [Testing - Failure Injection](./reference-implementation/DeployAndTest-Testing-FailureInjection.md)
  * Networking and Connectivity
    * [Networking Design Decisions](./reference-implementation/Networking-Design-Decisions.md)
    * [Custom Domains](./reference-implementation/Networking-Custom-Domains.md)
  * Operational Procedures
    * [Operational Procedures](./reference-implementation/OpProcedures-Operational-Procedures.md)
    * [Key and Secret Rotation](./reference-implementation/OpProcedures-KeyRotation.md)
* [ESLZ Alignment](./reference-implementation/ESLZ-Alignment.md)

## Source Code README Files

* [Infrastructure](/src/infra/README.md)
  * [Terraform-based IaC](/src/infra/workload/README.md)
  * [Grafana](/src/infra/monitoring/grafanapanel/README.md)
* [Application](/src/app/README.md)
  * [Catalog Service](/src/app/AlwaysOn.CatalogService/README.md)
  * [Health Service](/src/app/AlwaysOn.HealthService/README.md)
  * [Background Processor](/src/app/AlwaysOn.BackgroundProcessor/README.md)
  * [Unit Tests](/src/app/AlwaysOn.Tests/README.md)
  * [UI Application](/src/app/AlwaysOn.UI/README.md)
* [Deployment Pipelines](/.ado/pipelines/README.md)
* [Configuration](/src/infra/README.md)
* [Testing](/src/testing/README.md)

---

## Documentation Conventions

* Overarching topics concerning the AlwaysOn architecture, design principles, design decisions, and cross-component integration are documented as separate markdown documents within the `/docs/` folder.

* Each source code component for the reference implementation has it's own `README.md` file which explains how that particular component works, how it is supposed to be used, and how it may interact with other aspects of the AlwaysOn solution.
  * Within the `main` branch, each `README.md` file must accurately represent the state of the associated component which will serve as a core aspect of PR reviews. Any modifications to source components must therefore be reflected in the documentation as well.
