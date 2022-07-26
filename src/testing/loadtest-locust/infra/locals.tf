locals {
  default_tags = {
    Owner       = "Azure Mission-Critical V-Team"
    Project     = "Azure Mission-Critical Solution Engineering"
    Toolkit     = "Terraform"
    Environment = var.environment
    Prefix      = var.prefix
    Branch      = var.branch
    CreatedFor  = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)
  }

  prefix = lower(var.prefix)

  # see https://docs.locust.io/en/stable/configuration.html for details on individual Locust configuration options
  environment_variables_common = {
    "LOCUST_LOCUSTFILE" = "/home/locust/locust/${azurerm_storage_share_file.locustfile.name}"
  }

  # values which are needed when the Locust master schedules a load test
  environment_variables_master = {
    "LOCUST_HOST"             = var.targeturl,
    "LOCUST_MODE_MASTER"      = "true"
    "LOCUST_LOGFILE"          = "/home/locust/locust/logs/${local.prefix}.log"
    "LOCUST_CSV_FULL_HISTORY" = "true"
    "LOCUST_CSV"              = "locust/stats/${local.prefix}"
  }

  environment_variables_worker = {
    "LOCUST_MODE_WORKER" = "true"
  }

}

