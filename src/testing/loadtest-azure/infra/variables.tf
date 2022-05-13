variable "location" {
  description = "The Azure Region in which the load test will be provisioned."
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment Resource Tag"
  type        = string
  default     = "int"
}

variable "queued_by" {
  description = "Name of the user who has queued the pipeline run that has deployed this environment."
  type        = string
  default     = "not set"
}

variable "branch" {
  description = "Name of the repository branch used for the deployment. Used as an Azure Resource Tag."
  type        = string
  default     = "not set"
}

variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
}