variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Primary region for the platform"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Primary zone within the region"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address for operational alerts"
  type        = string
}