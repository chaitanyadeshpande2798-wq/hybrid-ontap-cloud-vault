resource "aws_fsx_ontap_file_system" "hybrid_ontap" {
  storage_capacity                = var.storage_capacity_gb
  subnet_ids                      = slice(var.subnet_ids, 0, 1)
  preferred_subnet_id             = var.subnet_ids[0]
  deployment_type                 = "SINGLE_AZ_1"
  throughput_capacity             = var.throughput_capacity_mbps
  fsx_admin_password              = var.fsx_admin_password
  automatic_backup_retention_days = 7

  tags = {
    Name = "${var.project_prefix}-fsx-ontap"
    Role = "Hybrid-Primary-Storage"
  }
}

resource "aws_fsx_ontap_storage_virtual_machine" "prod_svm" {
  file_system_id             = aws_fsx_ontap_file_system.hybrid_ontap.id
  name                       = "svm_prod_hybrid"
  root_volume_security_style = "UNIX"

  tags = {
    Name = "${var.project_prefix}-svm-prod"
  }
}

# Primary RW Volume with FabricPool AUTO Tiering (31-day cooling period)
resource "aws_fsx_ontap_volume" "app_prod_vol" {
  name                       = "vol_app_prod"
  junction_path              = "/app_prod"
  size_in_megabytes          = 102400 # 100 GiB thin-provisioned
  storage_efficiency_enabled = true
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.prod_svm.id
  ontap_volume_type          = "RW"

  tiering_policy {
    name           = "AUTO"
    cooling_period = 31
  }

  tags = {
    TieringPolicy = "FabricPool-AUTO-31d"
  }
}

# SnapMirror Disaster Recovery Destination Volume (DP) with ALL Tiering
resource "aws_fsx_ontap_volume" "app_dr_snapmirror_vol" {
  name                       = "vol_app_dr_mirror"
  size_in_megabytes          = 102400
  storage_efficiency_enabled = true
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.prod_svm.id
  ontap_volume_type          = "DP"

  tiering_policy {
    name = "ALL"
  }

  tags = {
    ReplicationRole = "SnapMirror-DR-Target"
    TieringPolicy   = "FabricPool-ALL"
  }
}
