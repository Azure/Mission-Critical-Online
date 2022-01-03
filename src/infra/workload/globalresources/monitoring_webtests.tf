
##################
### Application Insights Availability Tests
##################
# Ping the CatalogService API
# We are using the catalogitem/?limit=1 API, since that is one of the APIs that does not require authentication
resource "azurerm_application_insights_web_test" "api_ping" {
  name                    = "${local.prefix}-appinsights-webtest-api-global"
  location                = azurerm_resource_group.monitoring.location
  resource_group_name     = azurerm_resource_group.monitoring.name
  application_insights_id = azurerm_application_insights.monitoring.id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 30
  enabled                 = true
  geo_locations           = ["us-tx-sn1-azr", "us-il-ch1-azr", "emea-fr-pra-edge", "emea-se-sto-edge", "apac-hk-hkn-azr", "apac-jp-kaw-edge", "latam-br-gru-edge", "emea-au-syd-edge"]

  # The GUIDs are ignored by Application Insights so we can set them all to zero
  configuration = <<XML
<WebTest Name="${local.prefix}-appinsights-webtest-api-global" Id="00000000-0000-0000-0000-000000000000" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="30" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="00000000-0000-0000-0000-000000000000" Version="1.1" Url="https://${var.custom_fqdn != "" ? var.custom_fqdn : azurerm_frontdoor.main.cname}/api/1.0/catalogitem/?limit=1" ThinkTime="0" Timeout="30" ParseDependentRequests="False" FollowRedirects="False" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags because there is a hidden-link tag that gets created by ARM
      tags
    ]
  }
}

# Ping the Website
resource "azurerm_application_insights_web_test" "website_ping" {
  name                    = "${local.prefix}-appinsights-webtest-website-global"
  location                = azurerm_resource_group.monitoring.location
  resource_group_name     = azurerm_resource_group.monitoring.name
  application_insights_id = azurerm_application_insights.monitoring.id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 30
  enabled                 = true
  geo_locations           = ["us-tx-sn1-azr", "us-il-ch1-azr", "emea-fr-pra-edge", "emea-se-sto-edge", "apac-hk-hkn-azr", "apac-jp-kaw-edge", "latam-br-gru-edge", "emea-au-syd-edge"]

  # The GUIDs are ignored by Application Insights so we can set them all to zero
  configuration = <<XML
<WebTest Name="${local.prefix}-appinsights-webtest-website-global" Id="00000000-0000-0000-0000-000000000000" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="30" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="00000000-0000-0000-0000-000000000000" Version="1.1" Url="https://${var.custom_fqdn != "" ? var.custom_fqdn : azurerm_frontdoor.main.cname}" ThinkTime="0" Timeout="30" ParseDependentRequests="False" FollowRedirects="False" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags because there is a hidden-link tag that gets created by ARM
      tags
    ]
  }
}