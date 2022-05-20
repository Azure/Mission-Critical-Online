resource "azapi_resource" "container_app_environment" {
  name = "${local.prefix}-${local.location_short}-container-app-environment"
  location             = azurerm_resource_group.stamp.location
  parent_id = azurerm_resource_group.stamp.id
  type = "Microsoft.App/managedEnvironments@2022-03-01"
  body = jsonencode({
    properties = {
        appLogsConfiguration = {
            destination = "log-analytics"
            logAnalyticsConfiguration = {
                customerId = data.azurerm_log_analytics_workspace.stamp.workspace_id
                sharedKey = data.azurerm_log_analytics_workspace.stamp.primary_shared_key
            }
        }
        vnetConfiguration ={
          infrastructureSubnetId = azurerm_subnet.ca_controlplane.id
          runtimeSubnetId = azurerm_subnet.ca_runtime.id
        }
    }
  })
  ignore_missing_property = true
}

resource "azapi_resource" "container_app" {
  name = "${local.prefix}-${local.location_short}-container-helloworld"
  location = azurerm_resource_group.stamp.location
  identity {
    type = "SystemAssigned"
  }

  parent_id = azurerm_resource_group.stamp.id
  type = "Microsoft.App/containerApps@2022-03-01"
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.container_app_environment.id
      configuration = {
        ingress = {
          targetPort = 80
          external = true
        },
      #   registries = [
      #   {
      #     server = azurerm_container_registry.acr.login_server
      #     username = azurerm_container_registry.acr.admin_username
      #     passwordSecretRef = "registry-password"
      #   }
      # ],
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
            image = "mcr.microsoft.com/containerapps-helloworld:latest"
            name = "helloworld"
          }
        ]
      }
    }
  })
  # This seems to be important for the private registry to work(?)
  ignore_missing_property = true
}