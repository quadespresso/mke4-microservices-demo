# Project configuration
# required to export METAL_AUTH_TOKEN=XXXX

variable "project_id" {
  type        = string
  description = <<EOT
ID of your Project in Equinix Metal,
possible to handle as environment variable:
export TF_VAR_project_id="XXXXXXXXXXX"
EOT
}

variable "use_reserved_hardware" {
  description = "Flag to decide if reserved hardware should be used."
  type        = bool
  default     = false
}

variable "cluster_name" {
  default = "mke"
  type    = string
}

variable "master_count" {
  default = 3
  type    = number
}

variable "worker_count" {
  default = 3
  type    = number
}

variable "metros" {
  description = "List of metros and their reserved hardware"
  type = list(object({
    metro = string
    reserved_hardware = list(object({
      id   = string
      plan = string
    }))
  }))
}

variable "admin_password" {
  default = "orcaorcaorca"
}

variable "email" {
  description = "The email address to be used with Ingress controllers"
  type        = string
  default     = "user@example.com"
}

variable "godaddy_api_key" {
  description = "API key for GoDaddy provider"
  type        = string
  sensitive   = true
}

variable "godaddy_api_secret" {
  description = "API secret for GoDaddy provider"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "The domain name for the microservice."
  type        = string
}

variable "server_name" {
  description = "The server name or subdomain for the microservice."
  type        = string
}

variable "mke_server_name" {
  description = "Server name for the MKE LB"
  type        = string
  default     = "mke"
}

variable "longhorn_server_name" {
  description = "Server name for the Longhorn module"
  type        = string
  default     = "longhorn"
}

variable "msr_server_name" {
  description = "Server name for the MSR module"
  type        = string
  default     = "msr"
}

variable "microservice_server_name" {
  description = "Server name for the Microservice module"
  type        = string
  default     = "microservice"
}
