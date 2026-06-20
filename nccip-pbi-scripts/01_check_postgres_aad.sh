#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"

echo "== AAD auth config on $PG_SERVER_NAME =="
az postgres flexible-server show \
  --name "$PG_SERVER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "authConfig" -o json

echo ""
echo "== Current AAD admins on $PG_SERVER_NAME =="
az postgres flexible-server ad-admin list \
  --server-name "$PG_SERVER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  -o table

echo ""
echo "If the SP isn't listed and you want it as a scoped read-only role instead"
echo "of a full AAD admin, skip ad-admin entirely and go straight to step 02"
echo "(it uses pgaadauth_create_principal, which doesn't need admin rights granted)."
