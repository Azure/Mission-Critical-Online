resource "azapi_resource" "container_app_environment" {
  name      = "${local.prefix}-${local.location_short}-container-app-environment"
  location  = azurerm_resource_group.stamp.location
  parent_id = azurerm_resource_group.stamp.id
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  body = jsonencode({
    properties = {
      #zoneRedundant = true
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = data.azurerm_log_analytics_workspace.stamp.workspace_id
          sharedKey  = data.azurerm_log_analytics_workspace.stamp.primary_shared_key
        }
      }
      vnetConfiguration = {
        #internal = true
        infrastructureSubnetId = azurerm_subnet.ca_controlplane.id
        runtimeSubnetId        = azurerm_subnet.ca_runtime.id
      }
    }
  })
  ignore_missing_property = true
}

resource "azapi_resource" "container_app" {
  name     = "${local.prefix}-${local.location_short}-ca-hello"
  location = azurerm_resource_group.stamp.location
  identity {
    type = "SystemAssigned"
  }

  parent_id = azurerm_resource_group.stamp.id
  type      = "Microsoft.App/containerApps@2022-03-01"
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.container_app_environment.id
      configuration = {
        ingress = {
          targetPort = 8080
          external   = true
        },
        registries = [
          {
            server   = data.azurerm_container_registry.global.login_server
            identity = "system"
          }
        ],
        # secrets: [
        #   {
        #     name = "registry-password"
        #     # Todo: Container apps does not yet support Managed Identity connection to ACR
        #     value =  azurerm_container_registry.acr.admin_password
        #   }
        # ]
      },
      template = {
        containers = [
          {
            name  = "catalogservice"
            image = "afe2e368cglobalcr.azurecr.io/alwayson/catalogservice:latest"
          }
        ]
      }
    }
  })
  ignore_missing_property = true
}