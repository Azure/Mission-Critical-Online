variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment - e2e, int or prod"
  type        = string
  default     = "e2e"
}

variable "vnet_address_space" {
  description = "Address space used for the VNets. Must be large enough to provide at least of size /20"
  type        = string
  default     = "10.0.0.0/20"
}