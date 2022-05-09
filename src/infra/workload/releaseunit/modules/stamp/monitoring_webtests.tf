
##################
### Application Insights Availability Tests
##################
# Ping the HealthService
resource "azurerm_application_insights_web_test" "cluster_ping" {
  name                    = "${local.prefix}-appinsights-webtest-cluster-${local.location_short}"
  location                = azurerm_resource_group.stamp.location
  resource_group_name     = var.monitoring_resource_group_name
  application_insights_id = data.azurerm_application_insights.stamp.id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 30
  enabled                 = true
  geo_locations           = ["us-tx-sn1-azr", "us-il-ch1-azr", "emea-fr-pra-edge", "emea-se-sto-edge", "apac-hk-hkn-azr"]

  # The GUIDs are ignored by Application Insights so we can set them all to zero
  configuration = <<XML
<WebTest Name="${local.prefix}-appinsights-webtest-cluster-${local.location_short}" Id="00000000-0000-0000-0000-000000000000" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="30" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="00000000-0000-0000-0000-000000000000" Version="1.1" Url="${azurerm_api_management.stamp.gateway_url}/healthservice/health/stamp" ThinkTime="0" Timeout="30" ParseDependentRequests="False" FollowRedirects="False" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False">
      <Headers>
        <Header Name="X-Azure-FDID" Value="${var.frontdoor_id_header}" />
      </Headers>
  </Request>
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

# Ping the Static Website Storage
resource "azurerm_application_insights_web_test" "static_storage_ping" {
  name                    = "${local.prefix}-appinsights-webtest-staticstorage-${local.location_short}"
  location                = azurerm_resource_group.stamp.location
  resource_group_name     = var.monitoring_resource_group_name
  application_insights_id = data.azurerm_application_insights.stamp.id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 30
  enabled                 = true
  geo_locations           = ["us-tx-sn1-azr", "us-il-ch1-azr", "emea-fr-pra-edge", "emea-se-sto-edge", "apac-hk-hkn-azr"]

  # The GUIDs are ignored by Application Insights so we can set them all to zero
  configuration = <<XML
<WebTest Name="${local.prefix}-appinsights-webtest-staticstorage-${local.location_short}" Id="00000000-0000-0000-0000-000000000000" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="30" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="00000000-0000-0000-0000-000000000000" Version="1.1" Url="https://${azurerm_storage_account.public.primary_web_host}" ThinkTime="0" Timeout="30" ParseDependentRequests="False" FollowRedirects="False" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
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
