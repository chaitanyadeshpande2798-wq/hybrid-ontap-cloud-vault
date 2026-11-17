variable "project_prefix" {
  description = "Naming prefix for FSx ONTAP resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of VPC subnet IDs for the FSx ONTAP file system"
  type        = list(string)
}

variable "fsx_admin_password" {
  description = "Password for the fsxadmin ONTAP cluster administrator"
  type        = string
  sensitive   = true
}

variable "storage_capacity_gb" {
  description = "SSD primary tier capacity in GiB (minimum 1024 GiB)"
  type        = number
  default     = 1024
}

variable "throughput_capacity_mbps" {
  description = "Throughput capacity in MBps"
  type        = number
  default     = 128
}
