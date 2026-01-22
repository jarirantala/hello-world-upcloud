variable "upcloud_token" {
  description = "UpCloud API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "UpCloud Region"
  type        = string
  default     = "FI-HEL2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}