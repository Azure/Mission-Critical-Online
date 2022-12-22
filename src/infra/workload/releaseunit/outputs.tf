# Build array of objects with properties of each stamp
output "stamp_properties" {
  value = [for instance in module.stamp : {
    location                                       = instance.location
    resource_group_name                            = instance.resource_group_name
    key_vault_name                                 = instance.key_vault_name
    aks_cluster_id                                 = instance.aks_cluster_id
    aks_cluster_name                               = instance.aks_cluster_name
    aks_cluster_ingress_fqdn                       = instance.aks_ingress_fqdn
    aks_cluster_ingress_ip_address                 = instance.aks_ingress_publicip_address
    public_storage_account_name                    = instance.public_storage_account_name
    storage_web_host                               = instance.public_storage_static_web_host
    catalogservice_managed_identity_client_id      = instance.catalogservice_managed_identity_client_id
    healthservice_managed_identity_client_id       = instance.healthservice_managed_identity_client_id
    backgroundprocessor_managed_identity_client_id = instance.backgroundprocessor_managed_identity_client_id
  }]
}

output "api_key" {
  value     = random_password.api_key.result
  sensitive = true
}