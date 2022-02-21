output "global_resource_group_name" {
  value = azurerm_resource_group.rg.name
}

# Azure Container Registry (Global) Login Server
output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "URL of the ACR. Sample: myacr.azurecr.io"
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "acr_resource_id" {
  value = azurerm_container_registry.main.id
}

output "frontdoor_resource_id" {
  value = azurerm_frontdoor.afdgrafana.id
}

output "frontdoor_name" {
  value = azurerm_frontdoor.afdgrafana.name
}

# Azure Front Door Header ID
output "frontdoor_header_id" {
  value = azurerm_frontdoor.afdgrafana.header_frontdoor_id
}

# Azure Front Door FQDN
output "frontdoor_fqdn" {
  value = var.custom_fqdn != "" ? var.custom_fqdn : azurerm_frontdoor.afdgrafana.cname
}
