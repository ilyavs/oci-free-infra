# oci-free-infra

## Project
Terraform for Oracle Cloud Free Tier instances. Provision a blank Ubuntu 24.04 on an Ampere A1 (up to 4 OCPU / 24 GB) and optionally an AMD E2.1 Micro (1/8 OCPU / 1 GB).

## Terraform state
State must be present before running `apply`. It is managed on the AMD instance via the `tf-retry` service.
- If working from a fresh clone, copy the `.tfstate` from the AMD instance (`/home/ubuntu/oci-free-infra/terraform.tfstate`) or run with a fresh state (will create new VCN/subnet).
- **Secrets never committed**: `terraform.tfvars` and `~/.oci/oci_api_key.pem` are gitignored/manual-copy only.

## Variables
| Var | Required | Notes |
|-----|----------|-------|
| `compartment_ocid`, `tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`, `region` | Yes | Standard OCI auth |
| `ssh_public_key_path` | Yes | Path to public key file (not the key text) |
| `availability_domain_index` | No (0) | 0–2, maps to Availability Domain 1/2/3 |
| `allow_amd_micro` | No (false) | Set true to also provision VM.Standard.E2.1.Micro |
| `amd_availability_domain_index` | No (2) | Availability Domain 3 is the only one that has this shape |

## Retry loop
`retry-apply.sh` runs via systemd (`tf-retry` service) every 15 min on the AMD micro, retrying the Ampere A1 until capacity opens.
- View status: `sudo systemctl status tf-retry`
- Tail logs: `sudo journalctl -u tf-retry -f`
- The script exits cleanly when the Ampere instance is created (detected via `data.oci_core_instance` data source).

### Telegram alert (optional)
To get notified when the instance provisions, create `~/.telegramrc`:
```
TELEGRAM_BOT_TOKEN="your:token"
TELEGRAM_CHAT_ID="your_chat_id"
```
If absent, the script runs silently. See README.md for full setup.

## SSH
| Instance | Command |
|----------|---------|
| AMD micro | `ssh -i <key> ubuntu@<terraform output amd_public_ip>` |
| Ampere A1 | `ssh -i <key> ubuntu@<terraform output>` |

## Commands
```bash
terraform init                      # first time only
terraform plan                      # preview
terraform apply                     # provision
terraform apply -auto-approve       # non-interactive
terraform destroy                   # tear down
```

## Conventions
- No comments in Terraform HCL (unless explaining a workaround).
- Use `ignore_changes` over `lifecycle` blocks to avoid recreating instances on image drift.
- Pin provider version to latest stable.
- Ubuntu 24.04 minimal image only.
