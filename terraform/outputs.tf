output "ransomware_vault_bucket" {
  value = module.s3_ransomware_vault.vault_bucket_id
}

output "ransomware_vault_arn" {
  value = module.s3_ransomware_vault.vault_bucket_arn
}

output "fsx_ontap_management_endpoint" {
  value = var.enable_fsx_ontap ? module.ontap_hybrid_tiering[0].ontap_management_dns : "Disabled (Plan-Only Mode - $0 Cost)"
}
