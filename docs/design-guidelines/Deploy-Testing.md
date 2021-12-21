# Deployment and Testing

## Introduction

The deployment of a solution is a critical consideration for an AlwaysOn system; this section looks at how best to eradicate any downtime during those deployments. Deployments are not just about how-to deliver updates to the users, but also how to address maintenance and issues that threaten operations e.g. new security measures or scaling operations. Therefore, with many deployment types covering a wide gamut of activity, they are often a daily activity and must be a critical consideration in an AlwaysOn solution. The reason deployments and methods are so important to AlwaysOn is that failed deployments are a major cause of many outages. As such, there is a clear need for those to be highly available and factored into a healthy deployment pipeline. The goals of any deployment should be:

- To include prerelease testing to ensure (wherever possible) that updates do not introduce any new defects.
- To eliminate downtime - Users should be able to continue their work uninterrupted.
- The deployment solution must be Highly Available and be resilient to potential outages.
- To be fully automated, requiring no manual intervention.

To achieve the above goals, the key principle is the requirement of multiple, staged environments into which all changes are deployed and fully tested (in sequence) before released to the final Production environment.

This chapter discusses the following key areas:

- Environments
- Deployment toolsets
- Infrastructure Deployments
- Branching
- Container Registry
- Secret Management
- Testing
- AI for DevOps

## Environments

### Design Recommendations

- Clearly define the number of staging environments and their purpose.
- All environments should resemble the Production environment as closely as possible.
- Avoid sharing components between environments, possible exceptions are downstream API endpoints or Firewalls.
- Ensure that there is a process for deploying code from feature branches to an environment.
- Use a blue/green approach for Production environment go-live to achieve zero-downtime deployment.

### Design Considerations

Before considering which tools to use for deployment, you must consider the environments you have/need. Most Microsoft customers have a variety of Test, Development and Production environments. Some of these exist permanently, whereas some will only exist for short periods of time for limited purposes. The solution may be deployed in several environments at any one time, or in sequence prior to go live. However only a few, e.g. the Production environments, will need to be AlwaysOn since they are mission-critical.

Development environments, even if they do not need to be AlwaysOn, are an essential part of any system and have a variety of purposes. These include the development of Infrastructure-as-Code (IaC) artifacts such as ARM or Terraform templates (and deployments of these), they can also be used as a data source for local machine testing or to perform validation of full deployments during and post deployment. It is likely that application development teams will have several Development environments (which must each serve a clear purpose), and although these should be available as required, they often only exist for short periods of time.  As a rule of thumb, Development environments can share the lifecycle of the code branch - As such, keeping environments short lived saves cost, and prevents the configuration drifting from the code base.

Production environments are those for which AlwaysOn is designed and, therefore, which must support high availability, resiliency and scaling.  To achieve zero interruptions to the user experience, customers should have a minimum of 2 Production environments during deployment (often called a *Blue/ Green* deployment). This allows the new code to be deployed and tested in one of those environments, and once ready, for traffic to be slowly migrated to the new environment.

This dual Production environment approach can be implemented at the application level or at the infrastructure level:

- **Application Level**. An application-level deployment would deploy the new code to a staging location within the existing infrastructure (For example, for Azure App Service this could be a secondary deployment slot or, for AKS this could be a separate pod deployment on each node). After a successful deployment, the slot will be swapped or the service definition updated. The advantage of this approach is that it is cheaper and faster than a full infrastructure deployment.

- **Infrastructure Level**.  These deployments contain all of the infrastructure within the deployment scope. All of the Azure resources e.g. Event Hubs, AKS Clusters and Azure Cache for Redis are deployed and subsequently the application code is deployed to that infrastructure. When the new deployment has been tested and traffic has been fully switched over and, the old infrastructure can then be decommissioned. The advantage of this approach is that any changes are fully deployed and tested before then switching traffic between environments and can therefore be achieved with zero downtime (it should be noted that deployments may take longer to complete using this method as it takes longer to deploy infrastructure than applications).

