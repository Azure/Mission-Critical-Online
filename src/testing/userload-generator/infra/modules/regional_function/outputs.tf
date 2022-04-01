output "function_name" {
  value = azurerm_linux_function_app.regional.name
}

output "function_host_key" {
  value = data.azurerm_function_app_host_keys.regional.default_function_key
}