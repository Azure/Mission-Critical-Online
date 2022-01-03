locals {
  default_tags = {
    Owner       = "AlwaysOn V-Team"
    Project     = "AlwaysOn Solution Engineering"
    Toolkit     = "Terraform"
    Contact     = "alwaysonappnet@microsoft.com"
    Environment = var.environment
    Prefix      = var.prefix
  }

  prefix = "${lower(var.prefix)}buildagents"
}