Both of the above approaches allow utilization of a *"Blue/Green"* deployment. This method uses a minimum of 2 identical Production environments (where one one of those is 'active'/blue and serving user traffic, whilst a second 'non-active'/green Production environment is ready to receive the new deployment).  Once the deployment is completed and tested, traffic is gradually switched from the blue environment to the green. If the load transfer is successful, that new environment becomes the new 'active' Production environment and the old, now 'non-active' environment can be decommissioned.  If there are issues within the new deployment, the deployment can be aborted and traffic can either remain in the old 'active' environment, or be directed back to it.  This gives customers a clear fall back plan and minimizes the potential for reliability issues e.g. by no longer having to cut traffic to Production to rectify an issue during a faulty deployment.

The orchestration of the user traffic between the blue and green environments is controlled by a global load balancer (e.g. Azure Front Door). To achieve zero downtime as required, the above migration process and the load balancer controlling it should be fully automated. The process would typically be as follows (assuming blue is active and green is the newly deployed environment):

- Add a green backend endpoint to all the backends in Azure Front Door using a low traffic volume/ weight (e.g. 10%)
- After verifying that the low traffic volume on green is being managed as expected, gradually increase the traffic in steps until it reaches 100%.
- Whilst increasing traffic, ensure to allow a short ramp-up period to catch faults which may not come to light immediately.
- Once all traffic has been migrated to switched to the new green environment, remove the blue backend from the global load balancer.
- Decommission the no longer active blue environment ensuring that any connections established while this environment was active are also closed and any queues are drained before removing associated resources.

For the next deployment, this process would be repeated with blue and green reversed. While blue and green environments *may* be reused each time, it is recommended to deploy a new infrastructure for each new deployment, ensuring that the new environment is completely free of potential configuration drift Additionally, removing unused resources between deployments will save costs.

## Deployment Toolsets

### Design Recommendations

- Understand the availability SLA of your deployment toolsets and consider these against the requirements of AlwaysOn when selecting which of them to use.
- When running a multi-region, active-passive setup for High Availability reasons, ensure that your failover orchestration and/or scaling operations are also capable of working independently in multiple regions.

### Design considerations

For deployment and testing, there are two different but largely overlapping Azure native toolsets - GitHub _Actions_ and Azure DevOps (ADO) _Pipelines_. Both platforms have pros and cons:

- GitHub is well known with all developers and open source projects.
- ADO is more mature in deployment pipelines, gates and approvals.

Customers can achieve a lot using GitHub Actions and it continues to improve, but, it is not yet as comprehensive as ADO (Aug 2021).

The capabilities required for implementing an AlwaysOn solution are available in both suites, it is also possible to use both simultaneously and to utilize the best features of each - A common approach is to hold code repositories in GitHub whilst using the deployment pipelines in ADO.  Although this makes sense in many respects, it should be noted that this dual approach to deployments now inherently relies on two different services and therefore adds an element of complexity and risk.

It must be noted that both GitHub and ADO instances are hosted in a single region of Azure (data is replicated across regions but only for Disaster Recovery purposes) and although for normal operation this would not matter, this should be considered in the spirit of AlwaysOn. For example, consider a scenario where your traffic is spread over West Europe and North Europe (with West Europe hosting your ADO instance). If West Europe experiences an outage (including ADO), North Europe would automatically now handle all of your traffic, but, if you need to add Scale Units to North Europe to enable this failover and this action depends on ADO to performing that task (which is now unavailable), your critical solution is now extremely constrained and may possible fail.

## Infrastructure Deployments

### Design recommendations

- Ensure the deployment of both infrastructure and applications is fully automated.
- Define your infrastructure as declarative templates, not as imperative scripts.
- Prohibit any manual operations against Production infrastructure.

### Design considerations

Applying the concept of 'Infrastructure-as-Code' (IaC), all Azure resources should be defined in declarative templates and maintained in a source control repository from where they can be deployed automatically using pipelines. Utilizing IaC ensures code consistency across environments, eliminates the possibility of human error during deployments and provides traceability and rollback capabilities.

Typically the IaC repository has two resource definitions: 'Global Resources' i.e. those that are deployed once in the solution e.g. Azure Front Door and Azure Cosmos DB and 'Regional' or *stamp* resources.

## Branching

### Design recommendations

- Create a branching strategy that details feature work and releases as a minimum.
- Apply restrictions to the Git environment using Git policies and/or branch policies to enforce the branching strategy.
- Have a clearly defined hotfix process and it's usage.

