locals {
  default_tags = {
    Owner       = "Azure Mission-Critical V-Team"
    Project     = "Azure Mission-Critical Solution Engineering"
    Toolkit     = "Terraform"
    Environment = var.environment
    Prefix      = var.prefix
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

  # specifics for headless mode (doesn't apply to worker - that's always headless)
  environment_variables_headless = {
    "LOCUST_RUN_TIME"       = var.locust_runtime, # defaults to 0 when not in headless mode
    "LOCUST_EXPECT_WORKERS" = var.locust_workers, # defaults to 0 when not in headless mode
    "LOCUST_HEADLESS"       = "true",             # locust runs either in headless mode or webui
    "LOCUST_SPAWN_RATE"     = var.locust_spawn_rate,
    "LOCUST_USERS"          = var.locust_number_of_users
  }
}

