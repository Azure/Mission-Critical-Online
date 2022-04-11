resource "azurerm_storage_account" "deployment" {
  name                     = "${local.prefix}loadtestst"
  location                 = azurerm_resource_group.deployment.location
  resource_group_name      = azurerm_resource_group.deployment.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.default_tags
}

resource "azurerm_storage_share" "locust" {
  name                 = "locust"
  storage_account_name = azurerm_storage_account.deployment.name
  quota                = 50
}

resource "azurerm_storage_share_file" "locustfile" {
  name             = "locustfile.py"
  storage_share_id = azurerm_storage_share.locust.id
  source           = "../locustfile.py"
}

resource "azurerm_storage_share_directory" "locust-logs" {
  name                 = "logs"
  share_name           = azurerm_storage_share.locust.name
  storage_account_name = azurerm_storage_account.deployment.name
}

resource "azurerm_storage_share_directory" "locust-stats" {
  name                 = "stats"
  share_name           = azurerm_storage_share.locust.name
  storage_account_name = azurerm_storage_account.deployment.name
}


data "azurerm_storage_account_sas" "locust_readwrite" {
  connection_string = azurerm_storage_account.deployment.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = false
    container = true
    object    = true
  }

  services {
    blob  = false
    queue = false
    table = false
    file  = true
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "72h")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}
