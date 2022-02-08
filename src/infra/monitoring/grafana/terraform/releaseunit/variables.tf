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
  description = "(Optional) Environment to deploy workloads in."
  type        = string
  default     = "PROD"
}

variable "alerts_enabled" {
  description = "Enable alerts?"
  type        = bool
  default     = false
}

variable "acr_resource_id" {
  description = "Resource ID of container registry that holds the container image"
  type        = string
}


############################### Grafana specific variables ##################################

variable "db_admin_user" {
  description = "Admin user account for backend database."
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "Azure Database for PostgreSQL SKU."
  type        = string
}

variable "db_ver" {
  description = "Azure Database for PostgreSQL version."
  type        = string
}

variable "db_storage_mb" {
  description = "Azure Database for PostgreSQL size in MB."
  type        = number
}

variable "db_bkp_retention" {
  description = "Database backup retention period."
  type        = number
  default     = 7
}

variable "db_geo_bkp" {
  description = "DB geo redundant backups toggle."
  type        = bool
  default     = true
}

variable "db_auto_grow" {
  description = "DB auto grow enabled toggle."
  type        = bool
  default     = true
}

variable "db_net_pub_access" {
  description = "DB network public access toggle. This is set to TRUE due to a bug which causes template to fail. We are enabling private endpoint for backend database to address this."
  type        = bool
  default     = true
}

variable "db_ssl" {
  description = "Toggle to enable SSL for database."
  type        = bool
  default     = true
}

variable "db_ssl_ver" {
  description = "DB SSL version."
  type        = string
  default     = "TLS1_2"
}

variable "db_charset" {
  description = "DB character set."
  type        = string
  default     = "UTF8"
}

variable "db_collation" {
  description = "DB collation."
  type        = string
  default     = "English_United States.1252"
}

variable "asp_tier" {
  description = "ASP SKU tier."
  type        = string
}

variable "asp_size" {
  description = "ASP size to deploy."
  type        = string
}

variable "wapp_container_image" {
  description = "Docker image to use for Grafana."
  type        = string
  default     = "grafana/grafana:latest"
}

variable "frontdoor_header_id" {
  description = "This is required to configure Frontdoor header ID and restrict access to app via AFD only."
  type        = string
}

variable "stamps" {
  type = map(object({
    location           = string
    vnet_address_space = string
    db_primary         = bool
    db_replica         = bool
    db_create_mode     = string
  }))
}