#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"

echo "== Secrets in $KEY_VAULT_NAME =="
az keyvault secret list --vault-name "$KEY_VAULT_NAME" --query "[].name" -o table

echo ""
echo "If nothing looks like an SP client-id/secret/tenant-id, the SP credentials"
echo "may not be in this vault yet — or 'the service principal' you mean might"
echo "actually be the backing principal of mi-nsync-aisocial-poc (a Managed"
echo "Identity, which has no extractable client secret). If that's the case,"
echo "tell me and we pivot to the MI-token approach instead."
echo ""
echo "Otherwise: copy the matching names into config.env under KV_SECRET_NAME_*"
