# AlwaysOn Introduction

Getting started on Azure is now easier than ever, however, building mission-critical and business-critical solutions that are highly reliable on the platform remains a challenge for three main reasons:

- Designing a reliable application at scale is complex and requires extensive platform knowledge to select the right technologies and optimally configure them as an end-to-end solution.

- Failure is inevitable in any complex distributed system, and the solution must therefore be architected to handle failures and correlated or cascading impact, which is a change in mindset for many developers and architects entering the cloud from an on-premises environment; reliability engineering is no longer an infrastructure topic, but should be a first-class concern within the application development process.

- Operationalizing mission-critical and business-critical solutions requires a high degree of engineering rigor and maturity throughout the end-to-end engineering lifecycle as well as the ability to learn from failure.

AlwaysOn strives to address the challenge of building highly reliable applications on Azure, leveraging lessons from numerous customer applications and first-party solutions, such as Xbox Live, to provide actionable and authoritative guidance. AlwaysOn therefore extends Well-Architected best practices to provide the technical foundation for building and operating a highly reliable business-critical solution on Azure at-scale.

More specifically, AlwaysOn provides a design methodology to guide readers through the design process of building a highly reliable cloud-native application on Azure, explaining key design considerations and requisite design decisions along with associated trade-offs. Additionally, AlwaysOn provides a gallery of fully functional production-ready reference implementations aligned to common industry scenarios, which can serve as a basis for further solution development.

## What is AlwaysOn?

The 'AlwaysOn' name refers to the highly-reliable and business-critical nature of the architectural pattern it represents, where for given set of business requirements, the application should always be operational and available. Because of this focus on reliability, the AlwaysOn design methodology adopts a globally distributed and highly scalable approach to building applications on Azure.

However, this globally distributed approach to achieve high reliability comes at a development cost which may not be justifiable for every workload scenario. We therefore strongly advocate that AlwaysOn design decisions are driven by your solution's business requirements and informed by the opinionated guidance provided within this repository.

## What Problem Does AlwaysOn Solve?

Building mission-critical and business-critical applications on Azure requires significant technical expertise and engineering investment to appropriately select and piece together Azure services and features. This complexity often leads to sub-optimal approaches as customers struggle to align with evolving best practices, particularly given the relative prioritization of business needs over platform fundamentals for many customers.

AlwaysOn addresses this complex consumption experience by expanding the [Well-Architected Framework](https://docs.microsoft.com/azure/architecture/framework/) within the context of mission-critical and business-critical application scenarios, providing prescriptive and opinionated technical guidance and streamlined consumption mechanisms for common industry patterns through solution orientated reference implementations; ‘turn-key’ AlwaysOn solutions that are implicitly aligned with Microsoft best practices.

[![Always On Positioning](/docs/media/AlwaysOnPositioning.png)](./README.md)

## What Does AlwaysOn Provide?

1. A cloud-native design methodology with **prescriptive design guidelines** to help readers navigate the architectural process of building a mature mission-critical application on Microsoft Azure, articulating key design considerations and requisite design decisions along with associated trade-offs.

2. **Fully functional production-ready reference implementations** intended to provide a solution orientated basis to showcase mission-critical application development on Microsoft Azure, leveraging Azure-native platform capabilities to maximize reliability and operational effectiveness. More specifically, each reference implementation consists of:

- Design and implementation guidance to help readers understand and use the AlwaysOn design methodology in the context of a particular industry scenario.

- Production-ready technical artifacts including Infrastructure-as-Code (IaC) resources and Continuous-Integration/Continuous-Deployment (CI/CD) pipelines (GitHub and Azure DevOps) to deploy an AlwaysOn application with mature end-to-end operational wrappers.

Important Note: AlwaysOn will continue to develop additional reference implementations for common industry scenarios, with several implementations currently under development.

---

|Previous Page|Next Page|
|--|--|
|[Home](../../README.md)|[How to use the AlwaysOn Design Guidelines](../design-guidelines/README.md)

---

[AlwaysOn - Full List of Documentation](/docs/README.md)
