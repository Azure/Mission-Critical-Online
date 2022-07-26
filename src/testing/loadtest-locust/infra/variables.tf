variable "location" {
  description = "The Azure Region in which the master and the shared storage account will be provisioned."
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment Resource Tag"
  type        = string
  default     = "int"
}

variable "branch" {
  description = "Name of the repository branch used for the deployment. Used as an Azure Resource Tag."
  type        = string
  default     = "not set"
}

variable "locust_container_image" {
  description = "Locust Container Image"
  type        = string
  default     = "locustio/locust:2.10.1"
}

variable "queued_by" {
  description = "Name of the user who has queued the pipeline run that has deployed this environment."
  type        = string
  default     = "not set"
}

variable "targeturl" {
  description = "Target URL"
  type        = string
  default     = "https://www.int.mission-critical.app"
}

variable "locust_workers" {
  description = "Number of Locust worker instances (zero will remove the master node as well)"
  type        = string
  default     = "0"
}

variable "locust_worker_locations" {
  description = "List of regions to deploy workers to in round robin fashion"
  type        = list(string)
  default = [
    "northeurope",
    "eastus2",
    "southeastasia",
    "westeurope",
    "westus",
    "australiaeast",
    "southafricanorth",
    "francecentral",
    "southcentralus",
    "japaneast",
    "southindia",
    "brazilsouth",
    "germanywestcentral",
    "uksouth",
    "canadacentral",
    "eastus",
    "uaenorth",
    "koreacentral",
    "eastasia",
    "westus3",
    "australiasoutheast",
    "canadaeast",
    "centralindia",
    "japanwest",
    "norwayeast",
    "switzerlandnorth",
    "ukwest",
    "centralus",
    "northcentralus",
    "westcentralus",
    "westus2"
  ]
}

variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
}
