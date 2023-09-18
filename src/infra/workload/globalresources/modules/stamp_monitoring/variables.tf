variable "location" {
  description = "Azure Region for this stamp"
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

variable "resource_group_id" {
  description = "Resource Group Id"
  type        = string
}

variable "azure_monitor_action_group_resource_id" {
  description = "Resource ID of a Azure Monitor action group to send alerts to"
  type        = string
}

variable "alerts_enabled" {
  description = "Enable alerts?"
  type        = bool
  default     = false
}

variable "law_daily_cap_gb" {
  description = "Daily data cap for Log Analytics Workspace and Application Insights in GB"
  type        = number
}

variable "default_tags" {}