########### Common variables (same for global resources) ###########

variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
}

variable "stamps" {
  description = "List of Azure regions into which stamps are deployed. Important: The first location in this list will be used as the main location for this deployment."
  type        = list(string)
}

variable "branch" {
  description = "Name of the repository branch used for the deployment. Used as an Azure Resource Tag."
  type        = string
  default     = "not set"
}

variable "queued_by" {
  description = "Name of the user who has queued the pipeline run that has deployed this environment. Used as an Azure Resource Tag."
  type        = string
  default     = "n/a"
}

variable "contact_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "OVERWRITE@noreply.com"
}

variable "environment" {
  description = "Environment name i.e. PRD, TEST etc."
  type        = string
}

variable "custom_fqdn" {
  description = "(Optional) Custom FQDN to be used with this app. There must exist an Azure DNS Zone for it. Sample value: www.int.myapp.net"
  type        = string
  default     = ""
}

variable "custom_dns_zone_resourcegroup_name" {
  description = "(Optional) Resource group which holds the Azure DNS Zone of the custom domain name to be used with this app. Must already be registered and the deploying service principal must have contributor permissions on the DNS zone. Does not need to be supplied if custom_fqdn is empty"
  type        = string
  default     = ""
}

variable "auth_group_id" {
  description = "AAD Group ID that grants access to login"
  type        = string
}