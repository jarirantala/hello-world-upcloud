variable "upcloud_token" {
  description = "UpCloud API Token"
  type        = string
  sensitive   = true
}

variable "valkey_plan" {
  description = "Plan for Managed Valkey database"
  type        = string
  default     = "1x1xCPU-2GB"
}

variable "region" {
  description = "UpCloud Region"
  type        = string
  default     = "fi-hel2"
}

variable "object_storage_region" {
  description = "Region for Object Storage"
  type        = string
  default     = "europe-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "container_image" {
  description = "Backend container image"
  type        = string
  default     = "python:3.9-alpine" # Default to base, but intended to be overridden
}

variable "github_repo_url" {
  description = "URL of the GitHub repository (e.g., https://github.com/user/repo)"
  type        = string
}

variable "github_token" {
  description = "GitHub PAT or Runner Registration Token"
  type        = string
  sensitive   = true
}