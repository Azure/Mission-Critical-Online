# Build array of objects with properties of each stamp
output "stamp_properties" {
  value = [for instance in module.stamp : {
    location                    = instance.location
    resource_group_name         = instance.resource_group_name
    key_vault_name              = instance.key_vault_name
    ingress_fqdn                = instance.ingress_fqdn
    ingress_ip_address          = instance.ingress_publicip_address
    public_storage_account_name = instance.public_storage_account_name
    storage_web_host            = instance.public_storage_static_web_host
  }]
}

output "api_key" {
  value     = random_password.api_key.result
  sensitive = true
}