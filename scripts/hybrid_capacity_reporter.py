import json
import os
from datetime import datetime, timezone
import boto3
from botocore.exceptions import ClientError

SSD_COST_PER_GB_MONTH = 0.125
CAPACITY_TIER_COST_PER_GB_MONTH = 0.023


def discover_vault_bucket(s3_client, prefix="ontap-hybrid-vault-"):
    response = s3_client.list_buckets()
    for bucket in response.get("Buckets", []):
        if bucket["Name"].startswith(prefix):
            return bucket["Name"]
    return None


def audit_s3_ransomware_vault(s3_client, bucket_name):
    if not bucket_name:
        return {
            "bucket_name": "NOT_DEPLOYED",
            "worm_status": "MISSING",
            "retention_days": 0,
            "versioning": "Disabled",
            "lifecycle_rules": 0,
            "compliance_passed": False,
        }

    ver = s3_client.get_bucket_versioning(Bucket=bucket_name).get("Status", "Disabled")

    worm_mode = "NONE"
    retention_days = 0
    try:
        lock_cfg = s3_client.get_object_lock_configuration(Bucket=bucket_name)
        rule = lock_cfg["ObjectLockConfiguration"]["Rule"]["DefaultRetention"]
        worm_mode = rule["Mode"]
        retention_days = rule.get("Days", 0)
    except ClientError:
        worm_mode = "ERROR_OR_DISABLED"

    try:
        lc = s3_client.get_bucket_lifecycle_configuration(Bucket=bucket_name)
        lc_rules = len(lc.get("Rules", []))
    except ClientError:
        lc_rules = 0

    passed = (ver == "Enabled") and (worm_mode in ["GOVERNANCE", "COMPLIANCE"]) and (lc_rules > 0)

    return {
        "bucket_name": bucket_name,
        "worm_status": worm_mode,
        "retention_days": retention_days,
        "versioning": ver,
        "lifecycle_rules": lc_rules,
        "compliance_passed": passed,
    }


def analyze_ontap_finops(ontap_data):
    total_ssd_gb = 0.0
    total_tiered_gb = 0.0
    volume_rows = []

    for vol in ontap_data["volumes"]:
        ssd_gb = vol["used_performance_ssd_gb"]
        tiered_gb = vol["tiered_capacity_pool_gb"]
        total_ssd_gb += ssd_gb
        total_tiered_gb += tiered_gb

        unoptimized_cost = (ssd_gb + tiered_gb) * SSD_COST_PER_GB_MONTH
        actual_cost = (ssd_gb * SSD_COST_PER_GB_MONTH) + (tiered_gb * CAPACITY_TIER_COST_PER_GB_MONTH)
        monthly_savings = unoptimized_cost - actual_cost

        volume_rows.append({
            "name": vol["name"],
            "type": vol["type"],
            "policy": vol["tiering_policy"],
            "ssd_gb": ssd_gb,
            "tiered_gb": tiered_gb,
            "monthly_savings_usd": round(monthly_savings, 2),
        })

    total_monthly_savings = round(
        total_tiered_gb * (SSD_COST_PER_GB_MONTH - CAPACITY_TIER_COST_PER_GB_MONTH), 2
    )
    sm_healthy = all(rel["healthy"] and rel["lag_time_seconds"] < 900 for rel in ontap_data["snapmirror_relationships"])

    return {
        "cluster_name": ontap_data["cluster"]["name"],
        "svm": ontap_data["cluster"]["svm"],
        "total_ssd_gb": total_ssd_gb,
        "total_tiered_gb": total_tiered_gb,
        "monthly_savings_usd": total_monthly_savings,
        "annual_savings_usd": round(total_monthly_savings * 12, 2),
        "snapmirror_sla_ok": sm_healthy,
        "volumes": volume_rows,
    }


def generate_reports(vault_audit, ontap_summary):
    os.makedirs("reports", exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    report_payload = {
        "generated_at": timestamp,
        "s3_ransomware_vault": vault_audit,
        "ontap_hybrid_finops": ontap_summary,
    }

    with open("reports/hybrid_health_report.json", "w", encoding="utf-8") as jf:
        json.dump(report_payload, jf, indent=2)

    md_lines = [
        "# Hybrid Cloud Storage & Ransomware Vault - Daily Health Report",
        f"**Generated:** {timestamp}  ",
        f"**ONTAP Cluster / SVM:** `{ontap_summary['cluster_name']}` / `{ontap_summary['svm']}`  ",
        f"**SnapMirror RPO SLA (<15m):** {'PASS' if ontap_summary['snapmirror_sla_ok'] else 'ALERT'}",
        "",
        "## 1. AWS S3 Ransomware Vault Compliance (Live Audit)",
        "| Check | Status |",
        "| :--- | :--- |",
        f"| **Target Bucket** | `{vault_audit['bucket_name']}` |",
        f"| **Versioning** | {vault_audit['versioning']} |",
        f"| **Object Lock (WORM)** | {vault_audit['worm_status']} ({vault_audit['retention_days']} days) |",
        f"| **Lifecycle Tiering Rules** | {vault_audit['lifecycle_rules']} Active |",
        f"| **Overall Immutability Compliance** | **{'COMPLIANT' if vault_audit['compliance_passed'] else 'NON-COMPLIANT'}** |",
        "",
        "## 2. NetApp ONTAP FabricPool Tiering & FinOps Savings",
        "| Volume | Type | Tiering Policy | Active SSD (GB) | Cold Tiered (GB) | Monthly Savings |",
        "| :--- | :--- | :--- | :---: | :---: | :---: |",
    ]

    for v in ontap_summary["volumes"]:
        md_lines.append(
            f"| `{v['name']}` | {v['type']} | {v['policy']} | {v['ssd_gb']} | {v['tiered_gb']} | ${v['monthly_savings_usd']:.2f} |"
        )

    md_lines.extend([
        "",
        f"- **Total Cold Data Offloaded to Capacity Tier:** `{ontap_summary['total_tiered_gb']} GB`",
        f"- **Estimated Monthly Tiering Savings:** **`${ontap_summary['monthly_savings_usd']:.2f}/mo`** (`${ontap_summary['annual_savings_usd']:.2f}/yr`)",
    ])

    md_content = "\n".join(md_lines) + "\n"
    with open("reports/hybrid_health_report.md", "w", encoding="utf-8") as mf:
        mf.write(md_content)

    print(md_content)


if __name__ == "__main__":
    s3 = boto3.client("s3", region_name="eu-central-1")
    vault_name = discover_vault_bucket(s3)
    vault_results = audit_s3_ransomware_vault(s3, vault_name)

    with open("scripts/mock_ontap_data.json", "r", encoding="utf-8") as f:
        ontap_raw = json.load(f)

    ontap_results = analyze_ontap_finops(ontap_raw)
    generate_reports(vault_results, ontap_results)
