locals {

  default_tags = {
    Owner       = "Azure Mission-Critical V-Team"
    Project     = "Azure Mission-Critical Solution Engineering"
    Toolkit     = "Terraform"
    Contact     = var.contact_email
    Environment = var.environment
    Prefix      = var.prefix
    Branch      = var.branch
  }

  prefix = lower(var.prefix)
}
