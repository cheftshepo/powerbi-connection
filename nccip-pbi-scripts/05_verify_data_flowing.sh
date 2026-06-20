#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/config.env"
source "$(dirname "$0")/lib_sp.sh"
load_sp_creds

SP_DISPLAY_NAME=$(az ad sp show --id "$SP_CLIENT_ID" --query displayName -o tsv)
TOKEN_FILE="$(dirname "$0")/pbi_pg_token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "No token found — run 03_get_pbi_token.sh first."
  exit 1
fi

echo "== Row count sanity check (connecting as the SP) =="
PGPASSWORD=$(cat "$TOKEN_FILE") psql \
  -h "$PG_HOST" -U "$SP_DISPLAY_NAME" -d "$PG_DB_NAME" --set=sslmode=require \
  -c "SELECT COUNT(*) FROM enriched_posts;"

echo ""
echo "== Geo resolution gap check (known issue from earlier debugging) =="
PGPASSWORD=$(cat "$TOKEN_FILE") psql \
  -h "$PG_HOST" -U "$SP_DISPLAY_NAME" -d "$PG_DB_NAME" --set=sslmode=require \
  -c "SELECT COUNT(*) AS total,
             COUNT(*) FILTER (WHERE district_code IS NOT NULL) AS has_district,
             COUNT(*) FILTER (WHERE geo_source = 'unresolved') AS unresolved
      FROM enriched_posts;"

echo ""
echo "If has_district is low relative to total, the map visual will render"
echo "empty or mostly empty — worth knowing before you're live tomorrow."
