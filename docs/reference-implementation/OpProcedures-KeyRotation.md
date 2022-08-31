# Key and Secret Rotation

Rotating (renewing) keys/secrets should be a standard procedure in any workload. Secrets might need to be changed on short notice after being exposed or regularly as a good security practice.

As expired or invalid secrets can cause outages to the application (see [Failure Analysis](https://docs.microsoft.com/azure/architecture/reference-architectures/containers/aks-mission-critical/mission-critical-health-modeling#failure-analysis)), it is important to have a clearly defined and proven process in place. For Azure Mission-Critical, rotating secrets of stamp resources, such as Event Hub access keys, are not a significant concern as the stamps are expected to be live a few weeks at most. Also, even if secrets in one stamp expire, this would not bring down the whole application.

Management of secrets to access long-living global resources, however, are critical, notably the Cosmos DB API keys. If these expire it is likely that all stamps will be affected simultaneously and cause a complete outage of the application.

Azure Mission-Critical tested and documented the approach for how to rotate the keys for Cosmos DB without causing downtime and this is detailed below:

## Cosmos DB Key Rotation Walkthrough

1) By default, using Terraform, the primary API key of Cosmos DB is stored in each stamp's Key Vault [as a secret](/src/infra/workload/releaseunit/modules/stamp/keyvault-secrets.tf). So firstly, we need to change this Terraform code to use the `secondary_key` instead. This change needs to go through the regular PR review and update procedure to either get deployed as a new release or as a hotfix release to an existing release.
1) If this was deployed as a hotfix to an existing release, the pods will automatically pick up the new secret from Key Vault after a few minutes, however, the Cosmos DB client code does currently not re-initialize with a changed key. To resolve this, all of the pods now need to be restarted in a rolling fashion by connecting to each AKS cluster and run the following commands:

    ```bash
    kubectl rollout restart deployment/CatalogService-deploy -n workload
    kubectl rollout restart deployment/BackgroundProcessor-deploy -n workload
    kubectl rollout restart deployment/healthservice-deploy -n workload
    ```

1) Restarted pods will now use the secondary API key.
1) Once all pods on all stamps have been restarted we can regenerate the primary API key for Cosmos DB:

    ```bash
    az cosmosdb keys regenerate --key-kind primary --name MyCosmosDBDatabaseAccount --resource-group MyResourceGroup
    ```

1) Finally, the Terraform template should be changed back to use the primary key again for future deployments; if not, we can continue to use the secondary key and switch back to the primary key when we need to renew the secondary key in the future.

---

[Azure Mission-Critical - Full List of Documentation](/docs/README.md)
