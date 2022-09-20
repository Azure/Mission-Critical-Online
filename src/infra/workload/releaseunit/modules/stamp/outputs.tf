output "location" {
  value = var.location
}

output "resource_group_name" {
  value = azurerm_resource_group.stamp.name
}

# Name of the per-stamp Azure Key Vault instance
output "key_vault_name" {
  value = azurerm_key_vault.stamp.name
}

# Ingress Controller PublicIP Address
output "ingress_publicip_address" {
  value = azurerm_public_ip.ingress.ip_address
}

# Ingress Controller PublicIP FQDN
output "ingress_fqdn" {
  value = azurerm_public_ip.ingress.fqdn
}

# Name of the public Storage Account
output "public_storage_account_name" {
  value = azurerm_storage_account.public.name
}

# Hostname of the static website storage endpoint
output "public_storage_static_web_host" {
  value = azurerm_storage_account.public.primary_web_host
}

output "app_insights_id" {
  value = data.azurerm_application_insights.stamp.id
}

output "app_insights_name" {
  value = data.azurerm_application_insights.stamp.name
}

output "eventhub_id" {
  value = azurerm_eventhub_namespace.stamp.id
}
