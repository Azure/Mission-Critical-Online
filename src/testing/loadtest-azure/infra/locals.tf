locals {
  default_tags = {
    Owner       = "AlwaysOn V-Team"
    Project     = "Always-on Solution Engineering"
    Toolkit     = "Terraform"
    Environment = var.environment
    Prefix      = var.prefix
    Branch      = var.branch
    CreatedFor  = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)
  }

  prefix = lower(var.prefix)
}
