# Enterprise Scale Landing Zones

The [Enterprise-Scale architecture](https://github.com/azure/enterprise-scale) provides prescriptive guidance coupled with Azure best practices, and it follows design principles across the critical design areas for organizations to define their Azure architecture.

It is crucial to understand and identify in which connectivity scenario an AlwaysOn application will be used and deployed. Enterprise-Scale supports different landing zones separated into different Management Group scopes.

This scope will define the guardrails with Azure Policy and RBAC plus will provide several shared services from which an AlwaysOn application will benefit. DNS, Routes (UDR), VNet and its configuration are the most common services that will be provided from a central platform team (NetOps).
Organizations require centralized platform logging and monitoring capabilities that provides a holistic view for Operation (Ops) and Security (SecOps) teams. AlwaysOn leverages the central Management subscription recommended by Enterprise-scale landing zone and sends, enforced by Azure Policy, the required logs to the Log Analytics Workspace.

The three most common deployment scenarios are:
- Public application endpoint **without** corporate network connectivity. (online)
- Public application endpoint **with** corporate network connectivity (management and backend service connectivity). (corp)
- Private application endpoint **without** public connectivity. (corp)

This diagram visualizes the relationship and dependency an AlwaysOn application can take on Enterprise-Scale landing zone.

![AlwaysOn - ESLZ dependency](/docs/media/AlwaysOn-ESLZ.gif "ESLZ dependency")

> Note: The AlwaysOn reference implementation is aligned with the Enterprise-Scale architecture and was successfully deployed and validated in an "online" landing zone (subscription).

See [Enterprise-Scale](https://github.com/Azure/Enterprise-Scale/) and [Enterprise-Scale design principles](https://github.com/Azure/Enterprise-Scale/wiki/How-Enterprise-Scale-Works#enterprise-scale-design-principles) for more information.



---
[AlwaysOn - Full List of Documentation](/docs/README.md)
