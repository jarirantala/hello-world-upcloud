variable "upcloud_token" {
  description = "UpCloud API Token"
  type        = string
  sensitive   = true
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