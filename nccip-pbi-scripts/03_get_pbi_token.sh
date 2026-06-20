#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/lib_sp.sh"
load_sp_creds

# Isolated az config dir so this SP login doesn't clobber your normal
# az CLI session (steps 00/01/02 need to run as YOU, not the SP).
SP_AZ_CONFIG_DIR=$(mktemp -d)
export AZURE_CONFIG_DIR="$SP_AZ_CONFIG_DIR"

az login --service-principal \
  --username "$SP_CLIENT_ID" \
  --password "$SP_CLIENT_SECRET" \
  --tenant "$SP_TENANT_ID" \
  --output none

TOKEN=$(az account get-access-token \
  --resource https://ossrdbms-aad.database.windows.net \
  --query accessToken -o tsv)

rm -rf "$SP_AZ_CONFIG_DIR"

OUT="$(dirname "$0")/pbi_pg_token.txt"
echo "$TOKEN" > "$OUT"
chmod 600 "$OUT"

echo "Token written to $OUT (chmod 600, expires in ~1hr)"
echo "Token length: ${#TOKEN} chars"
echo "Your normal az CLI session (logged in as you) was untouched."
echo ""
echo "Re-run this script whenever the token lapses during demo prep."
