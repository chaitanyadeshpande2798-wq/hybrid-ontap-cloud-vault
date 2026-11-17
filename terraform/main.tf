data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "s3_ransomware_vault" {
  source              = "./modules/s3-ransomware-vault"
  project_prefix      = var.project_prefix
  worm_retention_days = var.worm_retention_days
}

module "ontap_hybrid_tiering" {
  count  = var.enable_fsx_ontap ? 1 : 0
  source = "./modules/ontap-hybrid-tiering"

  project_prefix     = var.project_prefix
  subnet_ids         = data.aws_subnets.default.ids
  fsx_admin_password = var.fsx_admin_password
}
