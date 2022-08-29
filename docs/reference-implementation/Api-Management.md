# Adding API Management

A common scenario, which is not covered by the main reference implementation, is to include an API Management service in the architecture. It is not included in the main branch as it is considered an optional service and not essentially required in many cases.

Therefore there is a [separate branch](https://github.com/Azure/Mission-Critical-Online/tree/examples/api-management) which includes Azure API Management (APIM) and all the required changes to properly embed this in the reference implementation. This article walks through the various required changes.

## Architecture overview

The architecture diagram for Azure Mission-Critical Online using an regional APIM instance is shown below.

![Mission-Critical architecture diagram with API Management](/docs/media/Mission-critical-APIM-architecture.svg)

It is important to note that API Management is used as a regional resource, i.e. deployed per stamp, and not in the geo-replicated version of APIM. This is to not break the principle of having no regional dependencies wherever possible. While the geo-replicated deployment of APIM does provide resiliency of the data plane (i.e. the gateways) against a regional outage, the control plane is bound to the primary region. If APIM in that region experiences issues, no deployments/changes can be made. Hence, we deploy separate instances per stamp.

## Overview of the changes

1) Add a subnet to host API Management in ["external" VNet mode](https://docs.microsoft.com/azure/api-management/virtual-network-concepts?tabs=stv2#access-options) plus the required Network Security Group and rules.
1) Add a subnet to host the new internal Kubernetes load balancer for the ingress controller
1) Add a definition for the APIM service into the Terraform IaC part
1) Add definitions for all the APIs, operations and polices, also to Terraform
1) Change the publicly exposed Kubernetes service for the ingress controller to an internal load balancer
1) Change all tests and other tasks which were targeting the public IP of the load balancer to now target APIM
1) Change Azure Front Door backend to point to APIM
1) Since the ingress controller is now an internal service, we cannot use the HTTP-01 issuer of Let's Encrypt anymore to procure SSL certificates for the ingress

## Detailed changes

**Note:** The following changes are not included in the main branch, the links refer to the files in the [`examples/api-management` branch](https://github.com/Azure/Mission-Critical-Online/tree/examples/api-management).

### Add a subnet to host API Management and Network Security Group

To host the API Management service, we need to add a subnet to the VNet. This subnet will be used to host the API Management service. This is implemented in [network.tf](/src/infra/workload/releaseunit/modules/stamp/network.tf).

Also a dedicated NSG is added which contains the [required rules](https://docs.microsoft.com/azure/api-management/api-management-using-with-vnet?tabs=stv2#configure-nsg-rules) for APIM.

### Add a subnet to host the new internal Kubernetes load balancer

The internal load balancer for Kubernetes gets its own subnet, so we can control its internal IP address for the ingress controller. This is also implemented in [network.tf](/src/infra/workload/releaseunit/modules/stamp/network.tf)

### Add API Management service Terraform definition

The APIM service is defined in [apim.tf](/src/infra/workload/releaseunit/modules/stamp/apim.tf). Settings can be changed as required by your specific scenario.

Also note the newly added values in the `output.tf` which refer to APIM and which are needed later.

### Add definitions for all the APIs, operations and polices

Also in the same file (`apim.tf`) are defined the API, operations and policies.
To define the actual API operations, we import the Swagger/OpenAPI definitions for both, CatalogService and HealthService. Currently these files are just statically put inside the repository [/src/infra/workload/releaseunit/apim](/src/infra/workload/releaseunit/apim). Ideally, these would be generated dynamically as part of the deployment pipeline.

Also in the same folder the globally applicable policies ([apim-api-policy.xml](/src/infra/workload/releaseunit/apim/apim-api-policy.xml)) are defined. In this case we do the Front Door header validation as part of this, which was formerly done inside the Nginx ingress controller.

### Change Kubernetes service for the ingress controller to an internal load balancer

Converting the ingress controller service to a private load balancer is done via two annotations on the Nginx configuration in [jobs-configuration.yaml](/.ado/pipelines/templates/jobs-configuration.yaml):

```console
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="true" `
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet"="aks-lb-snet"
```

### Change tests and import task to point to APIM

Using the new output variables from the Terraform definition, we can now change all the tests and import tasks to point to the new APIM service. For instance in the [jobs-init-sampledata.yaml](/.ado/pipelines/templates/jobs-init-sampledata.yaml) as well as in [SmokeTests.ps1](/.ado/pipelines/scripts/Run-SmokeTests.ps1).

### Change Azure Front Door backend to point to APIM

To point the Front Door backend to the new APIM service, we only need to change the pipeline script which builds the backend pool settings: [steps-frontdoor-traffic-switch.yaml](/.ado/pipelines/templates/steps-frontdoor-traffic-switch.yaml).

### Change cert-manager to not use HTTP-01 issuer

In the main reference implementation we use the ACME HTTP-01 issuer of Let's Encrypt to procure SSL certificates for the ingress. This is not possible in the new API Management service, so we need to change the issuer to use the DNS-01 issuer. However, this requires the use of custom domain names on the internal load balancer of AKS. The Terraform templates and pipelines in the `examples/api-management` branch are fully prepared for that. However, the use of custom domain names might not be feasible in every deployment. Therefore, the cert-manager issuer is configured to fall back to the self-signed issuer method in case no custom domain name is provided. In this case, also the backend setting of APIM will disable any certificate validation.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
