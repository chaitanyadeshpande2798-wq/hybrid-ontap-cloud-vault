output "fsx_file_system_id" {
  value = aws_fsx_ontap_file_system.hybrid_ontap.id
}

output "ontap_management_dns" {
  value = aws_fsx_ontap_file_system.hybrid_ontap.endpoints[0].management[0].dns_name
}

output "svm_id" {
  value = aws_fsx_ontap_storage_virtual_machine.prod_svm.id
}

output "prod_volume_id" {
  value = aws_fsx_ontap_volume.app_prod_vol.id
}

output "dr_snapmirror_volume_id" {
  value = aws_fsx_ontap_volume.app_dr_snapmirror_vol.id
}
