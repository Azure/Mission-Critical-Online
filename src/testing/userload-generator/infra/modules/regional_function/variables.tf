variable "location" {
  description = "Azure Region for this Function deployment"
  type        = string
}

variable "prefix" {
  description = "Resource Prefix"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
}

variable "additional_app_settings" {
  description = "Additional Function app settings"
  type        = map(any)
}

variable "function_user_managed_identity_resource_id" {
  type = string
}

variable "default_tags" {}