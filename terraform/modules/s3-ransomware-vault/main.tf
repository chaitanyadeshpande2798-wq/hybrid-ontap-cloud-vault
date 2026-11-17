resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "ransomware_vault" {
  bucket              = "${var.project_prefix}-vault-${random_id.bucket_suffix.hex}"
  object_lock_enabled = true
  force_destroy       = true
}

resource "aws_s3_bucket_public_access_block" "vault_pab" {
  bucket                  = aws_s3_bucket.ransomware_vault.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "vault_versioning" {
  bucket = aws_s3_bucket.ransomware_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vault_sse" {
  bucket = aws_s3_bucket.ransomware_vault.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "vault_worm" {
  bucket = aws_s3_bucket.ransomware_vault.id
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.worm_retention_days
    }
  }
  depends_on = [aws_s3_bucket_versioning.vault_versioning]
}

resource "aws_s3_bucket_lifecycle_configuration" "vault_tiering" {
  bucket = aws_s3_bucket.ransomware_vault.id
  rule {
    id     = "fabricpool-cold-data-tiering"
    status = "Enabled"
    filter {
      prefix = "ontap-backups/"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }
  depends_on = [aws_s3_bucket_versioning.vault_versioning]
}
