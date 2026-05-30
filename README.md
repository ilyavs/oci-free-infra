# oci-free-infra

Terraform to provision **Oracle Cloud Free Tier** compute instances.

| Instance | Spec | Free tier limit |
|----------|------|-----------------|
| Ampere A1 (ARM) | Up to 4 OCPU, 24 GB RAM | 1 instance |
| AMD E2.1 Micro | 1/8 OCPU, 1 GB RAM | Optional add-on |

Both use Ubuntu 24.04 minimal. Nothing pre-installed — blank SSH access.

## Why two instances?

The Ampere A1 (the free tier flagship) is perpetually out of capacity in many regions. The AMD micro is a fallback that can fit in most Availability Domains — it's weak (1 GB RAM) but enough to run the retry loop (`retry-apply.sh`) that keeps trying the Ampere until capacity opens.

## Prerequisites

- [OCI API key](https://docs.oracle.com/en-us/us/iaas/Content/API/Concepts/apisigningkey.htm)
- Compartment OCID, tenancy OCID
- SSH key pair

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# fill in your OCIDs and key path
terraform init
terraform plan
terraform apply
```

## Variables

| Variable | Default | Notes |
|----------|---------|-------|
| `instance_name` | `free-tier-arm` | |
| `instance_ocpus` | 4 | 1–4 (free tier max) |
| `instance_memory_gb` | 24 | 1–24 (free tier max) |
| `boot_volume_size_gb` | 50 | 1–200 (free tier max) |
| `availability_domain_index` | 0 | 0–2, maps to Availability Domain 1/2/3 |
| `free_tier_safeguard` | `true` | Caps instance count at 1 |
| `allow_amd_micro` | `false` | Set `true` to also provision AMD E2.1.Micro |
| `amd_availability_domain_index` | 2 | AMD shape only available in Availability Domain 3 (index 2) |
| `allowed_ssh_cidrs` | `["0.0.0.0/0"]` | Restrict to your IP if desired |

## Retry loop

The repo includes two retry scripts:

- **`retry-apply.sh`** — for Linux (works well as a systemd service)
- **`retry-apply.ps1`** — for Windows PowerShell

Both try `terraform apply` every 15 minutes, creating the Ampere A1 when capacity opens. They exit cleanly once an instance is provisioned.

### Telegram alert (optional)

Get a notification the moment the instance provisions:

1. Create a bot via [@BotFather](https://t.me/BotFather) on Telegram, save the token
2. Start a chat with your bot, then visit `https://api.telegram.org/bot<TOKEN>/getUpdates` to get your chat ID
3. Create `~/.telegramrc` on the machine running the retry script:

```
TELEGRAM_BOT_TOKEN="your:token"
TELEGRAM_CHAT_ID="your_chat_id"
```

If this file is missing or incomplete, the script runs normally without notifications.

## Security

- `terraform.tfvars`, `*.tfstate`, and `*.log` are gitignored — **never commit secrets**
- SSH uses key-only authentication (no passwords)
- Default security list allows SSH (port 22) from `0.0.0.0/0` — change `allowed_ssh_cidrs` to restrict

## outputs

| Output | Description |
|--------|-------------|
| `instance_public_ip` | Ampere A1 public IP |
| `amd_public_ip` | AMD micro public IP |
| `ssh_connect` | SSH command for Ampere |
| `ssh_amd` | SSH command for AMD micro |
