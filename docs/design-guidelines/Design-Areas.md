# AlwaysOn Critical Design Areas

The 8 design areas below represent the architecturally significant topics which must be discussed and designed for when defining a target AlwaysOn application architecture. In this regard, this section of the repository is intended to provide prescriptive and opinionated guidance to support readers in designing an AlwaysOn solution.

- [Application Design](./App-Design.md)
- [Application Platform](./App-Platform.md)
- [Data Platform](./Data-Platform.md)
- [Health Modeling](./Health-Modeling.md)
- [Deployment and Testing](./Deploy-Testing.md)
- [Networking and Connectivity](./Networking.md)
- [Security](./Security.md)
- [Operational Procedures](./Operational-Procedures.md)

These 8 critical design areas will be explored at length within ensuing pages, for which critical review considerations and design recommendations are provided along with their broader design impact across other areas. Ultimately, the design areas are interrelated and decisions made within one area can impact or influence decisions across the entire design, so readers are encouraged to use the provided design guidance to navigate the key design decisions.

[![AlwaysOn-Design-Areas](/docs/media/AlwaysOn-Design-Areas.png "AlwaysOn Critical Design Areas")](./Principles.md)

## Reference Architecture

An AlwaysOn application architecture is defined by the various design decisions required to ensure both functional and non-functional business-requirements are fully satisfied. The target AlwaysOn architecture is therefore greatly influenced by the relevant business requirements, and as a result may vary between different application contexts.  

The image below represents a target technical state recommended for business-critical applications on Azure. It leverages a reference set of business requirements to achieve an optimised architecture for different target reliability tiers.

![WhatIsAlwaysOn](/docs/media/Architecture-Public.png)

> The [foundational reference implementation](https://github.com/Azure/AlwaysOn/blob/main/docs/reference-implementation/README.md) provides a solution orientated showcase for this reference architecture, demonstrating how this design can be implemented alongside the operational wrappers required to maximize reliability and operational effectiveness.

## Cross Cutting Concerns

There are several critical cross-cutting themes which traverse the 8 design areas and are contextualized below for subsequent consideration within each design area.

### Scale Limits

Various [limits and quotas within the Azure platform](https://docs.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits) may have a significant bearing on large AlwaysOn application scenarios and must be appropriately considered by the target architecture.

> Limits and quotas may change as Azure seeks to further enhance the platform and user experience.

- Leverage subscriptions as scale units, scaling out resources and subscriptions as required
- Employ a scale unit approach for resource composition, deployment, and management
- Ensure scale limits are considered as part of capacity planning
- If available, use data gathered about existing application environments to explore which limits might be encountered

### Automation

Maximize reliability and operability through the holistic automation of all deployment and management activities.

- Automate CI/CD deployments for all application components
- Automate application management activities, such as patching and monitoring
- Use declarative management semantics over imperative
- Prioritize templating over scripting; only use scripting when it is not possible to use templates

### Azure Roadmap Alignment & Regional Service Availability

Align the target architecture with the Azure platform roadmap to inform the application trajectory, and ensure that required services and features are available within the chosen deployment regions.

- Align with Azure engineering roadmaps and regional role out plans
- Unblock with preview services or by taking dependencies on the Azure platform roadmap
- Only take a dependency on committed services and features; validate roadmap dependencies with Microsoft engineering product groups

### Enterprise-Scale and Azure Landing Zone Integration

[Enterprise-Scale](https://github.com/azure/enterprise-scale) provides prescriptive architectural guidance to define a reliable and scalable shared-service platform for enterprise Azure deployments with requisite centralised governance. 

AlwaysOn can integrate seamlessly within an Azure Landing Zone as part of an Enterprise-Scale architecture. More specifically, an AlwaysOn application can be deployed in both the *Online* or *Corp. Connected* Landing Zone formats as demonstrated within the image below.

![AlwaysOn and Enterprise-Scale Integration](/docs/media/AlwaysOn-ESLZ.gif "AlwaysOn and Enterprise-Scale Integration")

It is crucial to understand and identify in which connectivity scenario an AlwaysOn application requires since Enterprise-Scale supports different landing zones archetypes separated into different Management Group scopes.

- In the context of an *Online* Landing Zone archetype, AlwaysOn operates as a completely independent solution, without any direct corporate network connectivity to the rest of the Enterprise-Scale architecture. The application will, however, be further safeguarded through the [*policy-driven management*]((https://github.com/Azure/Enterprise-Scale/wiki/How-Enterprise-Scale-Works#enterprise-scale-design-principles)) approach which is foundational to Enterprise-Scale, and will automatically integrate with centralized platform logging through policy.

  - A *Online* deployment can only really consider a public AlwaysOn application deployment since there is no private corporate connectivity provided.

- When deployed in a *Corp. Connected* Landing Zone context, the AlwaysOn application takes a dependency on the Enterprise-Scale platform to provide connectivity resources which allow for integration with other applications and shared services existing on the platform. This necessitates some transformation on-top of the *Online* integration approach, since some foundational resources are expected to exist up-front as part of the shared-service platform. More specifically, the AlwaysOn regional deployment stamp should not longer encompass an ephemeral Virtual Network or Azure Private DNS Zone since these will exist within the Enterprise-Scale *connectivity* subscription. 
  - A *Corp. Connected* deployment can consider both a public or private AlwaysOn application deployment.

> The AlwaysOn reference implementation is fully aligned with the Enterprise-Scale architectural approach and is immediately deployable within an *Online* Landing Zone subscription.

---

|Previous Page|Next Page|
|--|--|
|[AlwaysOn Design Principles](./Principles.md)|[Application Design](./App-Design.md)

---

|Design Guidelines|
|--|
|[How to use the AlwaysOn Design Guidelines](./README.md)
|[AlwaysOn Design Principles](./Principles.md)
|[AlwaysOn Design Areas](./Design-Areas.md)
|[Application Design](./App-Design.md)
|[Application Platform](./App-Platform.md)
|[Data Platform](./Data-Platform.md)
|[Health Modeling and Observability](./Health-Modeling.md)
|[Deployment and Testing](./Deploy-Testing.md)
|[Networking and Connectivity](./Networking.md)
|[Security](./Security.md)
|[Operational Procedures](./Operational-Procedures.md)

---

[AlwaysOn - Full List of Documentation](/docs/README.md)
