# Configuration Layer

The "configuration layer" builds the bridge between the infrastructure deployed in the [Infrastructure Layer](../infra/README.md) and the application. This reference implementation partially separates the infrastructure, configuration and workload deployment which allow us to use different toolkits for each part and to separate it into different stages.

## Versioning

All dependencies and components used for the Azure Mission-Critical reference implementation are defined using a specific, static version to avoid issues due to changes with untested, newer versions of certain components.

These versions are specified in `.ado/pipelines/config/configuration.yaml` and loaded into all Azure DevOps pipelines. Here's an example how this looks like:

```yaml
variables:
- name:  'helmVersion'         # helm package manager version
  value: 'v3.5.4'
- name:  'terraformVersion'    # Terraform Version
  value: '0.15.2'
```

These version definitions are not only used for the components installed, but also for the cli tools like helm, kubectl and others to make sure that the same version is used.

## Components

The configuration layer is responsible for installing a set of components on top of the Azure resources, in this reference implementation mainly Azure Kubernetes Service, deployed as part of the infrastructure layer:

* [ingress-nginx](#ingress-nginx)
* [cert-manager](#cert-manager)
* [csi-driver-keyvault](#csi-driver-keyvault)
* [monitoring](#monitoring)

Additional configuration and manifests files used to configure the additional services are stored within the `/src/config` directory.

### ingress-nginx

**ingress-nginx** is a Helm chart used to deploy the nginx-based ingress controller onto the AKS cluster. The Azure Public IP address for the ingress controller's load balancer is already pre-created as part of the [Infrastructure Layer](/src/infra/README.md). The Public IP address and Azure Resource Group where it resides are handed over to the Helm chart as a deployment parameter so it can be [used by the Kubernetes service](https://learn.microsoft.com/azure/aks/load-balancer-standard#additional-customizations-via-kubernetes-annotations).

Important configurations are:

* Configure autoscaling
* Set resource requests
* Enable Prometheus metrics

Further settings are set in the `values.helm.yaml` file in [src/config/ingress-nginx](/src/config/ingress/values.helm.yaml). See [ingress-nginx/values.yaml](https://github.com/kubernetes/ingress-nginx/blob/master/charts/ingress-nginx/values.yaml) for all configuration options available for the `ingress-nginx` helm chart.

### cert-manager

Jetstack's cert-manager is used to auto-provision SSL/TLS certificates (using Let's Encrypt) for ingress rules. It is installed via the `cert-manager` helm chart as part of the configuration stage.

Additional configuration settings like the `ClusterIssuer` (used to request certificates from Let's Encrypt) is deployed via a separate `cert-manager-config` helm chart stored in [src/config/cert-manager/chart](/src/config/cert-manager/chart/).

This implementation is using `ClusterIssuer` instead of `Issuer` as documented [here](https://cert-manager.io/docs/concepts/issuer/) and [here](https://docs.cert-manager.io/en/release-0.7/tasks/issuing-certificates/ingress-shim.html) to avoid having issuers per namespaces.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
```

### csi-driver-keyvault

To securely read secrets such as connection strings from Azure Key Vault, we use the open-source [Azure Key Vault Provider for Secrets Store CSI Driver](https://azure.github.io/secrets-store-csi-driver-provider-azure/). It uses the Managed Identities of the respective pod ("workload identity"), so no credentials need to be stored anywhere inside the cluster to access Key Vault.

During the infra-config deployment step, all required components are installed via Helm. The provider is configured to mount all the secrets from the Key Vault on the file system of a pod, as well as to provide them as Kubernetes secret objects.
Optionally, these can later be loaded as ENV variables for easy application access inside the pods.
Note: Even if a pod only wants to use the ENV variables, it still needs to do the file system mount in order for the secret retrieval to work. This step is done in the app deployment.

### Monitoring

Monitoring contains an additional YAML manifest to update and change the OMSAgent configuration (using a ConfigMap) which is installed to all our AKS clusters as part of Azure Monitor Container Insights. The OMSAgent is automatically provisioned as a container per node on all cluster nodes in our AKS clusters by using a Kubernetes DaemonSet.

```YAML
  prometheus-data-collection-settings: |-
    # Custom Prometheus metrics data collection settings
    [prometheus_data_collection_settings.cluster]
        #kubernetes_services = ["https://kubernetes.default.svc/metrics"] # kubernetes apiserver
        [..]

    [prometheus_data_collection_settings.node]
        #urls = ["https://$NODE_IP:10250/metrics"] #kubelet
        [..]
```

Our ConfigMap disabled Prometheus-scraping and stdout/stderr collection to reduce the amount of monitoring data sent to the corresponding Log Analytics workspace (per regional deployment).

---

[Back to documentation root](/docs/README.md)
