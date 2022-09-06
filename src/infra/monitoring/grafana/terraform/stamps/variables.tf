########### Common variables (same for global resources) ###########

variable "prefix" {
  description = "A prefix used for all resources in this example. Must not contain any special characters. Must not be longer than 10 characters."
  type        = string
  validation {
    condition     = length(var.prefix) >= 5 && length(var.prefix) <= 10
    error_message = "Prefix must be between 5 and 10 characters long."
  }
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
  description = "Environment to deploy workloads in."
  type        = string
}

variable "acr_resource_id" {
  description = "Resource ID of container registry that holds the container image"
  type        = string
}


############################### Grafana specific variables ##################################

variable "db_admin_user" {
  description = "Admin user account for backend database."
  type        = string
  default     = "psqladmin"
}

variable "wapp_container_image" {
  description = "Docker image to use for Grafana."
  type        = string
  default     = "grafana/grafana:latest"
}

variable "frontdoor_fqdn" {
  description = "This is required to add the Front Door FQDN to the allowed origins."
  type        = string
}

variable "frontdoor_header_id" {
  description = "This is required to configure Frontdoor header ID and restrict access to app via AFD only."
  type        = string
}

variable "stamps" {
  description = "List of Azure regions into which stamps are deployed. Important: The first location in this list will be used as the main location for this deployment."
  type        = list(string)
}