variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_prefix" {
  type    = string
  default = "ontap-hybrid"
}

variable "worm_retention_days" {
  type    = number
  default = 30
}

variable "enable_fsx_ontap" {
  description = "Set to true ONLY for terraform plan dry-runs. Keep false for $0 operation."
  type        = bool
  default     = false
}

variable "fsx_admin_password" {
  description = "ONTAP admin password used during plan validation"
  type        = string
  sensitive   = true
  default     = "NetAppPortfolio2026!"
}
