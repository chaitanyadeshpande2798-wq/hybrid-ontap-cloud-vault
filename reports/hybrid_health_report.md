# Hybrid Cloud Storage & Ransomware Vault - Daily Health Report
**Generated:** 2026-11-17 15:39:08 UTC  
**ONTAP Cluster / SVM:** `ontap-hybrid-fsx-01` / `svm_prod_hybrid`  
**SnapMirror RPO SLA (<15m):** PASS

## 1. AWS S3 Ransomware Vault Compliance (Live Audit)
| Check | Status |
| :--- | :--- |
| **Target Bucket** | `ontap-hybrid-vault-aac6e32c` |
| **Versioning** | Enabled |
| **Object Lock (WORM)** | GOVERNANCE (30 days) |
| **Lifecycle Tiering Rules** | 1 Active |
| **Overall Immutability Compliance** | **COMPLIANT** |

## 2. NetApp ONTAP FabricPool Tiering & FinOps Savings
| Volume | Type | Tiering Policy | Active SSD (GB) | Cold Tiered (GB) | Monthly Savings |
| :--- | :--- | :--- | :---: | :---: | :---: |
| `vol_app_prod` | RW | AUTO | 140.0 | 360.0 | $36.72 |
| `vol_app_dr_mirror` | DP | ALL | 12.0 | 488.0 | $49.78 |

- **Total Cold Data Offloaded to Capacity Tier:** `848.0 GB`
- **Estimated Monthly Tiering Savings:** **`$86.50/mo`** (`$1038.00/yr`)
