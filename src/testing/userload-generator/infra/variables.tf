variable "location" {
  description = "The Azure Region in which the master will be provisioned."
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment Resource Tag"
  type        = string
  default     = "int"
}

variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
}

variable "queued_by" {
  description = "Name of the user who has queued the pipeline run that has deployed this environment."
  type        = string
  default     = "not set"
}

variable "targeturl" {
  description = "Target URL"
  type        = string
  default     = "https://www.int.shop.mission-critical.app"
}

variable "regional_functions_workers" {
  type = map(any)
  default = {
    "EMEA" = ["northeurope", "germanywestcentral", "francecentral", "westeurope", "uksouth", "ukwest", "switzerlandnorth", "norwayeast"]
    #"AMERICAS" = ["eastus2", "westus2", "brazilsouth"]
    #"APAC"     = ["australiaeast", "japaneast", "southeastasia"]
  }
}
