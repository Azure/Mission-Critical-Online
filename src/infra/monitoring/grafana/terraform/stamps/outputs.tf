output "appservice_name" {
  value = {
    for k, v in azurerm_linux_web_app.appservice : k => v.name
  }
}

output "appservice_identity" {
  value = {
    for k, v in azurerm_linux_web_app.appservice : k => v.identity
  }
}