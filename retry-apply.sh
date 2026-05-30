#!/usr/bin/env bash
set -euo pipefail

INTERVAL="${1:-900}"  # default 15 min
DIR="$(cd "$(dirname "$0")" && pwd)"
ATTEMPT=0

while true; do
  ATTEMPT=$((ATTEMPT + 1))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attempt $ATTEMPT -- running terraform apply..."

  cd "$DIR"
  terraform apply -auto-approve \
    -var="allow_amd_micro=true" \
    -var="amd_availability_domain_index=2" 2>&1 | tee /tmp/tf-apply.log

  if terraform state list 2>/dev/null | grep -q 'oci_core_instance\.this\['; then
    IP=$(terraform output -json instance_public_ip 2>/dev/null | jq -r '.[0] // empty')
    echo "SUCCESS! Ampere A1 provisioned at $IP"
    break
  fi

  if grep -q 'Out of host capacity' /tmp/tf-apply.log; then
    echo "  -> Out of host capacity. Retrying in $INTERVAL s..."
  else
    echo "  -> Unexpected error. Retrying in $INTERVAL s..."
    cat /tmp/tf-apply.log
  fi

  sleep "$INTERVAL"
done