- Prioritize the use of [GitHub for source control](https://docs.github.com/en/code-security/supply-chain-security/managing-vulnerabilities-in-your-projects-dependencies/about-managing-vulnerable-dependencies).

### Design considerations

A fundamental aspect of source control is the branching strategy. While there are many valid ways to implement branching in source control, there are several types of branches that should in some way be implemented:

- Developers will carry out their daily work in _feature/*_ and _fix/*_ branches and these are the entry points for changes to the deployment. When they are pushed to _origin_, a process should be automatically triggered that runs automated testing. These tests must be passed before any Pull Request (PR) can be completed and any PR should require the review of at least one other team member before it can get merged.

- The _main_ branch is considered a continuously forward moving and stable branch and is mostly used for integration testing. Changes are only to be made to _main_ via PRs – a branch policy should be used to prohibit direct commits to it. Every time a PR is merged into _main_, it automatically kicks off a deployment against an integration environment. _main_ can be considered stable, meaning it should be safe to create a release of it at any given time.

- _release/*_ branches are created from the _main_ branch and are used to deploy to Production environments. _release/*_ branches will stay in the repository.

Restrictions to the branches should be applied as part of the branching strategy e.g. allowing only administrators to create release branches or enforcing naming conventions so that no other branches other than the above can be created.

A related consideration is how best to manage _hotfixes_. There may be rare occasions where a hotfix is urgently required and that needs to bypass the regular release process but instead is applied directly into an existing release branch then subsequently deployed to the Production infrastructure. Examples of hotfixes may include critical security updates or issues breaking the user experience that were not caught in testing and need to be addressed urgently. Typically, these hotfixes are created on a _fix/*_ branch and managed into the release branch. It is essential that the change is brought into _main_ as soon as practical so that is part of future releases and also avoids any reoccurrence of the issue. This process must only be used for small changes addressing urgent issues and with restraint - All changes should normally go through the regular release process whenever possible.

## Container Registry

### Design Recommendations

- The Azure Container Registry used to host container images should be hosted geographically as close as possible to the consuming compute resources, i.e. in the same Azure regions whenever possible.
- The container registry should be part of the 'global resources'.
- Geo-replication for container registry should be enabled.
- Use Azure AD integrated authentication to push and pull images instead of relying on access keys.
- When using container registries outside Azure, ensure that they have a proper SLA and adequate measures are taken to meet reliability and security requirements.

### Design Considerations

Container registries are one of the core components for a containerized application workload. One of their main purposes is to host container images that can be consumed by AKS. Most container registries use the same format and standards as introduced by Docker to both push and pull container images; they are therefore widely compatible and can be used as preference dictates. Coupled with publicly available container registries, most architectures contain either their own private container registry or a company-wide private container registry. These registries are the central place to build, store and manage container images.

In some scenarios it might make sense to replicate public container images into a private container registry to limit egress traffic, to increase availability or to avoid throttling.

- **Docker Hub**. Container images stored on Docker Hub (and on other public registries) live outside of Azure and outside of a given virtual network. This is not necessarily a problem, but can lead to a variety of potential issues with data exfiltration, service unavailability, throttling etc.

- [**Azure Container Registry (ACR)**](https://azure.microsoft.com/services/container-registry/). This is an Azure native service and offers a wide range of features including geo-replication, Azure AD authentication, automated container building and patching using ACR tasks. It also offers support in locking down a container registry to a given set of virtual networks and subnets.

## Secret Management

### Design Recommendations

- Secrets should be stored in Azure Key Vault.
- Managed identities should be used instead of service principals whenever possible.
- Secrets should be retrieved at application start up, not during deployment time or at runtime. 
- Implement coding patterns so when an authorization failure occurs at runtime, secrets are re-retrieved.
- Have a fully automated key-rotation process that runs periodically within the solution.
- Azure Key Vault instances should be deployed per stamp, not per solution.

### Design Considerations

Within AlwaysOn, secret management is a topic that needs to be considered not only through the lens of security but also that of reliability. Any secret management system that is selected for an AlwaysOn application must provide the required level of security and must also offer acceptable levels of availability.

Whilst designing an AlwaysOn system, the architect must decide at what point secrets get read from the secret management solution and injected into the application. Commonly three approaches are applied:

- **Deployment Time Retrieval**.  Retrieving secrets at deployment time (for example, injecting them as environment variables into a Kubernetes pod or into a Kubernetes secret), is advantageous as the secret management solution only needs to be available at deployment time - there are no direct dependencies after this. Only the deployment service principal needs to access the secrets which simplifies RBAC permissions on the secret management system.  This method, however, comes with a tradeoff - many of the security benefits of the secret management solution are not being used at this point and the solution instead relies solely on the access control to the application platform to keep secrets safe. In addition, and secret update or rotation will require a full redeployment in order to take effect.

- **On Application Start Retrieval**.  A second method is to retrieve and inject secrets at application start up. The benefit of this is that secrets can easily be updated or rotated and only a restart of the application is needed to fetch the latest value. This method ensures that secrets do not need to be stored on the application platform but can be held in memory only. For AKS, available implementations for this approach include the [CSI SecretStore driver for KeyVault](https://azure.github.io/secrets-store-csi-driver-provider-azure/) and [akv2aks](https://akv2k8s.io/). A native Azure solution [Azure Key Vault referenced App Settings](https://docs.microsoft.com/azure/app-service/app-service-key-vault-references) is also available. The disadvantage of this approach is that it creates a runtime dependency to your secret management solution; if this experiences an outage, application components already running **may** be able to continue serving requests, however, any restart or scale out operation will likely fail.

- **During Runtime Retrieval**.  The third method retrieves secrets at runtime from within the application itself. This is the most secure solution as even the application platform never has access to the secrets, however, it does require a connection from each application component to the secret management system. This makes it harder to test components individually and usually requires the use of an SDK. The application itself needs to be able to authenticate to the secret management system. For AKS the latter can be achieved using [Pod-managed Identities](https://docs.microsoft.com/azure/aks/use-azure-ad-pod-identity), but that is currently (as of August 2021) still in preview - Plus, it creates the same runtime dependency as the previous option.

Whilst there are various Key Management solutions available to customers, only Azure Key Vault provides a fully-managed PaaS option that integrates natively with most other Azure services and supports Availability Zone-redundancy and direct integration with Azure AD for authentication and authorization.

## Testing

Testing has a very critical role in both the application code and the infrastructure code. In order to meet the desired standards for security, quality, performance, scale, and availability, testing must be well planned and well designed as a core component of the platform architecture. Testing is a major concern for both the "Inner Loop” (local developer experience) and the "Outer Loop” (full DevOps cycle). The outer loop is when the code contributed by developers will begin the release pipeline processes on its journey to the Production environment. The scope of the following section is limited to testing being carried out in the outer loop i.e. for a product release. Testing categories include unit, build, static, security, integration, regression, UX, performance, capacity and failure injection. The order of the tests must also be considered as this will be reliant on various dependencies, such as the need to have a running application environment. Tests with shorter execution times should generally run earlier in the cycle where possible to increase testing efficiency.

For more detail about these loops for containerized applications follow these links [Inner Loop](https://docs.microsoft.com/dotnet/architecture/containerized-lifecycle/design-develop-containerized-apps/docker-apps-inner-loop-workflow) and [Outer Loop](https://docs.microsoft.com/dotnet/architecture/containerized-lifecycle/docker-devops-workflow/docker-application-outer-loop-devops-workflow).

### Design Recommendations

- All testing should be automated (both infrastructure and application).
- All test artifacts should be treated as code and maintained with version control.
- The results of the tests should be captured and analyzed for both individual test results and assessing testing trends over time.
- The test results should be continually evaluated for accuracy and coverage.
- The test infrastructure availability should meet or exceed your deployment and testing cycle SLA.
- Use PaaS CI/CD orchestration platforms such as Azure DevOps or GitHub Actions where possible.
- Load patterns for load testing must reflect real usage patterns.
- Run load tests prior to any new deployment or significant changes (as a minimum).
- If database interactions are needed for load or smoke tests (i.e. to create new records), use test accounts with reduced privileges and make the test data separable from real user content.

### Design Considerations

Testing is a fundamental component of DevOps and agile development methodologies. With high degrees of deployment automation, automated testing is essential in providing confidence that the application/infrastructure code behaves as intended in a timely and repeatable manor. The purpose of testing is to detect errors and issues before they reach Production and there are a variety of methods and approaches, including the following:

- **Unit testing**. This confirms that the business logic of the application works as expected. Unit tests improve confidence in code changes. Unit testing considered as part of the Inner Loop and as such will not be discussed further.

- **Smoke testing**. This identifies if the infrastructure and application are available and act as expected.

  - Smoke tests should be executed as part of every deployment.
  - A smoke test focuses on functionality rather than performance under load. Typically only a single virtual user session is tested.
  - Common smoke testing scenarios include: reaching the HTTPS endpoint of a web application, querying a database and simulating a user flow in the application.
  - The outcome of a smoke test is that that the system should respond after a deployment and return the expected values.

- **UI testing**. This validates that the user interface was deployed and works as expected.

  - UI testing is similar to smoke testing but it is focused on user interface interactions.
  - UI automation tools are used.
  - During a UI test the script mimics a realistic user scenario and follows a series of steps to execute functionality xyz and achieve an outcome.

- **Performance testing**. This is a combination of both *load* and *stress testing*. The primary goal of performance testing is to validate and set the benchmark behavior for an application.

- **Load testing**. Validates application scalability by rapidly and/or gradually increasing the load on the application until it reaches a threshold/limit.

  - Azure services have different soft and hard limits associated with them and load testing can reveal if the system faces a risk of exceeding them during the expected production load.
  - Load testing can be used to fine-tune auto-scaling for services that support it (i.e. to set appropriate measured thresholds).
  - Load tests are designed around a "scenario" or user flow to verify if the system satisfies the response goal for that scenario under a defined load.

- **Stress testing**. This is a type of negative testing which involves various activities aimed at overloading existing resources in order to understand where are limits of the solution and to ensure the systems ability to recovery gracefully to operating norms.

  - During stress tests it is essential to monitor all components of the system in order to identify any bottlenecks.
  - Every component of the system not able to scale out can turn into a scale limitation e.g. active/passive network components or databases. It is important to understand their limits so that the solution can mitigate any impact.
  - Unlike load testing, stress tests don't adhere to a realistic usage pattern but aim to identify performance limits.
  - An alternative approach is to limit the computing resources of the system and monitor how it behaves under load and whether it is able to recover.

- **Failure Injection testing**.  This introduces artificial failures to the system.

  - As the application should be resilient to infrastructure failures, introducing faults in the underlying infrastructure and observing how the application behaves is essential to increase the trust in the solutions redundancy mechanisms.
  - Shutting down infrastructure components, purposely degrading performance or introducing faults are ways of verifying that the application is going to react as expected when these situations occur in real life.

- **Security Testing**.  This ensures that the application and its environment meet your expected security posture.

  - These tests will probe the application an environment for security vulnerabilities.
  - The end to end software supply chain of components and package dependencies must be scanned and monitored for known CVE's.

## AIOps

AIOps can be used to supplement traditional tests with capabilities to detect likely regressions or degradations that would result from the in-process deployment. The deployment can be preemptively stopped by signaling failure due to a preemptive detection, similarly to how failed traditional tests could fail a deployment.

### Design Recommendations

- Collect deployment telemetry, i.e. time series data of changes in each deployment
- Expose both deployment and platform observability data for analysis and correlation in AIOps models
- Develop analytical models capable of context- and dependency-aware predictions and automated feature engineering to address schema and behavior changes
- Operationalize models by registering and deploying the best trained models for access in deployment pipelines
- Adopt [MLOps Workflow](https://azure.microsoft.com/services/machine-learning/mlops/)

### Design Considerations

- CI/CD pipelines typically include various types of tests, including unit, smoke, performance and load tests.

- Collecting DevOps process telemetry will require planning of what data will be collected and how it will be analyzed. The changes in a deployment will need to be stored in a manner suitable for automated analysis and correlation to deployment outcomes. Additionally, telemetry of the deployment process itself - that is, in addition to the changes in the code and artifacts - will need to be collected and analyzed.

- Traditional data processing approaches such as Extract, Transform, and Load (ETL) may not be able to scale throughput to keep up with growth of deployment telemetry and application observability data. To enable ongoing analysis by AIOps models, consider modern analytics approaches which do not require ETL and data movement, such as data virtualization.

---

|Previous Page|Next Page|
|:--|:--|
[Health Modeling and Observability](./Health-Modeling.md)|[Networking and Connectivity](./Networking.md)

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
