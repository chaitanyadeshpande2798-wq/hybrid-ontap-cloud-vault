# Hybrid Cloud Storage & Ransomware Vault (NetApp ONTAP + AWS S3)

An Infrastructure-as-Code (Terraform) and Python FinOps automation project demonstrating enterprise **hybrid cloud data tiering**, **ransomware-resilient WORM backups**, and **automated capacity/cost reporting** across NetApp ONTAP and AWS S3 (eu-central-1).

## Architecture Overview
See [docs/architecture.md](docs/architecture.md) for the full Mermaid topology diagram.

1. **AWS S3 Ransomware Vault (Live Deployment):**
   - Provisioned via modular Terraform (terraform/modules/s3-ransomware-vault).
   - Enforces **S3 Object Lock (WORM)** in GOVERNANCE mode (30-day immutable retention), bucket versioning, AES-256 server-side encryption, and strict public access blocks.
   - Automates cold backup transitions (Standard -> Standard-IA -> Glacier Instant Retrieval -> Glacier Deep Archive).
2. **NetApp ONTAP Hybrid Tiering Blueprint (Plan-Validated):**
   - Modular Terraform configuration (terraform/modules/ontap-hybrid-tiering) modeling Amazon FSx for NetApp ONTAP, Storage Virtual Machines (svm_prod_hybrid), thin-provisioned FlexVols with storage efficiency, **FabricPool AUTO (31-day cooling)** and **ALL** tiering policies, and **SnapMirror** disaster recovery (DP) volumes.
   - Guarded by an enable_fsx_ontap = false feature toggle to ensure **.00 AWS spend** during continuous validation.
3. **Python Unified Capacity & FinOps Reporter (scripts/hybrid_capacity_reporter.py):**
   - Audits live S3 Object Lock and lifecycle compliance via boto3.
   - Parses NetApp ONTAP volume and SnapMirror telemetry to compute monthly/annual FabricPool tiering savings and generates Markdown/JSON health reports in reports/.

## Quick Start

```powershell
# 1. Deploy the  AWS S3 Ransomware Vault
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve

# 2. Preview the NetApp ONTAP Hybrid Stack ( Plan-Only Mode)
terraform -chdir=terraform plan -var="enable_fsx_ontap=true"

# 3. Run the Python Compliance & FinOps Health Reporter
pip install -r scripts/requirements.txt
python scripts/hybrid_capacity_reporter.py
```
