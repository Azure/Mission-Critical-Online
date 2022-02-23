output "locust_webui_fqdn" {
  value = azurerm_container_group.master.*.fqdn
}

output "locust_webui_url" {
  value = var.locust_workers >= 1 ? "http://${azurerm_container_group.master.0.fqdn}:8089" : null
}

output "locust_storage_url" {
  value = azurerm_storage_share.locust.url
}

output "locust_readwrite_sas_token" {
  value     = data.azurerm_storage_account_sas.locust_readwrite.sas
  sensitive = true
}