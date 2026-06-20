#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/lib_sp.sh"
load_sp_creds

SP_DISPLAY_NAME=$(az ad sp show --id "$SP_CLIENT_ID" --query displayName -o tsv)
SP_OBJECT_ID=$(az ad sp show --id "$SP_CLIENT_ID" --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Adding $SP_DISPLAY_NAME (object id $SP_OBJECT_ID) as a Postgres AAD admin..."

az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforPostgreSQL/flexibleServers/$PG_SERVER_NAME/administrators/$SP_OBJECT_ID?api-version=2025-08-01" \
  --body "{\"properties\":{\"principalName\":\"$SP_DISPLAY_NAME\",\"principalType\":\"ServicePrincipal\",\"tenantId\":\"$SP_TENANT_ID\"}}"

echo ""
echo "Done. SP now has full admin access on this server -- broader than the"
echo "SELECT-only role originally planned. Fine for tonight; tighten after."
