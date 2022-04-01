output "loadgen_function_names_per_geo" {
  value = local.function_names_per_geo
}

output "master_function_name" {
  value = azurerm_linux_function_app.master.name
}

output "resource_group_name" {
  value = azurerm_resource_group.deployment.name
}