output "appservice_name" {
  value = {
    for k, v in azurerm_app_service.appservice : k => v.name
  }
}

output "appservice_identity" {
  value = {
    for k, v in azurerm_app_service.appservice : k => v.identity
  }
}