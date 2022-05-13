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
}
